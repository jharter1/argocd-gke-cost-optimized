output "project_id" {
  description = "The project ID (created or provided)"
  value       = var.create_project ? google_project.project[0].project_id : var.project_id
}

output "generated_project_id" {
  description = "The auto-generated project ID (if applicable)"
  value       = var.create_project && var.project_id == "" ? local.project_id : "N/A - using provided project_id"
}

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.dev_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.dev_cluster.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.dev_cluster.location
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.dev_cluster.name} --zone ${google_container_cluster.dev_cluster.location} --project ${var.create_project ? google_project.project[0].project_id : var.project_id}"
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = google_container_cluster.dev_cluster.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "argocd_external_ip" {
  description = "External IP reserved for ArgoCD ingress (if created)"
  value       = var.create_static_ip ? google_compute_global_address.argocd_ip[0].address : "No static IP created (using ephemeral IP)"
}

output "argocd_domain" {
  description = "ArgoCD domain name"
  value       = var.domain_name != "" ? "argocd.${var.domain_name}" : "Use external IP with /etc/hosts or port-forward"
}

output "access_instructions" {
  description = "Instructions for accessing ArgoCD"
  value = var.use_nginx_ingress ? "NGINX Ingress (Cheapest):\n1. Apply: kubectl apply -f k8s_manifests/nginx-ingress-setup.yaml\n2. Use port-forward: kubectl port-forward svc/nginx-ingress-nginx-controller -n ingress-nginx 8080:80\n3. Visit: http://localhost:8080" : var.create_static_ip ? "GKE Ingress with Static IP:\n1. Add to /etc/hosts: ${google_compute_global_address.argocd_ip[0].address} argocd.local\n2. Apply: kubectl apply -f k8s_manifests/argocd-ingress-http.yaml\n3. Visit: http://argocd.local" : "GKE Ingress (Ephemeral IP):\n1. Get IP: kubectl get ingress -n argocd\n2. Add to /etc/hosts: <IP> argocd.local\n3. Visit: http://argocd.local"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_cli_login_command" {
  description = "Command to login with ArgoCD CLI"
  value = var.enable_https && var.domain_name != "" ? "argocd login argocd.${var.domain_name} --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" : "argocd login argocd.local --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d) --insecure"
}

output "port_forward_command" {
  description = "Port-forward command for local access"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:80"
}
