# Setting Up GitHub CI/CD for GlideInfra

This document explains how to set up GitHub Actions for automated EKS cluster management.

## 1. Repository Setup

First, push your code to a GitHub repository:

```bash
git init
git remote add origin https://github.com/whyaneel/glideinfra.git
git add .
git commit -m "Initial commit for glideinfra EKS tools"
git push -u origin main
```

## 2. Configure GitHub Secrets

You need to add AWS credentials as GitHub secrets:

1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret"
4. Add the following secrets:
   - Name: `AWS_ACCESS_KEY_ID`  
     Value: *Your AWS access key*
   - Name: `AWS_SECRET_ACCESS_KEY`  
     Value: *Your AWS secret key*

> ⚠️ **Important**: Make sure the AWS credentials have sufficient permissions to create and manage EKS clusters, VPCs, and related resources.

## 3. IAM Policy Requirements

The AWS user/role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "autoscaling:*",
        "cloudformation:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
```

For a more secure setup, consider creating a dedicated IAM user with restricted permissions.

## 4. Using Commit Triggers

### To create a cluster:

Include `[setup-eks]` in your commit message:

```bash
git commit -m "Update configuration [setup-eks]"
git push
```

### To destroy a cluster:

Include `[destroy-eks]` in your commit message:

```bash
git commit -m "Cleanup resources [destroy-eks]"
git push
```

## 5. Manual Workflow Execution

You can also run the workflows manually:

1. Go to the "Actions" tab in your GitHub repository
2. Select either "Setup EKS Cluster" or "Destroy EKS Cluster"
3. Click "Run workflow"
4. Adjust parameters if needed
5. Click "Run workflow" to execute

## 6. Monitoring Cluster Status

The repository tracks cluster status in the `cluster-status/` directory:
- `status.txt`: Current status (ACTIVE or DESTROYED)
- `name.txt`: Cluster name
- `region.txt`: AWS region
- `timestamp.txt`: Unix timestamp of last status change

A daily workflow checks if clusters have been running for too long and creates GitHub issues as reminders to clean up resources.

## 7. Debugging Failed Workflows

If a workflow fails:

1. Check the workflow run logs in the Actions tab
2. Common issues include:
   - Insufficient IAM permissions
   - AWS region constraints
   - Resource quotas
   - Terraform state conflicts

For Terraform state conflicts, you may need to manually delete the state or use the AWS Console to clean up resources.
