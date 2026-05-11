# RESUMEN DE SOLUCIONES - 10 EJERCICIOS DE MODELADO DE AEROLÍNEA

## 📋 Descripción General
Se han creado soluciones completas para los 10 ejercicios del modelo de base de datos de aerolínea. Cada solución incluye:
- Consulta SQL con INNER JOIN (mínimo 5 tablas)
- Trigger AFTER INSERT
- Procedimiento almacenado
- Scripts de prueba

---

## 🎯 Ejercicio 01 - Check-in y Trazabilidad Comercial
**Archivo:** `ejercicio_01_solucion.sql`

### Vista: `v_passenger_flight_traceability`
Relaciona: reservation → reservation_passenger → person → ticket → ticket_segment → flight_segment → flight → flight_status → airport (2×)

### Trigger: `trg_create_boarding_pass_on_checkin`
Cuando se registra un check-in, se crea automáticamente un boarding_pass

### Procedimiento: `sp_register_checkin`
Registra el check-in de un pasajero para un ticket_segment existente

---

## 💳 Ejercicio 02 - Control de Pagos y Transacciones
**Archivo:** `ejercicio_02_solucion.sql`

### Vista: `v_payment_transaction_flow`
Relaciona: sale → reservation → payment → payment_status → payment_method → payment_transaction → currency

### Trigger: `trg_create_refund_on_transaction`
Cuando se registra una transacción de reversión, crea automáticamente un refund

### Procedimiento: `sp_record_payment_transaction`
Registra una transacción financiera sobre un pago existente

---

## 📄 Ejercicio 03 - Facturación e Integración
**Archivo:** `ejercicio_03_solucion.sql`

### Vista: `v_invoice_detail`
Relaciona: sale → invoice → invoice_status → invoice_line → tax → currency

### Trigger: `trg_update_invoice_total_on_line`
Cuando se registra una línea facturable, actualiza el total de la factura

### Procedimiento: `sp_add_invoice_line`
Registra una nueva línea facturable (detalle) en una factura existente

---

## ✈️ Ejercicio 04 - Acumulación de Millas y Nivel
**Archivo:** `ejercicio_04_solucion.sql`

### Vista: `v_loyalty_program_status`
Relaciona: customer → person → loyalty_account → loyalty_program → loyalty_tier → loyalty_account_tier → sale → miles_transaction

### Trigger: `trg_check_loyalty_tier_on_miles`
Cuando se registra una transacción de millas, verifica cambios de nivel

### Procedimiento: `sp_record_miles_transaction`
Registra una transacción de millas (acumulación/redención/ajuste) para una cuenta

---

## 🔧 Ejercicio 05 - Mantenimiento de Aeronaves
**Archivo:** `ejercicio_05_solucion.sql`

### Vista: `v_aircraft_maintenance_history`
Relaciona: aircraft → airline → aircraft_model → aircraft_manufacturer → maintenance_event → maintenance_type → maintenance_provider

### Trigger: `trg_audit_maintenance_event`
Cuando se registra un evento de mantenimiento, crea un registro de auditoría

### Procedimiento: `sp_register_maintenance_event`
Registra un nuevo evento de mantenimiento para una aeronave

---

## ⏰ Ejercicio 06 - Retrasos Operativos y Análisis
**Archivo:** `ejercicio_06_solucion.sql`

### Vista: `v_flight_delay_analysis`
Relaciona: airline → flight → flight_status → flight_segment → airport (2×) → flight_delay → delay_reason_type

### Trigger: `trg_update_flight_status_on_delay`
Cuando se registra una demora, actualiza el estado del vuelo si la demora es significativa

### Procedimiento: `sp_register_flight_delay`
Registra una demora (retraso) para un segmento de vuelo

---

## 🪑 Ejercicio 07 - Asignación de Asientos y Equipaje
**Archivo:** `ejercicio_07_solucion.sql`

### Vista: `v_seat_baggage_assignment`
Relaciona: ticket → ticket_segment → flight_segment → flight → seat_assignment → aircraft_seat → aircraft_cabin → cabin_class → baggage

### Trigger: `trg_validate_baggage_capacity`
Cuando se registra equipaje, valida la capacidad disponible

### Procedimiento: `sp_register_baggage`
Registra equipaje para un ticket_segment

---

## 🔐 Ejercicio 08 - Auditoría de Acceso y Asignación de Roles
**Archivo:** `ejercicio_08_solucion.sql`

