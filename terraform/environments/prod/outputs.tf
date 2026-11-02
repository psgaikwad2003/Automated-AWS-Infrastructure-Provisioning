output "vpc_id" {
  description = "VPC ID"
  value       = module.infrastructure.vpc_id
}

output "web_alb_dns_name" {
  description = "Web ALB DNS name"
  value       = module.infrastructure.web_alb_dns_name
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = module.infrastructure.bastion_public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.infrastructure.rds_endpoint
  sensitive   = true
}

