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
    Name = "dev-vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}
