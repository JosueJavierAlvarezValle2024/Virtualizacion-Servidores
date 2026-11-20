# =============================================================================
#  99_validar.ps1 - Pruebas automaticas de la Tarea 5.2
#  Comprueba cada modo de red, el aislamiento, los recursos y la carpeta compartida.
#  Guarda la salida en .\evidencias\validacion_<fecha>.txt
#
#  Uso:  powershell -ExecutionPolicy Bypass -File .\scripts\99_validar.ps1
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
function Muestra($lineas) { foreach ($l in @($lineas)) { if ($l) { Linea "         $l" } } }

# ---- Ayudas ----
function Responde-Ping($ip) { return [bool](Test-Connection -ComputerName $ip -Count 2 -Quiet -ErrorAction SilentlyContinue) }
function Puerto-Abierto($ip, $puerto) {
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $r = $c.BeginConnect($ip, $puerto, $null, $null)
        $ok = $r.AsyncWaitHandle.WaitOne(2500)
        return ($ok -and $c.Connected)
    } catch { return $false } finally { $c.Close() }
}
function Web-Contiene($url, $texto) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8
        return ($r.Content -match $texto)
    } catch { return $false }
}

Linea "Validacion Tarea 5.2 - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

# ---------------------------------------------------------------------------
Seccion '1. Estado de las maquinas'
$corriendo = & $VBOX list runningvms
Prueba 'u5-web01 esta encendida' (($corriendo -join ' ') -match 'u5-web01')
Prueba 'u5-db01 esta encendida'  (($corriendo -join ' ') -match 'u5-db01')

# ---------------------------------------------------------------------------
Seccion '2. Modo NAT (web01)'
# El puerto del anfitrion se pregunta a Vagrant (puede cambiar si estaba ocupado)
Push-Location $TAREA
$puertoNat = ((& vagrant port web01 --guest 80 2>$null) | Select-Object -First 1).ToString().Trim()
Pop-Location
Linea "         Puerto del anfitrion reenviado al 80 de web01: $puertoNat"
Prueba "Reenvio de puertos: http://127.0.0.1:$puertoNat responde web01" (Web-Contiene "http://127.0.0.1:$puertoNat" 'web01')
$null = En-VM 'web01' 'ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1'
Prueba 'web01 sale a internet (8.8.8.8) por NAT' ($LASTEXITCODE -eq 0)
$ruta = En-VM 'web01' 'ip route show default'
Muestra $ruta
Prueba 'La ruta por defecto de web01 es el NAT (10.0.2.2)' (($ruta -join ' ') -match '10\.0\.2\.2')

# ---------------------------------------------------------------------------
Seccion '3. Modo Solo anfitrion / Host-Only (192.168.56.0/24)'
Prueba "El anfitrion hace ping a web01 ($IP_WEB_HOSTONLY)" (Responde-Ping $IP_WEB_HOSTONLY)
Prueba "El anfitrion abre http://$IP_WEB_HOSTONLY" (Web-Contiene "http://$IP_WEB_HOSTONLY" 'web01')

# ---------------------------------------------------------------------------
Seccion '4. Red interna red-backend (10.10.10.0/24)'
$null = En-VM 'web01' "ping -c 2 -W 2 $IP_DB_INTERNA >/dev/null 2>&1"
Prueba "web01 hace ping a db01 ($IP_DB_INTERNA)" ($LASTEXITCODE -eq 0)
$db = En-VM 'web01' 'probar_db'
Muestra $db
Prueba 'web01 consulta la base de datos de db01 (MariaDB, puerto 3306)' (($db -join ' ') -match 'Teclado')
$tr = En-VM 'web01' "traceroute -n -m 3 $IP_DB_INTERNA"
Muestra $tr
Prueba 'Traza web01 -> db01: un solo salto (mismo segmento)' (($tr -join "`n") -match '(?m)^\s*1\s+10\.10\.10\.20')

# ---------------------------------------------------------------------------
Seccion '5. Aislamiento de db01'
Prueba "El anfitrion NO alcanza a db01 ($IP_DB_INTERNA): la red interna esta aislada" (-not (Responde-Ping $IP_DB_INTERNA))
Prueba "El puerto 3306 de db01 NO es accesible desde el anfitrion" (-not (Puerto-Abierto $IP_DB_INTERNA 3306))
Prueba "El puerto 3306 NO esta abierto en web01 (host-only)" (-not (Puerto-Abierto $IP_WEB_HOSTONLY 3306))
$ss = En-VM 'db01' 'ss -ltn'
Muestra ($ss | Select-String ':3306')
Prueba 'MariaDB en db01 escucha solo en 10.10.10.20 (no en 0.0.0.0)' ((($ss -join ' ') -match '10\.10\.10\.20:3306') -and -not (($ss -join ' ') -match '0\.0\.0\.0:3306'))
$ipsDb = En-VM 'db01' 'ip -br -4 addr'
Muestra $ipsDb
Prueba 'db01 no tiene adaptador host-only ni puente' (-not (($ipsDb -join ' ') -match '192\.168\.56\.|192\.168\.100\.'))

