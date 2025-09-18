# Prometheus Helm Release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  # Use values file for complex configuration
  values = [
    file("${path.module}/values.yaml")
  ]

  # Override specific values
  set {
    name  = "server.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "server.persistentVolume.size"
    value = var.prometheus_storage_size
  }

  set {
    name  = "alertmanager.enabled"
    value = var.alertmanager_enabled
  }

  set {
    name  = "pushgateway.enabled"
    value = var.pushgateway_enabled
  }

  set {
    name  = "nodeExporter.enabled"
    value = var.node_exporter_enabled
  }

  # Configure service discovery for Kubernetes
  set {
    name  = "server.global.external_labels.cluster"
    value = var.cluster_name
  }

  # Wait for deployment to be ready
  wait          = true
  timeout       = 600
  wait_for_jobs = false

  depends_on = []
}

# Create monitoring namespace if it doesn't exist
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}