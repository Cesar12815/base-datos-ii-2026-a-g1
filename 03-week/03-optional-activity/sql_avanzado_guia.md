# SQL Avanzado - Respuestas del Foro

## 1. ¿Qué errores comunes pueden ocurrir al usar JOINs?

**Error principal:** Duplicación de datos cuando unes tablas con relación 1:N sin considerar la agregación.

```sql
-- ❌ MALO: duplica totales
SELECT c.nombre, SUM(v.total)
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
JOIN detalle_ventas dv ON v.id = dv.venta_id  -- ¡Aquí se duplica!
GROUP BY c.nombre;

-- ✅ BIEN: agrupa en el nivel correcto
SELECT c.nombre, SUM(v.total)
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
GROUP BY c.nombre;
```

**Otro error:** Usar INNER JOIN cuando necesitas LEFT JOIN (pierdes registros nulos).

---

## 2. ¿Cuándo usar subconsultas o EXISTS en lugar de JOINs?

**Usa EXISTS cuando solo importa si existe o no:**
```sql
-- Más eficiente que JOIN + DISTINCT
SELECT e.nombre
FROM estudiantes e
WHERE NOT EXISTS (
    SELECT 1 FROM matriculas m 
    WHERE m.estudiante_id = e.id
);
```

**Usa subconsultas para valores calculados:**
```sql
SELECT nombre, precio
FROM productos
WHERE precio > (SELECT AVG(precio) FROM productos);
```

---

## 3. ¿Por qué diferenciar WHERE y HAVING?

- **WHERE:** Filtra ANTES de agrupar (más eficiente)
- **HAVING:** Filtra DESPUÉS de agrupar (usa funciones agregadas)

```sql
SELECT asignatura, COUNT(*) as total
FROM matriculas
WHERE semestre = '2024-1'     -- Filtra registros
GROUP BY asignatura
HAVING COUNT(*) > 30;          -- Filtra grupos
```

---

## 4. ¿Ventajas de funciones de ventana vs GROUP BY?

**GROUP BY colapsa filas, funciones de ventana las mantiene:**

```sql
-- Con ventana: ves cada estudiante + su ranking
SELECT 
    estudiante,
    nota,
    RANK() OVER (ORDER BY nota DESC) as ranking,
    AVG(nota) OVER () as promedio_general
FROM notas;

-- Con GROUP BY: solo ves promedios
SELECT AVG(nota) FROM notas;
```

**Ventaja:** Rankings, acumulados y comparaciones sin perder el detalle individual.

---

## 5. Escenario real donde aplicarías SQL avanzado

**Sistema hospitalario:** Necesitas detectar interacciones medicamentosas en tiempo real, analizar tendencias de signos vitales con promedios móviles, identificar readmisiones tempranas (indicador de calidad), y optimizar carga de trabajo médica. 

Requiere: JOINs complejos (múltiples tablas de medicamentos), funciones de ventana (tendencias), subconsultas (comparar contra promedios), y LEFT JOINs (pacientes sin historial previo).

Un error en una consulta SQL puede llevar a decisiones médicas incorrectas, por eso la precisión es crítica.

---

**Tips rápidos:**
- Siempre verifica conteos antes/después de JOINs
- Usa LEFT JOIN cuando necesites incluir registros sin coincidencia
- Prefiere WHERE sobre HAVING cuando sea posible (rendimiento)
- EXISTS es más eficiente que JOIN + DISTINCT para verificar existencia
