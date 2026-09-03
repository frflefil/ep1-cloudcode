# 1. Configuración del Backend (Estado Remoto)
terraform {
  backend "s3" {
    bucket = "flefil-caro-estado-tf"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 2. Redes y Seguridad (VPC y Security Groups)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Asigna IP pública automáticamente

  tags = {
    Name = "terraform-public-subnet"
  }
}

resource "aws_security_group" "terraform_sg" {
  name        = "terraform-sg"
  description = "Permitir HTTP y MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
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

# 3. Almacenamiento CDN (Bucket S3)
resource "aws_s3_bucket" "cdn" {
  bucket        = "flefil-caro-cdn-bucket"
  force_destroy = true 
}

resource "aws_s3_bucket_public_access_block" "cdn_public_access" {
  bucket = aws_s3_bucket.cdn.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "cdn_public_policy" {
  bucket = aws_s3_bucket.cdn.id
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
  depends_on = [aws_s3_bucket_public_access_block.cdn_public_access]
}

# 4. Base de Datos (RDS Persistente)
resource "aws_db_instance" "db" {
  identifier           = "flefil-caro-db"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Admin123!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = false
  final_snapshot_identifier = "flefil-caro-db-snapshot"
  deletion_protection  = var.deletion_protection
  snapshot_identifier  = var.restore ? "flefil-caro-db-snapshot" : null
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]
}

# 5. Servidor de Aplicaciones (Instancia EC2)
resource "aws_instance" "app_server" {
  ami                    = "ami-0e2c8caa4b6378d8c" # Ubuntu 24.04 LTS en us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]

  tags = {
    Name = "flefil-caro-app-server"
  }
}
