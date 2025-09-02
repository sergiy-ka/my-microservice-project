#!/bin/bash

# Налаштування
REGION="us-west-2"
REPOSITORY_NAME="lesson-8-9-django-app"
BUCKET_NAME="terraform-state-bucket-lesson8-9-sergiy-2025"

echo "Початок очищення AWS ресурсів lesson-8-9..."

# Крок 1: Видалення Helm застосунків
echo "1. Видалення Helm застосунків..."
helm uninstall django-app 2>/dev/null || echo "Django app Helm release не знайдено"
helm uninstall jenkins -n jenkins 2>/dev/null || echo "Jenkins Helm release не знайдено"
helm uninstall argo-cd -n argocd 2>/dev/null || echo "Argo CD Helm release не знайдено"
helm uninstall argo-cd-apps -n argocd 2>/dev/null || echo "Argo CD Apps Helm release не знайдено"

# Крок 2: Видалення namespace (якщо потрібно)
echo "2. Видалення namespace..."
kubectl delete namespace jenkins --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# Крок 3: Очікування видалення LoadBalancer (120 секунд)
echo "3. Очікування видалення LoadBalancer (120 секунд)..."
sleep 120

# Крок 4: Видалення Terraform інфраструктури
echo "4. Видалення Terraform інфраструктури..."
terraform destroy -auto-approve

# Крок 5: Очищення ECR (якщо не видалився)
echo "5. Перевірка та очищення ECR..."
if aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення образів з ECR..."
    aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --image-ids imageTag=latest --region $REGION >/dev/null 2>&1
    aws ecr list-images --repository-name $REPOSITORY_NAME --region $REGION --query 'imageIds[*]' --output json | jq '.[]' | \
    while read img; do
        aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --image-ids "$img" --region $REGION >/dev/null 2>&1
    done
    echo "Видалення ECR репозиторію..."
    aws ecr delete-repository --repository-name $REPOSITORY_NAME --force --region $REGION >/dev/null 2>&1
    echo "ECR очищено"
else
    echo "ECR вже видалений"
fi

# Крок 6: Очищення S3 bucket (якщо не видалився)
echo "6. Перевірка та очищення S3 bucket..."
if aws s3 ls s3://$BUCKET_NAME >/dev/null 2>&1; then
    echo "Видалення версій файлів з S3..."
    aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: Versions[].{Key: Key, VersionId: VersionId}}' --output json)" --region $REGION >/dev/null 2>&1
    aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: DeleteMarkers[].{Key: Key, VersionId: VersionId}}' --output json)" --region $REGION >/dev/null 2>&1
    echo "Видалення S3 bucket..."
    aws s3 rb s3://$BUCKET_NAME --force
    echo "S3 bucket очищено"
else
    echo "S3 bucket вже видалений"
fi

# Крок 7: Очистка DynamoDB table
echo "7. Перевірка та очищення DynamoDB..."
TABLE_NAME="terraform-locks-lesson8-9"
if aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення DynamoDB table..."
    aws dynamodb delete-table --table-name $TABLE_NAME --region $REGION >/dev/null 2>&1
    echo "DynamoDB table видалена"
else
    echo "DynamoDB table вже видалена"
fi

# Крок 8: Перевірка очищення
echo ""
echo "8. Перевірка повного очищення..."

# Перевірка ECR
ECR_COUNT=$(aws ecr describe-repositories --region $REGION --query 'length(repositories)' --output text 2>/dev/null || echo "0")
echo "ECR репозиторії: $ECR_COUNT"

# Перевірка EKS
EKS_COUNT=$(aws eks list-clusters --region $REGION --query 'length(clusters)' --output text 2>/dev/null || echo "0")
echo "EKS кластери: $EKS_COUNT"

# Перевірка VPC
VPC_COUNT=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-8-9" --region $REGION --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
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