# Workspace Security

## Introduction

La **sécurité des workspaces** est le premier niveau de contrôle d'accès dans Microsoft Fabric, définissant qui peut voir et interagir avec les éléments.

```
Security Layers:
┌─────────────────────────────────┐
│  Azure AD Authentication        │  ← Identity verification
├─────────────────────────────────┤
│  Workspace Roles                │  ← Access level (Admin, Member, etc.)
├─────────────────────────────────┤
│  Item Permissions               │  ← Granular object access
├─────────────────────────────────┤
│  RLS/CLS/Masking                │  ← Data-level security
└─────────────────────────────────┘
```

## Workspace Roles

### Admin

```
Full control over workspace

Permissions:
  ✅ Add/remove members
  ✅ Change workspace settings
  ✅ Delete workspace
  ✅ Create, edit, delete all items
  ✅ Publish content
  ✅ Configure connections
  ✅ Manage permissions

Use cases:
  • Technical leads
  • Team managers
  • Platform administrators

Best practice:
  Limit admins (principle of least privilege)
  Minimum 2 admins for redundancy
```

### Member

```
Create and modify content

Permissions:
  ✅ Create new items (datasets, reports)
  ✅ Edit existing items
  ✅ Delete items they created
  ✅ Publish content
  ✅ Share items
  ❌ Add workspace members
  ❌ Change workspace settings

Use cases:
  • Data engineers
  • Data analysts
  • Report developers

Typical team:
  5-10 members per workspace
  Active content creators
```

### Contributor

```
Edit existing content only

Permissions:
  ✅ Edit existing items
  ✅ Refresh datasets
  ✅ View all items
  ❌ Create new items
  ❌ Delete items
  ❌ Share workspace content

Use cases:
  • Occasional editors
  • External consultants
  • QA testers

Restriction:
  Cannot create from scratch
  Can modify existing work
```

### Viewer

```
Read-only access

Permissions:
  ✅ View reports and dashboards
  ✅ Interact with visuals (filter, drill)
  ✅ Export to PDF/PowerPoint
  ❌ Edit anything
  ❌ Access underlying data models
  ❌ Create or modify

Use cases:
  • Business stakeholders
  • Executive leadership
  • End consumers of reports

Most common role:
  Majority of users are viewers
  Consume but don't create
```

## Managing Workspace Access

### Adding Members

```
Via Fabric Portal:
1. Open workspace
2. Click "Manage access" (top right)
3. Type user email or group name
4. Select role (Admin/Member/Contributor/Viewer)
5. Click "Add"

Via PowerShell:
$workspaceId = "xxxxxxxx-xxxx-xxxx-xxxx"
Add-PowerBIWorkspaceUser -Id $workspaceId `
    -UserEmailAddress "user@company.com" `
    -AccessRight "Member"

Via REST API:
POST https://api.powerbi.com/v1.0/myorg/groups/{groupId}/users
{
    "emailAddress": "user@company.com",
    "groupUserAccessRight": "Member"
}
```

### Using Azure AD Groups

```
Benefits of groups:
  ✅ Easier management (add to group, not workspace)
  ✅ Consistent across environments
  ✅ Integrates with organizational structure
  ✅ Bulk permission changes

Configuration:
1. Create Azure AD security group
   Group: "Finance-Data-Analysts"
   Members: analyst1@company.com, analyst2@company.com

2. Add group to workspace
   Workspace → Manage access → Add "Finance-Data-Analysts"
   Role: Member

3. Group membership changes automatically reflected
   New employee joins Finance team → Added to group → Has workspace access

Best practice:
  Always use groups over individual users
  Name groups descriptively (Team-Role-Environment)
  Document group purposes
```

### Removing Access

```
Remove user/group:
1. Manage access
2. Find user/group
3. Click "..." menu
4. Select "Remove"

When to remove:
  • Employee leaves team
  • Project completed
  • Role change
  • Security audit findings

Important:
  RLS roles remain even after workspace removal
  User loses workspace access but RLS definition stays
  Clean up RLS assignments separately
```

## Service Principals

### What is a Service Principal?

```
Service Principal = Application identity (non-human)

Use cases:
  ✅ Automated pipelines (CI/CD)
  ✅ Data refresh without user credentials
  ✅ API integrations
  ✅ Scheduled tasks
  ❌ Interactive user sessions

Benefits:
  • No user password expiration
  • Auditable as separate identity
  • Can be secured with certificates
  • Multiple environments, single identity
```

