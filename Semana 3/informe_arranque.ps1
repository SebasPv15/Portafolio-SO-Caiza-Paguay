# Autores: Bryan Caiza, Fernando Paguay (GR1)
# Fecha: 28/10/2026
# Declaración de uso de IA: Ninguna IA generativa fue utilizada para obtener la salida de los comandos.

Write-Host "=== 1 · SO, versión y núcleo ==="
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "Sistema: $($os.Caption)"
Write-Host "Versión: $($os.Version) - Build: $($os.BuildNumber)"
Write-Host "Arquitectura: $($os.OSArchitecture)"

Write-Host "`n=== 2 · Último arranque y uptime ==="
$bootTime = $os.LastBootUpTime
Write-Host "Último arranque: $bootTime"
$uptime = (Get-Date) - $bootTime
Write-Host "Tiempo encendido: $($uptime.Days) días, $($uptime.Hours) horas, $($uptime.Minutes) minutos"

Write-Host "`n=== 3 · Desglose del arranque ==="
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    $fwTime = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction SilentlyContinue).FwPOSTTime
    Write-Host "FwPOSTTime: $fwTime ms"
    $evento = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($evento) { Write-Host "Evento 100: $($evento.Message)" }
} else {
    Write-Host "Aviso: Se requieren permisos de administrador para consultar FwPOSTTime y el evento 100."
}

Write-Host "`n=== 4 · Cinco unidades más lentas ==="
Write-Host "Servicios en ejecución y automáticos detenidos:"
Get-CimInstance Win32_Service | Where-Object { $_State -eq 'Running' -or ($_StartMode -eq 'Auto' -and $_.State -eq 'Stopped') } | Select-Object Name, DisplayName, State, StartMode -First 5

Write-Host "`n=== 5 · Módulos / controladores ==="
$drivers = Get-CimInstance Win32_SystemDriver | Where-Object State -eq 'Running'
Write-Host "Total de controladores en ejecución: $($drivers.Count)"
Write-Host "Muestra de driverquery:"
driverquery | Select-Object -First 8

Write-Host "`n=== 6 · Cierre ==="
$hiber = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction SilentlyContinue).HiberbootEnabled
Write-Host "HiberbootEnabled (inicio rápido): $hiber"