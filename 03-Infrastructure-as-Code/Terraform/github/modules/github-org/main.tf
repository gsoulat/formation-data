terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Note: GitHub organization creation via Terraform is limited
# Organizations are typically created manually via GitHub web interface
# This module configures existing organization settings

data "github_organization" "main" {
  name = var.organization_name
}

# Configure organization settings
resource "github_organization_settings" "main" {
  billing_email = var.organization_email
  blog          = var.organization_blog
  description   = var.organization_description
  email         = var.organization_email
  location      = var.organization_location
  name          = var.organization_display_name

  # Security settings
  dependency_graph_enabled_for_new_repositories            = true
  dependabot_alerts_enabled_for_new_repositories           = true
  dependabot_security_updates_enabled_for_new_repositories = true

  # Member settings
  members_can_create_repositories          = false
  members_can_create_public_repositories   = false
  members_can_create_private_repositories  = false
  members_can_create_internal_repositories = false
  members_can_create_pages                 = false
  members_can_fork_private_repositories    = false

  # Advanced security
  advanced_security_enabled_for_new_repositories               = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}