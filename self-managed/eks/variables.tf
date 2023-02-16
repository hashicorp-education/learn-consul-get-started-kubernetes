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

variable "consul_version" {
  type        = string
  description = "The Consul version"
  default     = "v1.14.4"
}

variable "api_gateway_version" {
  type        = string
  description = "The Consul API gateway CRD version to use"
  default     = "0.5.1"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name = "${var.name}-${random_string.suffix.result}"
}