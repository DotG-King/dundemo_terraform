# 버킷의 이름을 유일하게 만들기 위한 랜덤 문자열 생성
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 버킷 생성
resource "aws_s3_bucket" "app_artifacts" {
  bucket = "${var.bucket_prefix}-${terraform.workspace}-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "App Artifacts Bucket"
    Environment = terraform.workspace
  }
}

# 버전 관리 기능 활성화
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.app_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 퍼블릭 엑세스 차단
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.app_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 서버 측 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.app_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