### Creating Service Principal

```
Azure Portal:
1. Azure Active Directory → App registrations
2. + New registration
3. Name: "Fabric-DataPipeline-Prod"
4. Supported account types: Single tenant
5. Register

Credentials:
  Option A: Client secret
    App → Certificates & secrets → New client secret
    Save secret value (shown once!)
    Expires after set period

  Option B: Certificate (more secure)
    Upload .cer file
    No expiration concerns
    Better for production

Record:
  • Application (client) ID
  • Directory (tenant) ID
  • Client secret or certificate thumbprint
```

### Adding Service Principal to Workspace

```
Requirements:
1. Enable service principals in tenant settings
   Admin Portal → Tenant settings → Service principals can use Fabric APIs
   Enable for specific security group

2. Add service principal to workspace
   Manage access → Enter app name or ID → Select role

3. Grant API permissions
   Azure Portal → App → API permissions
   Add "Power BI Service" permissions

Example code:
# PowerShell with service principal
$tenantId = "xxxxxxxx"
$appId = "xxxxxxxx"
$secret = ConvertTo-SecureString "secret" -AsPlainText -Force
$cred = New-Object PSCredential($appId, $secret)

Connect-PowerBIServiceAccount -ServicePrincipal -Credential $cred -TenantId $tenantId

Get-PowerBIWorkspace -Name "Sales Analytics"
```

## Managed Identities

### System-Assigned Identity

```
Automatic identity for Azure resources

Use case:
  Azure Data Factory → Fabric Lakehouse
  No credentials to manage

Configuration:
  1. Enable system identity on ADF
     ADF → Identity → System assigned → On

  2. Grant identity access to Fabric
     Fabric workspace → Add ADF identity
     Role: Member (for write operations)

  3. Use in ADF pipelines
     Copy Activity → Linked service → Managed Identity auth

Benefits:
  ✅ No credential rotation
  ✅ Automatic lifecycle (deleted with resource)
  ✅ Azure manages security
```

### User-Assigned Identity

```
Standalone identity, reusable

Use case:
  Multiple Azure services share same identity
  Central management

Configuration:
  1. Create user-assigned identity
     Azure → Managed Identities → Create

  2. Assign to resources
     VM, ADF, Functions → Identity → Add user-assigned

  3. Grant to Fabric workspace
     Add identity as workspace member

Benefits:
  ✅ Shareable across resources
  ✅ Independent lifecycle
  ✅ Pre-created before resource deployment
```

## Item-Level Permissions

### Sharing Individual Items

```
Beyond workspace roles:

Scenario:
  User needs ONE report, not entire workspace

Share specific item:
1. Report → Share button
2. Enter recipient email
3. Choose permissions:
   • Read only
   • Allow reshare
   • Allow Build (create new content from dataset)

Result:
  User sees shared item in "Shared with me"
  No workspace access required
  Limited to that specific item
```

### Build Permissions

```
Create content on top of dataset

What Build allows:
  ✅ Create reports using this dataset
  ✅ Create composite models
  ✅ Access in "Get Data" dialogs
  ❌ View underlying data model
  ❌ Edit dataset itself

Configuration:
  Dataset → Manage permissions → Add user → Build

Use case:
  Self-service BI: Analysts create their own reports
  Dataset owner maintains single source of truth
  Users leverage shared semantic model
```

### Permission Inheritance

```
How permissions flow:

Workspace Admin
  ↓ (automatic)
All items in workspace
  ↓ (optional sharing)
Specific items to external users

Example:
  Anna is workspace Member
    → Can edit all reports in workspace

  Bob received shared Report A
    → Can view only Report A
    → Cannot see other workspace content

  Carol received dataset Build permission
    → Can create reports on dataset
    → Cannot view workspace
```

## Security Scenarios

### Multi-Environment Setup

```
Common pattern: Dev → Test → Prod

Configuration:
  Workspace: Sales-Analytics-DEV
    Admins: Platform team
    Members: All developers

  Workspace: Sales-Analytics-TEST
    Admins: Platform team
    Members: Test team, QA
    Viewers: Business testers

  Workspace: Sales-Analytics-PROD
    Admins: Platform team (2-3 people)
    Members: Senior developers only
    Viewers: All business users

Benefits:
  • Separation of concerns
  • Testing before production
  • Controlled promotion
  • Clear responsibilities
```

