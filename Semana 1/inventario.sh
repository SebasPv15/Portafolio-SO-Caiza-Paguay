#!/usr/bin/env bash
# ==============================================================================
# Script: inventario.sh
# Descripción: Script de inventario de hardware para Linux (Semana 1)
# ==============================================================================

SALIDA="inventario_$(hostname).txt"

{
    echo "=================================================="
    echo "          REPORTE DE INVENTARIO DE HARDWARE       "
    echo "=================================================="
    echo "Nombre del equipo : $(hostname)"
    echo "Fecha y hora      : $(date)"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Sistema Operativo : $PRETTY_NAME"
    else
        echo "Sistema Operativo : $(uname -s -r)"
    fi
    echo ""

    echo "=================================================="
    echo " [CPU] Información del Procesador"
    echo "=================================================="
    lscpu | grep -E 'Model name|^CPU\(s\):|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|CPU MHz|CPU max MHz|L1d|L1i|L2|L3'
    echo ""

    echo "=================================================="
    echo " [MEMORIA] Memoria RAM Total"
    echo "=================================================="
    free -h
    echo ""

    echo "=================================================="
    echo " [DISCOS] Dispositivos de Almacenamiento"
    echo "=================================================="
    lsblk -d -o NAME,TYPE,SIZE,MODEL 2>/dev/null || lsblk -d -o NAME,TYPE,SIZE
    echo ""

    echo "=================================================="
    echo " [EXTRA] Interfaces de Red y Dirección IP"
    echo "=================================================="
    ip -o -4 addr show | awk '{print "Interfaz: " $2 " | IP: " $4}'
    echo "--------------------------------------------------"

} > "$SALIDA"

echo "¡Reporte generado con éxito en el archivo: $SALIDA!"
