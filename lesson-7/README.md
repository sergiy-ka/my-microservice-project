# Lesson 7: Helm та Kubernetes (EKS) розгортання

Цей проект демонструє створення повної інфраструктури для Django застосунку з використанням Terraform, Docker, Kubernetes (EKS) та Helm.

## Архітектура проекту

**Інфраструктура:**
- **AWS EKS** — керований Kubernetes кластер
- **AWS ECR** — реєстр Docker образів
- **AWS VPC** — мережева інфраструктура з lesson-5
- **PostgreSQL** — база даних у Kubernetes
- **LoadBalancer** — зовнішній доступ до застосунку

**Компоненти застосунку:**
- **Django** — веб-застосунок (2-6 реплік з HPA)
- **PostgreSQL** — база даних (1 репліка)
- **ConfigMap** — конфігурація та змінні середовища

## Структура проекту

```
lesson-7/
├── main.tf                    # Головний Terraform файл
├── backend.tf                 # S3 backend конфігурація
├── outputs.tf                 # Terraform outputs
├── Dockerfile                 # Django образ
├── build-and-push-image.sh    # Скрипт завантаження в ECR
├── myproject/                 # Django проект з lesson-4
├── modules/                   # Terraform модулі
│   ├── s3-backend/            # S3 + DynamoDB для Terraform state
│   ├── vpc/                   # VPC інфраструктура
│   ├── ecr/                   # Elastic Container Registry
│   └── eks/                   # EKS кластер та node groups
└── charts/django-app/         # Helm chart
    ├── Chart.yaml             # Метадані chart
    ├── values.yaml            # Конфігурація
    └── templates/             # Kubernetes шаблони
        ├── configmap.yaml     # Змінні середовища
        ├── deployment.yaml    # Django застосунок
        ├── service.yaml       # LoadBalancer сервіс
        ├── hpa.yaml           # Horizontal Pod Autoscaler
        ├── postgres.yaml      # PostgreSQL бази даних
        └── _helpers.tpl       # Helm helper функції
```

## Інструкції по розгортанню

### Передумови

- AWS CLI налаштований з відповідними правами доступу
- Terraform >= 1.0
- Docker Desktop запущений
- kubectl встановлений
- Helm >= 3.0

### Крок 1: Розгортання інфраструктури

```bash
# Ініціалізація Terraform (з локальним backend)
terraform init

# Перевірка плану
terraform plan

# Розгортання інфраструктури
terraform apply
```

### Крок 2: Міграція на remote backend (S3)

**Важливо**: Після створення S3 bucket та DynamoDB потрібно мігрувати state.

```bash
# Розкоментовуємо backend.tf
sed -i 's/^#//g' backend.tf

# Переініціалізуємо з remote backend
terraform init

# Підтверджуємо міграцію: yes
```

### Крок 3: Налаштування kubectl

```bash
# Підключення до EKS кластера
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks-cluster

# Перевірка підключення
kubectl get nodes
```

### Крок 4: Завантаження Docker образу

```bash
# Побудова та завантаження Django образу в ECR
./build-and-push-image.sh
```

### Крок 5: Розгортання застосунку

```bash
# Перевірка Helm chart
helm lint charts/django-app

# Розгортання застосунку
helm install django-app charts/django-app

# Перевірка статусу
helm status django-app
kubectl get all -l app.kubernetes.io/name=django-app
```

## Доступ до застосунку

Після успішного розгортання застосунок буде доступний через LoadBalancer:

```bash
# Отримання зовнішньої IP адреси
kubectl get service django-app

# Доступ до Django
# http://<EXTERNAL-IP>
```

## Корисні команди

### Моніторинг та діагностика

```bash
# Перевірка статусу подів
kubectl get pods

# Перегляд логів Django
kubectl logs -l app.kubernetes.io/name=django-app,component!=database

# Перегляд логів PostgreSQL
kubectl logs -l component=database

# Перевірка HPA
kubectl get hpa

# Перевірка ConfigMap
kubectl describe configmap django-app-config
```

### Масштабування

```bash
# Ручне масштабування (якщо HPA відключено)
kubectl scale deployment django-app --replicas=4

# Перевірка автомасштабування
kubectl top pods
```

### Оновлення застосунку

```bash
# Оновлення образу
./build-and-push-image.sh

# Оновлення Helm chart
helm upgrade django-app charts/django-app

# Рестарт deployment
kubectl rollout restart deployment django-app
```

## Конфігурація

### Helm Values

Основні параметри налаштовуються у файлі `charts/django-app/values.yaml`:

- **replicaCount**: кількість подів Django (за замовчуванням: 2)
- **image.repository**: ECR репозиторій
- **service.type**: тип сервісу (LoadBalancer)
- **autoscaling**: налаштування HPA (2-6 подів при CPU > 70%)
- **config**: змінні середовища Django та PostgreSQL

### Змінні середовища

ConfigMap містить наступні змінні:
- `POSTGRES_HOST=db`
- `POSTGRES_PORT=5432`
- `POSTGRES_DB=myproject_db`
- `POSTGRES_USER=myproject_user`
- `POSTGRES_PASSWORD=secret_password`
- `DEBUG=True`
- `ALLOWED_HOSTS=*`

## Очищення ресурсів

**КРИТИЧНО ВАЖЛИВО**: Правильна послідовність видалення запобігає проблемам з залежностями та зависанню процесу.

### Автоматизоване очищення (рекомендовано)

Для швидкого і надійного видалення всіх ресурсів використовуйте скрипт:

```bash
# Запуск автоматичного очищення
./cleanup-aws-resources.sh
```

Скрипт автоматично:
1. Видалить Helm застосунок і чекатиме видалення LoadBalancer
2. Виконає `terraform destroy`
3. Очистить залишкові ECR образи та S3 bucket
4. Перевірить повне видалення всіх ресурсів

### Ручне очищення (покрокове)

Якщо потрібно ручне управління процесом:

```bash
# 1. Видалення Kubernetes ресурсів
helm uninstall django-app

# 2. Очікування видалення AWS LoadBalancer (2-5 хвилин)
aws elbv2 describe-load-balancers --region us-west-2

# 3. Видалення Terraform інфраструктури
terraform destroy

# 4. Очищення залишків (якщо потрібно)
aws ecr batch-delete-image --repository-name lesson-7-django-app --image-ids imageTag=latest --region us-west-2
aws ecr delete-repository --repository-name lesson-7-django-app --force --region us-west-2
```

### Верифікація очищення

```bash
# Перевірка повного видалення
aws ecr describe-repositories --region us-west-2       # має бути порожньо
aws eks list-clusters --region us-west-2               # має бути порожньо  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-7" --region us-west-2  # порожньо
```

## Troubleshooting

### Поширені проблеми

1. **Поди в стані CrashLoopBackOff**
   ```bash
   kubectl logs <pod-name>
   kubectl describe pod <pod-name>
   ```

2. **LoadBalancer не отримує зовнішню IP**
   ```bash
   kubectl describe service django-app
   ```

3. **Django не може підключитися до БД**
   ```bash
   kubectl logs -l component=database
   kubectl exec -it <django-pod> -- env
   ```

4. **HPA показує unknown metrics**
   ```bash
   kubectl top nodes
   kubectl top pods
   ```

## Додаткові ресурси

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Documentation](https://docs.djangoproject.com/)
