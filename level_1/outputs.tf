output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_availability_zones" {
  value = module.vpc.azs
}

output "public_subnets_ids" {
  value = module.vpc.public_subnets
}

output "private_subnets_ids" {
  value = module.vpc.private_subnets
}

output "database_subnets_ids" {
  value = module.vpc.database_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "database_subnets" {
  value = module.vpc.database_subnets_cidr_blocks
}
