# Manual de reconstrucción paso a paso — Tarea 5.3

Este manual explica cómo volver a levantar **toda la infraestructura** (servidor y cliente con DHCP, DNS, web HTTPS, base de datos y almacenamiento) en una computadora nueva, usando solo VirtualBox, una ISO de Xubuntu 25.10 y los scripts de este repositorio.

Todos los comandos de Windows se escriben en **PowerShell**; los de Linux, en la **terminal de la VM** que se indique.

## 0. Requisitos

| Elemento | Detalle |
|---|---|
| Computadora | Windows 11, ≥ 8 GB de RAM (el servidor usa ≈ 3 GB y el cliente ≈ 2 GB) y ≥ 60 GB libres |
| Hipervisor | Oracle VirtualBox 7.2.x |
| ISO | Xubuntu 25.10 (64 bits), descargada de xubuntu.org |
| Internet | Para descargar los paquetes y clonar los repositorios |
| Repositorios | `Virtualizacion-Servidores` (este), `Administracion-Servidores` (Unidad 3) y `Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos` (Unidad 4) del usuario `JosueJavierAlvarezValle2024` |

> **Apaga las demás VMs de VirtualBox** antes de empezar: la RAM alcanza para dos máquinas a la vez, no para más.

## 1. Crear las máquinas virtuales (en Windows)

Clona este repositorio en Windows (o descárgalo) y entra a la carpeta de la tarea:

```powershell
git clone https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores
```

```powershell
cd Virtualizacion-Servidores\Unidad_5\Tarea_5.3
```

Crea las dos VMs con la ISO montada (cambia la ruta de la ISO):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\iac\crear_vms.ps1 -Iso C:\ISOs\xubuntu-25.10-desktop-amd64.iso
```

El script crea, con el mismo hardware del laboratorio original:

| VM | RAM | Red | Discos (dinámicos) |
|---|---|---|---|
| `u5r-srv01` (servidor) | 3072 MB, 2 vCPU | Adaptador 1 NAT · Adaptador 2 red interna `red-u4` | sistema 25 GB, datos 2 GB, respaldos 4 GB, y 3 discos de 1 GB para el RAID |
| `u5r-cli01` (cliente) | 2048 MB, 2 vCPU | Adaptador 1 red interna `red-u4`, MAC `08:00:27:81:8d:77` | sistema 25 GB |

> La MAC del cliente es la que reserva el servidor DHCP (192.168.50.20). Si todavía tienes el `Cliente-U4` original, no enciendas los dos clientes a la vez.

Para crear con otro nombre o menos memoria: `-Prefijo otro -RamServidor 2560 -RamCliente 1536`.
Para borrar todo y empezar de nuevo: `-Eliminar`.

## 2. Instalar el sistema del servidor

1. Enciende `u5r-srv01` e instala **Xubuntu 25.10** en el disco de 25 GB (el primero).
2. Datos de la instalación: usuario **`vboxuser`**, teclado en español (latinoamericano) y el nombre de equipo que prefieras (por ejemplo `srv01`; los scripts no lo cambian, y el DNS usa `srv01.empresa.lan` como nombre del registro).
3. Cuando reinicie, abre una terminal y deja el sistema al día y con las Guest Additions:

```bash
sudo apt update
```

```bash
sudo apt install -y git virtualbox-guest-utils virtualbox-guest-x11
```

4. Reinicia la VM (`sudo reboot`).
5. Comprueba que ve los discos vacíos que usarán las tareas de almacenamiento: `lsblk` debe mostrar `sda` (25 G), `sdb` (2 G), `sdc` (4 G) y `sdd`, `sde`, `sdf` (1 G cada uno).

## 3. Reconstruir los servicios del servidor (un solo comando)

Clona el repositorio dentro del servidor:

```bash
git clone https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores /home/vboxuser/Virtualizacion-Servidores
```

Primero **simula** el plan para ver qué va a ejecutarse (no cambia nada):

```bash
sudo bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3/scripts/iac/reconstruir_servidor.sh --simular
```

Después ejecútalo de verdad. La opción `--si` responde por ti las confirmaciones de formateo (`FORMATEAR` y `RAID`), que **borran `sdb` a `sdf`**: úsala solo si esos discos están vacíos, como en la VM recién creada.

```bash
sudo bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3/scripts/iac/reconstruir_servidor.sh --si
```

El script clona los repositorios de las unidades 3 y 4 y ejecuta, en este orden:

| # | Qué instala | Script |
|---|---|---|
| 1 | Usuarios, grupos y políticas de seguridad | Tarea 3.1 · `00_ejecutar_todo.sh` |
| 2 | Discos de datos y respaldos, ACL, cuotas y respaldos automáticos | Tarea 3.2 · `00` a `03` |
| 3 | RAID 5 y NAS (Samba y NFS) | Tarea 3.3 · `00_crear_raid.sh` y `02_compartir_samba_nfs.sh` |
| 4 | Red del servidor, **DHCP** y **DNS** | Tarea 4.1 · `00_ejecutar_todo.sh` |
| 5 | **Web HTTPS**, **MariaDB**, CA local, **FTPS** y **SFTP** | Tarea 4.2 · `00_ejecutar_todo.sh` |
| 6 | Correo SMTP/IMAP con TLS | Tarea 4.3 · `00_ejecutar_todo.sh` |
| 7 | Validación integral de todos los servicios | `servidor/01_validar_servicios.sh --completa` |

La bitácora queda en `/root/tarea53_reconstruccion_<fecha>.log`. Si un paso falla, el script se detiene y dice cuál; corrige el problema y vuelve a ejecutar (los scripts de las tareas son idempotentes).

Para omitir la Unidad 3 (solo DHCP, DNS, web, base de datos, FTP y correo): agrega `--sin-u3`.

## 4. Preparar el cliente

1. Enciende `u5r-cli01` **después** del servidor, e instala Xubuntu 25.10 igual que en el paso 2 (usuario `vboxuser`, nombre de equipo a tu gusto).
2. Con el servidor encendido, el cliente recibe solo su IP (192.168.50.20) del DHCP. Compruébalo con `ip -br addr`.
3. Instala las herramientas y clona los repositorios:

```bash
sudo apt install -y git curl bind9-dnsutils
```

```bash
git clone https://github.com/JosueJavierAlvarezValle2024/Virtualizacion-Servidores /home/vboxuser/Virtualizacion-Servidores
```

```bash
git clone https://github.com/JosueJavierAlvarezValle2024/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos /home/vboxuser/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos
```

4. Instala la autoridad certificadora de `empresa.lan` en el cliente (una sola vez):

```bash
bash /home/vboxuser/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos/Unidad_4/Tarea_4.2/scripts/cliente_pruebas.sh confiar-ca
```

## 5. Validar la infraestructura

**En el servidor** (inventario y validación de todos los servicios):

```bash
sudo bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3/scripts/servidor/01_validar_servicios.sh --completa
```

**En el cliente** (recorrido de los servicios y paso de tráfico entre ellos):

```bash
bash /home/vboxuser/Virtualizacion-Servidores/Unidad_5/Tarea_5.3/scripts/cliente/prueba_integral.sh
```

Ambos terminan con `Pruebas que fallaron: 0` y guardan su evidencia en la carpeta `evidencias/`.

## 6. Proteger el estado: snapshot en caliente (en Windows)

Con el servidor **encendido** y todos los servicios funcionando:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\01_crear_snapshot.ps1 -VM u5r-srv01
```

