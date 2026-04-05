# Taller: Roles, Privilegios y Pruebas en PostgreSQL
**Base de Datos II · Semana 6 · Sesión 2 · CORHUILA 2026**

---

## 1. Descripción del escenario

| Campo | Detalle |
|---|---|
| **Objetivo** | Implementar un esquema de seguridad básico y verificable siguiendo el principio de mínimo privilegio |
| **Motor** | PostgreSQL |
| **Esquema** | `public` |
| **Base de datos** | `basedatos2` |
| **Usuarios creados** | `u_reportes`, `u_app`, `u_admin` |
| **Roles de grupo** | `rol_lectura`, `rol_escritura`, `rol_admin` |

---

## 2. Paso 1 — Creación de roles de grupo

| # | Comando SQL | Descripción |
|---|---|---|
| 1 | `CREATE ROLE rol_lectura;` | Rol para usuarios que solo necesitan consultar datos |
| 2 | `CREATE ROLE rol_escritura;` | Rol para usuarios que pueden insertar, actualizar y eliminar |
| 3 | `CREATE ROLE rol_admin;` | Rol para administradores con control total |

---

## 3. Paso 2 — Creación de usuarios con LOGIN

| Usuario | Comando SQL | Propósito |
|---|---|---|
| `u_reportes` | `CREATE ROLE u_reportes LOGIN PASSWORD 'Cambiar_123';` | Usuario de área de reportes / analistas |
| `u_app` | `CREATE ROLE u_app LOGIN PASSWORD 'Cambiar_123';` | Usuario de la aplicación backend |
| `u_admin` | `CREATE ROLE u_admin LOGIN PASSWORD 'Cambiar_123';` | Usuario administrador de la base de datos |

---

## 4. Paso 3 — Asignación de roles a usuarios

| Usuario | Rol(es) asignado(s) | Comando SQL |
|---|---|---|
| `u_reportes` | `rol_lectura` | `GRANT rol_lectura TO u_reportes;` |
| `u_app` | `rol_lectura`, `rol_escritura` | `GRANT rol_lectura, rol_escritura TO u_app;` |
| `u_admin` | `rol_admin` | `GRANT rol_admin TO u_admin;` |

---

## 5. Paso 4 — Permisos a nivel de base de datos y esquema

| Objeto | Permiso | Beneficiario | Comando SQL |
|---|---|---|---|
| Base de datos `basedatos2` | `CONNECT` | `rol_lectura`, `rol_escritura`, `rol_admin` | `GRANT CONNECT ON DATABASE basedatos2 TO rol_lectura, rol_escritura, rol_admin;` |
| Esquema `public` | `USAGE` | `rol_lectura`, `rol_escritura`, `rol_admin` | `GRANT USAGE ON SCHEMA public TO rol_lectura, rol_escritura, rol_admin;` |
| Esquema `public` | `CREATE` | `rol_admin` | `GRANT CREATE ON SCHEMA public TO rol_admin;` |

> **Nota:** `USAGE` permite ver y usar los objetos del esquema. `CREATE` permite crear nuevas tablas u objetos dentro de él.

---

## 6. Paso 5 — Permisos sobre tablas

| Rol | Privilegios sobre tablas | Comando SQL |
|---|---|---|
| `rol_lectura` | `SELECT` | `GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_lectura;` |
| `rol_escritura` | `INSERT`, `UPDATE`, `DELETE` | `GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rol_escritura;` |
| `rol_admin` | Todos (`ALL PRIVILEGES`) | `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;` |

---

## 7. Paso 6 — Permisos sobre secuencias (autoincremento)

| Rol | Privilegios | Comando SQL | ¿Por qué? |
|---|---|---|---|
| `rol_escritura` | `USAGE`, `SELECT` | `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_escritura, rol_admin;` | Necesario para que los `INSERT` con columnas `SERIAL` funcionen correctamente |
| `rol_admin` | `USAGE`, `SELECT` | (mismo comando) | Administración completa de secuencias |

---

## 8. Resumen de permisos por perfil (mínimo privilegio)

| Acción | `u_reportes` | `u_app` | `u_admin` |
|---|:---:|:---:|:---:|
| `CONNECT` a la base de datos | ✅ | ✅ | ✅ |
| `USAGE` del esquema `public` | ✅ | ✅ | ✅ |
| `SELECT` en tablas | ✅ | ✅ | ✅ |
| `INSERT` en tablas | ❌ | ✅ | ✅ |
| `UPDATE` en tablas | ❌ | ✅ | ✅ |
| `DELETE` en tablas | ❌ | ✅ | ✅ |
| `CREATE TABLE` | ❌ | ❌ | ✅ |
| `ALL PRIVILEGES` | ❌ | ❌ | ✅ |

---

## 9. Pruebas de verificación

### 9.1. Plan de pruebas

| # | Prueba | Usuario | Acción | Resultado esperado |
|---|---|---|---|---|
| A | SELECT sobre tabla `estudiante` | `u_reportes` | `SELECT * FROM estudiante;` | ✅ Éxito |
| B | INSERT sobre tabla `estudiante` | `u_app` | `INSERT INTO estudiante(nombre) VALUES ('Prueba App');` | ✅ Éxito |
| C | INSERT sobre tabla `estudiante` | `u_reportes` | `INSERT INTO estudiante(nombre) VALUES ('Prueba Reportes');` | ❌ Error: `permission denied` |
| D | CREATE TABLE | `u_app` | `CREATE TABLE tabla_no_permitida (...);` | ❌ Error: `permission denied for schema public` |
| E | CREATE TABLE | `u_admin` | `CREATE TABLE tabla_admin_ok (...);` | ✅ Éxito |

### 9.2. Cómo ejecutar las pruebas

| Herramienta | Cómo cambiar de usuario |
|---|---|
| **psql** | `\c basedatos2 u_reportes` luego ejecutar la sentencia |
| **pgAdmin** | Crear una nueva conexión con las credenciales de cada usuario |

### 9.3. Errores esperados (evidencia de seguridad)

| Prueba | Mensaje de error esperado en PostgreSQL |
|---|---|
| INSERT como `u_reportes` | `ERROR: permission denied for table estudiante` |
| CREATE TABLE como `u_app` | `ERROR: permission denied for schema public` |

---

## 10. Descripción de permisos por usuario (resumen ejecutivo)

| Usuario | Descripción de sus permisos |
|---|---|
| `u_reportes` | Solo puede conectarse a la base de datos y ejecutar consultas `SELECT` en todas las tablas del esquema `public`. No puede modificar, insertar, eliminar ni crear objetos. |
| `u_app` | Puede conectarse, consultar (`SELECT`) e insertar/actualizar/eliminar datos (`INSERT`, `UPDATE`, `DELETE`). No puede crear ni modificar la estructura de la base de datos (sin `CREATE`). |
| `u_admin` | Tiene control total: puede conectarse, leer, escribir, crear tablas, modificar objetos y administrar el esquema `public`. Es el único con privilegio `CREATE` en el esquema. |

---

## 11. Nota sobre objetos futuros

| Situación | Solución |
|---|---|
| Se crean nuevas tablas después de ejecutar los `GRANT` | Los permisos **no se aplican automáticamente** a las tablas nuevas |
| Solución recomendada | Usar `ALTER DEFAULT PRIVILEGES` para que los permisos se apliquen a objetos creados en el futuro |
| Ejemplo | `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_lectura;` |

---

*Material elaborado para: Base de Datos II · Unidad 2 · Semana 6 · Sesión 2 · CORHUILA 2026*
