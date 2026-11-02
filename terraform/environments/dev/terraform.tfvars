project_name = "aws-infra"
environment  = "dev"
owner        = "devops-team"
aws_region   = "us-east-1"

# Networking
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.0.0/20", "10.0.16.0/20"]
private_app_subnet_cidrs = ["10.0.128.0/20", "10.0.144.0/20"]
private_db_subnet_cidrs  = ["10.0.160.0/20", "10.0.176.0/20"]
availability_zones       = ["us-east-1a", "us-east-1b"]

# Web Tier (small for dev)
web_instance_type = "t3.micro"
web_asg_min       = 1
web_asg_max       = 3
web_asg_desired   = 1

# App Tier (small for dev)
app_instance_type = "t3.micro"
app_asg_min       = 1
app_asg_max       = 3
app_asg_desired   = 1

# Database (small for dev)
db_instance_class = "db.t3.micro"
db_engine         = "mysql"
db_engine_version = "8.0"
db_name           = "appdb"
db_username       = "dbadmin"

# Access
key_pair_name              = "dev-keypair"
bastion_allowed_cidr       = "0.0.0.0/0" # Restrict to your IP in production!
enable_deletion_protection = false