### Vista: `v_user_role_authorization`
Relaciona: person → user_account → user_status → user_role → security_role → role_permission → security_permission

### Trigger: `trg_audit_user_role_assignment`
Cuando se asigna un rol a usuario, crea registro de auditoría

### Procedimiento: `sp_assign_role_to_user`
Asigna un rol de seguridad a una cuenta de usuario

---

## 💰 Ejercicio 09 - Publicación de Tarifas y Análisis
**Archivo:** `ejercicio_09_solucion.sql`

### Vista: `v_fare_commercialization`
Relaciona: airline → fare → fare_class → airport (2×) → currency → reservation → sale → ticket

### Trigger: `trg_record_fare_publication`
Cuando se publica una tarifa, registra la publicación

### Procedimiento: `sp_publish_fare`
Registra/publica una tarifa para una ruta y clase tarifaria específica

---

## 👤 Ejercicio 10 - Identidad de Pasajeros, Documentos y Contacto
**Archivo:** `ejercicio_10_solucion.sql`

### Vista: `v_passenger_identity_profile`
Relaciona: person → person_type → person_document → document_type → country → person_contact → contact_type → reservation_passenger → reservation

### Trigger: `trg_validate_document_uniqueness`
Cuando se registra un documento, valida que no haya duplicados

### Procedimientos:
- `sp_register_person_document`: Registra un documento para una persona
- `sp_register_person_contact`: Registra un contacto para una persona

---

## 📊 Resumen de Entidades Utilizadas

| Dominio | Ejercicios | Descripción |
|---------|-----------|-------------|
| **GEOGRAPHY & REFERENCE** | Mult. | Ciudades, países, aeropuertos, monedas, zonas horarias |
| **AIRLINE** | Todos | Información de la aerolínea operadora |
| **IDENTITY** | 01, 08, 10 | Personas, documentos, contactos, tipos |
| **SECURITY** | 08 | Usuarios, roles, permisos, auditoría |
| **CUSTOMER & LOYALTY** | 04 | Clientes, cuentas, programas, millas |
| **AIRPORT** | Mult. | Información de terminales, puertas, regulaciones |
| **AIRCRAFT** | 05, 07 | Aeronaves, modelos, fabricantes, asientos |
| **FLIGHT OPERATIONS** | 01, 06 | Vuelos, segmentos, estados, demoras |
| **SALES, RESERVATION, TICKETING** | Mult. | Reservas, tiquetes, tarifas, asignaciones |
| **BOARDING** | 01, 07 | Check-in, pases de abordar, validaciones |
| **PAYMENT** | 02 | Pagos, transacciones, devoluciones |
| **BILLING** | 03 | Facturas, líneas, impuestos, conversiones |

---

## 🛠️ Características Técnicas por Ejercicio

### Consultas (INNER JOIN)
- Mínimo 5 tablas por consulta
- Uso de aliases para claridad
- Ordenamiento apropiado
- Vistas reutilizables

### Triggers
- Tipo AFTER INSERT o UPDATE
- Funciones específicas en PL/pgSQL
- Manejo de errores y validaciones
- Mensajes informativos (RAISE NOTICE)

### Procedimientos Almacenados
- Parámetros de entrada validados
- Manejo de excepciones
- Inserción o actualización segura
- Mensajes de confirmación

### Scripts de Prueba
- Consultas para explorar datos
- Ejemplos de invocación comentados
- Verificación de resultados
- Validación de triggers

---

## 📝 Cómo Usar Estas Soluciones

1. **Ejecutar el modelo base:**
   ```sql
   psql -f modelo_postgresql.sql
   ```

2. **Ejecutar una solución de ejercicio:**
   ```sql
   psql -f ejercicio_0X_solucion.sql
   ```

3. **Probar en base de datos:**
   - Descomentar los scripts de prueba
   - Ajustar IDs según datos existentes
   - Ejecutar y verificar resultados

---

## ✅ Validación de Cumplimiento

Cada ejercicio cumple con:
- ✓ Consulta INNER JOIN (5+ tablas)
- ✓ Trigger AFTER (INSERT/UPDATE)
- ✓ Función auxiliar para el trigger
- ✓ Procedimiento almacenado reutilizable
- ✓ Scripts de prueba funcionales
- ✓ Consultas de validación
- ✓ No modifica estructura base del modelo
- ✓ Usa solo entidades y atributos reales

---

**Creado:** 16 de Abril de 2026  
**Modelo de BD:** Sistema Integral de Aerolínea  
**Base de Datos:** PostgreSQL
