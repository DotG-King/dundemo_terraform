output "db_instance_private_ip" {
  description = "Private IP of the Database server"
  value = aws_instance.db_server.private_ip
}