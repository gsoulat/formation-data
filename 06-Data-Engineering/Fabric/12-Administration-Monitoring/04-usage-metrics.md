# Usage Metrics and Analytics

## Introduction

Les métriques d'utilisation dans Microsoft Fabric fournissent des insights précieux sur l'adoption, les performances et les patterns d'usage. Ces données permettent aux administrateurs de prendre des décisions éclairées sur l'allocation des ressources, l'optimisation des coûts et l'amélioration de l'expérience utilisateur.

## Sources de Métriques

### 1. Fabric Capacity Metrics App

Application Power BI pré-construite pour le monitoring des capacités :

```powershell
# Installation de l'app Capacity Metrics
# Via Admin Portal > Monitoring apps > Install

# Configuration des paramètres
$capacityMetricsConfig = @{
    "CapacityId" = "your-capacity-guid"
    "RefreshSchedule" = "Every 30 minutes"
    "RetentionDays" = 30
    "AlertThresholds" = @{
        "CPUOverload" = 80
        "MemoryUsage" = 90
        "Throttling" = 5
    }
}
```

### 2. Activity Log

Journal détaillé de toutes les activités utilisateur :

```python
import requests
from datetime import datetime, timedelta

def get_activity_events(access_token, start_date, end_date, activity_type=None):
    """
    Récupère les événements d'activité via l'API Admin
    """
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }

    base_url = "https://api.powerbi.com/v1.0/myorg/admin/activityevents"

    params = {
        'startDateTime': start_date.isoformat() + 'Z',
        'endDateTime': end_date.isoformat() + 'Z'
    }

    if activity_type:
        params['$filter'] = f"Activity eq '{activity_type}'"

    all_activities = []
    continuation_uri = f"{base_url}?{urlencode(params)}"

    while continuation_uri:
        response = requests.get(continuation_uri, headers=headers)
        data = response.json()

        all_activities.extend(data.get('activityEventEntities', []))
        continuation_uri = data.get('continuationUri')

    return all_activities

# Exemple d'utilisation
# activities = get_activity_events(token, start, end, "ViewReport")
```

## Métriques Clés à Monitorer

### Performance Metrics

| Métrique | Description | Seuil Critique |
|----------|-------------|----------------|
| Query Duration P95 | 95th percentile temps requête | > 30 secondes |
| Refresh Duration | Temps de rafraîchissement datasets | > 2 heures |
| Query Failures | Taux d'échec des requêtes | > 5% |
| Throttling Percentage | % requêtes limitées | > 10% |

### Adoption Metrics

```sql
-- Requête pour analyser l'adoption
SELECT
    DATE_TRUNC('week', activity_date) as week,
    COUNT(DISTINCT user_id) as active_users,
    COUNT(DISTINCT workspace_id) as active_workspaces,
    COUNT(*) as total_activities,
    COUNT(CASE WHEN activity_type = 'ViewReport' THEN 1 END) as report_views,
    COUNT(CASE WHEN activity_type = 'CreateReport' THEN 1 END) as reports_created,
    COUNT(CASE WHEN activity_type = 'ExportData' THEN 1 END) as data_exports
FROM fabric_audit.activity_log
WHERE activity_date >= DATEADD(month, -3, GETDATE())
GROUP BY DATE_TRUNC('week', activity_date)
ORDER BY week DESC;
```

### Usage Patterns

