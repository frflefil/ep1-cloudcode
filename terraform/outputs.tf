output "bucket_name" {
  value = aws_s3_bucket.cdn.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "app_url" {
  value = "http://${aws_instance.web.public_ip}/app"
}
