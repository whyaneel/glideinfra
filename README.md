# GlideInfra

A lightweight infrastructure setup for quickly provisioning and destroying AWS EKS clusters to minimize costs, with CI/CD integration.

## Overview

GlideInfra provides simple scripts and CI/CD workflows to:
- Quickly provision a minimal EKS cluster in AWS (us-east-1)
- Easily destroy the infrastructure when not in use to save costs
- Support basic configuration customization
- Control infrastructure through Git commits

## Prerequisites

- AWS CLI installed and configured
- Terraform ≥ 1.0.0
- kubectl
- [eksctl](https://eksctl.io/) (optional)
- GitHub repository with Actions enabled

## Quick Start

### Setting up the EKS cluster

You can set up an EKS cluster in multiple ways:

#### 1. Using Git Commit (CI/CD)

Add `[setup-eks]` to your commit message to trigger cluster creation:

```bash
git commit -m "Update infrastructure configuration [setup-eks]"
git push
```

#### 2. Using GitHub Actions UI

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Setup EKS Cluster" workflow
3. Click "Run workflow"
4. Fill in the parameters or use defaults
5. Click "Run workflow" again

#### 3. Using Local Scripts

```bash
# Make the setup script executable
chmod +x setup_glideinfra.sh

# Run the setup script
./setup_glideinfra.sh
```

### Destroying the EKS cluster

Similarly, you can destroy the cluster in multiple ways:

#### 1. Using Git Commit (CI/CD)

Add `[destroy-eks]` to your commit message:

```bash
git commit -m "Cleanup infrastructure [destroy-eks]"
git push
```

#### 2. Using GitHub Actions UI

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Destroy EKS Cluster" workflow
3. Click "Run workflow"
4. Confirm the parameters
5. Click "Run workflow" again

#### 3. Using Local Scripts

```bash
# Make the destroy script executable
chmod +x destroy_glideinfra.sh

# Run the destroy script
./destroy_glideinfra.sh
```

## CI/CD Integration

This repository includes three GitHub Actions workflows:

1. **Setup EKS Cluster** (`.github/workflows/setup-eks.yml`)
   - Triggered by `[setup-eks]` in commit messages
   - Can be manually triggered from GitHub UI
   - Creates and configures the EKS cluster

2. **Destroy EKS Cluster** (`.github/workflows/destroy-eks.yml`)
   - Triggered by `[destroy-eks]` in commit messages
   - Can be manually triggered from GitHub UI
   - Destroys the EKS cluster and all resources

3. **Check EKS Cluster Status** (`.github/workflows/check-status.yml`)
   - Runs daily to check if clusters are still running
   - Creates issues for long-running clusters (> 3 days)
   - Updates status if clusters no longer exist

### Required GitHub Secrets

You must set the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

These credentials should have appropriate permissions to create and manage EKS clusters.

## Cost Saving Strategies

This repo implements several cost-saving approaches:
1. Minimal node configuration (2 small t3.medium nodes by default)
2. Easy teardown when not in use
3. Spot instance support (optional)
4. No unnecessary AWS resources
5. Automated alerts for long-running clusters

## Configuration

Edit the `terraform/variables.tf` file to customize your deployment:

- Cluster name
- Node instance type
- Number of nodes
- Other EKS configuration

## Known Limitations

- Designed for development/testing purposes, not production workloads
- Uses default networking configuration
- Simple security setup (should be enhanced for production use)

## License

MIT
