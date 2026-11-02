variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for the bastion host"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
}

