# 1. VPC Module
module "vpc" {
  source      = "../../../modules/aws/vpc"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

# 2. Security Groups Module
module "security_groups" {
  source      = "../../../modules/aws/security_group"
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
  environment = var.environment
}

# 3. EC2 Module
module "ec2" {
  source            = "../../../modules/aws/ec2"
  subnet_id         = module.vpc.private_subnet_a_id
  security_group_id = module.security_groups.ec2_security_group_id
  instance_type     = var.instance_type
  environment       = var.environment
}

# 4. ALB Module
module "alb" {
  source                = "../../../modules/aws/alb"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  target_ec2_id         = module.ec2.instance_id
  environment           = var.environment
}