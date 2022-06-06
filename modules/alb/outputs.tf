output "target_group_arns" {
  value = aws_lb_target_group.target-group-1.arn
}

output "aws_lb_dns_name" {
  value       = aws_lb.alb-1.dns_name
}
