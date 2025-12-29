# PHP Container Application & AWS Infrastructure

This project represents a production-ready architecture for deploying a lightweight, containerized PHP application on **Amazon ECS (Fargate)** using **Terraform**.

## 🌟 Features

### 🐘 Application
*   **Optimized Build:** Multi-stage Docker build resulting in a minimal image size (~8MB).
*   **Observability:** Standardized logging to `stdout/stderr` and a dedicated `/health` endpoint for Load Balancers.
*   **Security:** Container runs as a non-root user to follow least-privilege principles.
*   **Configurable:** Port configuration via Environment Variables.

### ☁️ Infrastructure (AWS)
*   **Cost-Efficient:** Uses ECS Fargate Spot Instances to reduce compute costs by up to 70%.
*   **Simplified Network:** Deployed in Public Subnets to eliminate the need for expensive NAT Gateways while maintaining security via strict Security Groups.
*   **Zero-Trust CI/CD:** Utilizes **OpenID Connect (OIDC)** for GitHub Actions, removing the security risk of long-lived AWS Access Keys.
*   **Infrastructure as Code:** Fully managed via Terraform with remote state locking (S3 + DynamoDB).
*   **Automated DNS:** Automatically updates Route 53 Domain registration with the correct Name Servers.

## 📂 Directory Structure

```text
├── .github/
│   └── workflows/
│       └── prod-deploy.yml          # 🤖 CI/CD Workflow (w/ OIDC authentication)
├── php-app/                         # 🐘 Application Source
│   ├── Dockerfile                   # Multi-stage Docker build definition
│   └── public/                      # PHP entry point and source code
├── scripts/                         # 🛠 Automation Scripts
│   ├── build_push.sh                # Helper to Build & Push Docker Image
│   ├── provision.sh                 # Wrapper to init/plan/apply Terraform
│   └── destroy.sh                   # Wrapper to destroy Infra & clean ECR
├── terraform/                       # ☁️ Infrastructure as Code
│   ├── environments/
│   │   └── production/              # Environment-specific config (tfvars, backend)
│   └── modules/
│       ├── ecs-app/                 # Core Module (ALB, ECS, ECR, Logs, Network)
│       └── github-oidc/             # Security Module (IAM Identity Provider)
└── README.md
```

## 🐘 The Application (Local Development)
How to build and run the PHP application on local machine.

**1. Build the Image**
```bash
# Run from project root
docker build -t php-health-app ./php-app
```

**2. Run the Container**
```bash
docker run -d --name php-health-app -p 8080:8080 php-health-app
```

**3. Verification**
```bash
# Check Health Endpoint
curl -i http://localhost:8080/health

# Check Logs
docker logs -f php-health-app
```

## ☁️ Infrastructure Deployment (AWS)
How to deploy the application to production using the included scripts.

**0. Prerequisites (One-Time Setup)**

1. Domain Name Purchase (Manual Step): Assumptions to support a production-like application with domain exposure and SSL/TLS handshake
```text
Log in to the AWS Console and go to Route 53.
Click Domains -> Registered domains -> Register Domain.
Purchase the domain (e.g., plist.com) in the same AWS account we are deploying to.
Wait until the domain status is "Active" (approx. 15-30 mins).
```
2. AWS Credentials: Ensure aws configure is active.
3. State Backend: Create S3 Bucket and DynamoDB table for Terraform state.
```bash
aws s3api create-bucket --bucket plist-tf-state-bucket --region us-west-2
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region us-west-2
```
4. AWS ECR Repository: To store application docker image
```bash
aws ecr create-repository --repository-name php-health-app-production --region us-west-2
```
5. Permissions: Make scripts executable.
```bash
chmod +x scripts/*.sh
```

**1. Bootstrap (Build & Push Image)**

Use the bootstrap script to build and push application docker image to AWS ECR Repository
```bash
./scripts/build_push.sh production
```

**2. Provision Infrastructure**
Use the provision script to apply Terraform. This script automatically handles ECR repository checks and runs terraform init/plan/apply.
```bash
./scripts/provision.sh production
```
📝 Critical Outputs:
At the end of the script, note the following outputs:
- github_actions_role_arn (For Step 3, CI/CD Configuration (GitHub Actions))
- health_check_url (For Verification)

**3. CI/CD Configuration (GitHub Actions)**
1. Copy the GitHub Actions Role ARN from the Step 2 output.
2. Edit .github/workflows/prod-deploy.yml.
3. Update the IAM_ROLE_ARN env variable:
```yaml
IAM_ROLE_ARN: arn:aws:iam::123456789:role/php-health-app-production-gh-actions-role
```
4. Push the code to the main branch. GitHub Actions will now automatically Build, Push, and Deploy.

## ✅ Verification
Terraform automatically updates the AWS Domain Name Servers. Wait ~15 minutes for DNS propagation, then verify the live environment.

**1. HTTPS & SSL:**
```bash
curl -v $(terraform -chdir=terraform/environments/production output -raw health_check_url)
```
Expected: HTTP/2 200 and a valid SSL handshake.

**2. HTTP Redirection (Security)**
This checks if insecure HTTP requests are automatically redirected to HTTPS.
```bash
# We dynamically replace 'https' with 'http' from the output to test the redirect
curl -I $(terraform -chdir=terraform/environments/production output -raw health_check_url | sed 's/https/http/')
```
Expected: HTTP/1.1 301 Moved Permanently (Location: https://php-prod.plist.com)

## 🧹 Cleanup
To destroy all resources, including the Infrastructure, ECR Repository, and Docker Images (to stop all billing).
```bash
./scripts/destroy.sh production
```
