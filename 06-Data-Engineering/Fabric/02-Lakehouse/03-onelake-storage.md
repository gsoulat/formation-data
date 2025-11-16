# OneLake Storage

## Organisation du Stockage

### Structure Hiérarchique

```
Tenant (Organization)
└── OneLake
    └── Workspace: Sales-Analytics
        └── Lakehouse: SalesData
            ├── Files/
            │   ├── bronze/
            │   ├── silver/
            │   └── gold/
            └── Tables/
                ├── customers/
                │   ├── _delta_log/
                │   └── *.parquet
                └── orders/
```

### Dossiers Files vs Tables

**Files/** : Données non-structurées
- Tout type de fichier (CSV, JSON, Parquet, images, etc.)
- Organisation libre
- Pas de transaction log
- Schema-on-read

**Tables/** : Tables Delta Lake
- Format Delta uniquement
- Transaction log automatique
- ACID transactions
- Schema enforced

## Formats Supportés

### Dans Files/

```python
# CSV
df = spark.read.csv("Files/data.csv", header=True)

# JSON
df = spark.read.json("Files/data.json")

# Parquet
df = spark.read.parquet("Files/data.parquet")

# Delta
df = spark.read.format("delta").load("Files/delta_table")

# Images, vidéos, binaires
# Stockables mais non-requêtables directement
```

### Dans Tables/

```python
# Uniquement Delta Lake
df = spark.read.format("delta").load("Tables/my_table")
df = spark.table("my_table")
```

## Accès au Stockage

### 1. Via Fabric UI

```
Workspace → Lakehouse → Files ou Tables
  └─ Browse, upload, download
  └─ Preview data
  └─ Properties
```

### 2. Via Notebooks

```python
# Lakehouse attaché au notebook
# Accès direct

# Lire
df = spark.read.csv("Files/data.csv")

# Écrire
df.write.mode("overwrite").csv("Files/output.csv")
```

### 3. Via ADLS Gen2 API

OneLake expose une API compatible ADLS Gen2 :

```python
# URL OneLake
onelake_path = "abfss://workspace@onelake.dfs.fabric.microsoft.com/Lakehouse/Files/data.csv"

df = spark.read.csv(onelake_path)
```

### 4. Via Azure Storage Explorer

```
1. Ouvrir Azure Storage Explorer
2. Connecter: Attach à OneLake
3. URL: https://onelake.dfs.fabric.microsoft.com
4. Auth: Azure AD
5. Browse workspaces/lakehouses
```

### 5. Via OneLake File Explorer (Windows)

```
Windows Explorer integration
  └─ OneLake apparaît comme un drive
  └─ Drag & drop files
```

## Sécurité et Permissions

### Niveaux de Sécurité

```
1. Workspace Level
   └─ Admin, Member, Contributor, Viewer

2. Item Level (Lakehouse)
   └─ Share permissions

3. Folder/File Level
   └─ Via shortcuts ou external tables

4. Row/Column Level
   └─ RLS dans semantic models
```

### Permissions Files vs Tables

**Files/** :
- Contrôle au niveau Lakehouse
- Tous les membres peuvent lire/écrire (selon rôle workspace)

**Tables/** :
- Mêmes permissions que Files
- + RLS via SQL Analytics Endpoint
- + CLS via views

## OneLake Path Formats

### Chemin Relatif (dans notebook)

```python
# Si notebook attaché au Lakehouse
df = spark.read.csv("Files/data.csv")
df = spark.table("my_table")
```

### Chemin Absolu OneLake

```python
# Format ABFS
path = "abfss://{workspace}@onelake.dfs.fabric.microsoft.com/{lakehouse}/Files/data.csv"

# Example
path = "abfss://SalesAnalytics@onelake.dfs.fabric.microsoft.com/SalesLH/Files/bronze/sales.csv"
```

### Chemin HTTP

```python
# Pour download via API
url = "https://onelake.dfs.fabric.microsoft.com/{workspace}/{lakehouse}/Files/data.csv"
```

## Gestion du Stockage

### Quotas et Limites

**Inclus dans Capacity :**
- Stockage de base inclus
- Dépend du SKU de capacité

**Au-delà du quota :**
- Facturation : ~€0.023/GB/mois
- Monitorer via Capacity Metrics

### Optimisation du Stockage

#### 1. Compression

```python
# Parquet avec compression
df.write.mode("overwrite") \
    .option("compression", "snappy") \
    .parquet("Files/data.parquet")

# Delta (compression par défaut)
df.write.format("delta").save("Tables/data")
```

#### 2. V-Order

```python
# Activation V-Order (automatic dans Fabric)
spark.sql("OPTIMIZE my_table")

# V-Order compresse ~50% mieux que Parquet standard
```

#### 3. Partitionnement

```python
# Évite de stocker tout dans un seul fichier
df.write.format("delta") \
    .partitionBy("year", "month") \
    .save("Tables/partitioned_data")
```

#### 4. VACUUM

```python
# Nettoyer anciennes versions
spark.sql("VACUUM my_table RETAIN 168 HOURS")  # 7 jours

# Libère espace storage
```

### Monitoring Storage

```python
# Taille d'une table
spark.sql("DESCRIBE DETAIL my_table").select("sizeInBytes").show()

# Nombre de fichiers
spark.sql("DESCRIBE DETAIL my_table").select("numFiles").show()
```

## OneLake vs ADLS Gen2

### Similarités

- API compatible ADLS Gen2
- Format de stockage identique (blob)
- Hiérarchique (folders/files)
- Security Azure AD

### Différences

| Feature | ADLS Gen2 | OneLake |
|---------|-----------|---------|
| **Scope** | Par storage account | Tout le tenant |
| **Unification** | Silotté | Unifié |
| **Compute** | Externe | Intégré (Spark, SQL) |
| **Format natif** | Tout format | Delta Lake optimisé |
| **Data duplication** | Oui (entre services) | Non (shortcuts) |
| **Pricing** | Storage + transactions | Inclus dans capacity |

## Scenarios d'Utilisation

### Scenario 1 : Ingestion de Fichiers Bruts

```
Source (Azure Blob) → Pipeline Copy → Lakehouse Files/bronze/
                                              ↓
                                      Notebook lit et convertit
                                              ↓
                                      Tables/bronze_table (Delta)
```

### Scenario 2 : Architecture Medallion

```
Files/bronze/          Files/silver/         Files/gold/
  ├─ raw CSVs    →        ├─ cleaned     →      ├─ aggregated
  └─ raw JSONs           └─ validated          └─ business logic

Tables/bronze_*    →   Tables/silver_*    →   Tables/gold_*
```

### Scenario 3 : Mixed Workload

```
Tables/ (Delta)
  ├─ transactional_data  ← High update rate
  └─ analytics_data      ← Append-only

Files/
  ├─ images/             ← Binary files
  ├─ documents/          ← PDFs, docs
  └─ archives/           ← Historical data
```

## Integration avec Autres Services

### Power BI Direct Lake

```
OneLake Tables (Delta) → Power BI lit directement
                         Pas de copie
                         Performance optimale
```

### Azure Synapse (via shortcuts)

```
Synapse Analytics → Shortcut vers OneLake
                    Requête Delta tables
                    Pas de duplication
```

### External Tools

```
Python/PySpark local → Authenticate à OneLake
                       Read/Write via ADLS API
```

## Best Practices

### Organisation

✅ **DO:**
```
Files/
  ├─ bronze/source_name/YYYY/MM/DD/
  ├─ silver/domain/
  └─ gold/use_case/

Tables/
  ├─ bronze_*
  ├─ silver_*
  └─ gold_*
```

❌ **DON'T:**
```
Files/
  ├─ data/
  ├─ temp/
  ├─ old_stuff/
  └─ misc/
```

### Nommage

✅ **Conventions:**
- Lowercase avec underscores
- Préfixe layer (bronze_, silver_, gold_)
- Nom descriptif
- Pas de caractères spéciaux

### Sécurité

✅ **DO:**
- Utiliser workspace roles
- Principe du moindre privilège
- Documenter les accès
- Audit régulier

## Points Clés

- OneLake = stockage unifié pour tout Fabric
- Files/ pour non-structuré, Tables/ pour Delta
- API compatible ADLS Gen2
- V-Order compression automatique
- Shortcuts pour virtualisation
- Monitoring storage important pour coûts

---

**Prochain fichier :** [04 - Shortcuts](./04-shortcuts.md)

[⬅️ Fichier précédent](./02-delta-lake-tables.md) | [⬅️ Retour au README du module](./README.md)
