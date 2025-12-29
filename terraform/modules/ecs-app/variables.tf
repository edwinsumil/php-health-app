# ------------------------------------------------------------------------------
# Input Variables
# ------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Base name for resources (e.g., php-app)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the Docker container"
  type        = number
}

variable "app_count" {
  description = "Number of Docker replicas to run"
  type        = number
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
}

variable "fargate_memory" {
  description = "Fargate Memory in MiB"
  type        = number
}

# --- DNS & SSL Variables ---

variable "root_domain_name" {
  description = "The root domain for the Hosted Zone (e.g., example.com)"
  type        = string
}

variable "app_domain_name" {
  description = "The full FQDN for the application (e.g., app.example.com)"
  type        = string
}