variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "owner" {
  description = "Owner team"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "web_instance_type" {
  description = "Web instance type"
  type        = string
}

variable "app_instance_type" {
  description = "App instance type"
  type        = string
}

variable "web_asg_min" {
  description = "Web ASG min"
  type        = number
}

variable "web_asg_max" {
  description = "Web ASG max"
  type        = number
}

variable "web_asg_desired" {
  description = "Web ASG desired"
  type        = number
}

variable "app_asg_min" {
  description = "App ASG min"
  type        = number
}

variable "app_asg_max" {
  description = "App ASG max"
  type        = number
}

variable "app_asg_desired" {
  description = "App ASG desired"
  type        = number
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_engine" {
  description = "DB engine"
  type        = string
}

variable "db_engine_version" {
  description = "DB engine version"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "bastion_allowed_cidr" {
  description = "Bastion allowed CIDR"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

