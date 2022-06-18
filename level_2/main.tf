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
      cidr_blocks = join(",", local.private_subnets, local.public_subnets)
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

module "sg_elb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sg_elb"
  description = "Security group for elb"
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

  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.sg_mysql.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  create_db_subnet_group = true
  subnet_ids             = local.database_subnets_ids
  skip_final_snapshot    = true

  family               = "mysql5.7"
  major_engine_version = "5.7"
  deletion_protection  = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.nano"
  subnet_id                   = local.public_subnets_ids[0]
  vpc_security_group_ids      = [module.sg_bastion.security_group_id]
  associate_public_ip_address = true
  key_name                    = "wordpress"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_launch_template" "wordpress" {
  name          = "wordpress"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.sg_ec2.security_group_id]
  }

  key_name = "wordpress"

  user_data = base64encode(templatefile("startup.tpl",
    { username = local.db_creds.username,
      password = local.db_creds.password,
  rds_endpoint = module.db.db_instance_endpoint }))

  lifecycle {
    create_before_destroy = true
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "${local.project}-asg"

  create_launch_template = false
  launch_template        = aws_launch_template.wordpress.name

  load_balancers = [module.elb.elb_id]

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

  depends_on = [module.db]

}

module "elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "${local.project}-elb"

  subnets         = local.public_subnets_ids
  security_groups = [module.sg_elb.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
    {
      instance_port      = 80
      instance_protocol  = "http"
      lb_port            = 443
      lb_protocol        = "https"
      ssl_certificate_id = aws_acm_certificate.default.arn
    },
  ]

  health_check = {
    target              = "TCP:80"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_acm_certificate" "default" {
  domain_name       = "tasucu.click"
  validation_method = "DNS"
}

data "aws_route53_zone" "external" {
  name = "tasucu.click"
}

resource "aws_route53_record" "validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.external.zone_id
  records         = [tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_value]
  ttl             = "60"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = aws_acm_certificate.default.arn

  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}

resource "aws_route53_record" "tasucu_click" {
  zone_id = "Z0864870176T1RW93BUL9"
  name    = "tasucu.click"
  type    = "A"

  alias {
    name                   = module.elb.elb_dns_name
    zone_id                = module.elb.elb_zone_id
    evaluate_target_health = true
  }
}
