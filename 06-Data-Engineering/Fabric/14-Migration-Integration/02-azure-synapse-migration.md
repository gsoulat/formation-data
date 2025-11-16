# Azure Synapse to Microsoft Fabric Migration

## Introduction

La migration d'Azure Synapse Analytics vers Microsoft Fabric représente une évolution naturelle pour les organisations utilisant déjà l'écosystème Microsoft. Fabric offre une intégration plus profonde, des capacités OneLake unifiées, et une expérience utilisateur simplifiée. Ce guide détaille les stratégies spécifiques pour cette migration.

## Comparaison Synapse vs Fabric

### Mapping des Services

| Azure Synapse | Microsoft Fabric | Notes |
|--------------|------------------|-------|
| Dedicated SQL Pool | Data Warehouse | T-SQL compatible, nouvelle architecture |
| Serverless SQL Pool | SQL Endpoint (Lakehouse) | Query-on-demand sur OneLake |
| Spark Pools | Notebooks & Spark Jobs | Runtime optimisé pour Fabric |
| Data Explorer | Real-Time Analytics | KQL queries, streaming |
| Synapse Pipelines | Data Factory (Fabric) | Interface similaire |
| Synapse Studio | Fabric Workspace | Expérience unifiée |
| ADLS Gen2 | OneLake | Storage centralisé |

### Considérations Clés

```python
class SynapseToFabricMigration:
    def __init__(self):
        self.compatibility_matrix = self._build_compatibility_matrix()

    def assess_migration_complexity(self, synapse_workspace):
        """Évalue la complexité de migration"""
        complexity = {
            'dedicated_sql_pools': self._assess_sql_pools(synapse_workspace['sql_pools']),
            'spark_pools': self._assess_spark_pools(synapse_workspace['spark_pools']),
            'pipelines': self._assess_pipelines(synapse_workspace['pipelines']),
            'linked_services': self._assess_linked_services(synapse_workspace['linked_services'])
        }

        total_score = sum([c['score'] for c in complexity.values()])
        return {
            'details': complexity,
            'total_score': total_score,
            'category': self._categorize_complexity(total_score)
        }

    def _assess_sql_pools(self, sql_pools):
        """Évalue la migration des SQL Pools"""
        issues = []

        for pool in sql_pools:
            # Vérifier les fonctionnalités non supportées
            if pool.uses_external_tables:
                issues.append("External tables need reconfiguration for OneLake")

            if pool.uses_polybase:
                issues.append("PolyBase queries need conversion to COPY INTO")

            if pool.distribution != 'HASH':
                issues.append("Consider optimizing distribution strategy")

        return {
            'count': len(sql_pools),
            'issues': issues,
            'score': len(issues) * 5
        }
```

## Migration du Dedicated SQL Pool

### Étape 1: Export du Schéma

```sql
-- Script d'export des schémas depuis Synapse
-- À exécuter dans Synapse Analytics

-- Export des tables
SELECT
    SCHEMA_NAME(t.schema_id) as schema_name,
    t.name as table_name,
    CASE
        WHEN tp.distribution_policy_desc = 'HASH' THEN
            'DISTRIBUTION = HASH(' + c.name + ')'
        WHEN tp.distribution_policy_desc = 'REPLICATE' THEN
            'DISTRIBUTION = REPLICATE'
        ELSE 'DISTRIBUTION = ROUND_ROBIN'
    END as distribution,
    ISNULL(cp.data_compression_desc, 'NONE') as compression
FROM sys.tables t
INNER JOIN sys.pdw_table_distribution_properties tp ON t.object_id = tp.object_id
LEFT JOIN sys.columns c ON tp.distribution_ordinal = c.column_id AND t.object_id = c.object_id
LEFT JOIN sys.partitions p ON t.object_id = p.object_id
LEFT JOIN sys.data_compression_mappings cp ON p.object_id = cp.object_id;

-- Export des procédures stockées
SELECT
    SCHEMA_NAME(p.schema_id) as schema_name,
    p.name as procedure_name,
    m.definition
FROM sys.procedures p
INNER JOIN sys.sql_modules m ON p.object_id = m.object_id;

-- Export des vues
SELECT
    SCHEMA_NAME(v.schema_id) as schema_name,
    v.name as view_name,
    m.definition
FROM sys.views v
INNER JOIN sys.sql_modules m ON v.object_id = m.object_id;
```

### Étape 2: Conversion vers Fabric Warehouse

