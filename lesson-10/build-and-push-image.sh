#!/bin/bash

# УВАГА: Цей скрипт для ручного тестування та розробки
# Основний CI/CD процес виконується через Jenkins pipeline

# Налаштування змінних
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REPOSITORY_NAME="lesson-10-django-app"
IMAGE_TAG="manual-$(date +%Y%m%d-%H%M%S)"

# Отримуємо URL репозиторію ECR з Terraform outputs
ECR_URL=$(terraform output -raw ecr_repository_url)

echo "Building and pushing Docker image to ECR..."
echo "Repository: $ECR_URL"

# Логінимося до ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Будуємо Docker образ з lesson-10 контексту
echo "Building Docker image..."
docker build -t $REPOSITORY_NAME:$IMAGE_TAG lesson-10/

# Тегуємо образ для ECR
echo "Tagging image for ECR..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ECR_URL:$IMAGE_TAG

# Завантажуємо образ в ECR
echo "Pushing image to ECR..."
docker push $ECR_URL:$IMAGE_TAG

echo "Image successfully pushed to ECR: $ECR_URL:$IMAGE_TAG"
echo ""
echo "NOTE: Цей образ має тег 'manual-*' і не буде використовуватись ArgoCD"
echo "Для production деплою використовуйте Jenkins pipeline, який створює теги 'v1.0.X'"