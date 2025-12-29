# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "ecr_repo" {
  value = module.ecs_app.ecr_repository_url
}

output "health_check_url" {
  value = module.ecs_app.health_check_url
}

output "name_servers" {
  value = module.ecs_app.name_servers
}

# ------------------------------------------------------------------------------
# Output: GitHub Role ARN
# This value is required in our .github/workflows/deploy.yml file
# under the 'role-to-assume' step.
# ------------------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "The ARN needed for the GitHub Actions OIDC step"
  value       = module.github_oidc.role_arn
}