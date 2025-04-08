# GlideInfra

A lightweight infrastructure setup for quickly provisioning and destroying AWS EKS clusters to minimize costs.

## Overview

GlideInfra provides simple scripts to:
- Quickly provision a minimal EKS cluster in AWS (us-east-1)
- Easily destroy the infrastructure when not in use to save costs
- Support basic configuration customization

## Prerequisites

- AWS CLI installed and configured
- Terraform ≥ 1.0.0
- kubectl
- [eksctl](https://eksctl.io/) (optional)

## Quick Start

### Setting up the EKS cluster

```bash
# Make the setup script executable
chmod +x setup_glideinfra.sh

# Run the setup script
./setup_glideinfra.sh
```

### Destroying the EKS cluster

```bash
# Make the destroy script executable
chmod +x destroy_glideinfra.sh

# Run the destroy script
./destroy_glideinfra.sh
```

Alternatively, you can use the provided Makefile:

```bash
# To setup
make setup

# To destroy
make destroy
```

## Configuration

Edit the `terraform/variables.tf` file to customize your deployment:

- Cluster name
- Node instance type
- Number of nodes
- Other EKS configuration

## Cost Saving Strategies

This repo implements several cost-saving approaches:
1. Minimal node configuration (2 small t3.medium nodes by default)
2. Easy teardown when not in use
3. Spot instance support (optional)
4. No unnecessary AWS resources

## Known Limitations

- Designed for development/testing purposes, not production workloads
- Uses default networking configuration
- Simple security setup (should be enhanced for production use)

## License

MIT
