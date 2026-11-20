# Guion del video — Tarea 5.2: entorno virtualizado y redes virtuales (≈ 16 min)

El video debe demostrar:

1. La **consola del hipervisor** (VirtualBox) con las dos máquinas virtuales de servidor.
2. La **configuración de los adaptadores de red** de cada VM: NAT, Solo anfitrión, Red interna y Puente.
3. **Pruebas de conectividad:** `ping`, trazas de ruta y acceso a servicios entre los segmentos de red.
4. **Pruebas de aislamiento:** qué se puede alcanzar y qué no.
5. La **compartición de recursos físicos:** vCPU y RAM, disco con aprovisionamiento fino y carpeta compartida.

La **cámara web** debe aparecer en la **esquina inferior derecha**.

> **Cómo usar este guion:** primero graba **solo la pantalla, sin voz**, siguiendo los pasos y comandos. Después grábate con cámara y micrófono explicando ese video: la columna **🎙️ Qué decir** de la tabla de pasos está junto a cada comando, en el mismo orden que la grabación. Léela como apoyo y dilo con tus palabras.

## Antes de grabar

- **OBS:** captura de pantalla completa y la cámara web pequeña en la esquina inferior derecha. Deja 2–3 líneas vacías al final de las terminales para que la cámara no tape el texto. Haz una prueba de 10 segundos.
- **VirtualBox:** abre el Administrador. Deben verse **`u5-web01`** y **`u5-db01`** con el estado **Encendida**. Las demás VMs (Xubuntuu, Cliente-U4, etc.) deben estar **apagadas**: la RAM es de 7.7 GB.
- Si las VMs no están creadas o están apagadas, enciéndelas **antes** de grabar (tarda varios minutos):
  `powershell -ExecutionPolicy Bypass -File .\scripts\00_ejecutar_todo.ps1`
- **Terminal de Windows:** en el Explorador abre la carpeta `U5\Unidad_5\Tarea_5.2`, haz clic derecho en un espacio vacío y elige **Abrir en Terminal**. El prompt debe terminar en `...\Tarea_5.2>`. Pon la letra grande (**Ctrl + +**).
- **Navegador:** ábrelo en una pestaña en blanco, para los pasos 9 y 10.
- **Estado inicial** (revísalo antes de grabar):
  - El NAT de db01 debe estar **conectado**. Si no: `powershell -ExecutionPolicy Bypass -File .\scripts\03_aislar_backend.ps1 -Modo Restaurar`
  - El límite de CPU de web01 debe estar al 100 %. Si no: `powershell -ExecutionPolicy Bypass -File .\scripts\01_recursos_dinamicos.ps1 -Restaurar`
- Comprueba que todo pasa: `powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1` debe terminar en **"Pruebas que fallaron: 0"**. Después `clear`.
- **Anota la IP del puente de web01** (se ve en el paso 7, en la interfaz `eth3`; por ejemplo `192.168.100.14`). La necesitas en el paso 10.
- Si te equivocas, usa **Pausar grabación** en OBS.

## Pasos

Los pasos 1 a 5 se hacen en **VirtualBox** y en la terminal de Windows; los pasos 6 a 8 y la mitad del 16, **dentro de las VMs** (`vagrant ssh`, prompt `vagrant@web01:~$`); los pasos 9 a 15 y el 17, en **Windows**. Lo que dice "debería" puede variar un poco en tu equipo (IP del puente, tiempos de respuesta).

