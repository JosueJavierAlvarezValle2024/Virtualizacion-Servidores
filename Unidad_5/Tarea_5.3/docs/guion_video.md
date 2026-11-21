# Guion del video — Tarea 5.3: proyecto integrador (≈ 18 min)

El video debe demostrar:

1. La **infraestructura virtualizada completa en funcionamiento**: servidor y cliente con DHCP, DNS, web HTTPS, base de datos y almacenamiento.
2. El **paso de tráfico entre los servicios**, visto desde el cliente.
3. Un **snapshot en caliente**, un **fallo de configuración** provocado a propósito y la **restauración del snapshot**.
4. El **desempeño del servidor** bajo carga.
5. La **infraestructura como código** para reconstruirlo todo.

La **cámara web** debe aparecer en la **esquina inferior derecha**.

> **Cómo usar este guion:** primero graba **solo la pantalla, sin voz**, siguiendo los pasos y comandos. Después grábate con cámara y micrófono explicando ese video: la columna **🎙️ Qué decir** de la tabla de pasos está junto a cada comando, en el mismo orden que la grabación. Léela como apoyo y dilo con tus palabras.

## Antes de grabar

- **OBS:** captura de pantalla completa y la cámara web pequeña en la esquina inferior derecha. Deja 2–3 líneas vacías al final de las terminales para que la cámara no tape el texto. Haz una prueba de 10 segundos.
- **VirtualBox:** apaga **todas** las VMs, incluidas `u5-web01` y `u5-db01` (con `vagrant halt` en la carpeta de la 5.2). Después enciende, en este orden y esperando a que cada una termine de arrancar:

  | VM | Papel | Estado al iniciar |
  |---|---|---|
  | **Xubuntuu** | Servidor `srv01` (192.168.50.10) | **Encendida**, con la sesión iniciada |
  | **Cliente-U4** | Cliente (192.168.50.20) | **Encendida**, con la sesión iniciada |

- **Repositorio al día** en las dos VMs (el servidor primero). En la terminal de cada una:
  `cd /home/vboxuser/Virtualizacion-Servidores`
  `git pull`
- **Windows:** en el Explorador abre la carpeta `U5\Unidad_5\Tarea_5.3`, clic derecho en un espacio vacío → **Abrir en Terminal**. El prompt debe terminar en `...\Tarea_5.3>`.
- **Servidor:** abre **una** terminal y déjala en la carpeta de la tarea:
  `cd /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3`
- **Cliente:** abre una terminal y entra a la misma carpeta. Abre también **Firefox**.
- **Comprobaciones previas** (fuera de cámara):
  - Que no exista ya el snapshot de la tarea: `powershell -ExecutionPolicy Bypass -File .\scripts\00_estado.ps1` no debe listar `5.3 Servicios integrados`. Si existe, bórralo desde el Administrador de VirtualBox → *Instantáneas* (**solo ese**, no los de las tareas 3.x ni la base enlazada).
  - Que todo pase: en el servidor `sudo bash scripts/servidor/01_validar_servicios.sh` y en el cliente `bash scripts/cliente/prueba_integral.sh` deben terminar en **"Pruebas que fallaron: 0"**. Después `clear` en las tres terminales.
- Letra grande en las terminales (**Ctrl + +**). Si te equivocas, usa **Pausar grabación** en OBS.

## Pasos

Los pasos 1, 2, 6, 9, 15 y 16 se hacen en **Windows**; los pasos 3, 7, 11, 14 y 17, en la terminal del **servidor**; los pasos 4, 5, 8 y 10, en el **cliente**; el 12 usa el servidor y el cliente a la vez y el 13 solo muestra los resultados. Lo que dice "debería" puede variar un poco en tu equipo (tiempos, números).

