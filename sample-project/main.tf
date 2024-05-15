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

module "ec2_instance" {
  source        = "../modules/ec2"
  instance_type = var.instance_type
  ami           = var.ami
  key_name      = var.key_name
  subnet_ids    = module.vpc_demo.subnet_ids
  sg_id         = module.vpc_demo.sg_id
}



module "eks_cluster" {
  source             = "../modules/eks"
  node_group_name    = var.node_group_name
  private_subnet_ids = module.vpc_demo.private_subnet_ids
  sg_id              = module.vpc_demo.sg_id
}
