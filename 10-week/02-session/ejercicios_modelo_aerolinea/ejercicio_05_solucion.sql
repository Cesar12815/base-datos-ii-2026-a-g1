-- ============================================
-- EJERCICIO 05 - MANTENIMIENTO DE AERONAVES
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en maintenance_event
-- 3. Procedimiento almacenado para registrar evento de mantenimiento
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona aeronave, aerolínea, modelo, fabricante, tipo y proveedor de mantenimiento

CREATE OR REPLACE VIEW v_aircraft_maintenance_history AS
SELECT 
    ac.aircraft_id,
    ac.registration_number,
    al.airline_id,
    al.airline_code,
    al.airline_name,
    acm.aircraft_model_id,
    acm.model_name,
    acmf.aircraft_manufacturer_id,
    acmf.manufacturer_name,
    me.maintenance_event_id,
    me.event_start_date,
    me.event_end_date,
    mt.maintenance_type_id,
    mt.type_code,
    mt.type_name,
    mp.maintenance_provider_id,
    mp.provider_name,
    mp.phone_number
FROM aircraft ac
INNER JOIN airline al ON ac.airline_id = al.airline_id
INNER JOIN aircraft_model acm ON ac.aircraft_model_id = acm.aircraft_model_id
INNER JOIN aircraft_manufacturer acmf ON acm.aircraft_manufacturer_id = acmf.aircraft_manufacturer_id
INNER JOIN maintenance_event me ON ac.aircraft_id = me.aircraft_id
INNER JOIN maintenance_type mt ON me.maintenance_type_id = mt.maintenance_type_id
INNER JOIN maintenance_provider mp ON me.maintenance_provider_id = mp.maintenance_provider_id
ORDER BY ac.registration_number, me.event_start_date DESC;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN MAINTENANCE_EVENT
-- ============================================
-- Cuando se registra un evento de mantenimiento, crea un registro de auditoría

CREATE OR REPLACE FUNCTION fn_audit_maintenance_event()
RETURNS TRIGGER AS $$
DECLARE
    v_audit_log_exists boolean;
BEGIN
    -- Aquí podríamos crear una tabla de auditoría o actualizar un contador
    -- Por ahora solo registramos el evento de forma segura
    
    -- Si hubiera una tabla audit_log:
    -- INSERT INTO audit_log (
    --     table_name, operation, record_id, old_values, new_values, created_at
    -- ) VALUES (
    --     'maintenance_event', 'INSERT', NEW.maintenance_event_id, NULL, 
    --     row_to_json(NEW), NOW()
    -- );

    RAISE NOTICE 'Evento de mantenimiento registrado para aeronave: %', NEW.aircraft_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_audit_maintenance_event ON maintenance_event;

-- Crear el trigger
CREATE TRIGGER trg_audit_maintenance_event
AFTER INSERT ON maintenance_event
FOR EACH ROW
EXECUTE FUNCTION fn_audit_maintenance_event();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Registra un nuevo evento de mantenimiento para una aeronave

CREATE OR REPLACE PROCEDURE sp_register_maintenance_event(
    p_aircraft_id uuid,
    p_maintenance_type_id uuid,
    p_maintenance_provider_id uuid,
    p_event_start_date timestamp DEFAULT NULL,
    p_notes varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_maintenance_event_id uuid;
BEGIN
    -- Validar que la aeronave existe
    IF NOT EXISTS (SELECT 1 FROM aircraft WHERE aircraft_id = p_aircraft_id) THEN
        RAISE EXCEPTION 'La aeronave con ID % no existe', p_aircraft_id;
    END IF;

    -- Validar que el tipo de mantenimiento existe
    IF NOT EXISTS (SELECT 1 FROM maintenance_type WHERE maintenance_type_id = p_maintenance_type_id) THEN
        RAISE EXCEPTION 'El tipo de mantenimiento con ID % no existe', p_maintenance_type_id;
    END IF;

    -- Validar que el proveedor existe
    IF NOT EXISTS (SELECT 1 FROM maintenance_provider WHERE maintenance_provider_id = p_maintenance_provider_id) THEN
        RAISE EXCEPTION 'El proveedor con ID % no existe', p_maintenance_provider_id;
    END IF;

    -- Usar la fecha actual si no se proporciona
    IF p_event_start_date IS NULL THEN
        p_event_start_date := NOW();
    END IF;

    -- Registrar el evento de mantenimiento
    INSERT INTO maintenance_event (
        aircraft_id,
        maintenance_type_id,
        maintenance_provider_id,
        event_start_date,
        notes,
        created_at
    )
    VALUES (
        p_aircraft_id,
        p_maintenance_type_id,
        p_maintenance_provider_id,
        p_event_start_date,
        p_notes,
        NOW()
    )
    RETURNING maintenance_event_id INTO v_maintenance_event_id;

    -- El trigger se encargará de auditar el evento

    RAISE NOTICE 'Evento de mantenimiento registrado. Event ID: %', v_maintenance_event_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver historial de mantenimiento
SELECT 
    ac.registration_number,
    al.airline_code,
    acm.model_name,
    mt.type_name,
    mp.provider_name,
    me.event_start_date,
    me.event_end_date
FROM v_aircraft_maintenance_history v
JOIN aircraft ac ON v.aircraft_id = ac.aircraft_id
JOIN airline al ON v.airline_id = al.airline_id
JOIN aircraft_model acm ON v.aircraft_model_id = acm.aircraft_model_id
JOIN maintenance_type mt ON v.maintenance_type_id = mt.maintenance_type_id
JOIN maintenance_provider mp ON v.maintenance_provider_id = mp.maintenance_provider_id
JOIN maintenance_event me ON v.maintenance_event_id = me.maintenance_event_id
LIMIT 5;

-- 2. Obtener datos para la prueba
-- SELECT 
--     ac.aircraft_id,
--     ac.registration_number,
--     mt.maintenance_type_id,
--     mp.maintenance_provider_id
-- FROM aircraft ac
-- JOIN maintenance_type mt ON mt.maintenance_type_id = (SELECT maintenance_type_id FROM maintenance_type LIMIT 1)
-- JOIN maintenance_provider mp ON mp.maintenance_provider_id = (SELECT maintenance_provider_id FROM maintenance_provider LIMIT 1)
-- LIMIT 1;

-- 3. Registrar un evento de mantenimiento
-- CALL sp_register_maintenance_event(
--     p_aircraft_id := 'AIRCRAFT_ID_HERE',
--     p_maintenance_type_id := 'MAINTENANCE_TYPE_ID_HERE',
--     p_maintenance_provider_id := 'MAINTENANCE_PROVIDER_ID_HERE',
--     p_notes := 'Mantenimiento preventivo regular'
-- );

-- 4. Verificar que se registró
-- SELECT 
--     me.maintenance_event_id,
--     me.event_start_date,
--     mt.type_name,
--     mp.provider_name
-- FROM maintenance_event me
-- JOIN maintenance_type mt ON me.maintenance_type_id = mt.maintenance_type_id
-- JOIN maintenance_provider mp ON me.maintenance_provider_id = mp.maintenance_provider_id
-- ORDER BY me.created_at DESC
-- LIMIT 1;
