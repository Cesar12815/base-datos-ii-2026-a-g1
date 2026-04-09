# Modelo de datos base del sistema

## 1. Descripción general del modelo
El modelo de datos corresponde a un sistema integral de aerolínea, diseñado para soportar de forma relacional los procesos principales del negocio: gestión geográfica, identidad de personas, seguridad, clientes, fidelización, aeropuertos, aeronaves, operación de vuelos, reservas, tiquetes, abordaje, pagos y facturación.

Se trata de un modelo amplio y normalizado, en el que las entidades están separadas por dominios funcionales y conectadas mediante llaves foráneas para garantizar trazabilidad, integridad y consistencia en todo el flujo operativo y comercial.

---

## 2. Resumen previo del análisis realizado
Como base de trabajo, previamente se identificó y organizó el script en dominios funcionales. A partir de esa revisión, se determinó que el modelo no corresponde a un caso pequeño o aislado, sino a una solución empresarial con múltiples áreas del negocio conectadas entre sí.

También se verificó que:
- el modelo contiene más de 60 entidades,
- las relaciones entre tablas siguen una estructura consistente,
- existen restricciones de integridad mediante `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE` y `CHECK`,
- el diseño soporta trazabilidad end-to-end desde la reserva hasta el pago, abordaje y facturación.

---

## 3. Dominios del modelo y propósito general

### GEOGRAPHY AND REFERENCE DATA
**Entidades:** `time_zone`, `continent`, `country`, `state_province`, `city`, `district`, `address`, `currency`  
**Resumen:** Centraliza información geográfica y de referencia para ubicar aeropuertos, personas, proveedores y definir monedas operativas del sistema.

### AIRLINE
**Entidades:** `airline`  
**Resumen:** Representa la aerolínea operadora del sistema, incluyendo sus códigos y país base.

### IDENTITY
**Entidades:** `person_type`, `document_type`, `contact_type`, `person`, `person_document`, `person_contact`  
**Resumen:** Permite modelar la identidad de las personas, sus documentos y medios de contacto.

### SECURITY
**Entidades:** `user_status`, `security_role`, `security_permission`, `user_account`, `user_role`, `role_permission`  
**Resumen:** Administra autenticación, autorización y control de acceso al sistema.

### CUSTOMER AND LOYALTY
**Entidades:** `customer_category`, `benefit_type`, `loyalty_program`, `loyalty_tier`, `customer`, `loyalty_account`, `loyalty_account_tier`, `miles_transaction`, `customer_benefit`  
**Resumen:** Gestiona clientes, programas de fidelización, acumulación de millas, beneficios y niveles.

### AIRPORT
**Entidades:** `airport`, `terminal`, `boarding_gate`, `runway`, `airport_regulation`  
**Resumen:** Modela la infraestructura aeroportuaria y las condiciones regulatorias asociadas a cada aeropuerto.

### AIRCRAFT
**Entidades:** `aircraft_manufacturer`, `aircraft_model`, `cabin_class`, `aircraft`, `aircraft_cabin`, `aircraft_seat`, `maintenance_provider`, `maintenance_type`, `maintenance_event`  
**Resumen:** Gestiona aeronaves, fabricantes, configuración interna y procesos de mantenimiento.

### FLIGHT OPERATIONS
**Entidades:** `flight_status`, `delay_reason_type`, `flight`, `flight_segment`, `flight_delay`  
**Resumen:** Controla la operación de vuelos, sus segmentos, estados y retrasos.

### SALES, RESERVATION, TICKETING
**Entidades:** `reservation_status`, `sale_channel`, `fare_class`, `fare`, `ticket_status`, `reservation`, `reservation_passenger`, `sale`, `ticket`, `ticket_segment`, `seat_assignment`, `baggage`  
**Resumen:** Gestiona el flujo comercial principal: reserva, pasajero, venta, emisión de tiquetes, asignación de asiento y equipaje.

### BOARDING
**Entidades:** `boarding_group`, `check_in_status`, `check_in`, `boarding_pass`, `boarding_validation`  
**Resumen:** Soporta el proceso de check-in, emisión de pase de abordar y validación final de embarque.

### PAYMENT
**Entidades:** `payment_status`, `payment_method`, `payment`, `payment_transaction`, `refund`  
**Resumen:** Administra pagos, transacciones y devoluciones asociadas a las ventas.

### BILLING
**Entidades:** `tax`, `exchange_rate`, `invoice_status`, `invoice`, `invoice_line`  
**Resumen:** Gestiona impuestos, tasas de cambio, facturas y detalle facturable.

---

## 4. Enfoque de los ejercicios
Los ejercicios planteados sobre este modelo tendrán como propósito que el estudiante analice relaciones reales entre entidades y construya soluciones en PostgreSQL sin alterar la estructura base del sistema.

