output "eks_cluster_role" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "node_role" {
  value = aws_iam_role.node_role.arn
}

output "aws_iam_instance_profile" {
  value = aws_iam_instance_profile.karpenter.arn
}

output "aws_iam_policy_attachment" {
  value = aws_iam_policy_attachment.eks_cluster_policy_attachment
}
