output "vpc_id" {
  description = "VPC id"
  value       = module.vpc.vpc_id
}

output "aws_availability_zones" {
  description = "A list of AWS availability zones"
  value       = module.vpc.azs
}

output "public_subnets_ids" {
  description = "A list of ids of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets_ids" {
  description = "A list of ids of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets_ids" {
  description = "A list of ids of database subnets"
  value       = module.vpc.database_subnets
}

output "public_subnets" {
  description = "A list of CIDRs of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  description = "A list of CIDRs of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "database_subnets" {
  description = "A list of CIDRs of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}
