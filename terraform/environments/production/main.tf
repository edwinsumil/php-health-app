# ------------------------------------------------------------------------------
# Module Instantiation
# ------------------------------------------------------------------------------
module "ecs_app" {
  source = "../../modules/ecs-app"

  aws_region       = var.aws_region
  project_name     = var.project_name
  environment      = var.environment
  container_port   = var.container_port
  app_count        = var.app_count
  fargate_cpu      = var.fargate_cpu
  fargate_memory   = var.fargate_memory
  
  # DNS Configuration
  root_domain_name = var.root_domain_name
  app_domain_name  = var.app_domain_name
}

# ------------------------------------------------------------------------------
# GitHub OIDC Configuration
# Sets up the Trust Relationship between AWS and GitHub Repository.
# This eliminates the need to store long-lived AWS Access Keys in GitHub Secrets.
# ------------------------------------------------------------------------------
module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name = var.project_name
  environment  = var.environment
  
  # IMPORTANT: Update below to match exact GitHub "Username/RepoName"
  github_repo  = "username/repo-name"

  terraform_state_bucket = "platinumlist-tf-state-bucket"
  terraform_lock_table   = "terraform-state-lock"
}