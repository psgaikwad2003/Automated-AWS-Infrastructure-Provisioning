variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to associate with WAF"
  type        = string
}

variable "rate_limit" {
  description = "Maximum number of requests permitted from a single IP in a 5-minute period"
  type        = number
  default     = 2000
}

variable "enable_waf" {
  description = "Flag to enable or disable WAF Web ACL creation"
  type        = bool
  default     = true
}