| # | Tiempo | Comandos / acciones | Qué debería aparecer | 🎙️ Qué decir |
|---|---|---|---|---|
| 1 | ≈ 30 s | **Administrador de VirtualBox:** muestra las dos VMs `u5-web01` y `u5-db01` encendidas | Las dos VMs con el icono de **Encendida** · el resto, apagadas | **Presentación.** Hola, soy Josué Javier Álvarez Valle, de la materia Administración de Servidores. En la Tarea 5.2 despliego un entorno virtualizado con dos servidores y lo conecto con los cuatro modos de red de VirtualBox: NAT, solo anfitrión, red interna y puente. Después pruebo qué se puede alcanzar y qué queda aislado, y configuro los recursos: procesador, memoria, disco y carpeta compartida. Aquí en el hipervisor están las dos máquinas: web01, que es el servidor web, y db01, que es la base de datos. |
| 2 | ≈ 30 s | **Terminal de Windows:** `vagrant status` | `web01 running (virtualbox)` y `db01 running (virtualbox)` | **Vagrant.** Las máquinas no las creé a mano: las definí en un archivo, el Vagrantfile, y las levanté con Vagrant. Aquí se ve que las dos están encendidas. Eso hace que el entorno se pueda repetir con un solo comando. |
| 3 | ≈ 1 min 20 s | **En VirtualBox:** clic derecho en `u5-web01` → *Configuración → Red*. Recorre las pestañas **Adaptador 1, 2, 3 y 4**. En el **Adaptador 1**, abre *Avanzado → Reenvío de puertos* y ciérralo. Termina con **Cancelar** | Adaptador 1: **NAT** (reenvío `8088 → 80` y `2222 → 22`) · Adaptador 2: **Adaptador solo anfitrión** · Adaptador 3: **Red interna**, nombre `red-backend` · Adaptador 4: **Adaptador puente** con la tarjeta Wi-Fi | **Adaptadores de web01.** web01 tiene cuatro adaptadores, uno por cada modo. El primero es NAT: la máquina sale a internet a través de la computadora, y como nadie de afuera puede entrar, hay un reenvío de puertos: lo que llegue al 8088 de Windows pasa al puerto 80 de web01. El segundo es solo anfitrión: una red privada entre Windows y la máquina. El tercero es una red interna llamada red-backend, que solo existe entre las máquinas virtuales. Y el cuarto es el puente: conecta la máquina directo a mi red física, a través de la tarjeta Wi-Fi. |
| 4 | ≈ 50 s | Clic derecho en `u5-db01` → *Configuración → Red*. Recorre las pestañas **Adaptador 1, 2, 3 y 4**. Termina con **Cancelar** | Adaptador 1: **NAT** · Adaptador 2: **Red interna** `red-backend` · Adaptadores 3 y 4: **sin marcar** (deshabilitados) | **Adaptadores de db01.** db01 es la base de datos y está más protegida: solo tiene NAT, que Vagrant necesita para administrarla, y la red interna red-backend. No tiene adaptador solo anfitrión ni puente, así que Windows y mi red física no la ven. |
| 5 | ≈ 30 s | **Terminal de Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\04_ver_adaptadores.ps1` | Las dos VMs con cada adaptador: **NAT**, **Solo anfitrion**, **Red interna** `red-backend` y **Puente** (con la tarjeta MediaTek); el reenvío `8088 → 80` y las MAC · db01 con los adaptadores 3 y 4 **deshabilitado** | **Resumen desde el hipervisor.** Este script le pregunta a VirtualBox cómo está configurada cada máquina y lo resume. Es lo mismo que vimos en las ventanas: web01 con los cuatro modos y db01 solo con NAT y red interna. |
| 6 | ≈ 40 s | `vagrant ssh web01` → `ver_redes` | El prompt cambia a `vagrant@web01:~$` · cuatro interfaces: `eth0` **10.0.2.15** (NAT), `eth1` **192.168.56.10** (solo anfitrión), `eth2` **10.10.10.10** (red interna) y `eth3` con una IP de tu red física, por ejemplo **192.168.100.14** (puente) · la ruta `default via 10.0.2.2` | **Redes dentro de web01.** Ahora entro a web01. Cada adaptador de VirtualBox es una interfaz de Linux, con su dirección: la 10.0.2.15 es el NAT, la 192.168.56.10 es la red solo anfitrión, la 10.10.10.10 es la red interna, y la eth3 tiene una dirección de mi red física: es el puente. La ruta por defecto sale por el NAT, la 10.0.2.2. |
| 7 | ≈ 1 min | `ping -c 2 10.10.10.20` · `traceroute -n 10.10.10.20` · `probar_db` | `2 packets transmitted, 2 received, 0% packet loss` · la traza con **un solo salto**: `1  10.10.10.20` · la tabla de la base de datos con `Teclado`, `Mouse` y `Monitor` | **Red interna.** Desde web01 le hago ping a db01 por la red interna, la 10.10.10.20, y responde. La traza muestra un solo salto: están en el mismo segmento, sin router de por medio. Con probar_db, web01 consulta la base de datos de db01 por el puerto 3306: es un servicio entre dos segmentos funcionando. |
| 8 | ≈ 40 s | `ping -c 2 8.8.8.8` · `traceroute -n -m 3 8.8.8.8` · `exit` | `0% packet loss` · el primer salto de la traza es **`10.0.2.2`** (el NAT); los siguientes pueden salir con `* * *` (es normal) · al hacer `exit` vuelve el prompt de Windows | **Salida a internet.** web01 también llega a internet. En la traza, el primer salto es 10.0.2.2: es el NAT de VirtualBox, o sea, sale por el adaptador 1. Los asteriscos de después son routers que no contestan, y es normal. Salgo de web01 con exit. |
| 9 | ≈ 1 min | **Terminal de Windows:** `ping -n 2 192.168.56.10` · `tracert -d -h 3 192.168.56.10` · **Navegador:** abre `http://192.168.56.10` | Respuestas de `192.168.56.10` · la traza con **un salto** · en el navegador, la página **"web01 - frontend de la Tarea 5.2"** | **Solo anfitrión.** Ahora desde Windows. Le hago ping a web01 por la red solo anfitrión y responde, la traza es de un salto, y en el navegador se abre la página de web01. Esta red permite que yo administre las máquinas desde mi computadora sin exponerlas afuera. |
| 10 | ≈ 50 s | **Navegador:** abre `http://127.0.0.1:8088` · después `http://` + la **IP del puente** que anotaste (por ejemplo `http://192.168.100.14`) | La misma página de web01 en las dos direcciones | **NAT con reenvío y puente.** La primera dirección usa el reenvío de puertos del NAT: pido el puerto 8088 de mi computadora y llego al 80 de web01. La segunda es la dirección que web01 tiene en mi red física, por el puente: cualquier equipo de mi red, como un celular, podría abrirla. |
| 11 | ≈ 40 s | `ping -n 2 10.10.10.20` | `Tiempo de espera agotado` o `Host de destino inaccesible` en las dos pruebas · `100% perdidos` | **Aislamiento.** Ahora intento llegar a db01 desde Windows, a la 10.10.10.20. No responde: esa red interna solo existe dentro de VirtualBox, y Windows no está en ella. Es el aislamiento de los servicios del backend: la base de datos solo se alcanza a través de web01. |
| 12 | ≈ 1 min 40 s | `powershell -ExecutionPolicy Bypass -File .\scripts\03_aislar_backend.ps1 -Modo Aislar` | `[OK] NAT de db01 desconectado` · `Network is unreachable` y ✓ `[OK] db01 NO tiene salida a internet (aislada)` · ✓ `web01 SI alcanza a db01` y la tabla de la base de datos | **Aislamiento total.** db01 tiene NAT, y una máquina en NAT puede salir a internet. Para aislarla del todo, este script desconecta el cable virtual de ese adaptador. Ahora db01 no tiene salida a internet, pero web01 sigue alcanzándola por la red interna y sigue consultando la base de datos. Eso es una red de backend realmente segmentada. |
| 13 | ≈ 1 min 10 s | `powershell -ExecutionPolicy Bypass -File .\scripts\03_aislar_backend.ps1 -Modo Restaurar` | `[OK] NAT de db01 reconectado` · espera unos 12 s · `[..] db01 SI tiene salida a internet (por NAT)` | **Restaurar.** Reconecto el cable de db01 y, pasados unos segundos, vuelve a tener salida a internet. Lo dejo así porque Vagrant necesita ese adaptador para administrarla. |
| 14 | ≈ 1 min 10 s | `powershell -ExecutionPolicy Bypass -File .\scripts\01_recursos_dinamicos.ps1` · `powershell -ExecutionPolicy Bypass -File .\scripts\01_recursos_dinamicos.ps1 -Limite 50` · `powershell -ExecutionPolicy Bypass -File .\scripts\01_recursos_dinamicos.ps1 -Restaurar` | web01: **2 vCPU, 1024 MB** · db01: **1 vCPU, 1024 MB** · limite CPU **100 %** → `[OK] Limite aplicado sin reiniciar web01` y limite CPU **50 %** → de nuevo **100 %** | **vCPU y memoria.** Cada máquina tiene sus recursos asignados: web01, dos procesadores y un giga de RAM; db01, uno y un giga. Estos valores están en el Vagrantfile. Con este script puedo limitar la CPU de web01 al 50 por ciento sin apagarla, y luego la regreso a 100. Para cambiar la memoria o el número de procesadores sí hay que reiniciar la máquina. |
| 15 | ≈ 1 min 20 s | `powershell -ExecutionPolicy Bypass -File .\scripts\02_disco_fino.ps1` · `powershell -ExecutionPolicy Bypass -File .\scripts\02_disco_fino.ps1 -Llenar 500` | La tabla con `datos_web.vdi` y `datos_db.vdi`: **capacidad 20480 MB**, ocupando solo unas decenas o pocos cientos de MB · tras `-Llenar 500`, `df` muestra `/dev/sdb 20G ... /datos` con ≈ 500 MB usados y **`datos_web.vdi` crece ≈ 500 MB** | **Aprovisionamiento fino.** Cada máquina tiene un disco extra de 20 gigas, pero es de aprovisionamiento fino: en Windows solo ocupa lo que realmente se escribió. Aquí se ve la capacidad, 20 mil megas, contra lo que ocupa. Ahora escribo 500 megas dentro de web01: el disco crece solo esos 500 megas en Windows, y su capacidad sigue siendo de 20 gigas. Así se aprovecha mejor el espacio físico. |
| 16 | ≈ 1 min | `Set-Content compartido\hola.txt hola_desde_windows` · `vagrant ssh web01` → `cat /compartido/hola.txt` · `echo hola_desde_web01 > /compartido/web01.txt` · `exit` · `type compartido\web01.txt` | `hola_desde_windows` dentro de web01 · tras salir, `hola_desde_web01` en Windows | **Carpeta compartida.** La carpeta compartido de Windows aparece dentro de las máquinas como /compartido. Creo un archivo en Windows y web01 lo lee. Luego creo otro archivo desde web01 y Windows lo ve. Las dos máquinas comparten la misma carpeta. |
| 17 | ≈ 1 min 40 s | `powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1` (sube un poco para mostrar las secciones) | Las secciones 1 a 9 con líneas ✓ `[PASA]` y, al final, **`Pruebas que fallaron: 0`** y `Evidencia guardada en: ...validacion_...txt` | **Validación y cierre.** Por último, el script de validación repite todo de forma automática: el NAT, la red solo anfitrión, la red interna, el aislamiento de db01, el puente, las trazas, los recursos, los discos y la carpeta compartida. No hay ninguna falla. Con esto el entorno cumple: dos servidores en segmentos distintos, con los cuatro modos de red, recursos configurados y pruebas de conectividad y de aislamiento. Gracias. |

