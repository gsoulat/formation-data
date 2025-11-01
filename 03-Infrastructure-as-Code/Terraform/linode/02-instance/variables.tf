variable "linode_token" {
  description = "Linode API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique"
  type        = string
}

variable "root_password" {
  description = "Mot de passe root (min 8 caractères avec majuscule, minuscule et chiffre)"
  type        = string
  sensitive   = true
}
