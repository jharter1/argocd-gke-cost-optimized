# Generate a unique project ID if not provided
resource "random_id" "project_id" {
  count       = var.create_project && var.project_id == "" ? 1 : 0
  byte_length = 4
}

locals {
  project_id = var.create_project ? (
    var.project_id != "" ? var.project_id : "argocd-dev-${random_id.project_id[0].hex}"
  ) : var.project_id
}

# Create GCP Project
resource "google_project" "project" {
  count           = var.create_project ? 1 : 0
  name            = var.project_name
  project_id      = local.project_id
  billing_account = var.billing_account

  # Auto-delete default service accounts to keep it clean
  auto_create_network = false

  # Removed prevent_destroy for dev environment
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com"
  ])

  project = var.create_project ? google_project.project[0].project_id : var.project_id
  service = each.value

  # Don't disable services when destroying
  disable_on_destroy = false

  depends_on = [google_project.project]
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.create_project ? google_project.project[0].project_id : var.project_id

  depends_on = [google_project_service.required_apis]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.create_project ? google_project.project[0].project_id : var.project_id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.11.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "10.12.0.0/16"
  }
}

# GKE Cluster
resource "google_container_cluster" "dev_cluster" {
  name     = var.cluster_name
  location = var.zone
  project  = var.create_project ? google_project.project[0].project_id : var.project_id

  # Disable deletion protection for dev environment
  deletion_protection = false

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "services-range"
  }

  # Enable basic auth and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Node Pool
resource "google_container_node_pool" "dev_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.dev_cluster.name
  node_count = var.node_count
  project    = var.create_project ? google_project.project[0].project_id : var.project_id

  node_config {
    preemptible  = true
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.cluster_name}-gke-sa"
  display_name = "GKE Service Account"
  project      = var.create_project ? google_project.project[0].project_id : var.project_id
}

# IAM binding for the service account
resource "google_project_iam_member" "gke_service_account" {
  project = var.create_project ? google_project.project[0].project_id : var.project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Reserve a static external IP for the ingress (optional, costs money)
resource "google_compute_global_address" "argocd_ip" {
  count        = var.create_static_ip ? 1 : 0
  name         = "argocd-ingress-ip"
  project      = var.create_project ? google_project.project[0].project_id : var.project_id
  address_type = "EXTERNAL"
  
  depends_on = [google_project_service.required_apis]
}

# Google-managed SSL certificate for ArgoCD (only if HTTPS enabled and domain provided)
resource "google_compute_managed_ssl_certificate" "argocd_ssl_cert" {
  count   = var.enable_https && var.domain_name != "" && var.create_static_ip ? 1 : 0
  name    = "argocd-ssl-cert"
  project = var.create_project ? google_project.project[0].project_id : var.project_id

  managed {
    domains = ["argocd.${var.domain_name}"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.required_apis]
}
