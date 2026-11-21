<#
.SYNOPSIS
    Auditoría de seguridad en Windows (5 secciones y veredicto).
.DESCRIPTION
    Revisa administradores locales (SID S-1-5-32-544 y cuenta -500), puertos TCP
    expuestos, perfiles de firewall y eventos 4625 (desde log o archivo -Muestra).
.NOTES
    Autores: Bryan Caiza, Fernando Paguay (Grupo GR1)
    Uso de IA: Generado con asistencia de IA (Gemini) para implementar las consultas
               de red, firewall, lectura de eventos 4625 sin permisos de administrador
               mediante -Muestra y exportación automática del reporte .txt.
#>

param(
    [string]$Muestra = "",
    [int]$Umbral = 5
)

$Alertas = 0
$Equipo = $env:COMPUTERNAME
$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$RutaReporte = if (Test-Path "semana05") { "semana05\auditoria_windows_$Equipo.txt" } else { "auditoria_windows_$Equipo.txt" }

$LineasReporte = New-Object System.Collections.Generic.List[string]

function Registrar {
    param([string]$Texto)
    Write-Output $Texto
    $LineasReporte.Add($Texto)
}

Registrar "============================================================"
Registrar " AUDITORÍA DE SEGURIDAD - WINDOWS ($Equipo)"
Registrar " Fecha: $Fecha | Umbral intentos: $Umbral"
if ($Muestra -ne "") {
    Registrar " Modo muestra activado: $Muestra"
}
Registrar "============================================================`n"

# ------------------------------------------------------------------------------
# SECCIÓN 1: Llavero maestro (SID S-1-5-32-544 y cuenta integrada ...-500)
# ------------------------------------------------------------------------------
Registrar "--- [1. Llavero maestro] ---"
try {
    $Admins = Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction Stop
    $Admin500Habilitado = $false

    foreach ($miembro in $Admins) {
        Registrar "  - Miembro: $($miembro.Name) | SID: $($miembro.SID)"
        if ($miembro.SID.Value -like "*-500") {
            $CuentaLocal = Get-LocalUser -SID $miembro.SID.Value -ErrorAction SilentlyContinue
            if ($CuentaLocal -and $CuentaLocal.Enabled) {
                $Admin500Habilitado = $true
            }
        }
    }

    if ($Admin500Habilitado) {
        Registrar "Estado Sección 1: ALERTA (La cuenta integrada Administrador ...-500 está habilitada)`n"
        $Alertas++
    } else {
        Registrar "Estado Sección 1: OK`n"
    }
} catch {
    Registrar "No se pudo consultar el grupo local: $_"
    Registrar "Estado Sección 1: ALERTA`n"
    $Alertas++
}

# ------------------------------------------------------------------------------
# SECCIÓN 2: Puertas abiertas (Puertos 21, 23, 3306, 3389, 5900 expuestos a red)
# ------------------------------------------------------------------------------
Registrar "--- [2. Puertas abiertas] ---"
$PuertosCriticos = @(21, 23, 3306, 3389, 5900)
$ConexionesExpuestas = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {
    ($PuertosCriticos -contains $_.LocalPort) -and
    ($_.LocalAddress -ne "127.0.0.1") -and
    ($_.LocalAddress -ne "::1")
}

if ($ConexionesExpuestas) {
    foreach ($conn in $ConexionesExpuestas) {
        Registrar "  - Puerto expuesto: $($conn.LocalAddress):$($conn.LocalPort)"
    }
    Registrar "Estado Sección 2: ALERTA`n"
    $Alertas++
} else {
    Registrar "Ningún puerto crítico (21, 23, 3306, 3389, 5900) expuesto a la red."
    Registrar "Estado Sección 2: OK`n"
}

# ------------------------------------------------------------------------------
# SECCIÓN 3: Portero activo (Perfiles de Windows Firewall)
# ------------------------------------------------------------------------------
Registrar "--- [3. Portero activo] ---"
$PerfilesFW = Get-NetFirewallProfile -ErrorAction SilentlyContinue
$PerfilApagado = $false

