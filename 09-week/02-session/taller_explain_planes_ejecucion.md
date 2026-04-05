# Base de Datos II
## Semana 9 · Sesión 2: Planes de ejecución (EXPLAIN) y Actividad

**Unidad 2** · EXPLAIN/ANALYZE y optimización · Ingeniería de Sistemas

© 2026 CORHUILA

---

## Estructura de la sesión

- **Inicio**: EXPLAIN vs EXPLAIN ANALYZE
- **Cómo leer un plan**: Elementos esenciales
- **Laboratorio guiado**: Antes vs después
- **Actividad práctica**: Repaso no obligatorio

---

## Idea clave

**La única forma confiable de saber si optimizaste es viendo el plan: "lo que la base realmente hace", no lo que creemos que hace.**

---

## 1. EXPLAIN vs EXPLAIN ANALYZE

### Diferencias fundamentales

| Comando | Ejecuta consulta | Muestra | Uso |
|---------|------------------|--------|-----|
| `EXPLAIN` | **No** | Plan estimado, costos estimados | Verificar estructura del plan |
| `EXPLAIN ANALYZE` | **Sí** | Plan real, tiempos reales, filas reales | Validar optimizaciones reales |

### Conceptos clave

- **Planner/Optimizer**: Elige el plan más "barato" según estadísticas
- **Plan estimado**: Basado en estadísticas (puede no ser exacto)
- **Plan real**: Resultado después de ejecutar la consulta

---

## 1.1. Ejemplo básico con EXPLAIN

```sql
EXPLAIN
SELECT *
FROM matricula
WHERE semestre = '2026-1';
```

**Salida típica:**
```
Seq Scan on matricula  (cost=0.00..35.50 rows=1500 width=32)
  Filter: (semestre = '2026-1')
```

---

## 1.2. Ejemplo con EXPLAIN ANALYZE (ejecución real)

```sql
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1';
```

**Salida típica:**
```
Seq Scan on matricula  (cost=0.00..35.50 rows=1500 width=32)
                       (actual time=0.245..5.432 rows=1480 loops=1)
  Filter: (semestre = '2026-1')
  Rows Removed by Filter: 20
Planning Time: 0.123 ms
Execution Time: 5.678 ms
```

### ⚠️ Tip para práctica académica

El objetivo es comparar el plan "antes vs después" de crear índices.

---

## 2. Cómo leer un plan (lo esencial)

### Elementos principales del plan

| Elemento | Qué significa | Qué buscar |
|----------|---------------|-----------|
| **Seq Scan** | Recorre toda la tabla fila por fila | Si hay muchas filas, suele ser lento |
| **Index Scan** | Usa índice para ubicar filas | Ideal en filtros selectivos |
| **Bitmap Index/Heap Scan** | Combina múltiples hits de índice | Frecuente cuando hay muchas coincidencias |
| **Cost** | Estimación interna del planner | Comparar antes vs después |
| **Rows** | Filas estimadas vs reales | Si difiere mucho, faltan estadísticas |
| **Execution Time** | Tiempo real de ejecución (ANALYZE) | Principal métrica de mejora |

### Lectura rápida de un plan

1. Mira el **nodo principal**: ¿Seq Scan o Index Scan?
2. Revisa cuántas **filas reales** salen (en ANALYZE)
3. Revisa el **tiempo total** (execution time)
4. **Compara** con/sin índice

---

## 2.1. ¿Por qué a veces NO usa el índice?

❌ La condición devuelve demasiadas filas (poca selectividad)  
❌ La tabla es pequeña (seq scan es más barato)  
❌ El filtro aplica una función (rompe el índice normal)  
❌ Estadísticas desactualizadas (faltó ANALYZE/VACUUM)  
❌ El índice no existe

---

## 3. Laboratorio guiado: antes vs después

### Objetivo

Ejecutar una consulta, ver su plan, crear índice, volver a ver el plan y comparar.

### 3.1. Consulta de prueba (ANTES - sin índice)

```sql
EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1';
```

**Observa:** ¿Es Seq Scan? ¿Cuánto tiempo toma?

---

### 3.2. Crear índice y repetir

