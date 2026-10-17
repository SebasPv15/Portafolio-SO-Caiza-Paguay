# ============================================================
# REPORTE DE HARDWARE Y MEMORIA - WINDOWS POWERSHELL
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

$Equipo = $env:COMPUTERNAME
$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Archivo = "memoria_$Equipo.txt"

$Reporte = @()

function Agregar-Seccion {
    param([string]$Titulo)

    $script:Reporte += ""
    $script:Reporte += "=" * 65
    $script:Reporte += $Titulo
    $script:Reporte += "=" * 65
}

# ============================================================
# 1. INFORMACION GENERAL
# ============================================================

Agregar-Seccion "1. INFORMACION GENERAL"

$SO = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor | Select-Object -First 1

$Reporte += "Nombre del equipo: $Equipo"
$Reporte += "Sistema operativo: $($SO.Caption)"
$Reporte += "Version del sistema: $($SO.Version)"
$Reporte += "Fecha y hora: $Fecha"
$Reporte += "Arquitectura del sistema: $($SO.OSArchitecture)"
$Reporte += "Arquitectura del procesador: $($CPU.Architecture)"

# Orden de bytes de Windows
$Reporte += "Orden de bytes: Little-endian"

# ============================================================
# 2. INFORMACION DEL PROCESADOR
# ============================================================

Agregar-Seccion "2. INFORMACION DEL PROCESADOR"

$Reporte += "Procesador: $($CPU.Name)"
$Reporte += "Nucleos: $($CPU.NumberOfCores)"
$Reporte += "Procesadores logicos: $($CPU.NumberOfLogicalProcessors)"
$Reporte += "Frecuencia maxima: $($CPU.MaxClockSpeed) MHz"

# ============================================================
# 3. CACHES DEL PROCESADOR
# ============================================================

Agregar-Seccion "3. CACHES DEL PROCESADOR"

$Caches = Get-CimInstance Win32_CacheMemory

if ($Caches) {
    foreach ($Cache in $Caches) {

        $Nivel = $Cache.Level
        $Tamano = $Cache.InstalledSize
        $Linea = $Cache.LineSize
        $Vias = $Cache.Associativity
        $Proposito = $Cache.Purpose

        $Reporte += ""
        $Reporte += "Nivel: $Nivel"
        $Reporte += "Proposito: $Proposito"
        $Reporte += "Tamano: $Tamano KB"
        $Reporte += "Tamano de linea: $Linea bytes"
        $Reporte += "Vias reportadas: $Vias"
    }
}
else {
    $Reporte += "Windows no proporciono informacion de las caches mediante CIM."
}

# Intentar obtener informacion adicional mediante Get-CPUInfo no es
# necesario: se consultara directamente la API nativa de Windows.

# ============================================================
# 4. CONJUNTOS DE LA CACHE L1d
# Formula: S = C / (L * A)
# ============================================================

Agregar-Seccion "4. CALCULO DE CONJUNTOS DE L1d"

$Reporte += "Formula: S = C / (L * A)"
$Reporte += "C = capacidad de la cache en bytes"
$Reporte += "L = tamano de linea en bytes"
$Reporte += "A = numero de vias"

# La clase Win32_CacheMemory no identifica de forma fiable
# la cache L1 de datos ni proporciona todos sus parametros.
# Por eso no se debe inventar un resultado.

$Reporte += "Resultado: requiere identificar L1d, su capacidad,"
$Reporte += "tamano de linea y asociatividad con datos compatibles."
$Reporte += "Los campos de Win32_CacheMemory por si solos pueden no bastar."

# ============================================================
# 5. MEMORIA RAM
# ============================================================

Agregar-Seccion "5. MEMORIA RAM"

$RAMTotalKB = [double]$SO.TotalVisibleMemorySize
$RAMLibreKB = [double]$SO.FreePhysicalMemory

$RAMTotalGB = [math]::Round($RAMTotalKB / 1MB, 2)
$RAMLibreGB = [math]::Round($RAMLibreKB / 1MB, 2)

$Reporte += "RAM total: $RAMTotalGB GB"
$Reporte += "RAM libre: $RAMLibreGB GB"