foreach ($perfil in $PerfilesFW) {
    Registrar "  - Perfil $($perfil.Name): Enabled = $($perfil.Enabled)"
    if (-not $perfil.Enabled) {
        $PerfilApagado = $true
    }
}

if ($PerfilApagado) {
    Registrar "Estado Sección 3: ALERTA (Uno o más perfiles de firewall están deshabilitados)`n"
    $Alertas++
} else {
    Registrar "Estado Sección 3: OK`n"
}

# ------------------------------------------------------------------------------
# SECCIÓN 4: Intentos fallidos (Eventos 4625 por IP desde -Muestra o registro)
# ------------------------------------------------------------------------------
Registrar "--- [4. Intentos fallidos] ---"
$ConteoIPs = @{}

if ($Muestra -ne "" -and (Test-Path $Muestra)) {
    # Soporta archivos .evtx o archivos de texto/log exportados
    if ($Muestra -like "*.evtx") {
        $Eventos = Get-WinEvent -Path $Muestra -FilterXPath "*[System[(EventID=4625)]]" -ErrorAction SilentlyContinue
        foreach ($ev in $Eventos) {
            if ($ev.Message -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                $ip = $Matches[1]
                if ($ip -ne "127.0.0.1" -and $ip -ne "0.0.0.0") {
                    $ConteoIPs[$ip] = ($ConteoIPs[$ip] -as [int]) + 1
                }
            }
        }
    } else {
        $Lineas = Get-Content $Muestra
        foreach ($linea in $Lineas) {
            if ($linea -match '4625' -and $linea -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                $ip = $Matches[1]
                if ($ip -ne "127.0.0.1" -and $ip -ne "0.0.0.0") {
                    $ConteoIPs[$ip] = ($ConteoIPs[$ip] -as [int]) + 1
                }
            }
        }
    }
} else {
    # Intento de lectura directa (si no hay permisos de admin, no rompe el script)
    try {
        $Hace24h = (Get-Date).AddHours(-24)
        $Eventos = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$Hace24h} -ErrorAction Stop
        foreach ($ev in $Eventos) {
            if ($ev.Message -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                $ip = $Matches[1]
                if ($ip -ne "127.0.0.1" -and $ip -ne "0.0.0.0") {
                    $ConteoIPs[$ip] = ($ConteoIPs[$ip] -as [int]) + 1
                }
            }
        }
    } catch {
        Registrar "Aviso: Sin permisos para leer Security Log directo. Use el parámetro -Muestra."
    }
}

$AlertaLogon = $false
if ($ConteoIPs.Count -gt 0) {
    Registrar "Conteo de eventos 4625 por IP:"
    foreach ($ip in $ConteoIPs.Keys) {
        $cant = $ConteoIPs[$ip]
        Registrar "  - IP: $ip -> $cant intentos"
        if ($cant -ge $Umbral) {
            $AlertaLogon = $true
        }
    }
} else {
    Registrar "No se encontraron eventos 4625 con IP origen."
}

if ($AlertaLogon) {
    Registrar "Estado Sección 4: ALERTA (Una o más IPs alcanzaron o superaron el umbral de $Umbral)`n"
    $Alertas++
} else {
    Registrar "Estado Sección 4: OK`n"
}

# ------------------------------------------------------------------------------
# SECCIÓN 5: Veredicto final
# ------------------------------------------------------------------------------
Registrar "============================================================"
if ($Alertas -gt 0) {
    Registrar " VEREDICTO FINAL: ALERTA ($Alertas secciones con hallazgos)"
    Registrar " Reporte guardado en: $RutaReporte"
    Registrar "============================================================"
    $LineasReporte | Out-File -FilePath $RutaReporte -Encoding UTF8
    exit 1
} else {
    Registrar " VEREDICTO FINAL: OK (Equipo sin alertas)"
    Registrar " Reporte guardado en: $RutaReporte"
    Registrar "============================================================"
    $LineasReporte | Out-File -FilePath $RutaReporte -Encoding UTF8
    exit 0
}