### External Collaboration

```
Sharing with external partners

Options:
1. Azure AD B2B (recommended)
   External user added to Azure AD as guest
   Full audit trail
   Conditional access policies apply

2. Public embedding
   No authentication required
   Use only for truly public data
   Embed in public websites

Configuration for B2B:
  1. Invite external user to Azure AD
  2. Add guest user to workspace
  3. Guest receives email notification
  4. Guest signs in with their organization credentials

Security considerations:
  • External guests marked in audit logs
  • Apply sensitivity labels
  • Consider data residency
  • Limit permissions (viewer only usually)
```

### Automation Security

```
CI/CD pipeline permissions

Scenario:
  GitHub Actions deploys to Fabric

Setup:
  1. Service principal for pipeline
  2. Grant Member role to workspace
  3. Store credentials securely (Key Vault)
  4. Pipeline uses SP to deploy

Security measures:
  • Rotate secrets periodically
  • Use certificates over secrets
  • Limit SP to specific workspaces
  • Monitor SP activity in audit logs

Example pipeline:
  name: Deploy to Fabric
  steps:
    - uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    - run: |
        pwsh -Command "Connect-PowerBIServiceAccount -ServicePrincipal ..."
```

## Best Practices

### Principle of Least Privilege

```
Grant minimum required access

Examples:
  ❌ Bad: Everyone is Admin "for convenience"
  ✅ Good: Only 2-3 Admins, rest are Members or Viewers

  ❌ Bad: Single workspace for all projects
  ✅ Good: Separate workspaces by team/project

  ❌ Bad: Individual user permissions everywhere
  ✅ Good: Azure AD groups for permission management

Review regularly:
  • Quarterly permission audits
  • Remove stale access
  • Verify role appropriateness
```

### Access Review Checklist

```
Monthly/Quarterly tasks:
  [ ] List all workspace members
  [ ] Verify each user still needs access
  [ ] Check role appropriateness
  [ ] Review service principal usage
  [ ] Validate group memberships
  [ ] Remove terminated employees
  [ ] Document changes made

Tools:
  • Azure AD Access Reviews
  • Power BI Activity Logs
  • Custom PowerShell scripts
```

### Documentation

```
Maintain records of:

1. Workspace inventory
   - Name, purpose, environment
   - Admin contacts
   - Security classification

2. Access matrix
   - User/Group → Workspace → Role
   - Justification for access
   - Expiration date (if temporary)

3. Service principal registry
   - App name, purpose
   - Workspaces with access
   - Credential rotation schedule

4. Change log
   - Who changed what, when, why
   - Approval records
   - Audit trail
```

## Monitoring Access

### Activity Logs

```
Track who does what:

Captured events:
  • Workspace created/deleted
  • User added/removed
  • Role changed
  • Items accessed
  • Data exported

Access logs:
  Admin Portal → Audit logs
  Filter by workspace, user, activity

Example findings:
  "User exported 10MB of data at 3 AM"
  "Admin role granted without approval"
  "Failed login attempts from unknown IP"
```

### Compliance Reporting

```
Generate reports for:
  • Who has access to what
  • Role distribution (admins vs viewers)
  • External user count
  • Service principal inventory
  • Permission changes over time

PowerShell script:
$workspaces = Get-PowerBIWorkspace -Scope Organization
foreach ($ws in $workspaces) {
    $users = Get-PowerBIWorkspaceUser -Id $ws.Id
    Export-Csv -Path "AccessReport.csv" -Append
}
```

## Points Clés

- 4 workspace roles: Admin (full control), Member (create), Contributor (edit), Viewer (read)
- Use Azure AD groups instead of individual user assignments
- Service principals for automation (no user credentials)
- Managed identities for Azure-to-Fabric integration
- Item-level sharing for selective access without full workspace
- Build permission enables self-service BI
- Multi-environment pattern: Dev → Test → Prod workspaces
- Principle of least privilege: minimum necessary access
- Regular access reviews prevent permission creep
- Activity logs provide audit trail for compliance

---

**Prochain fichier :** [02 - Row-Level Security (RLS)](./02-row-level-security.md)

[⬅️ Retour au README du module](./README.md)
