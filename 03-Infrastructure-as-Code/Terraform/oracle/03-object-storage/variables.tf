variable "tenancy_ocid" {
  description = "OCID du tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID de l'utilisateur"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint de la clé API"
  type        = string
}

variable "private_key_path" {
  description = "Chemin vers la clé privée"
  type        = string
}

variable "region" {
  description = "Région OCI"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "compartment_ocid" {
  description = "OCID du compartiment"
  type        = string
}
