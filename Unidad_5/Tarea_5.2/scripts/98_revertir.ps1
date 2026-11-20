# =============================================================================
#  98_revertir.ps1 - Borra el entorno de la Tarea 5.2 (las 2 VMs y sus discos)
#  No toca las demas VMs de VirtualBox ni los archivos de .\compartido
#  La imagen descargada (box) se conserva para no bajarla otra vez.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\98_revertir.ps1 -Si
# =============================================================================
param([switch]$Si)

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base

if (-not $Si) {
    Aviso 'Esto BORRA las VMs u5-web01 y u5-db01 con sus discos.'
    Falla 'Vuelve a ejecutar con -Si para confirmar.'
}

Titulo 'Destruyendo las maquinas virtuales'
Push-Location $TAREA
try { & vagrant destroy -f } finally { Pop-Location }

# Si quedo algun disco huerfano de estas VMs, se elimina
Titulo 'Buscando discos sobrantes'
$lista = & $VBOX list hdds
$uuid = $null
foreach ($l in $lista) {
    if ($l -match '^UUID:\s+(\S+)') { $uuid = $Matches[1] }
    if ($l -match '^Location:\s+.*u5-(web01|db01)') {
        Info "Eliminando disco sobrante $uuid"
        & $VBOX closemedium disk $uuid --delete 2>$null
    }
}

if (Test-Path (Join-Path $TAREA '.vagrant')) { Remove-Item (Join-Path $TAREA '.vagrant') -Recurse -Force }
Ok 'Entorno borrado. Para crearlo de nuevo: .\scripts\00_ejecutar_todo.ps1'
Info 'Para borrar tambien la imagen descargada: vagrant box remove bento/ubuntu-24.04'
