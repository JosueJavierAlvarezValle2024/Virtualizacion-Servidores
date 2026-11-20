# =============================================================================
#  00_ejecutar_todo.ps1 - Levanta todo el entorno de la Tarea 5.2
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\00_ejecutar_todo.ps1
#  Opcional: -Bridge "nombre del adaptador" para usar otra red fisica en el puente
# =============================================================================
param([string]$Bridge = '')

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base

Titulo 'Revision previa'
Info "Vagrant: $(vagrant --version)"
Info "VirtualBox: $(& $VBOX --version)"

# La laptop tiene 7.7 GB de RAM: las dos VMs nuevas usan 2 GB, hay que apagar las demas
$encendidas = & $VBOX list runningvms | Where-Object { $_ -notmatch 'u5-' }
if ($encendidas) {
    Aviso 'Hay otras VMs de VirtualBox encendidas (gastan RAM):'
    $encendidas | ForEach-Object { Write-Host "   $_" }
    Aviso 'Apagalas antes de seguir si la laptop va lenta.'
}

# Comprueba que existe el adaptador fisico para el modo puente
if ($Bridge) { $env:BRIDGE_IFACE = $Bridge }
$nombrePuente = if ($env:BRIDGE_IFACE) { $env:BRIDGE_IFACE } else { 'MediaTek MT7921 Wi-Fi 6 802.11ax PCIe Adapter' }
$disponibles = (& $VBOX list bridgedifs | Select-String '^Name:\s+(.*)$' | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() })
if ($disponibles -notcontains $nombrePuente) {
    Aviso "No existe el adaptador '$nombrePuente'. Adaptadores disponibles:"
    $disponibles | ForEach-Object { Write-Host "   $_" }
    Falla 'Vuelve a ejecutar con: -Bridge "nombre exacto"'
}
Ok "Adaptador para el puente: $nombrePuente"

Titulo 'Creando las maquinas virtuales (la primera vez descarga la imagen, ~600 MB)'
Push-Location $TAREA
try {
    & vagrant up
    if ($LASTEXITCODE -ne 0) { Falla 'vagrant up fallo. Revisa el mensaje de arriba.' }
} finally { Pop-Location }

Titulo 'Estado'
Push-Location $TAREA
try { & vagrant status } finally { Pop-Location }

Titulo 'Redes de web01'
En-VM 'web01' 'ver_redes'

Ok 'Entorno listo. Siguiente paso: powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1'
