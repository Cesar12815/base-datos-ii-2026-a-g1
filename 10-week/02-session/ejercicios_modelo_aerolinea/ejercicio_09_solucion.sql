-- ============================================
-- EJERCICIO 09 - PUBLICACIÓN DE TARIFAS Y ANÁLISIS
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en fare
-- 3. Procedimiento almacenado para registrar tarifa
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona aerolínea, tarifa, clase, aeropuertos, moneda, reservas y tiquetes

CREATE OR REPLACE VIEW v_fare_commercialization AS
SELECT 
    al.airline_id,
    al.airline_code,
    al.airline_name,
    f.fare_id,
    f.fare_code,
    f.base_fare_amount,
    fc.fare_class_id,
    fc.class_code,
    fc.class_name,
    a_origin.airport_id AS origin_id,
    a_origin.airport_code AS origin_code,
    a_origin.airport_name AS origin_name,
    a_dest.airport_id AS destination_id,
    a_dest.airport_code AS destination_code,
    a_dest.airport_name AS destination_name,
    c.iso_currency_code,
    c.currency_symbol,
    r.reservation_id,
    r.reservation_code,
    s.sale_id,
    s.sale_code,
    t.ticket_id,
    t.ticket_number
FROM airline al
INNER JOIN fare f ON al.airline_id = f.airline_id
INNER JOIN fare_class fc ON f.fare_class_id = fc.fare_class_id
INNER JOIN airport a_origin ON f.origin_airport_id = a_origin.airport_id
INNER JOIN airport a_dest ON f.destination_airport_id = a_dest.airport_id
INNER JOIN currency c ON f.currency_id = c.currency_id
LEFT JOIN reservation r ON f.airline_id = r.airline_id
LEFT JOIN sale s ON r.reservation_id = s.reservation_id
LEFT JOIN ticket t ON s.sale_id = t.sale_id
ORDER BY f.fare_code, r.reservation_code;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN FARE
-- ============================================
-- Cuando se publica una tarifa, actualiza estadísticas de disponibilidad

CREATE OR REPLACE FUNCTION fn_record_fare_publication()
RETURNS TRIGGER AS $$
DECLARE
    v_airline_id uuid;
BEGIN
    v_airline_id := NEW.airline_id;

    -- Aquí se podría actualizar una tabla de estadísticas
    -- INSERT INTO fare_publication_stats (
    --     airline_id, fare_count, last_publication_date, created_at
    -- ) VALUES (
    --     v_airline_id,
    --     (SELECT COUNT(*) FROM fare WHERE airline_id = v_airline_id),
    --     NOW(),
    --     NOW()
    -- )
    -- ON CONFLICT (airline_id) DO UPDATE SET
    --     fare_count = EXCLUDED.fare_count,
    --     last_publication_date = NOW();

    RAISE NOTICE 'Tarifa % publicada para aerolínea %', NEW.fare_code, v_airline_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_record_fare_publication ON fare;

-- Crear el trigger
CREATE TRIGGER trg_record_fare_publication
AFTER INSERT ON fare
FOR EACH ROW
EXECUTE FUNCTION fn_record_fare_publication();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra una tarifa para una ruta y clase específica

