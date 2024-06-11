terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

module "eks_cluster_role" {
  source       = "./iam"
  project_name = var.project_name
  module_name  = "dev_eks_cluster_role"
}

module "spot_instance_nodegroup" {
  source        = "./node_group"
  project_name  = var.project_name
  module_name   = "dev_eks_node_role"
  cluster_name  = aws_eks_cluster.smackdab_dev.name
  node_role_arn = module.eks_cluster_role.node_role
  instance_type = [var.instance_type]
  desired_size  = var.desired_size
  min_size      = var.min_size
  max_size      = var.max_size
  subnet_ids    = var.subnet_ids
  usage_label   = var.usage_label
}


resource "aws_eks_cluster" "smackdab_dev" {
  name     = "${var.project_name}_cluster"
  role_arn = module.eks_cluster_role.eks_cluster_role
  version  = var.eks_version
  vpc_config {
    subnet_ids = var.subnet_ids
  }
  depends_on = [module.eks_cluster_role]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = aws_eks_cluster.smackdab_dev.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.30.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.smackdab_dev.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  addon_version               = "v1.18.1-eksbuild.3"
}

data "tls_certificate" "smackdab_dev" {
  url = aws_eks_cluster.smackdab_dev.identity.0.oidc.0.issuer
}
resource "aws_iam_openid_connect_provider" "smackdab_dev_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.smackdab_dev.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.smackdab_dev.identity.0.oidc.0.issuer
}
