#Fetch EKS OIDC Data
data "aws_eks_cluster" "oidc_url" {
  name = "eks"
}

data "aws_eks_cluster" "eks_cluster_name" {
  name = "eks"
}

# data "aws_eks_cluster" "securitygroup" {
#   name       = "${var.project_name}_cluster"
#   depends_on = [var.cluster_name]
# }
output "eks_cluster_endpoint" {
  value = data.aws_eks_cluster.eks_cluster_name.endpoint
}

output "oidc_provider_url" {
  value = data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer
}

data "aws_eks_cluster" "oidc_arn" {
  name       = "eks"
  depends_on = [var.cluster_name]
}

data "aws_eks_cluster" "demo_cluster" {
  name = "eks"
}

data "aws_eks_cluster_auth" "demo_cluster" {
  name = "eks"
}

data "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.aws_eks_cluster.demo_cluster.identity[0].oidc[0].issuer
}


output "eks_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.eks_oidc.arn
}