**Nota del paso 3:** abre la configuración solo para **ver** y termina siempre con **Cancelar**. Con la VM encendida, VirtualBox no deja cambiar casi nada, y no hace falta tocar nada.

**Nota del paso 6:** si tu terminal no reconoce `vagrant ssh`, abre una terminal nueva en la carpeta `Tarea_5.2`. El prompt de Linux es `vagrant@web01:~$`; todo lo que escribes ahí corre dentro de web01 hasta que escribes `exit`.

**Nota de los pasos 12 y 13:** mientras db01 está aislada, `vagrant ssh db01` **no funciona** (usa el NAT). Por eso el script comprueba db01 por otra vía, y por eso el paso 13 la restaura antes de seguir. **No termines el video sin hacer el paso 13.**

**Nota del paso 16:** usa `Set-Content` y no `echo ... > archivo` en Windows: con `>` PowerShell escribe el archivo en UTF-16 y Linux lo muestra con caracteres raros. Dentro de web01 sí puedes usar `echo ... >`.

## Después de grabar

- La validación guarda su salida en `evidencias/validacion_<fecha>.txt`: es un entregable del repositorio.
- Toma las capturas para el reporte:

  | # | Paso | Captura |
  |---|---|---|
  | 1 | 1 | Administrador de VirtualBox con `u5-web01` y `u5-db01` encendidas |
  | 2 | 3 | Configuración de red de `u5-web01`: las 4 pestañas (adaptadores 1 a 4) y el reenvío de puertos |
  | 3 | 4 | Configuración de red de `u5-db01` (adaptadores 1 y 2) |
  | 4 | 5 | Salida de `04_ver_adaptadores.ps1` |
  | 5 | 6 | `ver_redes` dentro de web01 |
  | 6 | 7 | `ping`, `traceroute` y `probar_db` desde web01 hacia db01 |
  | 7 | 8 | `traceroute` hacia 8.8.8.8 (primer salto `10.0.2.2`) |
  | 8 | 9 | Ping, `tracert` y la página de web01 por `192.168.56.10` |
  | 9 | 10 | La página por `127.0.0.1:8088` y por la IP del puente |
  | 10 | 11 | `ping` fallido de Windows hacia `10.10.10.20` |
  | 11 | 12 | `03_aislar_backend.ps1 -Modo Aislar` completo |
  | 12 | 14 | `01_recursos_dinamicos.ps1` con el límite de CPU |
  | 13 | 15 | `02_disco_fino.ps1 -Llenar 500` (antes y después) |
  | 14 | 16 | Carpeta compartida en las dos direcciones |
  | 15 | 17 | Resultado de `99_validar.ps1` |

