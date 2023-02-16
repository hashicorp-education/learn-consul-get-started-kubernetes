locals {
  hvn_id  = "${var.hvn_id}-${random_string.suffix.result}"
  name    = "${var.name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

variable "name" {
  description = "Tutorial name"
  type        = string
  default     = "learn-consul-gs"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-west-2"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "learn-consul-gs"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "consul_tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}

variable "consul_version" {
  type        = string
  description = "The HCP Consul version"
  default     = "v1.14.4"
}

variable "api_gateway_version" {
  type        = string
  description = "The Consul API gateway CRD version to use"
  default     = "0.5.1"
}
