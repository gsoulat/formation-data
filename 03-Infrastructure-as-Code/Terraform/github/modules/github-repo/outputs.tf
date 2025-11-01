output "repositories" {
  description = "Created repositories information"
  value = {
    for k, v in github_repository.repos : k => {
      id            = v.id
      name          = v.name
      full_name     = v.full_name
      description   = v.description
      private       = v.private
      clone_url     = v.clone_url
      ssh_clone_url = v.ssh_clone_url
      git_clone_url = v.git_clone_url
      html_url      = v.html_url
    }
  }
}

output "repository_urls" {
  description = "URLs of created repositories"
  value = {
    for k, v in github_repository.repos : k => v.html_url
  }
}

output "repository_names" {
  description = "Names of created repositories"
  value       = [for repo in github_repository.repos : repo.name]
}