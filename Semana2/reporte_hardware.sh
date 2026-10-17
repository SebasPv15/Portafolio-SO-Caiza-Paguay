#!/bin/bash

# ============================================================
# REPORTE DE HARDWARE Y MEMORIA - LINUX
# ============================================================

# Nombre del equipo y archivo de salida
EQUIPO=$(hostname)
ARCHIVO="memoria_${EQUIPO}.txt"
FECHA=$(date '+%Y-%m-%d %H:%M:%S')

# Crear el reporte
exec > >(tee "$ARCHIVO") 2>&1

echo "============================================================"
echo "       REPORTE DE HARDWARE Y MEMORIA - LINUX"
echo "============================================================"

# ============================================================
# 1. INFORMACION GENERAL
# ============================================================

echo
echo "1. INFORMACION GENERAL"
echo "------------------------------------------------------------"

echo "Nombre del equipo: $EQUIPO"
echo "Sistema operativo: $(uname -s)"
echo "Distribucion: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2)"
echo "Kernel: $(uname -r)"
echo "Fecha y hora: $FECHA"
echo "Arquitectura: $(uname -m)"

if lscpu | grep -qi 'Byte Order:.*Little Endian'; then
    echo "Orden de bytes: Little-endian"
elif lscpu | grep -qi 'Byte Order:.*Big Endian'; then
    echo "Orden de bytes: Big-endian"
else
    echo "Orden de bytes: $(lscpu | grep 'Byte Order:' | cut -d ':' -f 2- | xargs)"
fi

# ============================================================
# 2. INFORMACION DEL PROCESADOR
# ============================================================

echo
echo "2. INFORMACION DEL PROCESADOR"
echo "------------------------------------------------------------"

lscpu | grep -E \
'Model name:|Architecture:|CPU\(s\):|Thread|Core|Socket|CPU max MHz:|CPU MHz:'

# ============================================================
# 3. CACHES DEL PROCESADOR
# ============================================================

echo
echo "3. CACHES DEL PROCESADOR"
echo "------------------------------------------------------------"

for CACHE in /sys/devices/system/cpu/cpu0/cache/index*; do

    [ -d "$CACHE" ] || continue

    NIVEL=$(cat "$CACHE/level" 2>/dev/null)
    TIPO=$(cat "$CACHE/type" 2>/dev/null)
    TAMANO=$(cat "$CACHE/size" 2>/dev/null)
    VIAS=$(cat "$CACHE/ways_of_associativity" 2>/dev/null)
    LINEA=$(cat "$CACHE/coherency_line_size" 2>/dev/null)
    CONJUNTOS=$(cat "$CACHE/number_of_sets" 2>/dev/null)

    case "$NIVEL:$TIPO" in
        1:Data) NOMBRE="L1d" ;;
        1:Instruction) NOMBRE="L1i" ;;
        2:*) NOMBRE="L2" ;;
        3:*) NOMBRE="L3" ;;
        *) NOMBRE="L${NIVEL} ($TIPO)" ;;
    esac

    echo
    echo "Cache: $NOMBRE"
    echo "  Nivel: $NIVEL"
    echo "  Tipo: $TIPO"
    echo "  Tamano: ${TAMANO:-No disponible}"
    echo "  Vias: ${VIAS:-No disponible}"
    echo "  Linea: ${LINEA:-No disponible} bytes"
    echo "  Numero de conjuntos: ${CONJUNTOS:-No disponible}"

done

# ============================================================
# 4. CALCULO DE CONJUNTOS L1d
# Formula: S = C / (L * A)
# ============================================================

echo
echo "4. CALCULO DE CONJUNTOS DE L1d"
echo "------------------------------------------------------------"

L1D="/sys/devices/system/cpu/cpu0/cache/index0"

# Buscar el indice que corresponde a L1 de datos.
for CACHE in /sys/devices/system/cpu/cpu0/cache/index*; do

    [ -d "$CACHE" ] || continue

    NIVEL=$(cat "$CACHE/level" 2>/dev/null)
    TIPO=$(cat "$CACHE/type" 2>/dev/null)

    if [ "$NIVEL" = "1" ] && [ "$TIPO" = "Data" ]; then
        L1D="$CACHE"
        break
    fi

done

