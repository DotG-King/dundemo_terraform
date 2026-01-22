output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.app_artifacts.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.app_artifacts.arn
}
