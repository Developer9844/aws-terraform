variable "instance_type" {}

variable "associate_public_ip_address" {
  default = true
}

variable "ami" {}

variable "key_name" {}

variable "availability_zone" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "subnet_ids" {
  type = list(string)
}

variable "sg_id" {}
