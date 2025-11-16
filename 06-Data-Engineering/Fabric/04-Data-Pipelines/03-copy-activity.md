# Copy Activity Avancé

## Introduction

Le **Copy Activity** est l'activity la plus utilisée dans les pipelines pour déplacer des données entre sources et destinations. L'optimisation du Copy Activity est cruciale pour les performances ETL.

```
Copy Activity Architecture:
┌────────────┐      ┌──────────┐      ┌────────────┐
│   Source   │ ───→ │ Pipeline │ ───→ │    Sink    │
│  (Input)   │      │ (Transform)     │  (Output)  │
└────────────┘      └──────────┘      └────────────┘
                         ↓
                  [Staging optional]
```

## Sources et Destinations

### Sources Supportées

**Databases :**
```
• SQL Server
• Azure SQL Database / MI
• PostgreSQL
• MySQL
• Oracle
• Teradata
• DB2
• Sybase
• SAP HANA
• Snowflake
• Google BigQuery
```

**Files :**
```
• Azure Blob Storage
• Azure Data Lake Gen2
• Amazon S3
• Google Cloud Storage
• SFTP / FTP
• File System (via gateway)
• HTTP endpoint
```

**SaaS / Applications :**
```
• Salesforce
• Dynamics 365
• ServiceNow
• SAP ECC / S4
• REST API
• OData
```

**Fabric :**
```
• Lakehouse Tables/Files
• Warehouse Tables
• KQL Database
```

### Destinations (Sinks)

```
Mêmes sources + optimisations spécifiques:
• Lakehouse (Delta Lake)
• Warehouse (T-SQL)
• KQL (Real-time)
• Blob/ADLS (Parquet, CSV, JSON)
```

## Configuration Détaillée

### Source Configuration

#### SQL Source

```json
{
  "source": {
    "type": "SqlSource",
    "sqlReaderQuery": "SELECT * FROM sales WHERE sale_date >= '@{formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')}'",
    "queryTimeout": "02:00:00",
    "isolationLevel": "ReadCommitted",
    "partitionOption": "PhysicalPartitionsOfTable",
    "partitionSettings": {
      "partitionColumnName": "id",
      "partitionUpperBound": "1000000",
      "partitionLowerBound": "1",
      "partitionNames": ["p0", "p1", "p2", "p3"]
    }
  }
}
```

**Partitioning Strategies :**

```sql
-- 1. Physical Partitions (Table déjà partitionnée)
Partition Option: PhysicalPartitionsOfTable
→ Utilise partitions existantes de la table

-- 2. Dynamic Range Partitioning
Partition Option: DynamicRange
Partition Column: id
Lower Bound: 1
Upper Bound: 1000000
Max Partitions: 4

→ Crée ranges:
  [1, 250000]
  [250001, 500000]
  [500001, 750000]
  [750001, 1000000]

-- 3. No Partitioning
Partition Option: None
→ Single read
```

#### File Source (CSV, Parquet, JSON)

```json
{
  "source": {
    "type": "DelimitedTextSource",
    "storeSettings": {
      "type": "AzureBlobStorageReadSettings",
      "recursive": true,
      "wildcardFolderPath": "sales/2024/*",
      "wildcardFileName": "*.csv",
      "modifiedDatetimeStart": "2024-01-01T00:00:00Z",
      "modifiedDatetimeEnd": "2024-01-31T23:59:59Z",
      "deleteFilesAfterCompletion": false
    },
    "formatSettings": {
      "type": "DelimitedTextReadSettings",
      "skipLineCount": 1,
      "compressionType": "GZip",
      "encodingName": "UTF-8",
      "escapeChar": "\\",
      "quoteChar": "\"",
      "firstRowAsHeader": true,
      "nullValue": "NULL"
    },
    "additionalColumns": [
      {
        "name": "source_file",
        "value": "$$FILEPATH"
      },
      {
        "name": "loaded_at",
        "value": "$$NOW"
      }
    ]
  }
}
```

