###############################################################################
# outputs.tf
###############################################################################

output "app_url" {
  description = "URL pública de la aplicación web."
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "public_ip" {
  description = "IP pública de la instancia EC2."
  value       = aws_instance.app_server.public_ip
}

output "public_dns" {
  description = "DNS público de la instancia EC2."
  value       = aws_instance.app_server.public_dns
}

output "ssh_command" {
  description = "Comando para conectarse mediante SSH."
  value       = "ssh -i labsuser.pem ubuntu@${aws_instance.app_server.public_ip}"
}

output "vpc_id" {
  description = "ID de la VPC creada."
  value       = aws_vpc.main.id
}

output "bucket_name" {
  description = "Nombre del bucket S3 utilizado para contenido estático."
  value       = aws_s3_bucket.cdn.bucket
}

output "rds_endpoint" {
  description = "Endpoint de la instancia RDS."
  value       = aws_db_instance.db.endpoint
}

output "rds_address" {
  description = "Dirección DNS de la instancia RDS."
  value       = aws_db_instance.db.address
}

output "rds_port" {
  description = "Puerto de conexión de RDS."
  value       = aws_db_instance.db.port
}