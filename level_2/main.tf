data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "creds"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
  project  = "terraform-aws-wordpress"
}

module "db" {
  source            = "../modules/db"
  vpc_id            = data.terraform_remote_state.level1.outputs.vpc_id
  private_subnet_id = data.terraform_remote_state.level1.outputs.private_subnet_id
  username          = local.db_creds.username
  password          = local.db_creds.password
}

module "alb" {
  source    = "../modules/alb"
  project   = local.project
  vpc_id    = data.terraform_remote_state.level1.outputs.vpc_id
  subnet_id = data.terraform_remote_state.level1.outputs.public_subnet_id
}

module "asg" {
  source                 = "../modules/asg"
  project                = local.project
  subnet_id              = data.terraform_remote_state.level1.outputs.private_subnet_id
  security_group_id      = data.terraform_remote_state.level1.outputs.aws_security_group_sg1_id
  aws_availability_zones = data.terraform_remote_state.level1.outputs.aws_availability_zones
  target_group_arns      = module.alb.target_group_arns
  username               = local.db_creds.username
  password               = local.db_creds.password
  rds_endpoint           = module.db.rds_endpoint
}

module "bastion" {
  source            = "../modules/ec2"
  project           = local.project
  subnet_id         = data.terraform_remote_state.level1.outputs.public_subnet_id[0]
  security_group_id = data.terraform_remote_state.level1.outputs.aws_security_group_sg1_id
}
