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

provider "hcloud" {
  token = var.hcloud_token
}

# Créer une clé SSH
resource "hcloud_ssh_key" "default" {
  name       = "terraform-key"
  public_key = var.ssh_public_key
}

# Créer un serveur
resource "hcloud_server" "web" {
  name        = "web-server"
  server_type = "cx11" # 1 vCPU, 2GB RAM
  image       = "ubuntu-22.04"
  location    = "nbg1" # Nuremberg
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Outputs
output "server_ip" {
  value       = hcloud_server.web.ipv4_address
  description = "Adresse IP du serveur"
}

output "server_status" {
  value       = hcloud_server.web.status
  description = "Statut du serveur"
}