```python
import pandas as pd
import matplotlib.pyplot as plt

def analyze_usage_patterns(activity_df):
    """
    Analyse les patterns d'utilisation
    """
    # Distribution par heure de la journée
    activity_df['hour'] = pd.to_datetime(activity_df['timestamp']).dt.hour
    hourly_usage = activity_df.groupby('hour').size()

    # Top utilisateurs
    top_users = activity_df.groupby('user_email').size().nlargest(10)

    # Types d'activités les plus fréquentes
    activity_types = activity_df['activity_type'].value_counts()

    # Jours de la semaine
    activity_df['day_of_week'] = pd.to_datetime(activity_df['timestamp']).dt.day_name()
    daily_pattern = activity_df.groupby('day_of_week').size()

    return {
        'hourly_usage': hourly_usage,
        'top_users': top_users,
        'activity_types': activity_types,
        'daily_pattern': daily_pattern
    }

def create_usage_dashboard(patterns):
    """
    Crée un dashboard visuel des patterns
    """
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))

    # Graphique 1: Usage horaire
    patterns['hourly_usage'].plot(kind='bar', ax=axes[0,0])
    axes[0,0].set_title('Activité par Heure')
    axes[0,0].set_xlabel('Heure')
    axes[0,0].set_ylabel('Nombre d\'activités')

    # Graphique 2: Top utilisateurs
    patterns['top_users'].plot(kind='barh', ax=axes[0,1])
    axes[0,1].set_title('Top 10 Utilisateurs')

    # Graphique 3: Types d'activités
    patterns['activity_types'].head(10).plot(kind='pie', ax=axes[1,0])
    axes[1,0].set_title('Distribution des Activités')

    # Graphique 4: Pattern hebdomadaire
    patterns['daily_pattern'].plot(kind='bar', ax=axes[1,1])
    axes[1,1].set_title('Activité par Jour')

    plt.tight_layout()
    return fig
```

## Alerting et Notifications

### Configuration des Alertes

```json
{
  "alertRules": [
    {
      "name": "High CPU Usage",
      "metric": "cpu_utilization",
      "condition": "GreaterThan",
      "threshold": 85,
      "windowSize": "PT15M",
      "frequency": "PT5M",
      "severity": 2,
      "actionGroup": "ag-fabric-admins"
    },
    {
      "name": "Query Failures Spike",
      "metric": "query_failure_rate",
      "condition": "GreaterThan",
      "threshold": 10,
      "windowSize": "PT1H",
      "frequency": "PT15M",
      "severity": 1,
      "actionGroup": "ag-critical-alerts"
    },
    {
      "name": "Low User Adoption",
      "metric": "daily_active_users",
      "condition": "LessThan",
      "threshold": 50,
      "windowSize": "P1D",
      "frequency": "P1D",
      "severity": 3,
      "actionGroup": "ag-business-insights"
    }
  ]
}
```

### Script de Notification

```powershell
# Envoi d'alertes personnalisées
function Send-UsageAlert {
    param(
        [string]$AlertType,
        [string]$Message,
        [string]$Severity
    )

    $webhookUrl = "https://company.webhook.office.com/..."

    $body = @{
        "@type" = "MessageCard"
        "summary" = "Fabric Usage Alert"
        "sections" = @(
            @{
                "activityTitle" = "Alert: $AlertType"
                "facts" = @(
                    @{name = "Severity"; value = $Severity},
                    @{name = "Message"; value = $Message},
                    @{name = "Time"; value = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")}
                )
            }
        )
    }

    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($body | ConvertTo-Json -Depth 10)
}
```

## Reporting Automatisé

### Rapport Hebdomadaire

```sql
-- Template pour rapport hebdomadaire
WITH weekly_summary AS (
    SELECT
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(*) as total_operations,
        AVG(query_duration_ms) as avg_query_time,
        SUM(data_processed_gb) as total_data_gb,
        SUM(compute_minutes) as total_compute_min
    FROM fabric_metrics.operations
    WHERE operation_date >= DATEADD(week, -1, GETDATE())
)
SELECT
    unique_users,
    total_operations,
    ROUND(avg_query_time / 1000.0, 2) as avg_query_seconds,
    ROUND(total_data_gb, 2) as data_processed_gb,
    ROUND(total_compute_min / 60.0, 2) as compute_hours,
    ROUND((total_data_gb * 0.05 + total_compute_min * 0.01), 2) as estimated_cost_usd
FROM weekly_summary;
```

## Points Clés

- Installer et configurer la Capacity Metrics App pour un monitoring continu
- Analyser les patterns d'utilisation pour optimiser les ressources
- Mettre en place des alertes proactives sur les seuils critiques
- Générer des rapports réguliers pour stakeholders
- Utiliser les métriques pour justifier les investissements et optimisations
- Tracker l'adoption pour mesurer le ROI de la plateforme

---

**Navigation** : [Précédent : Workspace Governance](./03-workspace-governance.md) | [Index](../README.md) | [Suivant : Cost Management](./05-cost-management.md)
