# Guion del video — Tarea 5.1: hipervisores Tipo 1, Tipo 2 y contenedores (≈ 12 min)

El video debe demostrar:

1. Qué es la **virtualización** y qué hace un **hipervisor**.
2. La diferencia entre **Tipo 1**, **Tipo 2** y **contenedores**, y su **comparación** en sobrecarga, memoria, almacenamiento compartido y red.
3. Un **caso real** en mi laptop: VirtualBox (Tipo 2) funcionando encima de Hyper-V (Tipo 1).
4. Las **huellas del hipervisor** vistas desde dentro de una VM Linux.
5. **Qué conviene** según el tamaño de la organización.

La **cámara web** debe aparecer en la **esquina inferior derecha**.

> **Cómo usar este guion:** primero graba **solo la pantalla, sin voz**, siguiendo los pasos y comandos. Después grábate con cámara y micrófono explicando ese video: la columna **🎙️ Qué decir** de la tabla de pasos está junto a cada acción, en el mismo orden que la grabación. Léela como apoyo y dilo con tus palabras.

Este video es sobre todo de **exposición**: la mayor parte de la pantalla son el README y los diagramas en GitHub. Hay dos demostraciones cortas con comandos: una en Windows (pasos 7 y 8) y otra dentro de la VM (pasos 9 y 10).

## Antes de grabar

- **OBS:** captura de pantalla completa y la cámara web pequeña en la esquina inferior derecha. Deja 2–3 líneas vacías al final de las terminales para que la cámara no tape el texto. Haz una prueba de 10 segundos.
- **Git:** sube a GitHub los cambios de la Tarea 5.1 (README, diagrama 03, reporte y evidencias). Los comandos los ejecutas tú.
- **Navegador:** abre el README de la tarea y déjalo arriba del todo:
  `https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores/tree/main/Unidad_5/Tarea_5.1`
- **VirtualBox 7.2.20:**

  | VM | Estado al iniciar |
  |---|---|
  | **Xubuntuu** (servidor) | **Encendida**, con sesión iniciada |
  | **Cliente-U4**, UbuntuServer, FedoraServer y WinServer2022 | **Apagadas** (la RAM es de 7.7 GB y no alcanza para más) |

- **Windows:** en el Explorador abre la carpeta `U5\Unidad_5\Tarea_5.1\scripts`, haz clic derecho en un espacio vacío y elige **Abrir en Terminal**. Deja la terminal lista, sin ejecutar nada.
- **Servidor (Xubuntuu):** abre una terminal y escribe estos dos comandos para dejar el repositorio al día:
  `cd /home/vboxuser/Virtualizacion-Servidores`
  `git pull`
  Después `clear`.
- Cierra notificaciones y programas que no uses. Pon la **letra grande** en las dos terminales (**Ctrl + +**). Si te equivocas, usa **Pausar grabación** en OBS.

## Pasos

Los pasos 1 a 6 y 11 a 14 se hacen en el **navegador** (README en GitHub); los pasos 7 y 8, en **Windows**; los pasos 9 y 10, en la **VM Xubuntuu**.

