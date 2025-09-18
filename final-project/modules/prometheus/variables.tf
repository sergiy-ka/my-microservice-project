variable "namespace" {
  description = "Kubernetes namespace for Prometheus"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Prometheus Helm chart version"
  type        = string
  default     = "25.8.0"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus server"
  type        = string
  default     = "8Gi"
}

variable "alertmanager_enabled" {
  description = "Enable Alertmanager component"
  type        = bool
  default     = true
}

variable "pushgateway_enabled" {
  description = "Enable Pushgateway component"
  type        = bool
  default     = false
}

variable "node_exporter_enabled" {
  description = "Enable Node Exporter component"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}