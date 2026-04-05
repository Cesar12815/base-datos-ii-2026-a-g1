-- ============================================================================
-- Base de Datos II - Semana 9, Sesión 2
-- Taller: EXPLAIN, EXPLAIN ANALYZE y Planes de Ejecución
-- Ejercicios Prácticos
-- ============================================================================

-- PREREQUISITO: Asegúrate de tener la tabla matricula con datos
-- (creada en Sesión 1). Si no, descomenta la sección de setup al final.

-- ============================================================================
-- EJERCICIO 1: EXPLAIN vs EXPLAIN ANALYZE (comparación)
-- ============================================================================

-- Ejecuta sin ANALYZE (plan estimado, sin ejecutar)
EXPLAIN
SELECT *
FROM matricula
WHERE semestre = '2026-1';

-- Vs. con ANALYZE (plan real, ejecuta consulta)
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1';

-- Observa la diferencia:
-- - EXPLAIN muestra: cost estimado, rows estimadas
-- - EXPLAIN ANALYZE muestra: tiempo real, rows reales, loops

-- ============================================================================
-- EJERCICIO 2: Identificar Sequential Scan (sin índice)
-- ============================================================================

-- ANTES: Sin índice -> Sequential Scan
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY estudiante_id;

-- ¿Qué ves?
-- - Tipo de scan: Seq Scan (recorre toda la tabla)
-- - Filas estimadas vs reales
-- - Tiempo de ejecución
-- - Filas removidas por filtro

-- ============================================================================
-- EJERCICIO 3: Crear índice y ver cambio a Index Scan
-- ============================================================================

-- Crear índice
CREATE INDEX IF NOT EXISTS idx_matricula_semestre ON matricula(semestre);

-- Después: Con índice -> Index Scan
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY estudiante_id;

-- Compara con EJERCICIO 2:
-- - ¿Cambió de Seq Scan a Index Scan?
-- - ¿Mejoró el tiempo de ejecución?
-- - ¿Menos filas devueltas?

-- ============================================================================
-- EJERCICIO 4: Consultas con WHERE múltiples
-- ============================================================================

-- ANTES: Sin índice compuesto
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
  AND estudiante_id = 1;

-- DESPUÉS: Crear índice compuesto
CREATE INDEX IF NOT EXISTS idx_matricula_semestre_estudiante 
ON matricula(semestre, estudiante_id);

EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
  AND estudiante_id = 1;

-- ¿Qué observas?
-- - ¿Usa el índice compuesto?
-- - ¿Cuál es más rápido?

-- ============================================================================
-- EJERCICIO 5: Queries con ORDER BY + LIMIT (paginación)
-- ============================================================================

-- ANTES: Sin índice para ORDER BY
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY nota DESC
LIMIT 10;

-- DESPUÉS: Crear índice que soporte ORDER BY
CREATE INDEX IF NOT EXISTS idx_matricula_semestre_nota 
ON matricula(semestre, nota DESC);

EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY nota DESC
LIMIT 10;

-- ¿Qué cambió?
-- - ¿Desapareció el "Sort"?
-- - ¿Es más rápido?

-- ============================================================================
-- EJERCICIO 6: Queries con JOINs (índices en FKs)
-- ============================================================================

-- ANTES: Sin índice en FK
EXPLAIN ANALYZE
SELECT m.id_matricula, e.nombre, a.nombre AS asignatura, m.semestre
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
JOIN asignatura a ON m.asignatura_id = a.id_asignatura
WHERE m.semestre = '2026-1';

-- Crear índices en FKs (si no existen)
CREATE INDEX IF NOT EXISTS idx_matricula_estudiante ON matricula(estudiante_id);
CREATE INDEX IF NOT EXISTS idx_matricula_asignatura ON matricula(asignatura_id);

-- DESPUÉS: Con índices en FKs
EXPLAIN ANALYZE
SELECT m.id_matricula, e.nombre, a.nombre AS asignatura, m.semestre
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
JOIN asignatura a ON m.asignatura_id = a.id_asignatura
WHERE m.semestre = '2026-1';

-- Observa:
-- - Tipo de join (Nested Loop, Hash, Merge)
-- - ¿Usa índices en las claves de join?
-- - ¿Mejoró respecto a la versión anterior?

-- ============================================================================
-- EJERCICIO 7: GROUP BY con índices
-- ============================================================================

-- ANTES: Sin índice
EXPLAIN ANALYZE
SELECT e.nombre, COUNT(*) AS total_matriculas
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
WHERE m.semestre = '2026-1'
GROUP BY e.nombre
ORDER BY total_matriculas DESC;

-- DESPUÉS: Índices creados (pueden ayudar según planner)
-- Los índices ya existen del ejercicio anterior

EXPLAIN ANALYZE
SELECT e.nombre, COUNT(*) AS total_matriculas
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
WHERE m.semestre = '2026-1'
GROUP BY e.nombre
ORDER BY total_matriculas DESC;