Cada ejercicio se formulará para que el estudiante:
- interprete correctamente los dominios involucrados,
- construya consultas con múltiples relaciones,
- diseñe automatizaciones con triggers,
- implemente lógica reutilizable mediante procedimientos almacenados,
- y demuestre técnicamente el funcionamiento con scripts de prueba.

---

## 5. Restricción general para todos los ejercicios
Todos los ejercicios deben resolverse respetando estrictamente el modelo entregado.

No está permitido:
- cambiar atributos existentes,
- renombrar tablas o columnas,
- alterar relaciones,
- inventar entidades fuera del script base,
- ni modificar la estructura general del modelo.

La solución deberá construirse únicamente sobre las entidades y relaciones reales definidas en el script.

---

# Ejercicio 01 - Flujo de check-in y trazabilidad comercial del pasajero

## 1. Contexto del ejercicio
La aerolínea requiere fortalecer la trazabilidad operativa del proceso de abordaje, desde la reserva del pasajero hasta la emisión del pase de abordar. Para ello, se necesita consultar información consolidada del flujo comercial y, además, automatizar parte del proceso de check-in mediante lógica en base de datos.

Este ejercicio se desarrollará sobre el modelo relacional existente, sin cambiar atributos, sin renombrar entidades y sin alterar la estructura base del script entregado.

---

## 2. Dominios involucrados

### SALES, RESERVATION, TICKETING
**Entidades:** `reservation`, `reservation_passenger`, `sale`, `ticket`, `ticket_segment`  
**Propósito:** Gestionar el flujo comercial principal del sistema: reserva, pasajero asociado, venta, tiquete emitido y segmentos de vuelo asociados.

### FLIGHT OPERATIONS
**Entidades:** `flight`, `flight_segment`, `flight_status`  
**Propósito:** Administrar la operación de vuelos, sus segmentos, fechas de servicio y estado operativo.

### IDENTITY
**Entidades:** `person`  
**Propósito:** Representar la identidad del pasajero para relacionarlo con la reserva y el tiquete.

### BOARDING
**Entidades:** `check_in`, `check_in_status`, `boarding_group`, `boarding_pass`  
**Propósito:** Gestionar el proceso de registro previo al abordaje y la generación del pase de abordar.

### SECURITY
**Entidades:** `user_account`  
**Propósito:** Identificar el usuario del sistema que ejecuta el proceso de check-in.

> Nota: estos dominios y entidades existen en el modelo base y forman parte de las relaciones reales del script suministrado. :contentReference[oaicite:2]{index=2}

---

## 3. Planteamiento del problema
La aerolínea desea consultar qué pasajeros ya se encuentran asociados a reservas y tiquetes válidos para un vuelo determinado, y adicionalmente automatizar la creación del pase de abordar cuando se registra un check-in.

A partir de esta necesidad, el estudiante deberá diseñar una solución orientada a consulta, automatización y encapsulamiento de lógica en base de datos.

---

## 4. Objetivo del ejercicio
Diseñar una solución en PostgreSQL que permita:

1. Consultar información consolidada del flujo comercial y operativo de un pasajero.
2. Automatizar una acción posterior al registro de check-in mediante un trigger `AFTER`.
3. Encapsular el registro del check-in en un procedimiento almacenado reutilizable.
4. Demostrar el funcionamiento mediante scripts de prueba.

---

## 5. Requerimiento 1 - Consulta con `INNER JOIN` de al menos 5 tablas

### Enunciado
Construya una consulta SQL que permita listar la trazabilidad básica de pasajeros por vuelo, vinculando la información comercial y operativa del sistema.

### Restricciones obligatorias
- Debe usar **`INNER JOIN`**
- Debe involucrar **mínimo 5 tablas**
- Debe usar únicamente entidades y atributos existentes en el modelo base
- No se permite cambiar nombres de tablas ni columnas
- La consulta debe ser coherente con las relaciones reales del modelo

### Tablas mínimas sugeridas
El estudiante deberá incluir, como mínimo, una combinación válida de tablas como:
- `reservation`
- `reservation_passenger`
- `person`
- `ticket`
- `ticket_segment`
- `flight_segment`
- `flight`

### Resultado esperado a nivel funcional
La consulta debe permitir responder una necesidad como esta:

> “Mostrar los pasajeros asociados a un vuelo, indicando la reserva, el tiquete, el segmento y la fecha del servicio”.

### Campos esperados en el resultado
Como mínimo, el resultado debe exponer columnas equivalentes a:
- código de reserva
- número de vuelo
- fecha de servicio
- número de tiquete
- secuencia del pasajero en la reserva
- nombre del pasajero
- segmento del vuelo
- hora programada de salida

