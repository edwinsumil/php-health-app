# Infrastructure as Code: PHP Container App Deployment

This **Terraform** code-base provisions a cost-optimized, secure AWS infrastructure for running a PHP Docker application on **Amazon ECS (Fargate)**.

## 🏗 Architecture
- **Compute:** ECS Fargate (Spot Instances for ~70% cost savings).
- **Networking:** Runs in Default VPC Public Subnets (Public IPs) to eliminate expensive NAT Gateways.
- **Load Balancing:** Application Load Balancer (ALB) handles ingress traffic with path-based health checks.
- **Security:** 
  - Least Privilege: IAM roles grants only necessary permissions (ECR Pull, CloudWatch Push).
  - Security Group Chaining (ECS accepts traffic *only* from ALB).
- **Logging:** CloudWatch Logs (1 day retention).
- **State Management:** Remote S3 state with DynamoDB locking to prevent corruption.

## 📂 Directory Structure
```text
terraform/
├── modules/
│   └── ecs-app/                     # 📦 REUSABLE MODULE
│       ├── alb.tf                   # Application Load Balancer, Listener, and Target Group configuration.
│       ├── dns.tf                   # Creates Route53 Zone & Records.
│       ├── ecr.tf                   # Elastic Container Registry (ECR) to store Docker images.
│       ├── ecs.tf                   # ECS Cluster, Fargate Task Definition, and Service (Spot instances).
│       ├── iam.tf                   # IAM Roles (Task Execution Role) for pulling images and logging.
│       ├── logs.tf                  # CloudWatch Log Group setup with retention policies.
│       ├── network.tf               # Data sources for Default VPC and Security Group definitions (ALB & ECS).
│       ├── variables.tf             # Input variable definitions (Type constraints and descriptions).
│       └── outputs.tf               # Outputs returned by the module (Repo URL, DNS name).
│   └── github-oidc/                 # 🔐 GitHub OIDC MODULE (Auth Logic) for GitHub Actions Workflow
│       ├── main.tf                  # Identity Provider & Trust Policy.
│       ├── variables.tf             # Repo name variables.
│       └── outputs.tf               # Exports the Role ARN.
│
├── environments/
│   └── production/                  # 🚀 PRODUCTION ENVIRONMENT
│       ├── backend.tf               # Configures Terraform to store state in S3 with DynamoDB locking.
│       ├── provider.tf              # Configures the AWS Provider and default resource tagging.
│       ├── main.tf                  # Instantiates the 'ecs-app' module and maps variables.
│       └── terraform.tfvars         # Concrete values for variables (e.g., app_count = 2, cpu = 256).
│
└── README.md                        # This documentation file.
```

## 🚀 Deployment Guide

**1. Prerequisites (One-Time Setup)**
Before running Terraform, we need an S3 Bucket and DynamoDB table for state management. Run these AWS CLI commands once:
```bash
# 1. Domain Name Purchase (Manual Step) : Assumptions to support a production-like application with domain exposure and SSL/TLS handshake
Log in to the AWS Console and go to Route 53.
Click Domains -> Registered domains -> Register Domain.
Purchase the domain (e.g., plist.com) in the same AWS account we are deploying to.
Wait until the domain status is "Active" (approx. 15-30 mins).

# 2. Create S3 Bucket
aws s3api create-bucket --bucket plist-tf-state-bucket--region us-west-2

# 3. Create DynamoDB Lock Table
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region us-west-2
```

**2. Build & Push Docker Image**
Build and Push Application Docker Image to AWS ECR
```bash
# Define Variables 
REPO_NAME="php-health-app-production" # Must match terraform.tfvars: project_name + "-" + environment
REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 1. Create Repository
aws ecr create-repository --repository-name $REPO_NAME --region $REGION

# 2. Login to Docker
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 3. Build & Push
docker build -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest ../php-app/
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
```

**3. Deploy Infrastructure**

  **1. Configure Environment**
Edit environments/production/terraform.tfvars:
```hcl
root_domain_name = "plist.com"               # The Zone to create
app_domain_name  = "php-prod.plist.com"      # The record to create
```

  **2. Navigate to the production environment folder:**
```bash
cd environments/production

# Initialize (Download providers and configure Backend)
terraform init

# Plan (Preview changes)
terraform plan

# Apply (Create Resources)
terraform apply -auto-approve
```

**4. CI/CD Configuration (GitHub Actions OIDC)**
Terraform provisions a secure IAM Role for GitHub Actions. We must add this Role ARN to our GitHub Actions workflow file.

  **1. Get the Role ARN:**
```bash
terraform output github_actions_role_arn
```
Output Example: arn:aws:iam::123456789:role/php-health-app-production-gh-actions-role

  **2. Update Workflow:**
Paste this ARN into the .github/workflows/prod-deploy.yml file under the configure-aws-credentials step:
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789:role/php-health-app-production-gh-actions-role
    aws-region: us-west-2
```

## ✅ Verification
Terraform automatically updates the AWS Domain Name Servers. Wait ~15 minutes for DNS propagation, then verify the live environment.

  **1. Verify HTTPS & Certificate:**
```bash
curl -v $(terraform output -raw health_check_url)
```
Expected Response: `HTTP/2 200` and a valid SSL handshake.

  **2. Verify HTTP to HTTPS Redirect:**
```bash
curl -I $(terraform output -raw health_check_url | sed 's/https/http/')
```
Expected Response: `HTTP/1.1 301` Moved Permanently (Location: https://php-prod.plist.com)

## 🧹 Cleanup
To destroy all resources and stop billing:
```bash
cd environments/production
terraform destroy -auto-approve
```