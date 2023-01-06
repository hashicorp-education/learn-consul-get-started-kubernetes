output "azure_rg_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.k8.name
}

output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.consul_public_endpoint_url
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.k8.kube_config_raw
  sensitive = true
}

output "region" {
  value = var.network_region
}