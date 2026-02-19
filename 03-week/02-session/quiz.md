================================================================================
EJERCICIOS PRÁCTICOS DE SQL: CLÁUSULAS JOIN
Modelo: Sistema de Gestión de Facturas y Control de Acceso
Base de datos: facturacion_db
================================================================================

================================================================================
EJERCICIO 1: Análisis de Facturas por Usuario y Rol
================================================================================

DESCRIPCIÓN:
Obtén un reporte que muestre, para cada usuario del sistema, la siguiente 
información:
  - Nombre completo del usuario (concatenar first_name y last_name de person)
  - Nombre de usuario (username)
  - Rol asignado
  - Cantidad total de facturas creadas por ese usuario
  - Monto total facturado
  - Monto promedio por factura

Requisitos específicos:
  • Incluir ÚNICAMENTE usuarios que hayan creado al menos una factura.
  • Ordernar los resultados por monto total facturado de mayor a menor.
  • Filtrar SOLAMENTE roles con estado 'active'.

TABLAS INVOLUCRADAS: person, user, role, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN (mínimo 2 variantes)
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, AVG
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión optimizada con joins explícitos
  2. Versión alternativa utilizando subconsultas en la cláusula FROM


================================================================================
EJERCICIO 2: Productos Más Vendidos por Categoría
================================================================================

DESCRIPCIÓN:
Crea un reporte que identifique, para cada categoría de producto:
  - Nombre de la categoría
  - Nombre del producto más vendido (por cantidad total)
  - Cantidad total vendida del producto más vendido
  - Cantidad total de productos diferentes vendidos en esa categoría
  - Ingresos totales generados por esa categoría
  - Precio promedio de los productos en esa categoría

Requisitos específicos:
  • Incluir solamente productos con estado 'active'.
  • Incluir solamente facturas con estado 'issued' o 'paid'.
  • Ordenar por ingresos totales de mayor a menor.
  • Si una categoría no tiene ventas, mostrar NULL en campos de ventas.

TABLAS INVOLUCRADAS: product_category, product, bill_detail, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, AVG
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión usando LEFT JOIN para incluir categorías sin ventas
  2. Versión alternativa con CTE (Common Table Expression) o subconsultas 
     para separar el cálculo de categorías del cálculo de productos


================================================================================
EJERCICIO 3: Permisos Asignados a Roles por Módulo
================================================================================

DESCRIPCIÓN:
Genera un reporte que detalle:
  - Nombre del módulo
  - Nombre del rol
  - Lista de permisos asignados al rol en ese módulo (concatenados, separados 
    por coma)
  - Cantidad de permisos para esa combinación módulo-rol
  - Cantidad de usuarios con ese rol

Requisitos específicos:
  • Incluir solamente módulos, roles y permisos con estado 'active'.
  • Ordenar primero por nombre del módulo, luego por cantidad de usuarios 
    (mayor a menor).
  • Si un rol no tiene permisos en un módulo, mostrar 0 y NULL en la lista 
    de permisos.

TABLAS INVOLUCRADAS: module, role, permission, user

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT
  • GROUP_CONCAT (MySQL) o STRING_AGG (PostgreSQL)
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión optimizada con joins directos
  2. Versión alternativa usando UNION para separar roles con permisos de 
     roles sin permisos en módulos específicos


================================================================================
EJERCICIO 4: Análisis de Deudores: Facturas Pendientes por Usuario
================================================================================

DESCRIPCIÓN:
Obtén un reporte de usuarios con facturas pendientes de pago que incluya:
  - Nombre completo del usuario
  - Email de contacto
  - Cantidad de facturas pendientes (estado 'draft' o 'issued')
  - Monto total pendiente
  - Monto máximo de una factura individual
  - Fecha de la factura más antigua pendiente

Requisitos específicos:
  • Incluir solamente usuarios con estado 'active'.
  • Incluir solamente facturas con estado 'draft' o 'issued'.
  • Ordenar por monto total pendiente de mayor a menor.
  • Mostrar solamente usuarios que tengan al menos una factura pendiente.

TABLAS INVOLUCRADAS: person, user, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, MAX, MIN
  • HAVING
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión usando INNER JOIN y filtrado en WHERE
  2. Versión alternativa con subconsulta en cláusula FROM para precalcular 
     facturas pendientes


