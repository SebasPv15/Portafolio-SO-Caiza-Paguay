# Portafolio de Sistemas Operativos

**Estudiantes:** 
- Bryan Caiza
- Fernando Paguay  
**Grupo:** GR1  

---

## 📂 Estructura del Portafolio

En este repositorio se encuentran las actividades y evidencias correspondientes al portafolio de la materia de Sistemas Operativos.

### 📌 Semana 1 (`/Semana 1`)

En esta sección se encuentran los elementos solicitados para la primera semana:

#### 1. Ayuda Memoria (Comandos Básicos)
* **Comandos en Windows (PowerShell):**
  - `Get-CimInstance`: Permite consultar información detallada del sistema operativo, procesador y hardware mediante WMI/CIM.
  - `Get-PhysicalDisk`: Obtiene los dispositivos de almacenamiento conectados al equipo, mostrando su tamaño y tipo.
  - `Get-NetIPAddress`: Consulta las direcciones IP configuradas en las interfaces de red del equipo.
  - `Out-File`: Exporta los resultados obtenidos a un archivo de texto con codificación UTF-8.

* **Comandos en Linux (Bash):**
  - `hostname` / `uname`: Permiten identificar el nombre del equipo y la versión del núcleo del sistema operativo.
  - `lscpu`: Muestra información detallada sobre la arquitectura del procesador, núcleos e hilos.
  - `free -h`: Consulta el uso y capacidad de la memoria RAM en un formato legible para humanos.
  - `lsblk`: Lista los dispositivos de bloque (discos y particiones) conectados al sistema.
  - `ip addr show`: Muestra la configuración de las interfaces de red e IPs activas.

---

#### 2. Scripts de Aplicación
* **Script para Windows (`inventario.ps1`):**
  ```powershell
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor
  $ram = Get-CimInstance Win32_ComputerSystem
  $archivo = "inventario_hardware.txt"

  $inventario = @"
  ==============================================
          INVENTARIO DE HARDWARE
  ==============================================
  == Equipo: $($env:COMPUTERNAME)
  == Fecha: $(Get-Date)

  == Sistema Operativo
  SO: $($os.Caption)
  Version: $($os.Version)

  == CPU
  Modelo: $($cpu.Name)
  Nucleos: $($cpu.NumberOfCores)
  Hilos: $($cpu.NumberOfLogicalProcessors)
  Frecuencia: $($cpu.MaxClockSpeed) MHz
  "@
  * **Script para Linux (`inventario.sh`):**
  ```bash
  #!/usr/bin/env bash
SALIDA="inventario_$(hostname).txt"
{
    echo "=================================================="
    echo "          REPORTE DE INVENTARIO DE HARDWARE       "
    echo "=================================================="
    echo "Nombre del equipo : $(hostname)"
    echo "Fecha y hora      : $(date)"
    lscpu | grep -E 'Model name|^CPU\(s\):'
    free -h
    lsblk -d -o NAME,TYPE,SIZE,MODEL 2>/dev/null
} > "$SALIDA"
**Captura de salida / Resultados:** Archivo de texto con la ejecución de los scripts (`inventario_hardware.txt`)(`inventario_sebas15-VirtualBox.txt`).
