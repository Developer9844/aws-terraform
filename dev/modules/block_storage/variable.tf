variable "availability_zone" {}

variable "instance_id" {}

variable "volume_size" {
  type = number
}

variable "volume_type" {
  default = "gp3"
}

variable "project_name" {
  type = string
}

variable "final_snapshot" {
  type    = bool
  default = true
}
