################################################################
# EKS Cluster
################################################################

resource "aws_eks_cluster" "eksCluster" {
  name     = var.project_name
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_id]
  }
}

################################################################
# EKS node group
################################################################

resource "aws_eks_node_group" "eksNodeGroup" {
  node_group_name = var.node_group_name
  cluster_name    = aws_eks_cluster.eksCluster.name
  node_role_arn   = var.eks_nodegroup_role_arn
  subnet_ids      = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
  capacity_type   = "ON_DEMAND"
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
}

###############################################################
#
###############################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eksCluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = aws_eks_cluster.eksCluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates.0.sha1_fingerprint]
}

############################################################################
#
############################################################################

resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = aws_eks_cluster.eksCluster.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.44.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eksCluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  # addon_version               = "v1.19.5-eksbuild.1"
}


###################################################################################
#
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
  name               = "Addons-IAM-Role"
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
