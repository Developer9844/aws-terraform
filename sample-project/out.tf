# output "private_key" {
#   value     = module.ssh_key.private_key
#   sensitive = true
# }
# output "public_key" {
#   value     = module.ssh_key.public_key
#   sensitive = true
# }


# we have out the values in the module out.tf file
output "eks_cluster_id" {
  value = module.eks_cluster.eks_cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.eks_cluster_endpoint
}



output "aws_profile" {
  value = var.aws_profile
}