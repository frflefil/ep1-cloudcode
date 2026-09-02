#!/bin/bash
###############################################################################
# user_data.sh
# Script de arranque (cloud-init) adaptado para la app web personalizada.
###############################################################################
set -euxo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# Detener Apache si está instalado para que no bloquee el puerto 80
systemctl stop apache2 || true
systemctl disable apache2 || true

apt-get install -y git golang-go

cd /opt
git clone ${app_repo_url} demo-app || true
cd demo-app

# Inicializar módulo Go y descargar dependencias si no existe go.mod
if [ ! -f go.mod ]; then
  go mod init demoapp
  go mod tidy
fi

go build -o /usr/local/bin/webapp . || true

cat > /etc/systemd/system/webapp.service <<'UNIT'
[Unit]
Description=Demo web app personalizada
After=network.target

[Service]
ExecStart=/usr/local/bin/webapp
WorkingDirectory=/opt/demo-app
Restart=always
User=root
Environment=PORT=80

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

echo "Despliegue de la app web finalizado."