#!/usr/bin/env bash
# =============================================================================
#  prueba_rendimiento.sh - Genera carga HTTPS contra el servidor y mide la
#  latencia que percibe el cliente.
#
#  Hace N peticiones a https://www.empresa.lan/ con C conexiones en paralelo
#  (esa pagina usa Apache + PHP + MariaDB, asi que carga los tres a la vez).
#  Mientras corre, en el SERVIDOR se ejecuta: sudo bash scripts/servidor/03_rendimiento.sh
#
#  Uso:  bash scripts/cliente/prueba_rendimiento.sh [peticiones] [en_paralelo]
#        por omision: 600 peticiones, 10 en paralelo
#  La salida tambien se guarda en evidencias/carga_cliente_<fecha>.txt
# =============================================================================
set -uo pipefail

N="${1:-600}"
C="${2:-10}"
DOMINIO="empresa.lan"
URL="https://www.$DOMINIO/"
DIR="$(cd "$(dirname "$0")" && pwd)"
EVID="$DIR/../../evidencias"
mkdir -p "$EVID" 2>/dev/null
SALIDA="$EVID/carga_cliente_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$SALIDA") 2>&1

[[ "$N" =~ ^[0-9]+$ && "$C" =~ ^[0-9]+$ && "$N" -ge 1 && "$C" -ge 1 ]] || { echo "Uso: $0 [peticiones] [en_paralelo]"; exit 1; }
command -v curl >/dev/null || { echo "Falta curl: sudo apt install curl"; exit 1; }

CA="/usr/local/share/ca-certificates/empresa-ca.crt"
if [[ ! -f "$CA" ]]; then CA="/tmp/empresa-ca.crt"; curl -fsS "http://www.$DOMINIO/ca.crt" -o "$CA" 2>/dev/null; fi

TIEMPOS="$(mktemp)"
echo "Prueba de carga desde $(hostname) - $(date '+%Y-%m-%d %H:%M')"
echo "Destino: $URL · $N peticiones · $C en paralelo"
echo
echo "Generando carga ..."
inicio="$(date +%s.%N)"
seq "$N" | xargs -P "$C" -I{} curl -s --max-time 20 --cacert "$CA" -o /dev/null -w '%{time_total} %{http_code}\n' "$URL" > "$TIEMPOS"
fin="$(date +%s.%N)"

total="$(awk -v a="$inicio" -v b="$fin" 'BEGIN {printf "%.2f", b-a}')"
ok="$(awk '$2==200' "$TIEMPOS" | wc -l)"
mal=$((N - ok))
echo
echo "==== Resultado ===="
printf '  Peticiones correctas:   %d de %d (errores: %d)\n' "$ok" "$N" "$mal"
printf '  Tiempo total:           %s s\n' "$total"
awk -v n="$ok" -v t="$total" 'BEGIN { if (t>0) printf "  Peticiones por segundo: %.1f\n", n/t }'
sort -n "$TIEMPOS" | awk '$2==200 {t[++k]=$1; suma+=$1}
    END { if (k==0) exit
          printf "  Latencia minima:        %.0f ms\n", t[1]*1000
          printf "  Latencia promedio:      %.0f ms\n", suma/k*1000
          printf "  Latencia mediana (p50): %.0f ms\n", t[int(k*0.50+0.5)]*1000
          printf "  Latencia p95:           %.0f ms\n", t[int(k*0.95+0.5)]*1000
          printf "  Latencia maxima:        %.0f ms\n", t[k]*1000 }'
rm -f "$TIEMPOS"
echo
echo "Evidencia guardada en: $SALIDA"
