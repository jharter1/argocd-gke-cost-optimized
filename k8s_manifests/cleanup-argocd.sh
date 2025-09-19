#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🗑️  ArgoCD Cleanup Script${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ Error: kubectl is not installed.${NC}"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Error: Not connected to a Kubernetes cluster.${NC}"
    exit 1
fi

# Show current context
CONTEXT=$(kubectl config current-context)
echo -e "${BLUE}📋 Current kubectl context: ${CONTEXT}${NC}"
echo ""

# Ask for confirmation
echo -e "${YELLOW}⚠️  This will completely remove ArgoCD from the cluster!${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}✅ Cleanup cancelled.${NC}"
    exit 0
fi

# Remove ArgoCD
echo -e "${GREEN}🗑️  Removing ArgoCD installation...${NC}"
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Remove namespace
echo -e "${GREEN}🗑️  Removing argocd namespace...${NC}"
kubectl delete namespace argocd

echo -e "${GREEN}✅ ArgoCD cleanup complete!${NC}"
