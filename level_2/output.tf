#output "DB_secret_password" {
#  value     = local.db_creds
#  sensitive = true
#}
#
#output "rds_endpoint" {
#  value = module.db.rds_endpoint
#}
#
#output "alb_dns_name" {
#  value       = module.alb.aws_lb_dns_name
#  description = "The domain name of the load balancer"
#}
#
#output "bastion_public_ip" {
#  value       = module.bastion.public_ip
#  description = "Bastion server public IP"
#}
