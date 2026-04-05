-- ============================================================================
-- Base de Datos II - Semana 9, Sesión 1
-- Taller: Índices y Rendimiento en PostgreSQL
-- Ejercicios Prácticos
-- ============================================================================

-- EJERCICIO 1: Crear tabla de prueba (matricula)
-- ============================================================================
-- Primero, asegúrate de tener una base de datos de prueba.
-- Si no exists la tabla, créala aquí:

CREATE TABLE IF NOT EXISTS estudiante (
    id_estudiante SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    estado VARCHAR(20) DEFAULT 'activo'
);

CREATE TABLE IF NOT EXISTS asignatura (
    id_asignatura SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    codigo VARCHAR(20) UNIQUE,
    creditos INT
);

CREATE TABLE IF NOT EXISTS matricula (
    id_matricula SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES estudiante(id_estudiante),
    asignatura_id INT NOT NULL REFERENCES asignatura(id_asignatura),
    semestre VARCHAR(10) NOT NULL,
    nota DECIMAL(3,1),
    CONSTRAINT ux_matricula_unica UNIQUE (estudiante_id, asignatura_id, semestre)
);

-- Insertar datos de prueba (simular datos reales)
INSERT INTO estudiante (nombre, email, estado) VALUES
('Juan Pérez', 'juan@example.com', 'activo'),
('María García', 'maria@example.com', 'activo'),
('Carlos López', 'carlos@example.com', 'inactivo'),
('Ana Martínez', 'ana@example.com', 'activo'),
('Luis Rodríguez', 'luis@example.com', 'activo');

INSERT INTO asignatura (nombre, codigo, creditos) VALUES
('Base de Datos I', 'BD1', 3),
('Base de Datos II', 'BD2', 3),
('Programación I', 'PROG1', 4),
('Estructura de Datos', 'ED', 3),
('Algoritmos', 'ALG', 4);

INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota) VALUES
(1, 1, '2026-1', 4.5),
(1, 2, '2026-1', 4.8),
(1, 3, '2025-2', 3.9),
(2, 1, '2026-1', 3.7),
(2, 4, '2026-1', 4.2),
(3, 2, '2026-1', 2.5),
(4, 1, '2025-2', 4.9),
(4, 5, '2026-1', 4.6),
(5, 3, '2026-1', 3.5);

-- ============================================================================
-- EJERCICIO 2: Identificar consultas lentas (sin índices)
-- ============================================================================
-- Ejecuta estas consultas y observa el tiempo/costo (usa EXPLAIN)

-- Consulta 1: Buscar todas las matrículas de un semestre
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY estudiante_id;

-- Consulta 2: Buscar matrículas por estudiante y semestre
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE estudiante_id = 1
  AND semestre = '2026-1';

-- Consulta 3: JOIN entre matrículas y asignatura
EXPLAIN ANALYZE
SELECT m.id_matricula, e.nombre, a.nombre AS asignatura, m.semestre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
JOIN asignatura a ON m.asignatura_id = a.id_asignatura
WHERE m.semestre = '2026-1'
ORDER BY m.nota DESC;

-- ============================================================================
-- EJERCICIO 3: Crear índices en columnas frecuentemente filtradas
-- ============================================================================

-- Índice 3.1: Índice simple en semestre (filtro muy frecuente)
CREATE INDEX idx_matricula_semestre ON matricula(semestre);

-- Índice 3.2: Índice en estudiante_id (JOINs y filtros)
CREATE INDEX idx_matricula_estudiante ON matricula(estudiante_id);

-- Índice 3.3: Índice en asignatura_id (JOINs y filtros)
CREATE INDEX idx_matricula_asignatura ON matricula(asignatura_id);

-- ============================================================================
-- EJERCICIO 4: Crear índices compuestos (multicolumna)
-- ============================================================================

-- Índice 4.1: Para consultas que filtran por semestre Y estudiante_id
CREATE INDEX idx_matricula_semestre_estudiante 
ON matricula(semestre, estudiante_id);

