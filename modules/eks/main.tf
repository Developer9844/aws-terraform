module "eks_iam" {
  source       = "./eks_iam"
  project_name = var.project_name

}


resource "aws_eks_cluster" "demo_cluster" {
  name     = "eks"
  role_arn = module.eks_iam.eks_cluster_role_arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_id]
  }
  depends_on = [module.eks_iam]
}


#EKS node group
resource "aws_eks_node_group" "eks_node_group" {
  node_group_name = var.node_group_name
  cluster_name    = aws_eks_cluster.demo_cluster.name
  node_role_arn   = module.eks_iam.eks_nodegroup_role_arn
  subnet_ids      = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
  capacity_type   = "SPOT"
  instance_types  = [var.instance_types]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }
  depends_on = [module.eks_iam]
  lifecycle {
    create_before_destroy = true
  }
}
