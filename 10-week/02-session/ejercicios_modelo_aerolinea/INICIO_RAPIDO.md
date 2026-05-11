# 🎓 GUÍA RÁPIDA - SOLUCIONES DE EJERCICIOS

## 📌 Acceso Rápido

| Ejercicio | Tema | SQL | Documentación |
|-----------|------|-----|--------------|
| 01 | Check-in | [ejercicio_01_solucion.sql](ejercicio_01_solucion.sql) | [ejercicio_01.md](ejercicio_01.md) |
| 02 | Pagos | [ejercicio_02_solucion.sql](ejercicio_02_solucion.sql) | [ejercicio_02.md](ejercicio_02.md) |
| 03 | Facturación | [ejercicio_03_solucion.sql](ejercicio_03_solucion.sql) | [ejercicio_03.md](ejercicio_03.md) |
| 04 | Millas | [ejercicio_04_solucion.sql](ejercicio_04_solucion.sql) | [ejercicio_04.md](ejercicio_04.md) |
| 05 | Mantenimiento | [ejercicio_05_solucion.sql](ejercicio_05_solucion.sql) | [ejercicio_05.md](ejercicio_05.md) |
| 06 | Retrasos | [ejercicio_06_solucion.sql](ejercicio_06_solucion.sql) | [ejercicio_06.md](ejercicio_06.md) |
| 07 | Asientos/Equipaje | [ejercicio_07_solucion.sql](ejercicio_07_solucion.sql) | [ejercicio_07.md](ejercicio_07.md) |
| 08 | Seguridad/Roles | [ejercicio_08_solucion.sql](ejercicio_08_solucion.sql) | [ejercicio_08.md](ejercicio_08.md) |
| 09 | Tarifas | [ejercicio_09_solucion.sql](ejercicio_09_solucion.sql) | [ejercicio_09.md](ejercicio_09.md) |
| 10 | Identidad | [ejercicio_10_solucion.sql](ejercicio_10_solucion.sql) | [ejercicio_10.md](ejercicio_10.md) |

---

## 🚀 Inicio Rápido

### Opción 1: Terminal de PostgreSQL
```bash
cd /ruta/a/ejercicios_modelo_aerolinea
psql -U postgres -d aerolinea -f ejercicio_01_solucion.sql
```

### Opción 2: Usar el Script
```bash
chmod +x run_solution.sh
./run_solution.sh 01 aerolinea postgres
```

### Opción 3: Desde pgAdmin
1. Abrir pgAdmin → Servidor → Base de datos
2. Herramientas → Editor de consultas
3. Abrir archivo SQL → Ejecutar

---

## 📦 Componentes por Ejercicio

```
ejercicio_0X_solucion.sql
├── Vista/View
│   └── v_xxxx (INNER JOIN 5+ tablas)
├── Función PL/pgSQL
│   └── fn_xxxx_trigger()
├── Trigger
│   └── trg_xxxx
├── Procedimiento Almacenado
│   └── sp_xxxxx(parámetros)
└── Scripts de Prueba (comentados)
    ├── Consulta explorativa
    ├── Obtener datos para prueba
    ├── Invocar procedimiento
    └── Validar resultado
```

---

## 💡 Ejemplos Rápidos

### Ej 01: Registrar Check-in
```sql
-- Cargar solución
\i ejercicio_01_solucion.sql

-- Ver datos disponibles
SELECT * FROM v_passenger_flight_traceability LIMIT 1;

-- Obtener IDs
SELECT ts.ticket_segment_id, ua.user_account_id 
FROM ticket_segment ts 
JOIN user_account ua LIMIT 1;

-- Registrar check-in
CALL sp_register_checkin(
    'ticket_seg_id', 'user_id'
);

-- Validar boarding_pass creado
SELECT * FROM boarding_pass ORDER BY created_at DESC LIMIT 1;
```

