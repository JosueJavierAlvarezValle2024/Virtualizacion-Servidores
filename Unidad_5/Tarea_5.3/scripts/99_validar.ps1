# =============================================================================
#  99_validar.ps1 - Pruebas de la infraestructura virtualizada (lado Windows)
#  Comprueba las VMs, su red, sus discos y el snapshot de la tarea.
#  Los servicios por dentro se validan con scripts\servidor\01_validar_servicios.sh
#  y scripts\cliente\prueba_integral.sh.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1
#  Guarda la salida en .\evidencias\validacion_<fecha>.txt
# =============================================================================
. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base
New-Item -ItemType Directory -Force $EVID | Out-Null

$log = New-Object System.Collections.Generic.List[string]
$script:pasan = 0
$script:fallan = 0
function Linea($t) { Write-Host $t; $log.Add([string]$t) }
function Seccion($t) { Linea ''; Linea "==== $t ====" }
function Prueba($desc, [bool]$ok) {
    if ($ok) { $script:pasan++;  Linea "[PASA]  $desc" }
    else     { $script:fallan++; Linea "[FALLA] $desc" }
}

Linea "Validacion Tarea 5.3 (infraestructura) - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

Seccion '1. Hipervisor'
$ver = (& $VBOX --version)
Linea "         VirtualBox $ver"
Prueba 'VirtualBox 7.2 o superior' ($ver -match '^7\.(2|[3-9])|^[89]\.')

Seccion '2. Maquinas virtuales'
Prueba "Existe el servidor ($SERVIDOR)" (Existe-VM $SERVIDOR)
Prueba "Existe el cliente ($CLIENTE)"   (Existe-VM $CLIENTE)
foreach ($vm in @($SERVIDOR, $CLIENTE)) {
    if (-not (Existe-VM $vm)) { continue }
    Linea ("         {0}: {1} MB de RAM, {2} vCPU, estado {3}" -f $vm, (Valor-VM $vm 'memory'), (Valor-VM $vm 'cpus'), (Estado-VM $vm))
}

Seccion '3. Red virtualizada'
$srvRed = $false; $cliRed = $false; $srvNat = $false
foreach ($n in 1..4) {
    if ((Valor-VM $SERVIDOR "nic$n") -eq 'intnet' -and (Valor-VM $SERVIDOR "intnet$n") -eq 'red-u4') { $srvRed = $true }
    if ((Valor-VM $SERVIDOR "nic$n") -eq 'nat') { $srvNat = $true }
    if ((Valor-VM $CLIENTE  "nic$n") -eq 'intnet' -and (Valor-VM $CLIENTE  "intnet$n") -eq 'red-u4') { $cliRed = $true }
}
Prueba 'El servidor esta en la red interna red-u4' $srvRed
Prueba 'El servidor tiene un adaptador NAT (salida a internet)' $srvNat
Prueba 'El cliente esta en la red interna red-u4' $cliRed
Prueba 'El cliente NO tiene adaptador NAT (solo sale por el servidor)' (-not ((1..4 | Where-Object { (Valor-VM $CLIENTE "nic$_") -eq 'nat' }).Count))
$macCli = Valor-VM $CLIENTE 'macaddress1'
Prueba "El cliente usa la MAC reservada por el DHCP (080027818D77): $macCli" ($macCli -eq '080027818D77')

Seccion '4. Almacenamiento del servidor'
$discos = @(& $VBOX showvminfo $SERVIDOR --machinereadable | Select-String '^"[^"]*-\d+-\d+"="[^"]+\.(vdi|vmdk|vhd)"$')
Linea "         Discos virtuales conectados: $($discos.Count)"
Prueba 'El servidor tiene al menos 6 discos (sistema, datos, respaldos y 3 del RAID)' ($discos.Count -ge 6)

Seccion '5. Snapshots (contingencia)'
$snaps = Snapshots-VM $SERVIDOR
Linea "         Snapshots del servidor: $($snaps.Count)"
$snaps | ForEach-Object { Linea "           - $_" }
$tiene = $snaps -contains $SNAP_OK
Prueba "Existe el snapshot de la tarea: '$SNAP_OK'" $tiene
if ($tiene) {
    $est = (& $VBOX snapshot $SERVIDOR showvminfo $SNAP_OK --machinereadable 2>$null | Select-String '^VMState="?([^"]*)"?$')
    $estado = if ($est) { $est.Matches[0].Groups[1].Value } else { '?' }
    Linea "         Estado guardado en el snapshot: $estado"
    Prueba 'El snapshot es en caliente (guarda la memoria: estado saved)' ($estado -eq 'saved')
}

Seccion '6. Infraestructura como codigo'
$rutas = @('iac\crear_vms.ps1', 'iac\reconstruir_servidor.sh', 'servidor\01_validar_servicios.sh', 'servidor\02_fallo_controlado.sh', 'cliente\prueba_integral.sh', '01_crear_snapshot.ps1', '02_restaurar_snapshot.ps1')
foreach ($r in $rutas) { Prueba "Existe scripts\$r" (Test-Path (Join-Path $PSScriptRoot $r)) }
Prueba 'Existe el manual de reconstruccion (docs\manual_reconstruccion.md)' (Test-Path (Join-Path $TAREA 'docs\manual_reconstruccion.md'))

Linea ''
Linea "Pruebas que pasaron:  $script:pasan"
Linea "Pruebas que fallaron: $script:fallan"
$archivo = Join-Path $EVID ("validacion_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmm'))
$log | Out-File -FilePath $archivo -Encoding utf8
Write-Host "Evidencia guardada en: $archivo"
