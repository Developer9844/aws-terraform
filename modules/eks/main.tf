module "eksIAM" {
  source       = "./eks_iam"
  project_name = var.project_name

}

# EKS Cluster
resource "aws_eks_cluster" "eksCluster" {
  name     = "${var.project_name}-eks"
  role_arn = module.eksIAM.eks_cluster_role_arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_id]
  }
  depends_on = [module.eksIAM.eks_cluster_policy_attachment]
}


# EKS node group
resource "aws_eks_node_group" "eks_node_group" {
  node_group_name = var.node_group_name
  cluster_name    = aws_eks_cluster.eksCluster.name
  node_role_arn   = module.eksIAM.eks_nodegroup_role_arn
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
  depends_on = [module.eksIAM]
}

###############################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eksCluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = aws_eks_cluster.eksCluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates.0.sha1_fingerprint]
}
###################################################################################

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.eksCluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.44.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eksCluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  # addon_version               = "v1.19.2-eksbuild.3"
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

data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:karpenter"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
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

####################

resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${aws_eks_cluster.eksCluster.name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Sid      = "ConditionalEC2Termination"
        Effect   = "Allow"
        Action   = "ec2:TerminateInstances"
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid      = "PassNodeIAMRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::600748199510:role/eks_nodegroup_role"
      },
      {
        Sid      = "EKSClusterEndpointLookup"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${aws_eks_cluster.eksCluster.name}"
      },
      {
        Sid    = "AllowScopedInstanceProfileCreationActions"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.eksCluster.name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"                            = "${var.region}"
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"
        Action = [
          "iam:TagInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.eksCluster.name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"                            = "${var.region}"
            "aws:RequestTag/kubernetes.io/cluster/${aws_eks_cluster.eksCluster.name}"  = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"                             = "${var.region}"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.eksCluster.name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"                            = "${var.region}"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Action   = "iam:GetInstanceProfile"
        Resource = "*"
      }
    ]
  })
}




resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

################################################
resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = module.eksIAM.eks_nodegroup_role_name
}

#
##############################################

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eksCluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eksCluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["--profile", var.aws_profile, "eks", "get-token", "--cluster-name", aws_eks_cluster.eksCluster.name, "--region", "us-east-1"]
      command     = "aws"
    }
  }
}


resource "helm_release" "karpenter" {

  name             = "karpenter"
  namespace        = "kube-system"
  repository       = "oci://public.ecr.aws/karpenter/"
  chart            = "karpenter"
  version          = "1.5.0"
  create_namespace = false

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.eksCluster.name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.eksCluster.endpoint
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }


  depends_on = [aws_eks_node_group.eks_node_group]
}

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
