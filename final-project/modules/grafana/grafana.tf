# Grafana Helm Release
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = false # Namespace should be created by Prometheus module

  # Basic configuration via set parameters (simpler than values file)
  set {
    name  = "adminUser"
    value = "admin"
  }

  set_sensitive {
    name  = "adminPassword"
    value = var.admin_password
  }

  set {
    name  = "persistence.enabled"
    value = var.enable_persistence
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  set {
    name  = "persistence.storageClassName"
    value = "gp2"
  }

  # Configure Prometheus data source
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = var.prometheus_url
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  # Wait for deployment to be ready
  wait          = true
  timeout       = 600
  wait_for_jobs = false

  depends_on = []
}

# ConfigMap for custom dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-custom-dashboards"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "kubernetes-overview.json" = file("${path.module}/dashboards/kubernetes-overview.json")
    "django-app.json"          = file("${path.module}/dashboards/django-app.json")
  }

  depends_on = [helm_release.grafana]
}