# Portafolio de Sistemas Operativos - Grupo GR1

*Integrantes:* 
* Bryan Caiza
* Fernando Paguay

Repositorio oficial para las actividades, laboratorios, scripts y evidencias del portafolio de la materia de *Sistemas Operativos*.

---

## 📂 Contenido del Portafolio

### 📁 Semana 1: Introducción y Control de Versiones
* Configuración inicial del entorno de trabajo y repositorio en GitHub.
* Automatización de inventario de hardware inicial mediante scripts de sistema (inventario.sh e inventario.ps1).

### 📁 Semana 2: Reportes de Hardware, Memoria y Pruebas de Rendimiento
Desarrollo e implementación de scripts avanzados de automatización para la extracción de información profunda de hardware, arquitectura de procesadores, análisis de cachés, memoria RAM, archivos de paginación/Swap y medición de tiempos de ejecución de matrices en entornos multi-plataforma.

#### 🐧 Entorno Linux (Bash)
* *Script principal:* [Semana2/reporte_hardware.sh](./Semana2/reporte_hardware.sh)
* *Reporte generado:* [Semana2/memoria_sebas15-VirtualBox.txt](./Semana2/memoria_sebas15-VirtualBox.txt)

*Comandos de ejecución en Linux:*
```bash
# 1. Otorgar permisos de ejecución al script
chmod +x Semana2/reporte_hardware.sh

# 2. Ejecutar el script para compilar la información de hardware y memoria
./Semana2/reporte_hardware.sh