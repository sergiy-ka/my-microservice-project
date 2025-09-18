# Final Project: DevOps Infrastructure з Prometheus та Grafana

Цей проект демонструє створення повного CI/CD процесу для Django застосунку з використанням Jenkins, ArgoCD, Terraform, Docker, Kubernetes (EKS), Helm, універсального RDS/Aurora модуля для баз даних та системи моніторингу на базі Prometheus та Grafana.

## Архітектура проекту

**Інфраструктура:**
- **AWS EKS** — керований Kubernetes кластер
- **AWS ECR** — реєстр Docker образів
- **AWS VPC** — мережева інфраструктура
- **AWS RDS/Aurora** — керована база даних (універсальний модуль)
- **Jenkins** — CI/CD автоматизація з Kaniko
- **ArgoCD** — GitOps continuous deployment
- **Prometheus** — система збору та зберігання метрик
- **Grafana** — візуалізація метрик та дашборди
- **LoadBalancer** — зовнішній доступ до сервісів

**CI/CD Process:**
- **Jenkins Pipeline** — збірка Docker образу, пуш в ECR, оновлення Helm chart
- **ArgoCD Application** — автоматична синхронізація з Git репозиторієм
- **GitOps Flow** — Code Push → Jenkins Build → ECR → Chart Update → ArgoCD Sync

## Структура проекту

```
final-project/
├── main.tf                    # Головний Terraform файл
├── backend.tf                 # S3 backend конфігурація
├── outputs.tf                 # Terraform outputs
├── Dockerfile                 # Django образ
├── Jenkinsfile                # Jenkins Pipeline
├── build-and-push-image.sh    # Скрипт завантаження в ECR
├── cleanup-aws-resources.sh   # Автоматичне очищення ресурсів
├── myproject/                 # Django проект
├── modules/                   # Terraform модулі
│   ├── s3-backend/            # S3 + DynamoDB для Terraform state
│   ├── vpc/                   # VPC інфраструктура
│   ├── ecr/                   # Elastic Container Registry
│   ├── eks/                   # EKS кластер та node groups
│   ├── jenkins/               # Jenkins CI/CD через Helm
│   ├── argo-cd/               # ArgoCD GitOps через Helm
│   ├── prometheus/            # Prometheus моніторинг через Helm
│   ├── grafana/               # Grafana візуалізація через Helm
│   └── rds/                   # RDS/Aurora универсальний модуль
└── charts/django-app/         # Helm chart
    ├── Chart.yaml             # Метадані chart
    ├── values.yaml            # Конфігурація
    └── templates/             # Kubernetes шаблони
        ├── configmap.yaml     # Змінні середовища
        ├── deployment.yaml    # Django застосунок
        ├── service.yaml       # LoadBalancer сервіс
        ├── hpa.yaml           # Horizontal Pod Autoscaler
        ├── postgres.yaml      # PostgreSQL бази даних (опціонально)
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
terraform apply -target=module.vpc -target=module.s3_backend -target=module.ecr -target=module.eks -target=module.rds

# Підтвердити: yes
# Очікування: VPC, S3, ECR, EKS кластер та RDS база даних створені
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
aws eks update-kubeconfig --region us-west-2 --name final-project-eks-cluster

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
**Коли**: При кожному push в гілку final-project
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

1. **Пуш коду** → GitHub репозиторій (гілка final-project)
2. **Jenkins Pipeline** → автоматично запускається через SCM polling
3. **Збірка образу** → Kaniko збирає Docker образ
4. **Пуш в ECR** → образ завантажується в Amazon ECR
5. **Оновлення chart** → Jenkins оновлює тег в values.yaml
6. **ArgoCD sync** → ArgoCD підхоплює зміни та деплоїть

### Розгортання Django застосунку:

**Автоматичне розгортання (через ArgoCD):**
- ArgoCD стежить за `final-project/charts/django-app/` в Git репозиторії
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

## RDS/Aurora Модуль

### Універсальний модуль бази даних

Проект включає гнучкий модуль `modules/rds/`, який може створювати:

**RDS Instance** (use_aurora = false):
- Звичайна керована база даних AWS
- PostgreSQL, MySQL, MariaDB підтримка
- Multi-AZ для відмовостійкості
- Автоматичні резервні копії
- Налаштовувані parameter groups

**Aurora Cluster** (use_aurora = true):
- Високопродуктивний кластер Aurora
- Автоматичне масштабування читання
- До 15 read replicas
- Швидше відновлення після збоїв
- Кращі показники продуктивності

### Налаштування бази даних

**Перемикання між RDS та Aurora:**
```bash
# У main.tf змініть параметр:
use_aurora = false  # Звичайна RDS
use_aurora = true   # Aurora кластер
```

**Основні параметри конфігурації:**
- `engine`: postgres, mysql, mariadb
- `engine_version`: версія БД
- `instance_class`: розмір інстансу (db.t3.micro, db.r6g.large)
- `allocated_storage`: розмір диску (тільки для RDS)
- `multi_az`: відмовостійкість в кількох AZ
- `parameters`: налаштування PostgreSQL/MySQL

### Перевірка роботи RDS/Aurora

```bash
# Отримання інформації про базу даних
terraform output database_endpoint
terraform output database_port
terraform output database_type

