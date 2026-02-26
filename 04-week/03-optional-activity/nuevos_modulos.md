# ✈️ NUEVOS MÓDULOS — MODELO DE DOMINIO
## Aerolínea — Extensión del modelo existente

---

# 1️⃣3️⃣ CREW MODULE (Personal de Vuelo)

## Descripción
Gestiona el personal operativo asignado a cada vuelo: pilotos, copilotos,
sobrecargos y personal de cabina. Controla certificaciones, disponibilidad
y asignaciones.

## Entidades y relaciones

```
┌─────────────────────┐         ┌─────────────────────┐
│      crew_member    │         │    type_crew_role   │
├─────────────────────┤         ├─────────────────────┤
│ id (PK)             │         │ id (PK)             │
│ person_id (FK)      │         │ (Piloto, Copiloto,  │
│ type_crew_role_id   │────────▶│  Sobrecargo, etc.)  │
│   (FK)              │         └─────────────────────┘
│ airline_id (FK)     │
│ status_crew_id (FK) │────────▶┌─────────────────────┐
└────────┬────────────┘         │   status_crew       │
         │                      ├─────────────────────┤
         │                      │ id (PK)             │
         │ 1                    │ (Activo, Licencia,  │
         │                      │  Suspendido, etc.)  │
         ▼ N                    └─────────────────────┘
┌─────────────────────┐
│  crew_certification │         ┌─────────────────────┐
├─────────────────────┤         │ type_certification  │
│ id (PK)             │         ├─────────────────────┤
│ crew_member_id (FK) │         │ id (PK)             │
│ type_certification  │────────▶│ (Licencia, Rating,  │
│   _id (FK)          │         │  Habilitación, etc.)│
│ issue_date          │         └─────────────────────┘
│ expiry_date         │
└─────────────────────┘

         ┌─────────────────────┐
         │   crew_member       │
         └────────┬────────────┘
                  │ N
                  ▼
┌─────────────────────────────────┐
│         flight_crew             │
├─────────────────────────────────┤         ┌─────────────┐
│ id (PK)                         │         │   flight    │
│ flight_id (FK)                  │────────▶│ id (PK)     │
│ crew_member_id (FK)             │         │ ...         │
│ type_crew_role_id (FK)          │         └─────────────┘
│ status_assignment_id (FK)       │────────▶┌──────────────────────┐
└─────────────────────────────────┘         │  status_assignment   │
                                            ├──────────────────────┤
                                            │ id (PK)              │
                                            │ (Confirmado,         │
                                            │  Pendiente,          │
                                            │  Reemplazado, etc.)  │
                                            └──────────────────────┘

┌─────────────────────┐
│  crew_rest_record   │
├─────────────────────┤
│ id (PK)             │         Registra períodos de descanso
│ crew_member_id (FK) │────────▶obligatorio entre vuelos
│ flight_crew_id (FK) │         (cumplimiento regulatorio)
│ rest_start          │
│ rest_end            │
└─────────────────────┘
```

## Lista de tablas — Módulo Crew

| Tabla                | Descripción                                      |
|----------------------|--------------------------------------------------|
| `crew_member`        | Personal de vuelo registrado en la aerolínea     |
| `type_crew_role`     | Roles: Piloto, Copiloto, Sobrecargo, Cabina      |
| `status_crew`        | Estado: Activo, En licencia, Suspendido          |
| `crew_certification` | Licencias y habilitaciones del tripulante        |
| `type_certification` | Tipos de certificación requeridos                |
| `flight_crew`        | Asignación de tripulantes a vuelos específicos   |
| `status_assignment`  | Estado de la asignación al vuelo                 |
| `crew_rest_record`   | Registro de descanso obligatorio entre vuelos    |

## Relaciones con módulos existentes

```
  person (Módulo Identity)
     └──▶ crew_member.person_id

  flight (Módulo Flight Control)
     └──▶ flight_crew.flight_id

  airline (Módulo Airline)
     └──▶ crew_member.airline_id
```

---

# 1️⃣4️⃣ NOTIFICATION MODULE (Notificaciones)

## Descripción
Gestiona el envío de notificaciones a clientes y tripulación sobre
cambios de vuelo, check-in, abordaje, promociones y alertas del sistema.
Registra el canal usado, el estado de entrega y el historial completo.

## Entidades y relaciones

