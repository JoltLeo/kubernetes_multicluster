output "cluster_name" {
  description = "AKS cluster name"
  value       = "aks-${var.clusters_region}-${random_integer.random_id.result}"
}

output "cluster_endpoint" {
  description = "Endpoint for AKS control plane."
  value       = azurerm_kubernetes_cluster.az_cluster.fqdn
}

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