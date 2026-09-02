variable "aws_region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "francisco-cdn-bucket"
}

variable "db_identifier" {
  default = "francisco-db"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "Admin123!"
}

variable "ami_id" {
  default = "ami-08c40ec9ead489470" # Ubuntu 22.04 us-east-1
}

variable "restore" {
  description = "Indica si restaurar desde snapshot"
  type        = bool
  default     = false
}

variable "app_repo_url" {
  description = "Repositorio público con la app web de ejemplo."
  type        = string
  default     = "https://github.com/warawara-wiwi/infra_como_codigo1_EA1_flefil_caro.git"
}

variable "deletion_protection" {
  description = "Protección contra borrado en RDS"
  type        = bool
  default     = true
}