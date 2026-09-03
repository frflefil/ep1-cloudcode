###############################################################################
# variables.tf
###############################################################################

variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas."
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "bucket_name" {
  description = "Nombre global del bucket S3 utilizado para contenido estático."
  type        = string
  default     = "flefil-caro-cdn-bucket-1-2"
}

variable "db_identifier" {
  description = "Identificador de la instancia RDS."
  type        = string
  default     = "flefil-caro-db"
}

variable "db_username" {
  description = "Usuario administrador de RDS."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Contraseña del usuario administrador de RDS."
  type        = string
  sensitive   = true
  default     = "Admin123!"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 compatible con Learner Lab."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI de Ubuntu utilizada para EC2."
  type        = string
  default     = "ami-08c40ec9ead489470"
}

variable "app_repo_url" {
  description = "Repositorio que contiene la aplicación web basada en el demo de Terraform 101."
  type        = string
  default     = "https://github.com/hashicorp/demo-terraform-101"
}

variable "deletion_protection" {
  description = "Protección contra eliminación de la instancia RDS."
  type        = bool
  default     = true
}

variable "restore" {
  description = "Indica si RDS debe restaurarse desde un snapshot existente."
  type        = bool
  default     = true
}

variable "restore_snapshot_identifier" {
  description = "Identificador del snapshot utilizado para restaurar RDS."
  type        = string
  default     = "flefil-caro-db-snapshot"
}

variable "final_snapshot_identifier" {
  description = "Identificador del snapshot generado al destruir RDS."
  type        = string
  default     = "flefil-caro-db-snapshot"
}