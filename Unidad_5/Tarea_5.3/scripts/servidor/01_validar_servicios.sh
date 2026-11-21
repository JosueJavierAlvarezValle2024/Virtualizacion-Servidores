#!/usr/bin/env bash
# =============================================================================
#  01_validar_servicios.sh - Inventario y validacion de los servicios integrados
#
#  Revisa en el servidor los servicios esenciales del curso:
#    DHCP · DNS · Web HTTPS · Base de datos · Almacenamiento (FTPS/SFTP y RAID)
#  y, como extra, el correo y el NAS (Samba/NFS).
#
#  Uso:  sudo bash scripts/servidor/01_validar_servicios.sh [--completa]
#    --completa  ademas ejecuta los 99_validar.sh de las tareas 3.3, 4.1, 4.2 y 4.3
#                y suma sus resultados (tarda unos minutos)
#  La salida tambien se guarda en evidencias/servicios_<fecha>.txt
# =============================================================================
source "$(dirname "$0")/lib/comun.sh"
requiere_root
set +e

COMPLETA=0
for a in "$@"; do
    case "${a#--}" in completa) COMPLETA=1 ;; *) error "Opcion desconocida: $a (usa --completa)" ;; esac
done

mkdir -p "$EVID_DIR"
SALIDA="$EVID_DIR/servicios_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$SALIDA") 2>&1

pasaron=0; fallaron=0
pasa()  { echo -e "${VERDE}[PASA]${NC}  $1"; ((pasaron++)); }
falla() { echo -e "${ROJO}[FALLA]${NC} $1"; ((fallaron++)); }
extra() { echo -e "${AMARILLO}[EXTRA]${NC} $1"; }
# probar "descripcion" comando...   -> pasa si el comando termina bien
probar() { local d="$1"; shift; if "$@" &>/dev/null; then pasa "$d"; else falla "$d"; fi; }
# esperar "descripcion" "texto" comando...  -> pasa si la salida contiene el texto
esperar() {
    local d="$1" texto="$2"; shift 2
    local s; s="$("$@" 2>&1)"
    if grep -qF -- "$texto" <<< "$s"; then pasa "$d -> $texto"; else falla "$d (no aparece: $texto)"; fi
}

CURL_CA=(curl -s --max-time 10)
[[ -f "$CA_CRT" ]] && CURL_CA+=(--cacert "$CA_CRT") || CURL_CA+=(-k)

echo "Validacion de servicios integrados - $(hostname) - $(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------------------
titulo "1. Sistema"
printf '  %-22s %s\n' "Equipo:" "$(hostname)"
printf '  %-22s %s\n' "Sistema:" "$(. /etc/os-release; echo "$PRETTY_NAME")"
printf '  %-22s %s\n' "Kernel:" "$(uname -r)"
printf '  %-22s %s\n' "Encendido desde:" "$(uptime -s)"
printf '  %-22s %s\n' "Carga (1/5/15 min):" "$(cut -d' ' -f1-3 /proc/loadavg)"
printf '  %-22s %s\n' "Memoria (usada/total):" "$(free -m | awk '/^Mem:/ {printf "%d / %d MB", $3, $2}')"
printf '  %-22s %s\n' "Disco / (usado):" "$(df -h / | awk 'NR==2 {print $3 " de " $2 " (" $5 ")"}')"
echo "  Interfaces de red:"
ip -br -4 addr | sed 's/^/    /'
probar "El servidor tiene la IP $IP_SERVIDOR en la red interna" bash -c "ip -4 -o addr show | grep -q '$IP_SERVIDOR/'"

# ---------------------------------------------------------------------------
titulo "2. Inventario de servicios esenciales"
printf '  %-22s %-20s %-12s %s\n' "Servicio" "Programa" "Puerto" "Tarea de origen"
printf '  %-22s %-20s %-12s %s\n' "DHCP" "isc-dhcp-server" "67/udp" "4.1"
printf '  %-22s %-20s %-12s %s\n' "DNS" "named (BIND9)" "53" "4.1"
printf '  %-22s %-20s %-12s %s\n' "Web HTTPS" "apache2 + PHP" "80, 443" "4.2"
printf '  %-22s %-20s %-12s %s\n' "Base de datos" "mariadb" "3306 (local)" "4.2"
printf '  %-22s %-20s %-12s %s\n' "Archivos FTPS" "vsftpd" "21" "4.2"
printf '  %-22s %-20s %-12s %s\n' "Archivos SFTP" "ssh (OpenSSH)" "22" "4.2"
printf '  %-22s %-20s %-12s %s\n' "Almacenamiento RAID" "mdadm (md0)" "-" "3.3"

titulo "3. Estado de cada servicio"
probar "DHCP: isc-dhcp-server activo" servicio_activo isc-dhcp-server
probar "DHCP: escucha en el puerto 67/udp" escucha_udp 67
probar "DNS: named activo" servicio_activo named
probar "DNS: escucha en el puerto 53" escucha_tcp 53
probar "Web: apache2 activo" servicio_activo apache2
probar "Web: escucha en el puerto 80" escucha_tcp 80
probar "Web: escucha en el puerto 443" escucha_tcp 443
probar "Base de datos: mariadb activo" servicio_activo mariadb
probar "Base de datos: escucha en el puerto 3306" escucha_tcp 3306
probar "Archivos: vsftpd (FTPS) activo" servicio_activo vsftpd
probar "Archivos: escucha FTPS en el puerto 21" escucha_tcp 21
probar "Archivos: ssh (SFTP) activo" bash -c 'systemctl is-active --quiet ssh || systemctl is-active --quiet sshd'
probar "Archivos: escucha SSH/SFTP en el puerto 22" escucha_tcp 22

