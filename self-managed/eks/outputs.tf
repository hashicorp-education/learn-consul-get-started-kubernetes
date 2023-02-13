output "kubernetes_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "kubernetes_cluster_id" {
  value = local.name
}

output "region" {
  value = var.vpc_region
}

output "vpc" {
  value = {
    vpc_id         = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
  }
}