variable "private_subnet_ids" {}
variable "instance_types" {
  default = "t3.medium"
}

variable "node_group_name" {
  default = "demo_node_group"
}
variable "sg_id" {}



