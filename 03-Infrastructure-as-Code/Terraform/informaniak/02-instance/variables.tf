variable "user_name" {
  description = "Nom d'utilisateur Infomaniak"
  type        = string
}

variable "password" {
  description = "Mot de passe Infomaniak"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé SSH publique"
  type        = string
}
