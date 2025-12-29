# ------------------------------------------------------------------------------
# Data Source: GitHub TLS Certificate
# Dynamically fetches the certificate thumbprint from GitHub's OIDC endpoint.
# This ensures the OIDC provider configuration remains valid even if certificates rotate.
# ------------------------------------------------------------------------------
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ------------------------------------------------------------------------------
# IAM OIDC Provider
# Establishes trust between our AWS Account and GitHub's Identity Provider.
# This is a global IAM resource.
# ------------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# ------------------------------------------------------------------------------
# IAM Role for GitHub Actions
# This is the role that the GitHub Actions workflow will "Assume".
# The Trust Policy strictly limits assumption to:
# 1. The GitHub OIDC Provider
# 2. Specific GitHub repository (in var.github_repo)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-gh-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          # Security Condition: Only allow tokens signed by GitHub for our repo
          # The wildcard '*' allows any branch (main, feature/*) or tag.
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}:*"
          }
          # Security Condition: Ensure the token is intended for AWS STS
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy: CI/CD Pipeline Permissions
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "pipeline_perms" {
  name        = "${var.project_name}-${var.environment}-pipeline-policy"
  description = "Permissions for GitHub Actions to Build, Deploy, and Read State"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. ECR Permissions
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*" 
      },
      # 2. ECS Permissions
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      # 3. IAM PassRole
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService": "ecs-tasks.amazonaws.com"
          }
        }
      },
      # 4. Terraform State Access (RESTRICTED TO SPECIFIC ARNS)
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket", # Required to list the bucket itself
          "s3:GetObject"   # Required to read the state file
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",   # The Bucket itself
          "arn:aws:s3:::${var.terraform_state_bucket}/*"  # All objects inside
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        # Restrict to the specific Lock Table in any region/account
        Resource = "arn:aws:dynamodb:*:*:table/${var.terraform_lock_table}"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy Attachment
# Connects the permissions policy to the OIDC Role.
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.pipeline_perms.arn
}