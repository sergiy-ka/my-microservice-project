#!/bin/bash

# Налаштування
REGION="us-west-2"
REPOSITORY_NAME="lesson-10-django-app"

echo "Початок очищення AWS ресурсів lesson-10..."

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

# Крок 3: Очікування видалення всіх типів LoadBalancer
echo "3. Очікування видалення LoadBalancer..."
TIMEOUT=300  # 5 хвилин максимум
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    # Перевірка Application/Network Load Balancers (ELBv2)
    ALB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
    # Перевірка Classic Load Balancers (ELB)
    CLB_COUNT=$(aws elb describe-load-balancers --region $REGION --query 'length(LoadBalancerDescriptions)' --output text 2>/dev/null || echo "0")
    
    if [ "$ALB_COUNT" == "0" ] && [ "$CLB_COUNT" == "0" ]; then
        echo "Всі LoadBalancer видалені успішно!"
        break
    fi
    echo "LoadBalancer ще існує (ALB: $ALB_COUNT, CLB: $CLB_COUNT), очікування... ($ELAPSED/$TIMEOUT секунд)"
    sleep 30
    ELAPSED=$((ELAPSED + 30))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "УВАГА: LoadBalancer не видалився за 5 хвилин."
    echo "Примусове видалення залишкових LoadBalancer..."
    
    # Примусове видалення ALB/NLB
    aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[].LoadBalancerArn' --output text | tr '\t' '\n' | while read lb_arn; do
        if [[ "$lb_arn" != "" ]]; then
            echo "  Видаляємо ALB/NLB: $lb_arn"
            aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn --region $REGION 2>/dev/null
        fi
    done
    
    # Примусове видалення Classic LB
    aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text | tr '\t' '\n' | while read lb_name; do
        if [[ "$lb_name" != "" ]]; then
            echo "  Видаляємо Classic LB: $lb_name"
            aws elb delete-load-balancer --load-balancer-name $lb_name --region $REGION 2>/dev/null
        fi
    done
    
    echo "Очікування завершення видалення LoadBalancer..."
    sleep 60
fi

# Крок 4: Видалення Terraform інфраструктури
echo "4. Видалення Terraform інфраструктури..."
terraform destroy -auto-approve

# Крок 4.1: Примусове очищення залишкових мережевих ресурсів
echo "4.1. Перевірка та очищення залишкових VPC компонентів..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-10" --region $REGION --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [[ "$VPC_ID" != "None" && "$VPC_ID" != "" && "$VPC_ID" != "null" ]]; then
    echo "Знайдено VPC: $VPC_ID. Примусове очищення..."
    
    # Видалення Elastic IPs
    echo "  - Видалення Elastic IP адрес..."
    aws ec2 describe-addresses --region $REGION --query 'Addresses[?Domain==`vpc`].AllocationId' --output text | tr '\t' '\n' | while read eip_id; do
        if [[ "$eip_id" != "" ]]; then
            echo "    Звільняємо Elastic IP: $eip_id"
            aws ec2 release-address --allocation-id $eip_id --region $REGION 2>/dev/null || echo "    Не вдалося звільнити EIP: $eip_id"
        fi
    done
    
    # Видалення Security Groups (окрім default) - покращена версія
    echo "  - Видалення Security Groups..."
    for attempt in 1 2 3; do
        echo "    Спроба $attempt видалення Security Groups..."
        aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
            if [[ "$sg_id" != "" ]]; then
                echo "    Видаляємо Security Group: $sg_id"
                aws ec2 delete-security-group --group-id $sg_id --region $REGION 2>/dev/null || echo "    Не вдалося видалити SG: $sg_id (спроба $attempt)"
            fi
        done
        sleep 10
    done
    
    # Видалення Network Interfaces
    echo "  - Видалення Network Interfaces..."
    aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' --output text | tr '\t' '\n' | while read eni_id; do
        if [[ "$eni_id" != "" ]]; then
            echo "    Видаляємо ENI: $eni_id"
            aws ec2 delete-network-interface --network-interface-id $eni_id --region $REGION 2>/dev/null || echo "    Не вдалося видалити ENI: $eni_id"
        fi
    done
    
    # Очікуємо трохи для завершення операцій
    echo "  - Очікування завершення мережевих операцій..."
    sleep 30
    
    # Спроба видалити VPC вручну
    echo "  - Спроба видалити VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null && echo "    VPC видалено успішно!" || echo "    VPC все ще існує, можливо є залежності"
