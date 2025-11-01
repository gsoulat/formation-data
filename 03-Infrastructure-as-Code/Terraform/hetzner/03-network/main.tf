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

# Créer un réseau privé
resource "hcloud_network" "private_network" {
  name     = "private-net"
  ip_range = "10.0.0.0/16"
}

# Créer un sous-réseau
resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.private_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Créer une clé SSH
resource "hcloud_ssh_key" "default" {
  name       = "terraform-key"
  public_key = var.ssh_public_key
}

# Créer un serveur connecté au réseau privé
resource "hcloud_server" "app_server" {
  name        = "app-server"
  server_type = "cx11"
  image       = "ubuntu-22.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.5"
  }

  depends_on = [hcloud_network_subnet.subnet]
}

# Outputs
output "server_public_ip" {
  value = hcloud_server.app_server.ipv4_address
}

output "server_private_ip" {
  value = hcloud_server.app_server.network[0].ip
}

output "network_id" {
  value = hcloud_network.private_network.id
}
