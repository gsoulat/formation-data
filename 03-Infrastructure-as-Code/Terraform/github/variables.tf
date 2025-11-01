variable "github_token" {
  description = "GitHub personal access token with admin:org permissions"
  type        = string
  sensitive   = true
}

variable "organization_name" {
  description = "Name of the GitHub organization"
  type        = string
}

variable "organization_display_name" {
  description = "Display name of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_description" {
  description = "Description of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_email" {
  description = "Email of the GitHub organization"
  type        = string
  default     = ""
}

variable "reviewer_username" {
  description = "GitHub username of the primary reviewer"
  type        = string
}

variable "users" {
  description = "Map of users to add to the organization"
  type = map(object({
    username = string
    role     = string # "member" or "admin"
  }))
  default = {}
}

variable "repositories" {
  description = "List of repositories to create"
  type = map(object({
    name        = string
    description = string
    private     = bool
    template    = optional(string, "default")
  }))
  default = {
    backend = {
      name        = "backend"
      description = "Backend application repository"
      private     = true
    }
    frontend = {
      name        = "frontend"
      description = "Frontend application repository"
      private     = true
    }
    data = {
      name        = "data"
      description = "Data processing repository"
      private     = true
    }
  }
}