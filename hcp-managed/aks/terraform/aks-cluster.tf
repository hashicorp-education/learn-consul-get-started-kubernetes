# Create the AKS cluster.
resource "azurerm_kubernetes_cluster" "k8" {
  name                    = local.cluster_id
  dns_prefix              = local.cluster_id
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
    identity_ids              = [azurerm_user_assigned_identity.identity.id]
  }

  depends_on = [module.network]
}