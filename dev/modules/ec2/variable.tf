variable "ami" {
  type        = string
  description = "Enter ami id for your instance"

}

variable "type" {
  type        = string
  description = "Enter instance type family"
}

variable "keyname" {
  type        = string
  description = "Enter the KeyPair name for ec2 instance"
}

variable "security_groups" {
  type = list(string)
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Enter true or false"
}

variable "instance_tags" {
  type        = map(string)
  description = "pass the key and value pair in maping string form example  {\"env\" = \"dev\", \"version\" = \"v2\"}"
}

variable "vpc_id" {
}

variable "subnets" {
}
variable "project_name" {
  type = string
}

variable "module_name" {
  type = string
}
variable "instance_use" {
  type = string
}

variable "additional_volumes" {
  description = "Additional EBS volumes to attach to the instance"
  type = map(object({
    volume_size           = number
    volume_type           = string
    encrypted             = bool
    delete_on_termination = bool
  }))
  default = null
}

variable "extra_ebs" {
  description = "Flag to indicate whether to attach additional EBS volumes"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  type = string
}
