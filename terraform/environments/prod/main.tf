# -----------------------------------------------------------------------------
# Prod Environment — calls the root Terraform module with production settings
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket" # Set via bootstrap.sh
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

module "infrastructure" {
  source = "../../"

  # Core
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
  aws_region   = var.aws_region

  # Networking
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones

  # Compute
  web_instance_type = var.web_instance_type
  app_instance_type = var.app_instance_type
  web_asg_min       = var.web_asg_min
  web_asg_max       = var.web_asg_max
  web_asg_desired   = var.web_asg_desired
  app_asg_min       = var.app_asg_min
  app_asg_max       = var.app_asg_max
  app_asg_desired   = var.app_asg_desired

  # Database
  db_instance_class = var.db_instance_class
  db_engine         = var.db_engine
  db_engine_version = var.db_engine_version
  db_name           = var.db_name
  db_username       = var.db_username

  # Access
  key_pair_name              = var.key_pair_name
  bastion_allowed_cidr       = var.bastion_allowed_cidr
  enable_deletion_protection = var.enable_deletion_protection
}

