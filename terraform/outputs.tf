output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public (web tier) subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private application tier subnets"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the private database tier subnets"
  value       = module.vpc.private_db_subnet_ids
}

output "web_alb_dns_name" {
  description = "DNS name of the external (web) Application Load Balancer"
  value       = module.alb.web_alb_dns_name
}

output "app_alb_dns_name" {
  description = "DNS name of the internal (app) Application Load Balancer"
  value       = module.alb.app_alb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.ec2.bastion_public_ip
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = module.autoscaling.web_asg_name
}

output "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = module.autoscaling.app_asg_name
}

output "s3_app_bucket_name" {
  description = "Name of the S3 bucket for application assets"
  value       = module.s3.app_bucket_name
}

output "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  value       = module.iam.instance_profile_name
}

