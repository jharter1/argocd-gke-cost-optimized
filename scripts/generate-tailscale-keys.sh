#!/bin/bash

# Tailscale Auth Key Generator Script
# This script generates unique Tailscale auth keys for each service using the Tailscale API

set -euo pipefail

# Configuration
TAILSCALE_API_KEY="${TAILSCALE_API_KEY:-}"
TAILSCALE_TAILNET="${TAILSCALE_TAILNET:-}"
NAMESPACE="observability"

# Services that need Tailscale auth keys
SERVICES=("prometheus" "grafana" "loki")

# Function to check prerequisites
check_prerequisites() {
    if [ -z "$TAILSCALE_API_KEY" ]; then
        echo "❌ TAILSCALE_API_KEY environment variable is required"
        echo "   Get your API key from: https://login.tailscale.com/admin/settings/keys"
        echo "   Export it as: export TAILSCALE_API_KEY=tskey-api-YOUR-KEY-HERE"
        exit 1
    fi
    
    if [ -z "$TAILSCALE_TAILNET" ]; then
        echo "❌ TAILSCALE_TAILNET environment variable is required"
        echo "   This is your tailnet name (e.g., your-email@gmail.com or organization name)"
        echo "   Export it as: export TAILSCALE_TAILNET=your-tailnet-name"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "❌ jq is required but not installed"
        echo "   Install with: brew install jq"
        exit 1
    fi
}

# Function to generate a Tailscale auth key
generate_auth_key() {
    local service_name=$1
    local description="K8s ${service_name} service - Generated $(date -u +%Y-%m-%d)"
    
    echo "🔑 Generating auth key for ${service_name}..."
    
    local response
    response=$(curl -s -X POST \
        "https://api.tailscale.com/api/v2/tailnet/${TAILSCALE_TAILNET}/keys" \
        -H "Authorization: Bearer ${TAILSCALE_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"capabilities\": {
                \"devices\": {
                    \"create\": {
                        \"reusable\": true,
                        \"ephemeral\": false,
                        \"preauthorized\": true,
                        \"tags\": [\"tag:k8s\", \"tag:${service_name}\"]
                    }
                }
            },
            \"expirySeconds\": 7776000,
            \"description\": \"${description}\"
        }")
    
    local auth_key
    auth_key=$(echo "$response" | jq -r '.key // empty')
    
    if [ -z "$auth_key" ] || [ "$auth_key" = "null" ]; then
        echo "❌ Failed to generate auth key for ${service_name}"
        echo "   API Response: $response"
        return 1
    fi
    
    echo "✅ Generated auth key for ${service_name}: ${auth_key:0:20}..."
    echo "$auth_key"
}

# Function to create or update Kubernetes secret
create_k8s_secret() {
    local service_name=$1
    local auth_key=$2
    local secret_name="tailscale-${service_name}-auth"
    
    echo "🔄 Creating Kubernetes secret ${secret_name}..."
    
    # Delete existing secret if it exists
    if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
        echo "   Deleting existing secret..."
        kubectl delete secret "$secret_name" -n "$NAMESPACE"
    fi
    
    # Create new secret
    kubectl create secret generic "$secret_name" \
        --from-literal=authkey="$auth_key" \
        -n "$NAMESPACE"
    
    echo "✅ Created secret ${secret_name}"
}

# Function to restart deployment to pick up new secret
restart_deployment() {
    local service_name=$1
    
    echo "🔄 Restarting ${service_name} deployment..."
    if kubectl rollout restart deployment "$service_name" -n "$NAMESPACE" &> /dev/null; then
        echo "✅ Restarted ${service_name} deployment"
    else
        echo "⚠️  Could not restart ${service_name} deployment (may not exist yet)"
    fi
}

# Main function
main() {
    echo "🚀 Tailscale Auth Key Generator for Kubernetes Services"
    echo "=================================================="
    
    check_prerequisites
    
    echo "📝 Configuration:"
    echo "   Tailnet: ${TAILSCALE_TAILNET}"
    echo "   Namespace: ${NAMESPACE}"
    echo "   Services: ${SERVICES[*]}"
    echo ""
    
    for service in "${SERVICES[@]}"; do
        echo "🔄 Processing ${service}..."
        
        # Generate unique auth key
        auth_key=$(generate_auth_key "$service")
        if [ -z "$auth_key" ]; then
            echo "❌ Skipping ${service} due to auth key generation failure"
            continue
        fi
        
        # Create Kubernetes secret
        create_k8s_secret "$service" "$auth_key"
        
        # Restart deployment
        restart_deployment "$service"
        
        echo ""
    done
    
    echo "🎉 All services processed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Check pod status: kubectl get pods -n ${NAMESPACE}"
    echo "   2. View Tailscale devices: https://login.tailscale.com/admin/machines"
    echo "   3. Each service should get its own unique Tailscale IP"
}

# Run main function
main "$@"