# Grafana Helm Release
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = false # Namespace should be created by Prometheus module

  # Use values file for complex configuration
  values = [
    templatefile("${path.module}/values.yaml", {
      admin_password  = var.admin_password
      prometheus_url  = var.prometheus_url
      storage_size    = var.storage_size
      plugins_list    = join(",", var.grafana_plugins)
      enable_persist  = var.enable_persistence
      cluster_name    = var.cluster_name
    })
  ]

  # Set admin password
  set_sensitive {
    name  = "adminPassword"
    value = var.admin_password
  }

  # Configure Prometheus data source
  set {
    name  = "datasources.datasources.yaml.datasources[0].url"
    value = var.prometheus_url
  }

  set {
    name  = "datasources.datasources.yaml.datasources[0].name"
    value = "Prometheus"
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