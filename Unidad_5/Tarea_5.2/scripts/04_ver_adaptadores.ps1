# =============================================================================
#  04_ver_adaptadores.ps1 - Muestra los adaptadores de red de las dos VMs
#  tal como los ve el hipervisor (VirtualBox): modo, red, MAC y reenvio de puertos.
#  No modifica nada.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\04_ver_adaptadores.ps1
# =============================================================================
. (Join-Path $PSScriptRoot 'lib\comun.ps1')
if (-not (Test-Path $VBOX)) { Falla "No se encontro VBoxManage en $VBOX" }

$nombresModo = @{
    'nat'      = 'NAT'
    'hostonly' = 'Solo anfitrion (Host-Only)'
    'intnet'   = 'Red interna'
    'bridged'  = 'Puente (Bridged)'
}

function Valor($info, $clave) {
    $m = $info | Select-String ('^' + [regex]::Escape($clave) + '="(.*)"$')
    if ($m) { return $m.Matches[0].Groups[1].Value }
    return ''
}

foreach ($vm in @($VM_WEB, $VM_DB)) {
    $info = & $VBOX showvminfo $vm --machinereadable
    $estado = Valor $info 'VMState'
    Titulo "$vm  (estado: $estado)"
    foreach ($n in 1..4) {
        $modo = Valor $info "nic$n"
        if (-not $modo -or $modo -eq 'none') {
            '  Adaptador {0}: deshabilitado' -f $n
            continue
        }
        $mac = Valor $info "macaddress$n"
        $cable = Valor $info "cableconnected$n"
        $detalle = switch ($modo) {
            'hostonly' { 'adaptador: ' + (Valor $info "hostonlyadapter$n") }
            'intnet'   { 'red: ' + (Valor $info "intnet$n") }
            'bridged'  { 'adaptador fisico: ' + (Valor $info "bridgeadapter$n") }
            default    { '' }
        }
        '  Adaptador {0}: {1,-28} MAC {2}  cable {3}' -f $n, $nombresModo[$modo], $mac, $cable
        if ($detalle) { '                 ' + $detalle }
        if ($modo -eq 'nat') {
            foreach ($l in ($info | Select-String '^Forwarding\(\d+\)="(.*)"$')) {
                $p = $l.Matches[0].Groups[1].Value -split ','
                '                 reenvio de puertos: {0} -> anfitrion {1}:{2}  =>  VM puerto {3}' -f $p[0], $p[2], $p[3], $p[5]
            }
        }
    }
}
