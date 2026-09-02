variable "aws_region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "flefil-caro-cdn-bucket"
}

variable "db_identifier" {
  default = "flefil-caro-db"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "Admin123!"
}

variable "ami_id" {
  default = "ami-08c40ec9ead489470"
}

variable "restore" {
  description = "Indica si restaurar desde snapshot"
  type        = bool
  default     = false
}

variable "app_repo_url" {
  description = "Repositorio público con la app web de ejemplo."
  type        = string
  default     = "https://github.com/frflefil/ep1-cloudcode.git"
}

variable "deletion_protection" {
  description = "Protección contra borrado en RDS"
  type        = bool
  default     = true
}