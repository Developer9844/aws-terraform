terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

