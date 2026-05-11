-- ============================================
-- EJERCICIO 07 - ASIGNACIÓN DE ASIENTOS Y EQUIPAJE
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en baggage
-- 3. Procedimiento almacenado para registrar equipaje
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona tiquete, segmento ticketed, segmento operativo, asiento, cabina y equipaje

CREATE OR REPLACE VIEW v_seat_baggage_assignment AS
SELECT 
    t.ticket_id,
    t.ticket_number,
    ts.ticket_segment_id,
    ts.ticket_segment_sequence,
    fls.flight_segment_id,
    fls.segment_number,
    f.flight_number,
    f.flight_date,
    ac_seat.aircraft_seat_id,
    ac_seat.seat_row,
    ac_seat.seat_column,
    acc.aircraft_cabin_id,
    acc.cabin_number,
    cc.cabin_class_id,
    cc.class_code,
    cc.class_name,
    b.baggage_id,
    b.baggage_tag,
    b.baggage_type
FROM ticket t
INNER JOIN ticket_segment ts ON t.ticket_id = ts.ticket_id
INNER JOIN flight_segment fls ON ts.flight_segment_id = fls.flight_segment_id
INNER JOIN flight f ON fls.flight_id = f.flight_id
LEFT JOIN seat_assignment sa ON ts.ticket_segment_id = sa.ticket_segment_id
LEFT JOIN aircraft_seat ac_seat ON sa.aircraft_seat_id = ac_seat.aircraft_seat_id
LEFT JOIN aircraft_cabin acc ON ac_seat.aircraft_cabin_id = acc.aircraft_cabin_id
LEFT JOIN cabin_class cc ON acc.cabin_class_id = cc.cabin_class_id
LEFT JOIN baggage b ON ts.ticket_segment_id = b.ticket_segment_id
ORDER BY t.ticket_number, ts.ticket_segment_sequence;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN BAGGAGE
-- ============================================
-- Cuando se registra equipaje, se valida la capacidad disponible

CREATE OR REPLACE FUNCTION fn_validate_baggage_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_aircraft_id uuid;
    v_baggage_count integer;
    v_aircraft_capacity integer;
BEGIN
    -- Obtener el aircraft_id desde el ticket_segment
    SELECT f.aircraft_id INTO v_aircraft_id
    FROM flight_segment fls
    JOIN flight f ON fls.flight_id = f.flight_id
    WHERE fls.flight_segment_id = NEW.ticket_segment_id;

    -- Contar equipajes registrados para este ticket_segment
    SELECT COUNT(*) INTO v_baggage_count
    FROM baggage
    WHERE ticket_segment_id = NEW.ticket_segment_id;

    -- Capacidad simplificada (normalmente sería por clase o aeronave)
    v_aircraft_capacity := 2;

    -- Si se excede la capacidad, registrar un aviso
    IF v_baggage_count > v_aircraft_capacity THEN
        RAISE WARNING 'Se ha excedido el equipaje permitido para el segmento';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_validate_baggage_capacity ON baggage;

-- Crear el trigger
CREATE TRIGGER trg_validate_baggage_capacity
AFTER INSERT ON baggage
FOR EACH ROW
EXECUTE FUNCTION fn_validate_baggage_capacity();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra equipaje para un ticket_segment

CREATE OR REPLACE PROCEDURE sp_register_baggage(
    p_ticket_segment_id uuid,
    p_baggage_type varchar,
    p_weight_kg numeric DEFAULT NULL,
    p_description varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_baggage_id uuid;
    v_baggage_tag varchar;
BEGIN
    -- Validar que el ticket_segment existe
    IF NOT EXISTS (SELECT 1 FROM ticket_segment WHERE ticket_segment_id = p_ticket_segment_id) THEN
        RAISE EXCEPTION 'El ticket_segment con ID % no existe', p_ticket_segment_id;
    END IF;

    -- Generar etiqueta de equipaje
    v_baggage_tag := 'BAG-' || SUBSTRING(p_ticket_segment_id::varchar, 1, 8) || '-' || 
                     LPAD(EXTRACT(EPOCH FROM NOW())::text, 10, '0');

    -- Registrar el equipaje
    INSERT INTO baggage (
        ticket_segment_id,
        baggage_tag,
        baggage_type,
        weight_kg,
        description,
        created_at
    )
    VALUES (
        p_ticket_segment_id,
        v_baggage_tag,
        p_baggage_type,
        p_weight_kg,
        p_description,
        NOW()
    )
    RETURNING baggage_id INTO v_baggage_id;

    -- El trigger se encargará de validar capacidad

    RAISE NOTICE 'Equipaje registrado. Baggage ID: %, Tag: %', v_baggage_id, v_baggage_tag;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver asignaciones de asiento y equipaje
SELECT 
    t.ticket_number,
    ts.ticket_segment_sequence,
    f.flight_number,
    COALESCE(ac_seat.seat_row || ac_seat.seat_column, 'Pendiente') as seat,
    cc.class_name,
    b.baggage_tag,
    b.baggage_type
FROM v_seat_baggage_assignment v
JOIN ticket t ON v.ticket_id = t.ticket_id
JOIN ticket_segment ts ON v.ticket_segment_id = ts.ticket_segment_id
JOIN flight f ON v.flight_id = f.flight_id
LEFT JOIN seat_assignment sa ON ts.ticket_segment_id = sa.ticket_segment_id
LEFT JOIN aircraft_seat ac_seat ON v.aircraft_seat_id = ac_seat.aircraft_seat_id
LEFT JOIN cabin_class cc ON v.cabin_class_id = cc.cabin_class_id
LEFT JOIN baggage b ON v.baggage_id = b.baggage_id
LIMIT 10;

-- 2. Obtener datos para la prueba
-- SELECT 
--     ts.ticket_segment_id,
--     t.ticket_number
-- FROM ticket_segment ts
-- JOIN ticket t ON ts.ticket_id = t.ticket_id
-- LIMIT 1;

-- 3. Registrar equipaje
-- CALL sp_register_baggage(
--     p_ticket_segment_id := 'TICKET_SEGMENT_ID_HERE',
--     p_baggage_type := 'CHECKED',
--     p_weight_kg := 23.5,
--     p_description := 'Maleta azul con ruedas'
-- );

-- 4. Verificar registro
-- SELECT 
--     b.baggage_tag,
--     b.baggage_type,
--     b.weight_kg,
--     b.created_at,
--     COUNT(*) OVER (PARTITION BY ts.ticket_segment_id) as baggage_count
-- FROM baggage b
-- JOIN ticket_segment ts ON b.ticket_segment_id = ts.ticket_segment_id
-- ORDER BY b.created_at DESC
-- LIMIT 5;
