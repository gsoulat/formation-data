# Capacity Management in Microsoft Fabric

## Introduction

La gestion des capacités est un aspect fondamental de l'administration de Microsoft Fabric. Une capacity représente un ensemble dédié de ressources compute utilisées pour exécuter les workloads Fabric. Comprendre comment configurer, monitorer et optimiser ces capacités est essentiel pour garantir des performances optimales et maîtriser les coûts.

## Types de Capacités

### Fabric Capacity (F SKUs)

Les F SKUs sont les unités de capacité dédiées à Microsoft Fabric :

| SKU | Capacity Units (CUs) | Max Memory | Use Case |
|-----|---------------------|------------|----------|
| F2  | 2 | 3 GB | Développement/Test |
| F4  | 4 | 6 GB | Petites équipes |
| F8  | 8 | 12 GB | Production légère |
| F16 | 16 | 24 GB | Production standard |
| F32 | 32 | 48 GB | Workloads intensifs |
| F64+ | 64+ | 96+ GB | Enterprise |

### Power BI Premium (P SKUs)

Compatible avec Fabric mais optimisé pour Power BI :
- P1, P2, P3, P4, P5
- Migration progressive vers F SKUs recommandée

## Configuration de la Capacité

### Via Azure Portal

```powershell
# Création d'une capacité Fabric via Azure CLI
az resource create \
  --resource-group "rg-fabric-prod" \
  --resource-type "Microsoft.Fabric/capacities" \
  --name "fabric-prod-capacity" \
  --location "westeurope" \
  --sku "F8" \
  --properties '{
    "administration": {
      "members": ["admin@company.com"]
    }
  }'
```

### PowerShell Admin Module

```powershell
# Installation du module
Install-Module -Name MicrosoftPowerBIMgmt

# Connexion
Connect-PowerBIServiceAccount

# Récupération des capacités
$capacities = Get-PowerBICapacity
$capacities | Format-Table Name, Sku, State, Region

# Assignation d'un workspace à une capacité
Set-PowerBIWorkspace -Id "workspace-guid" -CapacityId "capacity-guid"
```

## Monitoring des Performances

### Metrics Clés à Surveiller

1. **CPU Utilization** : Pourcentage d'utilisation des CUs
2. **Memory Consumption** : Utilisation mémoire par workload
3. **Query Duration** : Temps d'exécution des requêtes
4. **Throttling Events** : Événements de limitation

### Dashboard de Monitoring

```python
# Script Python pour collecter les métriques via API
import requests
import pandas as pd
from datetime import datetime, timedelta

def get_capacity_metrics(capacity_id, access_token):
    """Récupère les métriques de capacité sur 24h"""

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }

    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=24)

    url = f"https://api.powerbi.com/v1.0/myorg/capacities/{capacity_id}/Workloads"

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return pd.DataFrame(response.json()['value'])
    else:
        raise Exception(f"Error: {response.status_code}")

# Utilisation
# metrics_df = get_capacity_metrics("capacity-id", "token")
```

## Autoscaling et Optimisation

### Configuration Autoscale

L'autoscaling permet d'ajuster automatiquement les ressources :

```json
{
  "autoscaleSettings": {
    "enabled": true,
    "maxCapacityUnits": 16,
    "scalingSchedule": {
      "weekdays": {
        "startTime": "08:00",
        "endTime": "18:00",
        "timezone": "Europe/Paris"
      }
    }
  }
}
```

### Bonnes Pratiques d'Optimisation

1. **Séparation des workloads** : Dédier des capacités par type (Dev/Test/Prod)
2. **Scheduling intelligent** : Planifier les jobs lourds hors heures de pointe
3. **Monitoring proactif** : Alertes sur seuils critiques (>80% CPU)
4. **Right-sizing** : Ajuster la taille selon l'usage réel

## Gestion Multi-Capacités

```sql
-- Requête pour identifier la distribution des workspaces
SELECT
    capacity_name,
    COUNT(workspace_id) as workspace_count,
    SUM(storage_gb) as total_storage_gb,
    AVG(daily_queries) as avg_daily_queries
FROM fabric_admin.capacity_workspaces
GROUP BY capacity_name
ORDER BY total_storage_gb DESC;
```

## Points Clés

- Les F SKUs sont spécifiquement conçues pour Microsoft Fabric
- Le monitoring continu des CUs est crucial pour éviter le throttling
- L'autoscaling aide à optimiser les coûts tout en maintenant les performances
- Séparez les environnements (Dev/Test/Prod) sur des capacités distinctes
- Utilisez les APIs REST et PowerShell pour l'automatisation

---

**Navigation** : [Index](../README.md) | [Suivant : Tenant Settings](./02-tenant-settings.md)
