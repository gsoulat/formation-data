# Module 12 - Administration & Monitoring

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre le modèle de capacités F-SKU
- ✅ Gérer et optimiser les capacités
- ✅ Différencier Trial, Premium et Fabric capacity
- ✅ Monitorer Fabric efficacement
- ✅ Utiliser le Capacity Metrics App
- ✅ Optimiser les coûts
- ✅ Gérer le throttling et les pauses
- ✅ Intégrer avec Log Analytics

## Contenu du module

### [01 - Capacités F-SKU](./01-capacites-f-sku.md)
- Modèle de licensing Fabric
- F-SKUs disponibles :
  - F2, F4, F8, F16, F32, F64, F128, F256, F512, F1024, F2048
- Capacity Units (CU) par SKU
- Calcul des CU consumed
- Smoothing et bursting
- Regions disponibles
- Pricing par région

### [02 - Capacity Management](./02-capacity-management.md)
- Création d'une capacité
- Assignment de workspaces
- Scale up / scale down
- Auto-scale (preview)
- Capacity admins
- Suspension et reprise
- Multi-geo capacities
- Capacity pooling

### [03 - Trial vs Premium vs Capacity](./03-trial-vs-premium.md)
- **Fabric Trial** :
  - 60 jours gratuit
  - Capacité F64 équivalent
  - Limitations
  - Extension possible
- **Power BI Premium** :
  - P-SKUs (P1, P2, P3)
  - Compatibilité avec Fabric
  - Migration vers F-SKU
- **Fabric Capacity** :
  - Pay-as-you-go
  - Commitment vs consumption
  - Savings plan

### [04 - Monitoring Fabric](./04-monitoring-fabric.md)
- Monitoring Hub
- Activity monitoring
- Pipeline runs
- Notebook executions
- Dataflow refreshes
- Real-time monitoring
- Historical analysis
- Filtering et export

### [05 - Capacity Metrics App](./05-capacity-metrics-app.md)
- Installation et configuration
- Dashboards disponibles :
  - Overview
  - Capacity utilization
  - Item performance
  - Background operations
- Analyse des pics
- Identification des workloads gourmands
- Recommendations
- Drill-through details

### [06 - Cost Optimization](./06-cost-optimization.md)
- Stratégies de réduction des coûts :
  - Right-sizing des capacités
  - Auto-pause pour dev/test
  - Optimisation des workloads
  - Archivage des données anciennes
- FinOps pour Fabric
- Budgets et alertes
- Chargeback par workspace
- ROI analysis

### [07 - Throttling & Pauses](./07-throttling-pauses.md)
- Concept de throttling
- Interactive vs background operations
- Rejection vs delay
- Smoothing window (24h)
- Auto-pause behavior
- Handling throttling errors
- Best practices pour éviter
- Burst capacity

### [08 - Log Analytics Integration](./08-log-analytics-integration.md)
- Configuration de diagnostic logs
- Envoi vers Log Analytics
- Kusto queries pour analyse
- Dashboards personnalisés
- Alertes avancées
- Long-term retention
- Compliance auditing
- Integration avec Azure Monitor

## Exercices pratiques

### Exercice 1 : Création et gestion de capacité
1. Créer une capacité F2 (ou utiliser trial)
2. Assigner un workspace à la capacité
3. Explorer les paramètres de capacité
4. Tester la suspension/reprise

### Exercice 2 : Capacity Metrics App
1. Installer le Capacity Metrics App
2. Connecter à votre capacité
3. Explorer le dashboard Overview
4. Identifier le workload le plus consommateur
5. Analyser un pic d'utilisation

### Exercice 3 : Simulation de charge
1. Créer plusieurs notebooks/pipelines
2. Exécuter simultanément
3. Monitorer la consommation en temps réel
4. Observer le smoothing
5. Vérifier dans Capacity Metrics

### Exercice 4 : Optimisation des coûts
1. Analyser l'utilisation sur 7 jours
2. Identifier les heures creuses
3. Planifier les jobs batch hors heures de pointe
4. Mesurer les économies potentielles

### Exercice 5 : Log Analytics
1. Configurer diagnostic settings
2. Envoyer logs vers Log Analytics
3. Créer une requête KQL pour analyser les erreurs
4. Créer une alerte sur échec de pipeline
5. Visualiser dans un dashboard

### Exercice 6 : Gestion du throttling
1. Simuler une charge élevée
2. Observer le throttling
3. Analyser les rejections
4. Ajuster la planification des jobs
5. Vérifier l'amélioration

## Quiz

1. Qu'est-ce qu'un Capacity Unit (CU) ?
2. Quelle est la différence entre F64 et P1 ?
3. Expliquez le concept de smoothing sur 24h
4. Comment éviter le throttling ?
5. Quels sont les avantages du Capacity Metrics App ?

## Exemples de configuration

### Création de capacité (Azure CLI)

```bash
# Créer une capacité Fabric
az fabric capacity create \
  --resource-group myResourceGroup \
  --name myFabricCapacity \
  --location westeurope \
  --sku-name F64 \
  --admin-members user@company.com

# Lister les capacités
az fabric capacity list

# Mettre à l'échelle
az fabric capacity update \
  --resource-group myResourceGroup \
  --name myFabricCapacity \
  --sku-name F128

# Suspendre
az fabric capacity suspend \
  --resource-group myResourceGroup \
  --name myFabricCapacity

# Reprendre
az fabric capacity resume \
  --resource-group myResourceGroup \
  --name myFabricCapacity
```

### Diagnostic settings (ARM Template)

