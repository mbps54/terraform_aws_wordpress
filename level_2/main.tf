data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "creds"
}

locals {
  db_creds             = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
  project              = "terraform-aws-wordpress"
  vpc_id               = data.terraform_remote_state.level1.outputs.vpc_id
  public_subnets       = data.terraform_remote_state.level1.outputs.public_subnets
  private_subnets      = data.terraform_remote_state.level1.outputs.private_subnets
  database_subnets     = data.terraform_remote_state.level1.outputs.database_subnets
  public_subnets_ids   = data.terraform_remote_state.level1.outputs.public_subnets_ids
  private_subnets_ids  = data.terraform_remote_state.level1.outputs.private_subnets_ids
  database_subnets_ids = data.terraform_remote_state.level1.outputs.database_subnets_ids
  vailability_zones    = data.terraform_remote_state.level1.outputs.aws_availability_zones
}

module "sg_mysql" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_mysql"
  description = "Security group for MySQL servers"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow only TCP/3306 inbound traffic"
      cidr_blocks = join(",", local.private_subnets)
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "databasemysql"

  engine            = "mysql"
  engine_version    = "5.7.25"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  storage_encrypted = false

  db_name  = "databasemysql"
  username = local.db_creds.username
  password = local.db_creds.password
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [module.sg_mysql.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = local.database_subnets_ids

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false
}

module "sg_ec2" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_ec2"
  description = "Security group for EC2 instances"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH inbound traffic from bastion"
      cidr_blocks = join(",", local.public_subnets)
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP inbound traffic from any"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "sg_alb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_alb"
  description = "Security group for load balancer"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP inbound traffic from any"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS inbound traffic from any"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "sg_bastion" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_bastion"
  description = "Security group for bastion server"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP inbound traffic from any"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH inbound traffic from any"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "alb" {
  source            = "../modules/alb"
  project           = local.project
  vpc_id            = local.vpc_id
  subnet_id         = local.public_subnets_ids
  security_group_id = module.sg_alb.security_group_id
}

module "asg" {
  source                 = "../modules/asg"
  project                = local.project
  subnet_id              = local.private_subnets_ids
  aws_availability_zones = local.vailability_zones
  target_group_arns      = module.alb.target_group_arns
  username               = local.db_creds.username
  password               = local.db_creds.password
  rds_endpoint           = module.db.db_instance_endpoint
  security_group_id      = module.sg_ec2.security_group_id
}

module "bastion" {
  source            = "../modules/ec2"
  project           = local.project
  subnet_id         = local.public_subnets_ids[0]
  security_group_id = module.sg_bastion.security_group_id
}
