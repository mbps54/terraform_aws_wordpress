variable "project" {
  description = "project"
  type        = string
}

variable "subnet_id" {
  description = "subnet_id"
  type        = list(any)
}

variable "security_group_id" {
  description = "security_group_id"
  type        = string
}

variable "target_group_arns" {
  description = "target_group_arns"
  type        = string
}
variable "aws_availability_zones" {
  description = "aws_availability_zones"
  type        = list(any)
}

variable "username" {
  description = "username"
  type        = string
}

variable "password" {
  description = "password"
  type        = string
}

variable "rds_endpoint" {
  type = string
}
