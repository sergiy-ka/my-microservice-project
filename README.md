# Мій власний мікросервісний проєкт
Це репозиторій для навчального проєкту в межах курсу "DevOps CI/CD".

## Мета
Навчитися основам роботи з Git і GitHub.

# Docker Django Project (Lesson 4)

Мікросервісний проєкт на Django з використанням Docker та Docker Compose для контейнеризації.

## Архітектура

**Docker-інфраструктура:**
- **Django** — веб-застосунок (порт 8000)
- **PostgreSQL** — база даних (порт 5432)
- **Nginx** — reverse proxy (порт 80)

## Структура проєкту

```
my-microservice-project/
├── myproject/           # Django проєкт
│   ├── settings.py     # Налаштування Django
│   ├── urls.py         # URL маршрути
│   └── ...
├── nginx/
│   └── nginx.conf      # Nginx конфігурація
├── docker-compose.yml  # Оркестрація сервісів
├── Dockerfile          # Django контейнер
├── requirements.txt    # Python залежності
├── manage.py           # Django управління
└── .gitignore          # Git ігнор файли
```

## Інструкція по запуску

### Запуск проєкту

```bash
# Клонуємо репозиторій
git clone <repository-url>
cd my-microservice-project

# Переключаємося на гілку lesson-4
git checkout lesson-4

# Запускаємо всі сервіси
docker-compose up -d

# Перевіряємо статус контейнерів
docker-compose ps
```

### Доступ до застосунку

- **Через Nginx:** http://localhost
- **Прямий доступ до Django:** http://localhost:8000
- **PostgreSQL:** localhost:5432

### Корисні команди

```bash
# Зупинка всіх сервісів
docker-compose down

# Перегляд логів
docker-compose logs web

# Виконання Django команд
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser

# Перебудова контейнерів після змін
docker-compose up --build
```

## Конфігурація

- **Django:** налаштований для роботи з PostgreSQL
- **PostgreSQL:** база даних `myproject_db`, користувач `myproject_user`
- **Nginx:** проксує запити з порту 80 на Django (порт 8000)