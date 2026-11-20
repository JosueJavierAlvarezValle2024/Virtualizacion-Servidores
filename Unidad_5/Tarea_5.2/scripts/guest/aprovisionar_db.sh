#!/usr/bin/env bash
# =============================================================================
#  aprovisionar_db.sh - Instala y configura db01 (MariaDB solo en la red interna)
#  Se ejecuta DENTRO de la VM, como root, desde el aprovisionamiento de Vagrant.
# =============================================================================
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[db01] Instalando paquetes"
apt-get update -qq
apt-get install -y -qq mariadb-server traceroute curl >/dev/null

# ---- MariaDB escucha SOLO en la IP de la red interna ----
# Los comentarios van en su propia linea.
cat > /etc/mysql/mariadb.conf.d/99-tarea52.cnf <<'CNF'
[mysqld]
# Solo atiende en la red interna red-backend (no en NAT ni en otras redes)
bind-address = 10.10.10.20
CNF

systemctl enable mariadb
systemctl restart mariadb

# ---- Base de datos de prueba y usuario que solo puede entrar desde web01 ----
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS tienda;
CREATE TABLE IF NOT EXISTS tienda.productos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(40) NOT NULL,
  precio DECIMAL(8,2) NOT NULL
);
INSERT IGNORE INTO tienda.productos (id, nombre, precio) VALUES
  (1, 'Teclado', 350.00),
  (2, 'Mouse', 180.00),
  (3, 'Monitor', 2400.00);
CREATE USER IF NOT EXISTS 'web'@'10.10.10.10' IDENTIFIED BY 'Web2026x';
GRANT SELECT ON tienda.* TO 'web'@'10.10.10.10';
FLUSH PRIVILEGES;
SQL

cat > /usr/local/bin/ver_redes <<'SH'
#!/usr/bin/env bash
echo "== Interfaces y direcciones =="
ip -br -4 addr
echo
echo "== Tabla de rutas =="
ip route
SH
chmod +x /usr/local/bin/ver_redes

echo "[db01] Listo. MariaDB escucha en 10.10.10.20:3306"
ss -ltn | grep 3306 || true
