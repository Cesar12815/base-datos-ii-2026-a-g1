# Base de Datos II
## Semana 9 · Sesión 1: Optimización básica (Índices y rendimiento)

**Unidad 2** · Índices y rendimiento · Ingeniería de Sistemas

© 2026 CORHUILA

---

## Estructura de la sesión

- **Inicio**: Conceptos fundamentales
- **Conceptos clave**: Rendimiento en BD
- **Índices en PostgreSQL**: Teoría y práctica
- **Patrones de consulta**: Optimización real
- **Cierre**: Resumen y próximos pasos

---

## Idea central

**Optimizar no es "poner índices a todo".**

Optimizar es entender: qué se consulta, cómo se filtra, cómo se ordena y qué tan selectiva es la condición.

---

## 1. Conceptos clave de rendimiento

### Definiciones

| Término | Definición |
|---------|-----------|
| **Rendimiento** | Qué tan rápido responde una consulta (tiempo y recursos) |
| **Sequential Scan** | La base recorre toda la tabla fila por fila |
| **Index Scan** | La base usa un índice para ubicar filas relevantes más rápido |
| **Selectividad** | Qué porcentaje de filas coincide con el filtro (alta selectividad = pocas filas) |

### ¿Por qué se vuelven lentas las consultas?

1. **Tablas grandes sin índices** en columnas filtradas
2. **Filtros poco selectivos** (devuelven demasiadas filas)
3. **JOINs con claves no indexadas**
4. **ORDER BY / GROUP BY** sobre columnas sin soporte
5. **Funciones sobre columnas** en WHERE (rompen el uso del índice en muchos casos)

---

## 2. Índices en PostgreSQL: qué son y cuándo usarlos

### ¿Qué es un índice?

Un índice es una estructura adicional (como un "índice de libro") que permite ubicar filas rápidamente.

El más común en PostgreSQL es el **B-Tree**, ideal para:
- Igualdad (`=`)
- Rangos (`>`, `<`, `BETWEEN`)
- `ORDER BY`

### ¿Qué costo tiene un índice?

✗ Ocupa espacio en disco  
✗ Hace más lentos INSERT/UPDATE/DELETE (porque debe actualizarse el índice)  
✗ Debe ser relevante: si nunca se usa, es "carga"

---

## 2.1. Crear y eliminar índices

### Índice simple (B-Tree por defecto)

```sql
CREATE INDEX idx_matricula_semestre ON matricula(semestre);
```

### Índice para JOINs (FKs)

```sql
CREATE INDEX idx_matricula_estudiante ON matricula(estudiante_id);
CREATE INDEX idx_matricula_asignatura ON matricula(asignatura_id);
```

### Eliminar índice

```sql
DROP INDEX IF EXISTS idx_matricula_semestre;
```

---

## 2.2. Índices compuestos (multicolumna)

Útiles cuando filtras por más de una columna de forma frecuente.

**El orden importa**: si filtras por `(semestre, asignatura_id)`, conviene que el índice esté en ese orden.

### Ejemplo

```sql
-- Índice para filtros por semestre y asignatura
CREATE INDEX idx_matricula_semestre_asig ON matricula(semestre, asignatura_id);
```

---

## 2.3. Índices UNIQUE (además de rendimiento: integridad)

Un `UNIQUE` ayuda a evitar duplicados y también puede mejorar búsquedas por ese campo.

```sql
-- Evita matrículas duplicadas por semestre
CREATE UNIQUE INDEX ux_matricula_unica
ON matricula(estudiante_id, asignatura_id, semestre);
```

### ⚠️ Tip importante

Las PK y UNIQUE crean índices automáticamente. No dupliques índices innecesarios.

---

## 3. Patrones de consulta que más se optimizan

### 3.1. Filtros frecuentes (WHERE)

Si una columna aparece todo el tiempo en `WHERE` (ej: semestre, estado, fecha), es candidata a índice.

### 3.2. JOINs (claves de relación)

Para JOINs grandes, tener índice en las columnas de unión (FK y PK) es clave.
*Normalmente PK ya está indexada, pero las FKs no siempre lo están.*

### 3.3. ORDER BY y paginación

Si ordenas por fecha o id y paginación (`LIMIT`/`OFFSET`), un índice puede reducir mucho el costo.

### ⚠️ Antipatrón común

Hacer filtros con funciones sobre la columna:

```sql
-- ✗ EVITAR - No usa índice
WHERE LOWER(email) = 'x'
WHERE DATE(fecha) = '2026-01-01'

-- ✓ PREFERIR
WHERE email ILIKE 'x'
WHERE fecha::date = '2026-01-01'
```

---

## 4. Ejemplo de filtro típico

```sql
SELECT *
FROM matricula
WHERE semestre = '2026-1'
  AND asignatura_id = 10
ORDER BY estudiante_id
LIMIT 50;
```

**Optimización recomendada:**
```sql
CREATE INDEX idx_matricula_semestre_asig 
ON matricula(semestre, asignatura_id, estudiante_id);
```

---

## 5. Cierre de la sesión

### Lo que debes llevarte

✓ Índice acelera lectura, pero cuesta en escritura  
✓ Índices en columnas de filtros y JOINs suelen ser los más valiosos  
✓ Índices compuestos dependen del patrón de filtros (orden importa)  
✓ La optimización se valida con planes de ejecución (Sesión 2: EXPLAIN/EXPLAIN ANALYZE)

### Próximas pasos

- **Sesión 2**: Planes de ejecución con `EXPLAIN` y `EXPLAIN ANALYZE`
- Validar optimizaciones en tiempo real
- Ajustar índices según métricas reales

---

## Recursos

- Material docente para: Base de Datos II
- Unidad 2 · Semana 9 · Sesión 1 · Índices y rendimiento
- Ingeniería de Sistemas
- © 2026 CORHUILA
