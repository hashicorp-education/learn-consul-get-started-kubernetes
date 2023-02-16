# Create the Consul cluster.
resource "hcp_consul_cluster" "main" {
  cluster_id         = var.cluster_id
  hvn_id             = hcp_hvn.hvn.hvn_id
  public_endpoint    = true
  tier               = var.tier
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