================================================================================
EJERCICIO 5: Detalles Completos de Facturas con Información de Productos
================================================================================

DESCRIPCIÓN:
Genera un reporte detallado de todas las facturas que muestre:
  - Número de factura
  - Fecha de factura
  - Nombre del usuario que emitió
  - Para cada línea de detalle de factura:
    • Nombre del producto
    • Categoría del producto
    • Cantidad solicitada
    • Precio unitario
    • Subtotal (antes de descuento)
    • Descuento aplicado (%)
    • Total neto (después de descuento)

Requisitos específicos:
  • Incluir todas las facturas, incluso aquellas sin detalles (si existen).
  • Incluir solamente productos con estado 'active'.
  • Ordenar por número de factura y luego por nombre de producto.
  • Calcular el total general de la factura en una línea aparte.

TABLAS INVOLUCRADAS: bill, user, person, bill_detail, product, product_category

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN (múltiples)
  • LEFT JOIN
  • WHERE
  • ORDER BY
  • CONCAT o funciones de string

VARIANTES SOLICITADAS:
  1. Versión con joins encadenados
  2. Versión alternativa con UNION (para separar detalles de factura del 
     total general como fila adicional)


================================================================================
EJERCICIO 6: Usuarios Inactivos con Historial de Facturas
================================================================================

DESCRIPCIÓN:
Crea un reporte de usuarios inactivos (status = 'inactive' o 'suspended') 
que contenga:
  - Nombre completo
  - Estado actual del usuario
  - Rol asignado
  - Última fecha de login (si existe)
  - Cantidad de facturas emitidas (cuando estaban activos)
  - Monto total facturado
  - Fecha de la última factura emitida

Requisitos específicos:
  • Incluir solamente usuarios con estado 'inactive' o 'suspended'.
  • Incluir solamente facturas con estado 'issued' o 'paid'.
  • Ordenar por fecha de última factura de más reciente a más antigua.
  • Mostrar NULL si el usuario no tiene facturas.

TABLAS INVOLUCRADAS: person, user, role, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, MAX
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión con LEFT JOIN para incluir usuarios sin facturas
  2. Versión alternativa con subconsulta correlacionada en SELECT para 
     obtener la fecha de última factura


================================================================================
EJERCICIO 7: Comparativa de Ventas: Módulos vs Permisos de Usuarios
================================================================================

DESCRIPCIÓN:
Elabora un análisis que cruce información de módulos, permisos y usuarios 
para determinar:
  - Nombre del módulo
  - Cantidad de usuarios con permiso de lectura en ese módulo (código 'READ')
  - Cantidad de usuarios con permiso de creación en ese módulo (código 'CREATE')
  - Cantidad de usuarios con permiso de edición en ese módulo (código 'EDIT')
  - Cantidad de usuarios con permiso de eliminación en ese módulo (código 'DELETE')
  - Cantidad total de facturas emitidas por usuarios con acceso a ese módulo

Requisitos específicos:
  • Incluir solamente módulos con estado 'active'.
  • Incluir solamente roles con estado 'active'.
  • Incluir solamente usuarios con estado 'active'.
  • Incluir solamente facturas con estado 'issued' o 'paid'.
  • Ordenar por cantidad total de facturas de mayor a menor.

TABLAS INVOLUCRADAS: module, permission, role, user, person, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN (múltiples)
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT
  • SUM
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión con JOINs explícitos y múltiples niveles de agrupación
  2. Versión alternativa usando UNION para contar permisos específicos


================================================================================
EJERCICIO 8: Rentabilidad por Categoría de Producto
================================================================================

DESCRIPCIÓN:
Genera un análisis financiero por categoría que incluya:
  - Nombre de la categoría
  - Cantidad de productos activos en esa categoría
  - Cantidad total de unidades vendidas
  - Ingresos brutos (antes de descuentos)
  - Descuentos totales otorgados
  - Ingresos netos (después de descuentos)
  - Margen promedio por producto (porcentaje de ganancia)
  - Producto más rentable en la categoría (por margen)

Requisitos específicos:
  • Incluir solamente productos y facturas activas.
  • Incluir solamente facturas con estado 'paid'.
  • Ordenar por ingresos netos de mayor a menor.
  • Mostrar 2 decimales en todos los cálculos monetarios.