> El estudiante define la consulta exacta, pero debe respetar estrictamente el modelo base.

---

## 6. Requerimiento 2 - Trigger `AFTER`

### Enunciado
Diseñe un trigger `AFTER INSERT` que automatice una acción posterior al registro de un `check_in`.

### Condición funcional del trigger
Cuando se inserte un nuevo registro en la tabla `check_in`, el trigger deberá ejecutar una acción automática relacionada con el proceso de abordaje.

### Restricción funcional obligatoria
La automatización deberá involucrar la tabla:

- `boarding_pass`

### Meta del trigger
El comportamiento esperado es que, después del registro del check-in, exista una evidencia automatizada del proceso en el flujo de abordaje.

### Restricciones del trigger
- Debe ser un trigger **`AFTER INSERT`**
- Debe operar sobre tablas reales del modelo
- No puede modificar atributos existentes del modelo base
- No puede cambiar la definición de las tablas originales
- La solución debe ser coherente con las relaciones entre `check_in` y `boarding_pass`

### Demostración obligatoria
El estudiante deberá entregar un **script de prueba** que dispare el trigger.

### Condición mínima de la demostración
El script de prueba debe:
1. Identificar o preparar los datos necesarios del modelo base
2. Ejecutar una inserción en `check_in`
3. Verificar el efecto posterior generado por el trigger

> El estudiante deberá decidir cómo validar el resultado, siempre sobre entidades reales del modelo.

---

## 7. Requerimiento 3 - Procedimiento almacenado

### Enunciado
Diseñe un procedimiento almacenado que encapsule el proceso de registro de un check-in.

### Propósito del procedimiento
Centralizar en una sola unidad lógica el registro del proceso de check-in para un pasajero sobre un segmento de vuelo ya ticketed.

### Alcance funcional mínimo
El procedimiento debe permitir registrar información relacionada con:
- segmento ticketed
- estado del check-in
- grupo de abordaje, si aplica
- usuario que ejecuta la operación
- fecha y hora del check-in

### Restricciones obligatorias
- Debe implementarse como **procedimiento almacenado**
- Debe trabajar sobre tablas y atributos existentes
- No puede cambiar la estructura del modelo base
- Debe ser reutilizable
- Debe poder invocarse desde un script SQL independiente

### Integración esperada
La inserción realizada por el procedimiento deberá ser compatible con el trigger solicitado en el requerimiento 2.

> Es decir, al usar el procedimiento, debe ser posible evidenciar indirectamente la ejecución del trigger `AFTER INSERT`.

---

## 8. Script de uso del procedimiento

### Enunciado
El estudiante deberá entregar un script SQL que invoque el procedimiento almacenado desarrollado.

### Propósito del script
Demostrar que el procedimiento:
1. recibe los parámetros necesarios,
2. registra el check-in,
3. activa el trigger definido previamente,
4. deja evidencia verificable del proceso.

### Contenido mínimo esperado
El script debe incluir:
- búsqueda o selección previa de identificadores necesarios
- invocación del procedimiento
- consulta posterior de validación

---

## 9. Entregables del estudiante
El estudiante deberá entregar:

1. **Consulta SQL** con `INNER JOIN` de mínimo 5 tablas  
2. **Trigger `AFTER INSERT`**  
3. **Función/objeto auxiliar necesario para el trigger**, si su diseño lo requiere  
4. **Procedimiento almacenado**  
5. **Script que dispare el trigger**  
6. **Script que invoque el procedimiento**  
7. **Consultas de validación** que demuestren el funcionamiento

---

## 10. Restricciones generales del ejercicio
- No modificar atributos existentes
- No renombrar tablas ni columnas
- No alterar el modelo base entregado
- No resolver el ejercicio con tablas ajenas al problema sin justificación técnica
- No usar datos inventados fuera de la estructura real del script
- Toda la solución debe respetar las relaciones reales del modelo

---

## 11. Criterios de aceptación
La solución propuesta por el estudiante será válida si cumple con todo lo siguiente:

- La consulta utiliza `INNER JOIN`
- La consulta relaciona al menos 5 tablas reales del modelo
- El trigger es `AFTER INSERT`
- El trigger se ejecuta sobre una tabla real del flujo de boarding
- El trigger produce un efecto verificable
- Existe un script que demuestra su ejecución
- El procedimiento almacenado encapsula una operación útil del negocio
- Existe un script que invoca el procedimiento
- La invocación del procedimiento permite evidenciar también el funcionamiento del trigger
- No se alteró la estructura base del modelo

---

## 12. Observación final
Este ejercicio no solicita la solución final enunciada en el documento. El estudiante deberá diseñarla e implementarla respetando las restricciones técnicas del modelo base.

