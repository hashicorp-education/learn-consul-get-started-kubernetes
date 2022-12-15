data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_id}-gid"
  location = var.network_region
}

resource "azurerm_route_table" "rt" {
  name                = "${var.cluster_id}-rt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.cluster_id}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create an Azure vnet and authorize Consul server traffic.
module "network" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.6.0"
  address_space       = var.vnet_cidrs
  resource_group_name = azurerm_resource_group.rg.name
  subnet_delegation   = var.subnet_delegation
  subnet_names        = keys(var.vnet_subnets)
  subnet_prefixes     = values(var.vnet_subnets)
  vnet_name           = "${var.cluster_id}-vnet"
  vnet_location       = var.network_region

  # Every subnet will share a single route table
  route_tables_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_route_table.rt.id }

  # Every subnet will share a single network security group
  nsg_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_network_security_group.nsg.id }

  depends_on = [azurerm_resource_group.rg]
}

## To be added after Ingress Gateway is created
# Authorize HTTP ingress to the load balancer.
#resource "azurerm_network_security_rule" "ingress" {
#  name                        = "http-ingress"
#  priority                    = 301
#  direction                   = "Inbound"
#  access                      = "Allow"
#  protocol                    = "Tcp"
#  source_port_range           = "*"
#  destination_port_range      = "8080"
#  source_address_prefix       = "*"
#  destination_address_prefix  = module.demo_app.load_balancer_ip
#  resource_group_name         = azurerm_resource_group.rg.name
#  network_security_group_name = azurerm_network_security_group.nsg.name
#
#  depends_on = [module.demo_app]
#}

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