-- ============================================
-- EJERCICIO 01 - CHECK-IN Y TRAZABILIDAD COMERCIAL
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en check_in
-- 3. Procedimiento almacenado para registrar check-in
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Trazabilidad del pasajero por vuelo: reserva, pasajero, tiquete, segmento y vuelo

CREATE OR REPLACE VIEW v_passenger_flight_traceability AS
SELECT 
    r.reservation_id,
    r.reservation_code,
    f.flight_id,
    f.flight_number,
    f.flight_date,
    fs.flight_status_name,
    ts.ticket_id,
    ts.ticket_number,
    ts.ticket_segment_sequence,
    p.person_id,
    p.first_name,
    p.last_name,
    rp.passenger_sequence,
    fls.flight_segment_id,
    fls.segment_number,
    fls.scheduled_departure_time,
    fls.scheduled_arrival_time,
    a_origin.airport_code AS origin_airport,
    a_dest.airport_code AS destination_airport
FROM reservation r
INNER JOIN reservation_passenger rp ON r.reservation_id = rp.reservation_id
INNER JOIN person p ON rp.person_id = p.person_id
INNER JOIN ticket ts ON r.reservation_id = ts.reservation_id
INNER JOIN ticket_segment ts_seg ON ts.ticket_id = ts_seg.ticket_id
INNER JOIN flight_segment fls ON ts_seg.flight_segment_id = fls.flight_segment_id
INNER JOIN flight f ON fls.flight_id = f.flight_id
INNER JOIN flight_status fs ON f.flight_status_id = fs.flight_status_id
INNER JOIN airport a_origin ON fls.origin_airport_id = a_origin.airport_id
INNER JOIN airport a_dest ON fls.destination_airport_id = a_dest.airport_id
ORDER BY r.reservation_code, rp.passenger_sequence, ts.ticket_segment_sequence;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN CHECK_IN
-- ============================================
-- Cuando se registra un check-in, automáticamente se crea un boarding_pass

CREATE OR REPLACE FUNCTION fn_create_boarding_pass_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    v_boarding_group_id uuid;
    v_ticket_segment_id uuid;
    v_check_in_status_id uuid;
    v_gate_id uuid;
BEGIN
    -- Obtener información necesaria del check_in
    SELECT 
        ci.ticket_segment_id,
        ci.check_in_status_id,
        ci.boarding_group_id
    INTO v_ticket_segment_id, v_check_in_status_id, v_boarding_group_id
    FROM check_in ci
    WHERE ci.check_in_id = NEW.check_in_id;

    -- Obtener una puerta de embarque disponible
    SELECT boarding_gate_id INTO v_gate_id
    FROM boarding_gate
    LIMIT 1;

    -- Crear el boarding_pass
    INSERT INTO boarding_pass (
        ticket_segment_id,
        boarding_group_id,
        boarding_gate_id,
        sequence_number,
        issued_at
    )
    VALUES (
        v_ticket_segment_id,
        v_boarding_group_id,
        v_gate_id,
        1,
        NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger ya existe, eliminarlo
DROP TRIGGER IF EXISTS trg_create_boarding_pass_on_checkin ON check_in;

-- Crear el trigger
CREATE TRIGGER trg_create_boarding_pass_on_checkin
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_create_boarding_pass_on_checkin();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra el check-in de un pasajero para un ticket_segment

CREATE OR REPLACE PROCEDURE sp_register_checkin(
    p_ticket_segment_id uuid,
    p_user_account_id uuid,
    p_boarding_group_id uuid DEFAULT NULL,
    p_boarding_group_name varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_in_status_id uuid;
    v_boarding_group_id_final uuid;
    v_check_in_id uuid;
BEGIN
    -- Obtener el estado de check-in "completed" o similar
    SELECT check_in_status_id INTO v_check_in_status_id
    FROM check_in_status
    WHERE status_code = 'COMPLETED'
    LIMIT 1;

    -- Si no existe estado, usar el primero disponible
    IF v_check_in_status_id IS NULL THEN
        SELECT check_in_status_id INTO v_check_in_status_id
        FROM check_in_status
        LIMIT 1;
    END IF;

    -- Si se proporciona nombre de grupo pero no ID, buscarlo o crear uno
    IF p_boarding_group_id IS NULL AND p_boarding_group_name IS NOT NULL THEN
        SELECT boarding_group_id INTO v_boarding_group_id_final
        FROM boarding_group
        WHERE group_name = p_boarding_group_name
        LIMIT 1;
    ELSE
        v_boarding_group_id_final := p_boarding_group_id;
    END IF;

    -- Si aun no hay grupo de embarque, obtener uno por defecto
    IF v_boarding_group_id_final IS NULL THEN
        SELECT boarding_group_id INTO v_boarding_group_id_final
        FROM boarding_group
        LIMIT 1;
    END IF;

    -- Registrar check-in
    INSERT INTO check_in (
        ticket_segment_id,
        check_in_status_id,
        user_account_id,
        boarding_group_id,
        checked_in_at
    )
    VALUES (
        p_ticket_segment_id,
        v_check_in_status_id,
        p_user_account_id,
        v_boarding_group_id_final,
        NOW()
    )
    RETURNING check_in_id INTO v_check_in_id;

    -- El trigger se encargará de crear el boarding_pass

    RAISE NOTICE 'Check-in registrado exitosamente. Check-in ID: %', v_check_in_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- Nota: Ejecutar solo después de tener datos de prueba en la BD

-- 1. Consultar datos disponibles
SELECT 
    r.reservation_code,
    p.first_name,
    p.last_name,
    ts.ticket_number,
    f.flight_number,
    a_origin.airport_code,
    a_dest.airport_code
FROM v_passenger_flight_traceability v
JOIN reservation r ON v.reservation_id = r.reservation_id
JOIN person p ON v.person_id = p.person_id
JOIN ticket ts ON v.ticket_id = ts.ticket_id
JOIN flight f ON v.flight_id = f.flight_id
JOIN airport a_origin ON v.origin_airport = a_origin.airport_code
JOIN airport a_dest ON v.destination_airport = a_dest.airport_code
LIMIT 1;

-- 2. Obtener IDs necesarios para la prueba
-- Estos valores deben ajustarse según los datos reales de la BD
-- SELECT 
--     ts.ticket_segment_id,
--     ua.user_account_id,
--     bg.boarding_group_id
-- FROM ticket_segment ts
-- JOIN ticket t ON ts.ticket_id = t.ticket_id
-- JOIN reservation r ON t.reservation_id = r.reservation_id
-- JOIN user_account ua ON ua.user_account_id = (SELECT user_account_id FROM user_account LIMIT 1)
-- JOIN boarding_group bg ON bg.boarding_group_id = (SELECT boarding_group_id FROM boarding_group LIMIT 1)
-- LIMIT 1;

-- 3. Invocación del procedimiento (ejemplo)
-- CALL sp_register_checkin(
--     p_ticket_segment_id := 'TICKET_SEGMENT_ID_HERE',
--     p_user_account_id := 'USER_ACCOUNT_ID_HERE',
--     p_boarding_group_name := 'BOARDING_GROUP_NAME'
-- );

-- 4. Verificar que se creó el boarding_pass
-- SELECT 
--     bp.boarding_pass_id,
--     bp.boarding_gate_id,
--     bp.issued_at,
--     ci.checked_in_at
-- FROM boarding_pass bp
-- JOIN ticket_segment ts ON bp.ticket_segment_id = ts.ticket_segment_id
-- JOIN check_in ci ON ci.ticket_segment_id = ts.ticket_segment_id
-- ORDER BY ci.checked_in_at DESC
-- LIMIT 1;
