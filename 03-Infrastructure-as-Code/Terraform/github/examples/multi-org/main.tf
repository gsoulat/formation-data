terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
}

# Production Organization
module "production_org" {
  source = "../../"

  github_token              = var.github_token
  organization_name         = var.production_org_name
  organization_display_name = "${var.production_org_name} Production"
  organization_description  = "Production environment organization"
  organization_email        = var.organization_email
  reviewer_username         = var.reviewer_username

  users = var.production_users

  repositories = {
    backend = {
      name        = "backend-prod"
      description = "Production backend application"
      private     = true
    }
    frontend = {
      name        = "frontend-prod"
      description = "Production frontend application"
      private     = true
    }
    data = {
      name        = "data-pipeline-prod"
      description = "Production data processing pipeline"
      private     = true
    }
    infrastructure = {
      name        = "infrastructure-prod"
      description = "Production infrastructure as code"
      private     = true
    }
  }
}

# Staging Organization
module "staging_org" {
  source = "../../"

  github_token              = var.github_token
  organization_name         = var.staging_org_name
  organization_display_name = "${var.staging_org_name} Staging"
  organization_description  = "Staging environment organization"
  organization_email        = var.organization_email
  reviewer_username         = var.reviewer_username

  users = var.staging_users

  repositories = {
    backend = {
      name        = "backend-staging"
      description = "Staging backend application"
      private     = true
    }
    frontend = {
      name        = "frontend-staging"
      description = "Staging frontend application"
      private     = true
    }
    data = {
      name        = "data-pipeline-staging"
      description = "Staging data processing pipeline"
      private     = true
    }
    testing = {
      name        = "e2e-tests"
      description = "End-to-end testing suite"
      private     = true
    }
  }
}

# Development Organization
module "development_org" {
  source = "../../"

  github_token              = var.github_token
  organization_name         = var.development_org_name
  organization_display_name = "${var.development_org_name} Development"
  organization_description  = "Development environment organization"
  organization_email        = var.organization_email
  reviewer_username         = var.reviewer_username

  users = var.development_users

  repositories = {
    backend = {
      name        = "backend-dev"
      description = "Development backend application"
      private     = true
    }
    frontend = {
      name        = "frontend-dev"
      description = "Development frontend application"
      private     = true
    }
    data = {
      name        = "data-pipeline-dev"
      description = "Development data processing pipeline"
      private     = true
    }
    experimental = {
      name        = "experimental-features"
      description = "Experimental features and prototypes"
      private     = true
    }
    documentation = {
      name        = "docs"
      description = "Project documentation and guides"
      private     = false
    }
  }
}