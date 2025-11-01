variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique"
  type        = string
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Localisation du datacenter"
  type        = string
  default     = "nbg1"

  validation {
    condition     = contains(["nbg1", "fsn1", "hel1"], var.location)
    error_message = "Location doit être nbg1 (Nuremberg), fsn1 (Falkenstein) ou hel1 (Helsinki)."
  }
}

variable "servers" {
  description = "Configuration des serveurs"
  type = map(object({
    type  = string
    image = string
  }))
  default = {
    web = {
      type  = "cx11"
      image = "ubuntu-22.04"
    }
    db = {
      type  = "cx21"
      image = "ubuntu-22.04"
    }
  }
}
