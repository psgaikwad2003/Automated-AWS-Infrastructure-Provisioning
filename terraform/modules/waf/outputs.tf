output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf && length(aws_wafv2_web_acl.main) > 0 ? aws_wafv2_web_acl.main[0].arn : null
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.enable_waf && length(aws_wafv2_web_acl.main) > 0 ? aws_wafv2_web_acl.main[0].id : null
}

output "web_acl_capacity" {
  description = "Web ACL capacity units (WCU) used"
  value       = var.enable_waf && length(aws_wafv2_web_acl.main) > 0 ? aws_wafv2_web_acl.main[0].capacity : null
}