TABLAS INVOLUCRADAS: product_category, product, bill_detail, bill

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, AVG
  • ORDER BY

VARIANTES SOLICITADAS:
  1. Versión con cálculos inline en SELECT
  2. Versión alternativa con CTE para precalcular totales por categoría


================================================================================
EJERCICIO 9: Auditoría de Acceso: Quién Puede Hacer Qué
================================================================================

DESCRIPCIÓN:
Construye un reporte de auditoría que muestre:
  - Nombre completo del usuario
  - Rol asignado
  - Módulo
  - Permisos específicos disponibles (nombre y código)
  - Estado del usuario
  - Última fecha de login

Con la estructura:
  usuario → rol → permisos por módulo

Requisitos específicos:
  • Incluir solamente usuarios y roles con estado 'active'.
  • Incluir solamente módulos y permisos con estado 'active'.
  • Ordenar por nombre de usuario, luego por módulo, luego por código de permiso.
  • Si un usuario tiene permisos en múltiples módulos, mostrar una fila por 
    permiso.

TABLAS INVOLUCRADAS: person, user, role, module, permission

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN (múltiples)
  • LEFT JOIN
  • WHERE
  • ORDER BY
  • DISTINCT (si es necesario eliminar duplicados)

VARIANTES SOLICITADAS:
  1. Versión con joins encadenados en forma clara
  2. Versión alternativa con UNION para separar usuarios con y sin permisos


================================================================================
EJERCICIO 10: Análisis Temporal: Evolución de Ventas
================================================================================

DESCRIPCIÓN:
Crea un reporte que analice la evolución de ventas por período (mes/año) 
que incluya:
  - Mes y año de la factura (formato: 'YYYY-MM')
  - Cantidad de facturas emitidas en ese período
  - Cantidad de facturas pagadas en ese período
  - Cantidad de productos diferentes vendidos
  - Monto total de ventas en ese período
  - Monto promedio por factura
  - Producto más vendido en ese período (por cantidad)
  - Usuario que más facturas emitió en ese período

Requisitos específicos:
  • Incluir solamente facturas con estado 'issued' o 'paid'.
  • Incluir solamente productos con estado 'active'.
  • Ordenar cronológicamente de más antiguo a más reciente.
  • Calcular y mostrar variación porcentual de ventas respecto al período 
    anterior (si existe).

TABLAS INVOLUCRADAS: bill, bill_detail, product, user, person

CLÁUSULAS/FUNCIONES OBLIGATORIAS:
  • INNER JOIN
  • LEFT JOIN
  • WHERE
  • GROUP BY
  • COUNT, SUM, AVG, MAX
  • DATE_FORMAT (MySQL) o equivalente
  • ORDER BY
  • Función de ventana (LAG/LEAD) para calcular variación período anterior

VARIANTES SOLICITADAS:
  1. Versión con funciones de ventana (WINDOW FUNCTIONS)
  2. Versión alternativa con subconsultas para calcular variación período 
     anterior sin usar funciones de ventana


================================================================================
NOTAS IMPORTANTES PARA LA SOLUCIÓN:
================================================================================

1. VERIFICACIÓN DE JOINS:
   - Cada ejercicio DEBE utilizar MÍNIMO 2 tipos diferentes de JOIN.
   - Documenta en tu solución qué tipos de JOIN utilizaste y por qué.

2. OPTIMIZACIÓN:
   - Considera el uso de índices en tu análisis de rendimiento.
   - En la versión optimizada, explica por qué esa variante es más eficiente.

3. INTEGRIDAD REFERENCIAL:
   - Verifica que todos los JOINs respeten las relaciones foráneas del modelo.
   - Asegúrate de que no haya pérdida de datos no deseada.

4. TESTING:
   - Ejecuta cada variante contra la base de datos facturacion_db.
   - Verifica que ambas variantes produzcan resultados idénticos.
   - Documenta el número de filas retornadas como validación.

5. EXPLICACIÓN:
   - Incluye un comentario SQL explicando la lógica de cada JOIN.
   - Describe qué tabla es "driving table" y cuál es "driven table" en 
     cada operación.

================================================================================
FIN DE EJERCICIOS
================================================================================