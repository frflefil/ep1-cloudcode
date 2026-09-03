#!/bin/bash

###############################################################################
# user_data.sh
# Configuración inicial de la instancia EC2.
# Instala las dependencias, clona la aplicación, la compila y la registra
# como servicio de systemd.
###############################################################################

set -euxo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

apt-get install -y git golang-go

cd /opt

rm -rf demo-app

git clone ${app_repo_url} demo-app

cd demo-app

go build -o /usr/local/bin/webapp .

cat > /etc/systemd/system/webapp.service <<'UNIT'
[Unit]
Description=Demo web app - Terraform 101
After=network.target

[Service]
ExecStart=/usr/local/bin/webapp
Restart=always
User=root
Environment=PORT=80

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload

systemctl enable webapp

systemctl restart webapp

echo "Despliegue de la aplicación web finalizado."