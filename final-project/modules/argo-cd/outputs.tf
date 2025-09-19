output "argo_cd_server_service" {
  description = "Argo CD server service"
  value       = "argo-cd.${var.namespace}.svc.cluster.local"
}

output "admin_password" {
  description = "Initial admin password"
  value       = "Run: kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d"
}

output "argo_cd_release_name" {
  description = "Name of the Argo CD Helm release"
  value       = helm_release.argo_cd.name
}

output "argo_cd_namespace" {
  description = "Namespace where Argo CD is deployed"
  value       = helm_release.argo_cd.namespace
}