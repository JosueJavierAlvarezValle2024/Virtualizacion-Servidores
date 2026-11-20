#!/usr/bin/env bash
# =============================================================================
#  disco_fino.sh - Formatea y monta el disco adicional (thin provisioning)
#  Se ejecuta DENTRO de la VM, como root, desde el aprovisionamiento de Vagrant.
#  Es idempotente: si el disco ya tiene sistema de archivos, no lo vuelve a formatear.
# =============================================================================
set -Eeuo pipefail

PUNTO="/datos"

# Busca un disco sin particiones y sin sistema de archivos (el disco nuevo)
DISCO=""
for d in $(lsblk -dnpo NAME,TYPE | awk '$2=="disk"{print $1}'); do
  hijos="$(lsblk -n "$d" | wc -l)"
  fs="$(lsblk -dnpo FSTYPE "$d" | tr -d ' ')"
  if [[ "$hijos" -eq 1 && -z "$fs" ]]; then DISCO="$d"; break; fi
done

if [[ -z "$DISCO" ]]; then
  # Ya estaba formateado: se busca por la etiqueta
  if blkid -L datos >/dev/null 2>&1; then
    DISCO="$(blkid -L datos)"
  else
    echo "[disco] No se encontro el disco adicional"; exit 1
  fi
else
  echo "[disco] Formateando $DISCO (ext4, etiqueta datos)"
  mkfs.ext4 -q -L datos "$DISCO"
fi

mkdir -p "$PUNTO"
if ! grep -q "LABEL=datos" /etc/fstab; then
  # La linea de comentario va aparte, como pide fstab
  echo "# Disco adicional de la Tarea 5.2" >> /etc/fstab
  echo "LABEL=datos $PUNTO ext4 defaults,nofail 0 2" >> /etc/fstab
fi
mountpoint -q "$PUNTO" || mount "$PUNTO"
chmod 777 "$PUNTO"
echo "[disco] $DISCO montado en $PUNTO"
df -h "$PUNTO" | tail -n 1
