/*
 *
 * Required Variables
 *
 */
variable "tenant_id" {
  type        = string
  description = "this is tenant id"
}

variable "subscription_id" {
  type        = string
  description = "this is the azure subscription id"
}

variable "hvn" {
  type = object({
    hvn_id     = string
    self_link  = string
    cidr_block = string
  })
  description = "The HCP HVN to connect to the VPC as defined in the datasource for hcp_hvn"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnets associated with the vnet"
}

variable "vnet_id" {
  type        = string
  description = "the id of the vnet"
}

variable "vnet_rg" {
  type        = string
  description = "The name of the vnet's resource group that everything will be created in"
}

/*
 *
 * Optional Variables
 *
 */

variable "security_group_names" {
  type        = list(string)
  description = "A list of security group IDs which should allow inbound Consul client traffic. If no security groups are provided, one will be generated for use."
  default     = []
}

variable "prefix" {
  type        = string
  description = "A prefix to be added to all resources to force uniqueness if required"
  default     = "peering"
}
