# Create a user assigned identity (required for UserAssigned identity in combination with brining our own subnet/nsg/etc)
resource "azurerm_user_assigned_identity" "identity" {
  name                = "aks-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the AKS cluster.
resource "azurerm_kubernetes_cluster" "k8" {
  name                    = var.cluster_id
  kubernetes_version      = "1.24"
  
  dns_prefix              = var.cluster_id
  location                = azurerm_resource_group.rg.location
  private_cluster_enabled = false
  resource_group_name     = azurerm_resource_group.rg.name

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.30.0.0/16"
    dns_service_ip     = "10.30.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
    pod_subnet_id   = module.network.vnet_subnets[0]
    vnet_subnet_id  = module.network.vnet_subnets[1]
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }

  depends_on = [module.network]
}

# Create a Kubernetes client that deploys Consul and its secrets.
module "aks_consul_client" {
  source = "./modules/hcp-aks-client"

  cluster_id = hcp_consul_cluster.main.cluster_id
  # strip out url scheme from the public url
  consul_hosts       = tolist([substr(hcp_consul_cluster.main.consul_public_endpoint_url, 8, -1)])
  consul_version     = hcp_consul_cluster.main.consul_version
  k8s_api_endpoint   = azurerm_kubernetes_cluster.k8.kube_config.0.host
  boostrap_acl_token = hcp_consul_cluster_root_token.token.secret_id
  datacenter         = hcp_consul_cluster.main.datacenter

  # The AKS node group will fail to create if the clients are
  # created at the same time. This forces the client to wait until
  # the node group is successfully created.
  depends_on = [azurerm_kubernetes_cluster.k8, kubernetes_namespace.consul]
}