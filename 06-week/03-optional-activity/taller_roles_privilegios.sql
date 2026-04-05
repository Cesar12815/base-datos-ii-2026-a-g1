-- ============================================================
--  TALLER: Roles, Privilegios y Pruebas en PostgreSQL
--  Base de Datos II · Semana 6 · Sesión 2
--  CORHUILA · Ingeniería de Sistemas · 2026
-- ============================================================

-- ============================================================
-- PASO 1: CREAR ROLES DE GRUPO
-- ============================================================

CREATE ROLE rol_lectura;
CREATE ROLE rol_escritura;
CREATE ROLE rol_admin;

-- ============================================================
-- PASO 2: CREAR USUARIOS CON LOGIN
-- ============================================================

CREATE ROLE u_reportes LOGIN PASSWORD 'Cambiar_123';
CREATE ROLE u_app      LOGIN PASSWORD 'Cambiar_123';
CREATE ROLE u_admin    LOGIN PASSWORD 'Cambiar_123';

-- ============================================================
-- PASO 3: ASIGNAR ROLES A USUARIOS
-- ============================================================

GRANT rol_lectura                    TO u_reportes;
GRANT rol_lectura, rol_escritura     TO u_app;
GRANT rol_admin                      TO u_admin;

-- ============================================================
-- PASO 4: PERMISOS A NIVEL DE BASE DE DATOS Y ESQUEMA
-- (Reemplaza "basedatos2" con el nombre real de tu BD)
-- ============================================================

GRANT CONNECT ON DATABASE basedatos2
    TO rol_lectura, rol_escritura, rol_admin;

GRANT USAGE  ON SCHEMA public
    TO rol_lectura, rol_escritura, rol_admin;

GRANT CREATE ON SCHEMA public
    TO rol_admin;

-- ============================================================
-- PASO 5: PERMISOS SOBRE TABLAS
-- ============================================================

-- Solo lectura
GRANT SELECT
    ON ALL TABLES IN SCHEMA public
    TO rol_lectura;

-- Lectura + escritura (app)
GRANT INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public
    TO rol_escritura;

-- Administración total
GRANT ALL PRIVILEGES
    ON ALL TABLES IN SCHEMA public
    TO rol_admin;

-- ============================================================
-- PASO 6: PERMISOS SOBRE SECUENCIAS (para autoincremento)
-- ============================================================

GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA public
    TO rol_escritura, rol_admin;

-- ============================================================
-- PASO 7: TABLA DE PRUEBA (ejecutar como superusuario)
-- ============================================================

CREATE TABLE IF NOT EXISTS estudiante (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- ============================================================
-- PASO 8: PRUEBAS DE PERMISOS
-- ============================================================

-- ----------------------------------------------------------
-- PRUEBA A: SELECT (conectarse como u_reportes)
-- Resultado esperado: OK ✅
-- ----------------------------------------------------------
-- \c basedatos2 u_reportes
SELECT * FROM estudiante;

-- ----------------------------------------------------------
-- PRUEBA B: INSERT como u_app
-- Resultado esperado: OK ✅
-- ----------------------------------------------------------
-- \c basedatos2 u_app
INSERT INTO estudiante(nombre) VALUES ('Prueba Permisos App');

-- ----------------------------------------------------------
-- PRUEBA C: INSERT como u_reportes
-- Resultado esperado: ERROR ❌ (permission denied)
-- ----------------------------------------------------------
-- \c basedatos2 u_reportes
INSERT INTO estudiante(nombre) VALUES ('Prueba Permisos Reportes');

-- ----------------------------------------------------------
-- PRUEBA D: CREATE TABLE como u_app
-- Resultado esperado: ERROR ❌ (permission denied for schema)
-- ----------------------------------------------------------
-- \c basedatos2 u_app
CREATE TABLE tabla_no_permitida (id SERIAL PRIMARY KEY, dato TEXT);

-- ----------------------------------------------------------
-- PRUEBA E: CREATE TABLE como u_admin
-- Resultado esperado: OK ✅
-- ----------------------------------------------------------
-- \c basedatos2 u_admin
CREATE TABLE tabla_admin_ok (id SERIAL PRIMARY KEY, dato TEXT);

-- ============================================================
-- PASO 9 (OPCIONAL): REVOCAR PERMISOS
-- ============================================================

-- Revocar INSERT a rol_escritura sobre una tabla específica
-- REVOKE INSERT ON estudiante FROM rol_escritura;

-- Revocar rol a un usuario
-- REVOKE rol_lectura FROM u_reportes;

-- ============================================================
-- PASO 10 (OPCIONAL): VERIFICAR PRIVILEGIOS
-- ============================================================

-- Ver roles asignados a un usuario
SELECT grantee, granted_role
FROM information_schema.role_table_grants
WHERE grantee IN ('u_reportes', 'u_app', 'u_admin');

-- Ver privilegios sobre tablas
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY grantee, table_name, privilege_type;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
