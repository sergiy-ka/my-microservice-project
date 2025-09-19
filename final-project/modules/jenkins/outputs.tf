output "jenkins_release_name" {
  description = "Name of the Jenkins Helm release"
  value       = helm_release.jenkins.name
}

output "jenkins_namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = helm_release.jenkins.namespace
}

output "jenkins_service_account_arn" {
  description = "ARN of the Jenkins service account IAM role"
  value       = aws_iam_role.jenkins_kaniko_role.arn
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = "admin123"
  sensitive   = true
}