**Built-in Variables :**
```
$$FILEPATH: Chemin complet du fichier
$$FILENAME: Nom du fichier
$$NOW: Timestamp actuel
$$COLUMN: Valeur d'une colonne
```

### Sink Configuration

#### Lakehouse Sink

```json
{
  "sink": {
    "type": "LakehouseSink",
    "writeBehavior": "Upsert",
    "tableActionOption": "autoCreate",
    "partitionOptions": {
      "partitionBy": ["year", "month"]
    },
    "upsertSettings": {
      "useTempDB": true,
      "keys": ["sale_id"],
      "interimSchemaName": "staging"
    },
    "preCopyScript": "DELETE FROM silver_sales WHERE processing_date = '@{pipeline().parameters.date}'",
    "maxConcurrentConnections": 5,
    "writeBatchSize": 10000,
    "writeBatchTimeout": "00:30:00"
  }
}
```

**Write Behaviors :**
```
• Insert: Append seulement (le plus rapide)
• Upsert: Update si existe, Insert sinon
• Overwrite: Truncate puis Insert
• Merge: Complex merge logic
```

#### Warehouse Sink

```json
{
  "sink": {
    "type": "WarehouseSink",
    "preCopyScript": "TRUNCATE TABLE staging_sales",
    "copyOptions": {
      "defaultValue": [],
      "tableOption": "autoCreate"
    },
    "writeBehavior": "Insert",
    "tableDistributionOption": "Hash",
    "tableDistributionColumnName": "customer_id",
    "disableMetricsCollection": false
  }
}
```

### Column Mapping

#### Simple Mapping

```json
{
  "translator": {
    "type": "TabularTranslator",
    "mappings": [
      { "source": { "name": "ID" }, "sink": { "name": "id" } },
      { "source": { "name": "CustomerName" }, "sink": { "name": "customer_name" } },
      { "source": { "name": "OrderDate" }, "sink": { "name": "order_date" } },
      { "source": { "name": "TotalAmount" }, "sink": { "name": "amount" } }
    ]
  }
}
```

#### Mapping avec Type Conversion

```json
{
  "translator": {
    "type": "TabularTranslator",
    "mappings": [
      {
        "source": { "name": "OrderDate", "type": "String" },
        "sink": { "name": "order_date", "type": "DateTime" }
      },
      {
        "source": { "name": "Amount", "type": "String" },
        "sink": { "name": "amount", "type": "Decimal", "precision": 18, "scale": 2 }
      },
      {
        "source": { "name": "IsActive", "type": "String" },
        "sink": { "name": "is_active", "type": "Boolean" }
      }
    ],
    "typeConversion": true,
    "typeConversionSettings": {
      "allowDataTruncation": false,
      "treatBooleanAsNumber": false,
      "dateTimeFormat": "yyyy-MM-dd HH:mm:ss",
      "dateTimeOffsetFormat": "yyyy-MM-dd HH:mm:ss zzz",
      "timeSpanFormat": "c"
    }
  }
}
```

#### Mapping avec Transformations

```json
{
  "translator": {
    "type": "TabularTranslator",
    "mappings": [
      {
        "source": { "name": "FirstName" },
        "sink": { "name": "first_name" }
      },
      {
        "source": { "name": "LastName" },
        "sink": { "name": "last_name" }
      }
    ],
    "collectionReference": "$['records'][*]",
    "mapComplexValuesToString": true
  }
}
```

## Performance Optimization

### Data Integration Units (DIU)

**Qu'est-ce que DIU ?**
```
DIU = Data Integration Unit
  • Mesure de puissance CPU + RAM + Network
  • Utilisé pour Copy Activity cloud-to-cloud
  • Auto ou Manual: 2-256 DIU
```

