variable "region" {
  type        = string
  description = "AWS Region where application being deployed"
  default     = "us-east-1"
}

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

variable "public_subnet_az1_cidr" {
  type        = string
  default     = "10.0.0.0/19"
  description = "Value of  Public CIDR for Availibility Zone 1"
}

variable "public_subnet_az2_cidr" {
  type        = string
  default     = "10.0.32.0/20"
  description = "Value of Public CIDR for Availibility Zone 2"
}

variable "public_subnet_az3_cidr" {
  type        = string
  default     = "10.0.48.0/20"
  description = "Value of Public CIDR for Availibility Zone 3"
}

variable "private_subnet_az1_cidr" {
  type        = string
  default     = "10.0.64.0/18"
  description = "Value of Private CIDR for Availibility Zone 1"
}

variable "private_subnet_az2_cidr" {
  type        = string
  default     = "10.0.128.0/18"
  description = "Value of Private CIDR for Availibility Zone 2"
}

variable "private_subnet_az3_cidr" {
  type        = string
  default     = "10.0.192.0/18"
  description = "Value of Private CIDR for Availibility Zone 3"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Provide True or False whethere you want to enable in VPC"
  default     = true
}
variable "instance_tags" {
  type        = map(string)
  description = "pass the key and value pair in maping string form example  {\"env\" = \"dev\", \"version\" = \"v2\"}"
  default     = {}
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Enter true or false to enable public ip address on EC2 instance"
  default     = false
}

variable "key_name" {
  type        = string
  description = "The name of the SSH key pair"
}
variable "aws_account_id" {
  description = "AWS Account id"
}

variable "desired_size" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 3
}

variable "max_size" {
  type    = number
  default = 3
}

variable "root_volume_size" {
  type    = string
  default = "10"
}
