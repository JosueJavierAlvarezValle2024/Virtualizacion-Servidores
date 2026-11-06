# =============================================================================
# Tarea 5.1 - info_anfitrion.ps1  (se ejecuta en Windows, en el equipo anfitrion)
# Muestra el hardware del anfitrion, si hay un hipervisor tipo 1 (Hyper-V)
# activo debajo de Windows y como lo aprovecha VirtualBox (tipo 2).
# No modifica nada.
# Uso (PowerShell):  powershell -ExecutionPolicy Bypass -File .\info_anfitrion.ps1
# Guarda una copia en ..\evidencias\anfitrion.txt
# =============================================================================
$ErrorActionPreference = 'SilentlyContinue'
$evid = Join-Path $PSScriptRoot '..\evidencias'
New-Item -ItemType Directory -Force $evid | Out-Null
$salida = Join-Path $evid 'anfitrion.txt'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'

function Titulo($t) { "`n== $t ==" }
function Dato($k, $v) { '  {0,-34} {1}' -f $k, $v }

$reporte = & {
  "Equipo anfitrion - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

  Titulo '1. Hardware fisico'
  $cpu = Get-CimInstance Win32_Processor
  $cs  = Get-CimInstance Win32_ComputerSystem
  Dato 'Procesador:' $cpu.Name
  Dato 'Nucleos / hilos:' "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
  Dato 'RAM fisica:' ('{0:N1} GB' -f ($cs.TotalPhysicalMemory / 1GB))
  Dato 'Sistema operativo:' (Get-CimInstance Win32_OperatingSystem).Caption
  $c = Get-PSDrive C
  Dato 'Disco C: libre / usado:' ('{0:N0} GB / {1:N0} GB' -f ($c.Free / 1GB), ($c.Used / 1GB))

  Titulo '2. Hipervisor tipo 1 debajo de Windows'
  Dato 'Hipervisor presente:' $cs.HypervisorPresent
  $dg = Get-CimInstance Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
  $vbs = @{ 0 = 'desactivada'; 1 = 'habilitada sin ejecutarse'; 2 = 'en ejecucion' }[[int]$dg.VirtualizationBasedSecurityStatus]
  Dato 'Seguridad basada en virtualizacion:' $vbs
  if ($cs.HypervisorPresent) {
    '  -> Windows ya corre como "particion raiz" encima de Hyper-V (tipo 1).'
    '     Por eso VT-x queda ocupado y VirtualBox usa la API de Hyper-V (NEM).'
  }

  Titulo '3. VirtualBox (hipervisor tipo 2)'
  if (Test-Path $vbox) {
    Dato 'Version:' (& $vbox --version)
    '  Maquinas virtuales registradas:'
    foreach ($linea in (& $vbox list vms)) {
      $nombre = ($linea -split '"')[1]
      $info = & $vbox showvminfo $nombre --machinereadable
      $mem  = ($info | Select-String '^memory=').Line -replace 'memory=', ''
      $cpus = ($info | Select-String '^cpus=').Line -replace 'cpus=', ''
      $est  = ($info | Select-String '^VMState=').Line -replace 'VMState=|"', ''
      '    {0,-16} RAM {1,5} MB   vCPU {2}   estado {3}' -f $nombre, $mem, $cpus, $est
    }
    $log = Join-Path $env:USERPROFILE 'VirtualBox VMs\Xubuntuu\Logs\VBox.log'
    if (Test-Path $log) {
      '  Motor de ejecucion usado por la VM Xubuntuu (registro VBox.log):'
      Select-String -Path $log -Pattern 'HMR3Init: Attempting fall back to NEM|NEM: WHvCapabilityCodeHypervisorPresent' |
        Select-Object -First 2 | ForEach-Object { '    ' + $_.Line.Trim() }
    }
  } else {
    '  VirtualBox no esta instalado en la ruta por defecto.'
  }
}

$reporte | Tee-Object -FilePath $salida
"`nEvidencia guardada en: $salida"
