project_name = "aws-infra"
environment  = "prod"
owner        = "devops-team"
aws_region   = "us-east-1"

# Networking (same CIDR — separate VPC from dev)
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.0.0/20", "10.0.16.0/20"]
private_app_subnet_cidrs = ["10.0.128.0/20", "10.0.144.0/20"]
private_db_subnet_cidrs  = ["10.0.160.0/20", "10.0.176.0/20"]
availability_zones       = ["us-east-1a", "us-east-1b"]

# Web Tier (production sizing)
web_instance_type = "t3.medium"
web_asg_min       = 2
web_asg_max       = 6
web_asg_desired   = 2

# App Tier (production sizing)
app_instance_type = "t3.large"
app_asg_min       = 2
app_asg_max       = 6
app_asg_desired   = 2

# Database (production sizing with larger instance)
db_instance_class = "db.t3.medium"
db_engine         = "mysql"
db_engine_version = "8.0"
db_name           = "appdb"
db_username       = "dbadmin"

# Access — RESTRICT bastion_allowed_cidr to your VPN/office IP!
key_pair_name              = "prod-keypair"
bastion_allowed_cidr       = "10.0.0.0/8" # Replace with your VPN/office CIDR
enable_deletion_protection = true

