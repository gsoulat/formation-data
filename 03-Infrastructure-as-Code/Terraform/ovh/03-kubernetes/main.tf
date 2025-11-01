# Configuration du provider OVHcloud
terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.35"
    }
  }
  required_version = ">= 1.0"
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# Cluster Kubernetes managé
resource "ovh_cloud_project_kube" "cluster" {
  service_name = var.project_id
  name         = "k8s-cluster"
  region       = "GRA11"
  version      = "1.28"

  private_network_id = null  # Optionnel: ID du vRack
}

# Node Pool
resource "ovh_cloud_project_kube_nodepool" "pool" {
  service_name  = var.project_id
  kube_id       = ovh_cloud_project_kube.cluster.id
  name          = "default-pool"
  flavor_name   = "b2-7"  # 2 vCore, 7GB RAM
  desired_nodes = 3
  min_nodes     = 1
  max_nodes     = 5

  autoscale     = true
  monthly_billed = false
}

# Outputs
output "cluster_id" {
  value = ovh_cloud_project_kube.cluster.id
}

output "cluster_url" {
  value = ovh_cloud_project_kube.cluster.url
}

output "kubeconfig" {
  value     = ovh_cloud_project_kube.cluster.kubeconfig
  sensitive = true
}

output "kubeconfig_file" {
  value = "Sauvegarder avec: terraform output -raw kubeconfig > kubeconfig.yaml"
}
