variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID for the database server"
  type        = string
}

variable "database_sg_id" {
  description = "Security Group ID for the DB instance"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
}
