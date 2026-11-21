# =============================================================================
#  01_crear_snapshot.ps1 - Crea un snapshot EN CALIENTE del servidor
#
#  Con el servidor encendido, VirtualBox guarda el disco y tambien la memoria
#  RAM: al restaurarlo, la VM vuelve a estar encendida y con los servicios
#  funcionando, justo como estaban al tomar el snapshot.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\01_crear_snapshot.ps1
#  Opcional: -Nombre "otro nombre"   -VM "otra VM"
# =============================================================================
param([string]$Nombre = '', [string]$VM = '')

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base
if ($VM) { $SERVIDOR = $VM }
if (-not $Nombre) { $Nombre = $SNAP_OK }

if (-not (Existe-VM $SERVIDOR)) { Falla "No existe la VM '$SERVIDOR'" }

Titulo "Antes de crear el snapshot"
$estado = Estado-VM $SERVIDOR
Info "Estado de ${SERVIDOR}: $estado"
if ($estado -ne 'running') {
    Aviso 'La VM no esta encendida: el snapshot sera "en frio" (solo disco, sin memoria).'
    Aviso 'Para un snapshot en caliente, enciende el servidor y espera a que arranquen los servicios.'
}
if ((Snapshots-VM $SERVIDOR) -contains $Nombre) {
    Falla "Ya existe un snapshot llamado '$Nombre'. Borralo o usa -Nombre con otro nombre."
}
$libre = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
Info "Espacio libre en C: $libre GB (un snapshot en caliente guarda hasta toda la RAM de la VM)"
if ($libre -lt 8) { Falla 'Hay menos de 8 GB libres: libera espacio antes de continuar.' }

Titulo "Creando el snapshot '$Nombre'"
$desc = "Servicios integrados de la Tarea 5.3 funcionando (DHCP, DNS, HTTPS, MariaDB, FTPS/SFTP, RAID). Creado el $(Get-Date -Format 'yyyy-MM-dd HH:mm')."
$reloj = [System.Diagnostics.Stopwatch]::StartNew()
if ($estado -eq 'running') {
    & $VBOX snapshot $SERVIDOR take $Nombre --description $desc --live
} else {
    & $VBOX snapshot $SERVIDOR take $Nombre --description $desc
}
$reloj.Stop()
if ($LASTEXITCODE -ne 0) { Falla 'VirtualBox no pudo crear el snapshot.' }
Ok ("Snapshot creado en {0:N1} segundos" -f $reloj.Elapsed.TotalSeconds)

Titulo 'Snapshots actuales'
& $VBOX snapshot $SERVIDOR list 2>&1 | ForEach-Object { Write-Host "  $_" }

$carpeta = Split-Path (Valor-VM $SERVIDOR 'CfgFile')
$sn = Join-Path $carpeta 'Snapshots'
if (Test-Path $sn) {
    $mb = [math]::Round(((Get-ChildItem $sn -Recurse -File | Measure-Object Length -Sum).Sum) / 1MB, 0)
    Info "La carpeta de snapshots ocupa ahora $mb MB"
}
