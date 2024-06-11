variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "module_name" {
  type = string
}

variable "description" {
  type = string
}

variable "ingress_access" {
  description = "List of maps containing CIDR blocks and corresponding ports for ingress access"
  type = list(object({
    cidr_blocks = list(string)
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

variable "egress_access" {
  description = "List of maps containing CIDR blocks and corresponding ports for egress access"
  type = list(object({
    cidr_blocks = list(string)
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}
