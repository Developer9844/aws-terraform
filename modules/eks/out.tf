#this output values will later expose, with the use of these outputs
#we will direct this values in main output.tf files in project directory

output "eks_cluster_id" {
  value = aws_eks_cluster.demo_cluster.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.demo_cluster.endpoint
}