| # | Tiempo | Comandos / acciones | Qué debería aparecer | 🎙️ Qué decir |
|---|---|---|---|---|
| 1 | ≈ 40 s | **Administrador de VirtualBox:** muestra `Xubuntuu` y `Cliente-U4` encendidas | Las dos VMs con **Corriendo** · `Xubuntuu` con su cadena de snapshots en la lista de *Instantáneas* | **Presentación.** Hola, soy Josué Javier Álvarez Valle, de la materia Administración de Servidores. En la Tarea 5.3 integro en un ambiente virtualizado los servicios del curso: DHCP, DNS, web con HTTPS, base de datos y almacenamiento, en una topología cliente servidor. Después protejo el servidor con un snapshot, provoco un fallo y me recupero restaurándolo. Aquí en VirtualBox están las dos máquinas: el servidor Xubuntuu y el cliente. |
| 2 | ≈ 45 s | **Terminal de Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\00_estado.ps1` | Las dos VMs con estado `running` y la IP **192.168.50.10** del servidor · sus redes: el servidor con NAT y `red-u4`, el cliente solo con `red-u4` · los snapshots del servidor · RAM libre del anfitrión | **Estado de la infraestructura.** Este script le pregunta a VirtualBox cómo está todo. El servidor tiene dos adaptadores: uno NAT, para salir a internet, y otro en la red interna red-u4. El cliente solo está en red-u4, así que todo lo que necesita lo recibe del servidor. Abajo están los snapshots que ya existían y la memoria del equipo, que es poca: por eso solo caben dos máquinas. |
| 3 | ≈ 1 min 30 s | **Terminal del servidor:** `sudo bash scripts/servidor/01_validar_servicios.sh` | El **inventario** (servicio, programa, puerto, tarea) · todas las líneas ✓ `[PASA]`: DHCP, DNS, Apache, MariaDB, vsftpd, ssh · `MariaDB escucha solo en 127.0.0.1` · el RAID `md0` con **`[UUU]`** montado en `/srv/raid` · los servicios extra de correo y NAS · **`Pruebas que fallaron: 0`** | **Inventario de servicios.** En el servidor reviso todos los servicios. El DHCP reparte las direcciones por el puerto 67; el DNS de BIND9 resuelve los nombres de empresa.lan; Apache sirve la web por el 80 y el 443; MariaDB es la base de datos y solo escucha en la misma máquina, por seguridad; vsftpd y SSH dan el almacenamiento de archivos por FTPS y SFTP, y el RAID 5 protege los datos en tres discos. Las pruebas pasan todas y la salida queda guardada como evidencia. |
| 4 | ≈ 1 min 40 s | **Terminal del cliente:** `bash scripts/cliente/prueba_integral.sh` | Sección 1: IP **192.168.50.20** y puerta de enlace `192.168.50.10` · sección 2: `www.empresa.lan` → `192.168.50.10`, la inversa `srv01.empresa.lan.`, el MX · sección 3: `200 0` y `TLSv1.3` · sección 4: `conectado` y ✓ `MariaDB ... cerrado a la red` · sección 5: `Verify return code: 0` y `acceso anonimo es rechazado` · **`Pruebas que fallaron: 0`** | **Recorrido del cliente.** Ahora lo veo desde el cliente, que sigue el camino de un usuario. Primero el DHCP: recibió la 192.168.50.20 y usa al servidor como puerta de enlace. Luego el DNS resuelve los nombres, directos e inversos. Después la web por HTTPS con TLS 1.3 y el certificado de mi propia autoridad. La página PHP consulta MariaDB, y desde el cliente no se puede entrar directo a la base. Por último el FTPS con certificado válido y sin acceso anónimo. Todo pasa. |
| 5 | ≈ 50 s | **Cliente, Firefox:** abre `https://www.empresa.lan` y luego `https://intranet.empresa.lan` | El **candado** de HTTPS, la página con el protocolo **TLS 1.3**, "MariaDB: conectado" y la tabla de empleados · la página de la intranet | **La web.** Así lo ve un usuario: el candado indica que la conexión es segura. La página de arriba muestra la versión de TLS, y más abajo la lista de empleados sale de la base de datos MariaDB: ahí se ve el tráfico completo, del navegador a Apache, a PHP y a la base. La intranet es otro sitio en el mismo servidor, solo accesible desde la red interna. |
| 6 | ≈ 40 s | **Terminal de Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\01_crear_snapshot.ps1` | `Estado de Xubuntuu: running` · `[OK] Snapshot creado en ... segundos` (puede tardar de 1 a 3 minutos: **pausa la grabación** si hace falta) · la lista de snapshots con **`5.3 Servicios integrados`** al final y la carpeta de snapshots con más MB | **Snapshot en caliente.** Con todo funcionando, tomo una instantánea del servidor. Como está encendido, VirtualBox guarda no solo el disco sino también la memoria: así, al restaurarlo, el servidor vuelve ya encendido y con los servicios corriendo, como si nada hubiera pasado. Es mi punto de recuperación antes de hacer cambios riesgosos. |
| 7 | ≈ 50 s | **Terminal del servidor:** `sudo bash scripts/servidor/02_fallo_controlado.sh web` | `Linea cambiada` con `SSLCertificateFile /etc/ssl/empresa/servidor_ROTO.crt` · el error de Apache al reiniciar · en rojo **`[FALLO PROVOCADO] Apache no arranco: el HTTPS esta caido`** · `[CAIDO] apache2: failed` y `apache2ctl configtest` con el mensaje del certificado | **Fallo de configuración.** Ahora simulo un error típico de un administrador: cambio mal la ruta del certificado del sitio web. Apache lee la configuración al arrancar, no encuentra el archivo, y ya no inicia. El servicio HTTPS queda caído. Este es el tipo de error que pasa en producción con un cambio mal hecho. |
| 8 | ≈ 50 s | **Cliente:** recarga Firefox (`F5`) en `https://www.empresa.lan` · después `bash scripts/cliente/prueba_integral.sh` y deja ver la sección 3 y el resultado | En Firefox: **"No se puede conectar"** · en el script, ✗ `[FALLA]` en la web (redirección, HTTPS, la página) y **`Pruebas que fallaron:`** con un número mayor que 0 | **El daño visto desde el cliente.** Desde el cliente la web ya no responde: Firefox no puede conectarse, y mi script de pruebas marca fallas en toda la parte web. Los demás servicios, como el DNS y el DHCP, siguen funcionando: el fallo está acotado a la web. Es la evidencia de que la falla es real. |
| 9 | ≈ 2 min | **Terminal de Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\02_restaurar_snapshot.ps1` → escribe **`SI`** y Enter · observa la ventana del servidor (puede reiniciar y mostrar el escritorio) | `Servidor: Xubuntuu` · `Snapshot: 5.3 Servicios integrados` · `1. Apagando el servidor` · `2. Restaurando el snapshot` · `[OK] Snapshot restaurado` · `3. Encendiendo el servidor` · `[OK] El invitado responde. IPs: ... 192.168.50.10` · **`Tiempo total de recuperacion: ... segundos`** | **Restauración del snapshot.** Para recuperarme, no arreglo a mano el archivo: restauro el snapshot. El script apaga el servidor de golpe, como ante un fallo grave, restaura el snapshot, y lo vuelve a encender. Como el snapshot guardó la memoria, el servidor arranca directo con los servicios funcionando, y el script mide cuánto tardó la recuperación: aquí vemos el tiempo total. |
| 10 | ≈ 1 min 20 s | **Cliente:** recarga Firefox en `https://www.empresa.lan` · `bash scripts/cliente/prueba_integral.sh` | La página **vuelve a abrir** con el candado y la tabla de empleados · todo ✓ `[PASA]` y **`Pruebas que fallaron: 0`** | **Servicio recuperado.** Desde el cliente la web vuelve a funcionar y el script marca cero fallas: el servidor quedó exactamente como estaba antes del error. En total, la recuperación tardó los segundos que mostró el script, sin reinstalar nada ni buscar el error. |
| 11 | ≈ 40 s | **Servidor:** `sudo bash scripts/servidor/02_fallo_controlado.sh estado` | `[OK] apache2: activo` y `[OK] named: activo` · `Syntax OK` en `configtest` · HTTPS `200` · DNS `192.168.50.10` | **Comprobación en el servidor.** En el servidor lo confirmo: Apache activo, la configuración sin errores y los dos servicios respondiendo. El archivo del certificado volvió a tener su ruta correcta porque el snapshot restauró todo el disco. |
| 12 | ≈ 1 min 20 s | **Servidor:** `sudo bash scripts/servidor/03_rendimiento.sh 40` · **inmediatamente después, en el cliente:** `bash scripts/cliente/prueba_rendimiento.sh 600 10` (que arranque durante los 40 segundos de muestreo) | En el cliente: `Peticiones correctas: 600 de 600`, **peticiones por segundo** y latencias (promedio, mediana, **p95**, máxima) · en el servidor: CPU ocupada (promedio y pico), memoria libre mínima, carga, procesos de Apache, conexiones y **Mbit/s** de red | **Desempeño bajo carga.** Para medir el desempeño, el cliente manda seiscientas peticiones HTTPS, diez al mismo tiempo, a la página que usa Apache, PHP y MariaDB. Mientras, el servidor mide su CPU, memoria y red. Del lado del cliente vemos cuántas peticiones por segundo atiende y la latencia: el promedio y el percentil 95, que dice cuánto tardan las más lentas. |
| 13 | ≈ 50 s | Muestra los **dos resultados lado a lado** (servidor y cliente) y repasa los números | Los resúmenes de las dos terminales | **Interpretación.** Con carga, el servidor sube su uso de CPU, pero conserva memoria libre y ninguna petición falla. La latencia se mantiene baja, así que con dos procesadores y poca memoria el servidor atiende bien este tráfico. Esto me permite dimensionar la máquina: sé que tiene margen. |
| 14 | ≈ 50 s | **Servidor:** `sudo bash scripts/iac/reconstruir_servidor.sh --simular` (el comando completo: `sudo bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3/scripts/iac/reconstruir_servidor.sh --simular`) | El **plan de reconstrucción** de 11 pasos: 3.1, 3.2 (×4), 3.3 (×2), 4.1, 4.2, 4.3 y la validación integral · `Simulacion terminada: no se ejecuto nada` | **Infraestructura como código.** Todo lo que vimos se puede reconstruir desde cero con código. Este script reconstruye el servidor completo: descarga mis repositorios de las unidades 3 y 4 y ejecuta en orden cada configuración: usuarios, discos, RAID, DHCP, DNS, web, base de datos, FTP y correo, y al final valida. Con la opción simular solo muestra el plan, sin cambiar nada. |
| 15 | ≈ 1 min | **Navegador de Windows:** abre `https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores/tree/main/Unidad_5/Tarea_5.3` y muestra `scripts/iac/crear_vms.ps1` y `docs/manual_reconstruccion.md` | La carpeta de la tarea en GitHub · el script que crea las VMs · el manual paso a paso | **Repositorio y manual.** Todo está en mi repositorio público de GitHub. Otro script, crear_vms, crea las dos máquinas virtuales con el mismo hardware: procesadores, memoria, discos y redes. Y el manual de reconstrucción explica paso a paso cómo levantar el servidor y el cliente desde cero. Así, la infraestructura se puede replicar en otra computadora. |
| 16 | ≈ 50 s | **Terminal de Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1` | Todo ✓ `[PASA]`, incluidos `Existe el snapshot de la tarea` y **`El snapshot es en caliente (guarda la memoria: estado saved)`** · **`Pruebas que fallaron: 0`** | **Validación final.** Este último script comprueba la infraestructura desde Windows: las dos máquinas, que estén en la red interna, los seis discos del servidor y que el snapshot exista y sea en caliente, es decir, que guarda la memoria. No hay ninguna falla. |
| 17 | ≈ 40 s | **Servidor:** `sudo bash scripts/servidor/01_validar_servicios.sh --completa` (tarda unos minutos: **pausa la grabación** mientras corre y retoma al final) | Las secciones 1 a 6 y la **7: Validadores de las tareas anteriores** con ✓ `Tarea 3.3`, `4.1`, `4.2` y `4.3` y **`Pruebas que fallaron: 0`** | **Validación completa.** Y para cerrar, el modo completo ejecuta también los validadores de mis tareas anteriores y suma sus resultados: el almacenamiento, el DHCP y DNS, la web con FTPS, y el correo. Todo en cero fallas. Con esto la infraestructura queda integrada, protegida con un snapshot, probada ante un fallo y documentada para reconstruirla. Gracias. |

**Nota del paso 6:** si el snapshot tarda mucho (guarda unos 3.7 GB de memoria), usa **Pausar grabación** en OBS y retómala cuando aparezca `[OK] Snapshot creado`.

**Nota del paso 9:** al restaurar, **todo lo que hiciste en el servidor después del paso 6 desaparece** (el fallo del paso 7 también). Por eso las evidencias del servidor se generaron antes. La ventana del servidor se cierra y se vuelve a abrir sola; es normal. Si la sesión del cliente muestra la web caída aún, recarga Firefox.

**Nota del paso 12:** el script del cliente debe empezar **durante** los 40 segundos del script del servidor. Lo más fácil: ten las dos terminales abiertas, lanza primero la del servidor, pasa al cliente y lanza la del cliente enseguida.

**Nota del paso 17:** la validación completa ejecuta los validadores de las tareas 3.3, 4.1, 4.2 y 4.3 (el de correo envía un mensaje de prueba); pausa la grabación mientras trabaja y retómala para mostrar el resultado.

## Después de grabar

- Los scripts guardan su salida en `evidencias/` (en cada VM, dentro de su copia del repositorio) y la de Windows en la carpeta del repositorio de Windows: son entregables.
- **Al terminar, borra el snapshot de la tarea si necesitas espacio** (ocupa ≈ 4 GB): Administrador de VirtualBox → `Xubuntuu` → *Instantáneas* → clic derecho en `5.3 Servicios integrados` → *Eliminar*. **Solo ese.**
- Toma las capturas para la memoria técnica:

  | # | Paso | Captura |
  |---|---|---|
  | 1 | 1 | Administrador de VirtualBox con las dos VMs |
  | 2 | 2 | Salida de `00_estado.ps1` |
  | 3 | 3 | Inventario y resultado de `01_validar_servicios.sh` |
  | 4 | 4 | `prueba_integral.sh` del cliente (antes del fallo) |
  | 5 | 5 | Firefox en `https://www.empresa.lan` con el candado |
  | 6 | 6 | Creación del snapshot en caliente |
  | 7 | 7 | `02_fallo_controlado.sh web` con Apache caído |
  | 8 | 8 | Firefox sin conexión y `prueba_integral.sh` con fallas |
  | 9 | 9 | Restauración del snapshot con el tiempo de recuperación |
  | 10 | 10 | Firefox y `prueba_integral.sh` ya recuperados (0 fallas) |
  | 11 | 12 y 13 | Resultados de rendimiento (servidor y cliente) |
  | 12 | 14 | Plan de `reconstruir_servidor.sh --simular` |
  | 13 | 16 | `99_validar.ps1` |

