//------------------------------------------------------------------------------------------
#Fetch EKS OIDC Data
data "aws_eks_cluster" "oidc_url" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_name]
}

data "aws_eks_cluster" "cluster_host" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_name]
}

data "aws_eks_cluster" "securitygroup" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_name]
}
output "cluster_endpoint" {
  value = data.aws_eks_cluster.cluster_host.endpoint
}

output "oidc_provider_url" {
  value = data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer
}

data "aws_eks_cluster" "oidc_arn" {
  name       = "${var.project_name}_cluster"
  depends_on = [var.cluster_name]
}

data "aws_iam_openid_connect_provider" "dev_provider" {
  url = data.aws_eks_cluster.oidc_arn.identity.0.oidc.0.issuer
}

output "eks_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.dev_provider.arn
}
//---
#create karpenter controller Policy
resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "${var.project_name}-AWSKarpenterControllerPolicy"
  path        = "/"
  description = "Policy for Karpenter Controller"
  tags = {
    Name = "${var.project_name}-AWSKarpenterControllerPolicy"
  }
  policy = file("./karpentercontrollepolicy.json")
}

//---
#Karpenter Controller Role
resource "aws_iam_role" "karpenter_controller_role" {
  name               = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_role_policy.json
  tags = {
    "Name" = "${var.project_name}-AmazonEKSKarpenterControllerRoleCustom"
  }
}

data "aws_iam_policy_document" "karpenter_controller_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.oidc_url.identity.0.oidc.0.issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.dev_provider.arn]
      type        = "Federated"
    }
  }
}
//------------------------------------------------------------------------------------------
#Attach karpenter CONTROLLER Policy to Above Role
resource "aws_iam_role_policy_attachment" "attach_karpenter_controller_policy" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn

  depends_on = [
    aws_iam_role.karpenter_controller_role,
    aws_iam_policy.karpenter_controller_policy
  ]
}

//---
#Installing Karpenter in Cluster

resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "0.36.1"
  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller_role.arn
  }

  set {
    name  = "settings.clusterName"
    value = var.project_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = data.aws_eks_cluster.cluster_host.endpoint
  }

  # set {
  #   name  = "settings.aws.defaultInstanceProfile"
  #   value = var.instance_profile
  # }

}

# resource "kubernetes_manifest" "example" {
#   yaml_body = "${file("deployment.yaml")}"
# }

# data "template_file" "nodepool_yaml" {
#   template = file("./nodepool.yml")

#   vars = {
#     public_subnet_a1         = var.public_subnet_a1
#     public_subnet_a2         = var.public_subnet_a2
#     public_subnet_a3         = var.public_subnet_a3
#     aws_iam_instance_profile = var.instance_profile
#     project_name             = var.project_name
#     securitygroup            = data.aws_eks_cluster.securitygroup.id
#   }
# }


resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "spot"
      annotations = {
        "kubernetes.io/description" : "NodePool for provisioning spot capacity"
      }
    }
    spec = {
      template = {
        metadata = {
          labels = {
            usage = "dev_node_general_node"
            role  = "${var.project_name}_general_node"
          }

        }
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["m5a.xlarge", "m6g.xlarge", "m7g.xlarge", "m6a.xlarge"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = ["us-east-1a", "us-east-1b", "us-east-1c"]
            }
          ],
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "default"
          }
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "48h"
      }
      limits = {
        cpu    = "20"
        memory = "100Gi"
      }
    }
  }
}

resource "kubernetes_manifest" "karpenter_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily       = "AL2"
      instanceProfile = "eks-28c7be4b-ca82-6608-33de-7930bccbd6a9"
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeType          = "gp3"
            volumeSize          = "20Gi"
            encrypted           = true
            deleteOnTermination = true
          }
        }
      ]

      subnetSelectorTerms = [
        {
          id = "${var.public_subnet_a1}"
        },
        {
          id = "${var.public_subnet_a2}"
        },
        {
          id = "${var.public_subnet_a3}"
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "aws:eks:cluster-name" = "${data.aws_eks_cluster.securitygroup.id}"
          }
        }
      ]
    }

  }
}
