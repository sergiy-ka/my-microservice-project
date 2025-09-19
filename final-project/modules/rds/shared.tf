# Subnet group (використовується обома типами БД)
resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

# Security group (використовується обома типами БД)
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name} database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Обмежити в продакшні
    description = "PostgreSQL access"
  }

  # Додаткове правило для MySQL, якщо потрібно
  dynamic "ingress" {
    for_each = contains(["mysql", "aurora-mysql"], var.use_aurora ? var.engine_cluster : var.engine) ? [1] : []
    content {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Обмежити в продакшні
      description = "MySQL access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}