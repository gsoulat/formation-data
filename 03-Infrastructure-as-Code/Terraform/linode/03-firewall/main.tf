# Configuration du provider Linode
terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "linode" {
  token = var.linode_token
}

# Firewall pour serveur web
resource "linode_firewall" "web_firewall" {
  label = "web-firewall"

  # Règles entrantes
  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
  }

  # Politique par défaut : DROP
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  # Tags pour appliquer le firewall
  tags = ["web-server"]
}

# Instance avec firewall
resource "linode_instance" "web" {
  label           = "web-server"
  image           = "linode/ubuntu22.04"
  region          = "eu-central"
  type            = "g6-nanode-1"
  authorized_keys = [var.ssh_public_key]
  root_pass       = var.root_password

  tags = ["web-server", "terraform"]
}

# Associer le firewall à l'instance
resource "linode_firewall_device" "web_device" {
  firewall_id = linode_firewall.web_firewall.id
  entity_id   = linode_instance.web.id
}

# Outputs
output "instance_ip" {
  value = linode_instance.web.ip_address
}

output "firewall_status" {
  value = linode_firewall.web_firewall.status
}