```json
{
  "type": "Microsoft.Insights/diagnosticSettings",
  "apiVersion": "2021-05-01-preview",
  "name": "FabricDiagnostics",
  "properties": {
    "workspaceId": "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}",
    "logs": [
      {
        "category": "PipelineRuns",
        "enabled": true
      },
      {
        "category": "NotebookExecutions",
        "enabled": true
      },
      {
        "category": "DataflowRefreshes",
        "enabled": true
      }
    ],
    "metrics": [
      {
        "category": "AllMetrics",
        "enabled": true
      }
    ]
  }
}
```

### Requêtes Log Analytics (KQL)

```kql
// Échecs de pipeline dans les dernières 24h
FabricPipelineRuns
| where TimeGenerated > ago(24h)
| where Status == "Failed"
| project TimeGenerated, PipelineName, ErrorMessage, Duration
| order by TimeGenerated desc

// Consommation CU par workspace
FabricMetrics
| where MetricName == "CapacityUnits"
| summarize TotalCU = sum(Value) by WorkspaceName
| order by TotalCU desc

// Top 10 des opérations les plus lentes
FabricActivityLog
| where Duration > 0
| top 10 by Duration desc
| project TimeGenerated, ActivityType, ItemName, Duration, User

// Throttling events
FabricCapacityEvents
| where EventType == "Throttled"
| summarize Count = count() by bin(TimeGenerated, 1h), WorkspaceName
| render timechart
```

### PowerShell - Gestion de capacité

```powershell
# Se connecter
Connect-AzAccount

# Créer une capacité
New-AzPowerBIEmbeddedCapacity `
  -ResourceGroupName "myRG" `
  -Name "myFabricCapacity" `
  -Location "West Europe" `
  -Sku "F64" `
  -Administrator "admin@company.com"

# Obtenir l'état
Get-AzPowerBIEmbeddedCapacity -Name "myFabricCapacity"

# Suspendre (économiser des coûts)
Suspend-AzPowerBIEmbeddedCapacity -Name "myFabricCapacity"

# Reprendre
Resume-AzPowerBIEmbeddedCapacity -Name "myFabricCapacity"
```

## Calcul de coûts

### Exemple de pricing (Europe Ouest, tarifs indicatifs)

| SKU | CU/heure | Prix/heure | Prix/mois (730h) |
|-----|----------|------------|-------------------|
| F2  | 2 | ~0.36€ | ~263€ |
| F4  | 4 | ~0.72€ | ~526€ |
| F8  | 8 | ~1.44€ | ~1,051€ |
| F16 | 16 | ~2.88€ | ~2,102€ |
| F32 | 32 | ~5.76€ | ~4,205€ |
| F64 | 64 | ~11.52€ | ~8,410€ |
| F128 | 128 | ~23.04€ | ~16,819€ |

### Estimation de coûts

```python
# Calculateur simple
def calculate_monthly_cost(sku, hours_per_day=24, days_per_month=30, price_per_cu_hour=0.18):
    """
    Calcule le coût mensuel d'une capacité Fabric

    Args:
        sku: Nombre de CU (2, 4, 8, 16, 32, 64, 128...)
        hours_per_day: Heures d'utilisation par jour
        days_per_month: Jours par mois
        price_per_cu_hour: Prix par CU par heure (varie selon région)
    """
    total_hours = hours_per_day * days_per_month
    total_cu_hours = sku * total_hours
    total_cost = total_cu_hours * price_per_cu_hour

    return {
        "sku": f"F{sku}",
        "total_hours": total_hours,
        "total_cu_hours": total_cu_hours,
        "total_cost_eur": round(total_cost, 2),
        "daily_cost_eur": round(total_cost / days_per_month, 2)
    }

# Exemple : F64, 12h/jour, 22 jours ouvrés
result = calculate_monthly_cost(sku=64, hours_per_day=12, days_per_month=22)
print(result)
# {'sku': 'F64', 'total_hours': 264, 'total_cu_hours': 16896, 'total_cost_eur': 3041.28, 'daily_cost_eur': 138.24}
```

## Best practices d'administration

### Gestion des capacités
- [ ] Utiliser des naming conventions claires
- [ ] Assigner des capacity admins
- [ ] Séparer dev/test/prod dans différentes capacités
- [ ] Activer auto-pause pour dev/test
- [ ] Documenter l'allocation des workspaces

### Monitoring
- [ ] Installer Capacity Metrics App
- [ ] Configurer Log Analytics
- [ ] Créer des alertes sur seuils (>80% CU)
- [ ] Revue hebdomadaire des métriques
- [ ] Dashboard de reporting pour management

### Coûts
- [ ] Établir des budgets par équipe/projet
- [ ] Implémenter chargeback
- [ ] Optimiser les schedules (off-peak hours)
- [ ] Utiliser auto-pause quand possible
- [ ] Revoir régulièrement le sizing

### Sécurité
- [ ] Principe du moindre privilège
- [ ] Audit logs activés
- [ ] Revue trimestrielle des accès
- [ ] Service principals pour automation
- [ ] MFA obligatoire pour admins

## Ressources complémentaires

### Documentation officielle
- [Fabric capacities](https://learn.microsoft.com/fabric/enterprise/licenses)
- [Capacity metrics app](https://learn.microsoft.com/fabric/enterprise/metrics-app)
- [Throttling in Fabric](https://learn.microsoft.com/fabric/enterprise/throttling)

### Pricing
- [Fabric pricing calculator](https://azure.microsoft.com/pricing/calculator/)
- [Fabric pricing page](https://azure.microsoft.com/pricing/details/microsoft-fabric/)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 3-4 heures
- **Total** : 7-9 heures

## Prochaine étape

➡️ [Module 13 - DevOps & CI/CD](../13-DevOps-CI-CD/)

---

[⬅️ Module précédent](../11-Optimisation-Performance/) | [⬅️ Retour au sommaire](../README.md)
