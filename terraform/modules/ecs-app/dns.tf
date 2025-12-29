# ------------------------------------------------------------------------------
# Route 53 Hosted Zone
# Creates a NEW Public Hosted Zone for the root domain.
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "main" {
  name = var.root_domain_name
}

# ------------------------------------------------------------------------------
# Route 53 Record (Alias)
# Points the app subdomain (ex:php-prod.plist.com) to the ALB.
# ------------------------------------------------------------------------------
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.app_domain_name
  type    = "A"

  alias {
    # References the resource inside alb.tf
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ------------------------------------------------------------------------------
# AWS Domain Registrar Update
# ⚠️ ONLY WORKS IF:
# 1. The domain is registered in AWS Route 53 Domains.
# 2. It is in the SAME AWS Account as this Terraform code.
# ------------------------------------------------------------------------------
resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.root_domain_name

  # Dynamically take the 4 Name Servers from the Hosted Zone created above
  dynamic "name_server" {
    for_each = aws_route53_zone.main.name_servers
    content {
      name = name_server.value
    }
  }

  # Ensure the Zone is created before trying to update the domain
  depends_on = [aws_route53_zone.main]
}