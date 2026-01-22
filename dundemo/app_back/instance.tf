resource "aws_launch_template" "application_launch_template" {
  name_prefix   = "dundemo_app_lt_${terraform.workspace}_"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    workspace      = terraform.workspace
    s3_bucket_name = var.s3_bucket_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "dundemo_app_server_${terraform.workspace}"
    }
  }
}

#Auto Scaling Group 생성
resource "aws_autoscaling_group" "application_asg" {
  name_prefix = "dundemo_app_asg_${terraform.workspace}_"

  launch_template {
    id      = aws_launch_template.application_launch_template.id
    version = "$Latest"
  }

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [var.load_balancer_target_group_arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Environment"
    value               = "${terraform.workspace}"
    propagate_at_launch = true
  }
}
