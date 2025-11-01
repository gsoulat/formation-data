# Configuration du provider OpenStack pour Infomaniak Public Cloud
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
  required_version = ">= 1.0"
}

# Provider OpenStack
provider "openstack" {
  auth_url    = "https://api.pub1.infomaniak.cloud/identity/v3"
  region      = "dc3-a"
  user_name   = var.user_name
  password    = var.password
  tenant_name = var.project_name
  domain_name = "default"
}

# Récupérer les informations du projet
data "openstack_identity_project_v3" "project" {
  name = var.project_name
}

# Récupérer les flavors disponibles
data "openstack_compute_flavor_v2" "flavors" {
  vcpus = 1
}

# Outputs
output "project_id" {
  value = data.openstack_identity_project_v3.project.id
}

output "auth_url" {
  value = "https://api.pub1.infomaniak.cloud/identity/v3"
}
