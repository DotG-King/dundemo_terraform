variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "current_region_id" {
  description = "The AWS region in which resources will be created"
  type        = string
}

variable "current_account_id" {
  description = "The AWS account ID where resources will be created"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket where application JARs are stored"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket where application JARs are stored"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet ID List for the application server"
  type        = list(string)
}

variable "backend_sg_id" {
  description = "Security Group ID for the backend instance"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
}

variable "load_balancer_target_group_arn" {
  description = "The ARN of the Load Balancer target group"
  type        = string
}
