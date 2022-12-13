# Create an Azure resource group.
resource "azurerm_resource_group" "rg" {
  name     = "${local.cluster_id}-gid"
  location = var.network_region
}

# Create a user assigned identity (required for UserAssigned identity in combination with bringing our own subnet/nsg/etc)
resource "azurerm_user_assigned_identity" "identity" {
  name                = "aks-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create an Azure vnet and authorize Consul server traffic.
module "network" {
  source              = "Azure/vnet/azurerm"
  address_space       = var.vnet_cidrs
  resource_group_name = azurerm_resource_group.rg.name
  subnet_delegation   = var.subnet_delegation
  subnet_names        = keys(var.vnet_subnets)
  subnet_prefixes     = values(var.vnet_subnets)
  vnet_name           = "${local.cluster_id}-vnet"
  vnet_location       = var.network_region

  # Every subnet will share a single route table
  route_tables_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_route_table.rt.id }

  # Every subnet will share a single network security group
  nsg_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_network_security_group.nsg.id }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_route_table" "rt" {
  name                = "${local.cluster_id}-rt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.cluster_id}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

## To be added after API Gateway is created
# Authorize HTTP ingress to the load balancer.
/* resource "azurerm_network_security_rule" "api-gateway-ingress" {
  name                        = "api-gw-http-ingress"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.137.88.78/32"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name

}
*/