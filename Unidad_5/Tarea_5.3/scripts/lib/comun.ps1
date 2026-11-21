# =============================================================================
#  comun.ps1 - Variables y funciones compartidas por los scripts de Windows (Tarea 5.3)
#  (Solo ASCII: PowerShell 5.1 lee mal los acentos en archivos sin BOM)
# =============================================================================

$TAREA     = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EVID      = Join-Path $TAREA 'evidencias'
$VBOX      = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'

# VMs del ambiente integrado (las de la Unidad 4)
$SERVIDOR  = 'Xubuntuu'
$CLIENTE   = 'Cliente-U4'
$SNAP_OK   = '5.3 Servicios integrados'
$IP_SERVIDOR = '192.168.50.10'

function Titulo($t) { Write-Host ""; Write-Host "==== $t ====" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "[OK] $t" -ForegroundColor Green }
function Info($t)   { Write-Host "[..] $t" }
function Aviso($t)  { Write-Host "[AVISO] $t" -ForegroundColor Yellow }
function Falla($t)  { Write-Host "[ERROR] $t" -ForegroundColor Red; exit 1 }

function Requisitos-Base {
    if (-not (Test-Path $VBOX)) { Falla "No se encontro VBoxManage en $VBOX" }
}

# Devuelve el valor de una clave de "showvminfo --machinereadable"
function Valor-VM($vm, $clave) {
    $m = & $VBOX showvminfo $vm --machinereadable 2>$null | Select-String ('^' + [regex]::Escape($clave) + '="?([^"]*)"?$')
    if ($m) { return $m.Matches[0].Groups[1].Value }
    return ''
}

function Estado-VM($vm) { return (Valor-VM $vm 'VMState') }

# Comprueba que la VM exista
function Existe-VM($vm) {
    $lista = & $VBOX list vms
    return [bool]($lista | Select-String ('^"' + [regex]::Escape($vm) + '"'))
}

# IPs que el invitado reporta por las Guest Additions (no necesita usuario ni clave).
# VirtualBox numera las interfaces desde 0. Devuelve las IPs separadas por coma.
function IP-Invitado($vm) {
    $ips = @()
    foreach ($n in 0..3) {
        $r = & $VBOX guestproperty get $vm "/VirtualBox/GuestInfo/Net/$n/V4/IP" 2>$null
        if ($r -match '^Value:\s*(\S+)') { $ips += $Matches[1] }
    }
    return ($ips -join ', ')
}

# Nombres de los snapshots de una VM
function Snapshots-VM($vm) {
    $r = & $VBOX snapshot $vm list --machinereadable 2>$null
    $nombres = @()
    foreach ($l in $r) { if ($l -match '^SnapshotName(?:-[\d-]+)?="(.*)"$') { $nombres += $Matches[1] } }
    return $nombres
}
