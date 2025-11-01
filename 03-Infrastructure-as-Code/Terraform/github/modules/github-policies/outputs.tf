output "github_repo_url" {
  description = "URL of the .github repository"
  value       = github_repository.github_repo.html_url
}

output "workflows_created" {
  description = "List of created workflow files"
  value = concat(
    [
      github_repository_file.conventional_commits_workflow.file,
      github_repository_file.branch_naming_workflow.file
    ],
    [for file in github_repository_file.ci_workflow : file.file]
  )
}

output "policies_applied" {
  description = "Repositories with policies applied"
  value       = [for k, v in var.repositories : k]
}