# ============================================================
# 6. MEMORIA VIRTUAL Y ARCHIVO DE PAGINACION
# ============================================================

Agregar-Seccion "6. MEMORIA VIRTUAL Y ARCHIVO DE PAGINACION"

$PageFiles = Get-CimInstance Win32_PageFileUsage

if ($PageFiles) {
    foreach ($PageFile in $PageFiles) {
        $Reporte += "Archivo: $($PageFile.Name)"
        $Reporte += "Tamano asignado: $($PageFile.AllocatedBaseSize) MB"
        $Reporte += "Uso actual: $($PageFile.CurrentUsage) MB"
        $Reporte += ""
    }
}
else {
    $Reporte += "No se encontraron archivos de paginacion activos."
}

$MemoriaVirtual = Get-CimInstance Win32_OperatingSystem

$VirtualTotalGB = [math]::Round(
    $MemoriaVirtual.TotalVirtualMemorySize / 1MB, 2
)

$VirtualLibreGB = [math]::Round(
    $MemoriaVirtual.FreeVirtualMemory / 1MB, 2
)

$Reporte += "Memoria virtual total: $VirtualTotalGB GB"
$Reporte += "Memoria virtual libre: $VirtualLibreGB GB"

# ============================================================
# 7. DISCOS FISICOS
# ============================================================

Agregar-Seccion "7. DISCOS FISICOS"

$Discos = Get-CimInstance Win32_DiskDrive

foreach ($Disco in $Discos) {

    $TamanoGB = [math]::Round($Disco.Size / 1GB, 2)

    $Reporte += ""
    $Reporte += "Nombre: $($Disco.DeviceID)"
    $Reporte += "Modelo: $($Disco.Model)"
    $Reporte += "Interfaz: $($Disco.InterfaceType)"
    $Reporte += "Tamano: $TamanoGB GB"

    # Intentar determinar si es SSD o HDD.
    $TipoDisco = "No determinado"

    $PhysicalDisks = Get-PhysicalDisk

    foreach ($PD in $PhysicalDisks) {
        if ($PD.FriendlyName -eq $Disco.Model) {
            $TipoDisco = $PD.MediaType
        }
    }

    $Reporte += "Tipo: $TipoDisco"
}

# ============================================================
# 8. TIEMPOS DE EJECUCION DE MATRIZ
# ============================================================

Agregar-Seccion "8. TIEMPOS DE EJECUCION"

function Medir-Matriz {
    param(
        [string[]]$Argumentos,
        [string]$Descripcion
    )

    $Ruta = Join-Path (Get-Location) "matriz.exe"

    if (-not (Test-Path $Ruta)) {
        return "$Descripcion : No medido. No existe matriz.exe en la carpeta actual."
    }

    $Cronometro = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $Proceso = Start-Process `
            -FilePath $Ruta `
            -ArgumentList $Argumentos `
            -Wait `
            -PassThru `
            -NoNewWindow

        $Cronometro.Stop()

        return @(
            $Descripcion
            "Tiempo transcurrido: $($Cronometro.Elapsed.TotalSeconds) segundos"
            "Codigo de salida: $($Proceso.ExitCode)"
        ) -join "`r`n"
    }
    catch {
        $Cronometro.Stop()
        return "$Descripcion : Error al ejecutar: $($_.Exception.Message)"
    }
}

$Tiempo1 = Medir-Matriz -Argumentos @() -Descripcion "Ejecucion de matriz.exe"
$Tiempo2 = Medir-Matriz -Argumentos @("c") -Descripcion "Ejecucion de matriz.exe c"

$Reporte += $Tiempo1
$Reporte += ""
$Reporte += $Tiempo2

# ============================================================
# 9. GENERAR ARCHIVO
# ============================================================

$Reporte += ""
$Reporte += "=" * 65
$Reporte += "FIN DEL REPORTE"

$RutaReporte = Join-Path (Get-Location) $Archivo

$Reporte | Out-File -FilePath $RutaReporte -Encoding utf8

Write-Host ""
Write-Host "Reporte generado correctamente." -ForegroundColor Green
Write-Host "Archivo: $RutaReporte" -ForegroundColor Cyan