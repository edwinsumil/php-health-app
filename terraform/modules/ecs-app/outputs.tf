output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}

output "health_check_url" {
  description = "The public HTTPS endpoint"
  value       = "https://${var.app_domain_name}/health"
}

output "name_servers" {
  description = "The NS records created by the new Hosted Zone. Update Registrar with these."
  value       = aws_route53_zone.main.name_servers
}