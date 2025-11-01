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

# Créer une instance Linode
resource "linode_instance" "web" {
  label           = "web-server"
  image           = "linode/ubuntu22.04"
  region          = "eu-central"  # Frankfurt
  type            = "g6-nanode-1" # 1GB RAM, 1 vCPU
  authorized_keys = [var.ssh_public_key]
  root_pass       = var.root_password

  tags = ["web", "terraform"]
}

# Outputs
output "instance_ip" {
  value       = linode_instance.web.ip_address
  description = "Adresse IP publique de l'instance"
}

output "instance_status" {
  value = linode_instance.web.status
}

output "ssh_command" {
  value = "ssh root@${linode_instance.web.ip_address}"
}
