# Виведення інформації про S3 Backend
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "s3_bucket_url" {
  description = "URL of the S3 bucket"
  value       = module.s3_backend.s3_bucket_url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# Виведення інформації про VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# Виведення інформації про ECR
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

# Виведення інформації про EKS
output "eks_cluster_id" {
  description = "Name/ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "eks_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

# Виведення інформації про Jenkins
output "jenkins_release_name" {
  description = "Name of the Jenkins Helm release"
  value       = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

# Виведення інформації про Argo CD
output "argo_cd_server_service" {
  description = "Argo CD server service"
  value       = module.argo_cd.argo_cd_server_service
}

output "argo_cd_admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = module.argo_cd.admin_password
}

output "argo_cd_release_name" {
  description = "Name of the Argo CD Helm release"
  value       = module.argo_cd.argo_cd_release_name
}

output "argo_cd_namespace" {
  description = "Namespace where Argo CD is deployed"
  value       = module.argo_cd.argo_cd_namespace
}

# Виведення інформації про RDS/Aurora
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.database_endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.rds.database_port
}

output "database_name" {
  description = "Name of the created database"
  value       = module.rds.database_name
}

output "database_type" {
  description = "Type of database (RDS or Aurora)"
  value       = module.rds.connection_info.type
  sensitive   = true
}

output "rds_security_group_id" {
  description = "Security group ID for the database"
  value       = module.rds.security_group_id
}

output "rds_subnet_group_name" {
  description = "Database subnet group name"
  value       = module.rds.subnet_group_name
}

# Aurora-specific outputs
output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = module.rds.aurora_cluster_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.rds.aurora_reader_endpoint
}