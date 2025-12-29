#!/bin/bash
set -e

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------
if [ -z "$1" ]; then
    echo "❌ Error: No environment specified."
    echo "Usage: ./scripts/destroy.sh <environment>"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_NAME="php-health-app"
REPO_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
REGION="us-west-2"
TF_DIR="./terraform/environments/${ENVIRONMENT}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 2. Check Directory
if [ ! -d "$TF_DIR" ]; then
    echo -e "${RED}❌ Error: Directory $TF_DIR does not exist.${NC}"
    exit 1
fi

echo -e "${RED}⚠️  WARNING: You are about to DESTROY the '${ENVIRONMENT}' environment.${NC}"
echo -e "${RED}Target: $REPO_NAME and resources in $TF_DIR${NC}"
read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo -e "${YELLOW}--- [1/2] Destroying Terraform Resources ---${NC}"

cd "$TF_DIR"
terraform destroy -auto-approve

echo -e "${YELLOW}--- [2/2] Cleaning up ECR Repository ---${NC}"

if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Deleting ECR Repository and all images..."
    aws ecr delete-repository --repository-name "$REPO_NAME" --region "$REGION" --force
    echo -e "${GREEN}✔ ECR Repository deleted.${NC}"
else
    echo "ECR Repository already deleted or not found."
fi

echo -e "${GREEN}✅ ${ENVIRONMENT} successfully destroyed.${NC}"