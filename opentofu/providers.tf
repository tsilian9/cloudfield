terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 2.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.0"
    }
  }
}

# Kubernetes provider – reads automatically from ~/.kube/config
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "microk8s"
}

# MinIO provider
provider "minio" {
  minio_server   = var.minio_endpoint
  minio_user     = var.minio_user
  minio_password = var.minio_password
  minio_ssl      = false
}

# Keycloak provider
provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_user
  password  = var.keycloak_admin_password
  url       = var.keycloak_url
}
