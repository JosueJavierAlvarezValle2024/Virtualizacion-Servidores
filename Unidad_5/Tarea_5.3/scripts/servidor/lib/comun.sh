#!/usr/bin/env bash
# =============================================================================
#  comun.sh - Variables y funciones compartidas por los scripts del servidor
#  (Tarea 5.3). Se ejecutan DENTRO de la VM servidor (Xubuntuu / srv01).
# =============================================================================
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"   # Unidad_5/Tarea_5.3
EVID_DIR="$BASE_DIR/evidencias"

# ---- Repositorios de las tareas anteriores (se pueden cambiar con variables) ----
USUARIO_VM="${SUDO_USER:-vboxuser}"
HOME_VM="$(getent passwd "$USUARIO_VM" | cut -d: -f6)"
HOME_VM="${HOME_VM:-/home/vboxuser}"
REPO_U3="${REPO_U3:-$HOME_VM/Administracion-Servidores}"
REPO_U4="${REPO_U4:-$HOME_VM/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos}"
URL_U3="https://github.com/JosueJavierAlvarezValle2024/Administracion-Servidores"
URL_U4="https://github.com/JosueJavierAlvarezValle2024/Configuracion-Servidores-DNS-Web-FTP-DHCP-Correos"

# ---- Datos del laboratorio (vienen de la Unidad 4) ----
DOMINIO="empresa.lan"
IP_SERVIDOR="192.168.50.10"
CA_CRT="/etc/ssl/empresa/ca.crt"
RESPALDOS_53="/root/tarea53_respaldos"

# ---- Salida con colores ----
VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMARILLO='\033[1;33m'; AZUL='\033[1;34m'; NC='\033[0m'
titulo() { echo -e "\n${AZUL}==== $* ====${NC}"; }
ok()     { echo -e "${VERDE}[OK]${NC} $*"; }
info()   { echo -e "[..] $*"; }
aviso()  { echo -e "${AMARILLO}[AVISO]${NC} $*"; }
error()  { echo -e "${ROJO}[ERROR]${NC} $*" >&2; exit 1; }

requiere_root() {
    [[ $EUID -eq 0 ]] || error "Ejecuta con sudo: sudo bash $0"
}

# Ayudantes de consulta. Se guarda la salida en una variable antes de buscar con
# grep: un "grep -q" dentro de una tuberia con pipefail corta la lectura y da
# falsos negativos.
servicio_activo() { systemctl is-active --quiet "$1" 2>/dev/null; }
escucha_tcp() { local s; s="$(ss -ltn 2>/dev/null)"; grep -qE "[:.]$1[[:space:]]" <<< "$s"; }
escucha_udp() { local s; s="$(ss -lun 2>/dev/null)"; grep -qE "[:.]$1[[:space:]]" <<< "$s"; }
