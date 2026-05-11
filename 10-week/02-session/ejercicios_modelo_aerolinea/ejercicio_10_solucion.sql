-- ============================================
-- EJERCICIO 10 - IDENTIDAD Y DOCUMENTOS DE PASAJEROS
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en person_document o person_contact
-- 3. Procedimiento almacenado para registrar documento o contacto
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona persona, tipo, documentos, contactos y participación en reservas

CREATE OR REPLACE VIEW v_passenger_identity_profile AS
SELECT 
    p.person_id,
    p.first_name,
    p.middle_name,
    p.last_name,
    p.second_last_name,
    p.birth_date,
    p.gender_code,
    pt.person_type_id,
    pt.type_name,
    pd.person_document_id,
    pd.document_number,
    dt.document_type_id,
    dt.type_name AS document_type_name,
    dc.country_name AS issuing_country,
    pd.issued_on,
    pd.expires_on,
    pc.person_contact_id,
    pc.contact_value,
    ct.contact_type_id,
    ct.type_name AS contact_type_name,
    pc.is_primary,
    rp.reservation_passenger_id,
    rp.passenger_sequence,
    r.reservation_id,
    r.reservation_code
FROM person p
INNER JOIN person_type pt ON p.person_type_id = pt.person_type_id
LEFT JOIN person_document pd ON p.person_id = pd.person_id
LEFT JOIN document_type dt ON pd.document_type_id = dt.document_type_id
LEFT JOIN country dc ON pd.issuing_country_id = dc.country_id
LEFT JOIN person_contact pc ON p.person_id = pc.person_id
LEFT JOIN contact_type ct ON pc.contact_type_id = ct.contact_type_id
LEFT JOIN reservation_passenger rp ON p.person_id = rp.person_id
LEFT JOIN reservation r ON rp.reservation_id = r.reservation_id
ORDER BY p.last_name, p.first_name, pd.issued_on DESC;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN PERSON_DOCUMENT
-- ============================================
-- Cuando se registra un documento, valida que no haya duplicados

CREATE OR REPLACE FUNCTION fn_validate_document_uniqueness()
RETURNS TRIGGER AS $$
DECLARE
    v_duplicate_count integer;
BEGIN
    -- Contar documentos con el mismo número y tipo
    SELECT COUNT(*) INTO v_duplicate_count
    FROM person_document
    WHERE person_id != NEW.person_id
    AND document_type_id = NEW.document_type_id
    AND document_number = NEW.document_number
    AND issuing_country_id = NEW.issuing_country_id;

    IF v_duplicate_count > 0 THEN
        RAISE WARNING 'Existe otro documento con el mismo número: %', NEW.document_number;
    END IF;

    RAISE NOTICE 'Documento registrado para persona: %', NEW.person_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_validate_document_uniqueness ON person_document;

-- Crear el trigger
CREATE TRIGGER trg_validate_document_uniqueness
AFTER INSERT ON person_document
FOR EACH ROW
EXECUTE FUNCTION fn_validate_document_uniqueness();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra un nuevo documento para una persona

