# ArgoCD on GKE - Cost-Optimized Setup

A streamlined, cost-optimized deployment of ArgoCD on Google Kubernetes Engine (GKE) using Terraform and NGINX ingress.

## 🎯 Cost Optimization Features

- **No expensive static IPs** - Uses ephemeral IPs when needed
- **NGINX ingress controller** instead of costly GKE Load Balancers  
- **Eliminated "Cloud Load Balancer Forwarding Rule Minimum" charges**
- **Preemptible nodes** for significant cost savings
- **Single-zone deployment** to reduce network costs

## 📁 Project Structure

```
├── k8s_manifests/                     # Kubernetes manifests
│   ├── argocd-ingress-http.yaml      # Simple GKE ingress (backup)
│   ├── argocd-server-nginx-ingress.yaml # Working NGINX ingress
│   ├── cleanup-argocd.sh             # Development cleanup utility
│   ├── nginx-ingress-class-correct.yaml # NGINX ingress class config
│   └── nginx-ingress-setup.yaml      # Cost-effective NGINX controller
└── terraform_gke_cluster/            # Infrastructure as Code
    ├── main.tf                       # Core infrastructure (cost-optimized)
    ├── variables.tf                  # Configuration variables
    ├── outputs.tf                    # Access instructions
    ├── terraform.tfvars.example      # Example configuration
    └── [other terraform files]       # Standard terraform files
```

## 🚀 Quick Start

### 1. Infrastructure Setup
```bash
cd terraform_gke_cluster
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
terraform init
terraform plan
terraform apply
```

### 2. ArgoCD Deployment
```bash
# Install official NGINX ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Apply ingress class
kubectl apply -f k8s_manifests/nginx-ingress-class-correct.yaml

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply NGINX ingress for ArgoCD
kubectl apply -f k8s_manifests/argocd-server-nginx-ingress.yaml
```

### 3. Access ArgoCD
```bash
# Port-forward to access ArgoCD UI
kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8081:80 &

# Open in browser
open http://localhost:8081
```

### 4. Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 💰 Cost Comparison

| Component | Before (GKE LB) | After (NGINX) | Savings |
|-----------|----------------|---------------|---------|
| Load Balancer | ~$18-25/month | $0 | ~$18-25/month |
| Static IP | ~$3/month | $0 | ~$3/month |
| **Total** | **~$21-28/month** | **~$0/month** | **~$21-28/month** |

## 🛠️ Development

### Cleanup
```bash
# Clean up ArgoCD resources
./k8s_manifests/cleanup-argocd.sh

# Destroy infrastructure
cd terraform_gke_cluster
terraform destroy
```

## 📋 Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Valid GCP billing account

## 🎛️ Configuration

Key cost optimization settings in `terraform.tfvars`:
```hcl
# Cost optimization
use_nginx_ingress = true    # Use NGINX instead of GKE ingress
create_static_ip = false    # Don't create expensive static IPs
enable_https = false        # HTTP for development (no SSL cert costs)

# Efficient cluster setup
machine_type = "e2-medium"  # Cost-effective node type
node_count = 2              # Minimal node count
```

## 🔧 GitHub Actions Ready

This project is structured for easy GitHub Actions CI/CD:
- Direct terraform commands (no wrapper scripts)
- Modular YAML manifests
- Cost-optimized by default
- Clear separation of concerns

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with cost optimization in mind
5. Submit a pull request

---

**Note**: This setup prioritizes cost optimization for development environments. For production, consider adding monitoring, backup strategies, and high availability configurations.