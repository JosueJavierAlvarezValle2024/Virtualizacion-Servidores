#!/usr/bin/env bash
# =============================================================================
#  aprovisionar_web.sh - Instala y configura web01 (nginx + herramientas de prueba)
#  Se ejecuta DENTRO de la VM, como root, desde el aprovisionamiento de Vagrant.
# =============================================================================
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[web01] Instalando paquetes"
apt-get update -qq
apt-get install -y -qq nginx mariadb-client traceroute curl >/dev/null

# ---- Pagina de inicio: muestra en que servidor y redes se esta ----
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>web01</title></head>
<body style="font-family:sans-serif">
<h1>web01 - frontend de la Tarea 5.2</h1>
<p>Si ves esta pagina, llegaste al servidor <b>web01</b>.</p>
</body></html>
HTML

systemctl enable --now nginx
systemctl reload nginx

# ---- Ruta por defecto: solo por el NAT, no por el puente ----
# Vagrant deja que el DHCP del puente (eth3) agregue su propia ruta por defecto
# con la misma metrica que el NAT, y el trafico a internet sale por el lugar
# equivocado. Con use-routes: false el puente conserva su IP y su red, pero ya no
# agrega rutas por defecto.
cat > /etc/netplan/60-tarea52-puente.yaml <<'YAML'
network:
  version: 2
  ethernets:
    eth3:
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
YAML
chmod 600 /etc/netplan/*.yaml
netplan apply
sleep 5

# ---- Comandos cortos para las pruebas del video ----
cat > /usr/local/bin/ver_redes <<'SH'
#!/usr/bin/env bash
echo "== Interfaces y direcciones =="
ip -br -4 addr
echo
echo "== Tabla de rutas =="
ip route
SH

cat > /usr/local/bin/probar_db <<'SH'
#!/usr/bin/env bash
# Consulta la base de datos de db01 por la red interna (10.10.10.20)
mysql -h 10.10.10.20 -u web -pWeb2026x -e "SELECT id, nombre, precio FROM tienda.productos;"
SH
chmod +x /usr/local/bin/ver_redes /usr/local/bin/probar_db

echo "[web01] Listo. Pagina en http://192.168.56.10"
