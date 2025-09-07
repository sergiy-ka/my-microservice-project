# Виходи для стандартної RDS
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].endpoint, null)
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].port, null)
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].identifier, null)
}

# === Виходи для Aurora ===
output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].endpoint, null) : null
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].reader_endpoint, null) : null
}

output "aurora_cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].cluster_identifier, null) : null
}

output "aurora_cluster_members" {
  description = "Aurora cluster members"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].cluster_members, []) : []
}

# Спільні виходи
output "database_name" {
  description = "Name of the created database"
  value       = var.db_name
}

output "database_username" {
  description = "Master username for the database"
  value       = var.username
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value = var.use_aurora ? try(aws_rds_cluster.aurora[0].port, 5432) : try(aws_db_instance.standard[0].port, 5432)
}

output "database_endpoint" {
  description = "Database endpoint (main endpoint)"
  value = var.use_aurora ? try(aws_rds_cluster.aurora[0].endpoint, null) : try(aws_db_instance.standard[0].endpoint, null)
}

output "security_group_id" {
  description = "Security group ID for the database"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.default.name
}

# Корисна інформація для підключення
output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint = var.use_aurora ? try(aws_rds_cluster.aurora[0].endpoint, null) : try(aws_db_instance.standard[0].endpoint, null)
    port     = var.use_aurora ? try(aws_rds_cluster.aurora[0].port, 5432) : try(aws_db_instance.standard[0].port, 5432)
    database = var.db_name
    username = var.username
    type     = var.use_aurora ? "Aurora" : "RDS"
  }
  sensitive = true
}