# Configuration du provider OVHcloud
terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.35"
    }
  }
  required_version = ">= 1.0"
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# Créer un utilisateur S3
resource "ovh_cloud_project_user" "s3_user" {
  service_name = var.project_id
  description  = "S3 User for Object Storage"
  role_name    = "objectstore_operator"
}

# Générer les credentials S3
resource "ovh_cloud_project_user_s3_credential" "s3_creds" {
  service_name = var.project_id
  user_id      = ovh_cloud_project_user.s3_user.id
}

# Container Object Storage (compatible S3)
resource "ovh_cloud_project_object_storage_container" "bucket" {
  service_name = var.project_id
  region_name  = "GRA"
  name         = "my-data-bucket"
}

# Outputs
output "s3_access_key" {
  value     = ovh_cloud_project_user_s3_credential.s3_creds.access_key_id
  sensitive = true
}

output "s3_secret_key" {
  value     = ovh_cloud_project_user_s3_credential.s3_creds.secret_access_key
  sensitive = true
}

output "s3_endpoint" {
  value = "https://s3.gra.io.cloud.ovh.net"
}

output "bucket_name" {
  value = ovh_cloud_project_object_storage_container.bucket.name
}

output "s3_configuration" {
  value = <<-EOT
    Configuration AWS CLI:

    aws configure set aws_access_key_id ${ovh_cloud_project_user_s3_credential.s3_creds.access_key_id}
    aws configure set aws_secret_access_key ${ovh_cloud_project_user_s3_credential.s3_creds.secret_access_key}
    aws configure set region gra

    Utilisation:
    aws s3 ls --endpoint-url https://s3.gra.io.cloud.ovh.net
    aws s3 cp file.txt s3://my-data-bucket/ --endpoint-url https://s3.gra.io.cloud.ovh.net
  EOT
}
