# S3 бакет для зберігання стану Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = var.tags
}

# Увімкнути керування версіями для S3 бакета
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Увімкнути шифрування на стороні сервера для S3 бакета
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Заблокувати публічний доступ до S3 бакета
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}