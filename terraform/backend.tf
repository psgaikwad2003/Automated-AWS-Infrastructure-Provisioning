terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket" # Replace with your bucket name after running bootstrap.sh
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

