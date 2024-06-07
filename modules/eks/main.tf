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
  depends_on = [module.eks_iam.eks_cluster_policy_attachment]
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
  update_config {
    max_unavailable = 1
  }
  labels = {
    role = "general"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [module.eks_iam]
}

###############################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.demo_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = aws_eks_cluster.demo_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates.0.sha1_fingerprint]
}
###################################################################################

resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = aws_eks_cluster.demo_cluster.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.31.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.demo_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  addon_version               = "v1.18.1-eksbuild.3"
}


###################################################################################

data "aws_iam_policy_document" "addons_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "addons_role" {
  assume_role_policy = data.aws_iam_policy_document.addons_assume_role_policy.json
  name               = "vpc-cni-role"
}

resource "aws_iam_role_policy_attachment" "vpc_cni_role_policy_attachement" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.addons_role.name
}

resource "aws_iam_role_policy_attachment" "ebs_driver_role_policy_attachement" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.addons_role.name
}


#
####################################################

data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["sts.amazonaws.com"]
    }

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
  name               = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  tags = {
    "Name" = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  }
}

resource "aws_iam_policy" "karpenter_controller_role_policy" {
  policy = file("~/Downloads/terraform/modules/eks/controller-policy.json")
  name   = "KarpenterControllerRolePolicy"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_role_policy.arn
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
      args        = ["--profile", var.aws_profile, "eks", "get-token", "--cluster-name", aws_eks_cluster.demo_cluster.name, "--region", "us-east-1"]
      command     = "aws"
    }
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter/"
  chart      = "karpenter"
  version    = "0.36.0"


  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.demo_cluster.name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.demo_cluster.endpoint
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [aws_eks_node_group.eks_node_group]
}

#
##########################################################################

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# resource "kubernetes_manifest" "karpenter_nodepools" {
#   manifest = yamldecode(file("${path.module}/karpenter.sh_nodepools.yaml"))
# }

# resource "kubernetes_manifest" "karpenter_ec2nodeclasses" {
#   manifest = yamldecode(file("${path.module}/karpenter.k8s.aws_ec2nodeclasses.yaml"))
# }

# resource "kubernetes_manifest" "karpenter_nodeclaims" {
#   manifest = yamldecode(file("${path.module}/karpenter.sh_nodeclaims.yaml"))
# }

# resource "kubernetes_manifest" "karpenter" {
#   manifest = yamldecode(file("${path.module}/karpenter.yaml"))
# }
