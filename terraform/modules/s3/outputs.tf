output "app_bucket_name" {
  description = "Name of the application assets S3 bucket"
  value       = aws_s3_bucket.app_assets.bucket
}

output "app_bucket_arn" {
  description = "ARN of the application assets S3 bucket"
  value       = aws_s3_bucket.app_assets.arn
}

output "app_bucket_domain_name" {
  description = "Domain name of the application assets S3 bucket"
  value       = aws_s3_bucket.app_assets.bucket_domain_name
}

output "terraform_state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_lock_table_name" {
  description = "Name of the DynamoDB state lock table"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_lock_table_arn" {
  description = "ARN of the DynamoDB state lock table"
  value       = aws_dynamodb_table.terraform_lock.arn
}

