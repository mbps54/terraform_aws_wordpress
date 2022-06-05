variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "private_subnet_id" {
  type = list(any)
}

variable "vpc_id" {
  type = string
}
