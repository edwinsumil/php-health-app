# ------------------------------------------------------------------------------
# Data Sources: Network
# We use the Default VPC to minimize costs (avoids NAT Gateways).
# ------------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ------------------------------------------------------------------------------
# Security Group: Load Balancer
# Allows HTTP and HTTPS traffic from the open internet.
# ------------------------------------------------------------------------------
resource "aws_security_group" "lb" {
  name        = "${var.project_name}-${var.environment}-lb-sg"
  description = "Controls access to the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTPS (443)
  ingress {
    description = "Allow HTTPS from anywhere"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (80) - Required for redirection
  ingress {
    description = "Allow HTTP from anywhere"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# Security Group: ECS Tasks
# Security Group Chaining: Only accepts traffic from the ALB Security Group.
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Controls access to the ECS Fargate Tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow traffic only from ALB"
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    description = "Allow all outbound (Required for ECR pull & Logs)"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}