variable "github_token" {
  description = "GitHub personal access token with admin:org permissions"
  type        = string
  sensitive   = true
}

variable "organization_email" {
  description = "Email for all organizations"
  type        = string
}

variable "reviewer_username" {
  description = "GitHub username of the primary reviewer for all organizations"
  type        = string
}

# Production Organization Variables
variable "production_org_name" {
  description = "Name of the production GitHub organization"
  type        = string
}

variable "production_users" {
  description = "Users for the production organization"
  type = map(object({
    username = string
    role     = string
  }))
  default = {}
}

# Staging Organization Variables
variable "staging_org_name" {
  description = "Name of the staging GitHub organization"
  type        = string
}

variable "staging_users" {
  description = "Users for the staging organization"
  type = map(object({
    username = string
    role     = string
  }))
  default = {}
}

# Development Organization Variables
variable "development_org_name" {
  description = "Name of the development GitHub organization"
  type        = string
}

variable "development_users" {
  description = "Users for the development organization"
  type = map(object({
    username = string
    role     = string
  }))
  default = {}
}