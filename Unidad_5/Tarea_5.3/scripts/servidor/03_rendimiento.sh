#!/usr/bin/env bash
# =============================================================================
#  03_rendimiento.sh - Mide el desempeño del servidor mientras recibe carga
#
#  Se ejecuta en el SERVIDOR; al mismo tiempo, en el CLIENTE se corre
#  prueba_rendimiento.sh para generar trafico HTTPS. Muestrea cada segundo la
#  CPU, la memoria, la carga y la actividad de disco y de red, y al final
#  imprime un resumen (promedio y pico).
#
#  Uso:  sudo bash scripts/servidor/03_rendimiento.sh [segundos]    (por omision 30)
#  La salida tambien se guarda en evidencias/rendimiento_<fecha>.txt
# =============================================================================
source "$(dirname "$0")/lib/comun.sh"
requiere_root
set +e

SEG="${1:-30}"
[[ "$SEG" =~ ^[0-9]+$ && "$SEG" -ge 5 ]] || error "Indica los segundos de muestreo (minimo 5), por ejemplo: 30"

mkdir -p "$EVID_DIR"
SALIDA="$EVID_DIR/rendimiento_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$SALIDA") 2>&1

IFACE="$(ip -4 -o addr show | awk -v ip="$IP_SERVIDOR" '$4 ~ ip"/" {print $2; exit}')"
[[ -n "$IFACE" ]] || IFACE="enp0s8"

echo "Rendimiento del servidor - $(hostname) - $(date '+%Y-%m-%d %H:%M')"
echo "Muestreo: $SEG segundos · interfaz de la red interna: $IFACE"

titulo "Antes de la prueba"
printf '  Carga (1 min): %s   Memoria libre: %s MB   Procesos de Apache: %s\n' \
    "$(cut -d' ' -f1 /proc/loadavg)" "$(free -m | awk '/^Mem:/ {print $7}')" "$(pgrep -c apache2)"

rx0="$(< /sys/class/net/$IFACE/statistics/rx_bytes)"; tx0="$(< /sys/class/net/$IFACE/statistics/tx_bytes)"

titulo "Muestreando $SEG segundos (genera carga desde el cliente ahora)"
MUESTRAS="$(mktemp)"
vmstat -S M 1 "$((SEG + 1))" > "$MUESTRAS"
# Se descartan las 2 lineas de encabezado y la primera muestra (promedio desde el arranque)
DATOS="$(tail -n +4 "$MUESTRAS")"

rx1="$(< /sys/class/net/$IFACE/statistics/rx_bytes)"; tx1="$(< /sys/class/net/$IFACE/statistics/tx_bytes)"

titulo "Resumen"
awk '
    { us+=$13; sy+=$14; id+=$15; wa+=$16; n++
      uso=100-$15; if (uso>pico) pico=uso
      if (min=="" || $4<min) min=$4
      if ($9+$10>io) io=$9+$10
      if ($12>cs) cs=$12 }
    END {
      printf "  CPU ocupada (promedio):  %5.1f %%   (usuario %.1f %% · sistema %.1f %% · espera de E/S %.1f %%)\n", 100-id/n, us/n, sy/n, wa/n
      printf "  CPU ocupada (pico):      %5.1f %%\n", pico
      printf "  Memoria libre (minimo):  %5d MB\n", min
      printf "  E/S de disco (pico):     %5d bloques/s\n", io
      printf "  Cambios de contexto:     %5d /s (pico)\n", cs
    }' <<< "$DATOS"
printf '  Carga al final (1/5/15): %s\n' "$(cut -d' ' -f1-3 /proc/loadavg)"
printf '  Procesos de Apache:      %s\n' "$(pgrep -c apache2)"
printf '  Conexiones TCP activas:  %s\n' "$(ss -tn state established 2>/dev/null | tail -n +2 | wc -l)"
awk -v rx=$((rx1 - rx0)) -v tx=$((tx1 - tx0)) -v s="$SEG" 'BEGIN {
    printf "  Red recibida:            %.2f MB  (%.2f Mbit/s promedio)\n", rx/1048576, rx*8/1000000/s
    printf "  Red enviada:             %.2f MB  (%.2f Mbit/s promedio)\n", tx/1048576, tx*8/1000000/s }'
echo
echo "Muestras (vmstat, cada segundo):"
sed -n '2,3p' "$MUESTRAS" | sed 's/^/  /'
head -n 9 <<< "$DATOS" | sed 's/^/  /'
[[ "$SEG" -gt 8 ]] && echo "  ... ($SEG muestras en total)"
rm -f "$MUESTRAS"

titulo "Resultado"
echo "Evidencia guardada en: $SALIDA"
