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

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
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

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
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

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "sg_asg" {
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

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
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

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

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
  create_db_subnet_group = false
  subnet_ids             = local.database_subnets_ids

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_launch_configuration" "launch-config-1" {
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  security_groups             = [var.security_group_id]
  associate_public_ip_address = false
  key_name                    = "my-key-pair-1"
  user_data = templatefile("${path.module}/startup.tpl",
    { username     = local.db_creds.username,
      password     = local.db_creds.password,
      rds_endpoint = data.db.db_instance_id})

  lifecycle {
    create_before_destroy = true
  }
}

#######################     EVERYTHING IS BAD BELOW    ########################

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${local.project}-asg"

  launch_configuration = "launch-config-1"

  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [module.sg_asg.security_group_id]
  load_balancers  = [module.elb.elb_id]

  # Auto scaling group
  asg_name                  = "${local.project}-asg"
  vpc_zone_identifier       = local.private_subnets_ids
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "${local.project}-elb"

  subnets         = local.private_subnets_ids
  security_groups = [module.sg_asg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
