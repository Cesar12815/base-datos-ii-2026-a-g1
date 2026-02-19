-- Crear y seleccionar la base de datos
CREATE DATABASE IF NOT EXISTS rbac_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE rbac_db;

-- ─────────────────────────────────────────
-- TABLAS
-- ─────────────────────────────────────────

CREATE TABLE module (
    id     INT          NOT NULL AUTO_INCREMENT,
    name   VARCHAR(100) NOT NULL,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE role (
    id     INT          NOT NULL AUTO_INCREMENT,
    name   VARCHAR(100) NOT NULL,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE permission (
    id        INT          NOT NULL AUTO_INCREMENT,
    name      VARCHAR(100) NOT NULL,
    module_id INT          NOT NULL,
    status    ENUM('active','inactive') NOT NULL DEFAULT 'active',
    PRIMARY KEY (id),
    CONSTRAINT fk_permission_module FOREIGN KEY (module_id) REFERENCES module(id)
);

CREATE TABLE user (
    id     INT          NOT NULL AUTO_INCREMENT,
    name   VARCHAR(100) NOT NULL,
    email  VARCHAR(150) NOT NULL UNIQUE,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE role_permission (
    role_id       INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role       FOREIGN KEY (role_id)       REFERENCES role(id),
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permission(id)
);

CREATE TABLE user_role (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES user(id),
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES role(id)
);

-- ─────────────────────────────────────────
-- DATOS DE PRUEBA
-- ─────────────────────────────────────────

-- Módulos
INSERT INTO module (name, status) VALUES
    ('Ventas',         'active'),
    ('Inventario',     'active'),
    ('Recursos Humanos','active'),
    ('Reportes',       'inactive');  -- debe quedar excluido del reporte

-- Roles
INSERT INTO role (name, status) VALUES
    ('Administrador', 'active'),
    ('Vendedor',      'active'),
    ('Auditor',       'active'),
    ('Invitado',      'inactive');   -- debe quedar excluido del reporte

-- Permisos
INSERT INTO permission (name, module_id, status) VALUES
    -- Ventas (module_id = 1)
    ('ventas.crear',      1, 'active'),
    ('ventas.editar',     1, 'active'),
    ('ventas.eliminar',   1, 'active'),
    ('ventas.ver',        1, 'active'),
    -- Inventario (module_id = 2)
    ('inventario.crear',  2, 'active'),
    ('inventario.editar', 2, 'active'),
    ('inventario.ver',    2, 'active'),
    -- RRHH (module_id = 3)
    ('rrhh.ver',          3, 'active'),
    ('rrhh.editar',       3, 'active'),
    -- Reportes (module_id = 4) — inactivo, debe excluirse
    ('reportes.ver',      4, 'inactive');

-- Usuarios
INSERT INTO user (name, email, status) VALUES
    ('Ana García',    'ana@empresa.com',    'active'),
    ('Luis Pérez',    'luis@empresa.com',   'active'),
    ('María López',   'maria@empresa.com',  'active'),
    ('Carlos Ruiz',   'carlos@empresa.com', 'active'),
    ('Sofía Torres',  'sofia@empresa.com',  'active');

-- Asignación rol ↔ permiso
INSERT INTO role_permission (role_id, permission_id) VALUES
    -- Administrador: todos los permisos activos
    (1, 1),(1, 2),(1, 3),(1, 4),
    (1, 5),(1, 6),(1, 7),
    (1, 8),(1, 9),
    -- Vendedor: solo ventas y ver inventario
    (2, 1),(2, 2),(2, 4),
    (2, 7),
    -- Auditor: solo ver en todos los módulos activos
    (3, 4),
    (3, 7),
    (3, 8);

-- Asignación usuario ↔ rol
INSERT INTO user_role (user_id, role_id) VALUES
    (1, 1),  -- Ana        → Administrador
    (2, 1),  -- Luis       → Administrador
    (3, 2),  -- María      → Vendedor
    (4, 2),  -- Carlos     → Vendedor
    (5, 3);  -- Sofía      → Auditor





--------------------------------------------------------------------------------
-- CONSULTA SOLUCIÓN

SELECT
    m.name                                      AS module_name,
    r.name                                      AS role_name,
    GROUP_CONCAT(p.name ORDER BY p.name SEPARATOR ', ')  AS permissions_list,
    COUNT(p.id)                                 AS permission_count,
    COUNT(DISTINCT ur.user_id)                  AS user_count
FROM module m
INNER JOIN permission p
        ON p.module_id = m.id
       AND p.status    = 'active'
INNER JOIN role_permission rp
        ON rp.permission_id = p.id
INNER JOIN role r
        ON r.id     = rp.role_id
       AND r.status = 'active'
LEFT  JOIN user_role ur
        ON ur.role_id = r.id
WHERE m.status = 'active'
GROUP BY
    m.id,
    m.name,
    r.id,
    r.name
ORDER BY
    m.name      ASC,
    user_count  DESC;


-------------------------------------------------------------------------------


-- VARIANTE 2 

-- PARTE A: Roles QUE SÍ tienen permisos en módulos activos
SELECT
    m.name                                                          AS module_name,
    r.name                                                          AS role_name,
    GROUP_CONCAT(p.name ORDER BY p.name SEPARATOR ', ')            AS permissions_list,
    COUNT(p.id)                                                     AS permission_count,
    COUNT(DISTINCT ur.user_id)                                      AS user_count,
    'with_permissions'                                              AS source
FROM module m
INNER JOIN permission p
        ON p.module_id = m.id
       AND p.status    = 'active'
INNER JOIN role_permission rp
        ON rp.permission_id = p.id
INNER JOIN role r
        ON r.id     = rp.role_id
       AND r.status = 'active'
LEFT  JOIN user_role ur
        ON ur.role_id = r.id
WHERE m.status = 'active'
GROUP BY
    m.id, m.name,
    r.id, r.name

UNION ALL

-- PARTE B: Roles activos que NO tienen ningún permiso en módulos activos
SELECT
    m.name                  AS module_name,
    r.name                  AS role_name,
    NULL                    AS permissions_list,
    0                       AS permission_count,
    COUNT(DISTINCT ur.user_id) AS user_count,
    'without_permissions'   AS source
FROM module m
CROSS JOIN role r
LEFT  JOIN user_role ur
        ON ur.role_id = r.id
WHERE m.status = 'active'
  AND r.status = 'active'
  AND NOT EXISTS (
        SELECT 1
        FROM role_permission rp
        INNER JOIN permission p
                ON p.id        = rp.permission_id
               AND p.module_id = m.id
               AND p.status    = 'active'
        WHERE rp.role_id = r.id
  )
GROUP BY
    m.id, m.name,
    r.id, r.name

ORDER BY
    module_name ASC,
    user_count  DESC;