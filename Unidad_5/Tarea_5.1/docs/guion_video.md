# Guion del video · Tarea 5.1 — Hipervisores Tipo 1 vs Tipo 2

**Duración sugerida:** 10 a 12 minutos · **Cámara web:** esquina inferior derecha.
**Cómo usar este guion:** primero graba **solo la pantalla** siguiendo los pasos. Después grábate tú (cámara y voz) explicando ese video con los textos 🎙️ **Qué decir**.

Este video es de **exposición**: la mayor parte son los diagramas del README en GitHub. Hay dos demostraciones cortas: una en Windows y otra dentro de la VM.

---

## 0. Antes de grabar

1. Sube a GitHub los cambios de la Tarea 5.1 (los comandos de git te los paso aparte).
2. En el navegador abre el README de la tarea:
   `https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores/tree/main/Unidad_5/Tarea_5.1`
3. Abre **VirtualBox** y enciende **solo** la VM **Xubuntuu** (el servidor). Inicia sesión.
4. En Windows abre en el Explorador la carpeta `U5\Unidad_5\Tarea_5.1\scripts`, haz clic derecho en un espacio vacío y elige **Abrir en Terminal**. Deja la terminal lista.
5. Cierra notificaciones y programas que no vayas a usar: la RAM está justa.

---

## 1. Presentación (30 s)

**En pantalla:** el README de la Tarea 5.1 en GitHub, arriba del todo.

> 🎙️ **Qué decir:** Hola, soy Josué Javier Álvarez Valle. Esta es la Tarea 5.1 de Administración de Servidores. Voy a explicar qué es la virtualización, la diferencia entre los hipervisores tipo 1 y tipo 2 y los contenedores, los voy a comparar en sobrecarga, memoria, almacenamiento y red, y al final diré cuál conviene según el tamaño de la empresa. También voy a mostrar con mi propia laptop un caso real.

---

## 2. ¿Qué es virtualizar? (1 min)

**En pantalla:** baja a la sección **1. Principios** y detente en la tabla de Popek y Goldberg y en el diagrama **"¿Cómo se ejecutan las instrucciones privilegiadas del invitado?"**.

> 🎙️ **Qué decir:** Virtualizar es crear con software una versión lógica del hardware: CPU, memoria, disco y red. La pieza que reparte el hardware real entre las máquinas virtuales es el hipervisor. Para que sea correcto debe cumplir tres reglas: el programa se comporta igual que en una máquina real, el hipervisor controla todos los recursos, y la mayoría de las instrucciones corren directo en la CPU.
>
> Aquí se ven las tres técnicas. Antes se usaba la traducción binaria, que reescribe instrucciones y es lenta. Luego la paravirtualización, donde el sistema invitado se modifica para pedirle cosas al hipervisor. Hoy se usa la virtualización asistida por hardware, con Intel VT-x o AMD-V: el hipervisor vive en un modo especial llamado anillo menos uno, y el sistema invitado corre sin modificarse.

---

## 3. Hipervisor Tipo 1 (1.5 min)

**En pantalla:** sección **2. Clasificación**, diagrama **"Tres formas de virtualizar un servidor"** (columna izquierda). Después baja al diagrama **"Hipervisores tipo 1: tres diseños internos"** y a la tabla de productos.

> 🎙️ **Qué decir:** El hipervisor tipo 1, o bare-metal, se instala directamente sobre el hardware, sin un Windows o Linux de escritorio debajo. Por eso tiene muy poca sobrecarga y mejor aislamiento. Es lo que se usa en los centros de datos.
>
> Hay tres diseños. VMware ESXi es monolítico: su VMkernel trae los drivers y se administra desde vCenter. Hyper-V es microkernel: el hipervisor es delgado, y los drivers están en una partición raíz con Windows Server; las VMs se comunican por el VMBus. Proxmox usa KVM: el kernel Linux, con el módulo kvm, se convierte en hipervisor, y además puede correr contenedores LXC.

---

## 4. Hipervisor Tipo 2 y contenedores (1.5 min)

**En pantalla:** regresa al diagrama de las tres formas (columnas del centro y derecha) y luego las tablas 2.2 y 2.3.

