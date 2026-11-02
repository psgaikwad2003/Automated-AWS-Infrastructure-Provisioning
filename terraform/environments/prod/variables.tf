variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "web_instance_type" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "web_asg_min" {
  type = number
}

variable "web_asg_max" {
  type = number
}

variable "web_asg_desired" {
  type = number
}

variable "app_asg_min" {
  type = number
}

variable "app_asg_max" {
  type = number
}

variable "app_asg_desired" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "key_pair_name" {
  type = string
}

variable "bastion_allowed_cidr" {
  type = string
}

variable "enable_deletion_protection" {
  type = bool
}

