module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.8.8"

  hvn                = hcp_hvn.main
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = concat(module.vpc.public_subnets)
  route_table_ids    = concat(module.vpc.public_route_table_ids)
  security_group_ids = [module.eks.cluster_primary_security_group_id]
}

resource "hcp_consul_cluster" "main" {
  cluster_id         = local.name
  hvn_id             = hcp_hvn.main.hvn_id
  public_endpoint    = true
  tier               = var.consul_tier
  min_consul_version = var.consul_version
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

module "eks_consul_client" {
  source = "./modules/eks-client"

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  cluster_id            = hcp_consul_cluster.main.cluster_id
  consul_ca_file        = base64decode(hcp_consul_cluster.main.consul_ca_file)
  consul_hosts          = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_version        = hcp_consul_cluster.main.consul_version
  datacenter            = hcp_consul_cluster.main.datacenter
  gossip_encryption_key = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
  k8s_api_endpoint      = module.eks.cluster_endpoint

  # The EKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [module.eks, kubernetes_namespace.consul]
}