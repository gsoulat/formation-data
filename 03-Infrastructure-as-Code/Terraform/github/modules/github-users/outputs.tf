output "organization_members" {
  description = "List of organization members"
  value = merge(
    {
      for k, v in github_membership.users : k => {
        username = v.username
        role     = v.role
      }
    },
    length(github_membership.reviewer) > 0 ? {
      reviewer = {
        username = github_membership.reviewer[0].username
        role     = github_membership.reviewer[0].role
      }
    } : {}
  )
}

output "member_usernames" {
  description = "List of member usernames"
  value = concat(
    [for membership in github_membership.users : membership.username],
    length(github_membership.reviewer) > 0 ? [github_membership.reviewer[0].username] : []
  )
}