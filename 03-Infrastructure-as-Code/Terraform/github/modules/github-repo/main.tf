terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Create repositories
resource "github_repository" "repos" {
  for_each = var.repositories

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.private ? "private" : "public"

  # Repository settings
  has_issues      = true
  has_projects    = true
  has_wiki        = true
  has_discussions = true

  # Security settings
  vulnerability_alerts        = true
  delete_branch_on_merge      = true
  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = false
  allow_auto_merge            = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Default branch
  auto_init = true
}

# Create develop branch
resource "github_branch" "develop" {
  for_each = var.repositories

  repository = github_repository.repos[each.key].name
  branch     = "develop"

  depends_on = [github_repository.repos]
}

# Branch protection for main branch
resource "github_branch_protection" "main" {
  for_each = var.repositories

  repository_id                   = github_repository.repos[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = false
  allows_deletions                = false
  allows_force_pushes             = false
  required_linear_history         = true
  require_conversation_resolution = true

  required_status_checks {
    strict   = true
    contexts = ["ci/conventional-commits", "ci/branch-naming"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    restrict_dismissals             = false
    required_approving_review_count = 1
    require_code_owner_reviews      = false
    require_last_push_approval      = true
  }

  depends_on = [github_repository.repos]
}

# Branch protection for develop branch
resource "github_branch_protection" "develop" {
  for_each = var.repositories

  repository_id                   = github_repository.repos[each.key].node_id
  pattern                         = "develop"
  enforce_admins                  = false
  allows_deletions                = false
  allows_force_pushes             = false
  required_linear_history         = true
  require_conversation_resolution = true

  required_status_checks {
    strict   = true
    contexts = ["ci/conventional-commits", "ci/branch-naming"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    restrict_dismissals             = false
    required_approving_review_count = 1
    require_code_owner_reviews      = false
    require_last_push_approval      = true
  }

  depends_on = [github_repository.repos, github_branch.develop]
}