CREATE OR REPLACE PROCEDURE sp_register_person_document(
    p_person_id uuid,
    p_document_type_id uuid,
    p_issuing_country_id uuid,
    p_document_number varchar,
    p_issued_on date DEFAULT NULL,
    p_expires_on date DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_person_document_id uuid;
BEGIN
    -- Validar que la persona existe
    IF NOT EXISTS (SELECT 1 FROM person WHERE person_id = p_person_id) THEN
        RAISE EXCEPTION 'La persona con ID % no existe', p_person_id;
    END IF;

    -- Validar que el tipo de documento existe
    IF NOT EXISTS (SELECT 1 FROM document_type WHERE document_type_id = p_document_type_id) THEN
        RAISE EXCEPTION 'El tipo de documento con ID % no existe', p_document_type_id;
    END IF;

    -- Validar que el país existe
    IF NOT EXISTS (SELECT 1 FROM country WHERE country_id = p_issuing_country_id) THEN
        RAISE EXCEPTION 'El país con ID % no existe', p_issuing_country_id;
    END IF;

    -- Validar que no exista documento duplicado
    IF EXISTS (
        SELECT 1 FROM person_document
        WHERE person_id = p_person_id
        AND document_type_id = p_document_type_id
        AND document_number = p_document_number
    ) THEN
        RAISE EXCEPTION 'Este documento ya está registrado para la persona';
    END IF;

    -- Validar fechas si ambas se proporcionan
    IF p_issued_on IS NOT NULL AND p_expires_on IS NOT NULL 
       AND p_expires_on < p_issued_on THEN
        RAISE EXCEPTION 'La fecha de vencimiento no puede ser anterior a la de emisión';
    END IF;

    -- Registrar el documento
    INSERT INTO person_document (
        person_id,
        document_type_id,
        issuing_country_id,
        document_number,
        issued_on,
        expires_on,
        created_at
    )
    VALUES (
        p_person_id,
        p_document_type_id,
        p_issuing_country_id,
        p_document_number,
        p_issued_on,
        p_expires_on,
        NOW()
    )
    RETURNING person_document_id INTO v_person_document_id;

    -- El trigger se encargará de validar unicidad

    RAISE NOTICE 'Documento registrado exitosamente. Document ID: %', v_person_document_id;
END;
$$;


-- ============================================
-- PROCEDIMIENTO ADICIONAL - REGISTRAR CONTACTO
-- ============================================
-- Registra un nuevo contacto para una persona

CREATE OR REPLACE PROCEDURE sp_register_person_contact(
    p_person_id uuid,
    p_contact_type_id uuid,
    p_contact_value varchar,
    p_is_primary boolean DEFAULT false
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_person_contact_id uuid;
BEGIN
    -- Validar que la persona existe
    IF NOT EXISTS (SELECT 1 FROM person WHERE person_id = p_person_id) THEN
        RAISE EXCEPTION 'La persona con ID % no existe', p_person_id;
    END IF;

    -- Validar que el tipo de contacto existe
    IF NOT EXISTS (SELECT 1 FROM contact_type WHERE contact_type_id = p_contact_type_id) THEN
        RAISE EXCEPTION 'El tipo de contacto con ID % no existe', p_contact_type_id;
    END IF;

    -- Registrar el contacto
    INSERT INTO person_contact (
        person_id,
        contact_type_id,
        contact_value,
        is_primary,
        created_at
    )
    VALUES (
        p_person_id,
        p_contact_type_id,
        p_contact_value,
        p_is_primary,
        NOW()
    )
    RETURNING person_contact_id INTO v_person_contact_id;

    RAISE NOTICE 'Contacto registrado exitosamente. Contact ID: %', v_person_contact_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver perfiles de identidad de pasajeros
SELECT 
    p.first_name,
    p.last_name,
    p.birth_date,
    pt.type_name,
    pd.document_number,
    dt.type_name AS document_type,
    pc.contact_value,
    ct.type_name AS contact_type,
    r.reservation_code
FROM v_passenger_identity_profile v
JOIN person p ON v.person_id = p.person_id
JOIN person_type pt ON v.person_type_id = pt.person_type_id
LEFT JOIN person_document pd ON v.person_document_id = pd.person_document_id
LEFT JOIN document_type dt ON v.document_type_id = dt.document_type_id
LEFT JOIN person_contact pc ON v.person_contact_id = pc.person_contact_id
LEFT JOIN contact_type ct ON v.contact_type_id = ct.contact_type_id
LEFT JOIN reservation r ON v.reservation_id = r.reservation_id
LIMIT 10;

-- 2. Obtener datos para la prueba
-- SELECT 
--     p.person_id,
--     p.first_name,
--     p.last_name,
--     dt.document_type_id,
--     dc.country_id,
--     ct.contact_type_id
-- FROM person p
-- CROSS JOIN document_type dt
-- CROSS JOIN (SELECT country_id FROM country LIMIT 1) dc
-- CROSS JOIN contact_type ct
-- LIMIT 1;

-- 3. Registrar un documento
-- CALL sp_register_person_document(
--     p_person_id := 'PERSON_ID_HERE',
--     p_document_type_id := 'DOCUMENT_TYPE_ID_HERE',
--     p_issuing_country_id := 'COUNTRY_ID_HERE',
--     p_document_number := 'PA123456789',
--     p_issued_on := '2020-01-15',
--     p_expires_on := '2030-01-15'
-- );

-- 4. Registrar un contacto
-- CALL sp_register_person_contact(
--     p_person_id := 'PERSON_ID_HERE',
--     p_contact_type_id := 'CONTACT_TYPE_ID_HERE',
--     p_contact_value := 'passenger@example.com',
--     p_is_primary := true
-- );

-- 5. Verificar el perfil de identidad
-- SELECT 
--     p.first_name,
--     p.last_name,
--     STRING_AGG(DISTINCT pd.document_number, ', ') as documents,
--     STRING_AGG(DISTINCT pc.contact_value, ', ') as contacts
-- FROM person p
-- LEFT JOIN person_document pd ON p.person_id = pd.person_id
-- LEFT JOIN person_contact pc ON p.person_id = pc.person_id
-- WHERE p.person_id = 'PERSON_ID_HERE'
-- GROUP BY p.person_id, p.first_name, p.last_name;
