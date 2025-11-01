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

# Créer un VPC
resource "linode_vpc" "main" {
  label       = "main-vpc"
  description = "VPC principal pour l'infrastructure"
  region      = "eu-central"
}

# Créer un subnet
resource "linode_vpc_subnet" "main" {
  vpc_id = linode_vpc.main.id
  label  = "main-subnet"
  ipv4   = "10.0.1.0/24"
}

# Instance web dans le VPC
resource "linode_instance" "web" {
  label           = "web-server"
  image           = "linode/ubuntu22.04"
  region          = "eu-central"
  type            = "g6-nanode-1"
  authorized_keys = [var.ssh_public_key]
  root_pass       = var.root_password

  interface {
    purpose = "public"
  }

  interface {
    purpose     = "vpc"
    subnet_id   = linode_vpc_subnet.main.id
    ipv4_ranges = ["10.0.1.2/32"]
  }

  tags = ["web", "vpc"]
}

# Instance backend dans le même VPC
resource "linode_instance" "backend" {
  label           = "backend-server"
  image           = "linode/ubuntu22.04"
  region          = "eu-central"
  type            = "g6-nanode-1"
  authorized_keys = [var.ssh_public_key]
  root_pass       = var.root_password

  interface {
    purpose = "public"
  }

  interface {
    purpose     = "vpc"
    subnet_id   = linode_vpc_subnet.main.id
    ipv4_ranges = ["10.0.1.3/32"]
  }

  tags = ["backend", "vpc"]
}

# Outputs
output "vpc_id" {
  value = linode_vpc.main.id
}

output "web_public_ip" {
  value = linode_instance.web.ip_address
}

output "backend_public_ip" {
  value = linode_instance.backend.ip_address
}

output "web_private_ip" {
  value = "10.0.1.2"
}

output "backend_private_ip" {
  value = "10.0.1.3"
}
