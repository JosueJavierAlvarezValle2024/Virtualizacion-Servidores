# =============================================================================
#  02_disco_fino.ps1 - Demuestra el aprovisionamiento fino (thin provisioning)
#
#  Sin parametros: muestra la capacidad de cada disco y lo que ocupa de verdad.
#    -Llenar 500    escribe un archivo de 500 MB dentro de web01 (en /datos)
#    -Borrar        borra ese archivo
#
#  Ejemplo:  powershell -ExecutionPolicy Bypass -File .\scripts\02_disco_fino.ps1 -Llenar 500
# =============================================================================
param([int]$Llenar = 0, [switch]$Borrar)

. (Join-Path $PSScriptRoot 'lib\comun.ps1')
Requisitos-Base

function Mostrar-Discos {
    Titulo 'Discos virtuales: capacidad contra espacio real en Windows'
    $discos = @(Get-Discos $VM_WEB) + @(Get-Discos $VM_DB)
    $discos | Format-Table VM, Disco, `
        @{ n = 'Capacidad (MB)'; e = { $_.CapacidadMB } }, `
        @{ n = 'Ocupa en Windows (MB)'; e = { $_.OcupaMB } } -AutoSize | Out-String | Write-Host
}

Mostrar-Discos

if ($Llenar -gt 0) {
    Titulo "Escribiendo $Llenar MB en web01 (/datos/relleno.bin)"
    # Se escriben datos aleatorios: VirtualBox no reserva espacio para bloques de ceros
    $null = En-VM 'web01' "dd if=/dev/urandom of=/datos/relleno.bin bs=1M count=$Llenar status=none; sync"
    En-VM 'web01' 'df -h /datos'
    Mostrar-Discos
    Info 'El disco "datos_web" crecio en Windows solo lo que se escribio; su capacidad sigue en 20 GB.'
}

if ($Borrar) {
    Titulo 'Borrando /datos/relleno.bin'
    $null = En-VM 'web01' 'rm -f /datos/relleno.bin; sync'
    En-VM 'web01' 'df -h /datos'
    Mostrar-Discos
    Info 'Un disco dinamico no se encoge solo al borrar archivos: hace falta compactarlo (VBoxManage modifymedium --compact).'
}
