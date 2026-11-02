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
  description = "IDs of the public subnets for the web ASG"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "IDs of the private subnets for the app ASG"
  type        = list(string)
}

variable "webserver_sg_id" {
  description = "Security group ID for web server instances"
  type        = string
}

variable "appserver_sg_id" {
  description = "Security group ID for app server instances"
  type        = string
}

variable "web_target_group_arn" {
  description = "ARN of the web ALB target group"
  type        = string
}

variable "app_target_group_arn" {
  description = "ARN of the app ALB target group"
  type        = string
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for app servers"
  type        = string
  default     = "t3.micro"
}

variable "web_asg_min" {
  description = "Minimum web ASG size"
  type        = number
  default     = 1
}

variable "web_asg_max" {
  description = "Maximum web ASG size"
  type        = number
  default     = 3
}

variable "web_asg_desired" {
  description = "Desired web ASG size"
  type        = number
  default     = 1
}

variable "app_asg_min" {
  description = "Minimum app ASG size"
  type        = number
  default     = 1
}

variable "app_asg_max" {
  description = "Maximum app ASG size"
  type        = number
  default     = 3
}

variable "app_asg_desired" {
  description = "Desired app ASG size"
  type        = number
  default     = 1
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "app_alb_dns_name" {
  description = "DNS name of the internal app ALB (for nginx upstream config)"
  type        = string
}

