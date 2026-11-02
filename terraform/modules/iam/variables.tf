variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "app_bucket_arn" {
  description = "ARN of the S3 application assets bucket"
  type        = string
}

