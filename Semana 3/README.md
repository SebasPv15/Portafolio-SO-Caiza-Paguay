# Sistemas Operativos
*Integrantes:* Bryan Caiza y Sebastián Paguay
*Curso:* GR1
*Semana:* 3

---

## Comandos más importantes de Linux (Bash)

* ps -p 1 -o pid,comm: Muestra el proceso inicial del sistema operativo (el PID 1, generalmente systemd), a partir del cual se originan los demás procesos.
* systemctl list-units --type=service --state=running: Lista todos los servicios (daemons) que se encuentran actualmente en ejecución en el sistema.
* vmstat 1 2: Despliega estadísticas del sistema. Sirve para revisar el porcentaje de tiempo que la CPU pasa inactiva (id) o esperando operaciones de entrada/salida (wa).
* systemd-analyze time: Muestra el tiempo total de arranque del sistema desglosado por fases (núcleo, initrd y espacio de usuario).
* systemd-analyze blame: Enumera las unidades y servicios del sistema ordenados por el tiempo que tardaron en iniciar, útil para detectar cuellos de botella en el arranque.
* lsmod: Imprime la lista de todos los módulos del núcleo (kernel) que están cargados actualmente.
* modprobe <modulo> / rmmod <modulo>: Permiten cargar (contratar) y descargar (despedir) módulos del núcleo en caliente, respectivamente, sin necesidad de reiniciar el equipo.

## Comandos más importantes de Windows (PowerShell)

* Get-Process: Obtiene y lista todos los procesos que se están ejecutando actualmente en la memoria.
* Get-CimInstance Win32_OperatingSystem: Consulta las propiedades fundamentales del sistema operativo (versión, compilación, arquitectura) y datos como la memoria libre y el tiempo del último arranque (LastBootUpTime).
* Get-CimInstance Win32_Service: Lista los servicios de Windows, permitiendo filtrar por su estado (ej. en ejecución) o su modo de inicio (ej. automático).
* Get-WinEvent -FilterHashtable @{...}: Extrae eventos específicos del registro de diagnósticos de Windows, como el evento 100 para evaluar el tiempo de las fases de arranque.
* driverquery: Muestra una lista detallada de todos los controladores (drivers) instalados en el sistema y su estado actual.
* powercfg /a: Despliega los estados de suspensión disponibles en el hardware y verifica si la función de "Inicio rápido" (hiberboot) se encuentra habilitada.