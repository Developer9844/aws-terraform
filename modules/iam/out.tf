output "eks_cluster_role_arn" {
  value = aws_iam_role.ClusterRole.arn
}

output "eks_nodegroup_role_arn" {
  value = aws_iam_role.NodeGroupRole.arn
}

output "eks_nodegroup_role_name" {
  value = aws_iam_role.NodeGroupRole.name
}

output "instance_profile_karpenter" {
  value = aws_iam_instance_profile.KarpenterInstanceProfile
}
