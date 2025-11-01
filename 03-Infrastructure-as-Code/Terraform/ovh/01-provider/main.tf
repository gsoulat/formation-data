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

# Récupérer les informations du projet
data "ovh_cloud_project_region" "regions" {
  service_name = var.project_id
}

# Output
output "available_regions" {
  value = data.ovh_cloud_project_region.regions
}

output "project_id" {
  value = var.project_id
}
