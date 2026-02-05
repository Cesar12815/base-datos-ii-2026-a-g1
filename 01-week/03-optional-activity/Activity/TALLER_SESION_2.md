# Modelado y Gestión de Bases de Datos
## Semana 1 · Sesión 2: Aplicación de los fundamentos

---

## Índice
1. [Repaso guiado](#repaso-guiado)
2. [Arquitectura y roles](#arquitectura-y-roles)
3. [Primer diseño de BD](#primer-diseño-de-bd)
4. [Reflexión final](#reflexión-final)

---

## 1. Repaso guiado

### Tabla de conceptos clave

| Concepto | Definición breve | Ejemplo en contexto académico |
|----------|-----------------|-------------------------------|
| **Dato** | Registro aislado sin contexto. | 4.5, "BD-101", "María López". |
| **Información** | Dato interpretado que responde una pregunta. | "María López obtuvo 4.5 en Modelado y Gestión de BD". |
| **Base de datos** | Conjunto organizado de datos relacionados. | Esquema institucional de estudiantes, asignaturas y matrículas. |
| **SGBD** | Software que administra y da acceso a la base de datos. | PostgreSQL administrando las tablas del sistema académico. |

### Actividad breve de activación: Dato vs. Información

**Escenario elegido: Tienda en Línea de Electrónica**

#### Ejemplo de Dato:
- `299.99` (solo número)
- `"Monitor LED 27 pulgadas"` (solo texto)
- `2024-02-05` (solo fecha)

#### Ejemplo de Información correspondiente:
- "El Monitor LED de 27 pulgadas cuesta $299.99 y está disponible en nuestro inventario desde el 2024-02-05"

#### Impacto en el diseño de la base de datos:

**Para una tienda en línea:**
- Tabla `Productos`: almacenar código, nombre, descripción, precio, categoría
- Tabla `Inventario`: cantidad disponible, ubicación del almacén, fecha de entrada
- Tabla `Precios_Historicos`: registrar cambios de precio a lo largo del tiempo
- Tabla `Clientes`: información de contacto, historial de compras
- Tabla `Pedidos`: relacionar cliente con productos, cantidades, fechas

**Si fuera una clínica:**
- Enfoque en pacientes, citas, diagnósticos, medicamentos prescritos
- Énfasis en seguridad y confidencialidad

**Si fuera una biblioteca:**
- Énfasis en libros, autores, préstamos, devoluciones
- Gestión de inventario por ubicación física

---

## 2. Arquitectura y roles en un sistema de bases de datos

### 2.1. Arquitectura lógica de tres capas

| Capa | Descripción | Responsabilidad técnica |
|------|-------------|------------------------|
| **Presentación** | Interfaz con la que interactúa el usuario. | Mostrar formularios, reportes, dashboards. |
| **Lógica de negocio** | Reglas que definen cómo se procesan los datos. | Validar notas, controlar matrículas, aplicar políticas. |
| **Datos** | Capas física y lógica del SGBD. | Almacenar, recuperar y proteger la información. |

#### Ejemplo práctico en sistema académico:

**Capa de Presentación:**
- Formulario web para ingreso de calificaciones
- Dashboard de estudiante para ver notas

**Capa de Lógica de Negocio:**
- Validación: nota debe estar entre 0 y 5
- Regla: estudiante solo puede ver sus propias calificaciones
- Regla: docente solo puede calificar sus grupos asignados

**Capa de Datos:**
- Tabla `Calificaciones` almacena calificaciones
- Índices en estudiante_id y grupo_id para consultas rápidas
- Triggers para registrar auditoría de cambios

### 2.2. Roles clave alrededor del SGBD

#### DBA y equipo de infraestructura
- ✓ Configura instancias del motor (PostgreSQL, MySQL, SQL Server)
- ✓ Define políticas de backup y recuperación
- ✓ Controla usuarios, roles y permisos sobre esquemas y objetos
- ✓ Monitorea rendimiento y ajusta parámetros de la base de datos
- ✓ Gestiona espacios de almacenamiento y capacidad

#### Equipo de desarrollo y analistas
- ✓ Diseñan el modelo lógico y diagrama entidad-relación
- ✓ Escriben y optimizan consultas SQL
- ✓ Desarrollan componentes (APIs, servicios) que interactúan con el SGBD
- ✓ Traducen requisitos del negocio a estructuras de datos coherentes
- ✓ Trabajan con el SGBD para garantizar integridad y consistencia

#### Colaboración entre roles:
```
Analista de Negocio
    ↓ (requisitos)
Analista de BD / Arquitecto
    ↓ (diseño de esquema)
Desarrollador
    ↓ (implementación)
DBA
    ↓ (deployment y mantenimiento)
SGBD (PostgreSQL, MySQL, etc.)
```

---

## 3. Primer diseño de una base de datos académica

### 3.1. Identificación de entidades iniciales

| Entidad candidata | Posibles atributos | Comentarios iniciales |
|-------------------|-------------------|----------------------|
| **Estudiante** | Código, nombre, documento, correo institucional, programa. | Cada estudiante debe identificarse de forma única (código o documento). |
| **Asignatura** | Código, nombre, créditos, semestre, área. | Una asignatura puede ser tomada por muchos estudiantes. |
| **Grupo** | Código de grupo, periodo, horario, docente responsable. | Permite diferenciar varios grupos de la misma asignatura. |
| **Matrícula** | Estudiante, grupo, fecha, estado. | Relaciona estudiantes con grupos específicos en un periodo. |

### 3.2. Extensión de entidades (Actividad práctica guiada)

#### Entidad: Docente

| Atributo | Tipo | Descripción |
|----------|------|------------|
| **cedula_docente** (PK) | VARCHAR(20) | Identificador único del docente |
| **nombre_completo** | VARCHAR(100) | Nombre y apellidos |
| **correo_institucional** | VARCHAR(100) | Email para contacto institucional |
| **numero_telefono** | VARCHAR(20) | Teléfono de contacto |
| **titulo_pregrado** | VARCHAR(100) | Formación académica base |
| **titulo_postgrado** | VARCHAR(100) | Especialización o maestría |
| **departamento** | VARCHAR(50) | Departamento al que pertenece |
| **estado_activo** | BOOLEAN | Indica si está activo en la institución |

**Clave principal:** `cedula_docente`

#### Entidad: Programa (Carrera)

| Atributo | Tipo | Descripción |
|----------|------|------------|
| **codigo_programa** (PK) | VARCHAR(10) | Identificador único del programa |
| **nombre_programa** | VARCHAR(100) | Nombre oficial de la carrera |
| **numero_semestres** | INT | Duración en semestres |
| **creditos_totales** | INT | Total de créditos requeridos |
| **area_conocimiento** | VARCHAR(50) | Área: Ingeniería, Ciencias, etc. |
| **director_programa** | VARCHAR(100) | Responsable del programa |
| **estado_activo** | BOOLEAN | Activo o suspendido |

**Clave principal:** `codigo_programa`

#### Entidad: Aula

| Atributo | Tipo | Descripción |
|----------|------|------------|
| **codigo_aula** (PK) | VARCHAR(10) | Identificador único del aula |
| **numero_aula** | VARCHAR(20) | Número o nombre del aula (A-101) |
| **capacidad** | INT | Número de puestos disponibles |
| **ubicacion** | VARCHAR(100) | Edificio y nivel |
| **recursos** | VARCHAR(200) | Proyector, TV, conexión internet, etc. |
| **estado_disponible** | BOOLEAN | Disponible para uso |

**Clave principal:** `codigo_aula`

### 3.3. Matriz de relaciones entre entidades

```
Estudiante (N) -----> (1) Programa
Estudiante (N) -----> (M) Grupo (a través de Matrícula)
Asignatura (1) -----> (M) Grupo
Grupo (1) -----> (1) Docente
Grupo (1) -----> (1) Aula
Docente (1) -----> (1) Departamento (implícito)
```

### 3.4. Diagrama inicial de la base de datos

```
┌─────────────────────┐
│    ESTUDIANTE       │
├─────────────────────┤
│ PK: codigo_est      │
│ - nombre            │
│ - documento         │
│ - correo            │
│ FK: programa_id     │──────┐
└─────────────────────┘      │
        │                    │
        │ (N)            (1) │
        │ M2M             │
        │                    │
┌─────────────────────┐      │
│   MATRICULA         │      │
├─────────────────────┤      │
│ PK: (est_id,grupo_id) │  │
│ - fecha_matricula   │      │
│ - estado            │      │
└─────────────────────┘      │
        │                    │
        │ (N)            (1) │
        │               PROGRAMA
┌─────────────────────┐      │
│   GRUPO             │      │
├─────────────────────┤      │
│ PK: codigo_grupo    │      │
│ - periodo           │      │
│ - horario           │      │
│ FK: asignatura_id   │──┐   │
│ FK: docente_id      │─┐│   │
│ FK: aula_id         │┌┼┼───┘
└─────────────────────┘││
                       ││
                 (1)   ││
                 │     ││
        ┌─────────────────────┐
        │   ASIGNATURA        │
        ├─────────────────────┤
        │ PK: codigo_asig     │
        │ - nombre            │
        │ - creditos          │
        │ - semestre          │
        └─────────────────────┘

        ┌─────────────────────┐
        │   DOCENTE           │
        ├─────────────────────┤
        │ PK: cedula_docente  │
        │ - nombre            │
        │ - especialidad      │
        │ - departamento      │
        └─────────────────────┘

        ┌─────────────────────┐
        │   AULA              │
        ├─────────────────────┤
        │ PK: codigo_aula     │
        │ - numero            │
        │ - capacidad         │
        │ - ubicacion         │
        └─────────────────────┘
```

### 3.5. Buenas prácticas tempranas

#### ✓ Decisiones de diseño aplicadas:

1. **Clave única para cada entidad principal**
   - Estudiante: `codigo_est` (único en institución)
   - Asignatura: `codigo_asig` (estandarizado)
   - Grupo: `codigo_grupo` (combinación de asignatura + período)
   - Docente: `cedula_docente` (documento único)
   - Programa: `codigo_programa` (identificador único)

2. **Evitar redundancia**
   - Datos de estudiante solo en tabla Estudiante
   - No repetir nombre de docente en cada grupo
   - Usar claves foráneas para referencias

3. **Separación de datos**
   - Datos personales (Estudiante, Docente) separados de datos académicos
   - Información de aulas separada de información de grupos
   - Historial de matrículas registrado en tabla Matrícula

4. **Normalización inicial**
   - Cada atributo almacena un dato atómico
   - No hay listas o arreglos en campos
   - Relaciones explícitas a través de claves foráneas

---

## 4. Reflexión final y preguntas clave

### Preguntas para llevarse

#### ¿Qué pasaría si no definimos correctamente las claves de cada entidad desde el inicio?

**Consecuencias:**
- Duplicación de registros (múltiples estudiantes con el mismo código)
- Impossibilidad de actualizar datos sin afectar múltiples registros
- Consultas ineficientes y resultados incorrectos
- Pérdida de integridad referencial
- Costosa reestructuración posterior

**Ejemplo:** Si no hubiéramos definido `codigo_est` como clave única, podríamos tener:
```
ID | Nombre      | Documento
1  | María López | 1001234567
2  | María López | 1001234567  ← Duplicado, confusión en matrículas
```

#### ¿Qué ventajas aporta tener identificadas las entidades antes de pasar al diagrama ER formal?

**Ventajas clave:**

1. **Claridad conceptual**
   - Entendimiento compartido del dominio
   - Reducción de ambigüedades

2. **Ahorro de tiempo**
   - Menos iteraciones en diseño
   - Requisitos más claros para desarrolladores

3. **Prevención de errores**
   - Identificar entidades faltantes temprano
   - Ajustar relaciones antes de implementación

4. **Mejora de comunicación**
   - Facilita explicación a stakeholders
   - Validación rápida de conceptos

5. **Escalabilidad**
   - Base sólida para expansiones futuras
   - Fácil integración de nuevas entidades

#### ¿Qué información adicional consideras crítica en un sistema académico que aún no hemos modelado?

**Información adicional esencial:**

1. **Calificaciones y desempeño**
   - Tabla `Calificaciones` (estudiante, grupo, nota, fecha)
   - Tabla `Evaluaciones` (tipo de evaluación, ponderación)
   - Permite: generar boletines, promedio ponderado, análisis de desempeño

2. **Requisitos y prerrequisitos**
   - Tabla `Requisitos` (asignatura_previa, asignatura_siguiente)
   - Permite: validar que estudiantes cumplan requisitos antes de matricularse

3. **Período académico y calendario**
   - Tabla `Periodo_Academico` (código, fecha_inicio, fecha_fin, estado)
   - Permite: organizar matrículas por semestre, años, años sabáticos

4. **Horarios detallados**
   - Tabla `Horario_Grupo` (grupo_id, dia, hora_inicio, hora_fin, aula_id)
   - Permite: detectar conflictos, optimizar uso de aulas

5. **Autorización y acceso**
   - Tabla `Usuario` (cedula, rol, contraseña_hash, estado)
   - Tabla `Permiso` (usuario_id, recurso, accion)
   - Permite: seguridad, control de acceso por rol

6. **Auditoría y trazabilidad**
   - Tabla `Auditoria` (tabla_afectada, usuario, fecha, accion, valor_anterior, valor_nuevo)
   - Permite: rastrear cambios, cumplimiento normativo

7. **Información financiera**
   - Tabla `Aranceles` (programa_id, semestre, valor_matricula)
   - Tabla `Pagos` (estudiante_id, periodo, monto, fecha_pago, estado)
   - Permite: gestión administrativa y presupuestaria

---

## Conclusiones

Este primer diseño nos proporciona:

✓ **Estructura base** para un sistema académico funcional  
✓ **Entidades y atributos** identificados y validados  
✓ **Relaciones claras** entre componentes del sistema  
✓ **Buenas prácticas** aplicadas desde el inicio  
✓ **Escalabilidad** para agregar nuevas funcionalidades  

**Próximos pasos:**
- Formalizar el diagrama Entidad-Relación (ER)
- Aplicar normas de normalización (1NF, 2NF, 3NF)
- Generar el script SQL para crear las tablas
- Implementar en un SGBD real (PostgreSQL)

---

**Fecha de elaboración:** Febrero 5, 2026  
**Curso:** Modelado y Gestión de Bases de Datos II  
**Semana:** 1 · Sesión 2
