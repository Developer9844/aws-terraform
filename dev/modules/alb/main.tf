//------------------------------------------------------------------------------------------
#Deploying aws_load-balancer-controller in cluster

module "alb_controller_policy" {
  source        = "./iam"
  project_name  = var.project_name
  cluster_name  = var.cluster_name
  cluster_state = var.cluster_state
}

resource "helm_release" "aws_load-balancer-controller" {
  name       = "${var.project_name}-aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    module.alb_controller_policy
  ]

  set {
    name  = "clusterName"
    value = var.project_name
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "image.repository"
    value = format("602401143452.dkr.ecr.%s.amazonaws.com/amazon/aws-load-balancer-controller", var.region)
  }
}
