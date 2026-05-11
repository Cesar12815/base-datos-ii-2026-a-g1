#!/bin/bash
# Script para ejecutar las soluciones de los ejercicios
# Uso: ./run_solution.sh <numero_ejercicio> <base_datos> <usuario>

EXERCISE=$1
DB=${2:-aerolinea}
USER=${3:-postgres}

if [ -z "$EXERCISE" ]; then
    echo "❌ Uso: ./run_solution.sh <numero> [base_datos] [usuario]"
    echo "   Ejemplo: ./run_solution.sh 01 aerolinea postgres"
    exit 1
fi

# Validar que el archivo existe
FILE="ejercicio_${EXERCISE}_solucion.sql"

if [ ! -f "$FILE" ]; then
    echo "❌ Error: Archivo $FILE no encontrado"
    echo "📁 Archivos disponibles:"
    ls ejercicio_*_solucion.sql 2>/dev/null | sed 's/^/   /'
    exit 1
fi

echo "✅ Ejecutando: $FILE"
echo "📊 Base de datos: $DB"
echo "👤 Usuario: $USER"
echo "---"

psql -U "$USER" -d "$DB" -f "$FILE"

if [ $? -eq 0 ]; then
    echo "---"
    echo "✨ Ejercicio $EXERCISE completado exitosamente"
else
    echo "---"
    echo "❌ Error ejecutando el ejercicio $EXERCISE"
fi
