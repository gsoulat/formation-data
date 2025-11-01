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

# Locals
locals {
  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  }
}

# Clé SSH
resource "hcloud_ssh_key" "default" {
  name       = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

# Serveurs
resource "hcloud_server" "servers" {
  for_each = var.servers

  name        = "${var.project_name}-${each.key}"
  server_type = each.value.type
  image       = each.value.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = merge(local.common_tags, {
    role = each.key
  })
}

# Outputs
output "servers" {
  value = {
    for k, v in hcloud_server.servers : k => {
      ip     = v.ipv4_address
      status = v.status
    }
  }
}
