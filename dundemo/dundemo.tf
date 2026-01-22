module "vpc" {
  source = "./VPC"

  providers = {
    aws = aws
  }
}

module "s3" {
  source = "./S3"
}

module "database" {
  source = "./db"

  providers = {
    aws = aws
  }

  # vpc 모듈의 output을 db 모듈의 input으로 전달
  ami_id            = data.aws_ami.amazon_linux_2023.id
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
  database_sg_id    = module.vpc.database_sg_id
  key_name          = aws_key_pair.dundemo_key_pair.key_name
}

module "app_back" {
  source = "./app_back"

  ami_id                         = data.aws_ami.amazon_linux_2023.id
  vpc_id                         = module.vpc.vpc_id
  current_region_id              = data.aws_region.current_region.id
  current_account_id             = data.aws_caller_identity.current_id.account_id
  s3_bucket_name                 = module.s3.s3_bucket_id
  s3_bucket_arn                  = module.s3.s3_bucket_arn
  private_subnet_ids             = module.vpc.private_subnet_ids
  backend_sg_id                  = module.vpc.backend_sg_id
  key_name                       = aws_key_pair.dundemo_key_pair.key_name
  asg_min_size                   = 1
  asg_max_size                   = 1
  asg_desired_capacity           = 1
  load_balancer_target_group_arn = module.vpc.load_balancer_target_group_arn
}

module "app_front" {
  source = "./app_front"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 현재 AWS 계정 ID를 동적으로 가져오기
data "aws_caller_identity" "current_id" {}

# 현재 AWS 리전 정보를 동적으로 가져오기
data "aws_region" "current_region" {}

# db 모듈에서 생성된 DNS 이름을 사용하여 MONGO_URI를 SSM Parameter Store에 저장
resource "aws_ssm_parameter" "mongo_uri" {
  name  = "/app/${terraform.workspace}/mongo/uri"
  type  = "SecureString"                                                    # 민감한 정보이므로 SecureString으로 저장
  value = "mongodb://${aws_route53_record.database_dns.name}:27017/dundemo" # db 모듈의 output과 조합

  tags = {
    Name = "dundemo_${terraform.workspace}_mongo_uri"
  }
}