Si más adelante algo falla, se vuelve a ese estado con:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\02_restaurar_snapshot.ps1 -VM u5r-srv01
```

Ver [README.md](../README.md), sección de contingencia, para el procedimiento completo.

## 7. Si algo sale mal

| Problema | Solución |
|---|---|
| `crear_vms.ps1` dice que ya existe la VM | Usa otro `-Prefijo`, o bórralas con `-Eliminar` |
| `lsblk` no muestra los 5 discos extra | La VM no se creó con `crear_vms.ps1`: agrega los discos en *Configuración → Almacenamiento* |
| El paso 2 del orquestador (3.2) se queda esperando | Está pidiendo escribir `FORMATEAR`: ejecuta con `--si` o escríbelo tú |
| El DHCP no le da IP al cliente | Revisa que la MAC del cliente sea `080027818D77` y que el servidor se encendió primero |
| `git clone` dice `Could not resolve host` | El servidor no tiene internet: el adaptador 1 debe ser NAT |
| El navegador del cliente avisa del certificado | Falta instalar la CA: repite el paso 4.4 y reinicia Firefox |
| `02_restaurar_snapshot.ps1` no encuentra el snapshot | Crealo antes con `01_crear_snapshot.ps1` (con el mismo `-VM`) |
| Poca RAM al encender las dos VMs | Apaga todo lo demás o baja la RAM con `-RamServidor` y `-RamCliente` al crear las VMs |

## 8. Alcance de esta documentación

- Los scripts de **Windows** (`crear_vms`, `01_crear_snapshot`, `02_restaurar_snapshot`, `00_estado`, `99_validar`) se probaron en el laboratorio real.
- El orquestador `reconstruir_servidor.sh` ejecuta los scripts de las unidades 3 y 4, que ya se habían probado uno por uno; su ejecución encadenada sobre una VM completamente nueva **no se repitió de principio a fin** para esta entrega, y la parte del plan (`--simular`) sí se comprobó.