```
┌──────────────────────────┐       ┌───────────────────────┐
│    notification_template │       │   type_notification   │
├──────────────────────────┤       ├───────────────────────┤
│ id (PK)                  │       │ id (PK)               │
│ type_notification_id(FK) │──────▶│ (Check-in, Retraso,   │
│ channel_id (FK)          │       │  Abordaje, Promo, etc)│
└──────────────────────────┘       └───────────────────────┘
           │
           │ usa plantilla
           ▼
┌──────────────────────────────────┐
│         notification             │
├──────────────────────────────────┤     ┌─────────────────────┐
│ id (PK)                          │     │  notification_      │
│ template_id (FK)                 │     │  channel            │
│ channel_id (FK)                  │────▶├─────────────────────┤
│ recipient_person_id (FK)         │     │ id (PK)             │
│ flight_id (FK)                   │     │ (Email, SMS, Push,  │
│ status_notification_id (FK)      │     │  WhatsApp, etc.)    │
│ sent_at                          │     └─────────────────────┘
│ scheduled_at                     │
└──────────┬───────────────────────┘
           │
           │ 1
           ▼ N
┌──────────────────────────────────┐
│    notification_delivery_log     │
├──────────────────────────────────┤     ┌──────────────────────────┐
│ id (PK)                          │     │   status_notification    │
│ notification_id (FK)             │     ├──────────────────────────┤
│ status_notification_id (FK)      │────▶│ id (PK)                  │
│ attempt_number                   │     │ (Pendiente, Enviado,     │
│ attempted_at                     │     │  Entregado, Fallido,     │
│ error_detail                     │     │  Leído)                  │
└──────────────────────────────────┘     └──────────────────────────┘

┌──────────────────────────────────┐
│   notification_preference        │
├──────────────────────────────────┤
│ id (PK)                          │     Preferencias del cliente:
│ person_id (FK)                   │────▶ qué notificaciones recibir
│ type_notification_id (FK)        │     y por qué canal
│ channel_id (FK)                  │
│ is_active                        │
└──────────────────────────────────┘
```

## Lista de tablas — Módulo Notification

| Tabla                        | Descripción                                          |
|------------------------------|------------------------------------------------------|
| `notification`               | Registro de cada notificación generada               |
| `notification_template`      | Plantillas reutilizables por tipo y canal            |
| `type_notification`          | Tipos: Check-in, Retraso, Abordaje, Promo, Alerta   |
| `notification_channel`       | Canales: Email, SMS, Push, WhatsApp                  |
| `status_notification`        | Estado: Pendiente, Enviado, Entregado, Fallido, Leído|
| `notification_delivery_log`  | Historial de intentos de entrega con detalle error   |
| `notification_preference`    | Preferencias de notificación por persona y canal     |

## Relaciones con módulos existentes

```
  person (Módulo Identity)
     └──▶ notification.recipient_person_id
     └──▶ notification_preference.person_id

  flight (Módulo Flight Control)
     └──▶ notification.flight_id
```

---

# 📊 RESUMEN — NUEVAS TABLAS AÑADIDAS AL MODELO

```
Módulo Crew (8 tablas nuevas)
├── crew_member
├── type_crew_role
├── status_crew
├── crew_certification
├── type_certification
├── flight_crew
├── status_assignment
└── crew_rest_record

Módulo Notification (7 tablas nuevas)
├── notification
├── notification_template
├── type_notification
├── notification_channel
├── status_notification
├── notification_delivery_log
└── notification_preference

Total tablas nuevas: 15
Total módulos en el modelo completo: 14
```

---

# 🔗 INTEGRACIÓN CON EL MODELO EXISTENTE

```
MÓDULO IDENTITY          MÓDULO FLIGHT CONTROL     MÓDULO AIRLINE
┌──────────┐             ┌──────────┐              ┌──────────┐
│  person  │             │  flight  │              │ airline  │
└────┬─────┘             └────┬─────┘              └────┬─────┘
     │                        │                         │
     │       ┌────────────────┘                         │
     │       │                                          │
     ▼       ▼                                          ▼
┌─────────────────┐                           ┌─────────────────┐
│  CREW MODULE    │                           │  CREW MODULE    │
│  crew_member    │◀──────── flight_crew ────▶│  crew_member    │
│  (person_id)   │          (flight_id)       │  (airline_id)   │
└─────────────────┘                           └─────────────────┘

     │
     ▼
┌─────────────────────┐
│ NOTIFICATION MODULE │
│ notification        │◀── notification.recipient_person_id
│ notification_pref   │◀── notification_preference.person_id
│ notification        │◀── notification.flight_id
└─────────────────────┘
```