## Si algo sale mal durante la grabación

| Problema | Solución |
|---|---|
| `01_validar_servicios.sh` marca fallas antes de empezar | Revisa cuál falla (la línea `[FALLA]` lo dice). Si es el DHCP o el DNS, el servidor se encendió después del cliente: reinicia el cliente |
| `prueba_integral.sh` no encuentra `dig` | `sudo apt install bind9-dnsutils` en el cliente |
| El cliente no tiene IP 192.168.50.20 | Apaga el cliente, comprueba que el servidor está encendido y vuelve a encender el cliente |
| `01_crear_snapshot.ps1` dice que ya existe el snapshot | Bórralo desde el Administrador de VirtualBox (solo ese) o usa `-Nombre "5.3 Servicios integrados 2"`; y entonces usa el mismo nombre en el paso 9 con `-Nombre` |
| `01_crear_snapshot.ps1` dice que hay poco espacio | Libera espacio en `C:`: se necesitan al menos 8 GB libres |
| El snapshot "en frio" no guarda la memoria | El servidor estaba apagado. Enciéndelo y espera a que arranquen los servicios antes del paso 6 |
| `02_fallo_controlado.sh web` no encuentra `SSLCertificateFile` | Revisa el archivo `/etc/apache2/sites-available/www.empresa.lan.conf` del servidor: debe existir (viene de la Tarea 4.2) |
| Tras restaurar, el invitado no reporta la IP 192.168.50.10 | Espera un par de minutos; si sigue, inicia sesión en la ventana del servidor y revisa `ip -br addr` |
| Firefox sigue mostrando "conexión rechazada" tras restaurar | Recarga con `Ctrl + F5`; si no, reinicia el cliente |
| `03_rendimiento.sh` pide los segundos | Escribe un número, por ejemplo `40` |
| Se acaba la RAM al encender las dos VMs | Cierra todo lo que no uses en Windows (navegador, OBS en vista previa) y confirma que `u5-web01` y `u5-db01` están apagadas |
| Te equivocaste en un comando | Sigue grabando y repítelo; luego se puede recortar en el editor |
