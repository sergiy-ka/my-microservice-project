variable "namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Grafana Helm chart version"
  type        = string
  default     = "7.0.19"
}

variable "admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "prometheus_url" {
  description = "Prometheus server URL for data source"
  type        = string
}

variable "storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "grafana_plugins" {
  description = "List of Grafana plugins to install"
  type        = list(string)
  default = [
    "grafana-kubernetes-app",
    "grafana-piechart-panel",
    "grafana-worldmap-panel"
  ]
}

variable "enable_persistence" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}