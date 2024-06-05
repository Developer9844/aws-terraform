output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "eks_nodegroup_role_arn" {
  value = aws_iam_role.eks_nodegroup_role.arn
}

output "eks_nodegroup_role_name" {
  value = aws_iam_role.eks_nodegroup_role.name
}

output "instance_profile_karpenter" {
  value = aws_iam_instance_profile.karpenter
}
