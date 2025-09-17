variable "name" {
  description = "Назва інстансу або кластера"
  type        = string
}

variable "use_aurora" {
  description = "Використовувати Aurora кластер замість звичайної RDS"
  type        = bool
  default     = false
}

# RDS-only змінні
variable "engine" {
  description = "Тип БД для звичайної RDS (postgres, mysql, mariadb тощо)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Версія БД для звичайної RDS"
  type        = string
  default     = "17.2"
}

variable "parameter_group_family_rds" {
  description = "Сімейство параметрів для звичайної RDS"
  type        = string
  default     = "postgres17"
}

variable "allocated_storage" {
  description = "Розмір сховища в ГБ для звичайної RDS"
  type        = number
  default     = 20
}

# Aurora-only змінні
variable "engine_cluster" {
  description = "Тип БД для Aurora кластера"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Версія БД для Aurora кластера"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_aurora" {
  description = "Сімейство параметрів для Aurora кластера"
  type        = string
  default     = "aurora-postgresql15"
}

variable "aurora_instance_count" {
  description = "Кількість інстансів в Aurora кластері (включно з writer)"
  type        = number
  default     = 2
}

variable "aurora_replica_count" {
  description = "Кількість read-only реплік в Aurora кластері"
  type        = number
  default     = 1
}

# Спільні змінні
variable "instance_class" {
  description = "Клас інстансу БД"
  type        = string
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "Ім'я бази даних, яка буде створена"
  type        = string
}

variable "username" {
  description = "Ім'я користувача адміністратора БД"
  type        = string
}

variable "password" {
  description = "Пароль адміністратора БД"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID VPC, де буде створена БД"
  type        = string
}

variable "subnet_private_ids" {
  description = "Список ID приватних сабнетів"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "Список ID публічних сабнетів"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Чи має бути БД доступна з інтернету"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ розгортання"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Кількість днів для збереження резервних копій"
  type        = number
  default     = 7
}

variable "parameters" {
  description = "Словник параметрів для налаштування БД"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}