# =============================================================================
#  crear_vms.ps1 - Infraestructura como codigo: crea las 2 VMs del ambiente
#  integrado con el mismo hardware que el laboratorio de la Unidad 4.
#
#    <prefijo>-srv01   servidor: 2 vCPU, NAT + red interna red-u4, 6 discos
#                      (sda 25 GB, sdb 2 GB, sdc 4 GB, sdd/sde/sdf 1 GB cada uno)
#    <prefijo>-cli01   cliente:  1 adaptador en la red interna red-u4
#
#  Los discos son dinamicos (thin provisioning). El sistema operativo se instala
#  despues (ver docs\manual_reconstruccion.md).
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\iac\crear_vms.ps1
#  Opciones:
#    -Prefijo u5r           nombre base de las VMs (por omision u5r)
#    -Iso "C:\ruta\xubuntu-25.10.iso"   monta la ISO en las dos VMs
#    -RamServidor 3072  -RamCliente 2048    memoria en MB
#    -MacCliente 080027818D77   MAC del cliente (la que reserva el DHCP)
#    -Eliminar              borra las VMs del prefijo y sus discos
# =============================================================================
param(
    [string]$Prefijo = 'u5r',
    [string]$Iso = '',
    [int]$RamServidor = 3072,
    [int]$RamCliente = 2048,
    [string]$MacCliente = '080027818D77',
    [switch]$Eliminar
)

$VBOX = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
function Titulo($t) { Write-Host ""; Write-Host "==== $t ====" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "[OK] $t" -ForegroundColor Green }
function Info($t)   { Write-Host "[..] $t" }
function Aviso($t)  { Write-Host "[AVISO] $t" -ForegroundColor Yellow }
function Falla($t)  { Write-Host "[ERROR] $t" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $VBOX)) { Falla "No se encontro VBoxManage en $VBOX" }
$SRV = "$Prefijo-srv01"
$CLI = "$Prefijo-cli01"

function Existe($vm) { return [bool]((& $VBOX list vms) | Select-String ('^"' + [regex]::Escape($vm) + '"')) }
function Ejecuta {
    & $VBOX @args
    if ($LASTEXITCODE -ne 0) { Falla "Fallo: VBoxManage $($args -join ' ')" }
}

# ---------------------------------------------------------------- eliminar
if ($Eliminar) {
    Titulo "Eliminando $SRV y $CLI"
    foreach ($vm in @($SRV, $CLI)) {
        if (Existe $vm) {
            if ((& $VBOX showvminfo $vm --machinereadable | Select-String '^VMState="running"')) { & $VBOX controlvm $vm poweroff | Out-Null; Start-Sleep 3 }
            & $VBOX unregistervm $vm --delete 2>&1 | Out-Null
            Ok "$vm eliminada con sus discos"
        } else { Info "$vm no existe" }
    }
    exit 0
}

# ---------------------------------------------------------------- crear
foreach ($vm in @($SRV, $CLI)) { if (Existe $vm) { Falla "Ya existe la VM '$vm'. Usa otro -Prefijo o -Eliminar." } }
if ($Iso -and -not (Test-Path $Iso)) { Falla "No se encontro la ISO: $Iso" }

# Carpeta donde VirtualBox guarda las VMs
$carpeta = ((& $VBOX list systemproperties) | Select-String '^Default machine folder:\s+(.*)$').Matches[0].Groups[1].Value.Trim()
Info "Carpeta de VMs: $carpeta"

function Nueva-VM($nombre, $ram) {
    Ejecuta createvm --name $nombre --ostype Ubuntu_64 --register
    Ejecuta modifyvm $nombre --memory $ram --cpus 2 --vram 16 --graphicscontroller vmsvga --ioapic on --boot1 dvd --boot2 disk --boot3 none --boot4 none
    Ejecuta storagectl $nombre --name 'SATA' --add sata --controller IntelAhci --portcount 8
    if ($Iso) {
        Ejecuta storagectl $nombre --name 'IDE' --add ide
        Ejecuta storageattach $nombre --storagectl 'IDE' --port 0 --device 0 --type dvddrive --medium $Iso
    }
}
function Agrega-Disco($nombre, $puerto, $mb, $archivo) {
    $ruta = Join-Path (Join-Path $carpeta $nombre) $archivo
    Ejecuta createmedium disk --filename $ruta --size $mb --format VDI
    Ejecuta storageattach $nombre --storagectl 'SATA' --port $puerto --device 0 --type hdd --medium $ruta
}

Titulo "Servidor: $SRV"
Nueva-VM $SRV $RamServidor
Ejecuta modifyvm $SRV --nic1 nat --nictype1 82540EM --nic2 intnet --intnet2 'red-u4' --nictype2 82540EM
$discos = @(@(0, 25600, 'sistema.vdi'), @(1, 2048, 'datos.vdi'), @(2, 4096, 'respaldos.vdi'),
            @(3, 1024, 'raid1.vdi'), @(4, 1024, 'raid2.vdi'), @(5, 1024, 'raid3.vdi'))
foreach ($d in $discos) { Agrega-Disco $SRV $d[0] $d[1] $d[2] }
Ok "$SRV creada: $RamServidor MB, 2 vCPU, 6 discos dinamicos, NAT + red-u4"

Titulo "Cliente: $CLI"
Nueva-VM $CLI $RamCliente
Ejecuta modifyvm $CLI --nic1 intnet --intnet1 'red-u4' --nictype1 82540EM --macaddress1 $MacCliente
Agrega-Disco $CLI 0 25600 'sistema.vdi'
Ok "$CLI creada: $RamCliente MB, 2 vCPU, red-u4, MAC $MacCliente"
if ($MacCliente -eq '080027818D77') {
    Aviso 'Esa MAC es la del Cliente-U4 original. No enciendas los dos clientes a la vez en red-u4.'
}

Titulo 'Resumen'
foreach ($vm in @($SRV, $CLI)) {
    $i = & $VBOX showvminfo $vm --machinereadable
    $mem = ($i | Select-String '^memory=(\d+)').Matches[0].Groups[1].Value
    $n = @($i | Select-String '^"(SATA|IDE) Controller-\d-\d"|^"SATA-\d-\d"="[^n]').Count
    "{0,-14} RAM {1} MB   discos/medios: {2}" -f $vm, $mem, $n
}
if (-not $Iso) { Info 'No se monto ninguna ISO: agregala en Configuracion > Almacenamiento o vuelve a crear con -Iso.' }
Info 'Siguiente paso: instalar Xubuntu 25.10 en las dos VMs (docs\manual_reconstruccion.md).'
