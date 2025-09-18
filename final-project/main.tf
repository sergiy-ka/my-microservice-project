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
      Project     = "final-project"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# EKS кластер data source для Helm та Kubernetes провайдерів
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

# Змінні
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
  default = "terraform-state-bucket-final-project-sergiy-2025"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "final-project-eks-cluster"
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
  default     = "" # Не зберігаємо у коді!
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
  table_name  = "terraform-locks-final-project"
  region      = var.aws_region

  tags = {
    Project     = "final-project"
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
  vpc_name           = "final-project-vpc"

  tags = {
    Project     = "final-project"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль ECR
module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "final-project-django-app"
  scan_on_push = true

  tags = {
    Project     = "final-project"
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
    Project     = "final-project"
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

# Підключаємо модуль RDS
module "rds" {
  source = "./modules/rds"

  name                       = "final-project-db"
  use_aurora                 = false  # Змініть на true для Aurora
  
  # RDS-only налаштування
  engine                     = "postgres"
  engine_version             = "16.6"
  parameter_group_family_rds = "postgres16"
  allocated_storage          = 20
  
  # Aurora-only налаштування
  engine_cluster                 = "aurora-postgresql"
  engine_version_cluster         = "15.3"
  parameter_group_family_aurora  = "aurora-postgresql15"
  aurora_instance_count          = 2
  aurora_replica_count           = 1

  # Спільні налаштування
  instance_class         = "db.t3.micro"
  db_name               = "myproject_db"
  username              = "postgres"
  password              = "admin123AWS23"  # В продакшні використовуйте secrets!
  vpc_id                = module.vpc.vpc_id
  subnet_private_ids    = module.vpc.private_subnets
  subnet_public_ids     = module.vpc.public_subnets
  publicly_accessible   = false  # true тільки для тестування
  multi_az              = false  # true для продакшн
  backup_retention_period = 7

  # Параметри БД
  parameters = {
    max_connections              = "200"
    log_min_duration_statement   = "500"
    shared_preload_libraries     = "pg_stat_statements"
  }

  tags = {
    Project     = "final-project"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.vpc]
}

# Підключаємо модуль Prometheus
module "prometheus" {
  source = "./modules/prometheus"

  namespace      = "monitoring"
  chart_version  = "25.8.0"
  cluster_name   = var.cluster_name

  # Resource configuration
  prometheus_retention    = "15d"
  prometheus_storage_size = "8Gi"

  # Component configuration
  alertmanager_enabled  = true
  pushgateway_enabled   = false
  node_exporter_enabled = true

  tags = {
    Project     = "final-project"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "monitoring"
  }

  depends_on = [module.eks]
}

# Підключаємо модуль Grafana
module "grafana" {
  source = "./modules/grafana"

  namespace      = "monitoring"
  chart_version  = "7.0.19"
  cluster_name   = var.cluster_name
  admin_password = "admin123"

  # Prometheus integration
  prometheus_url = module.prometheus.prometheus_server_url

  # Storage configuration
  storage_size       = "5Gi"
  enable_persistence = true

  # Plugin configuration
  grafana_plugins = [
    "grafana-kubernetes-app",
    "grafana-piechart-panel",
    "grafana-worldmap-panel"
  ]

  depends_on = [module.eks, module.prometheus]

  tags = {
    Project     = "final-project"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "monitoring"
  }

  depends_on = [module.eks, module.prometheus]
}
