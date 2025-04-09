Connecting to Your EKS Cluster from Your MacBook
To connect to your EKS cluster from your MacBook, you'll need to configure kubectl with the right credentials. Here's a step-by-step guide:
Prerequisites

Install the required tools on your MacBook:
bash# Install AWS CLI
brew install awscli

# Install kubectl
brew install kubernetes-cli

# Install eksctl (optional but helpful)
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

Make sure you have AWS credentials with access to your EKS cluster:
```aws configure```
# Enter your AWS Access Key ID, Secret Access Key, and default region (us-east-1)


Steps to Connect

Update your kubeconfig file:
```aws eks update-kubeconfig --name glide-api-cluster --region us-east-1```

Verify the connection:
```kubectl get nodes```

Check your pods:
``` 
kubectl get pods 
kubectl get pods -n kube-system  # For system pods
```