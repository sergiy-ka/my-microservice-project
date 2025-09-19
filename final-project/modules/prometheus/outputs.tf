output "prometheus_namespace" {
  description = "Namespace where Prometheus is deployed"
  value       = helm_release.prometheus.namespace
}

output "prometheus_service_name" {
  description = "Prometheus server service name"
  value       = "${helm_release.prometheus.name}-server"
}

output "prometheus_server_url" {
  description = "Internal URL for Prometheus server"
  value       = "http://${helm_release.prometheus.name}-server.${helm_release.prometheus.namespace}.svc:80"
}

output "alertmanager_service_name" {
  description = "Alertmanager service name"
  value       = var.alertmanager_enabled ? "${helm_release.prometheus.name}-alertmanager" : null
}

output "alertmanager_url" {
  description = "Internal URL for Alertmanager"
  value       = var.alertmanager_enabled ? "http://${helm_release.prometheus.name}-alertmanager.${helm_release.prometheus.namespace}.svc:80" : null
}

output "node_exporter_enabled" {
  description = "Whether Node Exporter is enabled"
  value       = var.node_exporter_enabled
}

output "helm_release_name" {
  description = "Helm release name for Prometheus"
  value       = helm_release.prometheus.name
}

output "helm_release_status" {
  description = "Status of the Prometheus Helm release"
  value       = helm_release.prometheus.status
}