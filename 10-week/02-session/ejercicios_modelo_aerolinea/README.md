# 📚 Soluciones - 10 Ejercicios del Modelo de Aerolínea

Este directorio contiene las **soluciones completas** para los 10 ejercicios SQL del modelo de base de datos de aerolínea.

## 📁 Contenido

### Archivos de Enunciados
- `ejercicio_01.md` al `ejercicio_10.md` - Descripciones y requerimientos de cada ejercicio

### Archivos de Soluciones
- `ejercicio_01_solucion.sql` al `ejercicio_10_solucion.sql` - Implementaciones completas

### Documentación
- `SOLUCIONES_RESUMEN.md` - Resumen ejecutivo de todas las soluciones
- Este archivo (`README.md`)

---

## 🎯 Ejercicios Incluidos

| # | Tema | Archivo |
|---|------|---------|
| 01 | Check-in y Trazabilidad Comercial | `ejercicio_01_solucion.sql` |
| 02 | Control de Pagos y Transacciones | `ejercicio_02_solucion.sql` |
| 03 | Facturación e Integración | `ejercicio_03_solucion.sql` |
| 04 | Acumulación de Millas y Nivel | `ejercicio_04_solucion.sql` |
| 05 | Mantenimiento de Aeronaves | `ejercicio_05_solucion.sql` |
| 06 | Retrasos Operativos y Análisis | `ejercicio_06_solucion.sql` |
| 07 | Asignación de Asientos y Equipaje | `ejercicio_07_solucion.sql` |
| 08 | Auditoría de Acceso y Roles | `ejercicio_08_solucion.sql` |
| 09 | Publicación de Tarifas | `ejercicio_09_solucion.sql` |
| 10 | Identidad y Documentos de Pasajeros | `ejercicio_10_solucion.sql` |

---

## 📋 Elementos por Solución

Cada archivo SQL de solución incluye:

### 1. Vista (VIEW) - INNER JOIN
- Mínimo 5 tablas relacionadas
- Alias descriptivos
- Ordenamiento lógico
- Resultado funcional

**Ejemplo Ejercicio 01:**
```sql
CREATE OR REPLACE VIEW v_passenger_flight_traceability AS
SELECT 
    r.reservation_id, r.reservation_code,
    f.flight_number, f.flight_date,
    p.first_name, p.last_name,
    ts.ticket_number,
    fls.segment_number,
    a_origin.airport_code, a_dest.airport_code
FROM reservation r
INNER JOIN reservation_passenger rp ON ...
INNER JOIN person p ON ...
INNER JOIN ticket ts ON ...
INNER JOIN ticket_segment ts_seg ON ...
INNER JOIN flight_segment fls ON ...
INNER JOIN flight f ON ...
INNER JOIN flight_status fs ON ...
INNER JOIN airport a_origin ON ...
INNER JOIN airport a_dest ON ...
```

### 2. Trigger AFTER
- Función en PL/pgSQL
- Automatización de acciones posteriores
- Manejo de errores
- Mensajes informativos

**Ejemplo Ejercicio 01:**
```sql
CREATE OR REPLACE FUNCTION fn_create_boarding_pass_on_checkin()
RETURNS TRIGGER AS $$
BEGIN
    -- Obtener información del check_in
    -- Crear boarding_pass automáticamente
    -- Registrar el evento
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_boarding_pass_on_checkin
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_create_boarding_pass_on_checkin();
```

### 3. Procedimiento Almacenado
- Parámetros de entrada
- Validaciones
- Operaciones DML (INSERT/UPDATE)
- Manejo de excepciones

**Ejemplo Ejercicio 01:**
```sql
CREATE OR REPLACE PROCEDURE sp_register_checkin(
    p_ticket_segment_id uuid,
    p_user_account_id uuid,
    p_boarding_group_id uuid DEFAULT NULL,
    p_boarding_group_name varchar DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validaciones
    -- Insertar check-in
    -- Retornar resultado
END;
$$;
```

### 4. Scripts de Prueba
- Consultas exploratorias
- Ejemplos de invocación comentados
- Consultas de validación
- Verificación de resultados

---

## 🚀 Cómo Usar

### Prerequisitos
- PostgreSQL 10+
- Modelo base de datos creado (`modelo_postgresql.sql`)
- Datos de prueba cargados

### Pasos para Ejecutar

#### 1. Ejecutar el modelo base
```bash
psql -U usuario -d base_datos -f modelo_postgresql.sql
```

