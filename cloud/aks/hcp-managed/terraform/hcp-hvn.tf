# Create an HCP HVN.
resource "hcp_hvn" "hvn" {
  cidr_block     = "172.25.32.0/20"
  cloud_provider = "azure"
  hvn_id         = local.hvn_id
  region         = local.hvn_region
}

# Peer the HVN to the vnet.
module "hcp_peering" {
  source  = "hashicorp/hcp-consul/azurerm"
  version = "~> 0.2.5"

  hvn    = hcp_hvn.hvn
  prefix = local.cluster_id

  security_group_names = [azurerm_network_security_group.nsg.name]
  subscription_id      = data.azurerm_subscription.current.subscription_id
  tenant_id            = data.azurerm_subscription.current.tenant_id

  subnet_ids = module.network.vnet_subnets
  vnet_id    = module.network.vnet_id
  vnet_rg    = azurerm_resource_group.rg.name
}