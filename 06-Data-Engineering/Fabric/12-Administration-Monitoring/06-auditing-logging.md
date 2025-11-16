# Auditing and Logging

## Introduction

L'audit et la journalisation dans Microsoft Fabric sont essentiels pour la conformité réglementaire, la sécurité et le troubleshooting. Un système d'audit robuste permet de tracer toutes les actions utilisateur, de détecter les comportements suspects et de répondre aux exigences de conformité (RGPD, SOX, HIPAA, etc.).

## Sources de Logs

### 1. Unified Audit Log (Microsoft 365)

Le Unified Audit Log capture toutes les activités Fabric :

```powershell
# Connexion à Exchange Online pour accéder aux audit logs
Connect-ExchangeOnline

# Recherche des activités Fabric
$auditLogs = Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -RecordType PowerBIAudit `
    -ResultSize 5000

# Export des résultats
$auditLogs | Select-Object CreationDate, UserIds, Operations, AuditData |
    Export-Csv "fabric_audit_logs.csv" -NoTypeInformation

# Analyse des activités sensibles
$sensitiveActivities = $auditLogs | Where-Object {
    $_.Operations -in @(
        'DeleteReport',
        'ExportReport',
        'ShareReport',
        'AddGroupMembers',
        'RemoveGroupMembers',
        'UpdateDatasetParameters'
    )
}
```

### 2. Activity Log API

```python
import requests
from datetime import datetime, timedelta
import pandas as pd

class FabricAuditClient:
    def __init__(self, access_token):
        self.token = access_token
        self.base_url = "https://api.powerbi.com/v1.0/myorg/admin"
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }

    def get_activity_events(self, start_date, end_date):
        """
        Récupère tous les événements d'activité
        """
        events = []
        continuation_token = None

        while True:
            url = f"{self.base_url}/activityevents"
            params = {
                'startDateTime': f"'{start_date.strftime('%Y-%m-%dT%H:%M:%S')}'",
                'endDateTime': f"'{end_date.strftime('%Y-%m-%dT%H:%M:%S')}'"
            }

            if continuation_token:
                url = continuation_token
                params = {}

            response = requests.get(url, headers=self.headers, params=params)
            data = response.json()

            events.extend(data.get('activityEventEntities', []))

            continuation_token = data.get('continuationUri')
            if not continuation_token:
                break

        return pd.DataFrame(events)

    def get_sensitive_operations(self, days=30):
        """
        Filtre les opérations sensibles
        """
        end = datetime.utcnow()
        start = end - timedelta(days=days)

        all_events = self.get_activity_events(start, end)

        sensitive_ops = [
            'DeleteReport', 'DeleteDashboard', 'DeleteDataset',
            'ExportArtifact', 'ExportData', 'ExportReport',
            'AddGroupMembers', 'DeleteGroupMembers',
            'TakeOverDatasource', 'SetScheduledRefresh',
            'UpdateGatewayDatasourceCredentials'
        ]

        return all_events[all_events['Activity'].isin(sensitive_ops)]
```

### 3. Azure Monitor Integration

```json
{
  "diagnosticSettings": {
    "name": "fabric-to-log-analytics",
    "workspaceId": "/subscriptions/.../workspaces/log-analytics-workspace",
    "logs": [
      {
        "category": "AllMetrics",
        "enabled": true,
        "retentionPolicy": {
          "enabled": true,
          "days": 90
        }
      },
      {
        "category": "AuditLogs",
        "enabled": true,
        "retentionPolicy": {
          "enabled": true,
          "days": 365
        }
      }
    ]
  }
}
```

## Types d'Événements Audités

### Catégories Principales

| Catégorie | Exemples | Criticité |
|-----------|----------|-----------|
| Authentication | SignIn, SignOut, MFA Challenge | Medium |
| Authorization | AddGroupMembers, ChangePermissions | High |
| Data Access | ViewReport, ExportData, QueryDataset | Medium-High |
| Content Management | CreateReport, DeleteDashboard, PublishToWeb | High |
| Administration | UpdateCapacityAdmins, ChangeTenantSettings | Critical |
| Sharing | ShareReport, CreateSubscription, InviteUser | High |

### Structure d'un Événement d'Audit

```json
{
  "Id": "event-guid",
  "RecordType": 20,
  "CreationTime": "2024-01-15T10:30:00Z",
  "Operation": "ViewReport",
  "OrganizationId": "org-guid",
  "UserType": 0,
  "UserKey": "user-key",
  "Workload": "PowerBI",
  "UserId": "user@company.com",
  "ClientIP": "192.168.1.100",
  "UserAgent": "Mozilla/5.0...",
  "Activity": "ViewReport",
  "ItemName": "Sales Dashboard",
  "WorkspaceName": "WS-Sales-Reporting-Prod",
  "DatasetName": "Sales Dataset",
  "ReportName": "Sales Dashboard",
  "CapacityId": "capacity-guid",
  "CapacityName": "fabric-prod-capacity",
  "ObjectId": "report-guid",
  "RequestId": "request-guid",
  "ActivityId": "activity-guid"
}
```

## Sécurité et Détection d'Anomalies

### Règles de Détection

```sql
-- Détection d'accès suspect hors heures ouvrables
SELECT
    user_id,
    activity_type,
    activity_timestamp,
    client_ip,
    workspace_name,
    item_name
