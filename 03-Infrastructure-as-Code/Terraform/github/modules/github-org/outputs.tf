output "organization_id" {
  description = "ID of the GitHub organization"
  value       = data.github_organization.main.id
}

output "organization_login" {
  description = "Login name of the GitHub organization"
  value       = data.github_organization.main.login
}

output "organization_url" {
  description = "URL of the GitHub organization"
  value       = "https://github.com/${data.github_organization.main.login}"
}

output "organization_node_id" {
  description = "Node ID of the GitHub organization"
  value       = data.github_organization.main.node_id
}

output "organization_members_count" {
  description = "Number of members in the organization"
  value       = length(data.github_organization.main.users)
}