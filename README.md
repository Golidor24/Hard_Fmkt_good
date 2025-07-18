# Hardening Script - Fidelity Marketing 2025

Este script interactivo de Bash automatiza el proceso de hardening (fortalecimiento de seguridad) para sistemas Linux.  Permite ejecutar o auditar scripts de seguridad organizados en bloques y gestiona los logs de cada operación.

## Requisitos

*   Bash

*   Privilegios de root (el script debe ejecutarse con `sudo`)

*   Comandos: `find`, `chmod`, `mktemp`, `head`, `rm`, `less`, `tee`, `cat`, `echo`, `select`, `case`, `read`

## Uso

1.  **Clonar el repositorio:**

    ```bash
    git clone https://github.com/Golidor24/Hardening_Fmkt.git
    cd Hardening_Fmkt
    ```

2.  **Ejecutar el script:**

    ```bash
    sudo ./hardening.sh
    ```

3.  **Interfaz interactiva:**

    El script presenta un menú con las siguientes opciones:

    *   **Ejecutar:**  Ejecuta los scripts de hardening en cada bloque, aplicando las configuraciones de seguridad.  **Requiere reiniciar el sistema después de la ejecución.**

    *   **Auditar:**  Realiza una ejecución en modo "dry-run" (simulación), mostrando los cambios que se aplicarían sin realmente modificarlos.

    *   **Ver log general:**  Muestra el archivo `Hardening.log`, que contiene un registro de todas las ejecuciones y auditorías.

    *   **Ver logs por bloque:** Permite explorar los logs específicos de cada bloque de hardening, si existen.
    
    *   **Salir:** Termina la ejecución del script.

**Estructura del proyecto**

El proyecto debe organizarse en directorios `Bloque*`, cada uno representando un conjunto de configuraciones de hardening segun los informes de Nessus.  Dentro de cada bloque, los scripts de hardening deben tener la extensión `.sh`.  Opcionalmente, cada bloque puede contener una carpeta `Log` para almacenar logs específicos del bloque.

---
---

# Justificaciones y mitigaciones


**Justificación para omitir controles 1.1.2.x (particiones separadas)**

Los siguientes controles, relativos a la creación de particiones separadas, no aplican en este entorno:

*   1.1.2.3.1 – Ensure separate partition exists for /home
*   1.1.2.4.1 – Ensure separate partition exists for /var
*   1.1.2.5.1 – Ensure separate partition exists for /var/tmp
*   1.1.2.6.1 – Ensure separate partition exists for /var/log
*   1.1.2.7.1 – Ensure separate partition exists for /var/log/audit

**Justificación:**

Este sistema opera sobre una instancia de infraestructura en la nube (AWS EC2).  En esta arquitectura, el almacenamiento se gestiona mediante volúmenes dinámicos (EBS), donde la administración tradicional de particiones físicas no es necesaria ni viable.  La seguridad de los datos en directorios críticos como `/var/log` y `/var/log/audit` se logra a través de mecanismos alternativos, incluyendo el registro centralizado en CloudWatch y snapshots automatizados de volúmenes.

**Mitigación del riesgo:**
La arquitectura en la nube, junto con el registro externo y los snapshots, mitiga los riesgos asociados a la falta de particiones separadas.

**Justificación para el control 5.2.4 (sudo con contraseña)**

El control 5.2.4, que exige el uso de contraseña para la escalada de privilegios con `sudo`, se ha adaptado.  Actualmente, se permite el uso de `sudo` sin contraseña (`NOPASSWD`) para usuarios técnicos específicos, como `nessus`.

**Justificación:**

Esta excepción facilita la ejecución de escaneos de seguridad automatizados, necesarios para el monitoreo continuo del sistema.  El acceso de estos usuarios técnicos está estrictamente controlado mediante SSH y monitorizado con `auditd`, limitando su capacidad de acción a tareas específicas y necesarias para la seguridad del sistema.

**Mitigación del riesgo:**

El monitoreo de acceso y la restricción de permisos a usuarios técnicos mitigan el riesgo asociado con la configuración `NOPASSWD`.
