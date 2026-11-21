# =============================================================================
#  00_estado.ps1 - Estado de la infraestructura virtualizada (solo lee)
#  Muestra las VMs del ambiente integrado, sus redes, sus snapshots y la RAM.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\00_estado.ps1
#  Opcional: -VMServidor "otra VM" -VMCliente "otra VM"
# =============================================================================
param([string]$VMServidor = '', [string]$VMCliente = '')

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base
# (PowerShell no distingue mayusculas: por eso los parametros no se llaman igual que las variables)
if ($VMServidor) { $SERVIDOR = $VMServidor }
if ($VMCliente)  { $CLIENTE  = $VMCliente }

Titulo 'Maquinas virtuales del ambiente integrado'
foreach ($par in @(@($SERVIDOR, 'servidor'), @($CLIENTE, 'cliente'))) {
    $vm = $par[0]
    if (-not (Existe-VM $vm)) { Aviso "No existe la VM '$vm' ($($par[1]))"; continue }
    $estado = Estado-VM $vm
    $mem = Valor-VM $vm 'memory'
    $cpu = Valor-VM $vm 'cpus'
    $ip = if ($estado -eq 'running') { IP-Invitado $vm } else { '' }
    '{0,-12} {1,-9} estado: {2,-9} RAM {3,5} MB   vCPU {4}   IP del invitado: {5}' -f $vm, $par[1], $estado, $mem, $cpu, $(if ($ip) { $ip } else { '-' })
}

Titulo 'Redes de cada VM'
foreach ($vm in @($SERVIDOR, $CLIENTE)) {
    if (-not (Existe-VM $vm)) { continue }
    Write-Host "  $vm"
    foreach ($n in 1..4) {
        $modo = Valor-VM $vm "nic$n"
        if (-not $modo -or $modo -eq 'none') { continue }
        $extra = switch ($modo) {
            'intnet'  { 'red interna: ' + (Valor-VM $vm "intnet$n") }
            'bridged' { 'adaptador: ' + (Valor-VM $vm "bridgeadapter$n") }
            default   { '' }
        }
        '    Adaptador {0}: {1,-9} MAC {2}  {3}' -f $n, $modo, (Valor-VM $vm "macaddress$n"), $extra
    }
}

Titulo "Snapshots del servidor ($SERVIDOR)"
$snaps = Snapshots-VM $SERVIDOR
if ($snaps.Count -eq 0) { Info 'Sin snapshots' }
else {
    & $VBOX snapshot $SERVIDOR list 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($snaps -contains $SNAP_OK) { Ok "Existe el snapshot de la tarea: '$SNAP_OK'" } else { Aviso "Todavia no existe el snapshot '$SNAP_OK' (se crea con 01_crear_snapshot.ps1)" }
}

Titulo 'Recursos del anfitrion'
$os = Get-CimInstance Win32_OperatingSystem
'  RAM libre de Windows: {0:N0} MB de {1:N0} MB' -f ($os.FreePhysicalMemory / 1KB), ($os.TotalVisibleMemorySize / 1KB)
$libre = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
"  Espacio libre en C: $libre GB"
$corriendo = & $VBOX list runningvms
"  VMs encendidas: $(@($corriendo).Count)"
$corriendo | ForEach-Object { Write-Host "    $_" }
