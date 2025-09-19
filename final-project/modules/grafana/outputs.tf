output "grafana_namespace" {
  description = "Namespace where Grafana is deployed"
  value       = helm_release.grafana.namespace
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = helm_release.grafana.name
}

output "grafana_service_url" {
  description = "Internal URL for Grafana service"
  value       = "http://${helm_release.grafana.name}.${helm_release.grafana.namespace}.svc:80"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.admin_password
  sensitive   = true
}

output "grafana_port_forward_command" {
  description = "Command to access Grafana via port-forward"
  value       = "kubectl port-forward -n ${helm_release.grafana.namespace} svc/${helm_release.grafana.name} 3000:80"
}

output "helm_release_name" {
  description = "Helm release name for Grafana"
  value       = helm_release.grafana.name
}

output "helm_release_status" {
  description = "Status of the Grafana Helm release"
  value       = helm_release.grafana.status
}

output "dashboards_configmap" {
  description = "ConfigMap name for custom dashboards"
  value       = kubernetes_config_map.grafana_dashboards.metadata[0].name
}