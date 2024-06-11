locals {
  project_name = var.project_name
  module_name  = var.module_name
}

resource "aws_eks_node_group" "spot_instance_nodegroup" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}_spot_node_group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_type
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
  capacity_type = "SPOT"
  update_config {
    max_unavailable = 1
  }
  labels = {
    Name  = "${var.cluster_name}"
    role  = "${var.project_name}_general_node"
    usage = "${var.usage_label}_general_node"
  }
  # lifecycle {
  #   ignore_changes = [scaling_config[0].desired_size]
  # }
}
