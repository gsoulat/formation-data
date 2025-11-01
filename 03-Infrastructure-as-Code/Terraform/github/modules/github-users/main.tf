terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Add users to the organization
resource "github_membership" "users" {
  for_each = var.users

  username = each.value.username
  role     = each.value.role
}

# Add reviewer as admin if not already in users list
resource "github_membership" "reviewer" {
  count = contains([for user in var.users : user.username], var.reviewer_username) ? 0 : 1

  username = var.reviewer_username
  role     = "admin"
}