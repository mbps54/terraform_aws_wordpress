output "rds_endpoint" {
  value = module.db.db_instance_endpoint
}

output "elb_dns_name" {
  value = module.elb.elb_dns_name
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
}
