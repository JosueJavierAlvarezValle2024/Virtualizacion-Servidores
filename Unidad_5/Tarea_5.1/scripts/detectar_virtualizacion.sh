#!/usr/bin/env bash
# =============================================================================
# Tarea 5.1 · detectar_virtualizacion.sh
# Muestra, desde DENTRO de una VM Linux, las huellas que deja el hipervisor:
# tipo de virtualizacion, CPU virtual, hardware emulado, memoria (balloon),
# disco, red y reloj paravirtualizado. No modifica nada del sistema.
# Uso:  bash detectar_virtualizacion.sh
# Guarda una copia en ../evidencias/virtualizacion_<equipo>.txt
# =============================================================================
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
EVID="$DIR/../evidencias"
mkdir -p "$EVID"
SALIDA="$EVID/virtualizacion_$(hostname).txt"

titulo() { printf '\n\033[1;34m== %s ==\033[0m\n' "$1"; }
dato()   { printf '  %-32s %s\n' "$1" "$2"; }
leer()   { [ -r "$1" ] && cat "$1" 2>/dev/null || echo "(no disponible)"; }

{
  echo "Detección de virtualización · $(hostname) · $(date '+%Y-%m-%d %H:%M')"

  titulo "1. ¿Estoy en una máquina virtual?"
  dato "systemd-detect-virt:" "$(systemd-detect-virt 2>/dev/null || echo none)"
  dato "¿Contenedor?:" "$(systemd-detect-virt -c 2>/dev/null || echo none)"
  dato "Fabricante (DMI):" "$(leer /sys/class/dmi/id/sys_vendor)"
  dato "Producto (DMI):" "$(leer /sys/class/dmi/id/product_name)"

  titulo "2. CPU virtual (vCPU)"
  dato "Modelo:" "$(lscpu | sed -n 's/^Model name: *//p')"
  dato "vCPU asignadas:" "$(nproc)"
  dato "Fabricante del hipervisor:" "$(lscpu | sed -n 's/^Hypervisor vendor: *//p')"
  dato "Tipo de virtualización:" "$(lscpu | sed -n 's/^Virtualization type: *//p')"
  if grep -m1 -w hypervisor /proc/cpuinfo > /dev/null; then
    dato "Bandera 'hypervisor':" "SÍ (la CPU avisa que hay un hipervisor debajo)"
  else
    dato "Bandera 'hypervisor':" "no"
  fi
  if grep -m1 -E -w 'vmx|svm' /proc/cpuinfo > /dev/null; then
    dato "VT-x/AMD-V dentro de la VM:" "SÍ (virtualización anidada disponible)"
  else
    dato "VT-x/AMD-V dentro de la VM:" "no (sin virtualización anidada)"
  fi

  titulo "3. Hardware emulado o paravirtualizado (PCI)"
  if command -v lspci > /dev/null; then
    lspci | grep -i -E 'virtualbox|vmware|virtio|qemu|hyper-v|ethernet|sata|vga' | sed 's/^/  /'
  else
    echo "  (lspci no instalado)"
  fi

  titulo "4. Memoria"
  free -h | sed 's/^/  /'
  if lsmod | grep -w vboxguest > /dev/null; then
    dato "Driver vboxguest:" "cargado (permite el globo de memoria / ballooning)"
  elif lsmod | grep -w virtio_balloon > /dev/null; then
    dato "Driver virtio_balloon:" "cargado (ballooning de KVM)"
  else
    dato "Driver de ballooning:" "no encontrado"
  fi

  titulo "5. Disco virtual"
  lsblk -d -o NAME,SIZE,MODEL,ROTA,TYPE | sed 's/^/  /'

  titulo "6. Red virtual (driver de cada interfaz)"
  for n in /sys/class/net/*; do
    i="$(basename "$n")"
    [ "$i" = lo ] && continue
    drv="$(basename "$(readlink -f "$n/device/driver" 2>/dev/null)" 2>/dev/null)"
    ip4="$(ip -4 -o addr show "$i" 2>/dev/null | awk '{print $4}' | head -n1)"
    dato "$i" "driver=${drv:-?}  mac=$(leer "$n/address")  ip=${ip4:--}"
  done

  titulo "7. Reloj (paravirtualización)"
  dato "Fuente de reloj:" "$(leer /sys/devices/system/clocksource/clocksource0/current_clocksource)"
  dato "Disponibles:" "$(leer /sys/devices/system/clocksource/clocksource0/available_clocksource)"

  titulo "8. Mensajes del kernel sobre el hipervisor"
  journalctl -k -b 2>/dev/null | grep -i -E 'hypervisor detected|booting paravirtualized' | head -n 3 | sed 's/^/  /'
  echo
} 2>&1 | tee "$SALIDA"

echo "Evidencia guardada en: $SALIDA"
