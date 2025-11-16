# Tenant Settings Configuration

## Introduction

Les Tenant Settings constituent le panneau de contrôle central pour configurer les fonctionnalités et les politiques de sécurité à l'échelle de l'organisation dans Microsoft Fabric. Ces paramètres déterminent quelles fonctionnalités sont disponibles, qui peut les utiliser, et comment les données sont partagées et protégées.

## Accès au Tenant Settings

### Via Admin Portal

1. Se connecter à app.fabric.microsoft.com
2. Cliquer sur l'icône Settings (engrenage)
3. Sélectionner "Admin portal"
4. Naviguer vers "Tenant settings"

### Permissions Requises

- Fabric Administrator
- Power Platform Administrator
- Global Administrator

## Catégories de Paramètres

### 1. Help and Support Settings

```json
{
  "helpAndSupportSettings": {
    "receiveEmailNotificationsForServiceOutages": true,
    "usersCanTryFabricPaidFeatures": false,
    "showCustomHelpUrl": true,
    "customHelpUrl": "https://support.company.com/fabric"
  }
}
```

### 2. Workspace Settings

Configuration des permissions de création et gestion des workspaces :

| Setting | Description | Recommandation Prod |
|---------|-------------|---------------------|
| Create workspaces | Qui peut créer des workspaces | Security Group spécifique |
| Use semantic models across workspaces | Partage de datasets | Enabled |
| Block users from reassigning personal workspaces | Protection My Workspace | Enabled |
| Define workspace retention period | Rétention après suppression | 30-90 jours |

### 3. Export and Sharing

```powershell
# Script PowerShell pour auditer les paramètres d'export
$tenantSettings = Get-PowerBITenantSettings

$exportSettings = @{
    "ExportToExcel" = $tenantSettings.exportToExcelSetting
    "ExportToCsv" = $tenantSettings.exportToCsvSetting
    "ExportToImage" = $tenantSettings.exportToImageSetting
    "ExportToPDF" = $tenantSettings.exportToPDFSetting
    "PrintDashboards" = $tenantSettings.printDashboardsSetting
}

$exportSettings | ConvertTo-Json
```

## Configuration de Sécurité

### Information Protection

Protection des données sensibles avec Microsoft Purview :

```python
# Configuration des labels de sensibilité via Graph API
import requests

def configure_sensitivity_labels(access_token, workspace_id):
    """Configure les labels de sensibilité pour un workspace"""

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }

    # Appliquer un label de sensibilité
    payload = {
        "sensitivityLabelId": "guid-du-label-confidential",
        "assignmentMethod": "Privileged"
    }

    url = f"https://api.powerbi.com/v1.0/myorg/groups/{workspace_id}/sensitivityLabels"

    response = requests.post(url, headers=headers, json=payload)
    return response.status_code == 200
```

### External Data Sharing

Paramètres critiques pour le partage externe :

1. **Allow Azure Active Directory guest users** : Contrôle des utilisateurs invités
2. **Publish to web** : DÉSACTIVER en production
3. **Email subscriptions to external users** : Restreindre aux groupes approuvés
4. **Allow XMLA endpoints** : Activer pour outils tiers (Tabular Editor, etc.)

## Developer Settings

### API et Intégrations

```json
{
  "developerSettings": {
    "serviceUsersCanAccessFabricItemsAPIs": true,
    "usersCanAccessFabricRESTAPI": "EnabledForSpecificSecurityGroups",
    "securityGroups": ["SG-Fabric-Developers"],
    "embedContentInApps": true,
    "allowServicePrincipalsToUseReadonlyAdminAPIs": true,
    "servicePrincipalGroup": "SG-Service-Principals"
  }
}
```

### Git Integration Settings

```powershell
# Activer Git integration au niveau tenant
Set-PowerBITenantSettings -SettingName "GitIntegration" -Enabled $true

# Restreindre aux branches protégées
$gitSettings = @{
    "allowedProviders" = @("AzureDevOps", "GitHub")
    "branchProtection" = $true
    "requireCodeReview" = $true
}
```

## Paramètres OneLake

Configuration spécifique pour OneLake :

| Setting | Description | Impact |
|---------|-------------|--------|
| Users can access data stored in OneLake with external tools | ADLS Gen2 APIs | Performance externe |
| Users can sync data in OneLake with OneLake file explorer | Sync local | Risque sécurité |
| OneLake shortcut permissions | Accès cross-tenant | Gouvernance données |

## Audit des Configurations

```sql
-- Requête pour suivre les changements de configuration
SELECT
    activity_date,
    setting_name,
    previous_value,
    new_value,
    changed_by,
    change_reason
FROM fabric_audit.tenant_settings_changes
WHERE activity_date >= DATEADD(day, -30, GETDATE())
ORDER BY activity_date DESC;
```

## Best Practices

1. **Principe du moindre privilège** : Restreindre par défaut, ouvrir selon les besoins
2. **Documentation** : Maintenir un registre des paramètres et justifications
3. **Review périodique** : Auditer les settings mensuellement
4. **Testing** : Tester les changements dans un tenant de dev d'abord
5. **Change Management** : Process formel pour modifications critiques

## Points Clés

- Les Tenant Settings impactent TOUS les utilisateurs de l'organisation
- Toujours documenter les changements avec justification business
- Utiliser les Security Groups pour un contrôle granulaire
- Désactiver "Publish to web" dans les environnements sensibles
- Activer l'audit logging pour tracer les modifications
- Réviser régulièrement les paramètres selon l'évolution des besoins

---

**Navigation** : [Précédent : Capacity Management](./01-capacity-management.md) | [Index](../README.md) | [Suivant : Workspace Governance](./03-workspace-governance.md)
