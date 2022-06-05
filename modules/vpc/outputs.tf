output "public_subnet_id" {
  value = aws_subnet.public.*.id
}


output "private_subnet_id" {
  value = aws_subnet.private.*.id
}


output "aws_security_group_sg1_id" {
  value = aws_security_group.sg1.id
}


output "vpc_id" {
  value = aws_vpc.main.id
}


output "aws_availability_zones" {
  value = tolist(data.aws_availability_zones.available.names)
}
