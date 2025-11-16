# Licences, SKU et Pricing

## Modèle de Licensing Fabric

Microsoft Fabric utilise un modèle de licensing **basé sur la capacité** (capacity-based licensing), différent du modèle traditionnel par utilisateur.

```
Modèle Traditionnel (Power BI Pro/Premium Per User):
  └─ Licence par utilisateur ($/user/mois)

Modèle Fabric:
  └─ Capacité partagée ($/CU/heure) + licenses utilisateurs
```

---

## Les Trois Composantes du Licensing

### 1. Fabric Capacity (F-SKUs) 💰

**C'est la partie principale du coût.**

La capacité Fabric fournit les ressources compute pour tous les workloads.

### 2. Power BI Licenses (Pour consommateurs de rapports)

Les utilisateurs qui **consomment** des rapports Power BI ont besoin d'une licence:

**Options :**
- **Power BI Free** : Peut voir rapports dans workspace Fabric capacity ✅
- **Power BI Pro** : Peut collaborer, partager
- **Power BI Premium Per User (PPU)** : Toutes fonctionnalités BI

**Important :** Avec Fabric capacity, même les utilisateurs Free peuvent consulter des rapports !

### 3. Azure Subscription

Fabric capacity est facturée sur votre abonnement Azure.

---

## F-SKUs Détaillés

### Table Complète des SKUs

| SKU | CU/h | v-Cores | RAM | Backend Cores | Prix €/h* | Prix €/mois* |
|-----|------|---------|-----|---------------|-----------|--------------|
| **F2** | 2 | 2 | 16 GB | 1 | 0.36 | 263 |
| **F4** | 4 | 4 | 32 GB | 2 | 0.72 | 526 |
| **F8** | 8 | 8 | 64 GB | 4 | 1.44 | 1,051 |
| **F16** | 16 | 16 | 128 GB | 8 | 2.88 | 2,102 |
| **F32** | 32 | 32 | 256 GB | 16 | 5.76 | 4,205 |
| **F64** | 64 | 64 | 512 GB | 32 | 11.52 | 8,410 |
| **F128** | 128 | 128 | 1 TB | 64 | 23.04 | 16,819 |
| **F256** | 256 | 256 | 2 TB | 128 | 46.08 | 33,638 |
| **F512** | 512 | 512 | 4 TB | 256 | 92.16 | 67,277 |
| **F1024** | 1024 | 1024 | 8 TB | 512 | 184.32 | 134,554 |
| **F2048** | 2048 | 2048 | 16 TB | 1024 | 368.64 | 269,107 |

*Prix Europe Ouest, Novembre 2024 (indicatifs, vérifier sur Azure Pricing)

### Équivalences avec Power BI Premium

| Fabric SKU | CU | ≈ Power BI Premium |
|------------|----|--------------------|
| F64 | 64 | P1 (8 v-cores) |
| F128 | 128 | P2 (16 v-cores) |
| F256 | 256 | P3 (32 v-cores) |
| F512 | 512 | P4 (64 v-cores) |
| F1024 | 1024 | P5 (128 v-cores) |

**Note :** F-SKUs apportent plus de fonctionnalités que P-SKUs (Data Engineering, Data Science, etc.)

---

## Capacity Units (CU) Expliqués

### Qu'est-ce qu'un CU ?

Un **Capacity Unit** est une unité de mesure de compute dans Fabric.

**Analogie :** CU = "crédits de calcul"

### Consommation par Type d'Opération

Différentes opérations consomment différemment :

| Opération | Consommation Type | CU/heure (indicatif) |
|-----------|-------------------|----------------------|
| **Spark notebook** (compute-heavy) | Élevée | 10-50 CU |
| **Pipeline Copy activity** | Moyenne | 2-10 CU |
| **Dataflow Gen2 refresh** | Moyenne | 5-15 CU |
| **Power BI semantic model refresh** | Variable | 2-20 CU |
| **Power BI report query** | Faible | 0.1-1 CU |
| **Warehouse query** (simple) | Faible | 0.5-2 CU |
| **KQL query** | Très faible | 0.1-0.5 CU |

### Formule de Calcul

```
CU consommés = Base Operation Cost × Complexity Factor × Data Volume Factor

Example:
  Spark job processing 1 TB data, complex transformations
  = 10 CU (base) × 3 (complexity) × 5 (volume)
  = 150 CU pour 1 heure
```

### Smoothing (Lissage 24h)

**Concept clé :** Fabric lisse la consommation sur 24h.

**Exemple pratique :**

```
Capacity: F64 (64 CU/heure)
Budget quotidien: 64 × 24 = 1,536 CU

Jour 1:
  00:00-08:00 : 5 CU/h  → 40 CU
  08:00-09:00 : 200 CU  → 200 CU (BURST!)
  09:00-12:00 : 20 CU/h → 60 CU
  12:00-24:00 : 10 CU/h → 120 CU

Total jour: 420 CU
Moyenne lissée: 420/24 = 17.5 CU/heure
Résultat: OK (< 64 CU/h) ✅

Jour 2 (mauvais):
  Constamment 80 CU/h pendant 24h
  Total: 1,920 CU
  Moyenne: 80 CU/h
  Résultat: DÉPASSEMENT ❌ → Throttling
```

