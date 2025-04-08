# AWS Load Balancer Controller

The AWS Load Balancer Controller has been installed in your EKS cluster. You can now create Ingress resources with ALB annotations.

## Example Ingress for your services

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: glide-charge-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    # Add your ACM certificate ARN here for HTTPS
    # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-5678-abcd-efgh-1234567890ab
spec:
  rules:
  - host: api.glideliving.com
    http:
      paths:
      - path: /glide-charge
        pathType: Prefix
        backend:
          service:
            name: glide-charge-service
            port:
              number: 80
```

## Using with Custom Domain

1. Once your ingress is created, get the ALB URL with:
   `kubectl get ingress glide-charge-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`

2. Create a CNAME record in your DNS provider pointing api.glideliving.com to this ALB hostname.

3. For HTTPS, request an ACM certificate for api.glideliving.com and add the certificate ARN to the ingress annotation.
