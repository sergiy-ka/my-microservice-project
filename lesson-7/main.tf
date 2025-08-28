# Налаштування постачальника AWS
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "lesson-7"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
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
  default = "terraform-state-bucket-lesson7-sergio-2025"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lesson-7-eks-cluster"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.bucket_name
  table_name  = "terraform-locks"
  region      = var.aws_region

  tags = {
    Project     = "lesson-7"
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
  vpc_name           = "lesson-7-vpc"

  tags = {
    Project     = "lesson-7"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль ECR
module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "lesson-7-django-app"
  scan_on_push = true

  tags = {
    Project     = "lesson-7"
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
    Project     = "lesson-7"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.vpc]
}