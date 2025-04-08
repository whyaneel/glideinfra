#!/bin/bash
set -e

# Colors for prettier output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}==== GlideInfra EKS Cluster Teardown ====${NC}"
echo -e "${YELLOW}WARNING: This will destroy your EKS cluster and all resources created by Terraform${NC}"

# Set variables
CLUSTER_NAME=${1:-glide-api-cluster}
REGION="us-east-1"

# Ask for confirmation
read -p "Are you sure you want to destroy the EKS cluster '${CLUSTER_NAME}'? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Destruction cancelled.${NC}"
  exit 0
fi

# Check prerequisites
if ! command -v terraform &> /dev/null; then
  echo -e "${RED}Error: terraform is required but not installed.${NC}"
  exit 1
fi

# Check if the cluster exists
if ! aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" &> /dev/null; then
  echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' doesn't exist or you don't have permissions to access it.${NC}"
  
  # Still try to run terraform destroy in case other resources exist
  echo "Proceeding with Terraform destroy anyway..."
else
  echo -e "${YELLOW}Found cluster '${CLUSTER_NAME}'. Proceeding with destruction...${NC}"
  
  # Clean up any resources that might block deletion
  echo "Removing Kubernetes workloads and services..."
  
  # Try to clean up resources but don't fail if it doesn't work
  if kubectl get namespace &> /dev/null; then
    kubectl delete service --all --all-namespaces || true
    kubectl delete deployment --all --all-namespaces || true
    kubectl delete pod --all --all-namespaces || true
  fi
fi

# Destroy with Terraform
echo "Running Terraform destroy..."
cd terraform
terraform destroy -auto-approve -var="cluster_name=${CLUSTER_NAME}" -var="region=${REGION}"

# Remove kubectl context
if kubectl config get-contexts | grep "${CLUSTER_NAME}" &> /dev/null; then
  echo "Removing kubectl context for the cluster..."
  kubectl config delete-context "$(kubectl config get-contexts | grep "${CLUSTER_NAME}" | awk '{print $1}')" || true
  kubectl config delete-cluster "$(kubectl config get-clusters | grep "${CLUSTER_NAME}")" || true
fi

echo -e "${GREEN}==== EKS Cluster Successfully Destroyed ====${NC}"
echo -e "All resources related to '${YELLOW}${CLUSTER_NAME}${NC}' should now be removed."
echo -e "Check your AWS console to confirm all resources have been properly removed."
