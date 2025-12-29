terraform {
  backend "s3" {
    bucket         = "plist-tf-state-bucket" 
    key            = "php-app/prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}