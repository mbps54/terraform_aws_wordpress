variable "public_cidr" {
  type        = list(any)
}

variable "private_cidr" {
  type        = list(any)
}

variable "admin_addresses" {
  type        = list(any)
}

variable "project" {
  type        = string
}
