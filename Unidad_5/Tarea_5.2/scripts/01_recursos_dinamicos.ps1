# =============================================================================
#  01_recursos_dinamicos.ps1 - Asignacion de vCPU y RAM
#
#  Sin parametros: solo muestra lo que tiene asignada cada VM.
#
#  EN CALIENTE (la VM sigue encendida):
#    -Limite 50      limita el uso de CPU al 50 % de lo asignado (1 a 100)
#    -Restaurar      quita el limite de CPU (100 %)
#
#  CON REINICIO (cambia el tamano de la VM):
#    -Cpus 2 -Memoria 1536     nuevo numero de vCPU y de MB de RAM
#
#  -VM web01 (por omision) o -VM db01
#  Ejemplo:  powershell -ExecutionPolicy Bypass -File .\scripts\01_recursos_dinamicos.ps1 -Limite 50
#
#  NOTA: aqui NO se usa el "globo de memoria" (VBoxManage controlvm ...
#  guestmemoryballoon). En esta laptop VirtualBox corre sobre Hyper-V (modo NEM) y,
#  al inflar el globo, la memoria de la VM quedo danada (SSH con bytes en cero y
#  VM colgada). Por eso la memoria se ajusta con reinicio.
# =============================================================================
param(
    [ValidateSet('web01', 'db01')][string]$VM = 'web01',
    [int]$Limite = 0,
    [switch]$Restaurar,
    [int]$Cpus = 0,
    [int]$Memoria = 0
)

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base
$nombre = "u5-$VM"

function Mostrar-Estado {
    Titulo 'Recursos asignados (vista del hipervisor)'
    foreach ($v in @($VM_WEB, $VM_DB)) {
        $i = & $VBOX showvminfo $v --machinereadable
        $cpus = ($i | Select-String '^cpus=(\d+)').Matches[0].Groups[1].Value
        $mem  = ($i | Select-String '^memory=(\d+)').Matches[0].Groups[1].Value
        $cap  = ($i | Select-String '^cpuexecutioncap=(\d+)').Matches[0].Groups[1].Value
        '{0,-10} vCPU {1}   RAM {2,5} MB   limite CPU {3,3} %' -f $v, $cpus, $mem, $cap
    }
}

Mostrar-Estado

# ---- En caliente: limite de CPU ----
if ($Restaurar) { $Limite = 100 }

if ($Limite -gt 0) {
    Titulo "Limite de CPU de $VM al $Limite %"
    & $VBOX controlvm $nombre cpuexecutioncap $Limite
    if ($LASTEXITCODE -eq 0) { Ok "Limite aplicado sin reiniciar $VM" } else { Aviso 'No se pudo aplicar (la VM esta encendida?)' }
}

# ---- Con reinicio: cambia el Vagrantfile por variables de entorno ----
if ($Cpus -gt 0 -or $Memoria -gt 0) {
    Titulo "Cambiando el tamano de $VM (se reinicia)"
    $pref = if ($VM -eq 'web01') { 'WEB' } else { 'DB' }
    if ($Cpus -gt 0)    { Set-Item "env:${pref}_CPUS" $Cpus }
    if ($Memoria -gt 0) { Set-Item "env:${pref}_MEM" $Memoria }
    Push-Location $TAREA
    try { & vagrant reload $VM } finally { Pop-Location }
    Info "Vista desde dentro de $VM :"
    En-VM $VM 'echo vCPU: $(nproc); free -m | sed -n 2p'
    Info 'Nota: para conservar el cambio en los siguientes "vagrant up", define las mismas variables o edita el Vagrantfile.'
}

if ($Limite -gt 0 -or $Cpus -gt 0 -or $Memoria -gt 0) { Mostrar-Estado }
