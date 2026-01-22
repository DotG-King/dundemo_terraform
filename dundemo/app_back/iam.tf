# EC2가 이 역할을 맡을 수 있도록 허용하는 정책
resource "aws_iam_role" "app_iam_role" {
  name = "app-ec2-role"
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
}

# S3 및 SSM 접근을 허용하는 정책 내용
resource "aws_iam_role_policy" "app_iam_policy" {
  name = "app-s3-ssm-policy"
  role = aws_iam_role.app_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${var.s3_bucket_arn}/*" # s3 버킷의 모든 객체
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.current_region_id}:${var.current_account_id}:parameter/app/${terraform.workspace}/version_number" # SSM 파라미터 ARN
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.current_region_id}:${var.current_account_id}:parameter/app/${terraform.workspace}/mongo/uri" # MONGO_URI 파라미터 ARN 추가
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.current_region_id}:${var.current_account_id}:parameter/app/api/key" # API_KEY 파라미터 ARN 추가
      },
      {
        Action = [
          "ksm:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*" # 필요에 따라 특정 KMS 키 ARN으로 제한 가능
      }
    ]
  })
}

# AWS 관리형 정책인 SSM Core 정책 연결 (SSM Agent 작동에 필요)
resource "aws_iam_role_policy_attachment" "ssm_core_attachment" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 인스턴스에 연결할 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "app-instance-profile"
  role = aws_iam_role.app_iam_role.name
}
