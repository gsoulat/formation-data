# Workspace Governance

## Introduction

La gouvernance des workspaces dans Microsoft Fabric est essentielle pour maintenir l'ordre, la sécurité et l'efficacité dans une organisation. Un workspace est un conteneur logique qui regroupe les artefacts Fabric (lakehouses, warehouses, notebooks, reports, etc.). Une gouvernance solide assure la cohérence, facilite la collaboration et respecte les exigences de conformité.

## Structure des Workspaces

### Modèles d'Organisation

#### 1. Par Domaine Métier

```
├── WS-Finance-Dev
├── WS-Finance-Test
├── WS-Finance-Prod
├── WS-Marketing-Dev
├── WS-Marketing-Test
├── WS-Marketing-Prod
└── WS-RH-Prod
```

#### 2. Par Projet

```
├── WS-ProjectAlpha-Analytics
├── WS-ProjectAlpha-DataEng
├── WS-ProjectBeta-Analytics
└── WS-ProjectBeta-DataEng
```

#### 3. Hybride (Recommandé)

```
├── WS-Sales-DataPlatform-Prod
├── WS-Sales-Reporting-Prod
├── WS-HR-DataPlatform-Prod
└── WS-Corporate-SharedAssets
```

## Naming Conventions

### Standard de Nommage

```python
def generate_workspace_name(domain: str, function: str, environment: str) -> str:
    """
    Génère un nom de workspace standardisé

    Format: WS-{Domain}-{Function}-{Environment}
    """
    valid_environments = ['Dev', 'Test', 'UAT', 'Prod']

    if environment not in valid_environments:
        raise ValueError(f"Environment must be one of {valid_environments}")

    # Validation longueur (max 256 caractères)
    name = f"WS-{domain}-{function}-{environment}"

    if len(name) > 256:
        raise ValueError("Workspace name too long")

    return name

# Exemples
print(generate_workspace_name("Finance", "Reporting", "Prod"))
# Output: WS-Finance-Reporting-Prod

print(generate_workspace_name("Sales", "DataPlatform", "Dev"))
# Output: WS-Sales-DataPlatform-Dev
```

### Conventions pour les Artefacts

| Type | Préfixe | Exemple |
|------|---------|---------|
| Lakehouse | LH_ | LH_Sales_Bronze |
| Warehouse | DW_ | DW_Finance_Gold |
| Notebook | NB_ | NB_ETL_CustomerData |
| Pipeline | PL_ | PL_Daily_Ingestion |
| Report | RPT_ | RPT_Monthly_Revenue |
| Semantic Model | SM_ | SM_Sales_Analytics |

## Rôles et Permissions

### Workspace Roles

```powershell
# Script pour configurer les permissions workspace
function Set-WorkspaceGovernance {
    param(
        [string]$WorkspaceId,
        [hashtable]$RoleAssignments
    )

    foreach ($role in $RoleAssignments.Keys) {
        $members = $RoleAssignments[$role]

        foreach ($member in $members) {
            Add-PowerBIWorkspaceUser -Id $WorkspaceId `
                -UserPrincipalName $member `
                -AccessRight $role
        }
    }
}

# Configuration type
$governance = @{
    "Admin" = @("workspace-admin@company.com")
    "Member" = @("SG-DataEngineers", "SG-DataAnalysts")
    "Contributor" = @("SG-ReportDevelopers")
    "Viewer" = @("SG-BusinessUsers")
}

Set-WorkspaceGovernance -WorkspaceId "guid" -RoleAssignments $governance
```

### Matrice des Permissions

| Action | Admin | Member | Contributor | Viewer |
|--------|-------|--------|-------------|--------|
| Manage workspace | ✓ | ✗ | ✗ | ✗ |
| Add/remove users | ✓ | ✗ | ✗ | ✗ |
| Create/edit content | ✓ | ✓ | ✓ | ✗ |
| Delete content | ✓ | ✓ | ✗ | ✗ |
| Publish reports | ✓ | ✓ | ✓ | ✗ |
| View content | ✓ | ✓ | ✓ | ✓ |
| Share content | ✓ | ✓ | ✗ | ✗ |

