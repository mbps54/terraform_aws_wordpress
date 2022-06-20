output "rds_endpoint" {
  description = "RDS endpoint hostname and port number"
  value       = module.db.db_instance_endpoint
}

output "elb_dns_name" {
  description = "ELB DNS name"
  value       = module.elb.elb_dns_name
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}
