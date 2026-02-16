# Guía Rápida: SQL Avanzado en Sistemas Reales

## 1. Errores comunes con JOINs y cómo evitarlos

### ❌ Error: Duplicación de datos
```sql
-- INCORRECTO: multiplica las ventas por cada detalle
SELECT c.nombre, SUM(v.total)
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
JOIN detalle_ventas dv ON v.id = dv.venta_id
GROUP BY c.nombre;
```

### ✅ Solución: Agregar en el nivel correcto
```sql
-- CORRECTO: suma solo los totales de venta
SELECT c.nombre, SUM(v.total)
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
GROUP BY c.nombre;
```

### ❌ Error: Usar INNER JOIN cuando se necesita LEFT JOIN
```sql
-- INCORRECTO: omite estudiantes sin matrícula
SELECT e.nombre
FROM estudiantes e
JOIN matriculas m ON e.id = m.estudiante_id;
```

### ✅ Solución: LEFT JOIN para incluir todos
```sql
-- CORRECTO: muestra estudiantes sin matrícula
SELECT e.nombre
FROM estudiantes e
LEFT JOIN matriculas m ON e.id = m.estudiante_id
WHERE m.id IS NULL;
```

---

## 2. Cuándo usar subconsultas o EXISTS

### Usar subconsultas para valores calculados
```sql
-- Productos con precio mayor al promedio
SELECT nombre, precio
FROM productos
WHERE precio > (SELECT AVG(precio) FROM productos);
```

### Usar EXISTS para verificar existencia (más eficiente)
```sql
-- Clientes que han comprado
SELECT c.nombre
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM ventas v WHERE v.cliente_id = c.id
);

-- Clientes que NO han comprado
SELECT c.nombre
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM ventas v WHERE v.cliente_id = c.id
);
```

**Ventaja de EXISTS:** Se detiene al encontrar el primer registro, más rápido que JOIN + DISTINCT.

---

## 3. WHERE vs HAVING

### WHERE: filtra ANTES de agrupar
```sql
SELECT asignatura, COUNT(*) as estudiantes
FROM matriculas
WHERE semestre = '2024-1'  -- Filtra registros individuales
GROUP BY asignatura;
```

### HAVING: filtra DESPUÉS de agrupar
```sql
SELECT asignatura, COUNT(*) as estudiantes
FROM matriculas
WHERE semestre = '2024-1'
GROUP BY asignatura
HAVING COUNT(*) > 30;  -- Filtra grupos agregados
```

### Ejemplo completo
```sql
-- Productos con ventas > $5000 en 2024
SELECT producto, SUM(monto) as total
FROM ventas
WHERE YEAR(fecha) = 2024        -- WHERE: filtra filas
GROUP BY producto
HAVING SUM(monto) > 5000;       -- HAVING: filtra grupos
```

**Regla:** Usa WHERE siempre que puedas (más eficiente). Usa HAVING solo para funciones agregadas.

---

## 4. Funciones de ventana vs GROUP BY

### GROUP BY: colapsa filas
```sql
-- Solo muestra promedios por asignatura
SELECT asignatura, AVG(nota) as promedio
FROM notas
GROUP BY asignatura;
```

### Funciones de ventana: mantiene todas las filas
```sql
-- Muestra cada estudiante con su nota y el promedio de su asignatura
SELECT 
    estudiante,
    asignatura,
    nota,
    AVG(nota) OVER (PARTITION BY asignatura) as promedio_asignatura,
    RANK() OVER (PARTITION BY asignatura ORDER BY nota DESC) as ranking
FROM notas;
```

### Ejemplo: Ventas con acumulado
```sql
SELECT 
    fecha,
    producto,
    ventas,
    SUM(ventas) OVER (
        PARTITION BY producto 
        ORDER BY fecha
    ) as ventas_acumuladas
FROM ventas_diarias;
```

**Ventajas:**
- Ver detalle individual Y agregados simultáneamente
- Rankings sin subconsultas
- Cálculos acumulados y promedios móviles

---

## 5. Caso real: Sistema de inventario

### Problema: Detectar productos con stock bajo
```sql
-- Productos cuyo stock está por debajo del promedio de su categoría
SELECT 
    p.nombre,
    p.stock_actual,
    AVG(p2.stock_actual) as promedio_categoria,
    c.nombre as categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
JOIN productos p2 ON p2.categoria_id = c.id
GROUP BY p.id, p.nombre, p.stock_actual, c.nombre
HAVING p.stock_actual < AVG(p2.stock_actual) * 0.5
ORDER BY (p.stock_actual / AVG(p2.stock_actual));
```

### Con funciones de ventana (más simple)
```sql
SELECT 
    nombre,
    stock_actual,
    categoria,
    AVG(stock_actual) OVER (PARTITION BY categoria) as promedio_categoria
FROM productos_con_categoria
WHERE stock_actual < (
    AVG(stock_actual) OVER (PARTITION BY categoria)
) * 0.5;
```

### Reporte de rotación de inventario
```sql
WITH ventas_producto AS (
    SELECT 
        producto_id,
        SUM(cantidad) as unidades_vendidas,
        COUNT(DISTINCT fecha) as dias_con_venta
    FROM detalle_ventas
    WHERE fecha >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY producto_id
)
SELECT 
    p.nombre,
    p.stock_actual,
    COALESCE(vp.unidades_vendidas, 0) as vendidas_30dias,
    CASE 
        WHEN vp.unidades_vendidas > 0 
        THEN ROUND(p.stock_actual / (vp.unidades_vendidas / 30), 1)
        ELSE NULL 
    END as dias_inventario,
    CASE
        WHEN vp.dias_con_venta = 0 THEN 'SIN MOVIMIENTO'
        WHEN p.stock_actual / (vp.unidades_vendidas / 30) < 7 THEN 'CRÍTICO'
        WHEN p.stock_actual / (vp.unidades_vendidas / 30) < 15 THEN 'BAJO'
        ELSE 'NORMAL'
    END as estado
FROM productos p
LEFT JOIN ventas_producto vp ON p.id = vp.producto_id
ORDER BY dias_inventario;
```

---

## Resumen de mejores prácticas

1. **JOINs:** Verifica siempre la cardinalidad, usa LEFT JOIN cuando necesites incluir registros sin coincidencias
2. **EXISTS vs JOIN:** Usa EXISTS para verificar existencia (más eficiente que JOIN + DISTINCT)
3. **WHERE vs HAVING:** WHERE para filtrar filas, HAVING para filtrar agregaciones
4. **Funciones de ventana:** Úsalas cuando necesites mantener detalle individual + agregados
5. **CTEs:** Mejoran la legibilidad en consultas complejas
6. **Validación:** Siempre verifica conteos antes y después de JOINs para detectar duplicación

---

## Consulta de validación rápida

```sql
-- Verificar si hay duplicación
SELECT 'Original' as tabla, COUNT(*) FROM ventas
UNION ALL
SELECT 'Después de JOIN', COUNT(*) 
FROM ventas v 
JOIN detalle_ventas dv ON v.id = dv.venta_id;

-- Si los conteos no coinciden, hay duplicación
```