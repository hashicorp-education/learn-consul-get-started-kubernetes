# Create a Kubernetes client that deploys Consul and its secrets.
module "aks_consul_client" {
  source  = "hashicorp/hcp-consul/azurerm//modules/hcp-aks-client"
  version = "~> 0.2.5"

  cluster_id       = hcp_consul_cluster.main.cluster_id
  consul_hosts     = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_version   = hcp_consul_cluster.main.consul_version
  k8s_api_endpoint = azurerm_kubernetes_cluster.k8.kube_config.0.host

  boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
  consul_ca_file        = base64decode(hcp_consul_cluster.main.consul_ca_file)
  datacenter            = hcp_consul_cluster.main.datacenter
  gossip_encryption_key = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]

  # The AKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [azurerm_kubernetes_cluster.k8]
}