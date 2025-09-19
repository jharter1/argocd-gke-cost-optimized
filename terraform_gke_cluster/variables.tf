variable "project_id" {
  description = "GCP Project ID (will be created if create_project is true). Leave empty to auto-generate."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Human readable project name"
  type        = string
  default     = "ArgoCD Development"
}

variable "create_project" {
  description = "Whether to create a new GCP project"
  type        = bool
  default     = true
}

variable "billing_account" {
  description = "GCP Billing Account ID"
  type        = string
  default     = "017F23-ED7E5E-37C2E8"
}

variable "domain_name" {
  description = "Your domain name for creating SSL certificates (use a real domain or leave empty for HTTP-only)"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS with SSL certificates (requires real domain)"
  type        = bool
  default     = false
}

variable "use_nginx_ingress" {
  description = "Use NGINX Ingress Controller instead of GKE Ingress (cheaper for dev)"
  type        = bool
  default     = true
}

variable "create_static_ip" {
  description = "Create a static external IP (costs money, set to false for dev)"
  type        = bool
  default     = false
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "dev-argocd-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-medium"
}
