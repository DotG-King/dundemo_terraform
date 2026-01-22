# Jenkins EC2 인스턴스를 위한 IAM Role 생성
data "aws_caller_identity" "current_id" {}

data "aws_region" "current_region" {}

resource "aws_iam_role" "jenkins_iam_role" {
  name = "jenkins-ec2-role"
  # 이 역할을 EC2 인스턴스가 맡을 수 있도록 설정
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "jenkins-ec2-role"
  }
}

# Jenkins에 필요한 권한을 정의하는 IAM Policy
resource "aws_iam_role_policy" "jenkins_iam_policy" {
  name = "jenkins-aws-permissions"
  role = aws_iam_role.jenkins_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 태그로 리소스를 조회할 수 있는 권한
        Action = [
          "tag:GetResources"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        # S3 버킷에 파일을 업로드할 수 있는 권한
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        # 보안을 위해 특정 버킷 ARN으로 제한하는 것이 좋습니다.
        # 예: "arn:aws:s3:::dundemo-app-artifacts-dev-*/*"
        Resource = [
          "arn:aws:s3:::dundemo-front-bkt-dev-*/*",
          "arn:aws:s3:::dundemo-front-bkt-prod-*/*",
          "arn:aws:s3:::dundemo-app-artifacts-*/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::dundemo-front-bkt-dev-*",
          "arn:aws:s3:::dundemo-front-bkt-prod-*",
          "arn:aws:s3:::dundemo-app-artifacts-*"
        ]
      },
      {
        Action = [
          "ssm:PutParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${data.aws_region.current_region.id}:${data.aws_caller_identity.current_id.account_id}:parameter/app/*/version_number"
      },
      {
        Action = [
          "autoscaling:StartInstanceRefresh"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:autoscaling:${data.aws_region.current_region.id}:${data.aws_caller_identity.current_id.account_id}:autoScalingGroup:*:autoScalingGroupName/dundemo_app_asg_*"
      },
      {
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:ListDistributions",
          "cloudfront:GetDistribution"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 생성한 IAM Role을 EC2 인스턴스에 연결하기 위한 인스턴스 프로파일
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_iam_role.name
}
