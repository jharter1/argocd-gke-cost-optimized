# ArgoCD Kubernetes Manifests

Simple shell scripts to install and manage ArgoCD on your GKE cluster.

## Scripts

### 🚀 `install-argocd.sh`

**Main installation script** - Installs ArgoCD from official GitHub manifests

- Creates argocd namespace
- Installs ArgoCD components
- Configures server for HTTP access (insecure mode)
- Retrieves admin password
- Shows connection instructions

```bash
./install-argocd.sh
```

### 🌐 `setup-ingress.sh`

**Ingress setup** - Creates NGINX ingress for external access

- Installs NGINX Ingress Controller if needed
- Creates ArgoCD ingress with `argocd.local` hostname
- Shows external IP and /etc/hosts setup instructions

```bash
./setup-ingress.sh
```

### 🗑️ `cleanup-argocd.sh`

**Cleanup script** - Completely removes ArgoCD installation

- Removes all ArgoCD components
- Deletes argocd namespace
- Asks for confirmation before cleanup

```bash
./cleanup-argocd.sh
```

## Usage Flow

1. **Install ArgoCD:**

   ```bash
   ./install-argocd.sh
   ```

2. **Access via port-forward (quick):**

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:80
   # Visit: http://localhost:8080
   ```

3. **Or setup external ingress:**

   ```bash
   ./setup-ingress.sh
   # Follow instructions to update /etc/hosts
   # Visit: http://argocd.local
   ```

## Login Credentials

- **Username:** `admin`
- **Password:** Shown by install script, or get with:

  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

## Prerequisites

- kubectl configured for your GKE cluster
- Cluster with ingress support (for external access)

## Notes

- ArgoCD runs in **insecure mode** (HTTP) for simplicity
- For production, configure proper TLS/SSL
- Delete initial admin secret after first login:

  ```bash
  kubectl -n argocd delete secret argocd-initial-admin-secret
  ```
