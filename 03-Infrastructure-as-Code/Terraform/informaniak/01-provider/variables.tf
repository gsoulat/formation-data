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
  description = "Nom du projet Infomaniak Public Cloud"
  type        = string
}
