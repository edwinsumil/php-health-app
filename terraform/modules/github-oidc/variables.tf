# ------------------------------------------------------------------------------
# Input Variables
# ------------------------------------------------------------------------------
variable "github_repo" {
  description = "The GitHub repository name in format: <org>/<repo> (e.g., myuser/my-php-app)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "terraform_state_bucket" {
  description = "The name of the S3 bucket used for remote state"
  type        = string
}

variable "terraform_lock_table" {
  description = "The name of the DynamoDB table used for state locking"
  type        = string
}