**Impact Performance :**
```
Dataset: 10 GB, Source: Azure SQL → Sink: Lakehouse

2 DIU:
  Duration: ~20 min
  Throughput: ~8.5 MB/s

4 DIU:
  Duration: ~10 min
  Throughput: ~17 MB/s

8 DIU:
  Duration: ~5 min
  Throughput: ~34 MB/s

16 DIU:
  Duration: ~2.5 min
  Throughput: ~68 MB/s

32 DIU:
  Duration: ~1.5 min
  Throughput: ~114 MB/s
```

**Configuration :**
```json
{
  "typeProperties": {
    "dataIntegrationUnits": 16,
    "parallelCopies": 8
  }
}
```

### Parallel Copies

**Concept :**
```
Parallel Copies = nombre de threads parallèles

1 Parallel Copy:
  Source → [Thread 1] → Sink

4 Parallel Copies:
  Source → [Thread 1] → Sink
  Source → [Thread 2] → Sink
  Source → [Thread 3] → Sink
  Source → [Thread 4] → Sink
```

**Recommandations :**
```
Source Type         | Parallel Copies
--------------------|----------------
File-based          | 4-32
SQL Database        | 2-8 (selon partitions)
NoSQL               | 4-16
API (REST)          | 1-4 (rate limiting)
```

**Configuration :**
```json
{
  "typeProperties": {
    "parallelCopies": 8,
    "source": {
      "partitionOption": "DynamicRange"
    }
  }
}
```

### Staging

**Quand Utiliser Staging ?**

```
Scénarios:
✅ Source et Sink dans différentes régions
✅ Transformations complexes nécessaires
✅ Données compressées/décompressées
✅ Conversion de format (CSV → Parquet)

Architecture avec Staging:
Source → Staging (Blob) → Transform → Sink
```

**Configuration :**
```json
{
  "typeProperties": {
    "enableStaging": true,
    "stagingSettings": {
      "linkedServiceName": {
        "referenceName": "BlobStagingStorage",
        "type": "LinkedServiceReference"
      },
      "path": "staging/sales",
      "enableCompression": true
    }
  }
}
```

**Performance Impact :**
```
Sans Staging:
  SQL Server (On-prem) → Lakehouse (EU)
  Duration: 45 min
  Network: Direct cross-region

Avec Staging (Blob même région que Lakehouse):
  SQL Server → Staging Blob → Lakehouse
  Duration: 15 min
  Network: Optimized within region
```

## Incremental Copy Patterns

### Watermark Pattern (Delta Copy)

```sql
-- 1. Table de watermark
CREATE TABLE watermark (
    table_name VARCHAR(100),
    last_update_time DATETIME
);

INSERT INTO watermark VALUES ('sales', '2024-01-01 00:00:00');
```

**Pipeline :**
```json
{
  "activities": [
    {
      "name": "Lookup_Watermark",
      "type": "Lookup",
      "typeProperties": {
        "source": {
          "query": "SELECT last_update_time FROM watermark WHERE table_name = 'sales'"
        }
      }
    },
    {
      "name": "Copy_Incremental_Data",
      "type": "Copy",
      "typeProperties": {
        "source": {
          "query": "SELECT * FROM sales WHERE updated_at > '@{activity('Lookup_Watermark').output.firstRow.last_update_time}'"
        }
      },
      "dependsOn": [
        { "activity": "Lookup_Watermark", "dependencyConditions": ["Succeeded"] }
      ]
    },
    {
      "name": "Update_Watermark",
      "type": "SqlServerStoredProcedure",
      "typeProperties": {
        "storedProcedureName": "sp_update_watermark",
        "storedProcedureParameters": {
          "table_name": "sales",
          "new_watermark": "@{activity('Copy_Incremental_Data').output.executionDetails[0].source.max_updated_at}"
        }
      },
      "dependsOn": [
        { "activity": "Copy_Incremental_Data", "dependencyConditions": ["Succeeded"] }
      ]
    }
  ]
}
```

### Change Data Capture (CDC)

**SQL Server CDC :**
```sql
-- Activer CDC sur database
EXEC sys.sp_cdc_enable_db;

-- Activer CDC sur table
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name = 'sales',
    @role_name = NULL,
    @supports_net_changes = 1;
```

