# Configuration du provider Hetzner Cloud
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
  required_version = ">= 1.0"
}

# Provider Hetzner Cloud
provider "hcloud" {
  token = var.hcloud_token
}

# Récupérer les informations du compte
data "hcloud_datacenters" "all" {}

# Afficher les datacenters disponibles
output "available_datacenters" {
  value = data.hcloud_datacenters.all.names
}
