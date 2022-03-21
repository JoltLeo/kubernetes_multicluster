output "client_certificate" {
  value = azurerm_kubernetes_cluster.az_cluster.kube_config.0.client_certificate
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.az_cluster.kube_config_raw
  sensitive = true
}

output "region" {
  description = "AKS region"
  value       = var.clusters_region
}