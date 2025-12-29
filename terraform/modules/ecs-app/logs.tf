# ------------------------------------------------------------------------------
# CloudWatch Logs
# Centralized logging for container stdout/stderr.
# Retention is configured to minimize storage costs.
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 1
}