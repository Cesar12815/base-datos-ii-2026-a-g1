-- ============================================
-- EJERCICIO 02 - CONTROL DE PAGOS Y TRANSACCIONES
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en payment_transaction
-- 3. Procedimiento almacenado para registrar transacción
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Consolida información de venta, pago, estado, método, transacción y moneda

CREATE OR REPLACE VIEW v_payment_transaction_flow AS
SELECT 
    s.sale_id,
    s.sale_code,
    s.sale_date,
    r.reservation_id,
    r.reservation_code,
    p.payment_id,
    p.amount AS payment_amount,
    ps.payment_status_id,
    ps.status_name AS payment_status,
    pm.payment_method_id,
    pm.method_name,
    pt.payment_transaction_id,
    pt.transaction_reference,
    pt.amount AS transaction_amount,
    pt.transaction_type,
    pt.transaction_date,
    c.iso_currency_code,
    c.currency_symbol
FROM sale s
INNER JOIN reservation r ON s.reservation_id = r.reservation_id
INNER JOIN payment p ON s.sale_id = p.sale_id
INNER JOIN payment_status ps ON p.payment_status_id = ps.payment_status_id
INNER JOIN payment_method pm ON p.payment_method_id = pm.payment_method_id
INNER JOIN payment_transaction pt ON p.payment_id = pt.payment_id
INNER JOIN currency c ON p.currency_id = c.currency_id
ORDER BY s.sale_date DESC, p.created_at DESC;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN PAYMENT_TRANSACTION
-- ============================================
-- Cuando se registra una transacción, se crea automáticamente un registro de devolución si es reversión

CREATE OR REPLACE FUNCTION fn_create_refund_on_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_payment_id uuid;
    v_refund_status_id uuid;
BEGIN
    -- Solo procesar si la transacción es de reversión/reembolso
    IF NEW.transaction_type = 'REVERSAL' OR NEW.transaction_type = 'REFUND' THEN
        
        -- Obtener el payment_id asociado
        SELECT payment_id INTO v_payment_id
        FROM payment_transaction
        WHERE payment_transaction_id = NEW.payment_transaction_id;

        -- Obtener el estado de reembolso
        SELECT refund_status_id INTO v_refund_status_id
        FROM refund_status
        WHERE status_code = 'INITIATED'
        LIMIT 1;

        -- Si no existe, usar el primero disponible
        IF v_refund_status_id IS NULL THEN
            SELECT refund_status_id INTO v_refund_status_id
            FROM refund_status
            LIMIT 1;
        END IF;

        -- Crear registro de devolución
        INSERT INTO refund (
            payment_id,
            refund_status_id,
            refund_amount,
            refund_date,
            reason_code,
            notes
        )
        VALUES (
            v_payment_id,
            v_refund_status_id,
            NEW.amount,
            NOW(),
            'AUTO_REVERSAL',
            'Devolución automática por transacción de reversión'
        );

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_create_refund_on_transaction ON payment_transaction;

-- Crear el trigger
CREATE TRIGGER trg_create_refund_on_transaction
AFTER INSERT ON payment_transaction
FOR EACH ROW
EXECUTE FUNCTION fn_create_refund_on_transaction();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra una transacción financiera sobre un pago existente

CREATE OR REPLACE PROCEDURE sp_record_payment_transaction(
    p_payment_id uuid,
    p_transaction_type varchar,
    p_amount numeric,
    p_transaction_reference varchar,
    p_provider_message varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_payment_transaction_id uuid;
BEGIN
    -- Validar que el pago exista
    IF NOT EXISTS (SELECT 1 FROM payment WHERE payment_id = p_payment_id) THEN
        RAISE EXCEPTION 'El pago con ID % no existe', p_payment_id;
    END IF;

    -- Validar tipos de transacción válidos
    IF p_transaction_type NOT IN ('AUTHORIZATION', 'CAPTURE', 'REVERSAL', 'REFUND') THEN
        RAISE EXCEPTION 'Tipo de transacción % no válido', p_transaction_type;
    END IF;

    -- Validar monto positivo
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto debe ser mayor a 0';
    END IF;

    -- Registrar la transacción
    INSERT INTO payment_transaction (
        payment_id,
        transaction_type,
        amount,
        transaction_reference,
        provider_message,
        transaction_date,
        created_at
    )
    VALUES (
        p_payment_id,
        p_transaction_type,
        p_amount,
        p_transaction_reference,
        p_provider_message,
        NOW(),
        NOW()
    )
    RETURNING payment_transaction_id INTO v_payment_transaction_id;

    -- El trigger se encargará de crear el refund si aplica

    RAISE NOTICE 'Transacción registrada exitosamente. Transaction ID: %', v_payment_transaction_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- Nota: Ejecutar solo después de tener datos de prueba en la BD

-- 1. Ver el flujo de pagos disponibles
SELECT 
    s.sale_code,
    r.reservation_code,
    p.payment_id,
    p.amount,
    ps.status_name
FROM v_payment_transaction_flow v
JOIN sale s ON v.sale_id = s.sale_id
JOIN reservation r ON v.reservation_id = r.reservation_id
JOIN payment p ON v.payment_id = p.payment_id
JOIN payment_status ps ON v.payment_status_id = ps.payment_status_id
LIMIT 5;

-- 2. Obtener datos para la prueba
-- SELECT 
--     p.payment_id,
--     p.amount,
--     s.sale_code
-- FROM payment p
-- JOIN sale s ON p.sale_id = s.sale_id
-- LIMIT 1;

-- 3. Registrar una transacción de captura
-- CALL sp_record_payment_transaction(
--     p_payment_id := 'PAYMENT_ID_HERE',
--     p_transaction_type := 'CAPTURE',
--     p_amount := 100.00,
--     p_transaction_reference := 'TXN-20260416-001',
--     p_provider_message := 'Transaction successful'
-- );

-- 4. Registrar una reversión (esto disparará el trigger para crear un refund)
-- CALL sp_record_payment_transaction(
--     p_payment_id := 'PAYMENT_ID_HERE',
--     p_transaction_type := 'REVERSAL',
--     p_amount := 100.00,
--     p_transaction_reference := 'REV-20260416-001',
--     p_provider_message := 'Reversal successful'
-- );

-- 5. Verificar que se crearon los refunds
-- SELECT 
--     r.refund_id,
--     r.refund_amount,
--     r.reason_code,
--     r.refund_date,
--     rs.status_name
-- FROM refund r
-- JOIN refund_status rs ON r.refund_status_id = rs.refund_status_id
-- ORDER BY r.refund_date DESC
-- LIMIT 1;
