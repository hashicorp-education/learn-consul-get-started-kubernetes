output "azure_rg_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.k8.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.k8.kube_config_raw
  sensitive = true
}

output "region" {
  value = var.network_region
}