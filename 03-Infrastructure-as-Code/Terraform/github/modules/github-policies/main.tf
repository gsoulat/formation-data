terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Create .github repository for organization-wide workflows
resource "github_repository" "github_repo" {
  name        = ".github"
  description = "Organization-wide GitHub workflows and policies"
  visibility  = "private"

  has_issues      = false
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  auto_init = true
}

# Conventional commits validation workflow
resource "github_repository_file" "conventional_commits_workflow" {
  repository = github_repository.github_repo.name
  branch     = "main"
  file       = ".github/workflows/conventional-commits.yml"
  content = templatefile("${path.module}/templates/conventional-commits.yml", {
    reviewer_username = var.reviewer_username
  })

  commit_message      = "Add conventional commits validation workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  depends_on = [github_repository.github_repo]
}

# Branch naming validation workflow
resource "github_repository_file" "branch_naming_workflow" {
  repository = github_repository.github_repo.name
  branch     = "main"
  file       = ".github/workflows/branch-naming.yml"
  content = templatefile("${path.module}/templates/branch-naming.yml", {
    reviewer_username = var.reviewer_username
  })

  commit_message      = "Add branch naming validation workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  depends_on = [github_repository.github_repo]
}

# CODEOWNERS file for repository management
resource "github_repository_file" "codeowners" {
  for_each = var.repositories

  repository = each.value.name
  branch     = "main"
  file       = "CODEOWNERS"
  content = templatefile("${path.module}/templates/CODEOWNERS", {
    reviewer_username = var.reviewer_username
  })

  commit_message      = "Add CODEOWNERS file"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Pull request template
resource "github_repository_file" "pr_template" {
  for_each = var.repositories

  repository = each.value.name
  branch     = "main"
  file       = ".github/pull_request_template.md"
  content    = file("${path.module}/templates/pull_request_template.md")

  commit_message      = "Add pull request template"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

}

# CI/CD workflow for each repository
resource "github_repository_file" "ci_workflow" {
  for_each = var.repositories

  repository = each.value.name
  branch     = "main"
  file       = ".github/workflows/ci.yml"
  content    = file("${path.module}/templates/ci.yml")

  commit_message      = "Add CI/CD workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Commitlint configuration for each repository
resource "github_repository_file" "commitlint_config" {
  for_each = var.repositories

  repository = each.value.name
  branch     = "main"
  file       = ".commitlintrc.json"
  content = jsonencode({
    extends = ["@commitlint/config-conventional"]
    rules = {
      "type-enum" = [2, "always", [
        "feat", "fix", "docs", "style", "refactor",
        "perf", "test", "chore", "ci", "build", "revert"
      ]]
      "type-case"              = [2, "always", "lower-case"]
      "type-empty"             = [2, "never"]
      "scope-case"             = [2, "always", "lower-case"]
      "subject-case"           = [2, "never", ["sentence-case", "start-case", "pascal-case", "upper-case"]]
      "subject-empty"          = [2, "never"]
      "subject-full-stop"      = [2, "never", "."]
      "header-max-length"      = [2, "always", 72]
      "body-leading-blank"     = [1, "always"]
      "body-max-line-length"   = [2, "always", 100]
      "footer-leading-blank"   = [1, "always"]
      "footer-max-line-length" = [2, "always", 100]
    }
  })

  commit_message      = "Add commitlint configuration"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}