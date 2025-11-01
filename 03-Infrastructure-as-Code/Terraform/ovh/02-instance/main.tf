# Configuration du provider OVHcloud
terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.35"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
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

# Récupérer les informations OpenStack
data "ovh_cloud_project_vrack" "vrack" {
  service_name = var.project_id
}

# Créer une clé SSH
resource "ovh_cloud_project_user" "user" {
  service_name = var.project_id
  description  = "Terraform user"
}

# Instance Public Cloud
resource "ovh_cloud_project_instance" "web" {
  service_name = var.project_id
  name         = "web-server"
  flavor_name  = "s1-2"     # 1 vCore, 2GB RAM
  image_name   = "Ubuntu 22.04"
  region       = "GRA11"    # Gravelines

  ssh_key_ids = [
    ovh_cloud_project_user.user.id
  ]
}

# Outputs
output "instance_ip" {
  value = ovh_cloud_project_instance.web.ip_address
}

output "instance_status" {
  value = ovh_cloud_project_instance.web.status
}

output "ssh_command" {
  value = "ssh ubuntu@${ovh_cloud_project_instance.web.ip_address}"
}
