# -----------------------------------------------------------------------------
# Root main.tf — Orchestrates all modules for the 3-tier AWS architecture
# -----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source = "./modules/iam"

  project_name   = var.project_name
  environment    = var.environment
  app_bucket_arn = module.s3.app_bucket_arn
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
}

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  bastion_sg_id         = module.security_groups.bastion_sg_id
  key_pair_name         = var.key_pair_name
  instance_profile_name = module.iam.instance_profile_name
}

module "alb" {
  source = "./modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_app_subnet_ids     = module.vpc.private_app_subnet_ids
  web_alb_sg_id              = module.security_groups.web_alb_sg_id
  app_alb_sg_id              = module.security_groups.app_alb_sg_id
  enable_deletion_protection = var.enable_deletion_protection
}

module "autoscaling" {
  source = "./modules/autoscaling"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  webserver_sg_id        = module.security_groups.webserver_sg_id
  appserver_sg_id        = module.security_groups.appserver_sg_id
  web_target_group_arn   = module.alb.web_target_group_arn
  app_target_group_arn   = module.alb.app_target_group_arn
  web_instance_type      = var.web_instance_type
  app_instance_type      = var.app_instance_type
  web_asg_min            = var.web_asg_min
  web_asg_max            = var.web_asg_max
  web_asg_desired        = var.web_asg_desired
  app_asg_min            = var.app_asg_min
  app_asg_max            = var.app_asg_max
  app_asg_desired        = var.app_asg_desired
  key_pair_name          = var.key_pair_name
  instance_profile_name  = module.iam.instance_profile_name
  app_alb_dns_name       = module.alb.app_alb_dns_name
}

module "rds" {
  source = "./modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  private_db_subnet_ids      = module.vpc.private_db_subnet_ids
  database_sg_id             = module.security_groups.database_sg_id
  db_instance_class          = var.db_instance_class
  db_engine                  = var.db_engine
  db_engine_version          = var.db_engine_version
  db_name                    = var.db_name
  db_username                = var.db_username
  enable_deletion_protection = var.enable_deletion_protection
}

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.alb.web_alb_arn
  rate_limit   = var.waf_rate_limit
  enable_waf   = var.enable_waf
}


