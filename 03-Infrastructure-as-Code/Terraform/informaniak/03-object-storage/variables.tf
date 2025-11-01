variable "access_key" {
  description = "Infomaniak Swiss Backup Access Key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Infomaniak Swiss Backup Secret Key"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Nom du bucket S3"
  type        = string
}
