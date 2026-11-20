# =============================================================================
#  03_aislar_backend.ps1 - Aislamiento total de db01
#
#  db01 usa NAT solo porque Vagrant lo necesita para administrarla. Un huesped en
#  NAT puede salir a internet y alcanzar lo que el anfitrion alcanza. Para dejar
#  db01 SOLO en la red interna, este script "desconecta el cable" de su NAT.
#
#    -Modo Aislar      desconecta el NAT de db01
#    -Modo Restaurar   lo vuelve a conectar
#    -Modo Estado      solo muestra las pruebas (por omision)
#
#  Mientras db01 esta aislada, "vagrant ssh db01" no funciona (usa el NAT).
#  Ejemplo:  powershell -ExecutionPolicy Bypass -File .\scripts\03_aislar_backend.ps1 -Modo Aislar
# =============================================================================
param([ValidateSet('Aislar', 'Restaurar', 'Estado')][string]$Modo = 'Estado')

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base

if ($Modo -eq 'Aislar') {
    Titulo 'Desconectando el adaptador NAT de db01'
    & $VBOX controlvm $VM_DB setlinkstate1 off
    if ($LASTEXITCODE -eq 0) { Ok 'NAT de db01 desconectado' } else { Falla 'No se pudo desconectar (db01 esta encendida?)' }
    Start-Sleep -Seconds 2
}
if ($Modo -eq 'Restaurar') {
    Titulo 'Reconectando el adaptador NAT de db01'
    & $VBOX controlvm $VM_DB setlinkstate1 on
    if ($LASTEXITCODE -eq 0) { Ok 'NAT de db01 reconectado' } else { Falla 'No se pudo reconectar' }
    # La VM tarda unos segundos en recuperar su ruta de red
    Info 'Esperando a que db01 recupere la red...'
    Start-Sleep -Seconds 12
}

Titulo 'Prueba 1: db01 hacia internet (desde dentro de db01, por Guest Additions)'
$r = & $VBOX guestcontrol $VM_DB run --username vagrant --password vagrant --wait-stdout --wait-stderr -- /usr/bin/ping -c 2 -W 2 8.8.8.8 2>&1
$r | ForEach-Object { Write-Host "   $_" }
if (($r -join ' ') -match ', 0 received|100% packet loss|unreachable') {
    Ok 'db01 NO tiene salida a internet (aislada)'
} else {
    Info 'db01 SI tiene salida a internet (por NAT)'
}

Titulo 'Prueba 2: web01 hacia db01 por la red interna'
$p = En-VM 'web01' 'ping -c 2 -W 2 10.10.10.20'
$p | ForEach-Object { Write-Host "   $_" }
if ($LASTEXITCODE -eq 0) { Ok 'web01 SI alcanza a db01 (la red interna sigue funcionando)' } else { Aviso 'web01 no alcanza a db01' }

Titulo 'Prueba 3: consulta a la base de datos desde web01'
En-VM 'web01' 'probar_db'
