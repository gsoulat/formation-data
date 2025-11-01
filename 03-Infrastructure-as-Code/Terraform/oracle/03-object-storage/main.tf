# Configuration du provider OCI
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

# Créer un bucket Object Storage
resource "oci_objectstorage_bucket" "data" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "data-bucket"
  access_type    = "NoPublicAccess"

  versioning = "Enabled"

  metadata = {
    "environment" = "dev"
    "managed_by"  = "terraform"
  }
}

# Récupérer le namespace
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

# Créer un objet dans le bucket
resource "oci_objectstorage_object" "readme" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.data.name
  object    = "README.txt"
  content   = "Ceci est un exemple de bucket Object Storage OCI créé avec Terraform"
}

# Outputs
output "bucket_name" {
  value = oci_objectstorage_bucket.data.name
}

output "namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_url" {
  value = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.ns.namespace}/b/${oci_objectstorage_bucket.data.name}/o/"
}
