variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "web_alb_arn_suffix" {
  description = "ARN suffix of the web ALB for CloudWatch metrics"
  type        = string
}

variable "web_target_group_arn_suffix" {
  description = "ARN suffix of the web target group for CloudWatch metrics"
  type        = string
}

variable "app_alb_arn_suffix" {
  description = "ARN suffix of the app ALB for CloudWatch metrics"
  type        = string
}

variable "app_target_group_arn_suffix" {
  description = "ARN suffix of the app target group for CloudWatch metrics"
  type        = string
}

variable "web_asg_name" {
  description = "Name of the web Auto Scaling Group"
  type        = string
}

variable "app_asg_name" {
  description = "Name of the app Auto Scaling Group"
  type        = string
}

variable "db_instance_id" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alert notifications"
  type        = string
  default     = ""
}
