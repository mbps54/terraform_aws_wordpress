output "public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Bastion server public IP"
}