if [ -d "$L1D" ] &&
   [ "$(cat "$L1D/level" 2>/dev/null)" = "1" ] &&
   [ "$(cat "$L1D/type" 2>/dev/null)" = "Data" ]; then

    TAMANO=$(cat "$L1D/size")
    LINEA=$(cat "$L1D/coherency_line_size")
    VIAS=$(cat "$L1D/ways_of_associativity")

    # Convertir el tamaño de la caché a bytes.
    NUMERO=${TAMANO%[KMG]}
    UNIDAD=${TAMANO##*[0-9.]}

    case "$UNIDAD" in
        K|k) MULTIPLICADOR=1024 ;;
        M|m) MULTIPLICADOR=1048576 ;;
        G|g) MULTIPLICADOR=1073741824 ;;
        *) MULTIPLICADOR=1 ;;
    esac

    if [[ "$NUMERO" =~ ^[0-9]+([.][0-9]+)?$ ]] &&
       [[ "$LINEA" =~ ^[0-9]+$ ]] &&
       [[ "$VIAS" =~ ^[0-9]+$ ]] &&
       [ "$LINEA" -gt 0 ] &&
       [ "$VIAS" -gt 0 ]; then

        CAPACIDAD=$(awk -v n="$NUMERO" -v m="$MULTIPLICADOR" \
            'BEGIN {printf "%.0f", n*m}')

        CONJUNTOS=$((CAPACIDAD / (LINEA * VIAS)))

        echo "Capacidad C: $CAPACIDAD bytes"
        echo "Tamano de linea L: $LINEA bytes"
        echo "Numero de vias A: $VIAS"
        echo "Formula: S = C / (L * A)"
        echo "Calculo: $CAPACIDAD / ($LINEA * $VIAS)"
        echo "Numero de conjuntos S: $CONJUNTOS"

    else
        echo "No se pudo calcular con los datos disponibles."
    fi

else
    echo "No se encontro informacion de la cache L1d."
fi

# ============================================================
# 5. MEMORIA RAM
# ============================================================

echo
echo "5. MEMORIA RAM"
echo "------------------------------------------------------------"

free -h

RAM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
RAM_LIBRE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
RAM_DISPONIBLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

echo
echo "RAM total: $((RAM_TOTAL / 1024)) MB"
echo "RAM libre: $((RAM_LIBRE / 1024)) MB"
echo "RAM disponible: $((RAM_DISPONIBLE / 1024)) MB"

# ============================================================
# 6. SWAP O ARCHIVO DE PAGINACION
# ============================================================

echo
echo "6. SWAP Y ARCHIVOS DE PAGINACION"
echo "------------------------------------------------------------"

swapon --show

echo
echo "Resumen de memoria swap:"
free -h | grep -i Swap

# ============================================================
# 7. DISCOS
# ============================================================

echo
echo "7. DISCOS"
echo "------------------------------------------------------------"

lsblk -d -o NAME,TYPE,SIZE,ROTA,MODEL

echo
echo "Interpretacion del tipo de disco:"
echo "ROTA = 0: dispositivo no rotacional, generalmente SSD."
echo "ROTA = 1: dispositivo rotacional, generalmente HDD."

# ============================================================
# 8. TIEMPOS DE EJECUCION DE MATRIZ
# ============================================================

echo
echo "8. TIEMPOS DE EJECUCION"
echo "------------------------------------------------------------"

medir_matriz() {

    DESCRIPCION="$1"
    shift

    if [ ! -f "./matriz" ]; then
        echo "$DESCRIPCION: No se encontro ./matriz."
        return
    fi

    if [ ! -x "./matriz" ]; then
        echo "$DESCRIPCION: El archivo no tiene permiso de ejecucion."
        return
    fi

    echo
    echo "$DESCRIPCION"

    INICIO=$(date +%s%N)

    timeout 600 ./matriz "$@" > /dev/null
    ESTADO=$?

    FIN=$(date +%s%N)

    DURACION=$(awk -v i="$INICIO" -v f="$FIN" \
        'BEGIN {printf "%.6f", (f-i)/1000000000}')

    echo "Tiempo transcurrido: $DURACION segundos"
    echo "Codigo de salida: $ESTADO"

    if [ "$ESTADO" -eq 124 ]; then
        echo "Advertencia: se alcanzo el limite de 600 segundos."
    fi
}

medir_matriz "Ejecucion de ./matriz"
medir_matriz "Ejecucion de ./matriz c" c

# ============================================================
# FIN DEL REPORTE
# ============================================================

echo
echo "============================================================"
echo "FIN DEL REPORTE"
echo "============================================================"

echo
echo "Reporte guardado en: $(pwd)/$ARCHIVO"
