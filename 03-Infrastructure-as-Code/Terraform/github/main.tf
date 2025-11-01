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

module "github_organization" {
  source = "./modules/github-org"

  organization_name         = var.organization_name
  organization_display_name = var.organization_display_name
  organization_description  = var.organization_description
  organization_email        = var.organization_email
}

# module "github_users" {
#   source = "./modules/github-users"

#   organization_name = var.organization_name
#   users             = var.users
#   reviewer_username = var.reviewer_username

#   depends_on = [module.github_organization]
# }


# module "github_repositories" {
#   source = "./modules/github-repo"

#   organization_name = var.organization_name
#   repositories      = var.repositories
#   reviewer_username = var.reviewer_username

#   depends_on = [module.github_organization, module.github_users]
# }

# module "github_policies" {
#   source = "./modules/github-policies"

#   organization_name = var.organization_name
#   repositories      = var.repositories
#   reviewer_username = var.reviewer_username

#   depends_on = [module.github_repositories]
# }