# Для Aurora - додаткові endpoints
terraform output aurora_cluster_endpoint    # writer
terraform output aurora_reader_endpoint     # читання

# Перевірка підключення з Kubernetes
kubectl exec -it <django-pod> -- python manage.py dbshell
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

## Моніторинг з Prometheus та Grafana

### Огляд системи моніторингу

Проект включає повноцінну систему моніторингу на базі:

**Prometheus:**
- Збір метрик з Kubernetes API серверів
- Моніторинг node metrics через Node Exporter
- Збір метрик контейнерів через cAdvisor
- Зберігання метрик з retention period 15 днів
- Alertmanager для сповіщень

**Grafana:**
- Візуалізація метрик через дашборди
- Готові дашборди для Kubernetes
- Кастомні дашборди для Django застосунку
- Інтеграція з Prometheus як data source

### Крок 8: Перевірка моніторингу

Після розгортання інфраструктури перевірте статус моніторингу:

```bash
# Перевірка статусу подів моніторингу
kubectl get pods -n monitoring

# Перевірка сервісів моніторингу
kubectl get services -n monitoring

# Статус всіх ресурсів моніторингу
kubectl get all -n monitoring
```

### Доступ до Prometheus

```bash
# Port-forward до Prometheus (порт 9090)
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Або отримання команди з Terraform outputs
terraform output prometheus_port_forward_command
```

Відкрийте у браузері: http://localhost:9090

**Корисні PromQL запити:**
- `up` - статус всіх targets
- `rate(container_cpu_usage_seconds_total[5m])` - CPU usage
- `container_memory_usage_bytes / 1024 / 1024` - Memory usage (MB)
- `kube_pod_container_status_restarts_total` - Pod restarts

### Доступ до Grafana

```bash
# Port-forward до Grafana (порт 3000)
kubectl port-forward -n monitoring svc/grafana 3000:80

# Або отримання команди з Terraform outputs
terraform output grafana_port_forward_command
```

Відкрийте у браузері: http://localhost:3000

**Логін:**
- Username: `admin`
- Password: `admin123`

### Доступні дашборди

**Автоматично імпортовані дашборди:**
1. **Node Exporter Full** (ID: 1860) - системні метрики серверів
2. **Kubernetes Cluster Monitoring** (ID: 315) - огляд кластера
3. **Kubernetes Deployments** (ID: 8588) - метрики deployments
4. **Kubernetes Pods** (ID: 6417) - моніторинг подів

**Кастомні дашборди:**
1. **Kubernetes Overview** - загальний огляд кластера
2. **Django Application Monitoring** - моніторинг Django застосунку

### Налаштування алертів

Prometheus включає базові правила для алертів. Alertmanager налаштований для обробки сповіщень:

```bash
# Доступ до Alertmanager
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:80
```

