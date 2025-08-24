# Lesson 5: Infrastructure as Code (Terraform)

Цей проект демонструє створення AWS інфраструктури за допомогою Terraform з використанням модульної архітектури.

## Структура проекту

```
lesson-5/
├── main.tf                # Головний файл для підключення модулів
├── backend.tf             # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf             # Загальне виведення ресурсів
├── modules/               # Каталог з усіма модулями
│   ├── s3-backend/        # Модуль для S3 та DynamoDB
│   │   ├── s3.tf          # Створення S3-бакета
│   │   ├── dynamodb.tf    # Створення DynamoDB
│   │   ├── variables.tf   # Змінні для S3
│   │   └── outputs.tf     # Виведення інформації про S3 та DynamoDB
│   ├── vpc/               # Модуль для VPC
│   │   ├── vpc.tf         # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf      # Налаштування маршрутизації
│   │   ├── variables.tf   # Змінні для VPC
│   │   └── outputs.tf     # Виведення інформації про VPC
│   └── ecr/               # Модуль для ECR
│       ├── ecr.tf         # Створення ECR репозиторію
│       ├── variables.tf   # Змінні для ECR
│       └── outputs.tf     # Виведення URL репозиторію ECR
└── README.md              # Документація проєкту
```

## Що створює цей проект

### 1. S3 Backend Module
- **S3 Bucket**: Для зберігання Terraform state файлів
- **Versioning**: Увімкнуте версіювання для збереження історії стейтів
- **Encryption**: Server-side шифрування AES256
- **DynamoDB Table**: Для блокування стейтів під час виконання операцій

### 2. VPC Module
- **VPC**: Virtual Private Cloud з CIDR блоком 10.0.0.0/16
- **Public Subnets**: 3 публічні підмережі в різних AZ
- **Private Subnets**: 3 приватні підмережі в різних AZ
- **Internet Gateway**: Для доступу публічних підмереж до інтернету
- **NAT Gateways**: Для доступу приватних підмереж до інтернету
- **Route Tables**: Налаштування маршрутизації

### 3. ECR Module
- **ECR Repository**: Elastic Container Registry для зберігання Docker-образів
- **Image Scanning**: Автоматичне сканування образів на вразливості
- **Lifecycle Policy**: Автоматичне управління життєвим циклом образів
- **Repository Policy**: Налаштування доступу до репозиторію

## Передумови

1. **AWS CLI** встановлений і налаштований
2. **Terraform** версії >= 1.0
3. **Права доступу AWS** з необхідними дозволами для створення:
    - S3 buckets
    - DynamoDB tables
    - VPC та мережеві ресурси
    - ECR repositories

## Команди для розгортання

### Крок 1: Ініціалізація Terraform
```bash
cd lesson-5
terraform init
```

### Крок 2: Перевірка плану
```bash
terraform plan
```

### Крок 3: Застосування змін
```bash
terraform apply
```

### Крок 4: Налаштування remote backend (після створення S3 та DynamoDB)
1. Розкоментуйте секцію в `backend.tf`
2. Переініціалізуйте Terraform:
```bash
terraform init
```
3. Підтвердіть міграцію стейту до S3

### Крок 5: Перевірка результатів
```bash
terraform output
```

## Команди для управління

### Показати поточний стейт
```bash
terraform show
```

### Показати outputs
```bash
terraform output
```

### Оновити стейт
```bash
terraform refresh
```

### Знищення інфраструктури
```bash
terraform destroy
```

## Важливі примітки

1. **Унікальність S3 bucket**: Переконайтеся, що ім'я S3 bucket унікальне глобально
2. **Backend налаштування**: Спочатку створіть S3 та DynamoDB, потім увімкніть remote backend
3. **Costs**: Пам'ятайте про витрати на NAT Gateways та інші ресурси
4. **Security**: Всі ресурси налаштовані з базовими security практиками

## Змінні

Основні змінні можна налаштувати в `main.tf`:
- `aws_region`: AWS регіон (за замовчуванням: us-west-2)
- `environment`: Середовище (за замовчуванням: dev)
- `bucket_name`: Ім'я S3 bucket для стейту

## Outputs

Після успішного розгортання ви отримаєте:
- URL S3 bucket для стейтів
- VPC ID та subnet IDs
- URL ECR repository
- Інші важливі ідентифікатори ресурсів

## Troubleshooting

### Помилка "bucket already exists"
- Змініть значення `bucket_name` на унікальне

### Помилка доступу
- Перевірте AWS credentials: `aws sts get-caller-identity`

### Проблеми з backend
- Переконайтеся, що S3 bucket і DynamoDB table створені перед увімкненням backend