#create vpc module

module "vpc_demo" {
  source          = "../modules/vpc"
  region          = var.region
  project_name    = var.project_name
  cidr_block      = var.cidr_block
  az_public_cidr  = var.az_public_cidr
  az_private_cidr = var.az_private_cidr
}

module "ssh_key" {
  source   = "../modules/ssh_key"
  key_name = var.key_name
}

