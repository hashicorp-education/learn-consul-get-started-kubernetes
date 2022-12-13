variable "cluster_id" {
  type        = string
  description = "The cluster id is unique. All other unique values will be derived from this (resource group, vnet etc)"
  default     = "learn-consul-aks"
}

variable "network_region" {
  type        = string
  description = "the Azure network region"
  default     = "westus2"
}

variable "vnet_cidrs" {
  type        = list(string)
  description = "The ciders of the vnet. This should make sense with vnet_subnets"
  default     = ["10.0.0.0/16"]
}

variable "vnet_subnets" {
  type        = map(string)
  description = "The subnets associated with the vnet"
  default = {
    "subnet1" = "10.0.1.0/24",
    "subnet2" = "10.0.2.0/24"
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

resource "random_string" "cluster_id" {
  length  = 6
  special = false
  upper   = false
}

locals {
  cluster_id = "${var.cluster_id}-${random_string.cluster_id.id}"
}