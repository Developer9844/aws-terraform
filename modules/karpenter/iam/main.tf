
data "aws_iam_policy_document" "KarpenterControllerAssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.aws_iam_openid_connect_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:karpenter"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [var.aws_iam_openid_connect_provider_arn]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  assume_role_policy = data.aws_iam_policy_document.KarpenterControllerAssumeRolePolicy.json
  name               = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  tags = {
    "Name" = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  }
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}


####################################################


resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${var.project_name}"
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
        Resource = "arn:aws:iam::600748199510:role/${var.project_name}-NodeGroup-Role"
      },
      {
        Sid      = "EKSClusterEndpointLookup"
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.project_name}"
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
            "aws:RequestTag/kubernetes.io/cluster/${var.project_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"             = "${var.region}"
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
            "aws:ResourceTag/kubernetes.io/cluster/${var.project_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = "${var.region}"
            "aws:RequestTag/kubernetes.io/cluster/${var.project_name}"  = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"              = "${var.region}"
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
            "aws:ResourceTag/kubernetes.io/cluster/${var.project_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = "${var.region}"
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

resource "aws_iam_instance_profile" "karpenterInstanceProfile" {
  name = "KarpenterNodeInstanceProfile"
  role = var.eks_nodegroup_role_name
}

output "karpenter_instance_profile_name" {
  value = aws_iam_instance_profile.karpenterInstanceProfile.name
}