**Copy Activity avec CDC :**
```json
{
  "source": {
    "type": "SqlSource",
    "sqlReaderQuery": "SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_sales(@from_lsn, @to_lsn, 'all')"
  }
}
```

### Partition-Based Incremental

```json
{
  "source": {
    "type": "SqlSource",
    "query": "SELECT * FROM sales WHERE year = @{formatDateTime(utcnow(), 'yyyy')} AND month = @{formatDateTime(utcnow(), 'MM')}",
    "partitionOption": "DynamicRange",
    "partitionSettings": {
      "partitionColumnName": "day",
      "partitionUpperBound": "@{formatDateTime(utcnow(), 'dd')}",
      "partitionLowerBound": "1"
    }
  }
}
```

## Error Handling

### Fault Tolerance

```json
{
  "typeProperties": {
    "enableSkipIncompatibleRow": true,
    "redirectIncompatibleRowSettings": {
      "linkedServiceName": "ErrorLogStorage",
      "path": "errors/sales/incompatible_rows"
    },
    "logSettings": {
      "enableCopyActivityLog": true,
      "copyActivityLogSettings": {
        "logLevel": "Warning",
        "enableReliableLogging": true
      },
      "logLocationSettings": {
        "linkedServiceName": "LogStorage",
        "path": "logs/copy_activity"
      }
    }
  }
}
```

**Incompatible Rows :**
```
Causes:
  • Type mismatch (string → int)
  • Constraint violation (NULL dans NOT NULL)
  • Out of range (number trop grand)
  • Invalid format (date malformée)

Action:
  enableSkipIncompatibleRow: true
  → Continue copy, log errors

  enableSkipIncompatibleRow: false
  → Fail entire copy
```

### Retry Policy

```json
{
  "policy": {
    "timeout": "01:00:00",
    "retry": 3,
    "retryIntervalInSeconds": 60,
    "secureOutput": false,
    "secureInput": false
  }
}
```

## Copy Activity Patterns

### Pattern 1 : Full Load

```
Use case: Petite table, refresh complet quotidien

Pipeline:
  1. Truncate target table
  2. Copy all data from source
  3. Rebuild indexes
```

```json
{
  "activities": [
    {
      "name": "Truncate_Target",
      "type": "Script",
      "typeProperties": {
        "scripts": [{ "type": "Query", "text": "TRUNCATE TABLE target_table" }]
      }
    },
    {
      "name": "Copy_Full_Data",
      "type": "Copy",
      "typeProperties": {
        "source": { "query": "SELECT * FROM source_table" },
        "sink": { "writeBehavior": "Insert" }
      },
      "dependsOn": [
        { "activity": "Truncate_Target", "dependencyConditions": ["Succeeded"] }
      ]
    }
  ]
}
```

### Pattern 2 : Incremental Load with Watermark

```
Use case: Grande table, seulement nouvelles/modifiées

Pipeline:
  1. Get last watermark
  2. Copy data > watermark
  3. Update watermark
```

*(Voir exemple CDC plus haut)*

### Pattern 3 : Merge (Upsert)

```
Use case: Dimension slowly changing (SCD Type 1)

Pipeline:
  1. Copy to staging
  2. Merge staging → target (UPDATE + INSERT)
  3. Truncate staging
```

```sql
-- Stored Procedure: sp_merge_customer_data
MERGE INTO dim_customer AS target
USING staging_customer AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.email = source.email,
        target.updated_at = GETDATE()

WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, email, created_at)
    VALUES (source.customer_id, source.customer_name, source.email, GETDATE());
```

### Pattern 4 : Partition Switching

```
Use case: Time-series data, daily partitions

Pipeline:
  1. Copy new day to staging table
  2. Switch partition from staging to main table
  3. Drop staging
```

```sql
-- Fast partition switch (metadata operation)
ALTER TABLE main_sales
SWITCH PARTITION $PARTITION.pf_daily('2024-01-15')
TO staging_sales PARTITION $PARTITION.pf_daily('2024-01-15');
```