### Моніторинг Django застосунку

Для моніторингу Django застосунку доступні метрики:

```bash
# CPU використання Django подів
container_cpu_usage_seconds_total{pod=~"django-app-.*"}

# Memory використання Django подів
container_memory_usage_bytes{pod=~"django-app-.*"}

# Кількість рестартів Django подів
kube_pod_container_status_restarts_total{pod=~"django-app-.*"}

# Статус Django подів
up{job="kubernetes-pods", kubernetes_pod_name=~"django-app-.*"}
```

### Команди моніторингу

```bash
# Отримання команд доступу до всіх сервісів моніторингу
terraform output monitoring_access_commands

# Перегляд метрик Prometheus
terraform output prometheus_server_url

# Отримання паролю Grafana
terraform output grafana_admin_password

# Перевірка targets Prometheus
curl http://localhost:9090/api/v1/targets (після port-forward)

# Перевірка health Prometheus
curl http://localhost:9090/api/v1/status/config
```

### Troubleshooting моніторингу

**Проблеми з Prometheus:**
```bash
# Логи Prometheus server
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server

# Конфігурація Prometheus
kubectl describe configmap -n monitoring prometheus-server

# Статус targets
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Перейти на http://localhost:9090/targets
```

**Проблеми з Grafana:**
```bash
# Логи Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Перевірка persistent volume
kubectl get pvc -n monitoring

# Ресетування паролю admin
kubectl delete secret -n monitoring grafana
terraform apply  # перестворить з новим паролем
```

**Проблеми з метриками:**
```bash
# Перевірка Node Exporter
kubectl get daemonset -n monitoring
kubectl logs -n monitoring -l app.kubernetes.io/name=node-exporter

# Перевірка кластерних метрик
kubectl top nodes
kubectl top pods -n monitoring
```

## Очищення ресурсів

**КРИТИЧНО ВАЖЛИВО**: Правильна послідовність видалення запобігає проблемам з залежностями та зависанню процесу.

### Автоматизоване очищення (рекомендовано)

Для швидкого і надійного видалення всіх ресурсів використовуйте скрипт:

```bash
# Запуск автоматичного очищення
# ВАЖЛИВО!!! - backend.tf має бути в розкоментованому виді 
./cleanup-aws-resources.sh
```

Скрипт автоматично:
1. Видалить Helm застосунок і чекатиме видалення LoadBalancer
2. Виконає `terraform destroy` (включно з RDS/Aurora)
3. **Примусове очистить залишкові VPC компоненти** (Security Groups, ENIs)
4. Очистить залишкові ECR образи та S3 bucket
5. Перевірить повне видалення всіх ресурсів (включно з RDS)

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
aws ecr batch-delete-image --repository-name final-project-django-app --image-ids imageTag=latest --region us-west-2
aws ecr delete-repository --repository-name final-project-django-app --force --region us-west-2
```

### Верифікація очищення

```bash
# Перевірка повного видалення
aws ecr describe-repositories --region us-west-2       # має бути порожньо
aws eks list-clusters --region us-west-2               # має бути порожньо  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=final-project" --region us-west-2  # порожньо
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

5. **RDS/Aurora підключення не працює**
   ```bash
   # Перевірка статусу RDS в AWS
   aws rds describe-db-instances --region us-west-2
   
   # Для Aurora
   aws rds describe-db-clusters --region us-west-2
   
   # Перевірка Terraform outputs
   terraform output database_endpoint
   terraform output database_port
   
   # Перевірка security group
   terraform output rds_security_group_id
   aws ec2 describe-security-groups --group-ids <security-group-id>
   ```

6. **Aurora read replicas не працюють**
   ```bash
   # Перевірка всіх endpoints
   terraform output aurora_cluster_endpoint
   terraform output aurora_reader_endpoint
   
   # Статус кластера Aurora
   aws rds describe-db-clusters --db-cluster-identifier final-project-db-cluster
   ```

## Додаткові ресурси

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Documentation](https://docs.djangoproject.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards Library](https://grafana.com/grafana/dashboards/)
