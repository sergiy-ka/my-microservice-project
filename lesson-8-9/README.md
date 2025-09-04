# Lesson 8-9: Jenkins + ArgoCD CI/CD Pipeline

Цей проект демонструє створення повного CI/CD процесу для Django застосунку з використанням Jenkins, ArgoCD, Terraform, Docker, Kubernetes (EKS) та Helm.

## Архітектура проекту

**Інфраструктура:**
- **AWS EKS** — керований Kubernetes кластер
- **AWS ECR** — реєстр Docker образів
- **AWS VPC** — мережева інфраструктура
- **Jenkins** — CI/CD автоматизація з Kaniko
- **ArgoCD** — GitOps continuous deployment
- **PostgreSQL** — база даних у Kubernetes
- **LoadBalancer** — зовнішній доступ до сервісів

**CI/CD Process:**
- **Jenkins Pipeline** — збірка Docker образу, пуш в ECR, оновлення Helm chart
- **ArgoCD Application** — автоматична синхронізація з Git репозиторієм
- **GitOps Flow** — Code Push → Jenkins Build → ECR → Chart Update → ArgoCD Sync

## Структура проекту

```
lesson-8-9/
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
│   ├── eks/                   # EKS кластер та node groups
│   ├── jenkins/               # Jenkins CI/CD через Helm
│   └── argo-cd/               # ArgoCD GitOps через Helm
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

### Крок 1: Налаштування GitHub PAT

Для забезпечення безпеки GitHub Personal Access Token передається через змінні середовища:

```bash
# Експорт GitHub PAT для Terraform
export TF_VAR_github_token="ghp_your_PAT_token_here"
```

### Крок 2: Розгортання базової інфраструктури (Target Apply)

**Важливо**: Через циклічну залежність між EKS та Helm провайдерами використовуємо поетапне розгортання.

```bash
# Ініціалізація Terraform (з локальним backend)
terraform init

# Створення тільки базової інфраструктури (target apply)
terraform apply -target=module.vpc -target=module.s3_backend -target=module.ecr -target=module.eks

# Підтвердити: yes
# Очікування: VPC, S3, ECR, EKS кластер створені
```

### Крок 3: Міграція на remote backend (S3)

```bash
# Розкоментуємо Backend.tf та переініціалізуємо з S3 backend
terraform init

# Підтверджуємо міграцію state з локального в S3: yes
```

### Крок 4: Налаштування kubectl та Jenkins secret

```bash
# Підключення до створеного EKS кластера
aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks-cluster

# Перевірка підключення до кластера
kubectl get nodes

# Створення namespace для Jenkins 
kubectl create namespace jenkins

# Створення secret з GitHub token для Jenkins
kubectl create secret generic jenkins-github-token \
  --from-literal=GITHUB_TOKEN="ghp_your_PAT_token_here" \
  -n jenkins
```

### Крок 5: Розгортання Jenkins та ArgoCD (Повний Apply)

```bash
# Тепер можемо застосувати повну конфігурацію
terraform apply

# Підтвердити: yes
# Очікування: Jenkins та ArgoCD успішно розгорнуті
```

### Крок 6: Перевірка Jenkins

```bash
# Отримання Jenkins LoadBalancer URL
kubectl get service -n jenkins

# Логін: admin / admin123
# Підтвердження скрипта в налаштуваннях Jenkins (In-process Script Approval)
# Перевірка seed-job та django-ci-cd pipeline
```

### Крок 7: Перевірка ArgoCD

```bash
# Отримання ArgoCD LoadBalancer URL
kubectl get service -n argocd

# Отримання admin паролю
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Логін: admin / <отриманий пароль>
# Перевірка django-app application
```

## Процеси збірки образів

### Автоматизований (Production) - Jenkins Pipeline
**Коли**: При кожному push в гілку lesson-8-9
**Теги**: Версіоновані `v1.0.X` (X = BUILD_NUMBER)
**Процес**: Kaniko збірка → ECR push → Chart update → ArgoCD sync

### Ручний (Development) - build-and-push-image.sh
**Коли**: Локальне тестування образу розробником
**Теги**: `manual-YYYYMMDD-HHMMSS` 
**Використання**:
```bash
# Ручна збірка та завантаження образу
./build-and-push-image.sh
```
**Примітка**: Образи з тегом `manual-*` не використовуються ArgoCD

## CI/CD Процес

### Як працює автоматизація:

1. **Пуш коду** → GitHub репозиторій (гілка lesson-8-9)
2. **Jenkins Pipeline** → автоматично запускається через SCM polling
3. **Збірка образу** → Kaniko збирає Docker образ
4. **Пуш в ECR** → образ завантажується в Amazon ECR
5. **Оновлення chart** → Jenkins оновлює тег в values.yaml
6. **ArgoCD sync** → ArgoCD підхоплює зміни та деплоїть

### Розгортання Django застосунку:

**Автоматичне розгортання (через ArgoCD):**
- ArgoCD стежить за `lesson-8-9/charts/django-app/` в Git репозиторії
- При зміні `values.yaml` (нового тегу) ArgoCD автоматично синхронізує
- Створюються: Deployment, Service (LoadBalancer), ConfigMap, HPA, PostgreSQL

**Перевірка роботи Django:**
```bash
# Статус ArgoCD application
kubectl get applications -n argocd

# Отримання зовнішньої IP адреси Django
kubectl get service django-app

# Доступ до Django застосунку
# http://<EXTERNAL-IP>

# Перевірка статусу подів
kubectl get pods -l app.kubernetes.io/name=django-app

# Детальна діагностика (якщо потрібно)
kubectl describe deployment django-app
kubectl logs -l app.kubernetes.io/name=django-app
```

**Ручне розгортання (для тестування):**
```bash
# Якщо потрібно розгорнути django-app поза ArgoCD
helm install django-app charts/django-app

# Або оновити вручну
helm upgrade django-app charts/django-app
```

### Доступ до застосунку:

```bash
# Django застосунок (через ArgoCD)
kubectl get service django-app

# Jenkins UI
kubectl get service -n jenkins

# ArgoCD UI  
kubectl get service -n argocd
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
aws ecr batch-delete-image --repository-name lesson-8-9-django-app --image-ids imageTag=latest --region us-west-2
aws ecr delete-repository --repository-name lesson-8-9-django-app --force --region us-west-2
```

### Верифікація очищення

```bash
# Перевірка повного видалення
aws ecr describe-repositories --region us-west-2       # має бути порожньо
aws eks list-clusters --region us-west-2               # має бути порожньо  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=lesson-8-9" --region us-west-2  # порожньо
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
