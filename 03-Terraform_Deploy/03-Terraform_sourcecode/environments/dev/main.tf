# ---
# config
# ---
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

# ---
# Variables config
# ---
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

# ---
# Network
# ---
module "network" {
  source = "../../modules/network"

  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr_block  = var.vpc_cidr_block
  AZ_1            = var.AZ_1
  AZ_1_publicsub  = var.AZ_1_publicsub
  AZ_1_privatesub = var.AZ_1_privatesub
  AZ_2            = var.AZ_2
  AZ_2_publicsub  = var.AZ_2_publicsub
  AZ_2_privatesub = var.AZ_2_privatesub
}

# ---
# Alb
# ---
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment
  region      = var.region

  web_sg_id         = module.security.web_sg_id
  alb_sg_id         = module.security.alb_sg_id
  vpc_id            = module.network.vpc_id
  public_subnet_1a  = module.network.public_subnet_1a
  public_subnet_1c  = module.network.public_subnet_1c
  private_subnet_1a = module.network.private_subnet_1a
  private_subnet_1c = module.network.private_subnet_1c
  web_server_id     = module.compute.web_server_id
}

# ---
# Security
# ---
module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment
  region      = var.region

  ALB_from_IP = var.ALB_from_IP

  vpc_id = module.network.vpc_id
}

# ---
# Compute
# ---
module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  region      = var.region

  appsv_instance_type = var.appsv_instance_type
  app_sv_ami          = var.app_sv_ami
  websv_instance_type = var.websv_instance_type
  web_sv_ami          = var.web_sv_ami

  public_subnet_1a  = module.network.public_subnet_1a
  private_subnet_1a = module.network.private_subnet_1a
  app_sg_id         = module.security.app_sg_id
  web_sg_id         = module.security.web_sg_id
  ec2_profile_name  = module.iam.ec2_profile_name
}

# ---
# RDS
# ---
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment
  region      = var.region

  rds_instance_class  = var.rds_instance_class
  rds_username        = var.rds_username
  rds_az_none_multiaz = var.rds_az_none_multiaz
  rds_db_name         = var.rds_db_name

  private_subnet_1a = module.network.private_subnet_1a
  private_subnet_1c = module.network.private_subnet_1c
  rds_sg_id         = module.security.rds_sg_id
}


# ---
# IAM
# ---
module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
  region      = var.region
}

# ---
# Route53
# ---
module "Route53" {
  source = "../../modules/route53"

  project     = var.project
  environment = var.environment
  region      = var.region

  private_host_zone = var.private_host_zone

  vpc_id                    = module.network.vpc_id
  appsv_instance_private_ip = module.compute.appsv_instance_private_ip
}

