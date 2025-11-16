# Concepts Lakehouse

## Qu'est-ce qu'un Lakehouse ?

Le **Lakehouse** est une architecture de données qui combine les avantages du **Data Lake** et du **Data Warehouse**.

```
Data Lake          Data Warehouse        Lakehouse
───────────────    ─────────────────    ──────────────────
Storage: Cheap     Storage: Expensive   Storage: Cheap
Format: Raw        Format: Structured   Format: Structured
Schema: On-read    Schema: On-write     Schema: Enforced
ACID: ❌           ACID: ✅             ACID: ✅
Performance: Slow  Performance: Fast    Performance: Fast
Cost: Low          Cost: High           Cost: Medium
ML Support: ✅     ML Support: ❌       ML Support: ✅
```

## Architecture Lakehouse

```
┌──────────────────────────────────────────┐
│           Applications                    │
│  (BI, ML, Analytics, Data Science)       │
└──────────────────┬───────────────────────┘
                   │
┌──────────────────▼───────────────────────┐
│         Transaction Layer                 │
│        (Delta Lake / Hudi)                │
│  • ACID Transactions                      │
│  • Time Travel                            │
│  • Schema Enforcement                     │
└──────────────────┬───────────────────────┘
                   │
┌──────────────────▼───────────────────────┐
│         Storage Layer                     │
│        (Parquet files)                    │
│     Object Storage (S3, ADLS, OneLake)   │
└──────────────────────────────────────────┘
```

## Évolution : Data Lake → Lakehouse

### Problèmes du Data Lake Traditionnel

❌ **Pas de transactions ACID**
```
Writer A et Writer B modifient simultanément
→ Corruption potentielle des données
```

❌ **Pas de schema enforcement**
```
Jour 1: {id: int, name: string}
Jour 2: {id: string, name: int}  # Oops!
→ Problèmes à la lecture
```

❌ **Performance de lecture médiocre**
```
Requêtes SQL lentes sur fichiers Parquet bruts
Pas d'indexes, statistiques limitées
```

❌ **Gestion difficile des updates/deletes**
```
Update = Read all → Modify → Write all
Très coûteux sur TB de données
```

### Solution : Lakehouse (Delta Lake)

✅ **ACID Transactions**
```
Transaction log garantit la cohérence
Concurrent reads/writes sans corruption
```

✅ **Schema Enforcement & Evolution**
```
Schéma défini et validé
Evolution contrôlée du schéma
```

✅ **Performance optimisée**
```
Statistiques intégrées
Data skipping
Z-Ordering
V-Order (Fabric)
```

✅ **Updates/Deletes efficaces**
```
MERGE, UPDATE, DELETE natifs
Optimisés pour performance
```

## Lakehouse vs Data Lake vs Data Warehouse

### Comparaison Détaillée

| Caractéristique | Data Lake | Data Warehouse | Lakehouse |
|----------------|-----------|----------------|-----------|
| **Format données** | Raw (CSV, JSON, Parquet) | Structured (Tables) | Structured (Delta) |
| **Schema** | Schema-on-read | Schema-on-write | Schema-enforced |
| **ACID** | ❌ | ✅ | ✅ |
| **Coût storage** | Très bas | Élevé | Bas |
| **Performance requêtes** | Lent | Très rapide | Rapide |
| **ML/Data Science** | ✅ | ❌ (export requis) | ✅ |
| **Streaming** | ✅ | ⚠️ (limité) | ✅ |
| **Updates/Deletes** | Difficile | Facile | Facile |
| **Scalabilité** | Excellente | Bonne | Excellente |
| **Cas d'usage** | Exploration, ML | BI, Reporting | Tout! |

### Quand Utiliser Quoi ?

**Data Lake (ADLS Gen2 simple) :**
- Archivage long terme
- Données ultra-brutes (logs, dumps)
- Coût minimal prioritaire

**Data Warehouse :**
- Requêtes SQL complexes haute performance
- Reporting temps réel critique
- Modélisation dimensionnelle stricte

**Lakehouse (Recommandé dans Fabric) :**
- Use case général moderne
- BI + ML + Analytics
- Flexibilité + Performance

## Lakehouse dans Microsoft Fabric

### Architecture Fabric Lakehouse

```
┌────────────────────────────────────────┐
│        Fabric Lakehouse                │
├────────────────────────────────────────┤
│  Files/                                │
│    ├─ bronze/                          │
│    ├─ silver/                          │
│    └─ gold/                            │
├────────────────────────────────────────┤
│  Tables/ (Delta Lake)                  │
│    ├─ customers                        │
│    ├─ orders                           │
│    └─ products                         │
├────────────────────────────────────────┤
│  SQL Analytics Endpoint (auto)         │
│    └─ T-SQL queries on Delta tables    │
└────────────────────────────────────────┘
           ↓
    ┌──────────────┐
    │   OneLake    │
    └──────────────┘
```

### Composants d'un Lakehouse Fabric

**1. Files Section**
- Stockage fichiers non-structurés
- Formats : CSV, JSON, Parquet, images, vidéos, etc.
- Organisation libre
- Idéal pour Bronze layer

**2. Tables Section**
- Tables Delta Lake managed
- Format optimisé (Parquet + transaction log)
- ACID guaranteed
- Requêtables via SQL/Spark

