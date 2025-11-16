# Cost Management in Microsoft Fabric

## Introduction

La gestion des coûts dans Microsoft Fabric est un aspect critique de l'administration. Avec le modèle de tarification basé sur la consommation de Capacity Units (CUs), il est essentiel de comprendre comment les coûts sont générés, de les monitorer en temps réel et d'optimiser les dépenses sans compromettre les performances.

## Modèle de Tarification

### Structure des Coûts Fabric

```python
# Calcul simplifié des coûts Fabric
class FabricCostCalculator:
    def __init__(self):
        # Prix indicatifs par région (USD/heure)
        self.sku_prices = {
            'F2': 0.36,
            'F4': 0.72,
            'F8': 1.44,
            'F16': 2.88,
            'F32': 5.76,
            'F64': 11.52,
            'F128': 23.04
        }

        # Coût stockage OneLake (USD/GB/mois)
        self.storage_cost_per_gb = 0.023

    def calculate_monthly_cost(self, sku, hours_per_month=730, storage_gb=0):
        """
        Calcule le coût mensuel estimé
        """
        compute_cost = self.sku_prices[sku] * hours_per_month
        storage_cost = storage_gb * self.storage_cost_per_gb

        total = compute_cost + storage_cost

        return {
            'compute_cost': round(compute_cost, 2),
            'storage_cost': round(storage_cost, 2),
            'total_monthly': round(total, 2)
        }

    def estimate_workload_cost(self, operations):
        """
        Estime le coût basé sur les opérations planifiées
        """
        total_cus = 0

        for op in operations:
            cus_consumed = op['duration_seconds'] * op['cu_rate']
            total_cus += cus_consumed

        # Conversion CU-seconds vers coût
        cost_per_cu_second = 0.00000139  # Approximatif
        return round(total_cus * cost_per_cu_second, 4)

# Exemple d'utilisation
calculator = FabricCostCalculator()
monthly = calculator.calculate_monthly_cost('F8', storage_gb=500)
print(f"Coût mensuel estimé: ${monthly['total_monthly']}")
```

### Consommation par Workload

| Workload | CU Consumption Rate | Billing Unit |
|----------|---------------------|--------------|
| Data Engineering (Spark) | Variable selon vCores | Par seconde d'exécution |
| Data Warehouse | Query-based | Par TB scanné |
| Real-Time Analytics | Ingestion + Query | Par événement + requête |
| Power BI | Report rendering | Par refresh/render |
| Data Factory | Pipeline runs | Par activité exécutée |

## Monitoring des Coûts

### Dashboard de Suivi

```sql
-- Vue pour le suivi quotidien des coûts
CREATE VIEW cost_monitoring.daily_cost_summary AS
SELECT
    operation_date,
    workspace_name,
    workload_type,
    SUM(cu_seconds_consumed) as total_cu_seconds,
    SUM(data_scanned_gb) as total_data_gb,
    SUM(storage_used_gb) as storage_gb,
    -- Calcul des coûts estimés
    SUM(cu_seconds_consumed) * 0.00000139 as compute_cost_usd,
    SUM(storage_used_gb) * 0.023 / 30 as daily_storage_cost_usd
FROM fabric_metrics.operations
GROUP BY operation_date, workspace_name, workload_type;

-- Rapport de coûts par département
SELECT
    department,
    SUM(compute_cost_usd + daily_storage_cost_usd) as total_cost,
    AVG(compute_cost_usd + daily_storage_cost_usd) as avg_daily_cost,
    MAX(compute_cost_usd + daily_storage_cost_usd) as peak_daily_cost
FROM cost_monitoring.daily_cost_summary dcs
JOIN governance.workspace_metadata wm ON dcs.workspace_name = wm.workspace_name
WHERE operation_date >= DATEADD(month, -1, GETDATE())
GROUP BY department
ORDER BY total_cost DESC;
```

### Azure Cost Management Integration

```powershell
# Export des données de coût vers Azure Cost Management
function Export-FabricCostData {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    # Connexion à Azure
    Connect-AzAccount
    Set-AzContext -SubscriptionId $SubscriptionId

    # Récupération des coûts Fabric
    $costData = Get-AzConsumptionUsageDetail `
        -ResourceGroup $ResourceGroupName `
        -StartDate $StartDate `
        -EndDate $EndDate `
        | Where-Object { $_.ConsumedService -like "*Fabric*" }

    # Agrégation par ressource
    $costSummary = $costData | Group-Object InstanceName | ForEach-Object {
        [PSCustomObject]@{
            Resource = $_.Name
            TotalCost = ($_.Group | Measure-Object PretaxCost -Sum).Sum
            Currency = $_.Group[0].Currency
            UsageQuantity = ($_.Group | Measure-Object UsageQuantity -Sum).Sum
        }
    }

    return $costSummary
}
```

## Stratégies d'Optimisation

### 1. Right-Sizing des Capacités

