output "organization_url" {
  description = "URL of the created GitHub organization"
  value       = module.github_organization.organization_url
}

# output "organization_members" {
#   description = "List of organization members"
#   value       = module.github_users.organization_members
# }

# output "repositories" {
#   description = "Created repositories information"
#   value       = module.github_repositories.repositories
# }

# output "repository_urls" {
#   description = "URLs of created repositories"
#   value       = module.github_repositories.repository_urls
# }
