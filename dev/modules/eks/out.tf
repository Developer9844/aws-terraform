output "aws_iam_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.smackdab_dev_oidc
}

output "ekscluster_name" {
  value = aws_eks_cluster.smackdab_dev.name
}

output "eks_cluster_profile" {
  value = module.eks_cluster_role.aws_iam_instance_profile
}
