# ArgoCD Applications

This directory contains ArgoCD Application manifests that define what applications should be deployed to the cluster.

## Structure

Each application has its own YAML file that tells ArgoCD:

- Where to find the application's Kubernetes manifests (GitHub repo/path)
- Which cluster/namespace to deploy to
- How often to sync
- Sync policies (automatic vs manual)

## How It Works

1. ArgoCD monitors this directory in the GitHub repository
2. When you add/modify an Application manifest here, ArgoCD automatically picks it up
3. ArgoCD then syncs the application according to its configuration

## Applications

- `prometheus.yaml` - Metrics collection and monitoring
- `grafana.yaml` - Visualization and dashboards  
- `loki.yaml` - Log aggregation and analysis

## Adding New Applications

1. Create a new YAML file following the Application CRD format
2. Define the source repository and path
3. Specify the destination cluster and namespace
4. Configure sync policy and parameters
5. Commit and push - ArgoCD will handle the rest!