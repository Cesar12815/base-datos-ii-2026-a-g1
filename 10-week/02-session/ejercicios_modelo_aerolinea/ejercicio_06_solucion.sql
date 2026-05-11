-- ============================================
-- EJERCICIO 06 - RETRASOS OPERATIVOS Y ANÁLISIS
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en flight_delay
-- 3. Procedimiento almacenado para registrar demora
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona aerolínea, vuelo, estado, segmento, aeropuertos y retrasos

CREATE OR REPLACE VIEW v_flight_delay_analysis AS
SELECT 
    al.airline_id,
    al.airline_code,
    al.airline_name,
    f.flight_id,
    f.flight_number,
    f.flight_date,
    fs.flight_status_id,
    fs.flight_status_name,
    fls.flight_segment_id,
    fls.segment_number,
    fls.scheduled_departure_time,
    fls.scheduled_arrival_time,
    a_origin.airport_id AS origin_airport_id,
    a_origin.airport_code AS origin_airport,
    a_origin.airport_name AS origin_name,
    a_dest.airport_id AS destination_airport_id,
    a_dest.airport_code AS destination_airport,
    a_dest.airport_name AS destination_name,
    fd.flight_delay_id,
    fd.delay_minutes,
    drt.delay_reason_type_id,
    drt.reason_code,
    drt.reason_description
FROM airline al
INNER JOIN flight f ON al.airline_id = f.airline_id
INNER JOIN flight_status fs ON f.flight_status_id = fs.flight_status_id
INNER JOIN flight_segment fls ON f.flight_id = fls.flight_id
INNER JOIN airport a_origin ON fls.origin_airport_id = a_origin.airport_id
INNER JOIN airport a_dest ON fls.destination_airport_id = a_dest.airport_id
INNER JOIN flight_delay fd ON fls.flight_segment_id = fd.flight_segment_id
INNER JOIN delay_reason_type drt ON fd.delay_reason_type_id = drt.delay_reason_type_id
ORDER BY f.flight_date DESC, fls.segment_number;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN FLIGHT_DELAY
-- ============================================
-- Cuando se registra una demora, se actualiza el estado del vuelo si es necesario

CREATE OR REPLACE FUNCTION fn_update_flight_status_on_delay()
RETURNS TRIGGER AS $$
DECLARE
    v_flight_id uuid;
    v_delayed_status_id uuid;
BEGIN
    -- Obtener el flight_id desde flight_segment
    SELECT fs.flight_id INTO v_flight_id
    FROM flight_segment fs
    WHERE fs.flight_segment_id = NEW.flight_segment_id;

    -- Obtener el estado "DELAYED" si existe
    SELECT fs_status.flight_status_id INTO v_delayed_status_id
    FROM flight_status fs_status
    WHERE fs_status.flight_status_code = 'DELAYED'
    LIMIT 1;

    -- Si no existe el estado DELAYED, obtener uno disponible
    IF v_delayed_status_id IS NULL THEN
        SELECT flight_status_id INTO v_delayed_status_id
        FROM flight_status
        LIMIT 1;
    END IF;

    -- Actualizar el estado del vuelo si la demora es significativa
    IF NEW.delay_minutes > 15 THEN
        UPDATE flight
        SET flight_status_id = v_delayed_status_id,
            updated_at = NOW()
        WHERE flight_id = v_flight_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_update_flight_status_on_delay ON flight_delay;

-- Crear el trigger
CREATE TRIGGER trg_update_flight_status_on_delay
AFTER INSERT ON flight_delay
FOR EACH ROW
EXECUTE FUNCTION fn_update_flight_status_on_delay();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra una demora para un segmento de vuelo

CREATE OR REPLACE PROCEDURE sp_register_flight_delay(
    p_flight_segment_id uuid,
    p_delay_reason_type_id uuid,
    p_delay_minutes numeric,
    p_notes varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_flight_delay_id uuid;
BEGIN
    -- Validar que el segmento de vuelo existe
    IF NOT EXISTS (SELECT 1 FROM flight_segment WHERE flight_segment_id = p_flight_segment_id) THEN
        RAISE EXCEPTION 'El segmento de vuelo con ID % no existe', p_flight_segment_id;
    END IF;

    -- Validar que el tipo de motivo existe
    IF NOT EXISTS (SELECT 1 FROM delay_reason_type WHERE delay_reason_type_id = p_delay_reason_type_id) THEN
        RAISE EXCEPTION 'El tipo de motivo con ID % no existe', p_delay_reason_type_id;
    END IF;

    -- Validar que la demora es positiva
    IF p_delay_minutes <= 0 THEN
        RAISE EXCEPTION 'La demora debe ser mayor a 0 minutos';
    END IF;

    -- Registrar la demora
    INSERT INTO flight_delay (
        flight_segment_id,
        delay_reason_type_id,
        delay_minutes,
        notes,
        reported_at,
        created_at
    )
    VALUES (
        p_flight_segment_id,
        p_delay_reason_type_id,
        p_delay_minutes,
        p_notes,
        NOW(),
        NOW()
    )
    RETURNING flight_delay_id INTO v_flight_delay_id;

    -- El trigger se encargará de actualizar el estado del vuelo

    RAISE NOTICE 'Demora registrada exitosamente. Delay ID: %', v_flight_delay_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver análisis de retrasos
SELECT 
    al.airline_code,
    f.flight_number,
    f.flight_date,
    a_origin.airport_code AS origin,
    a_dest.airport_code AS destination,
    fd.delay_minutes,
    drt.reason_description
FROM v_flight_delay_analysis v
JOIN airline al ON v.airline_id = al.airline_id
JOIN flight f ON v.flight_id = f.flight_id
JOIN airport a_origin ON v.origin_airport_id = a_origin.airport_id
JOIN airport a_dest ON v.destination_airport_id = a_dest.airport_id
JOIN flight_delay fd ON v.flight_delay_id = fd.flight_delay_id
JOIN delay_reason_type drt ON v.delay_reason_type_id = drt.delay_reason_type_id
LIMIT 10;

-- 2. Obtener datos para la prueba
-- SELECT 
--     fs.flight_segment_id,
--     f.flight_number,
--     drt.delay_reason_type_id,
--     drt.reason_code
-- FROM flight_segment fs
-- JOIN flight f ON fs.flight_id = f.flight_id
-- JOIN delay_reason_type drt ON drt.delay_reason_type_id = (SELECT delay_reason_type_id FROM delay_reason_type LIMIT 1)
-- LIMIT 1;

-- 3. Registrar una demora
-- CALL sp_register_flight_delay(
--     p_flight_segment_id := 'FLIGHT_SEGMENT_ID_HERE',
--     p_delay_reason_type_id := 'DELAY_REASON_TYPE_ID_HERE',
--     p_delay_minutes := 45,
--     p_notes := 'Retraso debido a condiciones climáticas'
-- );

-- 4. Verificar el registro y actualización del estado
-- SELECT 
--     f.flight_number,
--     f.flight_status_id,
--     fs.flight_status_name,
--     fd.delay_minutes,
--     fd.reported_at
-- FROM flight_delay fd
-- JOIN flight_segment fls ON fd.flight_segment_id = fls.flight_segment_id
-- JOIN flight f ON fls.flight_id = f.flight_id
-- JOIN flight_status fs ON f.flight_status_id = fs.flight_status_id
-- ORDER BY fd.reported_at DESC
-- LIMIT 1;
