locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
}

resource "random_string" "cluster_id" {
  length  = 6
  special = false
  upper   = false
}

variable "network_region" {
  type        = string
  description = "the network region"
  default     = "West US 2"
}

variable "cluster_id" {
  type        = string
  description = "the cluster id is unique. All other unique values will be derived from this (resource group, vnet etc)"
  default     = "learn-hcp-gs"
}

variable "consul_version" {
  type        = string
  description = "The Consul version"
  default     = "v1.14.4"
}

variable "vnet_cidrs" {
  type        = list(string)
  description = "the CIDR ranges of the vnet. This should make sense with vnet_subnets"
  default     = ["10.0.0.0/16"]
}

variable "vnet_subnets" {
  type        = map(string)
  description = "the subnets associated with the vnet"
  default = {
    "subnet1" = "10.0.1.0/24",
    "subnet2" = "10.0.2.0/24",
    "subnet3" = "10.0.3.0/24",
  }
}

variable "subnet_delegation" {
  type        = map(map(any))
  description = "A map of subnet name to delegation block on the subnet"
  default = {
      subnet1 = {
        "aks-delegation" = {
          service_name = "Microsoft.ContainerService/managedClusters"
          service_actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
    }
}