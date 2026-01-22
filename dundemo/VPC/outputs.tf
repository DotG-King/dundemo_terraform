output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main_vpc.id
}

output "private_subnet_id" {
  description = "Private Subnet ID List for the application server"
  value       = aws_subnet.private.id
}

output "private_subnet_ids" {
  description = "The ID list of private subnets"
  value       = [aws_subnet.private.id, aws_subnet.private_b.id]
}

output "public_subnet_ids" {
  description = "The ID list of public subnets"
  value       = [aws_subnet.public.id, aws_subnet.public_b.id]
}

output "database_sg_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.database_sg.id
}

output "backend_sg_id" {
  description = "The ID of the backend server security group"
  value       = aws_security_group.backend_sg.id
}

output "load_balancer_target_group_arn" {
  description = "The ARN of the LB target group for the application"
  value       = aws_lb_target_group.application_target_group.arn
}

output "load_balancer_zone_id" {
  description = "The Zone ID of the Load Balancer"
  value       = aws_lb.dundemo_load_balancer.zone_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of Application Load Balancer"
  value       = aws_lb.dundemo_load_balancer.dns_name
}

output "lb_cert_dvo" {
  description = "The domain validation options for the load balancer ACM certificate"
  value       = aws_acm_certificate.load_balancer_cert.domain_validation_options
}

output "lb_cert_arn" {
  description = "The ARN of the load balancer ACM certificate"
  value = aws_acm_certificate.load_balancer_cert.arn
}
