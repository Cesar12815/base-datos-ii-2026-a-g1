# Actividad Práctica: Optimización con Índices
## Semana 9 - Sesión 2 (Repaso no obligatorio)

**Base de Datos II** · Ingeniería de Sistemas · © 2026 CORHUILA

---

## Contexto

Esta actividad es un **repaso no obligatorio** de la Sesión 2. Simulas que tu base de datos creció significativamente y ahora algunas consultas tardan más de lo esperado. Tu tarea es:

1. Identificar 3 consultas problemáticas
2. Proponer índices para optimizarlas
3. Evidenciar mejoras con `EXPLAIN ANALYZE`
4. Documentar conclusiones

---

## Objetivo

Aprender a **validar optimizaciones con evidencia real** usando `EXPLAIN` y `EXPLAIN ANALYZE`, demostrando que entiendes:

- Cómo leer planes de ejecución
- La diferencia entre Sequential Scan e Index Scan
- Cómo crear índices efectivos
- Cómo medir mejora real

---

## Mini-Reto: Optimiza 3 Consultas

### Paso 1: Selecciona 3 consultas reales

Elige 3 queries de tu modelo `matricula` que representan patrones comunes:

**Ejemplo de consultas típicas:**

```
Consulta 1: Buscar todas las matrículas de un semestre
SELECT * FROM matricula WHERE semestre = '2026-1';

Consulta 2: Buscar matrículas de un estudiante en un semestre
SELECT * FROM matricula 
WHERE estudiante_id = 1 AND semestre = '2026-1';

Consulta 3: Extraer estudiantes con mejor nota en un semestre
SELECT e.nombre, m.nota FROM matricula m
JOIN estudiante e ON m.estudiante_id = e.id_estudiante
WHERE m.semestre = '2026-1'
ORDER BY m.nota DESC LIMIT 10;
```

**Tu selección:**

1. **Consulta 1:** (describe brevemente qué hace)
   - Patrón: (filtro/JOIN/GROUP BY/etc)

2. **Consulta 2:** (describe brevemente qué hace)
   - Patrón: (filtro/JOIN/GROUP BY/etc)

3. **Consulta 3:** (describe brevemente qué hace)
   - Patrón: (filtro/JOIN/GROUP BY/etc)

---

### Paso 2: Ejecuta EXPLAIN ANALYZE (ANTES - sin índices)

Para cada consulta, ejecuta `EXPLAIN ANALYZE` y **guarda aquí el resultado**:

#### Consulta 1 - ANTES

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Observaciones:**
- Tipo de scan: ___________________
- Rows estimadas vs reales: ___________________
- Tiempo de ejecución: ___________________
- ¿Usa índices?: ___________________

---

#### Consulta 2 - ANTES

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Observaciones:**
- Tipo de scan: ___________________
- Rows estimadas vs reales: ___________________
- Tiempo de ejecución: ___________________
- ¿Usa índices?: ___________________

---

#### Consulta 3 - ANTES

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Observaciones:**
- Tipo de scan: ___________________
- Rows estimadas vs reales: ___________________
- Tiempo de ejecución: ___________________
- ¿Usa índices?: ___________________

---

### Paso 3: Proponer y crear índices

Basándote en los planes anteriores, propón **3 índices** (1 simple, 1 compuesto, 1 para JOIN):

#### Índice 1 (Simple)

**Propósito:** ___________________

```sql
CREATE INDEX idx_nombre1 ON tabla(columna);
```

**Razonamiento:** 
- ¿Por qué esta columna?
- ¿Qué patrón de consulta beneficia?

---

#### Índice 2 (Compuesto - 2+ columnas)

**Propósito:** ___________________

```sql
CREATE INDEX idx_nombre2 ON tabla(columna1, columna2);
```

**Razonamiento:**
- ¿Por qué estas columnas en este orden?
- ¿Cuáles JOINs o filtros benefician?

---

#### Índice 3 (Para JOIN o FK)

**Propósito:** ___________________

```sql
CREATE INDEX idx_nombre3 ON tabla_fk(columna_fk);
```

**Razonamiento:**
- ¿Por qué esta FK está sin índice?
- ¿Qué JOIN mejorará?

---

