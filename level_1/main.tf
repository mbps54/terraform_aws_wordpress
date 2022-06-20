module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev-vpc"
  cidr = "10.1.0.0/16"

  azs              = ["eu-central-1a", "eu-central-1b"]
  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]
  database_subnets = ["10.1.201.0/24", "10.1.202.0/24"]

  #  create_database_subnet_group = true

  enable_ipv6 = false

  # Scenario: one NAT Gateway per availability zone
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    Name        = "dev-vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role" "s3_role" {
  name               = "s3_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "s3_profile" {
  name = "s3_instance_profile"
  role = aws_iam_role.s3_role.name
}

resource "aws_iam_role_policy" "s3_policy" {
  name   = "s3_iam_role_policy"
  role   = aws_iam_role.s3_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::aws-terraform-wordpress-backups-bucket"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::aws-terraform-wordpress-backups-bucket/*"]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "aws-terraform-wordpress-backups-bucket" {
  bucket = "aws-terraform-wordpress-backups-bucket"
}

resource "aws_s3_bucket_acl" "aws-terraform-wordpress-backups-bucket" {
  bucket = "aws-terraform-wordpress-backups-bucket"
  acl    = "private"
}
