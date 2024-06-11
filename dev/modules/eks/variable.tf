variable "project_name" {
  type = string
}

variable "module_name" {
  type = string
}

variable "subnet_ids" {}

variable "instance_type" {
  type = string
}

variable "desired_size" {
  type    = number
  default = 4
}

variable "min_size" {
  type    = number
  default = 4
}

variable "max_size" {
  type    = number
  default = 4
}

variable "usage_label" {
  type = string
}

variable "eks_version" {

}