| # | Tiempo | Comandos / acciones | Qué debe aparecer | 🎙️ Qué decir |
|---|---|---|---|---|
| 1 | ≈ 30 s | **Navegador:** el README de la Tarea 5.1 en GitHub, arriba del todo | El título *Estudio analítico de arquitecturas de virtualización e hipervisores* y la tabla de contenido | **Presentación.** Hola, soy Josué Javier Álvarez Valle, de la materia Administración de Servidores. Esta es la Tarea 5.1. Voy a explicar qué es la virtualización, la diferencia entre los hipervisores tipo 1 y tipo 2 y los contenedores, y los voy a comparar en cuatro puntos: sobrecarga, memoria, almacenamiento y red. Al final diré cuál conviene según el tamaño de la empresa, y voy a mostrar un caso real en mi propia laptop. |
| 2 | ≈ 50 s | Baja a **1. Principios de la virtualización** y detente en la tabla de **Popek y Goldberg** | La tabla con **Equivalencia**, **Control de recursos** y **Eficiencia** | **Qué es virtualizar.** Virtualizar es crear con software una versión lógica del hardware: CPU, memoria, disco y red. Una máquina virtual es un equipo completo hecho de esos recursos. La pieza que reparte el hardware real entre las máquinas virtuales es el hipervisor. Para ser correcto debe cumplir tres reglas: el programa se comporta igual que en una máquina real, el hipervisor controla todos los recursos, y la mayoría de las instrucciones corren directo en la CPU, sin su ayuda. |
| 3 | ≈ 50 s | Baja al diagrama de las **técnicas de virtualización de CPU** y a su tabla | Las tres técnicas: **traducción binaria**, **paravirtualización** y **asistida por hardware** | **Tres técnicas.** Hubo tres formas de lograrlo. Primero la traducción binaria, que reescribe las instrucciones del sistema invitado y es lenta. Luego la paravirtualización, donde el sistema invitado se modifica para pedirle cosas al hipervisor; hoy se usa sobre todo en los drivers. Y la que se usa hoy: la virtualización asistida por hardware, con Intel VT-x o AMD-V. La CPU tiene un modo especial para el hipervisor, y el sistema invitado corre sin modificarse. Es la que usan KVM, ESXi, Hyper-V y VirtualBox. |
| 4 | ≈ 50 s | Baja a **2. Clasificación**, al diagrama de las **tres arquitecturas** lado a lado | Tipo 1, Tipo 2 y contenedores en tres columnas | **Tres arquitecturas.** Aquí se ven las tres formas de virtualizar. En la primera, el hipervisor va directo sobre el hardware. En la segunda, hay un sistema operativo en medio. Y en la tercera, los contenedores comparten un solo kernel. Ahora las explico una por una. |
| 5 | ≈ 1 min 20 s | Baja a **2.1 Hipervisor Tipo 1**, al diagrama de los **diseños internos** y a la tabla de productos | ESXi (monolítico), KVM/Proxmox y Hyper-V (microkernel) | **Tipo 1.** El hipervisor tipo 1, o bare-metal, se instala directo sobre el hardware, sin un Windows o Linux de escritorio debajo. Por eso tiene muy poca sobrecarga y mejor aislamiento. Es lo que se usa en los centros de datos. Hay tres diseños. VMware ESXi es monolítico: su VMkernel trae los drivers y se administra desde vCenter. Hyper-V es microkernel: el hipervisor es delgado y los drivers están en una partición raíz con Windows. Y Proxmox usa KVM: el kernel Linux se convierte en hipervisor y además puede correr contenedores LXC. |
| 6 | ≈ 1 min 20 s | Baja a **2.2 Tipo 2** y **2.3 Contenedores** y recorre las dos tablas | VirtualBox, VMware Workstation, KVM/QEMU · LXC y Docker | **Tipo 2 y contenedores.** El tipo 2, o hosted, es un programa que se instala encima de un sistema operativo, como VirtualBox o VMware Workstation. Hay dos sistemas operativos, el anfitrión y el invitado, así que gasta más y compite con mis otros programas por la RAM. A cambio es gratis y fácil: es ideal para aprender, como en este curso. Los contenedores son distintos: no virtualizan hardware. Todos comparten el mismo kernel Linux y se aíslan con namespaces y cgroups. Arrancan en segundos y casi no consumen, pero su aislamiento es menor, y por eso en las empresas normalmente se corren dentro de máquinas virtuales. |
| 7 | ≈ 1 min 30 s | **Terminal de Windows** (carpeta `scripts`): `powershell -ExecutionPolicy Bypass -File .\info_anfitrion.ps1` | `i3-1115G4`, 2 núcleos / 4 hilos, 7.7 GB de RAM · `Hipervisor presente: True` · `Seguridad basada en virtualizacion: en ejecucion` · `Version: 7.2.20...` · las 5 VMs con su RAM (solo **Xubuntuu** en `running`) · las líneas `fall back to NEM: VT-x is not available` y `WHvCapabilityCodeHypervisorPresent is TRUE` | **Mi laptop.** Ahora un caso real. Este script revisa mi laptop, que tiene un i3 de 2 núcleos y casi 8 gigas de RAM. Lo importante es esta línea: hay un hipervisor presente. Windows 11 activa la seguridad basada en virtualización, y para eso enciende Hyper-V, que es un tipo 1. Windows ya no corre directo sobre el hardware: corre como la partición raíz de Hyper-V. Aquí está VirtualBox en su versión 7.2.20 y mis cinco máquinas virtuales. Si las sumo, tienen asignados unos 15 gigas de RAM contra 7.7 físicos, por eso solo puedo encender dos a la vez: VirtualBox reserva la memoria completa. |
| 8 | ≈ 50 s | **Ventana de la VM Xubuntuu:** señala con el mouse la **tortuga verde** en la barra de estado, abajo a la derecha · **Navegador:** el diagrama **Mi laboratorio real** (sección 2.4) | La tortuga verde (modo NEM) · el diagrama con VirtualBox 7.2.20 encima de Windows y Hyper-V | **Tipo 2 sobre tipo 1.** Cuando VirtualBox, que es tipo 2, quiere usar VT-x, lo encuentra ocupado por Hyper-V y cambia al modo NEM, que usa la API de Hyper-V. Lo dice esa línea del registro y se ve en esta tortuga verde de la ventana de la VM. Es decir, en mi propia laptop hay un hipervisor tipo 2 trabajando encima de uno tipo 1. El diagrama lo resume: abajo el hardware, luego Hyper-V, luego Windows y encima VirtualBox con mis máquinas. |
| 9 | ≈ 20 s | **Terminal de la VM Xubuntuu:** `cd /home/vboxuser/Virtualizacion-Servidores` · `git pull` · `clear` (si ya hiciste el `pull` antes de grabar, solo muestra el `cd`) | `Ya está actualizado.` o la lista de archivos que bajó | **Entro a la VM.** Ahora me paso a la máquina virtual del servidor. Entro a la carpeta del repositorio y lo actualizo con git pull. |
| 10 | ≈ 1 min 10 s | `bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.1/scripts/detectar_virtualizacion.sh` | Sección 1: `oracle` y producto `VirtualBox` · sección 2: modelo i3-1115G4, 2 vCPU, hipervisor `KVM`, tipo `full`, bandera `hypervisor` **SÍ** y VT-x dentro de la VM **no** · sección 3: VMSVGA, dos tarjetas Intel 82540EM y `VirtualBox Guest Service` · sección 4: `vboxguest` cargado · sección 5: discos `VBOX HARDDISK` · sección 6: `enp0s3` y `enp0s8` con driver `e1000` · sección 7: `kvm-clock` · al final, `Evidencia guardada en: ...` | **Desde dentro de la VM.** Ahora lo vemos desde dentro de la máquina virtual. El sistema sabe que está virtualizado: systemd lo detecta como oracle, que es VirtualBox. La CPU tiene la bandera hypervisor, que avisa que hay un hipervisor debajo, pero no tiene VT-x, así que aquí dentro no podría correr otra máquina acelerada: no hay virtualización anidada. También se ve el hardware emulado: una tarjeta de red Intel que en realidad es software, discos VBOX y el driver vboxguest, que permite el ballooning de memoria. El kernel dice que el hipervisor es KVM porque VirtualBox le ofrece esa interfaz de paravirtualización, y por eso el reloj es kvm-clock: el sistema le pide la hora directo al hipervisor. |
| 11 | ≈ 45 s | **Navegador:** baja a **3.2 Cómo se administra la memoria** y muestra el diagrama y la tabla | Overcommit, ballooning, páginas compartidas y compresión / swap | **Memoria.** Los tipo 1 manejan la memoria de forma más inteligente. El overcommit es asignar más RAM de la que existe, confiando en que no todas las máquinas la usan a la vez. El ballooning es un driver dentro de la máquina que devuelve la memoria que no usa. Y las páginas compartidas guardan una sola vez lo que es idéntico, como el mismo kernel en diez máquinas. VirtualBox reserva toda la RAM al encender, y por eso en mi laptop no puedo pasarme. |
| 12 | ≈ 1 min 20 s | Baja a **3.1 Comparativa por plataforma** y recorre la tabla fila por fila con el mouse · después muestra la tabla **3.3 Resumen cualitativo** | La tabla de siete plataformas con las cuatro columnas · la tabla de puntos ● | **Tabla comparativa.** Esta es la tabla comparativa. En sobrecarga, los tipo 1 como ESXi y Proxmox gastan entre 2 y 5 por ciento; VirtualBox entre 5 y 15, porque hay dos sistemas operativos; y los contenedores casi nada. En almacenamiento compartido, ESXi tiene VMFS y vSAN, Hyper-V tiene Cluster Shared Volumes y Proxmox tiene Ceph; eso permite mover máquinas en vivo entre servidores, y los tipo 2 no lo tienen. En red, los tipo 1 tienen switches virtuales y tarjetas paravirtualizadas casi a velocidad nativa; en VirtualBox, el modo NAT es el más lento. Los puntos de la tabla de abajo resumen todo. |
| 13 | ≈ 1 min | Baja a **4. ¿Cuándo conviene cada uno?** y muestra el diagrama y la tabla | Cinco filas: personal, pequeña, mediana, gran empresa y aplicaciones modernas | **Qué conviene.** Para uso personal o en el aula, un tipo 2 como VirtualBox es suficiente. Para una pequeña empresa con uno a tres servidores, conviene un tipo 1 sencillo como Proxmox, que es gratis, o Hyper-V si ya pagan Windows Server. Una mediana empresa necesita un clúster con almacenamiento compartido para tener alta disponibilidad. Y una gran empresa o un proveedor de nube usa vSphere o KVM con OpenStack. Los contenedores sirven en cualquier escala para las aplicaciones, normalmente dentro de máquinas virtuales. |
| 14 | ≈ 40 s | Baja a **6. Conclusiones** | Las cinco conclusiones | **Conclusión y cierre.** En resumen: el tipo 2 es para aprender y probar, el tipo 1 es para producción, y los contenedores empaquetan aplicaciones encima de cualquiera de los dos. La frontera no es rígida: en mi laptop un tipo 2 corre sobre un tipo 1. Para los servicios que hicimos en el curso, DNS, DHCP, web, correo y base de datos, yo recomendaría un servidor con Proxmox. Gracias. |

