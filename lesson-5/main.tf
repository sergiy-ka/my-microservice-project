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
      Project     = "lesson-5"
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
  default = "terraform-state-bucket-lesson5-sergio-2025"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name = var.bucket_name
  table_name  = "terraform-locks"
  region      = var.aws_region

  tags = {
    Project     = "lesson-5"
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
  vpc_name           = "lesson-5-vpc"

  tags = {
    Project     = "lesson-5"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Підключаємо модуль ECR
module "ecr" {
  source = "./modules/ecr"

  ecr_name     = "lesson-5-ecr"
  scan_on_push = true

  tags = {
    Project     = "lesson-5"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}