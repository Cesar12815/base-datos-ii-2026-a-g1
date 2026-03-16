-- Práctica SQL - Subconsultas y CTEs
-- Base de datos: Tienda de libros
-- Nivel: Intermedio

-- =============================================
-- Creación de tablas y datos
-- =============================================

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    nombre     VARCHAR(100),
    ciudad     VARCHAR(50)
);

CREATE TABLE libros (
    id_libro INT PRIMARY KEY,
    titulo   VARCHAR(150),
    genero   VARCHAR(50),
    precio   DECIMAL(8,2)
);

CREATE TABLE ventas (
    id_venta   INT PRIMARY KEY,
    id_cliente INT,
    id_libro   INT,
    fecha      DATE,
    cantidad   INT
);

INSERT INTO clientes VALUES
(1, 'Ana Gómez',    'Bogotá'),
(2, 'Luis Pérez',   'Medellín'),
(3, 'María Torres', 'Cali'),
(4, 'Carlos Ruiz',  'Bogotá'),
(5, 'Diana Mora',   'Medellín');

INSERT INTO libros VALUES
(1, 'El principito',         'Ficción',    32000),
(2, 'Cien años de soledad',  'Ficción',    45000),
(3, 'Python para todos',     'Tecnología', 58000),
(4, 'El arte de la guerra',  'Ensayo',     28000),
(5, 'Aprender SQL',          'Tecnología', 62000);

INSERT INTO ventas VALUES
(1, 1, 1, '2024-01-10', 2),
(2, 1, 3, '2024-02-15', 1),
(3, 2, 2, '2024-02-20', 1),
(4, 3, 5, '2024-03-05', 2),
(5, 4, 1, '2024-03-12', 1),
(6, 4, 4, '2024-04-01', 3),
(7, 2, 3, '2024-04-18', 1),
(8, 5, 2, '2024-05-02', 1);


-- =============================================
-- Ejercicio 1 - Subconsulta en WHERE con IN
-- Clientes que han comprado libros de Tecnología
-- =============================================

SELECT nombre, ciudad
FROM clientes
WHERE id_cliente IN (
    SELECT DISTINCT v.id_cliente
    FROM ventas v
    JOIN libros l ON v.id_libro = l.id_libro
    WHERE l.genero = 'Tecnología'
);


-- =============================================
-- Ejercicio 2 - Subconsulta escalar en WHERE
-- Libros con precio mayor al promedio
-- =============================================

SELECT titulo, genero, precio
FROM libros
WHERE precio > (SELECT AVG(precio) FROM libros)
ORDER BY precio DESC;


-- =============================================
-- Ejercicio 3 - EXISTS y NOT EXISTS
-- Clientes que compraron ficción pero NO ensayo
-- =============================================

SELECT nombre
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM ventas v
    JOIN libros l ON v.id_libro = l.id_libro
    WHERE v.id_cliente = c.id_cliente
      AND l.genero = 'Ficción'
)
AND NOT EXISTS (
    SELECT 1 FROM ventas v
    JOIN libros l ON v.id_libro = l.id_libro
    WHERE v.id_cliente = c.id_cliente
      AND l.genero = 'Ensayo'
);


-- =============================================
-- Ejercicio 4 - CTE
-- Total gastado por cliente y comparación
-- con el promedio general
-- =============================================

WITH gasto_cliente AS (
    SELECT c.nombre,
           SUM(v.cantidad * l.precio) AS total_gastado
    FROM ventas v
    JOIN clientes c ON v.id_cliente = c.id_cliente
    JOIN libros   l ON v.id_libro   = l.id_libro
    GROUP BY c.id_cliente, c.nombre
)
SELECT nombre,
       total_gastado,
       (SELECT ROUND(AVG(total_gastado), 0) FROM gasto_cliente) AS promedio_general,
       CASE
           WHEN total_gastado > (SELECT AVG(total_gastado) FROM gasto_cliente) THEN 'Por encima'
           ELSE 'Por debajo'
       END AS vs_promedio
FROM gasto_cliente
ORDER BY total_gastado DESC;