-- Índice 4.2: Para consultas que filtran por semestre y asignatura_id
CREATE INDEX idx_matricula_semestre_asignatura 
ON matricula(semestre, asignatura_id);

-- Índice 4.3: Índice compuesto incluyendo ORDER BY
CREATE INDEX idx_matricula_semestre_nota 
ON matricula(semestre, nota DESC);

-- ============================================================================
-- EJERCICIO 5: Comparar antes y después (EXPLAIN)
-- ============================================================================
-- Ejecuta nuevamente las consultas del EJERCICIO 2 y observa la diferencia
-- en el plan de ejecución (Index Scan vs Sequential Scan)

-- Ejecuta de nuevo y compara:
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY estudiante_id;

EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE estudiante_id = 1
  AND semestre = '2026-1';

EXPLAIN ANALYZE
SELECT m.id_matricula, e.nombre, a.nombre AS asignatura, m.semestre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
JOIN asignatura a ON m.asignatura_id = a.id_asignatura
WHERE m.semestre = '2026-1'
ORDER BY m.nota DESC;

-- ============================================================================
-- EJERCICIO 6: Análisis de índices existentes
-- ============================================================================

-- Listar todos los índices de la tabla matricula
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'matricula'
ORDER BY indexname;

-- Ver tamaño de los índices
SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS tamaño
FROM pg_stat_user_indexes
WHERE relname = 'matricula'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- EJERCICIO 7: Eliminar índices no útiles
-- ============================================================================

-- Verificar qué índices se usan
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'matricula'
ORDER BY idx_scan DESC;

-- Si un índice NO se usa (idx_scan = 0), considera eliminarlo:
-- DROP INDEX IF EXISTS idx_nombre_no_usado;

-- ============================================================================
-- EJERCICIO 8: Antipatrones - Funciones que rompen índices
-- ============================================================================

-- ✗ MALO: Función en columna de filtro
EXPLAIN ANALYZE
SELECT *
FROM estudiante
WHERE LOWER(email) = 'juan@example.com';

-- ✓ BUENO: Usar ILIKE (case-insensitive)
EXPLAIN ANALYZE
SELECT *
FROM estudiante
WHERE email ILIKE 'juan@example.com';

-- ✗ MALO: Función en fecha
-- EXPLAIN ANALYZE
-- SELECT *
-- FROM matricula
-- WHERE DATE(fecha_matricula) = '2026-01-01';

-- ✓ BUENO: Comparar directamente
-- EXPLAIN ANALYZE
-- SELECT *
-- FROM matricula
-- WHERE fecha_matricula >= '2026-01-01'
--   AND fecha_matricula < '2026-01-02';

-- ============================================================================
-- EJERCICIO 9: Índices UNIQUE (integridad + rendimiento)
-- ============================================================================

-- Ya creamos uno en la tabla (ux_matricula_unica)
-- Verificar que funcione:
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota)
VALUES (1, 1, '2026-1', 3.0);
-- Esto debe fallar con error de unique constraint

-- ============================================================================
-- EJERCICIO 10: Limpieza y conclusiones
-- ============================================================================

-- Ver estadísticas finales
SELECT
    schemaname,
    tablename,
    n_live_tup AS filas_vivas,
    n_dead_tup AS filas_muertas,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname IN ('matricula', 'estudiante', 'asignatura');

-- ============================================================================
-- PREGUNTAS PARA REFLEXIONAR
-- ============================================================================
-- 1. ¿Cuál fue la diferencia en tiempo entre Sequential Scan e Index Scan?
-- 2. ¿Qué índice fue más efectivo y por qué?
-- 3. ¿Cuánto espacio adicional ocupan los índices?
-- 4. ¿Cuál sería el impacto de agregar más índices?
-- 5. ¿Qué patrones de consulta justifican cada índice?

-- ============================================================================
-- LIMPIEZA (ejecutar si deseas borrar todo para empezar nuevamente)
-- ============================================================================
-- DROP TABLE IF EXISTS matricula CASCADE;
-- DROP TABLE IF EXISTS estudiante CASCADE;
-- DROP TABLE IF EXISTS asignatura CASCADE;
