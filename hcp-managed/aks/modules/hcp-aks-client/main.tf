terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
  }
}

locals {

  // consul client agents will not be installed starting chart version 1.0.0.
  install_consul_client_agent = substr(var.chart_version, 0, 1) == "1" ? "false" : "true"

  helm_values = templatefile("${path.module}/templates/consul.tpl", {
    consul_hosts        = jsonencode(var.consul_hosts)
    consul_version      = substr(var.consul_version, 1, -1)
    cluster_id          = var.cluster_id
    datacenter          = var.datacenter
    k8s_api_endpoint    = var.k8s_api_endpoint
    consul_client_agent = local.install_consul_client_agent
    api_gateway_version = var.api_gateway_version
  })

  consul_secrets_common = {
    bootstrapToken = var.boostrap_acl_token
  }

  consul_secrets_client_agent = {
    client_agent = local.install_consul_client_agent == "false" ? {} : {
      caCert              = var.consul_ca_file
      gossipEncryptionKey = var.gossip_encryption_key
    }
  }

  consul_secrets = merge(
    local.consul_secrets_common,
    local.consul_secrets_client_agent["client_agent"]
  )
}

resource "kubernetes_secret" "consul_secrets" {
  metadata {
    name = "${var.cluster_id}-hcp"
    namespace  = "consul"
  }

  data = local.consul_secrets

  type = "Opaque"
}

resource "helm_release" "consul" {
  name       = "consul"
  chart      = "consul"
  namespace  = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  timeout    = 600

  values = [local.helm_values]

  # Helm installation relies on the Kuberenetes secret being available.
  depends_on = [kubernetes_secret.consul_secrets]
}

resource "local_file" "helm_values" {
  content              = local.helm_values
  filename             = substr(var.helm_values_path, -1, 1) == "/" ? "${var.helm_values_path}helm_values_${var.datacenter}" : var.helm_values_path
  file_permission      = var.helm_values_file_permission
  directory_permission = "0755"
}
