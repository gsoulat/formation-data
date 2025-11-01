variable "organization_name" {
  description = "Name of the GitHub organization"
  type        = string
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