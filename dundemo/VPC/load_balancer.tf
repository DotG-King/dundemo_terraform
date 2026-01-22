resource "aws_lb_target_group" "application_target_group" {
  name     = "dundemo-${terraform.workspace}-app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_app_target_group"
  }
}

resource "aws_acm_certificate" "load_balancer_cert" {
  provider          = aws
  domain_name       = "*.api.dundemo.in"
  validation_method = "DNS"

  tags = {
    Name = "dundemo_${terraform.workspace}_load_balancer_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "dundemo_load_balancer" {
  name               = "dundemo-${terraform.workspace}-load-balancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.load_balancer_sg.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "dundemo_${terraform.workspace}_load_balancer"
  }
}

resource "aws_lb_listener" "dundemo_lb_http_listener" {
  load_balancer_arn = aws_lb.dundemo_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "dundemo_lb_https_listener" {
  load_balancer_arn = aws_lb.dundemo_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.load_balancer_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application_target_group.arn
  }
}