# ---------------------------------------------------------------------------
Seccion '6. Modo Puente / Bridged (red fisica)'
$wifi = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $wifi) {
    Prueba 'Se detecto la IP Wi-Fi del anfitrion' $false
} else {
    $pre = ($wifi.IPAddress -split '\.')[0..2] -join '.'
    Linea "         Anfitrion (Wi-Fi): $($wifi.IPAddress)   segmento: $pre.0/24"
    $dirs = En-VM 'web01' 'ip -4 -o addr show scope global'
    Muestra $dirs
    $ipPuente = $null
    foreach ($d in @($dirs)) { if ($d -match "inet ($([regex]::Escape($pre))\.\d+)/") { $ipPuente = $Matches[1] } }
    Prueba "web01 tiene una IP de la red fisica ($ipPuente)" ([bool]$ipPuente)
    if ($ipPuente) {
        $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
        $null = En-VM 'web01' "ping -c 2 -W 2 -I $ipPuente $gw >/dev/null 2>&1"
        Prueba "web01 alcanza el router de la red fisica ($gw) por el puente" ($LASTEXITCODE -eq 0)
        Prueba "El anfitrion hace ping a web01 por la red fisica ($ipPuente)" (Responde-Ping $ipPuente)
        Prueba "El anfitrion abre http://$ipPuente" (Web-Contiene "http://$ipPuente" 'web01')
    }
}

# ---------------------------------------------------------------------------
Seccion '7. Trazas de ruta'
Linea '  Anfitrion -> web01 (host-only):'
$t1 = (& tracert -d -h 3 $IP_WEB_HOSTONLY 2>&1)
Muestra $t1
Prueba 'Traza anfitrion -> web01: un salto' (($t1 -join ' ') -match '1\s+.*192\.168\.56\.10')
Linea '  web01 -> 8.8.8.8 (sale por el NAT):'
$t2 = En-VM 'web01' 'traceroute -n -m 3 8.8.8.8'
Muestra $t2
Prueba 'Traza web01 -> internet: el primer salto es el NAT (10.0.2.2)' (($t2 -join "`n") -match '(?m)^\s*1\s+10\.0\.2\.2')

# ---------------------------------------------------------------------------
Seccion '8. Recursos: vCPU, RAM y discos con aprovisionamiento fino'
foreach ($par in @(@($VM_WEB, 2, 1024), @($VM_DB, 1, 1024))) {
    $i = & $VBOX showvminfo $par[0] --machinereadable
    $cpus = [int]($i | Select-String '^cpus=(\d+)').Matches[0].Groups[1].Value
    $mem  = [int]($i | Select-String '^memory=(\d+)').Matches[0].Groups[1].Value
    Linea "         $($par[0]): $cpus vCPU, $mem MB de RAM"
    Prueba "$($par[0]) tiene los recursos del Vagrantfile (o los ajustados con 01_recursos_dinamicos.ps1)" (($cpus -ge 1) -and ($mem -ge 512))
}
foreach ($d in (@(Get-Discos $VM_WEB) + @(Get-Discos $VM_DB))) {
    if ($d.Disco -like 'datos_*') {
        Linea "         $($d.VM)/$($d.Disco): capacidad $($d.CapacidadMB) MB, ocupa $($d.OcupaMB) MB en Windows"
        Prueba "$($d.Disco) es de aprovisionamiento fino (ocupa mucho menos que su capacidad)" (($d.CapacidadMB -ge 20000) -and ($d.OcupaMB -lt ($d.CapacidadMB / 2)))
    }
}
$df = En-VM 'web01' 'df -h /datos'
Muestra $df
Prueba 'El disco adicional esta montado en /datos de web01' (($df -join ' ') -match '/datos')

# ---------------------------------------------------------------------------
Seccion '9. Carpeta compartida anfitrion <-> huespedes'
$compartido = Join-Path $TAREA 'compartido'
New-Item -ItemType Directory -Force $compartido | Out-Null
$marca = "desde Windows $(Get-Date -Format 'HH:mm:ss')"
Set-Content -Path (Join-Path $compartido 'prueba_anfitrion.txt') -Value $marca -Encoding Ascii
$v1 = En-VM 'web01' 'cat /compartido/prueba_anfitrion.txt'
$v2 = En-VM 'db01'  'cat /compartido/prueba_anfitrion.txt'
Prueba 'web01 lee el archivo creado en Windows (/compartido)' (($v1 -join ' ') -match 'desde Windows')
Prueba 'db01 lee el mismo archivo (carpeta compartida con las dos VMs)' (($v2 -join ' ') -match 'desde Windows')
$null = En-VM 'web01' 'echo desde web01 > /compartido/prueba_web01.txt'
Prueba 'Windows ve el archivo que creo web01' (Test-Path (Join-Path $compartido 'prueba_web01.txt'))

# ---------------------------------------------------------------------------
Linea ''
Linea "Pruebas que pasaron:  $script:pasan"
Linea "Pruebas que fallaron: $script:fallan"

$archivo = Join-Path $EVID ("validacion_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmm'))
$log | Out-File -FilePath $archivo -Encoding utf8
Write-Host "Evidencia guardada en: $archivo"
