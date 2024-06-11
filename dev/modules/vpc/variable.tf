variable "region" {}

variable "project_name" {}

variable "vpc_cidr" {}

variable "public_subnet_az1_cidr" {}

variable "public_subnet_az2_cidr" {}

variable "public_subnet_az3_cidr" {}

variable "private_subnet_az1_cidr" {}

variable "private_subnet_az2_cidr" {}

variable "private_subnet_az3_cidr" {}


variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}
