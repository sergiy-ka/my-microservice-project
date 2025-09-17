# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-lesson10-sergiy-2025"
#     key            = "lesson-10/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-lesson-10"
#     encrypt        = true
#   }
# }