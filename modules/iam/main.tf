#####################################################################
# EKS cluster role and policy attachment
#####################################################################
resource "aws_iam_role" "ClusterRole" {
  name = "${var.project_name}-Cluster-Role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : ["eks.amazonaws.com"]
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "ClusterPolicyAttachment" {
  name       = "${var.project_name}_AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.ClusterRole.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_policy_attachment" "EKSServicePolicyAttachment" {
  name       = "${var.project_name}_AmazonEKSServicePolicy"
  roles      = [aws_iam_role.ClusterRole.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}


########################################################################
# EKS node group role
########################################################################
resource "aws_iam_role" "NodeGroupRole" {
  name = "${var.project_name}-NodeGroup-Role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}
resource "aws_iam_role_policy_attachment" "AWSCSIProvisionerRolePolicy-Cluster" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AWSCSIProvisionerRolePolicy-Node" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

######################################################################
# Karpenter Policy Attachments
######################################################################
resource "aws_iam_role_policy_attachment" "KarpenterSSMPolicy" {
  role       = aws_iam_role.NodeGroupRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "KarpenterInstanceProfile" {
  name = "KarpenterNodeInstanceProfile-${var.project_name}"
  role = aws_iam_role.NodeGroupRole.name
}


#################################################################
#
#################################################################



