# Module 14 - Migration & Intégration

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Planifier une migration depuis Azure Synapse vers Fabric
- ✅ Concevoir des architectures hybrides
- ✅ Implémenter des patterns d'intégration de données
- ✅ Connecter des sources de données externes
- ✅ Gérer des scénarios multi-cloud

## Contenu du module

### [01 - Migration depuis Azure Synapse](./01-migration-azure-synapse.md)
- Synapse vs Fabric : différences architecturales
- Stratégies de migration :
  - Big bang
  - Phased approach
  - Parallel run
- Migration des composants :
  - Dedicated SQL Pools → Data Warehouse
  - Spark Pools → Fabric Spark
  - Pipelines → Data Pipelines
  - Notebooks → Fabric Notebooks
- Data migration (ADLS Gen2 → OneLake)
- Coût et ROI
- Timeline typique

### [02 - Architectures Hybrides](./02-hybrid-architectures.md)
- Patterns hybrides Synapse + Fabric
- Coexistence temporaire
- Shared data layer (OneLake shortcuts)
- Workload distribution
- Network topology
- Security considerations
- Governance across platforms

### [03 - Patterns d'Intégration de Données](./03-data-integration-patterns.md)
- **ETL patterns** :
  - Batch ETL
  - Micro-batch
  - Streaming
  - CDC (Change Data Capture)
- **Data synchronization** :
  - One-way sync
  - Bi-directional sync
  - Real-time vs scheduled
- **Data federation** :
  - Shortcuts
  - External tables
  - Virtual views

### [04 - Sources de Données Externes](./04-external-data-sources.md)
- Connecteurs supportés (100+)
- **Bases de données** :
  - SQL Server, PostgreSQL, MySQL, Oracle
  - Azure SQL, Cosmos DB
  - Snowflake, Databricks
- **Cloud storage** :
  - Azure Blob, ADLS Gen2
  - AWS S3
  - Google Cloud Storage
- **SaaS** :
  - Salesforce, Dynamics 365
  - SAP, ServiceNow
- **APIs et Web services**
- Configuration et authentification

### [05 - Scénarios Multi-Cloud](./05-multi-cloud-scenarios.md)
- Fabric + AWS
- Fabric + Google Cloud Platform
- Data residency et compliance
- Network connectivity (ExpressRoute, VPN)
- Security (encryption in transit)
- Cost optimization multi-cloud
- Disaster recovery cross-cloud

## Exercices pratiques

### Exercice 1 : Migration assessment
1. Inventorier une architecture Synapse existante
2. Mapper les composants vers Fabric
3. Identifier les gaps et limitations
4. Estimer l'effort de migration
5. Créer un plan de migration

### Exercice 2 : Migration Synapse → Fabric
1. Migrer un Synapse SQL Pool vers Warehouse
2. Migrer des pipelines ADF vers Fabric
3. Migrer des notebooks Synapse
4. Migrer les données (ADLS → OneLake)
5. Valider la parité fonctionnelle

### Exercice 3 : Architecture hybride
1. Configurer un shortcut OneLake vers ADLS Gen2
2. Créer une vue fédérée (Fabric + Synapse)
3. Partager des données entre les deux plateformes
4. Tester les performances
5. Monitorer l'utilisation

### Exercice 4 : Intégration multi-sources
1. Connecter à SQL Server on-premises
2. Connecter à AWS S3
3. Connecter à une API REST
4. Créer un pipeline d'intégration
5. Consolider dans OneLake

### Exercice 5 : CDC implementation
1. Configurer CDC sur SQL Server
2. Créer un pipeline pour capturer les changes
3. Appliquer les changements dans Lakehouse
4. Tester insert/update/delete
5. Monitorer la latence

### Exercice 6 : Multi-cloud setup
1. Créer un shortcut vers AWS S3
2. Configurer l'authentification cross-cloud
3. Tester l'accès aux données
4. Mesurer la latence
5. Évaluer les coûts de transfert

## Quiz

1. Quelle est la principale différence entre Synapse et Fabric ?
2. Quelles stratégies de migration sont possibles ?
3. Qu'est-ce qu'un pattern de données fédérées ?
4. Comment connecter Fabric à AWS S3 ?
5. Quels sont les défis d'une architecture multi-cloud ?

## Exemples de code

### Migration SQL Pool → Warehouse

```sql
-- Source: Synapse Dedicated SQL Pool
-- Script d'export

SELECT *
INTO [staging].[customers_export]
FROM [dw].[dim_customer]

-- Export vers ADLS Gen2
EXEC sp_export_to_adls
    @table = 'staging.customers_export',
    @path = 'abfss://container@storage.dfs.core.windows.net/export/';

-- Target: Fabric Data Warehouse
-- Import depuis OneLake

COPY INTO [dw].[dim_customer]
FROM 'https://onelake.dfs.fabric.microsoft.com/workspace/lakehouse/Files/export/'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL = (IDENTITY = 'Managed Identity')
);
```

### Shortcut vers AWS S3

```python
# PySpark - Créer un shortcut vers S3

from notebookutils import mssparkutils

# Configuration S3
s3_bucket = "my-bucket"
s3_path = "data/sales/"
aws_access_key = mssparkutils.credentials.getSecret("KeyVault", "aws-access-key")
aws_secret_key = mssparkutils.credentials.getSecret("KeyVault", "aws-secret-key")

# Lire depuis S3 via shortcut
df = spark.read.format("parquet") \
    .option("awsAccessKey", aws_access_key) \
    .option("awsSecretKey", aws_secret_key) \
    .load(f"s3a://{s3_bucket}/{s3_path}")

# Écrire dans OneLake
df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("sales_from_s3")
```

### CDC avec SQL Server

