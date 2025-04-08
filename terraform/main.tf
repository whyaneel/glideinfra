provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = var.cluster_name
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "glideinfra"
  }
}

# Create a random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# VPC for EKS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags required for EKS
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}

# Create CloudWatch Log Group with unique name
resource "aws_cloudwatch_log_group" "eks" {
  # Add unique identifier to avoid conflicts
  name              = "/aws/eks/${local.cluster_name}-${random_string.suffix.result}/cluster"
  retention_in_days = 7
  tags              = local.tags
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Use our custom CloudWatch log group
  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_kms_key_id = null
  cloudwatch_log_group_retention_in_days = 7

  # Override the default log group with our custom one
  cluster_additional_security_group_ids = []
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Use spot instances for cost savings
  eks_managed_node_groups = {
    main = {
      name = "node-group-1"

      instance_types = [var.instance_type]
      capacity_type  = var.use_spot_instances ? "SPOT" : "ON_DEMAND"

      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes

      # IAM - use separate IAM policies instead of inline policies
      create_iam_role = true
      iam_role_name   = "${local.cluster_name}-node-group-role"
      iam_role_use_name_prefix = false

      # Avoid inline policies - instead create explicit IAM policies
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"               = "true"
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
      }
    }
  }

  # Manage aws-auth configmap
  manage_aws_auth_configmap = true

  tags = local.tags
}

# IAM role for Cluster Autoscaler - create separate policy instead of inline
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.cluster_name}-cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = module.eks.cluster_iam_role_name
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "setup_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${local.cluster_name}"
}

output "cost_optimization_note" {
  description = "Cost optimization note"
  value       = "Remember to run ./destroy_glideinfra.sh when you're done to avoid unnecessary charges!"
}