-- ¿Qué ves?
-- - ¿Usa índices?
-- - HashAggregate es común en GROUP BY

-- ============================================================================
-- EJERCICIO 8: Funciones en WHERE (antipatrón)
-- ============================================================================

-- MALO: Función en la columna (rompe índice)
EXPLAIN ANALYZE
SELECT *
FROM estudiante
WHERE LOWER(email) = 'juan@example.com';

-- BUENO: Sin función (puede usar índice)
EXPLAIN ANALYZE
SELECT *
FROM estudiante
WHERE email ILIKE 'juan@example.com';

-- Compara:
-- - ¿Usa índice en la segunda?
-- - ¿Qué tipo de operación hace?

-- ============================================================================
-- EJERCICIO 9: Analizar estadísticas desactualizadas
-- ============================================================================

-- Ver estadísticas de la tabla
SELECT
    schemaname,
    tablename,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename = 'matricula';

-- Si rows estimadas difieren mucho de rows reales en EXPLAIN ANALYZE,
-- ejecuta ANALYZE para actualizar estadísticas:
ANALYZE matricula;

-- Luego repite cualquier EXPLAIN ANALYZE anterior
-- para ver si el planner elige mejor

-- ============================================================================
-- EJERCICIO 10: Comparar planes con BUFFERS (si usas ANALYZE)
-- ============================================================================

-- PostgreSQL también puede mostrar I/O con BUFFERS
-- Ejemplo:
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM matricula
WHERE semestre = '2026-1'
ORDER BY estudiante_id;

-- Ver:
-- - Heap Blks Read/Written (I/O en tabla)
-- - Index Blks Read/Written (I/O en índices)
-- - Shared Hit (datos en memoria)

-- ============================================================================
-- EJERCICIO 11: Listar índices y su uso
-- ============================================================================

-- Ver todos los índices creados en matricula
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'matricula'
ORDER BY indexname;

-- Ver cuáles se usan realmente
SELECT
    schemaname,
    tablename,
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'matricula'
ORDER BY idx_scan DESC;

-- Nota: idx_scan = 0 significa que el índice NO se usa (candidato a DROP)

-- ============================================================================
-- EJERCICIO 12: Tamaño de índices
-- ============================================================================

-- Ver cuánto espacio ocupan los índices
SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS tamaño_indice
FROM pg_stat_user_indexes
WHERE relname = 'matricula'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Si un índice ocupa mucho y no se usa, considerar eliminarlo

-- ============================================================================
-- EJERCICIO 13: Comparación de planes para optimización
-- ============================================================================

-- Consulta típica en el modelo académico
-- ANTES (sin todo):
-- EXPLAIN ANALYZE
-- SELECT m.*, e.nombre, a.nombre
-- FROM matricula m
-- JOIN estudiante e ON m.estudiante_id = e.id_estudiante
-- JOIN asignatura a ON m.asignatura_id = a.id_asignatura
-- WHERE m.semestre = '2026-1'
--   AND m.nota >= 3.0
-- ORDER BY m.nota DESC;

-- DESPUÉS (con índices):
EXPLAIN ANALYZE
SELECT m.id_matricula, e.nombre, a.nombre, m.semestre, m.nota
FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
JOIN asignatura a ON m.asignatura_id = a.id_asignatura
WHERE m.semestre = '2026-1'
  AND m.nota >= 3.0
ORDER BY m.nota DESC;

-- ¿Cambió significativamente?

-- ============================================================================
-- EJERCICIO 14: VACUUM vs ANALYZE vs REINDEX
-- ============================================================================

-- VACUUM: Limpia espacio de dead tuples
-- ANALYZE: Actualiza estadísticas
-- REINDEX: Reconstruye índices (costoso, usar con cuidado)

-- Ejecutar mantenimiento
VACUUM ANALYZE matricula;

-- Luego ejecutar nuevamente cualquier query anterior
-- para confirmar que el planner sigue eligiendo bien

-- ============================================================================
-- EJERCICIO 15: Eliminación de índices no útiles
-- ============================================================================

-- Si encuentras un índice con idx_scan = 0, considera eliminarlo:
-- DROP INDEX IF EXISTS idx_nombre_no_usado;

-- Ejemplo (NO ejecutar a menos que confirmes que el índice no se usa):
-- DROP INDEX IF EXISTS idx_matricula_semestre_asignatura;

-- ============================================================================
-- PREGUNTAS PARA REFLEXIONAR
-- ============================================================================
-- 1. ¿Cuál fue el cambio más drástico en tiempo de ejecución?
-- 2. ¿Qué índice fue más efectivo?
-- 3. ¿Hay divergencia entre rows estimadas y rows reales?
-- 4. ¿Usó todos los índices creados o solo algunos?
-- 5. ¿Qué consulta mejoró más con los índices?

-- ============================================================================
-- SETUP (ejecutar solo si no tienes datos)
-- ============================================================================

/*
-- Crear tablas base
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

-- Datos de prueba
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

-- Analizar para tener estadísticas iniciales
ANALYZE;
*/
