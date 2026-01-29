data "aws_route53_zone" "public" {
  name         = "dundemo.in."
  private_zone = false
}

resource "aws_route53_zone" "private" {
  name = "dundemo.internal"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_private_zone"
  }
}

resource "aws_route53_record" "database_dns" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "mongodb-${terraform.workspace}.dundemo.internal"
  type    = "A"
  ttl     = 300
  records = [module.database.db_instance_private_ip]
}

resource "aws_route53_record" "load_balancer" {
  zone_id = data.aws_route53_zone.public.zone_id

  name = "${terraform.workspace}.api.${data.aws_route53_zone.public.name}"
  type = "A"

  alias {
    name                   = module.vpc.load_balancer_dns_name
    zone_id                = module.vpc.load_balancer_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "lb_cert_validation" {
  # dev에서 생성한 인증서가 prod에서는 생성되지 않도록 방지
  for_each = terraform.workspace == "dev" ? {
    for dvo in module.vpc.lb_cert_dvo : dvo.domain_name => dvo
  } : {}

  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "lb_cert_validation" {
  # dev에서 생성한 인증서가 prod에서는 생성되지 않도록 방지
  count = terraform.workspace == "dev" ? 1 : 0

  provider = aws
  certificate_arn = module.vpc.lb_cert_arn
  validation_record_fqdns = [
    for dvo in module.vpc.lb_cert_dvo : dvo.resource_record_name
  ]
}

resource "aws_route53_record" "front_dns" {
  zone_id = data.aws_route53_zone.public.zone_id

  name = "www.${terraform.workspace}.${data.aws_route53_zone.public.name}"
  type = "A"

  alias {
    name                   = module.app_front.front_distribution_domain_name
    zone_id                = module.app_front.front_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "front_cert_validation" {
  # dev에서 생성한 인증서가 prod에서는 생성되지 않도록 방지
  for_each = terraform.workspace == "dev" ?{
    for dvo in module.app_front.front_cert_dvo : dvo.domain_name => dvo
  } : {}

  # for_each = {
  #   for dvo in module.app_front.front_cert_dvo : dvo.domain_name => dvo
  # }

  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "front_cert_validation" {
  # dev에서 생성한 인증서가 prod에서는 생성되지 않도록 방지
  count = terraform.workspace == "dev" ? 1 : 0

  provider        = aws.us_east_1
  certificate_arn = module.app_front.front_cert_arn
  validation_record_fqdns = [
    for dvo in module.app_front.front_cert_dvo : dvo.resource_record_name
  ]
}
