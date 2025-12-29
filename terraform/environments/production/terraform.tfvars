aws_region       = "us-west-2"
project_name     = "php-health-app"
environment      = "production"
container_port   = 8080
app_count        = 2
fargate_cpu      = 256
fargate_memory   = 512

# Domain Configuration
root_domain_name = "plist.com"      # The Zone to create
app_domain_name  = "php-prod.plist.com"  # The record to create