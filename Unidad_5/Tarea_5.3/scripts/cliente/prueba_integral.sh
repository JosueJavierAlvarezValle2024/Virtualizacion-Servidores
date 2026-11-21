#!/usr/bin/env bash
# =============================================================================
#  prueba_integral.sh - Recorrido de los servicios desde la VM CLIENTE
#
#  Sigue el camino de un usuario por la infraestructura y comprueba el paso de
#  trafico entre servicios:
#    1) DHCP  -> el cliente recibio su IP, puerta de enlace y DNS
#    2) DNS   -> resuelve nombres directos, inversos y de correo
#    3) HTTPS -> el sitio, con el certificado de la CA local
#    4) Web + PHP + MariaDB -> la pagina consulta la base (el cliente no la ve)
#    5) FTPS / SFTP -> cifrado obligatorio y sin acceso anonimo
#    6) Correo (extra) -> IMAPS con el certificado de la CA
#
#  Uso:  bash scripts/cliente/prueba_integral.sh
#  No pide sudo. La salida tambien se guarda en evidencias/cliente_<fecha>.txt
# =============================================================================
set -uo pipefail

DOMINIO="empresa.lan"
IP_SERVIDOR="192.168.50.10"
DIR="$(cd "$(dirname "$0")" && pwd)"
EVID="$DIR/../../evidencias"
mkdir -p "$EVID" 2>/dev/null
SALIDA="$EVID/cliente_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$SALIDA") 2>&1

AZUL='\033[1;34m'; VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMARILLO='\033[1;33m'; NC='\033[0m'
titulo() { echo -e "\n${AZUL}==== $* ====${NC}"; }
pasaron=0; fallaron=0
pasa()  { echo -e "${VERDE}[PASA]${NC}  $1"; ((pasaron++)); }
falla() { echo -e "${ROJO}[FALLA]${NC} $1"; ((fallaron++)); }
extra() { echo -e "${AMARILLO}[EXTRA]${NC} $1"; }
# esperar "descripcion" "texto" comando...   -> pasa si la salida contiene el texto
esperar() {
    local d="$1" texto="$2"; shift 2
    local s; s="$("$@" 2>&1)"
    if grep -qF -- "$texto" <<< "$s"; then pasa "$d -> $texto"; else falla "$d (no aparece: $texto)"; fi
}
# cerrado "descripcion" host puerto  -> pasa si NO se puede abrir esa conexion
cerrado() {
    if timeout 3 bash -c "exec 3<>/dev/tcp/$2/$3" 2>/dev/null; then falla "$1 (esta abierto y no deberia)"; else pasa "$1"; fi
}

command -v dig >/dev/null || { echo "Falta dig: sudo apt install bind9-dnsutils"; exit 1; }
command -v curl >/dev/null || { echo "Falta curl: sudo apt install curl"; exit 1; }

# Certificado de la CA: el del sistema si ya esta instalado; si no, se descarga
CA="/usr/local/share/ca-certificates/empresa-ca.crt"
if [[ ! -f "$CA" ]]; then
    CA="/tmp/empresa-ca.crt"
    curl -fsS "http://www.$DOMINIO/ca.crt" -o "$CA" 2>/dev/null || echo "(No se pudo bajar la CA: se intentara sin ella)"
fi
CURL=(curl -s --max-time 10 --cacert "$CA")

echo "Prueba integral desde el cliente - $(hostname) - $(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------------------
titulo "1. DHCP: la configuracion de red que recibio el cliente"
ip -br -4 addr | grep -v '^lo ' | sed 's/^/  /'
echo "  Puerta de enlace: $(ip route | awk '/^default/ {print $3; exit}')"
echo "  DNS en uso:       $(resolvectl dns 2>/dev/null | awk -F': ' 'NF>1 {print $2}' | head -n 1)"
ip_cliente="$(ip -4 -o addr show | awk '$4 ~ /^192\.168\.50\./ {print $4}' | head -n 1)"
[[ "$ip_cliente" == 192.168.50.* ]] && pasa "El cliente tiene una IP de la red 192.168.50.0/24 ($ip_cliente)" || falla "El cliente no tiene IP en 192.168.50.0/24"
esperar "La puerta de enlace es el servidor" "$IP_SERVIDOR" ip route

