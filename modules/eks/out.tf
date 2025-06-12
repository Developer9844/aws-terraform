output "eks_cluster_id" {
  value = aws_eks_cluster.eksCluster.id
}

output "eks_cluster" {
  value = aws_eks_cluster.eksCluster
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eksCluster.endpoint
}


output "aws_iam_openid_connect_provider_url" {
  value = aws_iam_openid_connect_provider.eks_oidc.url
}
output "aws_iam_openid_connect_provider_arn" {
  value = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eksCluster.name
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.eksCluster.certificate_authority[0].data
}