# ---------------------------------------------------------------------------
titulo "4. Pruebas de funcionamiento"
esperar "DNS responde el nombre www.$DOMINIO" "$IP_SERVIDOR" dig +short +time=3 +tries=1 "@$IP_SERVIDOR" "www.$DOMINIO"
esperar "DNS responde la inversa de $IP_SERVIDOR" "srv01" dig +short +time=3 +tries=1 -x "$IP_SERVIDOR" "@$IP_SERVIDOR"
esperar "HTTP redirige a HTTPS" "https://www.$DOMINIO" "${CURL_CA[@]}" -sI "http://www.$DOMINIO/"
esperar "HTTPS: el sitio responde (certificado de la CA)" "empresa" "${CURL_CA[@]}" "https://www.$DOMINIO/"
esperar "Web + PHP + MariaDB: la pagina consulta la base" "conectado" "${CURL_CA[@]}" "https://www.$DOMINIO/"
mariadb_expuesta() { local s; s="$(ss -ltn 2>/dev/null)"; grep -qE '(0\.0\.0\.0|\*|\[::\]|'"$IP_SERVIDOR"'):3306' <<< "$s"; }
if mariadb_expuesta; then falla "MariaDB NO debe escuchar en la red (solo 127.0.0.1)"; else pasa "MariaDB escucha solo en 127.0.0.1 (no esta expuesta a la red)"; fi
esperar "FTPS: el servidor ofrece AUTH TLS" "234" bash -c "exec 3<>/dev/tcp/127.0.0.1/21; read -t 3 -r _ <&3; printf 'AUTH TLS\r\n' >&3; read -t 3 -r l <&3; echo \"\$l\""

# ---------------------------------------------------------------------------
titulo "5. Almacenamiento (RAID 5)"
if [[ -r /proc/mdstat ]] && grep -q '^md0' /proc/mdstat; then
    grep -E '^md0|blocks' /proc/mdstat | sed 's/^/  /'
    esperar "El arreglo md0 esta activo" "active" cat /proc/mdstat
    esperar "El RAID esta completo (3 de 3 discos: [UUU])" "[UUU]" cat /proc/mdstat
    probar "El RAID esta montado en /srv/raid" mountpoint -q /srv/raid
    df -h /srv/raid 2>/dev/null | sed 's/^/  /'
else
    falla "No existe /dev/md0 (¿se monto el RAID de la Tarea 3.3?)"
fi

# ---------------------------------------------------------------------------
titulo "6. Servicios adicionales (no cuentan como falla)"
for par in "postfix:Correo SMTP (Tarea 4.3)" "dovecot:Correo IMAPS (Tarea 4.3)" "smbd:NAS Samba (Tarea 3.3)" "nfs-server:NAS NFS (Tarea 3.3)"; do
    u="${par%%:*}"; d="${par#*:}"
    if servicio_activo "$u"; then extra "$d: $u activo"; else extra "$d: $u no esta activo"; fi
done

# ---------------------------------------------------------------------------
if [[ $COMPLETA -eq 1 ]]; then
    titulo "7. Validadores de las tareas anteriores"
    ejecuta_validador() {
        local nombre="$1" script="$2" s r p f
        if [[ ! -f "$script" ]]; then falla "$nombre: no se encontro $script"; return; fi
        info "Ejecutando $nombre ..."
        s="$(bash "$script" 2>&1)"
        r="$(grep -o 'Pruebas que pasaron: *[0-9]* *Pruebas que fallaron: *[0-9]*' <<< "$s" | tail -n 1)"
        if [[ -z "$r" ]]; then falla "$nombre: no se pudo leer el resultado"; return; fi
        p="$(sed -E 's/.*pasaron: *([0-9]+).*/\1/' <<< "$r")"
        f="$(sed -E 's/.*fallaron: *([0-9]+).*/\1/' <<< "$r")"
        if [[ "$f" -eq 0 ]]; then pasa "$nombre: $p pruebas bien, 0 fallas"; else falla "$nombre: $f fallas de $((p + f)) pruebas"; fi
    }
    ejecuta_validador "Tarea 3.3 (RAID y NAS)"            "$REPO_U3/Unidad_3/Tarea_3.3/scripts/99_validar.sh"
    ejecuta_validador "Tarea 4.1 (DHCP y DNS)"            "$REPO_U4/Unidad_4/Tarea_4.1/scripts/99_validar.sh"
    ejecuta_validador "Tarea 4.2 (HTTPS, MariaDB, FTPS)"  "$REPO_U4/Unidad_4/Tarea_4.2/scripts/99_validar.sh"
    ejecuta_validador "Tarea 4.3 (correo)"                "$REPO_U4/Unidad_4/Tarea_4.3/scripts/99_validar.sh"
fi

titulo "Resultado"
echo "Pruebas que pasaron: $pasaron   Pruebas que fallaron: $fallaron"
echo "Evidencia guardada en: $SALIDA"
