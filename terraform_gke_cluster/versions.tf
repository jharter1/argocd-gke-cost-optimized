terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  # Project will be set by resource configuration
  region = var.region
  zone   = var.zone
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.dev_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.dev_cluster.master_auth.0.cluster_ca_certificate)
}

data "google_client_config" "default" {}