FROM fabric_audit.activity_log
WHERE
    DATEPART(hour, activity_timestamp) NOT BETWEEN 7 AND 20
    AND DATEPART(weekday, activity_timestamp) NOT IN (1, 7) -- Pas weekend
    AND activity_type IN ('ExportData', 'ViewReport', 'QueryDataset')
    AND activity_timestamp >= DATEADD(day, -1, GETDATE())
ORDER BY activity_timestamp DESC;

-- Détection de suppression massive
WITH deletion_counts AS (
    SELECT
        user_id,
        DATE_TRUNC('hour', activity_timestamp) as hour_block,
        COUNT(*) as deletion_count
    FROM fabric_audit.activity_log
    WHERE activity_type LIKE 'Delete%'
    GROUP BY user_id, DATE_TRUNC('hour', activity_timestamp)
)
SELECT *
FROM deletion_counts
WHERE deletion_count > 10;

-- Accès depuis IP inhabituelle
WITH user_normal_ips AS (
    SELECT
        user_id,
        client_ip,
        COUNT(*) as access_count
    FROM fabric_audit.activity_log
    WHERE activity_timestamp >= DATEADD(month, -1, GETDATE())
    GROUP BY user_id, client_ip
    HAVING COUNT(*) > 10
)
SELECT al.*
FROM fabric_audit.activity_log al
LEFT JOIN user_normal_ips uni ON al.user_id = uni.user_id AND al.client_ip = uni.client_ip
WHERE uni.user_id IS NULL
  AND al.activity_timestamp >= DATEADD(day, -1, GETDATE());
```

### Alertes de Sécurité

```python
def detect_security_anomalies(activity_df):
    """
    Détecte les anomalies de sécurité potentielles
    """
    alerts = []

    # 1. Multiple échecs d'authentification
    failed_logins = activity_df[
        (activity_df['Activity'] == 'SignIn') &
        (activity_df['IsSuccess'] == False)
    ].groupby('UserId').size()

    for user, count in failed_logins.items():
        if count > 5:
            alerts.append({
                'type': 'BRUTE_FORCE_ATTEMPT',
                'user': user,
                'count': count,
                'severity': 'HIGH'
            })

    # 2. Export massif de données
    exports = activity_df[
        activity_df['Activity'].isin(['ExportData', 'ExportReport'])
    ].groupby(['UserId', activity_df['CreationTime'].dt.date]).size()

    for (user, date), count in exports.items():
        if count > 20:
            alerts.append({
                'type': 'MASS_DATA_EXPORT',
                'user': user,
                'date': str(date),
                'count': count,
                'severity': 'CRITICAL'
            })

    # 3. Changements de permissions administratives
    admin_changes = activity_df[
        activity_df['Activity'].isin([
            'AddGroupMembers', 'DeleteGroupMembers',
            'UpdateCapacityAdmins', 'ChangeTenantSettings'
        ])
    ]

    if len(admin_changes) > 0:
        for _, row in admin_changes.iterrows():
            alerts.append({
                'type': 'ADMIN_PERMISSION_CHANGE',
                'user': row['UserId'],
                'activity': row['Activity'],
                'timestamp': str(row['CreationTime']),
                'severity': 'HIGH'
            })

    return alerts
```

## Conformité et Rétention

### Politique de Rétention

```powershell
# Configuration de la rétention des logs
$retentionPolicy = @{
    "AuditLogs" = @{
        "RetentionDays" = 365
        "StorageLocation" = "Azure Blob Storage"
        "Encryption" = "AES-256"
        "ComplianceHold" = $true
    }
    "ActivityLogs" = @{
        "RetentionDays" = 90
        "StorageLocation" = "Log Analytics Workspace"
    }
    "MetricsData" = @{
        "RetentionDays" = 30
        "Aggregation" = "Daily"
    }
}

# Archivage vers stockage long terme
function Archive-AuditLogs {
    param([int]$OlderThanDays = 90)

    $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)

    # Export vers Azure Blob Storage
    $storageContext = New-AzStorageContext -StorageAccountName "fabricauditarchive"

    # Logique d'archivage...
}
```

### Rapports de Conformité

```sql
-- Rapport d'accès aux données sensibles (RGPD)
SELECT
    user_id,
    user_department,
    COUNT(DISTINCT item_id) as items_accessed,
    COUNT(*) as total_access_events,
    MIN(activity_timestamp) as first_access,
    MAX(activity_timestamp) as last_access
FROM fabric_audit.activity_log al
JOIN governance.sensitive_data_catalog sdc ON al.item_id = sdc.item_id
WHERE sdc.data_classification IN ('Confidential', 'Highly Confidential')
  AND al.activity_timestamp BETWEEN @StartDate AND @EndDate
GROUP BY user_id, user_department
ORDER BY total_access_events DESC;
```

## Points Clés

- Activer le Unified Audit Log au niveau tenant
- Exporter les logs vers un stockage centralisé (Log Analytics, SIEM)
- Implémenter des règles de détection d'anomalies automatisées
- Définir des politiques de rétention conformes aux réglementations
- Créer des dashboards de monitoring en temps réel
- Générer des rapports de conformité périodiques
- Protéger les logs contre la modification (immutabilité)
- Former les équipes à interpréter les événements d'audit

---

**Navigation** : [Précédent : Cost Management](./05-cost-management.md) | [Index](../README.md) | [Suivant : Disaster Recovery and Backup](./07-disaster-recovery-backup.md)
