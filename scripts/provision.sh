#!/bin/bash
set -e

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------
# 1. Validate Input
if [ -z "$1" ]; then
    echo "❌ Error: No environment specified."
    echo "Usage: ./scripts/provision.sh <environment>"
    echo "Example: ./scripts/provision.sh production"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_NAME="php-health-app" 
REPO_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
REGION="us-west-2"
TF_DIR="./terraform/environments/${ENVIRONMENT}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}--- Target Environment: ${ENVIRONMENT} ---${NC}"

# 2. Check Directory Exists
if [ ! -d "$TF_DIR" ]; then
    echo -e "${RED}❌ Error: Directory $TF_DIR does not exist.${NC}"
    echo "Please create the environment folder in terraform/environments/ first."
    exit 1
fi

echo -e "${YELLOW}--- [1/3] Pre-Flight Checks: ECR Repository ---${NC}"

# Check/Create ECR Repo
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo -e "${GREEN}✔ Repository $REPO_NAME already exists.${NC}"
else
    echo -e "${YELLOW}Creating ECR Repository $REPO_NAME...${NC}"
    aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION"
    echo -e "${GREEN}✔ Repository created.${NC}"
fi

echo -e "${YELLOW}--- [2/3] Terraform Plan & Apply ---${NC}"

cd "$TF_DIR"

# Initialize
echo "Initializing Terraform..."
terraform init

# Plan
echo -e "${YELLOW}Generating Terraform Plan...${NC}"
# We save the plan to 'tfplan' to ensure we apply EXACTLY what we see here
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}---------------------------------------------------${NC}"
echo -e "${YELLOW}??? Do you want to apply these changes?${NC}"
read -p "Type 'y' to proceed, any other key to cancel: " -n 1 -r
echo "" # Move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Applying configuration...${NC}"
    terraform apply "tfplan"
    
    # Cleanup the plan file
    rm -f tfplan
else
    echo -e "${RED}❌ Deployment cancelled by user.${NC}"
    # Cleanup the plan file
    rm -f tfplan
    exit 0
fi

# ------------------------------------------------------------------
# OUTPUT DISPLAY
# ------------------------------------------------------------------
echo -e "${YELLOW}--- [3/3] Post-Provisioning Info ---${NC}"
echo -e "${GREEN}✅ ${ENVIRONMENT} Provisioned Successfully!${NC}"
echo ""

echo -e "🔹 ${YELLOW}ECR Repository URL:${NC}"
terraform output -raw ecr_repo 2>/dev/null || echo "N/A"
echo ""

echo -e "🔹 ${YELLOW}Health Check URL (Public Endpoint):${NC}"
terraform output -raw health_check_url 2>/dev/null || echo "N/A"
echo ""

echo -e "🔹 ${YELLOW}GitHub Actions Role ARN:${NC}"
echo "(Copy this to your .github/workflows YAML)"
terraform output -raw github_actions_role_arn 2>/dev/null || echo "N/A"
echo ""

echo -e "🔹 ${YELLOW}Name Servers:${NC}"
echo "(Update your Domain Registrar with these)"
terraform output -json name_servers 2>/dev/null || echo "N/A"
echo ""