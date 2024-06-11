variable "project_name" {
  type = string
}

variable "module_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
variable "node_role_arn" {}

variable "desired_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "min_size" {
  type = number
}

variable "instance_type" {
  type = list(string)
}


variable "usage_label" {}
