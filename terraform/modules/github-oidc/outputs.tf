# ------------------------------------------------------------------------------
# Outputs
# Exposes the Role ARN. We must copy/paste this into our GitHub Workflow YAML.
# ------------------------------------------------------------------------------
output "role_arn" {
  description = "The ARN of the IAM role GitHub Actions will assume"
  value       = aws_iam_role.github_actions.arn
}