# 버킷의 이름을 유일하게 만들기 위한 랜덤 문자열 생성
resource "random_string" "front_bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_acm_certificate" "front_cert" {
  provider          = aws.us_east_1
  domain_name       = "*.dundemo.in"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.dundemo.in",
    "*.dev.dundemo.in",
    "*.prod.dundemo.in"
  ]

  tags = {
    Name = "dundemo_${terraform.workspace}_front_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "front_bucket" {
  bucket_prefix = "${var.front_bucket_prefix}-${terraform.workspace}-${random_string.front_bucket_suffix.result}"

  tags = {
    Name        = "dundemo_${terraform.workspace}_front_bucket"
    Environment = terraform.workspace
    Type        = "front"
  }
}

resource "aws_s3_bucket_website_configuration" "front_bucket_website" {
  bucket = aws_s3_bucket.front_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_cloudfront_origin_access_control" "front_oac" {
  name                              = "dundemo-${terraform.workspace}-front-oac"
  description                       = "Origin Access Control for dundemo frontend S3 bucket in ${terraform.workspace} environment"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "front_bucket_policy" {
  bucket = aws_s3_bucket.front_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" },
        Action    = ["s3:GetObject"],
        Resource  = ["${aws_s3_bucket.front_bucket.arn}/*"],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.front_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "front_bucket_public_access_block" {
  bucket = aws_s3_bucket.front_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_distribution" "front_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "dundemo_${terraform.workspace}_front_distribution"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.front_bucket.bucket_regional_domain_name
    origin_id                = "S3-dundemo-frontend-bucket-${terraform.workspace}"
    origin_access_control_id = aws_cloudfront_origin_access_control.front_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-dundemo-frontend-bucket-${terraform.workspace}"
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["www.${terraform.workspace}.dundemo.in"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.front_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "dundemo_${terraform.workspace}_front_distribution"
  }
}
