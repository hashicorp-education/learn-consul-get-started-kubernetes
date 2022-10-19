terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.27"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.14"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.46"
    }
  }

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }
}

locals {
  ingress_consul_rules = [
    {
      description = "Consul LAN Serf (tcp)"
      rule_name   = "consul-lan-tcp"
      port        = 8301
      protocol    = "Tcp"
    },
    {
      description = "Consul LAN Serf (udp)"
      rule_name   = "consul-lan-udp"
      port        = 8301
      protocol    = "Udp"
    },
  ]

  # If a list of security_group_ids was provided, construct a rule set.
  hcp_consul_security_groups = flatten([
    for _, sg in var.security_group_names : [
      for i, rule in local.ingress_consul_rules : {
        security_group_name = sg
        description         = rule.description
        destination_port    = rule.port
        protocol            = rule.protocol
        rule_name           = rule.rule_name
      }
    ]
  ])
}

# Azure data sources unfortunately rely on name, and resource group name which will never be computed
# fields since they are known input fields. This results in the terraform failing since the data
# source tries to look them up before they are actually created. In aws data sources take computed
# and randomized unique names so we never have this problem.
#
# To get around this we are using the id of the vnet and the subnet (which are computed fields)
# to look them up. The benefit of this is that Azure ids have a known structure (unlike aws ids)
# that is unlikely to ever change:
#
# /subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Network/virtualNetworks/<vnet name>
#
# Using this known structure we can trim the prefix after matching everything up to virtualNetworks/
data "azurerm_virtual_network" "vnet" {
  name                = trimprefix(var.vnet_id, regex(".*virtualNetworks\\/", var.vnet_id))
  resource_group_name = var.vnet_rg
}

// Similar to above a subnet id will have a known structure that is unlikely to ever change:
//
// "/subscriptions/<subscription ids>/resourceGroups/<resource group name>/providers/Microsoft.Network/virtualNetworks/<vnet name>/subnets/<subnet name>
//
// Using this known strcuture we can trim the prefix after matching everything up to subnets/
data "azurerm_subnet" "selected" {
  count                = length(var.subnet_ids)
  name                 = trimprefix(var.subnet_ids[count.index], regex(".*subnets\\/", var.subnet_ids[count.index]))
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.vnet_rg
}

resource "hcp_azure_peering_connection" "peering" {
  hvn_link                 = var.hvn.self_link
  peering_id               = "${var.prefix}-peer"
  peer_vnet_name           = data.azurerm_virtual_network.vnet.name
  peer_subscription_id     = var.subscription_id
  peer_tenant_id           = var.tenant_id
  peer_resource_group_name = var.vnet_rg
  peer_vnet_region         = data.azurerm_virtual_network.vnet.location
}

resource "azuread_service_principal" "principal" {
  application_id = hcp_azure_peering_connection.peering.application_id
}

resource "azurerm_role_definition" "definition" {
  name  = "${var.prefix}-role-name"
  scope = var.vnet_id
  assignable_scopes = [
    var.vnet_id
  ]
  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/peer/action",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write"
    ]
  }
}

resource "azurerm_role_assignment" "role_assignment" {
  principal_id       = azuread_service_principal.principal.id
  role_definition_id = azurerm_role_definition.definition.role_definition_resource_id
  scope              = var.vnet_id
}

data "hcp_azure_peering_connection" "peering" {
  hvn_link              = var.hvn.self_link
  peering_id            = hcp_azure_peering_connection.peering.peering_id
  wait_for_active_state = true
}

# HVN route tables to point to subnets
resource "hcp_hvn_route" "route" {
  count        = length(data.azurerm_subnet.selected)
  hvn_link     = var.hvn.self_link
  hvn_route_id = "${var.prefix}-${count.index}"
  # TODO: handle multiple cidrs attached to a single subnet. Taking first for now
  destination_cidr = data.azurerm_subnet.selected[count.index].address_prefixes[0]
  target_link      = data.hcp_azure_peering_connection.peering.self_link
}

resource "azurerm_network_security_rule" "hcp_consul_existing_sg_rules" {
  count                       = length(local.hcp_consul_security_groups)
  name                        = "${var.prefix}-${local.hcp_consul_security_groups[count.index].rule_name}"
  priority                    = 100 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  description                 = local.hcp_consul_security_groups[count.index].description
  protocol                    = local.hcp_consul_security_groups[count.index].protocol
  source_port_range           = "*"
  destination_port_range      = local.hcp_consul_security_groups[count.index].destination_port
  source_address_prefix       = var.hvn.cidr_block
  destination_address_prefix  = "*"
  resource_group_name         = var.vnet_rg
  network_security_group_name = local.hcp_consul_security_groups[count.index].security_group_name
}

# If no security_group_names were provided, create a new security_group.
resource "azurerm_network_security_group" "nsg" {
  count               = length(var.security_group_names) == 0 ? 1 : 0
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = var.vnet_rg
}

# If no security_group_names were provided associate the new security 
# group with all the subnets
resource "azurerm_subnet_network_security_group_association" "subnetnsg" {
  count                     = length(var.security_group_names) == 0 ? length(var.subnet_ids) : 0
  subnet_id                 = var.subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

# If no security_group_ids were provided, use the new security_group.
resource "azurerm_network_security_rule" "hcp_consul_new_sg_rules" {
  count                       = length(var.security_group_names) == 0 ? length(local.ingress_consul_rules) : 0
  name                        = "${var.prefix}-${local.ingress_consul_rules[count.index].rule_name}"
  priority                    = 100 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = local.ingress_consul_rules[count.index].protocol
  source_port_range           = "*"
  destination_port_range      = local.ingress_consul_rules[count.index].port
  source_address_prefix       = var.hvn.cidr_block
  destination_address_prefix  = "*"
  resource_group_name         = var.vnet_rg
  network_security_group_name = azurerm_network_security_group.nsg[0].name
}
