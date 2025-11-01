variable "organization_name" {
  description = "Name of the GitHub organization"
  type        = string
}

variable "reviewer_username" {
  description = "GitHub username of the primary reviewer"
  type        = string
}

variable "repositories" {
  description = "Map of repositories to apply policies to"
  type = map(object({
    name        = string
    description = string
    private     = bool
    template    = optional(string, "default")
  }))
}