CREATE OR REPLACE PROCEDURE sp_publish_fare(
    p_airline_id uuid,
    p_origin_airport_id uuid,
    p_destination_airport_id uuid,
    p_fare_class_id uuid,
    p_currency_id uuid,
    p_base_fare_amount numeric,
    p_fare_code varchar DEFAULT NULL,
    p_effective_date date DEFAULT NULL,
    p_expiration_date date DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fare_id uuid;
    v_fare_code varchar;
BEGIN
    -- Validar que la aerolínea existe
    IF NOT EXISTS (SELECT 1 FROM airline WHERE airline_id = p_airline_id) THEN
        RAISE EXCEPTION 'La aerolínea con ID % no existe', p_airline_id;
    END IF;

    -- Validar que los aeropuertos existen
    IF NOT EXISTS (SELECT 1 FROM airport WHERE airport_id = p_origin_airport_id) THEN
        RAISE EXCEPTION 'El aeropuerto de origen con ID % no existe', p_origin_airport_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM airport WHERE airport_id = p_destination_airport_id) THEN
        RAISE EXCEPTION 'El aeropuerto de destino con ID % no existe', p_destination_airport_id;
    END IF;

    -- Validar que la clase tarifaria existe
    IF NOT EXISTS (SELECT 1 FROM fare_class WHERE fare_class_id = p_fare_class_id) THEN
        RAISE EXCEPTION 'La clase tarifaria con ID % no existe', p_fare_class_id;
    END IF;

    -- Validar que la moneda existe
    IF NOT EXISTS (SELECT 1 FROM currency WHERE currency_id = p_currency_id) THEN
        RAISE EXCEPTION 'La moneda con ID % no existe', p_currency_id;
    END IF;

    -- Validar monto positivo
    IF p_base_fare_amount <= 0 THEN
        RAISE EXCEPTION 'El monto de la tarifa debe ser mayor a 0';
    END IF;

    -- Generar código de tarifa si no se proporciona
    IF p_fare_code IS NULL THEN
        v_fare_code := 'FAR-' || SUBSTRING(p_airline_id::varchar, 1, 8) || '-' || 
                      EXTRACT(EPOCH FROM NOW())::text;
    ELSE
        v_fare_code := p_fare_code;
    END IF;

    -- Registrar la tarifa
    INSERT INTO fare (
        airline_id,
        origin_airport_id,
        destination_airport_id,
        fare_class_id,
        currency_id,
        fare_code,
        base_fare_amount,
        effective_date,
        expiration_date,
        created_at
    )
    VALUES (
        p_airline_id,
        p_origin_airport_id,
        p_destination_airport_id,
        p_fare_class_id,
        p_currency_id,
        v_fare_code,
        p_base_fare_amount,
        p_effective_date,
        p_expiration_date,
        NOW()
    )
    RETURNING fare_id INTO v_fare_id;

    -- El trigger se encargará de registrar la publicación

    RAISE NOTICE 'Tarifa publicada exitosamente. Fare ID: %, Code: %', v_fare_id, v_fare_code;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver tarifas y su comercialización
SELECT 
    al.airline_code,
    a_origin.airport_code AS origin,
    a_dest.airport_code AS destination,
    fc.class_code,
    f.base_fare_amount,
    c.currency_symbol,
    COUNT(DISTINCT t.ticket_id) as tickets_sold
FROM v_fare_commercialization v
JOIN airline al ON v.airline_id = al.airline_id
JOIN airport a_origin ON v.origin_id = a_origin.airport_id
JOIN airport a_dest ON v.destination_id = a_dest.airport_id
JOIN fare_class fc ON v.fare_class_id = fc.fare_class_id
JOIN fare f ON v.fare_id = f.fare_id
JOIN currency c ON v.currency_code = c.iso_currency_code
LEFT JOIN ticket t ON v.ticket_id = t.ticket_id
GROUP BY al.airline_code, a_origin.airport_code, a_dest.airport_code, 
         fc.class_code, f.base_fare_amount, c.currency_symbol
LIMIT 10;

-- 2. Obtener datos para la prueba
-- SELECT 
--     al.airline_id,
--     a_origin.airport_id,
--     a_dest.airport_id,
--     fc.fare_class_id,
--     c.currency_id
-- FROM airline al
-- CROSS JOIN airport a_origin
-- CROSS JOIN airport a_dest
-- CROSS JOIN fare_class fc
-- CROSS JOIN currency c
-- WHERE a_origin.airport_id != a_dest.airport_id
-- LIMIT 1;

-- 3. Publicar una nueva tarifa
-- CALL sp_publish_fare(
--     p_airline_id := 'AIRLINE_ID_HERE',
--     p_origin_airport_id := 'ORIGIN_AIRPORT_ID_HERE',
--     p_destination_airport_id := 'DESTINATION_AIRPORT_ID_HERE',
--     p_fare_class_id := 'FARE_CLASS_ID_HERE',
--     p_currency_id := 'CURRENCY_ID_HERE',
--     p_base_fare_amount := 299.99,
--     p_effective_date := CURRENT_DATE,
--     p_expiration_date := CURRENT_DATE + INTERVAL '90 days'
-- );

-- 4. Verificar publicación
-- SELECT 
--     f.fare_code,
--     f.base_fare_amount,
--     c.currency_symbol,
--     a_origin.airport_code,
--     a_dest.airport_code,
--     f.effective_date,
--     f.expiration_date
-- FROM fare f
-- JOIN airport a_origin ON f.origin_airport_id = a_origin.airport_id
-- JOIN airport a_dest ON f.destination_airport_id = a_dest.airport_id
-- JOIN currency c ON f.currency_id = c.currency_id
-- ORDER BY f.created_at DESC
-- LIMIT 1;