> 🎙️ **Qué decir:** El tipo 2, o hosted, es un programa que se instala encima de un sistema operativo, como VirtualBox o VMware Workstation. Hay dos sistemas operativos, el anfitrión y el invitado, por eso tiene más sobrecarga y compite con mis otros programas por la RAM. A cambio, es gratis y muy fácil de usar: es ideal para aprender y hacer pruebas, como en este curso.
>
> Los contenedores son distinto: no virtualizan hardware. Todos comparten el mismo kernel Linux y se aíslan con namespaces y cgroups. Arrancan en segundos y casi no consumen, pero su aislamiento es menor, por eso en las empresas normalmente se corren dentro de máquinas virtuales.

---

## 5. Demostración en Windows: mi laptop es tipo 2 encima de tipo 1 (2 min)

**En pantalla:** la terminal de Windows abierta en la carpeta `scripts`. Escribe:

```powershell
powershell -ExecutionPolicy Bypass -File .\info_anfitrion.ps1
```

**Qué debe verse:** el procesador i3-1115G4 con 2 núcleos y 4 hilos, 7.7 GB de RAM, `Hipervisor presente: True`, la seguridad basada en virtualización **en ejecución**, la lista de VMs y la línea `fall back to NEM: VT-x is not available`.

Después cambia a la ventana de la VM **Xubuntuu** y señala con el mouse la **tortuga verde** en la barra de estado de abajo a la derecha. Luego en GitHub muestra el diagrama **"Mi laboratorio real"**.

> 🎙️ **Qué decir:** Ahora un caso real. Este script revisa mi laptop: tiene un i3 de 2 núcleos y casi 8 gigas de RAM. Lo interesante es esta línea: hay un hipervisor presente. Windows 11 activa la seguridad basada en virtualización, y para eso enciende Hyper-V, que es un tipo 1. Windows ya no corre directo sobre el hardware: corre como la partición raíz de Hyper-V.
>
> Entonces, cuando VirtualBox, que es tipo 2, quiere usar VT-x, lo encuentra ocupado y cambia al modo NEM, usando la API de Hyper-V. Lo dice esta línea del registro, y se ve en esta tortuga verde de la ventana de la VM. Es decir, en mi propia laptop hay un hipervisor tipo 2 trabajando encima de uno tipo 1.

---

## 6. Demostración dentro de la VM (2 min)

**En pantalla:** la terminal de la VM **Xubuntuu**.

Si todavía no tienes el repositorio en la VM:

```bash
cd /home/vboxuser
```

```bash
git clone https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores
```

Si ya lo tienes:

```bash
cd /home/vboxuser/Virtualizacion-Servidores
```

```bash
git pull
```

Ejecuta el script:

```bash
bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.1/scripts/detectar_virtualizacion.sh
```

**Qué debe verse:**

| Sección | Valor esperado |
|---|---|
| 1 | `systemd-detect-virt: oracle` y producto `VirtualBox` |
| 2 | 2 vCPU, bandera `hypervisor` **SÍ**, VT-x dentro de la VM **no** |
| 3 | Dispositivos `VirtualBox Guest Service`, Intel Ethernet, VMware SVGA |
| 4 | `vboxguest` cargado (ballooning) |
| 5 | disco `VBOX HARDDISK` |
| 6 | `enp0s3` y `enp0s8` con driver `e1000`; enp0s8 con 192.168.50.10 |
| 7 | fuente de reloj `kvm-clock` (paravirtualizada) |

> 🎙️ **Qué decir:** Ahora lo vemos desde dentro de la máquina virtual. El sistema sabe que está virtualizado: systemd lo detecta como oracle, que es VirtualBox. La CPU tiene la bandera hypervisor, que avisa que hay un hipervisor debajo, pero no tiene VT-x, así que aquí dentro no podría correr otra VM acelerada: no hay virtualización anidada.
>
> También se ve el hardware emulado: una tarjeta de red Intel que en realidad es software, un disco VBOX y el driver vboxguest, que sirve para el ballooning de memoria. Y el reloj usa kvm-clock, que es un ejemplo de paravirtualización: el invitado le pide la hora directo al hipervisor.

---

## 7. Tabla comparativa (2 min)

