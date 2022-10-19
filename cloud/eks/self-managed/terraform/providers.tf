terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.11.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
  }
}

provider "aws" {
  region     = var.vpc_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
}