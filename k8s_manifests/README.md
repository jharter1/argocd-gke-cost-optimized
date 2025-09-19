# ArgoCD Kubernetes Manifests

This directory contains Kustomize-based Kubernetes manifests for deploying ArgoCD with different networking approaches.

## Architecture

Our architecture uses a clean separation of concerns with three overlay layers:

```
k8s_manifests/
├── base/                    # Minimal base layer (mostly empty)
├── overlays/
│   ├── argocd/             # Core ArgoCD installation
│   ├── argocd-nginx/       # ArgoCD + NGINX Ingress
│   └── argocd-tailscale/   # ArgoCD + Tailscale mesh
```

## Deployment Options

### 1. ArgoCD Only (Base Installation)
```bash
kubectl apply -k overlays/argocd
```
- Pure ArgoCD installation with ClusterIP service
- Configured with `--insecure` flag for HTTP access
- No external networking

### 2. ArgoCD + NGINX Ingress
```bash
kubectl apply -k overlays/argocd-nginx
```
- Includes full ArgoCD installation
- NGINX Ingress Controller with official manifests
- HTTP ingress at `argocd.local` (requires /etc/hosts entry)
- Cost: ~$21-28/month for GCP Load Balancer

### 3. ArgoCD + Tailscale (Cost-Optimized)
```bash
# Set environment variable for secretGenerator
source ../load_env.fish  # or manually: set TAILSCALE_AUTH_KEY your-key-here
kubectl apply -k overlays/argocd-tailscale
```
- Includes full ArgoCD installation
- Tailscale sidecar for mesh networking
- Zero additional infrastructure costs
- Access via Tailscale IP from any device on your tailnet

### 4. Tailscale Subnet Router (Full Cluster Access)
```bash
# Set environment variable for subnet router auth key
source ../load_env.fish  # Loads TAILSCALE_SUBNET_AUTH_KEY
kubectl apply -k overlays/tailscale-subnet-router
```
- Exposes entire cluster network (10.10.0.0/24, 10.11.0.0/16, 10.12.0.0/16) to Tailscale
- Direct access to ALL cluster services without port-forwarding
- Zero additional infrastructure costs
- **Requires**: Auth key with "Advertise routes" enabled and unused
- **Next step**: Enable routes in Tailscale admin console after deployment

## Environment Setup

For Tailscale deployment, you need to set the auth key:

1. **Create Tailscale Auth Key**: 
   - Go to https://login.tailscale.com/admin/settings/keys
   - Click "Generate auth key"
   - For subnet router: Check "Advertise routes" 
   - Recommended: Check "Reusable" for testing
   - Copy the key (starts with `tskey-auth-`)

2. **Fish Shell** (local development):
   ```bash
   # Update .env file with new key, then:
   source load_env.fish
   ```

3. **Manual** (any shell):
   ```bash
   # Fish
   set TAILSCALE_AUTH_KEY your-new-auth-key-here
   
   # Bash/Zsh  
   export TAILSCALE_AUTH_KEY=your-new-auth-key-here
   ```

4. **GitHub Actions/CI** (recommended):
   ```yaml
   env:
     TAILSCALE_AUTH_KEY: ${{ secrets.TAILSCALE_AUTH_KEY }}
   ```

## Current Status

- ✅ NGINX approach: Tested and working at http://localhost:8081
- ✅ Tailscale approach: Ready for deployment (dry-run validated)
- ✅ Clean Kustomize architecture with proper separation of concerns
- ✅ Environment variable management with .env file support

## Cost Comparison

| Approach | Monthly Cost | Access Method |
|----------|-------------|---------------|
| NGINX + GCP LB | $21-28 | Public HTTP endpoint |
| Tailscale | $0 | Private mesh network |

The Tailscale approach can save $250+ annually while providing more secure access.