```python
# Pipeline Python pour CDC

from pyspark.sql.functions import col, current_timestamp

# Lire les changes depuis SQL Server CDC tables
jdbc_url = "jdbc:sqlserver://server:1433;database=mydb"
cdc_table = "cdc.dbo_customers_CT"

changes_df = spark.read.format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", cdc_table) \
    .option("user", "username") \
    .option("password", "password") \
    .load()

# Filtrer les changes depuis le dernier run
last_sync = spark.sql("SELECT MAX(sync_timestamp) as last_sync FROM metadata.cdc_tracking").first()["last_sync"]

new_changes = changes_df.filter(col("__$start_lsn") > last_sync)

# Appliquer les changements
for change in new_changes.collect():
    operation = change["__$operation"]

    if operation == 2:  # Insert
        # Insérer dans Delta table
        pass
    elif operation == 4:  # Update
        # Mettre à jour
        pass
    elif operation == 1:  # Delete
        # Supprimer
        pass

# Mettre à jour le watermark
spark.sql(f"""
    UPDATE metadata.cdc_tracking
    SET sync_timestamp = current_timestamp()
""")
```

### Connexion à Snowflake

```python
# Connector Snowflake → Fabric

snowflake_options = {
    "sfUrl": "account.snowflakecomputing.com",
    "sfUser": "username",
    "sfPassword": "password",
    "sfDatabase": "ANALYTICS_DB",
    "sfSchema": "PUBLIC",
    "sfWarehouse": "COMPUTE_WH"
}

# Lire depuis Snowflake
df_snowflake = spark.read.format("snowflake") \
    .options(**snowflake_options) \
    .option("dbtable", "SALES_FACT") \
    .load()

# Transformer et charger dans Fabric
df_transformed = df_snowflake \
    .filter(col("sale_date") >= "2024-01-01") \
    .groupBy("product_id", "region") \
    .sum("amount")

# Écrire dans Lakehouse
df_transformed.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("sales_aggregated")
```

### Migration Pipeline ADF → Fabric

```json
// Pipeline Azure Data Factory (avant)
{
  "name": "CopyPipeline",
  "properties": {
    "activities": [
      {
        "name": "CopyFromSQL",
        "type": "Copy",
        "inputs": [
          {
            "referenceName": "SqlServerSource",
            "type": "DatasetReference"
          }
        ],
        "outputs": [
          {
            "referenceName": "ADLSGen2Sink",
            "type": "DatasetReference"
          }
        ],
        "typeProperties": {
          "source": {
            "type": "SqlSource",
            "sqlReaderQuery": "SELECT * FROM dbo.Sales"
          },
          "sink": {
            "type": "ParquetSink",
            "storeSettings": {
              "type": "AzureBlobFSWriteSettings"
            }
          }
        }
      }
    ]
  }
}

// Équivalent Fabric (après)
// Les pipelines Fabric ont une structure très similaire
// Migration souvent directe avec quelques ajustements
```

## Plan de migration type

### Phase 1 : Assessment (2-4 semaines)
- [ ] Inventaire des assets Synapse
- [ ] Analyse des dépendances
- [ ] Identification des gaps
- [ ] Estimation effort et coût
- [ ] Validation business case

### Phase 2 : Pilot (4-6 semaines)
- [ ] Sélection d'un workload pilote
- [ ] Migration du pilote
- [ ] Tests fonctionnels
- [ ] Tests de performance
- [ ] Validation utilisateurs
- [ ] Lessons learned

### Phase 3 : Migration (12-24 semaines selon taille)
- [ ] Migration par vague
- [ ] Data migration (historical)
- [ ] Application migration
- [ ] Testing complet
- [ ] Training utilisateurs
- [ ] Documentation

### Phase 4 : Cutover (2-4 semaines)
- [ ] Freeze Synapse
- [ ] Final data sync
- [ ] Cutover production
- [ ] Monitoring intensif
- [ ] Support hypercare
- [ ] Decommission Synapse

## Architecture de migration

### Pattern: Phased migration

```
                    [Phase 1]                [Phase 2]              [Phase 3]
[Synapse] ──────────────┐                                              ↓
                        ↓                                         [Decommission]
                [Pilot Workload]
                        ↓
                    [Fabric]
                        ↓
              [Parallel Run 30 days]
                        ↓
                  [Validation]
                        ↓
                [Remaining Workloads] ──→ [Fabric]
```

### Pattern: Hybrid (coexistence)

```
                    ┌─ [Fabric Workloads]
[OneLake] ──────────┤
                    └─ [Synapse Workloads] (via shortcuts)

[Users] → [Power BI] → reads from both platforms
```

## Ressources complémentaires

### Documentation officielle
- [Migrate from Synapse to Fabric](https://learn.microsoft.com/fabric/data-engineering/synapse-migration-overview)
- [OneLake shortcuts](https://learn.microsoft.com/fabric/onelake/onelake-shortcuts)
- [Data integration patterns](https://learn.microsoft.com/azure/architecture/data-guide/technology-choices/data-integration)

### Outils de migration
- [Azure Data Migration Tool](https://azure.microsoft.com/services/database-migration/)
- [Fabric Migration Utility (community)](https://github.com/microsoft/fabric-migration)

### Case studies
- [Microsoft Fabric migration stories](https://customers.microsoft.com/en-us/search?sq=fabric&ff=&p=0)

## Durée estimée

- **Lecture** : 3-4 heures
- **Exercices** : 3-4 heures
- **Total** : 6-8 heures

## Prochaine étape

➡️ [Module 15 - Préparation DP-700](../15-Preparation-DP700/)

---

[⬅️ Module précédent](../13-DevOps-CI-CD/) | [⬅️ Retour au sommaire](../README.md)
