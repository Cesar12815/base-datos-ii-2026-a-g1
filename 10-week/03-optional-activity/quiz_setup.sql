-- ============================================
-- CREACIÓN DE BASE DE DATOS QUIZ
-- ============================================

CREATE DATABASE Quiz;

-- Conectar a la base de datos Quiz
\c Quiz

-- ============================================
-- REQUERIMIENTO 1: VISTA DE TRAZABILIDAD
-- ============================================

CREATE OR REPLACE VIEW vw_passenger_flight_traceability AS
SELECT
    -- Información de la reserva
    r.reservation_code AS codigo_reserva,
    -- Información del pasajero
    p.first_name || ' ' || COALESCE(p.last_name, '') AS nombre_pasajero,
    rp.passenger_sequence_no AS secuencia_pasajero,
    rp.passenger_type AS tipo_pasajero,
    -- Información del vuelo
    f.flight_number AS numero_vuelo,
    f.service_date AS fecha_servicio,
    -- Información del tiquete
    t.ticket_number AS numero_tiquete,
    -- Información del segmento
    fs.segment_number AS numero_segmento,
    fs.scheduled_departure_at AS hora_salida_programada,
    fs.scheduled_arrival_at AS hora_llegada_programada,
    -- Información de origen y destino
    ao.airport_name AS aeropuerto_origen,
    ad.airport_name AS aeropuerto_destino,
    -- Metadatos
    r.booked_at AS fecha_reserva,
    t.issued_at AS fecha_emision_tiquete
    
FROM
    reservation r
    INNER JOIN reservation_passenger rp ON r.reservation_id = rp.reservation_id
    INNER JOIN person p ON rp.person_id = p.person_id
    INNER JOIN ticket t ON rp.reservation_passenger_id = t.reservation_passenger_id
    INNER JOIN ticket_segment ts ON t.ticket_id = ts.ticket_id
    INNER JOIN flight_segment fs ON ts.flight_segment_id = fs.flight_segment_id
    INNER JOIN flight f ON fs.flight_id = f.flight_id
    INNER JOIN airport ao ON fs.origin_airport_id = ao.airport_id
    INNER JOIN airport ad ON fs.destination_airport_id = ad.airport_id
ORDER BY
    r.reservation_code,
    rp.passenger_sequence_no,
    ts.segment_sequence_no;

-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT
-- ============================================
-- Trigger que automatiza la creación de boarding_pass
-- cuando se registra un check_in

-- Función auxiliar para el trigger
CREATE OR REPLACE FUNCTION fn_create_boarding_pass_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    v_check_in_id uuid;
    v_boarding_pass_code varchar(40);
    v_barcode_value varchar(120);
    v_segment_seq integer;
    v_ticket_id uuid;
BEGIN
    -- Obtener información del ticket_segment
    SELECT ts.ticket_id, ts.segment_sequence_no
    INTO v_ticket_id, v_segment_seq
    FROM ticket_segment ts
    WHERE ts.ticket_segment_id = NEW.ticket_segment_id;
    
    -- Generar código de pase de abordar basado en ticket y segmento
    v_boarding_pass_code := CONCAT(
        (SELECT t.ticket_number FROM ticket t WHERE t.ticket_id = v_ticket_id),
        '-',
        LPAD(v_segment_seq::text, 2, '0')
    );
    
    -- Generar código de barras usando UUID parcial
    v_barcode_value := CONCAT(v_boarding_pass_code, '-', SUBSTRING(gen_random_uuid()::text, 1, 8));
    
    -- Insertar el boarding_pass automáticamente
    INSERT INTO boarding_pass (
        check_in_id,
        boarding_pass_code,
        barcode_value,
        issued_at,
        created_at,
        updated_at
    ) VALUES (
        NEW.check_in_id,
        v_boarding_pass_code,
        v_barcode_value,
        now(),
        now(),
        now()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger AFTER INSERT en check_in
DROP TRIGGER IF EXISTS trg_auto_boarding_pass_on_checkin ON check_in CASCADE;

CREATE TRIGGER trg_auto_boarding_pass_on_checkin
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_create_boarding_pass_on_checkin();

-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Procedimiento que encapsula el registro de check-in
-- para un pasajero sobre un segmento de vuelo ticketed

CREATE OR REPLACE PROCEDURE sp_register_checkin(
    p_ticket_segment_id uuid,           -- ID del segmento ticketed
    p_check_in_status_code varchar(20), -- Código del estado (ej: 'CHECKED_IN')
    p_boarding_group_code varchar(10) DEFAULT NULL,  -- Código del grupo de abordaje (opcional)
    p_user_account_id uuid DEFAULT NULL  -- Usuario que ejecuta el check-in (opcional)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_in_status_id uuid;
    v_boarding_group_id uuid;
    v_check_in_id uuid;
    v_current_time timestamptz;
BEGIN
    -- Variables de control
    v_current_time := now();
    
    -- 1. Validar que el ticket_segment existe
    IF NOT EXISTS (SELECT 1 FROM ticket_segment WHERE ticket_segment_id = p_ticket_segment_id) THEN
        RAISE EXCEPTION 'El segmento de tiquete (ticket_segment_id: %) no existe', p_ticket_segment_id;
    END IF;
    
    -- 2. Validar que no existe un check_in previo para este segmento
    IF EXISTS (SELECT 1 FROM check_in WHERE ticket_segment_id = p_ticket_segment_id) THEN
        RAISE EXCEPTION 'Ya existe un check-in registrado para el segmento de tiquete (ticket_segment_id: %)', p_ticket_segment_id;
    END IF;
    
    -- 3. Obtener el ID del estado de check-in
    SELECT check_in_status_id
    INTO v_check_in_status_id
    FROM check_in_status
    WHERE status_code = p_check_in_status_code;
    
    IF v_check_in_status_id IS NULL THEN
        RAISE EXCEPTION 'El estado de check-in (status_code: %) no existe', p_check_in_status_code;
    END IF;
    
    -- 4. Obtener el ID del grupo de abordaje si se proporciona
    IF p_boarding_group_code IS NOT NULL THEN
        SELECT boarding_group_id
        INTO v_boarding_group_id
        FROM boarding_group
        WHERE group_code = p_boarding_group_code;
        
        IF v_boarding_group_id IS NULL THEN
            RAISE EXCEPTION 'El grupo de abordaje (group_code: %) no existe', p_boarding_group_code;
        END IF;
    END IF;
    
    -- 5. Insertar el registro de check-in
    INSERT INTO check_in (
        ticket_segment_id,
        check_in_status_id,
        boarding_group_id,
        checked_in_by_user_id,
        checked_in_at,
        created_at,
        updated_at
    ) VALUES (
        p_ticket_segment_id,
        v_check_in_status_id,
        v_boarding_group_id,  -- NULL si no se proporciona
        p_user_account_id,    -- NULL si no se proporciona
        v_current_time,
        v_current_time,
        v_current_time
    )
    RETURNING check_in_id INTO v_check_in_id;
    
    -- 6. Commit implícito del procedimiento
    -- El trigger AFTER INSERT se ejecutará automáticamente
    -- para crear el boarding_pass
    
    RAISE NOTICE 'Check-in registrado exitosamente. CHECK_IN_ID: %', v_check_in_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Error al registrar check-in: %', SQLERRM;
END;
$$;

-- ============================================
-- FIN DEL SCRIPT DE CONFIGURACIÓN
-- ============================================
RAISE NOTICE 'Base de datos Quiz creada exitosamente con vistas, triggers y procedimientos almacenados.';
