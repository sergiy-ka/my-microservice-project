#!/bin/bash

# Налаштування
REGION="us-west-2"
REPOSITORY_NAME="lesson-8-9-django-app"

echo "Початок очищення AWS ресурсів lesson-8-9..."

# Крок 1: Видалення Helm застосунків
echo "1. Видалення Helm застосунків..."
helm uninstall django-app 2>/dev/null || echo "Django app Helm release не знайдено"
helm uninstall jenkins -n jenkins 2>/dev/null || echo "Jenkins Helm release не знайдено"
helm uninstall argo-cd -n argocd 2>/dev/null || echo "Argo CD Helm release не знайдено"
helm uninstall argo-cd-apps -n argocd 2>/dev/null || echo "Argo CD Apps Helm release не знайдено"

# Крок 2: Видалення namespace
echo "2. Видалення namespace..."
kubectl delete namespace jenkins --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# Крок 3: Очікування видалення LoadBalancer
echo "3. Очікування видалення LoadBalancer..."
TIMEOUT=300  # 5 хвилин максимум
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    ELB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
    if [ "$ELB_COUNT" == "0" ]; then
        echo "LoadBalancer видалений успішно!"
        break
    fi
    echo "LoadBalancer ще існує, очікування... ($ELAPSED/$TIMEOUT секунд)"
    sleep 30
    ELAPSED=$((ELAPSED + 30))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "УВАГА: LoadBalancer не видалився за 5 хвилин. Продовжуємо..."
fi

# Крок 4: Видалення Terraform інфраструктури
echo "4. Видалення Terraform інфраструктури..."
terraform destroy -auto-approve

# Крок 5: Очищення ECR (якщо не видалився)
echo "5. Перевірка та очищення ECR..."
if aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення образів з ECR..."
    aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --image-ids imageTag=latest --region $REGION >/dev/null 2>&1
    echo "Видалення ECR репозиторію..."
    aws ecr delete-repository --repository-name $REPOSITORY_NAME --force --region $REGION >/dev/null 2>&1
    echo "ECR очищено"
else
    echo "ECR вже видалений"
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