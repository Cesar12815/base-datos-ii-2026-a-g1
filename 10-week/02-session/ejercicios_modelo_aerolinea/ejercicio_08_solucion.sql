-- ============================================
-- EJERCICIO 08 - AUDITORÍA Y ASIGNACIÓN DE ROLES
-- ============================================
-- Este archivo contiene:
-- 1. Consulta multi-tabla (INNER JOIN 5+ tablas)
-- 2. Trigger AFTER INSERT en user_role
-- 3. Procedimiento almacenado para asignar rol a usuario
-- 4. Script de prueba

-- ============================================
-- REQUERIMIENTO 1: CONSULTA CON INNER JOIN
-- ============================================
-- Relaciona persona, usuario, estado, roles y permisos asociados

CREATE OR REPLACE VIEW v_user_role_authorization AS
SELECT 
    p.person_id,
    p.first_name,
    p.last_name,
    ua.user_account_id,
    ua.username,
    ua.email,
    us.user_status_id,
    us.status_name,
    ur.user_role_id,
    ur.assigned_date,
    sr.security_role_id,
    sr.role_code,
    sr.role_name,
    sp.security_permission_id,
    sp.permission_code,
    sp.permission_description
FROM person p
INNER JOIN user_account ua ON p.person_id = ua.person_id
INNER JOIN user_status us ON ua.user_status_id = us.user_status_id
INNER JOIN user_role ur ON ua.user_account_id = ur.user_account_id
INNER JOIN security_role sr ON ur.security_role_id = sr.security_role_id
INNER JOIN role_permission rp ON sr.security_role_id = rp.security_role_id
INNER JOIN security_permission sp ON rp.security_permission_id = sp.security_permission_id
ORDER BY p.last_name, p.first_name, sr.role_code;


-- ============================================
-- REQUERIMIENTO 2: TRIGGER AFTER INSERT EN USER_ROLE
-- ============================================
-- Cuando se asigna un rol, se crea un registro de auditoría

CREATE OR REPLACE FUNCTION fn_audit_user_role_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_user_account_id uuid;
    v_username varchar;
    v_role_name varchar;
BEGIN
    -- Obtener información del usuario y rol
    SELECT ua.username, ua.user_account_id INTO v_username, v_user_account_id
    FROM user_account ua
    WHERE ua.user_account_id = NEW.user_account_id;

    SELECT sr.role_name INTO v_role_name
    FROM security_role sr
    WHERE sr.security_role_id = NEW.security_role_id;

    -- Aquí se podría insertar en una tabla de auditoría
    -- INSERT INTO security_audit_log (
    --     event_type, user_account_id, details, created_at
    -- ) VALUES (
    --     'ROLE_ASSIGNED', NEW.user_account_id,
    --     'Usuario ' || v_username || ' asignado al rol ' || v_role_name,
    --     NOW()
    -- );

    RAISE NOTICE 'Rol % asignado a usuario %', v_role_name, v_username;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Si el trigger existe, eliminarlo
DROP TRIGGER IF EXISTS trg_audit_user_role_assignment ON user_role;

-- Crear el trigger
CREATE TRIGGER trg_audit_user_role_assignment
AFTER INSERT ON user_role
FOR EACH ROW
EXECUTE FUNCTION fn_audit_user_role_assignment();


-- ============================================
-- REQUERIMIENTO 3: PROCEDIMIENTO ALMACENADO
-- ============================================
-- Asigna un rol a un usuario existente

CREATE OR REPLACE PROCEDURE sp_assign_role_to_user(
    p_user_account_id uuid,
    p_security_role_id uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_role_id uuid;
    v_username varchar;
    v_role_name varchar;
    v_role_exists boolean;
BEGIN
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM user_account WHERE user_account_id = p_user_account_id) THEN
        RAISE EXCEPTION 'El usuario con ID % no existe', p_user_account_id;
    END IF;

    -- Validar que el rol existe
    IF NOT EXISTS (SELECT 1 FROM security_role WHERE security_role_id = p_security_role_id) THEN
        RAISE EXCEPTION 'El rol con ID % no existe', p_security_role_id;
    END IF;

    -- Verificar que el rol no está ya asignado
    SELECT EXISTS(
        SELECT 1 FROM user_role
        WHERE user_account_id = p_user_account_id
        AND security_role_id = p_security_role_id
    ) INTO v_role_exists;

    IF v_role_exists THEN
        RAISE EXCEPTION 'El rol ya está asignado a este usuario';
    END IF;

    -- Obtener información para el mensaje
    SELECT username INTO v_username
    FROM user_account
    WHERE user_account_id = p_user_account_id;

    SELECT role_name INTO v_role_name
    FROM security_role
    WHERE security_role_id = p_security_role_id;

    -- Asignar el rol
    INSERT INTO user_role (
        user_account_id,
        security_role_id,
        assigned_date,
        created_at
    )
    VALUES (
        p_user_account_id,
        p_security_role_id,
        NOW(),
        NOW()
    )
    RETURNING user_role_id INTO v_user_role_id;

    -- El trigger se encargará de auditar la asignación

    RAISE NOTICE 'Rol % asignado exitosamente a usuario %. User Role ID: %', 
                 v_role_name, v_username, v_user_role_id;
END;
$$;


-- ============================================
-- SCRIPT DE PRUEBA
-- ============================================
-- 1. Ver asignaciones de roles y permisos
SELECT 
    p.first_name,
    p.last_name,
    ua.username,
    us.status_name,
    sr.role_name,
    COUNT(sp.security_permission_id) as permission_count
FROM v_user_role_authorization v
JOIN person p ON v.person_id = p.person_id
JOIN user_account ua ON v.user_account_id = ua.user_account_id
JOIN user_status us ON v.user_status_id = us.user_status_id
JOIN security_role sr ON v.security_role_id = sr.security_role_id
LEFT JOIN security_permission sp ON v.security_permission_id = sp.security_permission_id
GROUP BY p.first_name, p.last_name, ua.username, us.status_name, sr.role_name
LIMIT 10;

-- 2. Obtener datos para la prueba
-- SELECT 
--     ua.user_account_id,
--     ua.username,
--     sr.security_role_id,
--     sr.role_name
-- FROM user_account ua
-- CROSS JOIN security_role sr
-- WHERE NOT EXISTS (
--     SELECT 1 FROM user_role
--     WHERE user_account_id = ua.user_account_id
--     AND security_role_id = sr.security_role_id
-- )
-- LIMIT 1;

-- 3. Asignar rol a usuario
-- CALL sp_assign_role_to_user(
--     p_user_account_id := 'USER_ACCOUNT_ID_HERE',
--     p_security_role_id := 'SECURITY_ROLE_ID_HERE'
-- );

-- 4. Verificar asignación y permisos heredados
-- SELECT 
--     ua.username,
--     sr.role_name,
--     sp.permission_code,
--     sp.permission_description,
--     ur.assigned_date
-- FROM user_role ur
-- JOIN user_account ua ON ur.user_account_id = ua.user_account_id
-- JOIN security_role sr ON ur.security_role_id = sr.security_role_id
-- JOIN role_permission rp ON sr.security_role_id = rp.security_role_id
-- JOIN security_permission sp ON rp.security_permission_id = sp.security_permission_id
-- ORDER BY ur.assigned_date DESC
-- LIMIT 10;
