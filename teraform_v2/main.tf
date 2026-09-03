###############################################################################
# main.tf
# Infraestructura principal del proyecto:
# VPC, subredes públicas, Internet Gateway, Security Group,
# S3 para contenido estático, RDS MySQL y servidor EC2.
###############################################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "flefil-caro-ea1-codigo1"
    key    = "terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

###############################################################################
# DISPONIBILIDAD
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "flefil-caro-vpc"
  }
}

###############################################################################
# SUBREDES PÚBLICAS
#
# Se utilizan dos subredes para permitir que RDS tenga un DB subnet group
# válido distribuido en al menos dos zonas de disponibilidad.
###############################################################################

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "flefil-caro-public-${count.index + 1}"
    Tier = "public"
  }
}

###############################################################################
# INTERNET GATEWAY
###############################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flefil-caro-igw"
  }
}

###############################################################################
# TABLA DE RUTAS PÚBLICA
###############################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "flefil-caro-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# SECURITY GROUP
#
# HTTP permite acceder a la aplicación web.
# SSH permite administrar la instancia durante el laboratorio.
# MySQL permite realizar las pruebas de conexión solicitadas por la evaluación.
###############################################################################

resource "aws_security_group" "terraform_sg" {
  name        = "flefil-caro-sg"
  description = "Permitir HTTP, SSH y MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flefil-caro-sg"
  }
}

###############################################################################
# S3 - CDN / CONTENIDO ESTÁTICO
###############################################################################

resource "aws_s3_bucket" "cdn" {
  bucket       = var.bucket_name
  force_destroy = true

  tags = {
    Name = "flefil-caro-cdn"
  }
}

resource "aws_s3_bucket_public_access_block" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  depends_on = [
    aws_s3_bucket_public_access_block.cdn
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.cdn.arn}/*"
      }
    ]
  })
}

###############################################################################
# RDS SUBNET GROUP
###############################################################################

resource "aws_db_subnet_group" "db" {
  name = "flefil-caro-db-subnet-group"

  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "flefil-caro-db-subnet-group"
  }
}

###############################################################################
# RDS MYSQL
###############################################################################

resource "aws_db_instance" "db" {
  identifier = var.db_identifier

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.restore ? null : "evaluacion"
  username = var.db_username
  password = var.db_password

  parameter_group_name = "default.mysql8.0"

  db_subnet_group_name = aws_db_subnet_group.db.name

  vpc_security_group_ids = [
    aws_security_group.terraform_sg.id
  ]

  publicly_accessible = true

  skip_final_snapshot       = false
  final_snapshot_identifier = var.final_snapshot_identifier

  deletion_protection = var.deletion_protection

  snapshot_identifier = var.restore ? var.restore_snapshot_identifier : null

  tags = {
    Name = "flefil-caro-db"
  }

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

###############################################################################
# EC2 - SERVIDOR DE LA APLICACIÓN WEB
###############################################################################

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public[0].id

  vpc_security_group_ids = [
    aws_security_group.terraform_sg.id
  ]

  user_data = templatefile("${path.module}/user_data.sh", {
    app_repo_url = var.app_repo_url
  })

  tags = {
    Name = "flefil-caro-app-server"
  }
}