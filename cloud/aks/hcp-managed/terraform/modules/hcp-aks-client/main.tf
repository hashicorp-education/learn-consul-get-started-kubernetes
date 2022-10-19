terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
  }
}

resource "kubernetes_secret" "consul_secrets" {
  metadata {
    name = "${var.cluster_id}-hcp"
  }

  data = {
    caCert              = var.consul_ca_file
    gossipEncryptionKey = var.gossip_encryption_key
    bootstrapToken      = var.boostrap_acl_token
  }

  type = "Opaque"
}

resource "helm_release" "consul" {
  name       = "consul"
  chart      = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version

  values = [
    templatefile("${path.module}/templates/consul.tpl", {
      consul_hosts     = jsonencode(var.consul_hosts)
      consul_version   = substr(var.consul_version, 1, -1)
      cluster_id       = var.cluster_id
      datacenter       = var.datacenter
      k8s_api_endpoint = var.k8s_api_endpoint
    })
  ]

  # Helm installation relies on the Kuberenetes secret being available.
  depends_on = [kubernetes_secret.consul_secrets]
}
