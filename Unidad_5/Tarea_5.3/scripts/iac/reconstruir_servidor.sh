#!/usr/bin/env bash
# =============================================================================
#  reconstruir_servidor.sh - Infraestructura como codigo: levanta TODOS los
#  servicios del curso en un servidor Xubuntu 25.10 limpio.
#
#  Ejecuta, en orden y desde sus repositorios de GitHub, los scripts probados de
#  las tareas anteriores:
#     Unidad 3: 3.1 usuarios · 3.2 discos, ACL, cuotas y respaldos · 3.3 RAID y NAS
#     Unidad 4: 4.1 DHCP y DNS · 4.2 web HTTPS, MariaDB y FTPS/SFTP · 4.3 correo
#  y al final valida todo con 01_validar_servicios.sh --completa.
#
#  Requisitos: la VM de crear_vms.ps1 con Xubuntu 25.10 instalado, usuario
#  vboxuser, internet por el adaptador NAT y los 6 discos (sdb a sdf vacios).
#
#  Uso:  sudo bash scripts/iac/reconstruir_servidor.sh [opciones]
#    --simular   solo muestra el plan, no ejecuta nada (no pide sudo)
#    --si        responde solo las confirmaciones de formateo (FORMATEAR / RAID).
#                OJO: borra sdb, sdc, sdd, sde y sdf. Sin --si, te las pregunta.
#    --sin-u3    omite la Unidad 3 (solo DHCP, DNS, web, base de datos, FTP y correo)
#    --sin-validar   no ejecuta la validacion final
#  Las opciones se aceptan con o sin "--".
# =============================================================================
set -Eeuo pipefail

SIMULAR=0; SI=0; SIN_U3=0; VALIDAR=1
for a in "$@"; do
    case "${a#--}" in
        simular) SIMULAR=1 ;;
        si) SI=1 ;;
        sin-u3) SIN_U3=1 ;;
        sin-validar) VALIDAR=0 ;;
        *) echo "Opcion desconocida: $a"; sed -n '17,24p' "$0"; exit 1 ;;
    esac
done

AZUL='\033[1;34m'; VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMARILLO='\033[1;33m'; NC='\033[0m'
titulo() { echo -e "\n${AZUL}==== $* ====${NC}"; }
ok()     { echo -e "${VERDE}[OK]${NC} $*"; }
info()   { echo -e "[..] $*"; }
aviso()  { echo -e "${AMARILLO}[AVISO]${NC} $*"; }
error()  { echo -e "${ROJO}[ERROR]${NC} $*" >&2; exit 1; }

if [[ $SIMULAR -eq 0 && $EUID -ne 0 ]]; then error "Ejecuta con sudo: sudo bash $0"; fi

AQUI="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$AQUI/../.." && pwd)"
USUARIO_VM="${SUDO_USER:-vboxuser}"
HOME_VM="$(getent passwd "$USUARIO_VM" 2>/dev/null | cut -d: -f6 || true)"
HOME_VM="${HOME_VM:-/home/$USUARIO_VM}"
REPO_U3="${REPO_U3:-$HOME_VM/Administracion-Servidores}"
REPO_U4="${REPO_U4:-$HOME_VM/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos}"
URL_U3="https://github.com/JosueJavierAlvarezValle2024/Administracion-Servidores"
URL_U4="https://github.com/JosueJavierAlvarezValle2024/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos"
BITACORA="/root/tarea53_reconstruccion_$(date +%Y%m%d_%H%M%S).log"

# Cada paso:  descripcion | repositorio (U3/U4) | ruta del script | confirmacion que pide
PASOS=()
if [[ $SIN_U3 -eq 0 ]]; then
    PASOS+=(
        "3.1 Usuarios, grupos y politicas de seguridad|U3|Unidad_3/Tarea_3.1/scripts/00_ejecutar_todo.sh|"
        "3.2 Discos de datos y respaldos (sdb, sdc)|U3|Unidad_3/Tarea_3.2/scripts/00_preparar_discos.sh|FORMATEAR"
        "3.2 Permisos y ACL|U3|Unidad_3/Tarea_3.2/scripts/01_permisos_acl.sh|"
        "3.2 Cuotas de disco|U3|Unidad_3/Tarea_3.2/scripts/02_cuotas.sh|"
        "3.2 Respaldos automaticos|U3|Unidad_3/Tarea_3.2/scripts/03_instalar_respaldos.sh|"
        "3.3 RAID 5 (sdd, sde, sdf)|U3|Unidad_3/Tarea_3.3/scripts/00_crear_raid.sh|RAID"
        "3.3 NAS: Samba y NFS|U3|Unidad_3/Tarea_3.3/scripts/02_compartir_samba_nfs.sh|"
    )
