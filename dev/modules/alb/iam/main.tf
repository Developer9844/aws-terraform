data "aws_eks_cluster" "oidc_url" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_state]
}

data "aws_eks_cluster" "oidc_arn" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_state]
}

data "aws_iam_openid_connect_provider" "dev_provider" {
  url = data.aws_eks_cluster.oidc_arn.identity.0.oidc.0.issuer
}

output "eks_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.dev_provider.arn
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.project_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "Policy for ALB Controller"
  tags = {
    Name = "${var.project_name}-AWSLoadBalancerControllerIAMPolicy"
  }
  policy = file("./alb_controllerpolicy.json")
}


resource "aws_iam_role" "eks_alb_controller_role" {
  name               = "${var.project_name}_AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_alb_iam_role_policy.json
  tags = {
    "Name" = "${var.project_name}_AmazonEKSLoadBalancerControllerRole"
  }
}

data "aws_iam_policy_document" "eks_cluster_alb_iam_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.dev_provider.arn]
      type        = "Federated"
    }
  }
}

//------------------------------------------------------------------------------------------
#Attach ALB CONTROLLER Policy to Above Role
resource "aws_iam_role_policy_attachment" "attach_ebs_csi_policy" {
  role       = aws_iam_role.eks_alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn

  depends_on = [
    aws_iam_role.eks_alb_controller_role,
    aws_iam_policy.alb_controller_policy
  ]
}
//------------------------------------------------------------------------------------------
#Create Service Account for aws-load-balancer-controller
resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
      "app"                         = "${var.project_name}"

    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_alb_controller_role.arn
    }
  }
}