**En pantalla:** sección **3. Tabla comparativa técnica**. Recorre la tabla 3.1 fila por fila con el mouse. Después muestra el diagrama de memoria y la tabla de resumen 3.3.

> 🎙️ **Qué decir:** Esta es la tabla comparativa. En sobrecarga, los tipo 1 como ESXi y Proxmox gastan más o menos entre 2 y 5 por ciento; VirtualBox, entre 5 y 15, porque hay dos sistemas operativos; y los contenedores casi nada.
>
> En memoria, los tipo 1 permiten overcommit, que es asignar más RAM de la que existe; ballooning, que es un driver dentro de la VM que devuelve la memoria que no usa; y compartir páginas iguales entre VMs. VirtualBox reserva toda la RAM al encender, por eso yo solo puedo prender dos VMs a la vez.
>
> En almacenamiento compartido, ESXi tiene VMFS y vSAN, Hyper-V tiene Cluster Shared Volumes y Proxmox tiene Ceph; eso permite mover VMs en vivo entre servidores. Los tipo 2 no tienen eso. Y en red, los tipo 1 tienen switches virtuales y tarjetas paravirtualizadas casi a velocidad nativa; en VirtualBox el modo NAT es el más lento.

---

## 8. ¿Cuál conviene según la escala? (1.5 min)

**En pantalla:** sección **4**, diagrama **"¿Qué conviene según el tamaño de la organización?"** y su tabla.

> 🎙️ **Qué decir:** ¿Cuándo conviene cada uno? Para uso personal o en el aula, un tipo 2 como VirtualBox es suficiente. Para una pequeña empresa con uno a tres servidores, conviene un tipo 1 sencillo como Proxmox, que es gratis, o Hyper-V si ya pagan Windows Server. Una mediana empresa necesita un clúster con almacenamiento compartido para tener alta disponibilidad. Y una gran empresa o un proveedor de nube usa vSphere o KVM con OpenStack. Los contenedores sirven en cualquier escala para las aplicaciones, normalmente dentro de VMs.

---

## 9. Conclusión (30 s)

**En pantalla:** sección **6. Conclusiones**.

> 🎙️ **Qué decir:** En resumen: el tipo 2 es para aprender y probar, el tipo 1 es para producción, y los contenedores empaquetan aplicaciones encima de cualquiera de los dos. Para los servicios que hicimos en el curso, DNS, DHCP, web, correo y base de datos, yo recomendaría un servidor con Proxmox. Gracias.

---

## Si algo sale mal

| Problema | Solución |
|---|---|
| `info_anfitrion.ps1 no se puede cargar porque la ejecución de scripts está deshabilitada` | Escribe el comando completo con `powershell -ExecutionPolicy Bypass -File`, no solo el nombre del script. |
| La terminal de Windows no abre en la carpeta `scripts` | Escribe `cd` y un espacio, arrastra la carpeta `scripts` desde el Explorador a la terminal y presiona Enter. |
| `git clone` dice `Could not resolve host` | La VM no tiene internet: revisa que el adaptador 1 sea NAT y ejecuta `ping -c 2 github.com`. |
| `git pull` dice que hay cambios locales | Ejecuta `git checkout .` dentro de la carpeta del repositorio y repite `git pull`. |
| Sale `Permission denied` al ejecutar el script | Ejecútalo con `bash` delante, como en el guion. |
| `lspci no instalado` | `sudo apt install pciutils` y vuelve a ejecutar. |
| La fuente de reloj no es `kvm-clock` | No es un error: depende del proveedor de paravirtualización de la VM. Explica que la VM usa el reloj que muestra. |
| La laptop va muy lenta | Apaga el cliente y deja solo el servidor encendido; cierra el navegador mientras corre el script. |

## Capturas para el reporte

| # | Captura | Momento |
|---|---|---|
| 1 | Salida completa de `info_anfitrion.ps1` | Paso 5 |
| 2 | La tortuga verde en la barra de estado de la VM | Paso 5 |
| 3 | Secciones 1 y 2 de `detectar_virtualizacion.sh` | Paso 6 |
| 4 | Secciones 3 a 7 de `detectar_virtualizacion.sh` | Paso 6 |
| 5 | Configuración de la VM en VirtualBox: Sistema → Aceleración (paravirtualización) | Opcional |
