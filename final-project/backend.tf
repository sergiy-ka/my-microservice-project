# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-final-project-sergiy-2025"
#     key            = "final-project/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-final-project"
#     encrypt        = true
#   }
# }