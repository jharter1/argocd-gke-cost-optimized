# ArgoCD Kubernetes Manifests

This directory uses **Kustomize** for clean, organized deployment configurations.

## Structure

```
k8s_manifests/
├── base/                   # Base ArgoCD installation
│   └── kustomization.yaml
└── overlays/               # Environment-specific configurations
    ├── nginx/              # NGINX ingress approach
    │   ├── kustomization.yaml
    │   ├── nginx-ingress-controller.yaml
    │   ├── nginx-ingress-class.yaml
    │   └── argocd-ingress.yaml
    └── tailscale/          # Tailscale mesh networking approach
        ├── kustomization.yaml
        └── tailscale-secret.yaml
```

## Usage

### Deploy with NGINX Ingress (Current)
```bash
kubectl apply -k overlays/nginx
```

### Deploy with Tailscale (Cost-optimized)
```bash
# 1. Edit tailscale-secret.yaml with your auth key
# 2. Deploy
kubectl apply -k overlays/tailscale
```

### Switch Between Approaches
```bash
# Remove current deployment
kubectl delete -k overlays/nginx

# Deploy new approach
kubectl apply -k overlays/tailscale
```

## Cost Comparison

| Approach | Monthly Cost | Access Method |
|----------|-------------|---------------|
| **NGINX Ingress** | $24-31 | `kubectl port-forward` to localhost:8081 |
| **Tailscale** | $0 | Direct access at `http://argocd-gke` |

## Benefits of Kustomize Structure

1. **Clean Organization**: No scattered YAML files
2. **Environment Separation**: Easy to switch between NGINX/Tailscale
3. **Reusable Base**: Common ArgoCD config shared across overlays
4. **GitOps Ready**: Perfect for ArgoCD's Application definitions
5. **No Shell Scripts**: Pure declarative Kubernetes manifests

## Migration

To migrate from the old scattered files to this structure:
1. Use `kubectl apply -k overlays/nginx` instead of individual files
2. Remove old standalone YAML files after testing
3. Update any scripts or documentation to use Kustomize paths

## Next Steps

Once you've chosen your preferred approach (NGINX or Tailscale), you can:
1. Create ArgoCD Applications pointing to these Kustomize overlays
2. Set up GitOps workflows
3. Add additional overlays for different environments (dev/staging/prod)