### Paso 4: Ejecuta EXPLAIN ANALYZE (DESPUÉS - con índices)

Repite `EXPLAIN ANALYZE` para cada consulta y **compara**:

#### Consulta 1 - DESPUÉS

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Cambios observados:**
- Tipo de scan cambió a: ___________________
- Rows: ¿mejoraron estimaciones?: ___________________
- Tiempo: Antes ________ ms → Después ________ ms
- % Mejora: ___________________

---

#### Consulta 2 - DESPUÉS

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Cambios observados:**
- Tipo de scan cambió a: ___________________
- Rows: ¿mejoraron estimaciones?: ___________________
- Tiempo: Antes ________ ms → Después ________ ms
- % Mejora: ___________________

---

#### Consulta 3 - DESPUÉS

```sql
EXPLAIN ANALYZE
SELECT ...
```

**Captura/Resultado:**
```
[Pega aquí el output de EXPLAIN ANALYZE]
```

**Cambios observados:**
- Tipo de scan cambió a: ___________________
- Rows: ¿mejoraron estimaciones?: ___________________
- Tiempo: Antes ________ ms → Después ________ ms
- % Mejora: ___________________

---

### Paso 5: Escribe conclusiones

**Para cada consulta, explica (2-3 líneas):**

#### Conclusión - Consulta 1

¿Qué índice ayudó? ¿Por qué? ¿Cuánto mejoró?

[Tu respuesta aquí]

---

#### Conclusión - Consulta 2

¿Qué índice ayudó? ¿Por qué? ¿Cuánto mejoró?

[Tu respuesta aquí]

---

#### Conclusión - Consulta 3

¿Qué índice ayudó? ¿Por qué? ¿Cuánto mejoró?

[Tu respuesta aquí]

---

## Entregables (opcional)

### Entregar

1. **Script SQL** (archivo `.sql`)
   - Contiene: consultas, EXPLAIN para ambas, índices creados
   - Formato: comentarios claros, fácil de seguir
   - Archivo sugerido: `actividad_optimizacion.sql`

2. **Evidencias** (capturas o PDF)
   - 3 capturas "ANTES" (plans iniciales)
   - 3 capturas "DESPUÉS" (plans optimizados)
   - Destacar cambios en scan type y tiempo

3. **Documento de conclusiones**
   - Este archivo (completado)
   - Markdown o PDF
   - Archivo sugerido: `actividad_optimizacion.md` (este documento)

---

## Checklist de Auto-Evaluación

- [ ] Identifiqué 3 consultas reales y relevantes
- [ ] Ejecuté EXPLAIN ANALYZE en CADA consulta (sin índices)
- [ ] Guardé evidencia clara de los planes iniciales
- [ ] Propuse 3 índices con razonamiento
- [ ] Creé los índices en la BD
- [ ] Ejecuté EXPLAIN ANALYZE nuevamente (con índices)
- [ ] Guardé evidencia clara de los planes optimizados
- [ ] Comparé: tipo de scan, performance, filas
- [ ] Escribí conclusiones para cada consulta
- [ ] Documenté todo en archivo(s)

---

## Preguntas de reflexión final

1. **¿Cuál fue el cambio más drástico en performance?**
   - Respuesta:

2. **¿Hay algún índice que no se usó?**
   - Respuesta:

3. **¿Qué tipo de índice fue más efectivo (simple, compuesto, FK)?**
   - Respuesta:

4. **¿Qué hubiera pasado si crearamos MÁS índices de los necesarios?**
   - Respuesta:

5. **¿Cómo validarías esto en una BD de producción?**
   - Respuesta:

---

## Recursos de apoyo

- **Sesión 1:** Conceptos de índices y cuándo usarlos
- **Sesión 2:** Cómo leer planes con EXPLAIN/ANALYZE
- **Script:** `ejercicios_explain.sql` (ejemplos listos para ejecutar)

---

## Nota final

Esta es una actividad de **repaso y aprendizaje**. No es obligatoria, pero practicarla te dará confianza para optimizar consultas reales.

Recuerda: **"La única forma confiable de saber si optimizaste es viendo el plan"** - EXPLAIN ANALYZE es tu mejor aliado.

---

© 2026 CORHUILA · Base de Datos II · Ingeniería de Sistemas
