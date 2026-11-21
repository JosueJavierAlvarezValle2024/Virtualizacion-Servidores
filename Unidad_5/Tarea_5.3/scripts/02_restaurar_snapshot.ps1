# =============================================================================
#  02_restaurar_snapshot.ps1 - Restaura el servidor a un snapshot (contingencia)
#
#  Pasos:  1) apaga la VM de golpe (como ante un fallo grave)
#          2) restaura el snapshot (disco + memoria)
#          3) enciende la VM: vuelve a quedar ENCENDIDA y con los servicios
#             funcionando, en el estado en que se tomo el snapshot
#          4) espera a que el invitado reporte su IP y mide el tiempo total
#
#  CUIDADO: todo lo hecho en el servidor DESPUES del snapshot se pierde.
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\02_restaurar_snapshot.ps1
#  Opcional: -Nombre "otro snapshot"   -VM "otra VM"   -Si (no pregunta)
#            -NoEncender (restaura pero deja la VM apagada)
# =============================================================================
param([string]$Nombre = '', [string]$VM = '', [switch]$Si, [switch]$NoEncender)

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base
if ($VM) { $SERVIDOR = $VM }
if (-not $Nombre) { $Nombre = $SNAP_OK }

if (-not (Existe-VM $SERVIDOR)) { Falla "No existe la VM '$SERVIDOR'" }
if (-not ((Snapshots-VM $SERVIDOR) -contains $Nombre)) {
    Falla "No existe el snapshot '$Nombre' en $SERVIDOR. Crealo antes con 01_crear_snapshot.ps1"
}

Titulo 'Contingencia: restauracion de snapshot'
Info "Servidor:  $SERVIDOR"
Info "Snapshot:  $Nombre"
Aviso 'Se perdera todo lo hecho en el servidor despues de ese snapshot.'
if (-not $Si) {
    $r = Read-Host 'Escribe SI para continuar'
    if ($r -ne 'SI') { Falla 'Cancelado.' }
}

$reloj = [System.Diagnostics.Stopwatch]::StartNew()

Titulo '1. Apagando el servidor'
if ((Estado-VM $SERVIDOR) -in @('running', 'paused', 'stuck')) {
    & $VBOX controlvm $SERVIDOR poweroff 2>&1 | Out-Null
    for ($i = 0; $i -lt 30; $i++) {
        if ((Estado-VM $SERVIDOR) -ne 'running') { break }
        Start-Sleep -Seconds 1
    }
}
Info "Estado: $(Estado-VM $SERVIDOR)"

Titulo '2. Restaurando el snapshot'
& $VBOX snapshot $SERVIDOR restore $Nombre
if ($LASTEXITCODE -ne 0) { Falla 'VirtualBox no pudo restaurar el snapshot.' }
Ok 'Snapshot restaurado'

if ($NoEncender) {
    $reloj.Stop()
    Ok ("Restauracion terminada en {0:N0} segundos (la VM queda apagada por -NoEncender)" -f $reloj.Elapsed.TotalSeconds)
    exit 0
}

Titulo '3. Encendiendo el servidor'
& $VBOX startvm $SERVIDOR --type gui | Out-Null
if ($LASTEXITCODE -ne 0) { Falla 'No se pudo encender la VM.' }

Titulo '4. Esperando al invitado'
$ip = ''
for ($i = 0; $i -lt 90; $i++) {
    if ((Estado-VM $SERVIDOR) -eq 'running') {
        $ip = IP-Invitado $SERVIDOR
        if ($ip -match [regex]::Escape($IP_SERVIDOR)) { break }
    }
    Start-Sleep -Seconds 2
}
$reloj.Stop()
Info "Estado: $(Estado-VM $SERVIDOR)"
if ($ip -match [regex]::Escape($IP_SERVIDOR)) { Ok "El invitado responde. IPs: $ip" } else { Aviso "El invitado aun no reporta la IP $IP_SERVIDOR (puede tardar un poco mas). IPs vistas: $ip" }
Ok ("Tiempo total de recuperacion: {0:N0} segundos" -f $reloj.Elapsed.TotalSeconds)
Info 'Comprueba los servicios desde el cliente (prueba_integral.sh).'
