#create vpc module

module "vpc_demo" {
  source          = "../modules/vpc"
  cluster_name    = var.cluster_name
  region          = var.region
  project_name    = var.project_name
  cidr_block      = var.cidr_block
  az_public_cidr  = var.az_public_cidr
  az_private_cidr = var.az_private_cidr
  ingress_rules   = var.ingress_rules

}

# module "ssh_key" {
#   source   = "../modules/ssh_key"
#   key_name = var.key_name
# }

# module "ec2_instance" {
#   source        = "../modules/ec2"
#   instance_type = var.instance_type
#   ami           = var.ami
#   key_name      = var.key_name
#   subnet_ids    = module.vpc_demo.subnet_ids
#   sg_id         = module.vpc_demo.sg_id
# }

module "iam" {
  source       = "../modules/iam"
  project_name = var.project_name
}

module "eks_cluster" {
  source                 = "../modules/eks"
  region                 = var.region
  instance_types         = var.instance_types
  aws_profile            = var.aws_profile
  aws_account_id         = var.aws_account_id
  eks_cluster_role_arn   = module.iam.eks_cluster_role_arn
  eks_nodegroup_role_arn = module.iam.eks_nodegroup_role_arn
  project_name           = var.project_name
  private_subnet_ids     = module.vpc_demo.private_subnet_ids
  node_group_name        = var.node_group_name
  sg_id                  = module.vpc_demo.sg_id
}


provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["--profile", var.aws_profile, "eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_name, "--region", "us-east-1"]
      command     = "aws"
    }
  }
}

module "karpenter" {
  source                              = "../modules/karpenter"
  project_name                        = var.project_name
  aws_profile                         = var.aws_profile
  aws_account_id                      = var.aws_account_id
  region                              = var.region
  eks_cluster_name                    = module.eks_cluster.eks_cluster_name
  eks_cluster_endpoint                = module.eks_cluster.eks_cluster_endpoint
  aws_iam_openid_connect_provider_arn = module.eks_cluster.aws_iam_openid_connect_provider_arn
  aws_iam_openid_connect_provider_url = module.eks_cluster.aws_iam_openid_connect_provider_url
  cluster_ca_certificate              = module.eks_cluster.cluster_ca_certificate
  eks_nodegroup_role_name             = module.iam.eks_nodegroup_role_name

  depends_on = [ module.eks_cluster ]
}
