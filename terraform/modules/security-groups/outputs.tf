output "bastion_sg_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion.id
}

output "web_alb_sg_id" {
  description = "ID of the external ALB security group"
  value       = aws_security_group.web_alb.id
}

output "webserver_sg_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.webserver.id
}

output "app_alb_sg_id" {
  description = "ID of the internal ALB security group"
  value       = aws_security_group.app_alb.id
}

output "appserver_sg_id" {
  description = "ID of the application server security group"
  value       = aws_security_group.appserver.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

