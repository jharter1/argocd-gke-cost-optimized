# GKE Development Cluster for ArgoCD

This Terraform configuration creates a single-zone GKE cluster optimized for development and testing ArgoCD.

## File Structure


```
terraform_gke_cluster/
├── main.tf                     # Main Terraform configuration with GKE cluster resources
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── versions.tf                # Provider version constraints and configuration
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore for Terraform files
├── setup.sh                   # Setup script to enable APIs and initialize
└── README.md                  # This documentation
```

## Prerequisites

1. **Google Cloud SDK** installed and configured

   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Terraform >= 1.0** installed

   ```bash
   brew install terraform  # macOS
   ```

3. **A GCP project** with billing enabled

## Quick Start

1. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual project ID
   ```

2. **Run setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply
   ```

4. **Configure kubectl:**
   ```bash
   gcloud container clusters get-credentials dev-argocd-cluster --zone us-central1-a --project YOUR_PROJECT_ID
   ```

## Configuration Details

### Cluster Features
- **Single-zone deployment** (`us-central1-a`) for cost optimization
- **Preemptible nodes** to minimize costs and stay within free tier
- **Custom VPC** with proper IP range allocation for pods and services
- **2 nodes** by default (configurable)
- **e2-medium instances** (2 vCPU, 4GB RAM) suitable for development

### Network Configuration
- **VPC**: Custom network with secondary ranges for pods and services
- **Subnet**: `10.10.0.0/24` for nodes
- **Pods**: `10.12.0.0/16` secondary range
- **Services**: `10.11.0.0/24` secondary range

### Cost Optimization
- Uses preemptible nodes (up to 80% cost savings)
- Single zone deployment
- Minimal node count (2 nodes)
- Right-sized instances for development workloads

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP Project ID | Required |
| `region` | GCP Region | `us-central1` |
| `zone` | GCP Zone | `us-central1-a` |
| `cluster_name` | Name of the GKE cluster | `dev-argocd-cluster` |
| `node_count` | Number of nodes in the node pool | `2` |
| `machine_type` | Machine type for nodes | `e2-medium` |

## Outputs

After successful deployment, you'll get:
- Cluster name and endpoint
- kubectl configuration command
- Cluster location and CA certificate

## Integration with ArgoCD

After the cluster is created, you can install ArgoCD using your existing Helm values:

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm upgrade -i argo-cd argo/argo-cd -n argocd --create-namespace -f ../yaml_config_manifests/values-argocd-ingress.yaml
```

## Troubleshooting

### API Not Enabled
If you get API errors, ensure the required APIs are enabled:
```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
```

### Authentication Issues
Make sure you're authenticated with gcloud:
```bash
gcloud auth login
gcloud auth application-default login
```

### Quota Issues
Check your GCP quotas if cluster creation fails:
```bash
gcloud compute project-info describe --project YOUR_PROJECT_ID
```

## Clean Up

To destroy the infrastructure and avoid charges:

```bash
terraform destroy
```

**Note**: This will permanently delete your cluster and all data within it.

## Security Considerations

- Service account follows Google's recommendations
- No basic authentication enabled
- Client certificates disabled
- Custom service account with minimal required permissions

## Free Tier Compatibility

This configuration is designed to work within GCP's free tier limits:
- Uses preemptible instances
- Minimal resource allocation
- Single-zone deployment
- Standard persistent disks