#### 2. Ejecutar la solución deseada
```bash
psql -U usuario -d base_datos -f ejercicio_0X_solucion.sql
```

Ejemplo:
```bash
psql -U postgres -d aerolinea -f ejercicio_01_solucion.sql
```

#### 3. Prueba interactiva
```bash
psql -U usuario -d base_datos

-- Ejecutar la vista
SELECT * FROM v_passenger_flight_traceability LIMIT 5;

-- Invocar el procedimiento
CALL sp_register_checkin(
    p_ticket_segment_id := 'ID_HERE',
    p_user_account_id := 'ID_HERE'
);

-- Verificar que el trigger funcionó
SELECT * FROM boarding_pass ORDER BY issued_at DESC LIMIT 1;
```

---

## 🔍 Ejemplos de Uso

### Ejercicio 01 - Check-in

**Ver trazabilidad del pasajero:**
```sql
SELECT 
    r.reservation_code,
    p.first_name, p.last_name,
    ts.ticket_number,
    f.flight_number,
    a_origin.airport_code, a_dest.airport_code
FROM v_passenger_flight_traceability
LIMIT 10;
```

**Registrar check-in:**
```sql
-- Primero obtener un ticket_segment existente
SELECT ts.ticket_segment_id 
FROM ticket_segment ts LIMIT 1;

-- Registrar check-in
CALL sp_register_checkin(
    p_ticket_segment_id := 'ticket_seg_id_aqui',
    p_user_account_id := 'user_id_aqui'
);
```

### Ejercicio 02 - Pagos

**Ver flujo de pagos:**
```sql
SELECT 
    s.sale_code,
    p.amount,
    ps.status_name,
    pt.transaction_type,
    c.iso_currency_code
FROM v_payment_transaction_flow
LIMIT 10;
```

**Registrar transacción:**
```sql
CALL sp_record_payment_transaction(
    p_payment_id := 'payment_id_aqui',
    p_transaction_type := 'CAPTURE',
    p_amount := 299.99,
    p_transaction_reference := 'TXN-001'
);
```

---

## 📚 Documentación Adicional

Para información detallada sobre cada solución, consulte:
- **SOLUCIONES_RESUMEN.md** - Resumen ejecutivo con todas las vistas y procedimientos
- Los archivos `.md` de enunciados (ejercicio_01.md, etc.)

---

## ✅ Checklist de Cumplimiento

Cada solución válida debe cumplir:

- ✓ Consulta INNER JOIN con mínimo 5 tablas
- ✓ Trigger AFTER INSERT o UPDATE funcional
- ✓ Procedimiento almacenado reutilizable
- ✓ Scripts de prueba documentados
- ✓ Consultas de validación incluidas
- ✓ Sin modificaciones a la estructura base
- ✓ Solo usa entidades reales del modelo

---

## 🛠️ Troubleshooting

### Error: "relation does not exist"
**Causa:** El modelo base no ha sido creado
**Solución:** Ejecutar primero `modelo_postgresql.sql`

### Error: "function already exists"
**Causa:** Reintentar ejecutar la misma solución
**Solución:** Usar `DROP FUNCTION IF EXISTS` o `CREATE OR REPLACE`

### Trigger no se dispara
**Causa:** Los datos de prueba no existen en las tablas relacionadas
**Solución:** Verificar que existen registros en las tablas FK

### Procedimiento retorna error de validación
**Causa:** Parámetros inválidos
**Solución:** Verificar IDs existentes en la BD con consultas previas

---

## 📝 Notas Importantes

1. **Datos Reales:** Todos los ejemplos en scripts de prueba deben ajustarse con IDs reales de la base de datos
2. **Triggers:** Se crean como `AFTER` para permitir validación y lógica posterior
3. **Vistas:** Creadas con `CREATE OR REPLACE` para viabilidad de reintentos
4. **Procedimientos:** Incluyen validaciones exhaustivas de parámetros

---

## 👨‍💻 Autor y Fecha
**Creado:** 16 de Abril de 2026  
**Modelo:** Sistema Integral de Aerolínea  
**Base de Datos:** PostgreSQL

---

## 📞 Soporte
Para preguntas sobre las soluciones:
1. Revisar el archivo `.md` del ejercicio específico
2. Consultar SOLUCIONES_RESUMEN.md
3. Verificar los scripts de prueba en cada archivo `.sql`
