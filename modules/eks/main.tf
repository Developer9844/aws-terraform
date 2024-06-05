terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

module "eks_iam" {
  source       = "./eks_iam"
  project_name = var.project_name

}


resource "aws_eks_cluster" "demo_cluster" {
  name     = "eks"
  role_arn = module.eks_iam.eks_cluster_role_arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_id]
  }
  depends_on = [module.eks_iam]
}


#EKS node group
resource "aws_eks_node_group" "eks_node_group" {
  node_group_name = var.node_group_name
  cluster_name    = aws_eks_cluster.demo_cluster.name
  node_role_arn   = module.eks_iam.eks_nodegroup_role_arn
  subnet_ids      = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
  capacity_type   = "SPOT"
  instance_types  = [var.instance_types]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }
  depends_on = [module.eks_iam]
  lifecycle {
    create_before_destroy = true
  }
}


data "tls_certificate" "eks" {
  url = aws_eks_cluster.demo_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = aws_eks_cluster.demo_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates.0.sha1_fingerprint]
}


#
###########################

data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
  name               = "karpenter-controller"
}

resource "aws_iam_policy" "karpenter_controller" {
  policy = file("~/Downloads/terraform/modules/eks/controller-policy.json")
  name   = "KarpenterController"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = module.eks_iam.eks_nodegroup_role_name
}
#
##############################################

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.demo_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.demo_cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["--profile", "my_personal_aws", "eks", "get-token", "--cluster-name", aws_eks_cluster.demo_cluster.name, "--region", "us-east-1"]
      command     = "aws"
    }
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.13.1"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.demo_cluster.id
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.demo_cluster.endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [aws_eks_node_group.eks_node_group]
}

#
##########################################################################
