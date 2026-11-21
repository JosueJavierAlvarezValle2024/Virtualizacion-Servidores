#!/usr/bin/env bash
# =============================================================================
#  02_fallo_controlado.sh - Provoca un fallo de configuracion CONTROLADO
#
#  Sirve para la prueba de contingencia: se toma un snapshot con todo
#  funcionando, se rompe una configuracion con este script, se comprueba el
#  daño y se recupera el servidor restaurando el snapshot.
#
#  Uso:  sudo bash scripts/servidor/02_fallo_controlado.sh <modo>
#    web        rompe la ruta del certificado del sitio www.empresa.lan
#               (Apache ya no arranca: el HTTPS queda caido)
#    dns        agrega una linea invalida a la zona empresa.lan
#               (BIND ya no carga la zona: los nombres dejan de resolverse)
#    ambos      aplica los dos fallos
#    estado     muestra el estado de Apache y de BIND
#    revertir   deshace los fallos con las copias de seguridad (salida de emergencia;
#               la prueba normal se recupera restaurando el snapshot)
#  Los modos se aceptan con o sin "--".
# =============================================================================
source "$(dirname "$0")/lib/comun.sh"
requiere_root
set +e

VHOST="/etc/apache2/sites-available/www.empresa.lan.conf"
ZONA="/etc/bind/zones/db.empresa.lan"

respaldar() {
    mkdir -p "$RESPALDOS_53"
    local destino="$RESPALDOS_53/$(basename "$1")"
    [[ -f "$destino" ]] || cp -p "$1" "$destino"
}

estado() {
    titulo "Estado de los servicios"
    for u in apache2 named; do
        if servicio_activo "$u"; then ok "$u: activo"; else echo -e "${ROJO}[CAIDO]${NC} $u: $(systemctl is-active "$u")"; fi
    done
    echo "--- apache2ctl configtest"
    apache2ctl configtest 2>&1 | sed 's/^/  /'
    echo "--- named-checkzone $DOMINIO"
    named-checkzone "$DOMINIO" "$ZONA" 2>&1 | sed 's/^/  /' | tail -n 4
    echo "--- Respuesta de los servicios desde el propio servidor"
    printf '  HTTPS: '; curl -s -o /dev/null --max-time 5 -w '%{http_code}\n' -k "https://www.$DOMINIO/" || true
    printf '  DNS:   '; r="$(dig +short +time=2 +tries=1 "@$IP_SERVIDOR" "www.$DOMINIO" 2>&1)"; echo "${r:-SIN RESPUESTA}"
}

fallo_web() {
    titulo "Fallo de configuracion: certificado del sitio web"
    [[ -f "$VHOST" ]] || error "No existe $VHOST"
    grep -q 'SSLCertificateFile' "$VHOST" || error "No se encontro SSLCertificateFile en $VHOST"
    respaldar "$VHOST"
    sed -i -E 's#(SSLCertificateFile[[:space:]]+)\S+#\1/etc/ssl/empresa/servidor_ROTO.crt#' "$VHOST"
    info "Linea cambiada en $VHOST:"
    grep -n 'SSLCertificateFile' "$VHOST" | sed 's/^/    /'
    info "Reiniciando Apache (se espera que falle) ..."
    systemctl restart apache2 2>&1 | sed 's/^/    /'
    if servicio_activo apache2; then aviso 'Apache sigue activo: el fallo no tuvo efecto.'; else echo -e "${ROJO}[FALLO PROVOCADO]${NC} Apache no arranco: el HTTPS esta caido."; fi
}

fallo_dns() {
    titulo "Fallo de configuracion: zona DNS"
    [[ -f "$ZONA" ]] || error "No existe $ZONA"
    respaldar "$ZONA"
    if grep -q 'FALLO_CONTROLADO' "$ZONA"; then aviso 'La zona ya tiene el fallo.'; else
        printf '\n; FALLO_CONTROLADO (Tarea 5.3)\nregistro-invalido IN A esto-no-es-una-ip\n' >> "$ZONA"
    fi
    info "Revision de la zona:"
    named-checkzone "$DOMINIO" "$ZONA" 2>&1 | sed 's/^/    /' | tail -n 3
    info "Reiniciando BIND ..."
    systemctl restart named 2>&1 | sed 's/^/    /'
    r="$(dig +short +time=2 +tries=1 "@$IP_SERVIDOR" "www.$DOMINIO" 2>&1)"
    if [[ -z "$r" ]]; then echo -e "${ROJO}[FALLO PROVOCADO]${NC} El DNS ya no resuelve www.$DOMINIO."; else aviso "El DNS aun responde: $r"; fi
}

revertir() {
    titulo "Deshaciendo los fallos con las copias de seguridad"
    [[ -d "$RESPALDOS_53" ]] || { aviso "No hay copias en $RESPALDOS_53: nada que revertir."; return; }
    [[ -f "$RESPALDOS_53/$(basename "$VHOST")" ]] && { cp -p "$RESPALDOS_53/$(basename "$VHOST")" "$VHOST"; ok "Restaurado $VHOST"; }
    [[ -f "$RESPALDOS_53/$(basename "$ZONA")" ]]  && { cp -p "$RESPALDOS_53/$(basename "$ZONA")" "$ZONA";  ok "Restaurada $ZONA"; }
    systemctl restart apache2 named
    estado
}

MODO="${1:-}"; MODO="${MODO#--}"
case "$MODO" in
    web)      fallo_web;  estado ;;
    dns)      fallo_dns;  estado ;;
    ambos)    fallo_web;  fallo_dns; estado ;;
    estado)   estado ;;
    revertir) revertir ;;
    *)        sed -n '2,24p' "$0"; exit 1 ;;
esac
