-- ============================================
-- EJERCICIO 03 - FACTURACIÓN E INTEGRACIÓN
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en invoice_line
-- 3. Procedimiento almacenado para registrar línea facturable
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona venta, factura, estado, líneas, impuestos y moneda

CREATE OR REPLACE VIEW v_invoice_detail AS
SELECT 
    s.sale_id,
    s.sale_code,
    s.sale_date,
    inv.invoice_id,
    inv.invoice_number,
    invs.invoice_status_id,
    invs.status_name AS invoice_status,
    invl.invoice_line_id,
    invl.line_number,
    invl.description,
    invl.quantity,
    invl.unit_price,
    invl.line_total,
    t.tax_id,
    t.tax_code,
    t.tax_rate,
    c.iso_currency_code,
    c.currency_symbol
FROM sale s
INNER JOIN invoice inv ON s.sale_id = inv.sale_id
INNER JOIN invoice_status invs ON inv.invoice_status_id = invs.invoice_status_id
INNER JOIN invoice_line invl ON inv.invoice_id = invl.invoice_id
INNER JOIN tax t ON invl.tax_id = t.tax_id
INNER JOIN currency c ON inv.currency_id = c.currency_id
ORDER BY s.sale_date DESC, invl.line_number;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN INVOICE_LINE
-- ============================================
-- Cuando se registra una línea facturable, actualiza el total de la factura

CREATE OR REPLACE FUNCTION fn_update_invoice_total_on_line()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id uuid;
    v_new_total numeric;
BEGIN
    v_invoice_id := NEW.invoice_id;

    -- Calcular el nuevo total de la factura
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_new_total
    FROM invoice_line
    WHERE invoice_id = v_invoice_id;

    -- Actualizar el total en la factura
    UPDATE invoice
    SET total_amount = v_new_total,
        updated_at = NOW()
    WHERE invoice_id = v_invoice_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_update_invoice_total_on_line ON invoice_line;

-- Crear el trigger
CREATE TRIGGER trg_update_invoice_total_on_line
AFTER INSERT ON invoice_line
FOR EACH ROW
EXECUTE FUNCTION fn_update_invoice_total_on_line();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra una nueva línea facturable en una factura

CREATE OR REPLACE PROCEDURE sp_add_invoice_line(
    p_invoice_id uuid,
    p_description varchar,
    p_quantity numeric,
    p_unit_price numeric,
    p_tax_id uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_invoice_line_id uuid;
    v_line_number smallint;
    v_line_total numeric;
    v_tax_rate numeric;
BEGIN
    -- Validar que la factura existe
    IF NOT EXISTS (SELECT 1 FROM invoice WHERE invoice_id = p_invoice_id) THEN
        RAISE EXCEPTION 'La factura con ID % no existe', p_invoice_id;
    END IF;

    -- Validar que el impuesto existe
    IF NOT EXISTS (SELECT 1 FROM tax WHERE tax_id = p_tax_id) THEN
        RAISE EXCEPTION 'El impuesto con ID % no existe', p_tax_id;
    END IF;

    -- Obtener el número de línea siguiente
    SELECT COALESCE(MAX(line_number), 0) + 1
    INTO v_line_number
    FROM invoice_line
    WHERE invoice_id = p_invoice_id;

    -- Obtener la tasa de impuesto
    SELECT tax_rate INTO v_tax_rate
    FROM tax
    WHERE tax_id = p_tax_id;

    -- Calcular el total de la línea
    v_line_total := p_quantity * p_unit_price * (1 + v_tax_rate / 100);

    -- Registrar la línea facturable
    INSERT INTO invoice_line (
        invoice_id,
        line_number,
        description,
        quantity,
        unit_price,
        tax_id,
        line_total,
        created_at
    )
    VALUES (
        p_invoice_id,
        v_line_number,
        p_description,
        p_quantity,
        p_unit_price,
        p_tax_id,
        v_line_total,
        NOW()
    )
    RETURNING invoice_line_id INTO v_invoice_line_id;

    -- El trigger se encargará de actualizar el total de la factura

    RAISE NOTICE 'Línea facturable registrada. Invoice Line ID: %', v_invoice_line_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver facturas disponibles
SELECT 
    s.sale_code,
    inv.invoice_number,
    invs.status_name,
    COUNT(invl.invoice_line_id) as line_count
FROM v_invoice_detail v
JOIN sale s ON v.sale_id = s.sale_id
JOIN invoice inv ON v.invoice_id = inv.invoice_id
JOIN invoice_status invs ON v.invoice_status_id = invs.invoice_status_id
LEFT JOIN invoice_line invl ON inv.invoice_id = invl.invoice_id
GROUP BY s.sale_code, inv.invoice_number, invs.status_name
LIMIT 5;

-- 2. Obtener datos para la prueba
-- SELECT 
--     inv.invoice_id,
--     inv.invoice_number,
--     t.tax_id,
--     t.tax_code
-- FROM invoice inv
-- JOIN tax t ON t.tax_id = (SELECT tax_id FROM tax LIMIT 1)
-- LIMIT 1;

-- 3. Agregar línea facturable
-- CALL sp_add_invoice_line(
--     p_invoice_id := 'INVOICE_ID_HERE',
--     p_description := 'Servicio de transporte aéreo',
--     p_quantity := 1,
--     p_unit_price := 250.00,
--     p_tax_id := 'TAX_ID_HERE'
-- );

-- 4. Verificar que el total se actualizó
-- SELECT 
--     inv.invoice_number,
--     inv.total_amount,
--     COUNT(invl.invoice_line_id) as line_count
-- FROM invoice inv
-- LEFT JOIN invoice_line invl ON inv.invoice_id = invl.invoice_id
-- WHERE inv.invoice_id = 'INVOICE_ID_HERE'
-- GROUP BY inv.invoice_number, inv.total_amount;
