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

#### Using Git Commit (CI/CD)

Add `[setup-eks]` to your commit message to trigger cluster creation:

```bash
git commit -m "Update infrastructure configuration [setup-eks]"
git push
```

### Destroying the EKS cluster

Similarly, you can destroy the cluster in multiple ways:

#### Using Git Commit (CI/CD)

Add `[destroy-eks]` to your commit message:

```bash
git commit -m "Cleanup infrastructure [destroy-eks]"
git push
```

### Required GitHub Secrets

You must set the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

These credentials should have appropriate permissions to create and manage EKS clusters.

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
