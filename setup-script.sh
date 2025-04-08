#!/bin/bash
set -e

# Colors for prettier output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==== GlideInfra EKS Cluster Setup ====${NC}"
echo -e "${YELLOW}This script will create a minimal EKS cluster in us-east-1${NC}"

# Check prerequisites
check_command() {
  if ! command -v $1 &> /dev/null; then
    echo -e "${RED}Error: $1 is required but not installed.${NC}"
    exit 1
  fi
}

check_command aws
check_command terraform

# Check AWS credentials
echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}Error: AWS credentials not configured correctly.${NC}"
  echo -e "Please run 'aws configure' to set up your credentials."
  exit 1
fi

# Set variables
CLUSTER_NAME=${1:-glideinfra-eks}
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${GREEN}Setting up EKS cluster '${CLUSTER_NAME}' in region '${REGION}'${NC}"

# Initialize and apply Terraform
echo "Initializing Terraform..."
cd terraform
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve -var="cluster_name=${CLUSTER_NAME}" -var="region=${REGION}"

# Configure kubectl
echo "Configuring kubectl..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

# Verify deployment
echo "Verifying node status..."
kubectl get nodes

# Deploy metrics server
echo "Deploying metrics server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo -e "${GREEN}==== EKS Cluster Successfully Created ====${NC}"
echo -e "Cluster name: ${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "Region: ${YELLOW}${REGION}${NC}"
echo -e "To delete this cluster, run: ${YELLOW}./destroy_glideinfra.sh${NC}"
echo 
echo -e "${YELLOW}NOTE: As long as this cluster is running, you will be charged by AWS.${NC}"
echo -e "${YELLOW}Remember to destroy the cluster when not in use to avoid unnecessary costs.${NC}"