```sql
-- Adaptation pour Fabric Data Warehouse
-- Note: Fabric utilise une distribution automatique optimisée

-- Table Synapse originale
CREATE TABLE [dbo].[FactSales]
(
    [SalesKey] BIGINT NOT NULL,
    [CustomerKey] INT NOT NULL,
    [ProductKey] INT NOT NULL,
    [DateKey] INT NOT NULL,
    [Quantity] INT,
    [Amount] DECIMAL(18,2)
)
WITH
(
    DISTRIBUTION = HASH([CustomerKey]),
    CLUSTERED COLUMNSTORE INDEX
);

-- Conversion pour Fabric Warehouse
-- Fabric gère automatiquement la distribution
CREATE TABLE [dbo].[FactSales]
(
    [SalesKey] BIGINT NOT NULL,
    [CustomerKey] INT NOT NULL,
    [ProductKey] INT NOT NULL,
    [DateKey] INT NOT NULL,
    [Quantity] INT,
    [Amount] DECIMAL(18,2)
);

-- Ajout des contraintes
ALTER TABLE [dbo].[FactSales]
ADD CONSTRAINT PK_FactSales PRIMARY KEY NONCLUSTERED (SalesKey);

-- Index pour optimisation (Fabric supporte les index columnstore)
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactSales ON [dbo].[FactSales];
```

### Étape 3: Migration des Données

```python
# Script de migration des données via COPY INTO
class SynapseDataMigrator:
    def __init__(self, synapse_connection, fabric_connection):
        self.source = synapse_connection
        self.target = fabric_connection

    def migrate_table(self, table_name):
        """Migre une table de Synapse vers Fabric"""

        # 1. Export vers ADLS Gen2 (format Parquet)
        export_path = self._export_to_adls(table_name)

        # 2. Créer un shortcut OneLake vers ADLS (temporaire)
        shortcut_path = self._create_onelake_shortcut(export_path)

        # 3. COPY INTO dans Fabric Warehouse
        copy_sql = f"""
        COPY INTO [dbo].[{table_name}]
        FROM '{shortcut_path}'
        WITH (
            FILE_TYPE = 'PARQUET',
            CREDENTIAL = (IDENTITY = 'Shared Access Signature'),
            MAX_ERRORS = 0
        );
        """

        self.target.execute(copy_sql)

        # 4. Valider la migration
        validation = self._validate_migration(table_name)
        return validation

    def _export_to_adls(self, table_name):
        """Export les données vers ADLS en Parquet"""
        cetas_sql = f"""
        CREATE EXTERNAL TABLE [export].[{table_name}]
        WITH (
            LOCATION = '/migration/{table_name}/',
            DATA_SOURCE = [ExternalDataSource],
            FILE_FORMAT = [ParquetFileFormat]
        )
        AS SELECT * FROM [dbo].[{table_name}];
        """
        self.source.execute(cetas_sql)
        return f"/migration/{table_name}/"

    def migrate_incremental(self, table_name, watermark_column):
        """Migration incrémentale pour tables volumineuses"""
        last_watermark = self._get_last_watermark(table_name)

        incremental_sql = f"""
        SELECT *
        FROM [dbo].[{table_name}]
        WHERE [{watermark_column}] > '{last_watermark}'
        """

        # Export only new/modified data
        # ...
```

## Migration des Spark Pools

### Conversion des Notebooks

```python
# AVANT: Notebook Synapse Spark
# Utilise le connecteur Synapse spécifique

# Configuration Synapse Spark Pool
spark.conf.set("spark.sql.shuffle.partitions", "200")

# Lecture depuis Synapse Dedicated SQL Pool
df = spark.read \
    .format("com.microsoft.spark.sqlanalytics") \
    .option("spark.synapse.linkedService", "SynapseSQL") \
    .option("spark.synapse.authentication", "SqlPassword") \
    .load("SELECT * FROM dbo.FactSales")

# Écriture vers ADLS Gen2
df.write \
    .mode("overwrite") \
    .format("parquet") \
    .save("abfss://container@storage.dfs.core.windows.net/output/")
```

```python
# APRÈS: Notebook Fabric
# Utilise OneLake et les tables Delta natives

# Lecture depuis Lakehouse (automatiquement monté)
df = spark.read.table("sales_lakehouse.bronze.fact_sales")

# Ou lecture directe Delta Lake
df = spark.read.format("delta").load("Tables/bronze/fact_sales")

# Transformation
from pyspark.sql.functions import col, sum, avg

df_aggregated = df.groupBy("CustomerKey", "DateKey") \
    .agg(
        sum("Amount").alias("TotalAmount"),
        avg("Quantity").alias("AvgQuantity")
    )

# Écriture vers table Gold (automatiquement en Delta Lake)
df_aggregated.write \
    .mode("overwrite") \
    .format("delta") \
    .option("overwriteSchema", "true") \
    .saveAsTable("sales_lakehouse.gold.customer_daily_summary")

# Les tables sont immédiatement queryables via SQL Endpoint
```

### Adaptation des Configurations Spark

