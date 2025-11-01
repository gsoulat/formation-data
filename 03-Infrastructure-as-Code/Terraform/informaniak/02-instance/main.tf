# Configuration du provider OpenStack pour Infomaniak
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
  required_version = ">= 1.0"
}

provider "openstack" {
  auth_url    = "https://api.pub1.infomaniak.cloud/identity/v3"
  region      = "dc3-a"
  user_name   = var.user_name
  password    = var.password
  tenant_name = var.project_name
  domain_name = "default"
}

# Récupérer l'image Ubuntu
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04 LTS Jammy Jellyfish"
  most_recent = true
}

# Créer une clé SSH
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "terraform-key"
  public_key = var.ssh_public_key
}

# Créer un réseau privé
resource "openstack_networking_network_v2" "private" {
  name           = "private-network"
  admin_state_up = true
}

# Créer un sous-réseau
resource "openstack_networking_subnet_v2" "subnet" {
  name       = "private-subnet"
  network_id = openstack_networking_network_v2.private.id
  cidr       = "192.168.1.0/24"
  ip_version = 4
}

# Récupérer le réseau externe
data "openstack_networking_network_v2" "external" {
  name = "ext-floating1"
}

# Créer un routeur
resource "openstack_networking_router_v2" "router" {
  name                = "router"
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Connecter le sous-réseau au routeur
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

# Security group
resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "web-secgroup"
  description = "Security group for web server"
}

# Règle SSH
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

# Règle HTTP
resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

# Créer une instance
resource "openstack_compute_instance_v2" "web" {
  name            = "web-server"
  flavor_name     = "a1-ram2-disk20-perf1"  # 1 vCPU, 2GB RAM, 20GB
  image_id        = data.openstack_images_image_v2.ubuntu.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.secgroup.name]

  network {
    uuid = openstack_networking_network_v2.private.id
  }
}

# Floating IP
resource "openstack_networking_floatingip_v2" "fip" {
  pool = "ext-floating1"
}

# Associer la Floating IP
resource "openstack_compute_floatingip_associate_v2" "fip" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  instance_id = openstack_compute_instance_v2.web.id
}

# Outputs
output "instance_private_ip" {
  value = openstack_compute_instance_v2.web.access_ip_v4
}

output "instance_public_ip" {
  value = openstack_networking_floatingip_v2.fip.address
}

output "ssh_command" {
  value = "ssh ubuntu@${openstack_networking_floatingip_v2.fip.address}"
}
