variable "project" {
  description = "project"
  type        = string
}

variable "vpc_id" {
  description = "vpc_id"
  type        = string
}

variable "subnet_id" {
  description = "subnet_id"
  type        = list(any)
}
