FROM python:3.10-slim

# Встановлюємо системні залежності
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Створюємо робочу директорію
WORKDIR /app

# Копіюємо та встановлюємо Python залежності
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо код застосунку
COPY . .

# Створюємо користувача для безпеки
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Відкриваємо порт
EXPOSE 8000

# Команда запуску
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]