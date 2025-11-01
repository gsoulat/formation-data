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
  description = "Mot de passe root"
  type        = string
  sensitive   = true
}
