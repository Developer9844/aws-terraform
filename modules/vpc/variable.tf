variable "region" {}
variable "project_name" {}

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

variable "cluster_name" {}


variable "ingress_rules" {
  description = "Map of ingress rules to create"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}
