#!/bin/bash
set -e

# ------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------

# 1. Project Constants
PROJECT_BASE="php-health-app"
REGION="${AWS_REGION:-us-west-2}"

# CHANGE: Default path updated to match our folder structure (/php-app)
DOCKERFILE_CONTEXT="${DOCKER_PATH:-./php-app}" 

# 2. Determine Repository Name
# Scenario A: CI/CD (GitHub Actions sets ECR_REPO_NAME env var)
if [ ! -z "$ECR_REPO_NAME" ]; then
    REPO_NAME="$ECR_REPO_NAME"
    echo "--- Mode: CI/CD (Using Env Var) ---"

# Scenario B: Local (User passes environment arg: ./scripts/build_push.sh production)
elif [ ! -z "$1" ]; then
    ENVIRONMENT=$1
    REPO_NAME="${PROJECT_BASE}-${ENVIRONMENT}"
    echo "--- Mode: Local (Using Argument: $ENVIRONMENT) ---"

else
    echo "❌ Error: Configuration missing."
    echo "Usage: ./scripts/build_push.sh <environment>"
    exit 1
fi

# 3. Determine Image Tag
if [ -z "$GITHUB_SHA" ]; then
    IMAGE_TAG="local-$(date +%s)"
else
    IMAGE_TAG="$GITHUB_SHA"
fi

echo "Repo:    $REPO_NAME"
echo "Region:  $REGION"
echo "Tag:     $IMAGE_TAG"
echo "Context: $DOCKERFILE_CONTEXT"

# ------------------------------------------------------------------
# LOGIN
# ------------------------------------------------------------------
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# ------------------------------------------------------------------
# BUILD
# ------------------------------------------------------------------
echo "Building Image..."

# Docker build command checks the specific context folder
docker build -t $ECR_REGISTRY/$REPO_NAME:latest $DOCKERFILE_CONTEXT
docker build -t $ECR_REGISTRY/$REPO_NAME:$IMAGE_TAG $DOCKERFILE_CONTEXT

# ------------------------------------------------------------------
# PUSH
# ------------------------------------------------------------------
echo "Pushing Image..."
docker push $ECR_REGISTRY/$REPO_NAME:latest
docker push $ECR_REGISTRY/$REPO_NAME:$IMAGE_TAG

echo "✅ Build and Push Complete."