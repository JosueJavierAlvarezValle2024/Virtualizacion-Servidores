# =============================================================================
#  comun.ps1 - Variables y funciones compartidas por los scripts de la Tarea 5.2
#  (Solo ASCII: PowerShell 5.1 lee mal los acentos en archivos sin BOM)
# =============================================================================

$TAREA   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$EVID    = Join-Path $TAREA 'evidencias'
$VBOX    = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$VM_WEB  = 'u5-web01'
$VM_DB   = 'u5-db01'
$IP_WEB_HOSTONLY = '192.168.56.10'
$IP_WEB_INTERNA  = '10.10.10.10'
$IP_DB_INTERNA   = '10.10.10.20'

function Titulo($t) { Write-Host ""; Write-Host "==== $t ====" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "[OK] $t" -ForegroundColor Green }
function Info($t)   { Write-Host "[..] $t" }
function Aviso($t)  { Write-Host "[AVISO] $t" -ForegroundColor Yellow }
function Falla($t)  { Write-Host "[ERROR] $t" -ForegroundColor Red; exit 1 }

# Ejecuta un comando DENTRO de una VM con "vagrant ssh". Devuelve la salida y deja
# el codigo de salida en $LASTEXITCODE.
function En-VM($vm, $comando) {
    Push-Location $TAREA
    try { $salida = & vagrant ssh $vm -c $comando 2>$null } finally { Pop-Location }
    return $salida
}

# Lista los discos virtuales de una VM con su capacidad y lo que ocupan de verdad
function Get-Discos($vm) {
    $info = & $VBOX showvminfo $vm --machinereadable
    foreach ($l in $info) {
        if ($l -match '^"[^"]*-\d+-\d+"="(.*\.(vdi|vmdk|vhd))"$') {
            $ruta = $Matches[1] -replace '\\\\', '\'
            $cap = 0
            $m = & $VBOX showmediuminfo disk "$ruta" | Select-String '^Capacity:\s+(\d+)'
            if ($m) { $cap = [int]$m.Matches[0].Groups[1].Value }
            $ocupa = [math]::Round((Get-Item $ruta).Length / 1MB, 1)
            [pscustomobject]@{ VM = $vm; Disco = (Split-Path $ruta -Leaf); CapacidadMB = $cap; OcupaMB = $ocupa; Ruta = $ruta }
        }
    }
}

function Requisitos-Base {
    if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
        Falla 'Vagrant no esta instalado. Instalalo con: winget install Hashicorp.Vagrant (y abre una terminal nueva)'
    }
    if (-not (Test-Path $VBOX)) { Falla "No se encontro VBoxManage en $VBOX" }
}