## Si algo sale mal durante la grabación

| Problema | Solución |
|---|---|
| `vagrant` no se reconoce como comando | Abre una terminal **nueva** (se instaló después de abrir la anterior) o cierra y vuelve a abrir Windows Terminal. |
| El script dice que el archivo no existe | La terminal no está en la carpeta `Tarea_5.2`. Escribe `cd` y un espacio, arrastra la carpeta desde el Explorador y presiona Enter. |
| `vagrant ssh web01` se queda esperando o da error | Revisa `vagrant status`. Si dice `running`, espera un minuto; si dice `poweroff`, ejecuta `vagrant up web01`. |
| web01 no tiene IP en `eth3` (puente) | La red Wi-Fi no da IP a una VM en modo puente (pasa en escuelas). Graba el puente en tu casa o con un hotspot del celular. |
| El navegador no abre `http://192.168.100.14` | Esa IP cambió: mira la de `eth3` en `ver_redes` o con `vagrant ssh web01 -c ver_redes`. |
| `http://127.0.0.1:8088` no abre | Otro programa usa el 8088. Consulta el puerto real con `vagrant port web01` (línea `80 (guest)`). |
| `03_aislar_backend.ps1` dice que db01 sigue con internet | Espera unos segundos y repite; la VM tarda en cambiar su ruta. |
| La laptop va muy lenta | Cierra el navegador entre pasos y comprueba que las demás VMs estén apagadas. |
| Una VM se queda congelada | En el Administrador de VirtualBox: clic derecho en la VM → *Cerrar → Apagar la máquina*; luego en la terminal `vagrant up web01` (o `db01`). |
| Te equivocaste en un comando | Sigue grabando y repítelo; luego se puede recortar en el editor. |
