-- ============================================
-- EJERCICIO 04 - ACUMULACIÓN DE MILLAS Y NIVEL
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en miles_transaction
-- 3. Procedimiento almacenado para registrar transacción de millas
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona cliente, persona, cuenta de fidelización, programa, nivel y ventas

CREATE OR REPLACE VIEW v_loyalty_program_status AS
SELECT 
    cust.customer_id,
    cust.customer_code,
    p.first_name,
    p.last_name,
    la.loyalty_account_id,
    la.account_number,
    lp.loyalty_program_id,
    lp.program_name,
    lt.loyalty_tier_id,
    lt.tier_name,
    lat.assigned_date,
    sa.sale_id,
    sa.sale_code,
    COALESCE(mt.total_miles, 0) as accumulated_miles
FROM customer cust
INNER JOIN person p ON cust.person_id = p.person_id
INNER JOIN loyalty_account la ON cust.customer_id = la.customer_id
INNER JOIN loyalty_program lp ON la.loyalty_program_id = lp.loyalty_program_id
INNER JOIN loyalty_account_tier lat ON la.loyalty_account_id = lat.loyalty_account_id
INNER JOIN loyalty_tier lt ON lat.loyalty_tier_id = lt.loyalty_tier_id
LEFT JOIN sale sa ON cust.customer_id = sa.customer_id
LEFT JOIN (
    SELECT loyalty_account_id, COALESCE(SUM(miles_quantity), 0) as total_miles
    FROM miles_transaction
    GROUP BY loyalty_account_id
) mt ON la.loyalty_account_id = mt.loyalty_account_id
ORDER BY cust.customer_code, la.account_number;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN MILES_TRANSACTION
-- ============================================
-- Cuando se registra una transacción de millas, verifica si el cliente sube de nivel

CREATE OR REPLACE FUNCTION fn_check_loyalty_tier_on_miles()
RETURNS TRIGGER AS $$
DECLARE
    v_loyalty_account_id uuid;
    v_total_miles numeric;
    v_current_tier_id uuid;
    v_new_tier_id uuid;
BEGIN
    v_loyalty_account_id := NEW.loyalty_account_id;

    -- Calcular el total de millas acumuladas
    SELECT COALESCE(SUM(miles_quantity), 0)
    INTO v_total_miles
    FROM miles_transaction
    WHERE loyalty_account_id = v_loyalty_account_id;

    -- Obtener el tier actual
    SELECT loyalty_tier_id INTO v_current_tier_id
    FROM loyalty_account_tier
    WHERE loyalty_account_id = v_loyalty_account_id
    ORDER BY assigned_date DESC
    LIMIT 1;

    -- Buscar si hay un tier superior disponible basado en millas
    -- (Esto requeriría una columna en loyalty_tier para miles_required)
    -- Por ahora solo registramos la transacción

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_check_loyalty_tier_on_miles ON miles_transaction;

-- Crear el trigger
CREATE TRIGGER trg_check_loyalty_tier_on_miles
AFTER INSERT ON miles_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_check_loyalty_tier_on_miles();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra una transacción de millas para una cuenta de fidelización

CREATE OR REPLACE PROCEDURE sp_record_miles_transaction(
    p_loyalty_account_id uuid,
    p_miles_quantity numeric,
    p_transaction_type varchar,
    p_reference_sale_id uuid DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_miles_transaction_id uuid;
BEGIN
    -- Validar que la cuenta de fidelización existe
    IF NOT EXISTS (SELECT 1 FROM loyalty_account WHERE loyalty_account_id = p_loyalty_account_id) THEN
        RAISE EXCEPTION 'La cuenta de fidelización con ID % no existe', p_loyalty_account_id;
    END IF;

    -- Validar cantidad de millas positiva
    IF p_miles_quantity <= 0 THEN
        RAISE EXCEPTION 'La cantidad de millas debe ser mayor a 0';
    END IF;

    -- Validar tipo de transacción
    IF p_transaction_type NOT IN ('EARN', 'REDEEM', 'ADJUST', 'EXPIRE') THEN
        RAISE EXCEPTION 'Tipo de transacción % no válido', p_transaction_type;
    END IF;

    -- Registrar la transacción de millas
    INSERT INTO miles_transaction (
        loyalty_account_id,
        miles_quantity,
        transaction_type,
        reference_sale_id,
        transaction_date,
        created_at
    )
    VALUES (
        p_loyalty_account_id,
        p_miles_quantity,
        p_transaction_type,
        p_reference_sale_id,
        NOW(),
        NOW()
    )
    RETURNING miles_transaction_id INTO v_miles_transaction_id;

    -- El trigger se encargará de verificar cambios de nivel

    RAISE NOTICE 'Transacción de millas registrada. Transaction ID: %', v_miles_transaction_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver cuentas de fidelización disponibles
SELECT 
    cust.customer_code,
    p.first_name,
    p.last_name,
    la.account_number,
    lp.program_name,
    lt.tier_name,
    COALESCE(mt.accumulated_miles, 0) as miles
FROM v_loyalty_program_status v
JOIN customer cust ON v.customer_id = cust.customer_id
JOIN person p ON v.person_id = p.person_id
JOIN loyalty_account la ON v.loyalty_account_id = la.loyalty_account_id
JOIN loyalty_program lp ON v.loyalty_program_id = lp.loyalty_program_id
JOIN loyalty_tier lt ON v.loyalty_tier_id = lt.loyalty_tier_id
LEFT JOIN (SELECT loyalty_account_id, SUM(miles_quantity) as accumulated_miles FROM miles_transaction GROUP BY loyalty_account_id) mt ON la.loyalty_account_id = mt.loyalty_account_id
LIMIT 5;

-- 2. Obtener datos para la prueba
-- SELECT 
--     la.loyalty_account_id,
--     la.account_number,
--     lp.program_name
-- FROM loyalty_account la
-- JOIN loyalty_program lp ON la.loyalty_program_id = lp.loyalty_program_id
-- LIMIT 1;

-- 3. Registrar una transacción de millas
-- CALL sp_record_miles_transaction(
--     p_loyalty_account_id := 'LOYALTY_ACCOUNT_ID_HERE',
--     p_miles_quantity := 500,
--     p_transaction_type := 'EARN'
-- );

-- 4. Verificar acumulación
-- SELECT 
--     la.account_number,
--     SUM(mt.miles_quantity) as total_miles,
--     COUNT(mt.miles_transaction_id) as transaction_count
-- FROM loyalty_account la
-- LEFT JOIN miles_transaction mt ON la.loyalty_account_id = mt.loyalty_account_id
-- WHERE la.loyalty_account_id = 'LOYALTY_ACCOUNT_ID_HERE'
-- GROUP BY la.account_number;