```python
# Configuration migration guide
spark_config_migration = {
    'synapse': {
        # Synapse Spark specific configs
        'spark.synapse.linkedService': 'Not needed in Fabric',
        'spark.synapse.authentication': 'Handled by Fabric',
        'spark.hadoop.fs.azure.account.oauth2.client.endpoint': 'Not needed',
    },
    'fabric': {
        # Fabric optimized configs
        'spark.sql.adaptive.enabled': 'true',
        'spark.sql.adaptive.coalescePartitions.enabled': 'true',
        'spark.microsoft.delta.autoOptimize.enabled': 'true',
        'spark.sql.parquet.vorderEnabled': 'true',  # V-Order optimization
    }
}
```

## Migration des Pipelines

```json
// Pipeline Synapse original
{
  "name": "PL_DailySalesIngestion",
  "properties": {
    "activities": [
      {
        "name": "CopyFromSQLServer",
        "type": "Copy",
        "linkedServiceName": {
          "referenceName": "SqlServerLinkedService",
          "type": "LinkedServiceReference"
        },
        "typeProperties": {
          "source": {
            "type": "SqlServerSource",
            "sqlReaderQuery": "SELECT * FROM Sales"
          },
          "sink": {
            "type": "SqlDWSink",
            "preCopyScript": "TRUNCATE TABLE dbo.SalesStaging"
          }
        }
      },
      {
        "name": "TransformWithSpark",
        "type": "SynapseNotebook",
        "linkedServiceName": {
          "referenceName": "SynapseSparkPool",
          "type": "LinkedServiceReference"
        }
      }
    ]
  }
}

// Pipeline Fabric équivalent
{
  "name": "PL_DailySalesIngestion",
  "properties": {
    "activities": [
      {
        "name": "CopyFromSQLServer",
        "type": "Copy",
        "typeProperties": {
          "source": {
            "type": "SqlServerSource",
            "sqlReaderQuery": "SELECT * FROM Sales"
          },
          "sink": {
            "type": "LakehouseTable",
            "tableActionOption": "OverwriteTable"
          }
        },
        "linkedServiceName": {
          "referenceName": "OneLake",
          "type": "LinkedServiceReference"
        }
      },
      {
        "name": "TransformWithNotebook",
        "type": "Notebook",
        "typeProperties": {
          "notebookPath": "Sales/TransformDailySales",
          "baseParameters": {
            "date": "@pipeline().parameters.ProcessDate"
          }
        }
      }
    ]
  }
}
```

## Script de Migration Automatisée

```powershell
# migrate-synapse-to-fabric.ps1
param(
    [string]$SynapseWorkspaceName,
    [string]$FabricWorkspaceId,
    [string]$MigrationConfigPath
)

$config = Get-Content $MigrationConfigPath | ConvertFrom-Json

function Migrate-SqlPools {
    param($SqlPools, $TargetWorkspace)

    foreach ($pool in $SqlPools) {
        Write-Host "Migrating SQL Pool: $($pool.name)" -ForegroundColor Cyan

        # 1. Create Fabric Warehouse
        $warehouse = New-FabricWarehouse -Name $pool.name -WorkspaceId $TargetWorkspace

        # 2. Migrate schema
        $schema = Export-SynapseSchema -PoolName $pool.name
        Import-FabricSchema -WarehouseId $warehouse.id -Schema $schema

        # 3. Migrate data
        Invoke-DataMigration -Source $pool -Target $warehouse

        # 4. Migrate stored procedures
        $procs = Get-SynapseProcedures -PoolName $pool.name
        foreach ($proc in $procs) {
            Create-FabricProcedure -WarehouseId $warehouse.id -Definition $proc
        }
    }
}

function Migrate-SparkPools {
    param($Notebooks, $TargetWorkspace)

    foreach ($notebook in $Notebooks) {
        Write-Host "Migrating Notebook: $($notebook.name)" -ForegroundColor Cyan

        # Convert notebook
        $fabricNotebook = Convert-SynapseNotebook -SourceNotebook $notebook

        # Upload to Fabric
        Import-FabricNotebook -WorkspaceId $TargetWorkspace -Notebook $fabricNotebook
    }
}

# Main execution
Migrate-SqlPools -SqlPools $config.sqlPools -TargetWorkspace $FabricWorkspaceId
Migrate-SparkPools -Notebooks $config.notebooks -TargetWorkspace $FabricWorkspaceId

Write-Host "Migration completed!" -ForegroundColor Green
```

## Points Clés

- Fabric offre une simplification significative vs Synapse
- La distribution est automatique dans Fabric (pas de HASH/ROUND_ROBIN explicit)
- OneLake remplace ADLS Gen2 avec une expérience unifiée
- Les notebooks Spark nécessitent des adaptations mineures
- Les pipelines sont largement compatibles avec quelques ajustements
- Profiter de la migration pour adopter le pattern Medallion
- Valider les performances après migration avec les mêmes workloads
- Planifier la décommissionnement progressive de Synapse

---

**Navigation** : [Précédent : Migration Strategies](./01-migration-strategies.md) | [Index](../README.md) | [Suivant : Power BI Migration](./03-powerbi-migration.md)
