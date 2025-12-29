# ------------------------------------------------------------------------------
# Data Source: ECR Repository
# We reference an EXISTING repository created manually or via CI/CD.
# Terraform will fail if this repository does not exist.
# ------------------------------------------------------------------------------
data "aws_ecr_repository" "app" {
  name = "${var.project_name}-${var.environment}"
}