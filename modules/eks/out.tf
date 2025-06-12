#this output values will later expose, with the use of these outputs
#we will direct this values in main output.tf files in project directory

output "eks_cluster_id" {
  value = aws_eks_cluster.eksCluster.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eksCluster.endpoint
}

# output "aws_iam_openid_connect_provider" {
#   value = aws_iam_openid_connect_provider.eks_oidc
# }

output "eks_cluster_profile" {
  value = module.eksIAM.instance_profile_karpenter.arn
}

output "oidc_url" {
  value = aws_iam_openid_connect_provider.eks_oidc.url
}
output "oidc_arn" {
  value = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eksCluster.name
}

output "certificate_authority_data" {
  value = aws_eks_cluster.eksCluster.certificate_authority[0].data
}


