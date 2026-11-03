output "web_alb_arn" {
  description = "ARN of the external (web) ALB"
  value       = aws_lb.web.arn
}

output "web_alb_dns_name" {
  description = "DNS name of the external (web) ALB"
  value       = aws_lb.web.dns_name
}

output "web_alb_zone_id" {
  description = "Hosted zone ID of the external (web) ALB"
  value       = aws_lb.web.zone_id
}

output "web_target_group_arn" {
  description = "ARN of the web tier target group"
  value       = aws_lb_target_group.web.arn
}

output "web_alb_arn_suffix" {
  description = "ARN suffix of the external (web) ALB for CloudWatch metrics"
  value       = aws_lb.web.arn_suffix
}

output "web_target_group_arn_suffix" {
  description = "ARN suffix of the web target group for CloudWatch metrics"
  value       = aws_lb_target_group.web.arn_suffix
}

output "app_alb_arn" {
  description = "ARN of the internal (app) ALB"
  value       = aws_lb.app.arn
}

output "app_alb_dns_name" {
  description = "DNS name of the internal (app) ALB"
  value       = aws_lb.app.dns_name
}

output "app_alb_zone_id" {
  description = "Hosted zone ID of the internal (app) ALB"
  value       = aws_lb.app.zone_id
}

output "app_target_group_arn" {
  description = "ARN of the app tier target group"
  value       = aws_lb_target_group.app.arn
}

output "app_alb_arn_suffix" {
  description = "ARN suffix of the internal (app) ALB for CloudWatch metrics"
  value       = aws_lb.app.arn_suffix
}

output "app_target_group_arn_suffix" {
  description = "ARN suffix of the app target group for CloudWatch metrics"
  value       = aws_lb_target_group.app.arn_suffix
}


