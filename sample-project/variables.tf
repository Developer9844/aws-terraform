variable "region" {}
variable "region_name" {}
variable "project_name" {}
variable "aws_account_id" {}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zone" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "az_public_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_ip" {
  type    = bool
  default = true
}

variable "az_private_cidr" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

# variables for SSH key
variable "key_name" {}

# variables for ec2 instace

variable "instance_type" {}
variable "associate_public_ip_address" {
  default = true
}

variable "ami" {}




# variable "private_subnet_ids" {}
variable "instance_types" {
  default = "t3.medium"
}

variable "node_group_name" {
  default = "demo_node_group"
}
# variable "sg_id" {}

variable "cluster_name" {}

variable "aws_profile" {}
variable "ingress_rules" {}
