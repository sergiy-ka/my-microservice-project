#!/bin/bash

# Налаштування
REGION="us-west-2"
REPOSITORY_NAME="lesson-7-django-app"
BUCKET_NAME="terraform-state-bucket-lesson7-sergio-2025"

echo "Початок очищення AWS ресурсів lesson-7..."

# Крок 1: Видалення Helm застосунку
echo "1. Видалення Helm застосунку..."
helm uninstall django-app 2>/dev/null || echo "Helm release не знайдено"

# Крок 2: Очікування видалення LoadBalancer
echo "2. Очікування видалення LoadBalancer (60 секунд)..."
sleep 60

# Крок 3: Видалення Terraform інфраструктури
echo "3. Видалення Terraform інфраструктури..."
terraform destroy -auto-approve

# Крок 4: Очищення ECR (якщо не видалився)
echo "4. Перевірка та очищення ECR..."
if aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення образів з ECR..."
    aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --image-ids imageTag=latest --region $REGION >/dev/null 2>&1
    echo "Видалення ECR репозиторію..."
    aws ecr delete-repository --repository-name $REPOSITORY_NAME --force --region $REGION >/dev/null 2>&1
    echo "ECR очищено"
else
    echo "ECR вже видалений"
fi

# Крок 5: Очищення S3 bucket (якщо не видалився)
echo "5. Перевірка та очищення S3 bucket..."
if aws s3 ls s3://$BUCKET_NAME >/dev/null 2>&1; then
    echo "Видалення версій файлів з S3..."
    aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: Versions[].{Key: Key, VersionId: VersionId}}' --output json)" --region $REGION >/dev/null 2>&1
    echo "Видалення S3 bucket..."
    aws s3 rb s3://$BUCKET_NAME --force
    echo "S3 bucket очищено"
else
    echo "S3 bucket вже видалений"
fi

# Крок 6: Перевірка очищення
echo ""
echo "6. Перевірка повного очищення..."

# Перевірка ECR
ECR_COUNT=$(aws ecr describe-repositories --region $REGION --query 'length(repositories)' --output text 2>/dev/null || echo "0")
echo "ECR репозиторії: $ECR_COUNT"

# Перевірка EKS
EKS_COUNT=$(aws eks list-clusters --region $REGION --query 'length(clusters)' --output text 2>/dev/null || echo "0")
echo "EKS кластери: $EKS_COUNT"

# Перевірка VPC
VPC_COUNT=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-7" --region $REGION --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
echo "Project VPC: $VPC_COUNT"

# Перевірка LoadBalancer
ELB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
echo "Load Balancers: $ELB_COUNT"

echo ""
if [[ "$ECR_COUNT" == "0" && "$EKS_COUNT" == "0" && "$VPC_COUNT" == "0" ]]; then
    echo "Всі ресурси успішно видалені!"
else
    echo "Деякі ресурси можуть залишитися. Перевірте AWS консоль."
fi

echo ""