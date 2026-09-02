# VPC + Subnet + Gateway
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket con persistencia
resource "aws_s3_bucket" "cdn" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = false
  }
}

# RDS MySQL con creación o restauración automática
resource "aws_db_instance" "mysql" {
  identifier          = var.db_identifier
  instance_class      = "db.t3.medium"
  publicly_accessible = true

  engine              = var.restore ? null : "mysql"
  allocated_storage   = var.restore ? null : 20
  username            = var.restore ? null : var.db_username
  password            = var.restore ? null : var.db_password
  snapshot_identifier = var.restore ? "${var.db_identifier}-snapshot" : null

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.db_identifier}-snapshot"
  deletion_protection       = var.deletion_protection
}

# EC2 con despliegue corregido de Go
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_all.id]

  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/user-data.log) 2>&1
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    
    # Declarar variables de entorno críticas para que Go pueda descargar módulos
    export GOPATH=/root/go
    export GOCACHE=/root/.cache/go-build

    apt-get update -y
    
    systemctl stop apache2 || true
    systemctl disable apache2 || true

    apt-get install -y git golang-go

    cd /opt
    git clone ${var.app_repo_url} demo-app || true

    # Buscar dinámicamente la carpeta
    APP_DIR=$(find /opt/demo-app -name main.go -exec dirname {} \;)
    cd $APP_DIR

    # Resolver dependencias con el caché configurado
    rm -f go.mod go.sum
    go mod init demoapp
    go get github.com/GeertJohan/go.rice
    go get github.com/gorilla/mux
    go get github.com/graarh/golang-socketio
    go get github.com/graarh/golang-socketio/transport
    go mod tidy

    go build -o /usr/local/bin/webapp . || true

    # Crear el servicio
    cat > /etc/systemd/system/webapp.service <<-UNIT
    [Unit]
    Description=Demo web app personalizada
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/webapp
    WorkingDirectory=$APP_DIR
    Restart=always
    User=root
    Environment=PORT=80

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable webapp
    systemctl start webapp
  EOF
}