```sql
CREATE INDEX IF NOT EXISTS idx_matricula_semestre ON matricula(semestre);

EXPLAIN ANALYZE
SELECT *
FROM matricula
WHERE semestre = '2026-1';
```

**Observa:** ¿Es ahora Index Scan? ¿Mejoró el tiempo?

---

### 3.3. Optimizar JOIN (índice en FK)

Si haces un JOIN grande, índice en FK suele ayudar mucho.

```sql
-- Crear índices de join
CREATE INDEX IF NOT EXISTS idx_matricula_estudiante ON matricula(estudiante_id);

EXPLAIN ANALYZE
SELECT e.nombre, COUNT(*) AS total
FROM matricula m
JOIN estudiante e ON e.id_estudiante = m.estudiante_id
WHERE m.semestre = '2026-1'
GROUP BY e.nombre
ORDER BY total DESC;
```

**Observa:** ¿Cambió el plan del JOIN? ¿Usa el índice ahora?

---

### 3.4. Estadísticas (mantenimiento)

Si el plan estima mal (rows estimadas muy distintas a las reales), es señal de estadísticas desactualizadas.

En PostgreSQL se mejora con:

```sql
ANALYZE matricula;
VACUUM matricula;
```

Luego repite el EXPLAIN ANALYZE.

---

### ⚠️ Tip para evidencias

Guarda capturas del plan **"antes"** y **"después"**, destacando:
- Si cambió de **Seq Scan** a **Index Scan**
- Si mejoró el **tiempo total**
- Diferencia en **filas estimadas vs reales**

---

## 4. Actividad práctica (repaso no obligatorio)

### 4.1. Contexto

Esta actividad es un **repaso no obligatorio**. Simulas que tu base creció y ahora algunas consultas tardan. Debes proponer índices y evidenciar mejoras con planes.

---

### 4.2. Qué hacer (5 pasos)

1. **Selecciona 3 consultas reales** de tu modelo (ej: por semestre, por asignatura, por estudiante)
2. **Ejecuta EXPLAIN ANALYZE** a cada una y guarda evidencia
3. **Crea índices** (1 simple, 1 compuesto, 1 para JOIN)
4. **Repite EXPLAIN ANALYZE** y compara:
   - Tipo de scan (Seq vs Index)
   - Rows (estimadas vs reales)
   - Tiempo
5. **Escribe conclusión** (2–3 líneas): qué índice ayudó y por qué

---

### 4.3. Entregables (opcional)

| Entregable | Requisito mínimo | Formato sugerido |
|-----------|-----------------|-----------------|
| **Script SQL** | Consultas + EXPLAIN + índices creados | `.sql` |
| **Evidencias** | Capturas antes/después (3 consultas) | Imágenes / PDF |
| **Conclusiones** | Explicación breve de resultados | Markdown / Documento |

---

### 4.4. Checklist de la actividad

- [ ] Identifiqué 3 consultas relevantes
- [ ] Ejecuté EXPLAIN ANALYZE en cada una (SIN índices)
- [ ] Guardé evidencia del plan inicial
- [ ] Creé índices apropiados (simple, compuesto, FK)
- [ ] Ejecuté EXPLAIN ANALYZE nuevamente
- [ ] Guardé evidencia del plan optimizado
- [ ] Comparé: tipo scan, filas, tiempo
- [ ] Escribí conclusión (qué mejoró y por qué)

---

## 5. Resumen de la sesión

### Lo que aprendiste

✓ Diferencia entre EXPLAIN (estimado) y EXPLAIN ANALYZE (real)  
✓ Cómo leer un plan de ejecución  
✓ Identificar Seq Scan vs Index Scan  
✓ Validar optimizaciones con evidencia  
✓ Interpretar estadísticas (rows estimadas vs reales)  

### Próximas pasos

- Aplicar EXPLAIN en consultas reales
- Monitorear performance con estadísticas
- Mantener índices con VACUUM/ANALYZE

---

## Recursos

- Material docente para: Base de Datos II
- Unidad 2 · Semana 9 · Sesión 2 · EXPLAIN/ANALYZE + Actividad
- Ingeniería de Sistemas
- © 2026 CORHUILA