### Pattern 5 : Delta Lake MERGE

```python
# Lakehouse Notebook après Copy to staging
from delta.tables import DeltaTable

staging_df = spark.table("staging_sales")
delta_table = DeltaTable.forName(spark, "silver_sales")

delta_table.alias("target").merge(
    staging_df.alias("source"),
    "target.sale_id = source.sale_id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()
```

## Monitoring et Troubleshooting

### Copy Activity Output

```json
{
  "output": {
    "dataRead": 1073741824,
    "dataWritten": 1073741824,
    "filesRead": 10,
    "filesWritten": 1,
    "sourcePeakConnections": 4,
    "sinkPeakConnections": 1,
    "rowsCopied": 1000000,
    "rowsSkipped": 15,
    "copyDuration": 180,
    "throughput": 5957,
    "errors": [],
    "effectiveIntegrationRuntime": "AutoResolveIntegrationRuntime",
    "usedDataIntegrationUnits": 16,
    "usedParallelCopies": 8,
    "executionDetails": [
      {
        "source": {
          "type": "SqlServer",
          "status": "Succeeded"
        },
        "sink": {
          "type": "Lakehouse",
          "status": "Succeeded"
        },
        "status": "Succeeded",
        "start": "2024-01-15T10:00:00Z",
        "duration": 180,
        "detailedDurations": {
          "queuingDuration": 2,
          "transferDuration": 178
        }
      }
    ]
  }
}
```

### Performance Metrics

```
Key Metrics:
  • Throughput (MB/s)
  • Rows per second
  • DIU utilization
  • Parallel copies used
  • Queue time vs Transfer time

Calculs:
  Throughput = dataRead / copyDuration
  Rows/sec = rowsCopied / copyDuration

Optimization si:
  • Queue time > Transfer time → Increase DIU
  • Low throughput → Increase parallel copies
  • High skip rate → Fix data quality
```

## Best Practices

### ✅ Performance

```
1. Partitioning:
   • Utiliser partitions physiques si disponibles
   • Dynamic range pour grandes tables sans partitions
   • 4-8 partitions optimal

2. DIU:
   • Auto pour commencer
   • Monitor et ajuster si nécessaire
   • Plus de DIU n'est pas toujours mieux (diminishing returns)

3. Parallel Copies:
   • File-based: 8-16
   • Database: 4-8
   • Aligner avec partitions source

4. Staging:
   • Utiliser pour cross-region
   • Compression activée
   • Staging dans même région que sink
```

### ✅ Reliability

```
1. Error Handling:
   • Skip incompatible rows en DEV (identifier problèmes)
   • Fail en PROD (qualité garantie)
   • Log toutes erreurs

2. Retry:
   • 2-3 retries avec 30-60s interval
   • Timeout: 2x durée moyenne attendue

3. Monitoring:
   • Alertes sur failures
   • Tracking throughput trends
   • Monitor skip rate
```

### ✅ Cost

```
1. DIU Optimization:
   • Auto-scale si workload variable
   • Fixed DIU si workload prévisible

2. Incremental:
   • Watermark pour grandes tables
   • Éviter full loads si possible

3. Compression:
   • Source et sink compression
   • Staging compression
```

## Points Clés

- Copy Activity = cœur des pipelines ETL
- DIU et Parallel Copies = clés performance
- Staging pour cross-region et transformations
- Incremental patterns (watermark, CDC) pour efficacité
- Error handling et retry pour reliability
- Monitoring throughput et rows/sec
- Partitioning optimal = 4-8 partitions
- Column mapping avec type conversion
- Patterns: Full, Incremental, Merge, Partition Switch

---

**Prochain fichier :** [04 - Intégration Dataflows](./04-dataflows-integration.md)

[⬅️ Fichier précédent](./02-activities-transformations.md) | [⬅️ Retour au README du module](./README.md)
