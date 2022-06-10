output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_security_group_sg1_id" {
  value = module.vpc.aws_security_group_sg1_id
}

output "aws_availability_zones" {
  value = module.vpc.aws_availability_zones
}
