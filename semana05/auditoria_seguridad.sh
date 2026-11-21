#!/usr/bin/env bash
# ==============================================================================
# Archivo: semana05/auditoria_seguridad.sh
# Descripción: Auditoría de seguridad en Linux (5 secciones y veredicto).
# Autores: Bryan Caiza, Fernando Paguay (Grupo GR1)
# Uso de IA: Generado con asistencia de IA (Gemini) para estructurar las 5
#            secciones de auditoría, expresiones regulares de logs SSH, manejo
#            de parámetros (-m, -u) y generación automática del reporte .txt.
# ==============================================================================

MUESTRA=""
UMBRAL=5

# Procesamiento de argumentos (-m archivo_muestra, -u umbral)
while getopts "m:u:" opt; do
    case "$opt" in
        m) MUESTRA="$OPTARG" ;;
        u) UMBRAL="$OPTARG" ;;
        *) echo "Uso: $0 [-m archivo_muestra] [-u umbral]"; exit 1 ;;
    esac
done

ALERTAS=0
HOSTNAME_ACTUAL=$(hostname)
FECHA_ACTUAL=$(date "+%Y-%m-%d %H:%M:%S")
ARCHIVO_REPORTE="semana05/auditoria_linux_${HOSTNAME_ACTUAL}.txt"

# Función auxiliar para escribir en consola y en el archivo .txt simultáneamente
registrar() {
    echo -e "$1" | tee -a "$ARCHIVO_REPORTE"
}

# Limpiar/crear reporte si la carpeta existe, si no guardar en directorio actual
if [ ! -d "semana05" ]; then
    ARCHIVO_REPORTE="auditoria_linux_${HOSTNAME_ACTUAL}.txt"
fi
> "$ARCHIVO_REPORTE"

registrar "============================================================"
registrar " AUDITORÍA DE SEGURIDAD - LINUX ($HOSTNAME_ACTUAL)"
registrar " Fecha: $FECHA_ACTUAL | Umbral intentos: $UMBRAL"
if [ -n "$MUESTRA" ]; then
    registrar " Modo muestra activado: $MUESTRA"
fi
registrar "============================================================\n"

# ------------------------------------------------------------------------------
# SECCIÓN 1: Llavero maestro (UID 0 y grupo wheel)
# ------------------------------------------------------------------------------
registrar "--- [1. Llavero maestro] ---"
USUARIOS_UID0=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
NO_ROOT_UID0=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)
GRUPO_WHEEL=$(getent group wheel 2>/dev/null || echo "Grupo wheel no encontrado")

registrar "Usuarios con UID 0: $USUARIOS_UID0"
registrar "Miembros wheel: $GRUPO_WHEEL"

if [ -n "$NO_ROOT_UID0" ]; then
    registrar "Estado Sección 1: ALERTA (Se detectaron usuarios distintos de root con UID 0: $NO_ROOT_UID0)\n"
    ALERTAS=$((ALERTAS + 1))
else
    registrar "Estado Sección 1: OK\n"
fi

# ------------------------------------------------------------------------------
# SECCIÓN 2: Puertas abiertas (Puertos 21, 23, 3306, 3389, 5900 expuestos a red)
# ------------------------------------------------------------------------------
registrar "--- [2. Puertas abiertas] ---"
PUERTOS_RIESGO="21|23|3306|3389|5900"
# Buscar puertos en escucha que NO sean exclusivamente loopback (127.0.0.1 o [::1])
EXPUESTOS=$(ss -H -tln | awk '{print $4}' | grep -E ":(${PUERTOS_RIESGO})$" | grep -vE "^(127\.0\.0\.|\[::1\])")

if [ -n "$EXPUESTOS" ]; then
    registrar "Puertos críticos expuestos a la red:\n$EXPUESTOS"
    registrar "Estado Sección 2: ALERTA\n"
    ALERTAS=$((ALERTAS + 1))
else
    registrar "Ningún puerto crítico (21, 23, 3306, 3389, 5900) expuesto a la red."
    registrar "Estado Sección 2: OK\n"
fi

# ------------------------------------------------------------------------------
# SECCIÓN 3: Portero activo (firewalld)
# ------------------------------------------------------------------------------
registrar "--- [3. Portero activo] ---"
ESTADO_FW=$(systemctl is-active firewalld 2>/dev/null)
if [ "$ESTADO_FW" = "active" ]; then
    registrar "Estado del servicio firewalld: active"
    registrar "Estado Sección 3: OK\n"
else
    registrar "Estado del servicio firewalld: ${ESTADO_FW:-inactivo/no instalado}"
    registrar "Estado Sección 3: ALERTA\n"
    ALERTAS=$((ALERTAS + 1))
fi

# ------------------------------------------------------------------------------
# SECCIÓN 4: Intentos fallidos SSH (journal 24h o archivo -m)
# ------------------------------------------------------------------------------
registrar "--- [4. Intentos fallidos] ---"
LOGS_SSH=""
if [ -n "$MUESTRA" ] && [ -f "$MUESTRA" ]; then
    LOGS_SSH=$(grep "Failed password" "$MUESTRA")
else
    # Consulta journalctl de las últimas 24 horas (sin sudo muestra lo accesible al usuario)
    LOGS_SSH=$(journalctl --since "24 hours ago" 2>/dev/null | grep "Failed password")
fi

# Extraer IPs asociadas a "Failed password" (ignora "authentication failure" local)
IPS_ATACANTES=$(echo "$LOGS_SSH" | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' | sort | uniq -c)

ALERTA_SSH=0
if [ -n "$IPS_ATACANTES" ]; then
    registrar "Conteo de intentos fallidos SSH por IP:"
    while read -r conteo ip; do
        registrar "  - IP: $ip -> $conteo intentos"
        if [ "$conteo" -ge "$UMBRAL" ]; then
            ALERTA_SSH=1
        fi
    done <<< "$IPS_ATACANTES"
else
    registrar "No se encontraron registros de 'Failed password' por SSH."
fi

if [ "$ALERTA_SSH" -eq 1 ]; then
    registrar "Estado Sección 4: ALERTA (Una o más IPs alcanzaron o superaron el umbral de $UMBRAL)\n"
    ALERTAS=$((ALERTAS + 1))
else
    registrar "Estado Sección 4: OK\n"
fi

# ------------------------------------------------------------------------------
# SECCIÓN 5: Veredicto final
# ------------------------------------------------------------------------------
registrar "============================================================"
if [ "$ALERTAS" -gt 0 ]; then
    registrar " VEREDICTO FINAL: ALERTA ($ALERTAS secciones con hallazgos)"
    registrar " Reporte guardado en: $ARCHIVO_REPORTE"
    registrar "============================================================"
    exit 1
else
    registrar " VEREDICTO FINAL: OK (Equipo sin alertas)"
    registrar " Reporte guardado en: $ARCHIVO_REPORTE"
    registrar "============================================================"
    exit 0
fi
