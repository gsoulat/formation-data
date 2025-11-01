# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This Terraform project manages GitHub organizations and repositories with enforced security policies, branch protection, and user access controls.

## Architecture

### Module Structure
- `modules/github-org/` - Core organization management module
- `modules/github-repo/` - Repository creation and configuration module  
- `modules/github-users/` - User management and permissions module
- `modules/github-policies/` - Branch protection and CI policies module

### Key Components
- **Organization Management**: Creates GitHub organizations with default settings
- **Repository Templates**: Default repos (backend, frontend, data) with standardized configurations
- **User Access Control**: Limited user permissions preventing direct pushes to main/develop
- **Branch Protection**: Enforces semantic branch naming and conventional commits
- **CI/CD Integration**: Automated checks for commit conventions and PR reviews

## Development Commands

### Terraform Operations
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### Module Testing
```bash
terraform plan -target=module.github-org
terraform plan -target=module.github-repo
```

## Configuration Requirements

### Required Variables
- `github_token` - GitHub personal access token with admin:org permissions
- `organization_name` - Target GitHub organization name
- `reviewer_username` - Primary reviewer for all PRs
- `default_repositories` - List of default repos to create (backend, frontend, data)

### Branch Protection Rules
- **Main/Develop**: No direct pushes, requires PR with review approval
- **Feature Branches**: Must follow semantic naming (feature/, bugfix/, hotfix/)
- **Commit Messages**: Must follow conventional commit format
- **Required Checks**: CI pipeline must pass before merge

### User Permissions
- Standard users: Create branches, submit PRs, cannot push to protected branches
- Reviewer role: Approve/reject PRs, merge permissions
- Admin role: Full organization access

## Repository Templates

Each default repository includes:
- Branch protection rules
- Required CI workflows (.github/workflows/)
- Conventional commit validation
- PR templates
- Issue templates

## CI/CD Pipeline

GitHub Actions workflows enforce:
- Conventional commit message validation
- Semantic branch name validation  
- Code quality checks
- Automated PR labeling
- Review assignment

## Adding New Organizations

Use the modular structure to duplicate configurations:
```hcl
module "org_production" {
  source = "./modules/github-org"
  organization_name = "my-prod-org"
  # ... other variables
}

module "org_staging" {
  source = "./modules/github-org" 
  organization_name = "my-staging-org"
  # ... other variables
}
```

## Adding New Users

Extend user configurations in variables:
```hcl
variable "organization_users" {
  type = map(object({
    username = string
    role     = string
  }))
}
```

## Security Considerations

- GitHub tokens stored in Terraform Cloud/state encryption
- Principle of least privilege for user permissions
- Audit logging enabled for organization activities
- Branch protection cannot be bypassed by admins