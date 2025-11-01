variable "instance_name" {
  type        = string
  description = "Name of the instance"
  default     = "ma_super_instance"
}

variable "region" {
  type        = string
  description = "Region of the instance"
  default     = "eu-north-1"
}


variable "key_name" {
  description = "Nom de la clé SSH pour accéder à l'instance"
  type        = string
  default     = "berry-devops"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_ips" {
  description = "Liste des IPs autorisées pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port sur lequel l'application écoute"
  type        = number
  default     = 3000
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "site-perso"
}
