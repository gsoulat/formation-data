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

# Récupérer les informations du compte
data "linode_account" "me" {}

# Récupérer les régions disponibles
data "linode_regions" "all" {}

# Outputs
output "account_email" {
  value = data.linode_account.me.email
}

output "available_regions" {
  value = [for region in data.linode_regions.all.regions : region.id]
}
