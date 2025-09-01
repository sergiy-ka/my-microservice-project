# Налаштування постачальника AWS
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "lesson-8-9"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# EKS cluster data source for Helm and Kubernetes providers
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default = "terraform-state-bucket-lesson8-9-sergiy-2025"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lesson-8-9-eks-cluster"
}

variable "github_username" {
  description = "GitHub username"
  type        = string
  default     = "sergiy-ka"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
  default     = "***REDACTED***"
}

variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/sergiy-ka/my-microservice-project.git"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.bucket_name
  table_name  = "terraform-locks-lesson-8-9"
  region      = var.aws_region

  tags = {
    Project     = "lesson-8-9"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-8-9-vpc"

  tags = {
    Project     = "lesson-8-9"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль ECR
module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "lesson-8-9-django-app"
  scan_on_push = true

  tags = {
    Project     = "lesson-8-9"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль EKS
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  node_groups = {
    main = {
      desired_capacity = 2
      max_capacity     = 6
      min_capacity     = 2
      instance_types   = ["t3.medium"]
      disk_size        = 20
    }
  }

  tags = {
    Project     = "lesson-8-9"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.vpc]
}

# Підключаємо модуль Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  ecr_registry_url  = module.ecr.repository_url
  github_username   = var.github_username
  github_token      = var.github_token
  github_repo_url   = var.github_repo_url

  depends_on = [module.eks]
}

# Підключаємо модуль Argo CD
module "argo_cd" {
  source = "./modules/argo-cd"

  namespace       = "argocd"
  chart_version   = "5.46.4"
  github_repo_url = var.github_repo_url
  github_username = var.github_username
  github_token    = var.github_token

  depends_on = [module.eks]
}