**Nota del paso 7:** el script lee el registro de VirtualBox de la VM **Xubuntuu**, así que ella debe estar **encendida** cuando lo ejecutes. Si la apagaste, la última sección sale vacía. Las demás VMs deben estar apagadas para que en la lista solo una diga `running`.

**Nota del paso 10:** ejecútalo **sin `sudo`**. Con `sudo` el archivo de evidencia queda a nombre de root y después `git pull` puede dar problemas de permisos.

## Después de grabar

- Los scripts guardan su salida en `evidencias/` (`anfitrion.txt` y `virtualizacion_Xubuntuu.txt`): son entregables del repositorio.
- Toma las capturas para el reporte (las de esta tarea ya están, pero repítelas si cambias algo):

  | # | Paso | Captura |
  |---|---|---|
  | 1 | 7 | Salida completa de `info_anfitrion.ps1` |
  | 2 | 8 | La tortuga verde en la barra de estado de la VM |
  | 3 | 10 | Salida completa de `detectar_virtualizacion.sh` (secciones 1 a 8) |
  | 4 | Opcional | VirtualBox: *Configuración → Sistema → Aceleración* (interfaz de paravirtualización) |

## Si algo sale mal durante la grabación

| Problema | Solución |
|---|---|
| `info_anfitrion.ps1 no se puede cargar porque la ejecución de scripts está deshabilitada` | Escribe el comando completo con `powershell -ExecutionPolicy Bypass -File`, no solo el nombre del script. |
| El script de Windows dice que el argumento de `-File` no existe | La terminal no está en la carpeta `scripts`. Escribe `cd` y un espacio, arrastra la carpeta `scripts` desde el Explorador a la terminal y presiona Enter. |
| En el script de Windows la última sección sale vacía | La VM Xubuntuu está apagada: enciéndela y vuelve a ejecutar. |
| La VM se queda en pantalla negra al encender | Probablemente tiene un estado guardado de otra versión de VirtualBox. En el Administrador de VirtualBox: clic derecho en la VM → **Descartar estado guardado**, y enciéndela otra vez. |
| `git pull` dice que hay cambios locales | Ejecuta `git checkout .` dentro de la carpeta del repositorio y repite `git pull`. |
| `git pull` dice *Permission denied* en `evidencias` | El archivo quedó a nombre de root. Ejecuta `sudo chown -R vboxuser:vboxuser /home/vboxuser/Virtualizacion-Servidores` y repite `git pull`. |
| `git clone` dice `Could not resolve host` | La VM no tiene internet: revisa que el adaptador 1 sea NAT y ejecuta `ping -c 2 github.com`. |
| Sale `Permission denied` al ejecutar el script de la VM | Ejecútalo con `bash` delante, como en el guion. |
| `lspci no instalado` | `sudo apt install pciutils` y vuelve a ejecutar. |
| La fuente de reloj no es `kvm-clock` | No es un error: depende del proveedor de paravirtualización de la VM. Explica que la VM usa el reloj que muestra. |
| La laptop va muy lenta | Cierra el navegador mientras corren los scripts y deja solo la VM del servidor encendida. |
| Te equivocaste en un comando | Sigue grabando y repítelo; luego se puede recortar en el editor. |