### Ej 02: Registrar Transacción de Pago
```sql
-- Cargar solución
\i ejercicio_02_solucion.sql

-- Ver pagos
SELECT * FROM v_payment_transaction_flow LIMIT 1;

-- Registrar transacción
CALL sp_record_payment_transaction(
    'payment_id', 'CAPTURE', 100.00, 'REF-001'
);

-- Verificar
SELECT * FROM payment_transaction ORDER BY created_at DESC LIMIT 1;
```

### Ej 04: Registrar Millas
```sql
-- Cargar solución
\i ejercicio_04_solucion.sql

-- Ver cuentas
SELECT * FROM v_loyalty_program_status LIMIT 1;

-- Registrar millas
CALL sp_record_miles_transaction(
    'loyalty_account_id', 500, 'EARN'
);

-- Verificar acumulación
SELECT SUM(miles_quantity) FROM miles_transaction 
WHERE loyalty_account_id = 'id_aqui';
```

---

## 📊 Estadísticas de Soluciones

### Entidades Utilizadas
- **Total Tablas:** 60+
- **INNER JOINs:** 5-9 por ejercicio
- **Vistas Creadas:** 10
- **Triggers Creados:** 10
- **Procedimientos:** 12
- **Funciones PL/pgSQL:** 10

### Complejidad por Ejercicio
| Ej | Complejidad | INNER JOINs | Procedimientos |
|----|-------------|------------|----------------|
| 01 | Medio | 9 | 1 |
| 02 | Medio | 7 | 1 |
| 03 | Bajo | 6 | 1 |
| 04 | Bajo | 8 | 1 |
| 05 | Bajo | 7 | 1 |
| 06 | Medio | 10 | 1 |
| 07 | Medio | 9 | 1 |
| 08 | Medio | 7 | 1 |
| 09 | Medio | 8 | 1 |
| 10 | Medio | 8 | 2 |

---

## 📚 Documentos de Referencia

| Documento | Contenido |
|-----------|----------|
| [README.md](README.md) | Guía completa de uso |
| [SOLUCIONES_RESUMEN.md](SOLUCIONES_RESUMEN.md) | Resumen ejecutivo de todas las soluciones |
| `ejercicio_0X.md` | Enunciado y requerimientos específicos |
| `ejercicio_0X_solucion.sql` | Implementación completa |

---

## ⚠️ Prerequisitos

- ✅ PostgreSQL 10+
- ✅ Modelo base creado
- ✅ Datos de prueba disponibles
- ✅ Usuario con permisos CREATE/INSERT/UPDATE

---

## 🔧 Estructura de Repositorio

```
ejercicios_modelo_aerolinea/
├── ejercicio_01.md
├── ejercicio_01_solucion.sql
├── ejercicio_02.md
├── ejercicio_02_solucion.sql
├── ... (ejercicios 3-10)
├── README.md
├── SOLUCIONES_RESUMEN.md
├── INICIO_RAPIDO.md (este archivo)
└── run_solution.sh
```

---

## ✨ Características de Cada Solución

### ✅ Lo Que Incluye
- Consulta SQL multi-tabla
- Trigger AFTER con función
- Procedimiento almacenado
- Scripts de prueba
- Validaciones y manejo de errores
- Mensajes informativos

### ✏️ Lo Que NO Modifica
- Estructura de tablas
- Nombres de columnas
- Relaciones existentes
- Datos sin autorización

---

## 🎯 Próximos Pasos

1. **Seleccionar un ejercicio** de la tabla superior
2. **Leer el enunciado** en `ejercicio_0X.md`
3. **Ejecutar la solución** con `psql` o script
4. **Probar el código** con ejemplos comentados
5. **Validar los resultados** con consultas de verificación

---

## 📞 Soporte Rápido

**¿Cómo ejecutar una solución?**
→ Ver sección "Inicio Rápido"

**¿Cómo entender el código?**
→ Consultar [SOLUCIONES_RESUMEN.md](SOLUCIONES_RESUMEN.md)

**¿Qué es cada componente?**
→ Ver sección "Componentes por Ejercicio"

**¿Tengo un error?**
→ Verificar sección "Exemplos Rápidos"

---

**Creado:** 16 Abril 2026  
**Versión:** 1.0  
**Estado:** ✅ Completo