```python
def recommend_capacity_size(usage_metrics):
    """
    Recommande la taille de capacité optimale basée sur l'usage
    """
    avg_cpu = usage_metrics['avg_cpu_percent']
    peak_cpu = usage_metrics['peak_cpu_percent']
    throttling_events = usage_metrics['throttling_count']

    current_sku = usage_metrics['current_sku']

    recommendations = []

    # Sous-utilisation
    if avg_cpu < 30 and peak_cpu < 60:
        recommendations.append({
            'action': 'DOWNSIZE',
            'reason': f'Average CPU only {avg_cpu}%, consider smaller SKU',
            'potential_savings': '30-50%'
        })

    # Sur-utilisation
    if avg_cpu > 70 or throttling_events > 10:
        recommendations.append({
            'action': 'UPSIZE',
            'reason': f'High utilization ({avg_cpu}%) or throttling detected',
            'impact': 'Improved performance, reduced throttling'
        })

    # Autoscaling
    if peak_cpu > 90 and avg_cpu < 50:
        recommendations.append({
            'action': 'ENABLE_AUTOSCALE',
            'reason': 'High variance between peak and average usage',
            'benefit': 'Pay for peak only when needed'
        })

    return recommendations
```

### 2. Scheduling Intelligent

```json
{
  "costOptimizationSchedule": {
    "pauseCapacity": {
      "enabled": true,
      "weekdays": {
        "pause": "19:00",
        "resume": "07:00"
      },
      "weekends": "pause_all",
      "holidays": "pause_all"
    },
    "batchJobScheduling": {
      "preferredWindow": "02:00-06:00",
      "reason": "Lower costs during off-peak hours"
    },
    "reportRefreshOptimization": {
      "consolidate": true,
      "maxConcurrent": 3,
      "offPeakOnly": true
    }
  }
}
```

### 3. Query Optimization

```sql
-- Identifier les requêtes coûteuses
SELECT TOP 20
    query_hash,
    COUNT(*) as execution_count,
    AVG(duration_ms) as avg_duration,
    SUM(data_scanned_gb) as total_data_scanned,
    SUM(estimated_cost_usd) as total_cost,
    query_text_sample
FROM fabric_metrics.query_history
WHERE execution_date >= DATEADD(day, -7, GETDATE())
GROUP BY query_hash, query_text_sample
ORDER BY total_cost DESC;

-- Recommandations d'optimisation
/*
1. Partitionner les tables fréquemment filtrées
2. Utiliser les colonnes V-Order pour les scans
3. Éviter SELECT * - sélectionner uniquement les colonnes nécessaires
4. Matérialiser les agrégations fréquentes
5. Implémenter le caching intelligent
*/
```

## Alertes et Budgets

### Configuration des Alertes de Budget

```powershell
# Création d'alerte de budget Azure
$budgetParams = @{
    Name = "Fabric-Monthly-Budget"
    ResourceGroupName = "rg-fabric-prod"
    Amount = 5000
    TimeGrain = "Monthly"
    StartDate = (Get-Date).ToString("yyyy-MM-01")
    Category = "Cost"
    NotificationThreshold = @(50, 75, 90, 100)
    ContactEmails = @("admin@company.com", "finance@company.com")
}

New-AzConsumptionBudget @budgetParams

# Alerte spécifique Fabric
$alertRule = @{
    Name = "Fabric-Cost-Spike"
    Condition = "DailyCost > 200"
    Action = "SendEmail"
    Recipients = @("fabric-admins@company.com")
    Message = "Daily Fabric cost exceeded $200 threshold"
}
```

### Rapport de Chargeback

```sql
-- Rapport de facturation interne par département
SELECT
    department,
    project_code,
    workspace_name,
    MONTH(operation_date) as billing_month,
    YEAR(operation_date) as billing_year,
    SUM(compute_cost) as compute_charges,
    SUM(storage_cost) as storage_charges,
    SUM(network_cost) as network_charges,
    SUM(compute_cost + storage_cost + network_cost) as total_charges
FROM cost_monitoring.chargeback_details
WHERE operation_date >= DATEADD(month, -1, GETDATE())
GROUP BY department, project_code, workspace_name,
         MONTH(operation_date), YEAR(operation_date)
ORDER BY total_charges DESC;
```

## Points Clés

- Comprendre le modèle CU-based pour prédire les coûts
- Monitorer quotidiennement la consommation par workspace
- Implémenter le right-sizing basé sur l'usage réel
- Utiliser le scheduling pour réduire les coûts (pause/resume)
- Optimiser les requêtes les plus coûteuses
- Configurer des alertes de budget proactives
- Mettre en place le chargeback pour la responsabilisation des équipes

---

**Navigation** : [Précédent : Usage Metrics](./04-usage-metrics.md) | [Index](../README.md) | [Suivant : Auditing and Logging](./06-auditing-logging.md)
