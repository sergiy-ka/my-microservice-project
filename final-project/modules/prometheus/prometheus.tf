# Prometheus Helm Release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  # Використовуємо файл values для складної конфігурації
  values = [
    file("${path.module}/values.yaml")
  ]

  # Перевизначаємо специфічні значення
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

  # Налаштовуємо service discovery для Kubernetes
  set {
    name  = "server.global.external_labels.cluster"
    value = var.cluster_name
  }

  # Очікуємо готовності розгортання
  wait          = true
  timeout       = 600
  wait_for_jobs = false

  depends_on = []
}

# Створити простір імен monitoring, якщо його не існує
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}