# ---------------------------------------------------------------------------
titulo "2. DNS: resolucion de nombres con el servidor $IP_SERVIDOR"
esperar "www.$DOMINIO (A)" "$IP_SERVIDOR" dig +short +time=3 +tries=1 "@$IP_SERVIDOR" "www.$DOMINIO"
esperar "ftp.$DOMINIO (CNAME -> srv01)" "srv01.$DOMINIO" dig +short +time=3 +tries=1 "@$IP_SERVIDOR" "ftp.$DOMINIO"
esperar "Inversa de $IP_SERVIDOR (PTR)" "srv01.$DOMINIO" dig +short +time=3 +tries=1 -x "$IP_SERVIDOR" "@$IP_SERVIDOR"
esperar "Correo del dominio (MX)" "mail.$DOMINIO" dig +short +time=3 +tries=1 "@$IP_SERVIDOR" "$DOMINIO" MX
esperar "Reenviadores: resuelve un nombre de internet" "." dig +short +time=5 +tries=1 "@$IP_SERVIDOR" www.google.com

# ---------------------------------------------------------------------------
titulo "3. Web HTTPS"
esperar "HTTP redirige a HTTPS" "https://www.$DOMINIO" "${CURL[@]}" -sI "http://www.$DOMINIO/"
verif="$("${CURL[@]}" -o /dev/null -w '%{http_code} %{ssl_verify_result}' "https://www.$DOMINIO/")"
[[ "$verif" == "200 0" ]] && pasa "https://www.$DOMINIO responde 200 y el certificado es valido (verify 0)" || falla "https://www.$DOMINIO: '$verif' (se esperaba '200 0')"
esperar "intranet.$DOMINIO (sitio virtual)" "200" "${CURL[@]}" -o /dev/null -w '%{http_code}' "https://intranet.$DOMINIO/"
tls="$(echo | openssl s_client -connect "www.$DOMINIO:443" -servername "www.$DOMINIO" -CAfile "$CA" 2>/dev/null | grep -E 'Protocol|Verify return code' | sed 's/^ */  /')"
echo "$tls"
esperar "Version de TLS moderna" "TLSv1.3" echo "$tls"

# ---------------------------------------------------------------------------
titulo "4. Web + PHP + MariaDB: el trafico entre servicios"
pagina="$("${CURL[@]}" "https://www.$DOMINIO/")"
echo "$pagina" | grep -o -i 'MariaDB[^<]*' | head -n 2 | sed 's/^/  /'
grep -qi 'conectado' <<< "$pagina" && pasa "La pagina PHP se conecto a MariaDB y mostro datos" || falla "La pagina no pudo consultar la base de datos"
cerrado "El cliente NO puede entrar directo a MariaDB (puerto 3306 cerrado a la red)" "$IP_SERVIDOR" 3306

# ---------------------------------------------------------------------------
titulo "5. Archivos: FTPS y SFTP"
ftps="$(echo | openssl s_client -starttls ftp -connect "ftp.$DOMINIO:21" -CAfile "$CA" 2>/dev/null | grep -E 'Verify return code|Protocol' | sed 's/^ */  /')"
echo "$ftps"
esperar "FTPS: el certificado del servidor es de la CA" "Verify return code: 0" echo "$ftps"
curl -s --max-time 10 --ssl-reqd --cacert "$CA" "ftp://ftp.$DOMINIO/" --user anonymous:prueba -o /dev/null 2>/dev/null
[[ $? -eq 67 ]] && pasa "FTPS: el acceso anonimo es rechazado (530)" || falla "FTPS: el acceso anonimo no fue rechazado"
banner="$(timeout 3 bash -c "exec 3<>/dev/tcp/ftp.$DOMINIO/22; head -c 30 <&3" 2>/dev/null | tr -d '\r\n')"
echo "  Banner SSH: $banner"
grep -q 'SSH-2.0' <<< "$banner" && pasa "SFTP: el servidor SSH responde en el puerto 22" || falla "SFTP: no responde el puerto 22"

# ---------------------------------------------------------------------------
titulo "6. Correo (extra)"
imaps="$(echo | openssl s_client -connect "mail.$DOMINIO:993" -CAfile "$CA" 2>/dev/null | grep -E 'Verify return code' | sed 's/^ */  /')"
if grep -q 'return code: 0' <<< "$imaps"; then extra "IMAPS (993) con certificado de la CA: $imaps"; else extra "IMAPS (993): ${imaps:-sin respuesta}"; fi

titulo "Resultado"
echo "Pruebas que pasaron: $pasaron   Pruebas que fallaron: $fallaron"
echo "Evidencia guardada en: $SALIDA"
