output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.main.name
}

output "repository_url" {
  description = "URL of the repository"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.main.registry_id
}

output "repository_registry_id" {
  description = "Registry ID of the repository"
  value       = aws_ecr_repository.main.registry_id
}

output "repository_uri" {
  description = "URI of the repository"
  value       = aws_ecr_repository.main.repository_url
}