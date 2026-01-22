output "front_distribution_domain_name" {
  description = "The domain name of the CloudFront Distribution for the frontend"
  value       = aws_cloudfront_distribution.front_distribution.domain_name
}

output "front_distribution_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront Distribution for the frontend"
  value       = aws_cloudfront_distribution.front_distribution.hosted_zone_id
}

output "front_s3_bucket_id" {
  description = "The name of the front S3 bucket"
  value       = aws_s3_bucket.front_bucket.id
}

output "front_cert_dvo" {
  description = "The domain validation options for the frontend ACM certificate"
  value       = aws_acm_certificate.front_cert.domain_validation_options
}

output "front_cert_arn" {
  description = "The ARN of the frontend ACM certificate"
  value       = aws_acm_certificate.front_cert.arn
}
