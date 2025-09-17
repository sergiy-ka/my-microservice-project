variable "name" {
  description = "Name of the Argo CD Helm release"
  type        = string
  default     = "argo-cd"
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of Argo CD Helm chart"
  type        = string
  default     = "5.46.4"
}

variable "github_repo_url" {
  description = "GitHub repository URL for applications"
  type        = string
  default     = "https://github.com/your-username/your-repo.git"
}

variable "github_username" {
  description = "GitHub username"
  type        = string
  default     = "your-github-username"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
  default     = "your-github-pat-token"
}