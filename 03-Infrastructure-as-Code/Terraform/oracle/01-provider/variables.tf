variable "tenancy_ocid" {
  description = "OCID du tenancy OCI"
  type        = string
}

variable "user_ocid" {
  description = "OCID de l'utilisateur OCI"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint de la clé API"
  type        = string
}

variable "private_key_path" {
  description = "Chemin vers la clé privée OCI"
  type        = string
}

variable "region" {
  description = "Région OCI"
  type        = string
  default     = "eu-frankfurt-1"
}
