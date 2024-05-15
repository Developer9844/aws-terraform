# EKS cluster role and policy attachment
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : ["ec2.amazonaws.com", "eks.amazonaws.com"]
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eks_cluster_policy" {
  name        = "eks_cluster_policy"
  description = "Policy for EKS cluster"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "*",
      "Resource" : "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "eks_cluster_role_policy_attachment" {
  roles      = [aws_iam_role.eks_cluster_role.name]
  policy_arn = aws_iam_policy.eks_cluster_policy.arn
  name       = "policy"
}

# EKS node group role
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "eks_nodegroup_role"
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

resource "aws_iam_policy" "eks_nodegroup_policy" {
  name        = "eks_nodegroup_policy"
  description = "Policy for EKS node group"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "*",
      "Resource" : "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "eks_nodegroup_role_policy_attachment" {
  roles      = [aws_iam_role.eks_nodegroup_role.name]
  policy_arn = aws_iam_policy.eks_nodegroup_policy.arn
  name       = "policy-2"
}