fi
PASOS+=(
    "4.1 DHCP y DNS (red, isc-dhcp-server, BIND9)|U4|Unidad_4/Tarea_4.1/scripts/00_ejecutar_todo.sh|"
    "4.2 Web HTTPS, MariaDB, CA local, FTPS y SFTP|U4|Unidad_4/Tarea_4.2/scripts/00_ejecutar_todo.sh|"
    "4.3 Correo SMTP/IMAP con TLS|U4|Unidad_4/Tarea_4.3/scripts/00_ejecutar_todo.sh|"
)

titulo "Plan de reconstruccion"
info "Repositorio de la Unidad 3: $REPO_U3"
info "Repositorio de la Unidad 4: $REPO_U4"
n=0
for p in "${PASOS[@]}"; do
    n=$((n + 1)); IFS='|' read -r desc repo ruta conf <<< "$p"
    printf '  %2d. %-52s %s%s\n' "$n" "$desc" "$ruta" "${conf:+   (confirma: $conf)}"
done
printf '  %2d. %-52s %s\n' $((n + 1)) "Validacion integral de los servicios" "scripts/servidor/01_validar_servicios.sh --completa"
if [[ $SIMULAR -eq 1 ]]; then
    ok "Simulacion terminada: no se ejecuto nada."
    exit 0
fi

# ---------------------------------------------------------------------------
exec > >(tee -a "$BITACORA") 2>&1
info "Bitacora: $BITACORA"

titulo "Preparando el servidor"
command -v git >/dev/null || { apt-get update -q >/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y -q git >/dev/null; }
. /etc/os-release
[[ "${VERSION_ID:-}" == "25.10" ]] || aviso "Este laboratorio se probo en Ubuntu 25.10 y esta VM es ${PRETTY_NAME:-desconocida}."

clonar() {
    local url="$1" destino="$2"
    if [[ -d "$destino/.git" ]]; then
        info "Actualizando $destino"; sudo -u "$USUARIO_VM" git -C "$destino" pull -q || aviso "No se pudo actualizar $destino"
    else
        info "Clonando $url"; sudo -u "$USUARIO_VM" git clone -q "$url" "$destino"
    fi
}
if [[ $SIN_U3 -eq 0 ]]; then clonar "$URL_U3" "$REPO_U3"; fi
clonar "$URL_U4" "$REPO_U4"
ok "Repositorios listos"

# ---------------------------------------------------------------------------
n=0; total="${#PASOS[@]}"
for p in "${PASOS[@]}"; do
    n=$((n + 1)); IFS='|' read -r desc repo ruta conf <<< "$p"
    raiz="$REPO_U4"; [[ "$repo" == "U3" ]] && raiz="$REPO_U3"
    script="$raiz/$ruta"
    titulo "Paso $n de $total: $desc"
    [[ -f "$script" ]] || error "No existe $script"
    carpeta="$(dirname "$(dirname "$script")")"
    if [[ -n "$conf" && $SI -eq 1 ]]; then
        aviso "Se responde automaticamente '$conf' (opcion --si)"
        ( cd "$carpeta" && printf '%s\n' "$conf" | bash "$script" )
    else
        ( cd "$carpeta" && bash "$script" )
    fi
    ok "Paso $n terminado"
done

# ---------------------------------------------------------------------------
if [[ $VALIDAR -eq 1 ]]; then
    titulo "Validacion integral"
    bash "$BASE_DIR/scripts/servidor/01_validar_servicios.sh" --completa
fi
ok "Reconstruccion terminada. Bitacora: $BITACORA"
