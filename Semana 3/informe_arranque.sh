#!/bin/bash
# Autores: Bryan Caiza, Fernando Paguay (GR1)
# Fecha: 28/10/2026
# Declaración de uso de IA: Ninguna IA generativa fue utilizada para obtener la salida de los comandos.

echo "=== 1 · SO, versión y núcleo ==="
grep PRETTY_NAME /etc/os-release
uname -r
uname -m

echo -e "\n=== 2 · Último arranque y uptime ==="
uptime -s
uptime -p

echo -e "\n=== 3 · Desglose del arranque ==="
if command -v systemd-analyze &> /dev/null; then
    systemd-analyze time
else
    echo "Aviso: El comando systemd-analyze no existe o no está disponible."
fi

echo -e "\n=== 4 · Cinco unidades más lentas ==="
systemd-analyze blame --no-pager | head -n 5

echo -e "\n=== 5 · Módulos / controladores ==="
echo "Total de módulos cargados:"
lsmod | wc -l
echo "Los 5 módulos más grandes:"
lsmod | sort -k2 -n -r | head -n 5

echo -e "\n=== 6 · Cierre ==="
echo "Target por defecto:"
systemctl get-default
echo "Unidades fallidas:"
systemctl --failed
