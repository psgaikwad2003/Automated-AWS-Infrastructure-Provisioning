variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner team or person responsible for the infrastructure"
  type        = string
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public (web tier) subnets"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application tier subnets"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database tier subnets"
  type        = list(string)
  default     = ["10.0.160.0/20", "10.0.176.0/20"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ---------------------------------------------------------------------------
# Compute – Web Tier
# ---------------------------------------------------------------------------

variable "web_instance_type" {
  description = "EC2 instance type for the web tier"
  type        = string
  default     = "t3.micro"
}

variable "web_asg_min" {
  description = "Minimum number of instances in the web Auto Scaling Group"
  type        = number
  default     = 1
}

variable "web_asg_max" {
  description = "Maximum number of instances in the web Auto Scaling Group"
  type        = number
  default     = 3
}

variable "web_asg_desired" {
  description = "Desired number of instances in the web Auto Scaling Group"
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# Compute – App Tier
# ---------------------------------------------------------------------------

variable "app_instance_type" {
  description = "EC2 instance type for the application tier"
  type        = string
  default     = "t3.micro"
}

variable "app_asg_min" {
  description = "Minimum number of instances in the app Auto Scaling Group"
  type        = number
  default     = 1
}

variable "app_asg_max" {
  description = "Maximum number of instances in the app Auto Scaling Group"
  type        = number
  default     = 3
}

variable "app_asg_desired" {
  description = "Desired number of instances in the app Auto Scaling Group"
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine (mysql or postgres)"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

# ---------------------------------------------------------------------------
# Access
# ---------------------------------------------------------------------------

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB and RDS (set true for prod)"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# WAF Security
# ---------------------------------------------------------------------------

variable "enable_waf" {
  description = "Enable AWS WAFv2 Web ACL on external ALB"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "WAF IP rate limit (requests per 5 minutes)"
  type        = number
  default     = 2000
}

# ---------------------------------------------------------------------------
# Monitoring & Alerting
# ---------------------------------------------------------------------------

variable "alert_email" {
  description = "Optional email address for critical SNS alarm notifications"
  type        = string
  default     = ""
}



