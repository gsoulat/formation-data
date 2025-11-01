# Configuration du provider Oracle Cloud Infrastructure (OCI)
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Récupérer les informations de disponibilité
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Output
output "availability_domains" {
  value = data.oci_identity_availability_domains.ads.availability_domains[*].name
}
