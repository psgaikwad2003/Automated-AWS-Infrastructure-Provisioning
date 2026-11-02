variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for the external ALB"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "IDs of the private app subnets for the internal ALB"
  type        = list(string)
}

variable "web_alb_sg_id" {
  description = "Security group ID for the external ALB"
  type        = string
}

variable "app_alb_sg_id" {
  description = "Security group ID for the internal ALB"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALBs"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (leave empty to skip HTTPS)"
  type        = string
  default     = ""
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs (optional)"
  type        = string
  default     = ""
}