else
    echo "VPC з тегом Project=lesson-10 не знайдено"
fi

# Крок 5: Очищення ECR (якщо не видалився)
echo "5. Перевірка та очищення ECR..."
if aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення всіх образів з ECR..."
    # Спочатку видаляємо всі образи
    IMAGE_TAGS=$(aws ecr list-images --repository-name $REPOSITORY_NAME --region $REGION --query 'imageIds[*].[imageTag]' --output text 2>/dev/null)
    if [[ "$IMAGE_TAGS" != "" ]]; then
        echo "  Знайдені образи, видаляємо..."
        aws ecr batch-delete-image --repository-name $REPOSITORY_NAME --region $REGION --image-ids "$(aws ecr list-images --repository-name $REPOSITORY_NAME --region $REGION --query 'imageIds[]' --output json)" >/dev/null 2>&1
    fi
    # Потім видаляємо репозиторій
    aws ecr delete-repository --repository-name $REPOSITORY_NAME --force --region $REGION >/dev/null 2>&1
    echo "ECR репозиторій повністю видалений"
else
    echo "ECR вже видалений"
fi

# Крок 5.1: Очищення S3 bucket для Terraform state
echo "5.1. Очищення S3 bucket..."
BUCKET_NAME="terraform-state-bucket-lesson10-sergiy-2025"
if aws s3api head-bucket --bucket $BUCKET_NAME --region $REGION >/dev/null 2>&1; then
    echo "Видалення об'єктів з S3 bucket..."
    # Видаляємо всі версії та delete markers
    aws s3api list-object-versions --bucket $BUCKET_NAME --region $REGION --query 'DeleteMarkers[].[Key,VersionId]' --output text | while read key vid; do
        if [[ "$key" != "" && "$vid" != "" ]]; then
            aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$vid" --region $REGION >/dev/null 2>&1
        fi
    done
    aws s3api list-object-versions --bucket $BUCKET_NAME --region $REGION --query 'Versions[].[Key,VersionId]' --output text | while read key vid; do
        if [[ "$key" != "" && "$vid" != "" ]]; then
            aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$vid" --region $REGION >/dev/null 2>&1
        fi
    done
    # Звичайне очищення
    aws s3 rm s3://$BUCKET_NAME --recursive >/dev/null 2>&1
    # Видалення bucket
    aws s3api delete-bucket --bucket $BUCKET_NAME --region $REGION >/dev/null 2>&1
    echo "S3 bucket повністю очищено"
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

# Перевірка RDS
RDS_COUNT=$(aws rds describe-db-instances --region $REGION --query 'length(DBInstances)' --output text 2>/dev/null || echo "0")
echo "RDS інстанси: $RDS_COUNT"

# Перевірка Aurora
AURORA_COUNT=$(aws rds describe-db-clusters --region $REGION --query 'length(DBClusters)' --output text 2>/dev/null || echo "0")
echo "Aurora кластери: $AURORA_COUNT"

# Перевірка VPC (оновлено для lesson-10)
VPC_COUNT=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-10" --region $REGION --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
echo "Project VPC: $VPC_COUNT"

# Перевірка LoadBalancer (всіх типів)
ALB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
CLB_COUNT=$(aws elb describe-load-balancers --region $REGION --query 'length(LoadBalancerDescriptions)' --output text 2>/dev/null || echo "0")
TOTAL_LB_COUNT=$((ALB_COUNT + CLB_COUNT))
echo "Load Balancers: $TOTAL_LB_COUNT (ALB/NLB: $ALB_COUNT, Classic: $CLB_COUNT)"

echo ""
if [[ "$ECR_COUNT" == "0" && "$EKS_COUNT" == "0" && "$VPC_COUNT" == "0" && "$RDS_COUNT" == "0" && "$AURORA_COUNT" == "0" ]]; then
    echo "Всі ресурси успішно видалені!"
else
    echo "Деякі ресурси можуть залишитися. Перевірте AWS консоль."
    echo "RDS/Aurora ресурси можуть потребувати додаткового часу для видалення."
fi

echo ""