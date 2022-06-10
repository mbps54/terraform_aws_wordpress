variable "project" {
  type        = string
}

variable "subnet_id" {
  type        = list(any)
}

variable "security_group_id" {
  type        = string
}

variable "target_group_arns" {
  type        = string
}
variable "aws_availability_zones" {
  type        = list(any)
}

variable "username" {
  type        = string
}

variable "password" {
  type        = string
}

variable "rds_endpoint" {
  type = string
}
