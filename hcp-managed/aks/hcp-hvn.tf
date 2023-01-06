# Create an HCP HVN.
resource "hcp_hvn" "hvn" {
  cidr_block     = var.hvn_cidr_block
  cloud_provider = "azure"
  hvn_id         = var.hvn_id
  region         = var.hvn_region
}

# Note: Uncomment the below module to setup peering for connecting to a private HCP Consul cluster
# Peer the HVN to the vnet.
# module "hcp_peering" {
#   source  = "hashicorp/hcp-consul/azurerm"
#   version = "~> 0.3.1"

#   hvn    = hcp_hvn.hvn
#   prefix = var.cluster_id

#   security_group_names = [azurerm_network_security_group.nsg.name]
#   subscription_id      = data.azurerm_subscription.current.subscription_id
#   tenant_id            = data.azurerm_subscription.current.tenant_id

#   subnet_ids = module.network.vnet_subnets
#   vnet_id    = module.network.vnet_id
#   vnet_rg    = azurerm_resource_group.rg.name
# }