## Lifecycle Management

### Workflow de Création

```sql
-- Table de tracking des demandes de workspace
CREATE TABLE governance.workspace_requests (
    request_id INT IDENTITY(1,1) PRIMARY KEY,
    requestor_email VARCHAR(255),
    workspace_name VARCHAR(256),
    domain VARCHAR(100),
    environment VARCHAR(20),
    business_justification TEXT,
    data_classification VARCHAR(50),
    estimated_users INT,
    approval_status VARCHAR(20) DEFAULT 'Pending',
    approved_by VARCHAR(255),
    approval_date DATETIME,
    created_date DATETIME DEFAULT GETDATE()
);

-- Insertion d'une nouvelle demande
INSERT INTO governance.workspace_requests (
    requestor_email,
    workspace_name,
    domain,
    environment,
    business_justification,
    data_classification,
    estimated_users
) VALUES (
    'analyst@company.com',
    'WS-Marketing-Campaigns-Prod',
    'Marketing',
    'Prod',
    'Analyse des performances des campagnes marketing Q4',
    'Confidential',
    15
);
```

### Archivage et Suppression

```python
from datetime import datetime, timedelta

def identify_inactive_workspaces(days_threshold=90):
    """
    Identifie les workspaces inactifs pour archivage
    """
    cutoff_date = datetime.now() - timedelta(days=days_threshold)

    # Query hypothétique vers l'API d'audit
    inactive_workspaces = []

    # Critères d'inactivité:
    # - Aucune modification d'artefact
    # - Aucune exécution de pipeline
    # - Aucune requête sur les données
    # - Aucune connexion utilisateur

    return inactive_workspaces

def archive_workspace(workspace_id):
    """
    Process d'archivage sécurisé
    """
    steps = [
        "1. Notifier les propriétaires (30 jours avant)",
        "2. Exporter les métadonnées et configurations",
        "3. Backup des artefacts critiques",
        "4. Documenter dans le registre de gouvernance",
        "5. Retirer des capacités actives",
        "6. Marquer comme archivé",
        "7. Supprimer après période de rétention"
    ]
    return steps
```

## Monitoring et Compliance

### Dashboard de Gouvernance

Métriques à suivre :
1. Nombre de workspaces par environnement
2. Conformité aux conventions de nommage
3. Distribution des rôles par workspace
4. Artefacts orphelins
5. Violations de politique de sécurité

### Audit Automatisé

```powershell
# Audit de conformité des workspaces
$workspaces = Get-PowerBIWorkspace -Scope Organization

$auditResults = foreach ($ws in $workspaces) {
    [PSCustomObject]@{
        Name = $ws.Name
        NamingCompliant = $ws.Name -match "^WS-[A-Z][a-z]+-[A-Z][a-z]+-(?:Dev|Test|UAT|Prod)$"
        HasAdmin = ($ws.Users | Where-Object {$_.AccessRight -eq "Admin"}).Count -gt 0
        HasDescription = -not [string]::IsNullOrEmpty($ws.Description)
        OnCapacity = $ws.IsOnDedicatedCapacity
        ItemCount = $ws.Items.Count
    }
}

$auditResults | Export-Csv "workspace_audit.csv" -NoTypeInformation
```

## Points Clés

- Établir des conventions de nommage strictes dès le départ
- Utiliser des Security Groups plutôt que des utilisateurs individuels
- Implémenter un workflow d'approbation pour la création de workspaces
- Monitorer régulièrement l'activité et archiver les workspaces inactifs
- Documenter chaque workspace avec sa justification business
- Aligner la gouvernance avec les politiques de sécurité organisationnelles

---

**Navigation** : [Précédent : Tenant Settings](./02-tenant-settings.md) | [Index](../README.md) | [Suivant : Usage Metrics](./04-usage-metrics.md)
