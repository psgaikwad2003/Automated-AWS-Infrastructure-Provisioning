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

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
  default     = "0.0.0.0/0"
}