**Avantage :** Permet des pics temporaires sans throttling.

---

## Pricing Détaillé

### Prix par Région (Exemples)

| Région | F64 €/h | F64 €/mois* | F128 €/h | F128 €/mois* |
|--------|---------|-------------|----------|--------------|
| **West Europe** | 11.52 | 8,410 | 23.04 | 16,819 |
| **North Europe** | 11.52 | 8,410 | 23.04 | 16,819 |
| **East US** | $13.00 | $9,490 | $26.00 | $18,980 |
| **West US** | $13.00 | $9,490 | $26.00 | $18,980 |
| **Southeast Asia** | $14.30 | $10,439 | $28.60 | $20,878 |

*Prix indicatifs pour 730 heures/mois

### Coûts Additionnels

**Inclus dans F-SKU :**
- ✅ Compute (Spark, SQL, Dataflows)
- ✅ OneLake storage (jusqu'à seuil)
- ✅ Data integration
- ✅ Tous les workloads Fabric

**Facturé séparément :**
- ❌ OneLake storage au-delà du quota (€0.023/GB/mois)
- ❌ Shortcuts vers S3 (data transfer)
- ❌ Egress data (sortie vers internet)
- ❌ Azure services externes (Event Hub, etc.)

### OneLake Storage Pricing

**Stockage OneLake inclus dans capacity :**
- Quota de base inclus
- Au-delà : ~€0.023/GB/mois

**Optimisations storage :**
- V-Order compression (↓ 50% size)
- Delta Lake (compression native)
- VACUUM old versions
- Archive old data

---

## Fabric Trial (Gratuit)

### Caractéristiques du Trial

```
Durée: 60 jours
Capacité: Équivalent F64
Limitations:
  - 1 workspace par utilisateur
  - Pas pour production
  - Limited storage
Extension: Possible (1 fois pour 60 jours supplémentaires)
```

### Activer le Trial

**Étapes :**
1. Se connecter à https://app.fabric.microsoft.com
2. Cliquer sur l'icône utilisateur → "Start trial"
3. Accepter les termes
4. Trial activé ✅

**Après 60 jours :**
- Workspace devient read-only
- 30 jours pour migrer vers capacité payante
- Sinon, données conservées 90 jours puis supprimées

### Trial → Production Migration

```
1. Acheter Fabric capacity (F-SKU) dans Azure Portal
2. Dans Fabric: Workspace Settings → License
3. Changer de "Trial" vers "Fabric capacity"
4. Sélectionner votre capacité payante
5. Save → Migration immédiate ✅
```

---

## Sizing de Capacité

### Méthode de Sizing

**Étape 1 : Estimer les workloads**

```
Example organisation:
- 50 utilisateurs Power BI
- 10 data engineers (Spark jobs)
- 20 pipelines quotidiens
- 5 semantic models (refresh 2×/jour)
- 100 GB de données
```

**Étape 2 : Calculer CU nécessaires**

```
Power BI:
  - 50 users × 20 queries/jour × 0.2 CU = 200 CU/jour

Spark jobs:
  - 5 jobs/jour × 2h × 20 CU/h = 200 CU/jour

Pipelines:
  - 20 pipelines × 0.5h × 5 CU/h = 50 CU/jour

Semantic model refreshes:
  - 5 models × 2 refreshes × 10 CU = 100 CU/jour

Total: 550 CU/jour
Lissé: 550/24 = 23 CU/heure
Recommandation: F32 (32 CU/h) avec marge ✅
```

**Étape 3 : Ajouter marge de sécurité**

```
Règle: +30-50% pour pics imprévus

23 CU/h × 1.4 = 32.2 CU/h
Capacité recommandée: F32 ou F64 (pour confort)
```

### Sizing par Use Case

| Use Case | Users | Workload | Recommandation |
|----------|-------|----------|----------------|
| **Small Team** | <20 | Reporting BI basique | F8-F16 |
| **Department** | 50-100 | BI + light ETL | F32-F64 |
| **Mid-size** | 200-500 | BI + Data Engineering | F64-F128 |
| **Enterprise** | 1000+ | Full platform | F256+ |
| **ML Heavy** | Any | Intensive Spark/ML | F128+ (GPU) |

---

## Optimisation des Coûts

### Stratégies d'Optimisation

#### 1. Auto-Pause (Dev/Test)

```
Development capacity F16:
  - Active 8h/jour (9h-17h)
  - Pause le reste

Économie:
  Sans pause: 730h × €2.88/h = €2,102/mois
  Avec pause: 160h × €2.88/h = €461/mois

Économie: 78% 💰
```

**Configuration :**
```
Azure Portal → Fabric Capacity → Settings
  └─ Auto-pause: Activé
  └─ After: 15 minutes inactivity
```

#### 2. Right-Sizing

```
Scenario: F64 utilisé à 30% en moyenne

Solution:
  - Downgrade à F32
  - Économie: 50% (€4,205/mois)
```

**Monitoring :**
- Capacity Metrics App
- Azure Cost Management
- Alertes sur utilisation

#### 3. Scheduling Off-Peak

```
Batch jobs lourds:
  - Avant: Exécutés durant heures de bureau
  - Après: Schedulés la nuit (moins de concurrence)

Impact:
  - Pics réduits
  - Peut permettre downgrade de capacité
```

#### 4. Optimisation Workloads

```
Example Spark job:
  Before: 4h × 50 CU/h = 200 CU
  After optimization:
    - V-Order: -30% data to process
    - Partitioning: -40% scan time
    - Result: 1.5h × 30 CU/h = 45 CU

Économie: 77% sur ce job
```

### FinOps pour Fabric

**Mise en place :**

```
1. Tagging des workspaces:
   - Department
   - Project
   - Environment (dev/prod)

2. Chargeback par équipe:
   - Capacity Metrics App → par workspace
   - Rapporter consommation aux équipes

3. Budgets et alertes:
   - Budget €10,000/mois
   - Alerte à 80% (€8,000)
   - Action si dépassement

4. Revues mensuelles:
   - Top consumers
   - Optimisation opportunités
   - Rightsizing
```

---

## Comparaisons de Coûts

### Fabric vs Azure Synapse Analytics

| Composant | Synapse Dedicated | Fabric Equivalent | Comparaison |
|-----------|-------------------|-------------------|-------------|
| **DW Small** | DW100c (~€1,100/m) | F16 (~€2,100/m) | Synapse moins cher |
| **DW Medium** | DW500c (~€5,500/m) | F64 (~€8,400/m) | Synapse moins cher |
| **+ Spark** | + €500-2,000/m | Inclus | Fabric avantageux |
| **+ Data Factory** | + €300-1,000/m | Inclus | Fabric avantageux |
| **+ Power BI Premium** | + €4,995/m | Inclus | Fabric avantageux |
| **TOTAL Full Stack** | ~€10,000-15,000/m | ~€8,400/m (F64) | **Fabric gagnant** |

### Fabric vs Databricks

| Feature | Databricks (AWS) | Fabric F64 | Comparaison |
|---------|------------------|------------|-------------|
| **Compute** | ~$0.55/DBU | Inclus | Fabric |
| **Storage** | S3 separate | OneLake inclus | Fabric |
| **BI** | Externe (Tableau) | Power BI inclus | Fabric |
| **Integration** | Airbyte/Fivetran | Data Factory inclus | Fabric |
| **MLflow** | Inclus | Inclus | Égalité |
| **TOTAL** | ~$12,000/m | ~€8,400/m | **Fabric moins cher** |

*(Pour workload équivalent)*

---

## Calculateur de Coût

### Template Excel/Tool

```python
# Calculateur Python simple

def calculate_fabric_cost(
    sku_cu_per_hour,
    hours_per_day=24,
    days_per_month=30,
    price_per_cu_hour=0.18  # Europe
):
    """
    SKU: 2, 4, 8, 16, 32, 64, 128, 256, 512
    """
    total_hours = hours_per_day * days_per_month
    total_cu_hours = sku_cu_per_hour * total_hours
    monthly_cost = total_cu_hours * price_per_cu_hour

    return {
        "SKU": f"F{sku_cu_per_hour}",
        "Hours": total_hours,
        "CU-Hours": total_cu_hours,
        "Monthly Cost (€)": round(monthly_cost, 2),
        "Daily Cost (€)": round(monthly_cost/days_per_month, 2)
    }

# Examples
print(calculate_fabric_cost(64))  # F64, 24/7
# {'SKU': 'F64', 'Hours': 720, 'CU-Hours': 46080, 'Monthly Cost (€)': 8294.4, 'Daily Cost (€)': 276.48}

print(calculate_fabric_cost(16, hours_per_day=12))  # F16, 12h/jour
# {'SKU': 'F16', 'Hours': 360, 'CU-Hours': 5760, 'Monthly Cost (€)': 1036.8, 'Daily Cost (€)': 34.56}
```

---

## Best Practices Licensing

✅ **DO:**
- Commencer avec Trial pour POC
- Right-size selon workload réel
- Auto-pause pour dev/test
- Monitor avec Capacity Metrics App
- Utiliser tagging pour chargeback

❌ **DON'T:**
- Over-provision "just in case"
- Ignorer les métriques d'utilisation
- Mélanger prod et dev sur même capacity
- Oublier d'optimiser les workloads

---

## Points Clés à Retenir

- Fabric utilise un modèle capacity-based (F-SKUs)
- Capacity Units (CU) mesurent la consommation
- Smoothing sur 24h permet des pics
- F64 minimum recommandé pour production
- Trial gratuit 60 jours (équivalent F64)
- OneLake storage inclus (avec quota)
- Optimisation possible : auto-pause, right-sizing, scheduling

---

**Fin du Module 01 !** 🎉

[⬅️ Fichier précédent](./04-workspaces-capacites.md) | [➡️ Module suivant : Lakehouse](../../02-Lakehouse/) | [⬅️ Retour au README du module](./README.md)
