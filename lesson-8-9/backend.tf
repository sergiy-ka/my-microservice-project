 # terraform {
 #   backend "s3" {
 #     bucket         = "terraform-state-bucket-lesson8-9-sergiy-2025"
 #     key            = "lesson-8-9/terraform.tfstate"
 #     region         = "us-west-2"
 #     dynamodb_table = "terraform-locks"
 #     encrypt        = true
 #   }
 # }