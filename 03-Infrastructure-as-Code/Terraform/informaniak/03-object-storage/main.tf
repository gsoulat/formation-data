# Configuration pour Infomaniak Swiss Backup (S3 compatible)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Provider AWS configuré pour Infomaniak Swiss Backup
provider "aws" {
  region = "ch-gva-2"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "https://s3.swiss-backup02.infomaniak.com"
  }

  access_key = var.access_key
  secret_key = var.secret_key
}

# Créer un bucket S3
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name
}

# Versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Exemple d'objet
resource "aws_s3_object" "readme" {
  bucket  = aws_s3_bucket.data.id
  key     = "README.txt"
  content = "Bucket créé avec Terraform sur Infomaniak Swiss Backup"
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.data.id
}

output "bucket_region" {
  value = aws_s3_bucket.data.region
}

output "s3_endpoint" {
  value = "https://s3.swiss-backup02.infomaniak.com"
}

output "aws_cli_config" {
  value = <<-EOT
    Configuration AWS CLI pour Infomaniak:

    aws configure set aws_access_key_id ${var.access_key}
    aws configure set aws_secret_access_key ${var.secret_key}
    aws configure set region ch-gva-2

    Utilisation:
    aws s3 ls --endpoint-url https://s3.swiss-backup02.infomaniak.com
    aws s3 cp file.txt s3://${var.bucket_name}/ --endpoint-url https://s3.swiss-backup02.infomaniak.com
  EOT
}
