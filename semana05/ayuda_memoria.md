# Ayuda Memoria - Semana 5: Auditoría de Seguridad
| Sección | Comando Linux (Bash) | Comando Windows (PowerShell) |
| :--- | :--- | :--- |
| **1. Llavero maestro** | `awk -F: '$3 == 0' /etc/passwd` y `getent group wheel` | `Get-LocalGroupMember -SID S-1-5-32-544` |
| **2. Puertas abiertas** | `ss -H -tln` | `Get-NetTCPConnection -State Listen` |
| **3. Portero activo** | `systemctl is-active firewalld` | `Get-NetFirewallProfile` |
| **4. Intentos fallidos** | `journalctl --since "24 hours ago" \| grep "Failed password"` | `Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625}` |