**3. SQL Analytics Endpoint**
- Créé automatiquement
- Requêtes T-SQL sur tables Delta
- Read-only
- Connexion via SSMS, Azure Data Studio, Power BI

### Avantages Spécifiques à Fabric

✅ **OneLake Integration**
- Un seul lac de données pour tout le tenant
- Pas de duplication
- Shortcuts pour virtualisation

✅ **V-Order Optimization**
- Compression columnaire propriétaire
- ~50% meilleur que Parquet standard
- Lecture 2x plus rapide (Direct Lake)

✅ **Direct Lake Mode (Power BI)**
- Power BI lit directement depuis OneLake
- Pas de copie des données
- Performance Import + fraîcheur DirectQuery

✅ **Unified Experience**
- UI intégrée pour Files + Tables
- Notebooks, Pipelines dans même workspace
- Collaboration simplifiée

## Cas d'Usage Lakehouse

### 1. Architecture Medallion

```
Bronze Lakehouse          Silver Lakehouse       Gold Lakehouse
(Raw Data)                (Clean Data)           (Business Data)
     ↓                         ↓                       ↓
Files: sources brutes    Tables: validated      Tables: aggregated
Format: original         Format: Delta          Format: Delta
Quality: aucune          Quality: high          Quality: highest
Schema: variable         Schema: enforced       Schema: business
```

**Exemple concret :**
```
Bronze: raw_sales_csv/
  ├─ 2024-01-01.csv
  ├─ 2024-01-02.csv
  └─ ...

Silver: sales_cleaned (Delta table)
  └─ Deduplicated, validated, standardized

Gold: sales_by_region_monthly (Delta table)
  └─ Aggregated for reporting
```

### 2. ML Feature Store

```
Lakehouse: ML_Features
  ├─ Tables/
  │   ├─ customer_features (RFM, demographics)
  │   ├─ product_features (category, price_tier)
  │   └─ historical_features (time-series)
  └─ Models can directly read for training
```

### 3. Data Science Workspace

```
Lakehouse: Research
  ├─ Files/
  │   ├─ raw_datasets/
  │   ├─ notebooks/
  │   └─ experiments/
  └─ Tables/
      ├─ cleaned_data
      ├─ experiment_results
      └─ final_predictions
```

### 4. Streaming + Batch Hybrid

```
EventStream → Lakehouse Tables (micro-batches)
              ↓
         Delta tables updated en continu
              ↓
         Power BI Direct Lake (near real-time dashboards)
```

## Architecture Patterns

### Pattern 1 : Single Lakehouse (Small Projects)

```
MyLakehouse/
  ├─ Files/
  │   ├─ raw/
  │   ├─ staging/
  │   └─ archive/
  └─ Tables/
      ├─ bronze_*
      ├─ silver_*
      └─ gold_*
```

**Pros :** Simple, un seul endroit
**Cons :** Peut devenir désordonné

### Pattern 2 : Multi-Lakehouse (Medallion)

```
├─ Lakehouse_Bronze/
│   └─ Tables: raw data
├─ Lakehouse_Silver/
│   └─ Tables: cleaned data
└─ Lakehouse_Gold/
    └─ Tables: business aggregates
```

**Pros :** Séparation claire, sécurité granulaire
**Cons :** Plus complexe à gérer

### Pattern 3 : Domain-Driven

```
├─ Lakehouse_Sales/
├─ Lakehouse_Marketing/
├─ Lakehouse_Finance/
└─ Lakehouse_Shared/
    └─ Shortcuts vers données communes
```

**Pros :** Ownership clair, scaling par domaine
**Cons :** Duplication potentielle

## Best Practices

### Organisation des Données

✅ **DO:**
```
Files/
  ├─ bronze/
  │   └─ source_name/
  │       └─ YYYY/MM/DD/
  ├─ silver/
  └─ gold/

Tables/
  ├─ bronze_*
  ├─ silver_*
  └─ gold_*
```

❌ **DON'T:**
```
Files/
  ├─ data/
  ├─ stuff/
  ├─ old_files/
  └─ temp/
```

### Naming Conventions

✅ **Tables:**
```
{layer}_{domain}_{entity}

Examples:
  bronze_sales_transactions
  silver_crm_customers
  gold_analytics_monthly_revenue
```

✅ **Columns:**
```
snake_case
Descriptive names
Consistent across tables

Examples:
  customer_id
  order_date
  total_amount_usd
```

### Partitionnement

✅ **DO:**
```python
# Partitionner grandes tables (>1GB) par date
df.write.format("delta") \
    .partitionBy("year", "month") \
    .save("Tables/large_table")
```

❌ **DON'T:**
```python
# Over-partitioning
.partitionBy("year", "month", "day", "hour")  # Too many partitions!
```

## Points Clés

- Lakehouse = Data Lake + Data Warehouse (meilleur des deux)
- Delta Lake apporte ACID, schema, performance
- Fabric Lakehouse = Delta + OneLake + V-Order
- Architecture Medallion (Bronze/Silver/Gold) recommandée
- SQL Analytics Endpoint automatique pour requêtes T-SQL
- Direct Lake révolutionne le BI (Power BI)

---

**Prochain fichier :** [02 - Delta Lake et Tables](./02-delta-lake-tables.md)

[⬅️ Retour au README du module](./README.md)
