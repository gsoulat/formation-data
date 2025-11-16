# Activities et Transformations

## Vue d'Ensemble des Activities

```
Activities Fabric Pipelines:
├── Data Movement
│   ├── Copy Data
│   └── Delete Data
├── Data Transformation
│   ├── Dataflow Gen2
│   ├── Notebook
│   ├── Stored Procedure
│   └── Script (SQL, Python)
├── Control Flow
│   ├── If Condition
│   ├── ForEach
│   ├── Until
│   ├── Wait
│   ├── Set Variable
│   └── Append Variable
├── External
│   ├── Web Activity
│   ├── Azure Function
│   └── Webhook
└── Fabric Workloads
    ├── Lakehouse
    ├── Warehouse
    ├── KQL Database
    └── Office Script
```

## Data Movement Activities

### Copy Data Activity (Détaillé)

**Architecture :**
```
Source → [Staging (optional)] → Sink

Avec transformations column mapping:
Source columns → Mapped → Sink columns
```

#### Sources Supportées

```
On-Premises:
  • SQL Server
  • Oracle
  • MySQL/PostgreSQL
  • File System
  • SAP

Cloud:
  • Azure SQL Database
  • Azure Blob Storage
  • AWS S3
  • Google Cloud Storage
  • Snowflake
  • Salesforce

Fabric:
  • Lakehouse Tables/Files
  • Warehouse Tables
  • KQL Database
```

#### Configuration Avancée

```json
{
  "name": "Copy_With_Advanced_Settings",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT * FROM sales WHERE date >= '@{pipeline().parameters.start_date}'",
      "queryTimeout": "00:30:00",
      "partitionOption": "PhysicalPartitionsOfTable",
      "partitionSettings": {
        "partitionColumnName": "id",
        "partitionUpperBound": "1000000",
        "partitionLowerBound": "1"
      }
    },
    "sink": {
      "type": "LakehouseSink",
      "writeBehavior": "Upsert",
      "upsertSettings": {
        "useTempDB": true,
        "keys": ["sale_id"]
      },
      "tableOption": "autoCreate",
      "preCopyScript": "TRUNCATE TABLE staging_sales"
    },
    "enableStaging": true,
    "stagingSettings": {
      "linkedServiceName": "BlobStorage",
      "path": "staging/sales"
    },
    "parallelCopies": 8,
    "dataIntegrationUnits": 16,
    "enableSkipIncompatibleRow": true,
    "logSettings": {
      "enableCopyActivityLog": true,
      "copyActivityLogSettings": {
        "logLevel": "Warning",
        "enableReliableLogging": true
      }
    }
  }
}
```

#### Column Mapping

```json
{
  "translator": {
    "type": "TabularTranslator",
    "mappings": [
      {
        "source": { "name": "CustomerID" },
        "sink": { "name": "customer_id", "type": "Int32" }
      },
      {
        "source": { "name": "OrderDate" },
        "sink": { "name": "order_date", "type": "DateTime" }
      },
      {
        "source": { "name": "TotalAmount" },
        "sink": { "name": "amount", "type": "Decimal" }
      }
    ],
    "collectionReference": "",
    "mapComplexValuesToString": false
  }
}
```

#### Data Integration Units (DIU)

```
DIU = Mesure de puissance pour Copy Activity

Allocation:
  Auto (default): 4-256 DIU automatique
  Custom: 2, 4, 8, 16, 32, 64, 128, 256

Impact performance:
  2 DIU:   ~500 MB/s
  4 DIU:   ~1 GB/s
  8 DIU:   ~2 GB/s
  16 DIU:  ~4 GB/s

Cost:
  Plus de DIU = plus de CU consumption
```

**Example :**
```
Copy 10 GB:
  2 DIU:  ~20 minutes
  8 DIU:  ~5 minutes
  32 DIU: ~1.5 minutes
```

### Delete Data Activity

```json
{
  "name": "Delete_Old_Files",
  "type": "Delete",
  "typeProperties": {
    "dataset": {
      "referenceName": "BlobDataset"
    },
    "logStorageSettings": {
      "linkedServiceName": "LogStorage",
      "path": "logs/deletes"
    },
    "enableLogging": true,
    "storeSettings": {
      "type": "AzureBlobStorageReadSettings",
      "recursive": true,
      "wildcardFolderPath": "archives",
      "wildcardFileName": "*.csv",
      "modifiedDatetimeStart": "2023-01-01T00:00:00Z",
      "modifiedDatetimeEnd": "2023-12-31T23:59:59Z"
    }
  }
}
```

## Data Transformation Activities

### Notebook Activity

Exécute un Spark notebook pour transformations complexes.

```python
# Notebook: Transform_Sales_Data
# Parameters: processing_date, source_table, target_table

from pyspark.sql.functions import *
from delta.tables import DeltaTable

# Get parameters
processing_date = mssparkutils.env.getJobParameter("processing_date")
source_table = mssparkutils.env.getJobParameter("source_table")
target_table = mssparkutils.env.getJobParameter("target_table")

# Read source
df = spark.table(source_table) \
    .where(f"date = '{processing_date}'")

# Transformations
transformed_df = df \
    .dropDuplicates(["sale_id"]) \
    .filter(col("amount") > 0) \
    .withColumn("year", year(col("sale_date"))) \
    .withColumn("month", month(col("sale_date"))) \
    .withColumn("processed_at", current_timestamp())

# Upsert to target
delta_table = DeltaTable.forName(spark, target_table)
delta_table.alias("target").merge(
    transformed_df.alias("source"),
    "target.sale_id = source.sale_id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Return metrics
output = {
    "rows_processed": transformed_df.count(),
    "processing_date": processing_date
}

mssparkutils.notebook.exit(output)
```

**Dans Pipeline :**
```json
{
  "name": "Run_Transformation_Notebook",
  "type": "SparkNotebook",
  "typeProperties": {
    "notebook": {
      "referenceName": "Transform_Sales_Data",
      "type": "NotebookReference"
    },
    "parameters": {
      "processing_date": {
        "value": "@formatDateTime(utcnow(), 'yyyy-MM-dd')",
        "type": "Expression"
      },
      "source_table": {
        "value": "bronze_sales",
        "type": "String"
      },
      "target_table": {
        "value": "silver_sales",
        "type": "String"
      }
    },
    "snapshot": true,
    "conf": {
      "spark.dynamicAllocation.enabled": "true",
      "spark.dynamicAllocation.minExecutors": "2",
      "spark.dynamicAllocation.maxExecutors": "8"
    }
  }
}
```

### Dataflow Gen2 Activity

Exécute un Dataflow (Power Query) pour transformations no-code.

```
Dataflow: Clean_Customer_Data

Steps:
1. Source: SQL Server Customers table
2. Remove Duplicates (on email)
3. Filter: country IN ('FR', 'BE', 'CH')
4. Transform:
   ├─ Trim whitespace
   ├─ Proper case names
   └─ Format phone numbers
5. Enrich:
   └─ Merge with Country_Codes table
6. Destination: Lakehouse silver_customers
```

**Dans Pipeline :**
```json
{
  "name": "Run_Customer_Dataflow",
  "type": "ExecuteDataFlow",
  "typeProperties": {
    "dataflow": {
      "referenceName": "Clean_Customer_Data",
      "type": "DataFlowReference"
    },
    "compute": {
      "coreCount": 8,
      "computeType": "General"
    },
    "traceLevel": "Fine"
  }
}
```

### Stored Procedure Activity

Exécute procédure stockée SQL.

```sql
-- Stored Procedure: sp_aggregate_sales
CREATE PROCEDURE sp_aggregate_sales
    @processing_date DATE,
    @region VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Aggregate sales
    INSERT INTO gold_daily_sales_summary
    SELECT
        @processing_date as processing_date,
        ISNULL(@region, country) as region,
        product_category,
        SUM(amount) as total_sales,
        COUNT(DISTINCT customer_id) as unique_customers,
        COUNT(*) as transaction_count,
        AVG(amount) as avg_transaction_value
    FROM silver_sales
    WHERE sale_date = @processing_date
        AND (@region IS NULL OR country = @region)
    GROUP BY ISNULL(@region, country), product_category;

    -- Return stats
    SELECT @@ROWCOUNT as rows_inserted;
END;
```

**Dans Pipeline :**
```json
{
  "name": "Aggregate_Daily_Sales",
  "type": "SqlServerStoredProcedure",
  "typeProperties": {
    "storedProcedureName": "sp_aggregate_sales",
    "storedProcedureParameters": {
      "processing_date": {
        "value": "@formatDateTime(utcnow(), 'yyyy-MM-dd')",
        "type": "DateTime"
      },
      "region": {
        "value": "@pipeline().parameters.region",
        "type": "String"
      }
    }
  },
  "linkedServiceName": {
    "referenceName": "WarehouseConnection",
    "type": "LinkedServiceReference"
  }
}
```

### Script Activity

Exécute scripts SQL, Python ou autre.

**SQL Script :**
```json
{
  "name": "Run_SQL_Script",
  "type": "Script",
  "typeProperties": {
    "scripts": [
      {
        "type": "Query",
        "text": "DELETE FROM staging_sales WHERE processed = 1;"
      },
      {
        "type": "Query",
        "text": "UPDATE metadata SET last_processed = GETDATE() WHERE table_name = 'sales';"
      }
    ],
    "scriptBlockExecutionTimeout": "02:00:00"
  },
  "linkedServiceName": {
    "referenceName": "WarehouseConnection",
    "type": "LinkedServiceReference"
  }
}
```

## Control Flow Activities

### If Condition

```json
{
  "name": "Check_File_Exists",
  "type": "IfCondition",
  "typeProperties": {
    "expression": {
      "value": "@equals(activity('GetMetadata').output.exists, true)",
      "type": "Expression"
    },
    "ifTrueActivities": [
      {
        "name": "Process_File",
        "type": "Copy"
      }
    ],
    "ifFalseActivities": [
      {
        "name": "Send_Missing_File_Alert",
        "type": "WebActivity"
      }
    ]
  },
  "dependsOn": [
    {
      "activity": "GetMetadata",
      "dependencyConditions": ["Succeeded"]
    }
  ]
}
```

### ForEach Loop

**Sequential :**
```json
{
  "name": "Process_Each_Country",
  "type": "ForEach",
  "typeProperties": {
    "items": {
      "value": "@pipeline().parameters.country_list",
      "type": "Expression"
    },
    "isSequential": true,
    "activities": [
      {
        "name": "Copy_Country_Data",
        "type": "Copy",
        "typeProperties": {
          "source": {
            "query": "SELECT * FROM sales WHERE country = '@{item()}'"
          }
        }
      }
    ]
  }
}
```

**Parallel :**
```json
{
  "name": "Process_Files_Parallel",
  "type": "ForEach",
  "typeProperties": {
    "items": {
      "value": "@activity('GetFileList').output.childItems",
      "type": "Expression"
    },
    "isSequential": false,
    "batchCount": 10,
    "activities": [
      {
        "name": "Copy_File",
        "type": "Copy"
      }
    ]
  }
}
```

### Until Loop

```json
{
  "name": "Wait_Until_File_Ready",
  "type": "Until",
  "typeProperties": {
    "expression": {
      "value": "@equals(activity('CheckFileStatus').output.status, 'Ready')",
      "type": "Expression"
    },
    "timeout": "01:00:00",
    "activities": [
      {
        "name": "CheckFileStatus",
        "type": "WebActivity"
      },
      {
        "name": "Wait_30_Seconds",
        "type": "Wait",
        "typeProperties": {
          "waitTimeInSeconds": 30
        }
      }
    ]
  }
}
```

### Switch Activity

```json
{
  "name": "Route_By_FileType",
  "type": "Switch",
  "typeProperties": {
    "on": {
      "value": "@pipeline().parameters.file_type",
      "type": "Expression"
    },
    "cases": [
      {
        "value": "CSV",
        "activities": [
          { "name": "Process_CSV", "type": "Copy" }
        ]
      },
      {
        "value": "JSON",
        "activities": [
          { "name": "Process_JSON", "type": "Copy" }
        ]
      },
      {
        "value": "PARQUET",
        "activities": [
          { "name": "Process_Parquet", "type": "Copy" }
        ]
      }
    ],
    "defaultActivities": [
      {
        "name": "Send_Unsupported_Format_Alert",
        "type": "WebActivity"
      }
    ]
  }
}
```

### Set Variable & Append Variable

```json
{
  "name": "Set_Processing_Date",
  "type": "SetVariable",
  "typeProperties": {
    "variableName": "processing_date",
    "value": {
      "value": "@formatDateTime(utcnow(), 'yyyy-MM-dd')",
      "type": "Expression"
    }
  }
}
```

```json
{
  "name": "Append_File_To_List",
  "type": "AppendVariable",
  "typeProperties": {
    "variableName": "processed_files",
    "value": {
      "value": "@item().name",
      "type": "Expression"
    }
  }
}
```

### Validation Activity

```json
{
  "name": "Validate_File_Exists",
  "type": "Validation",
  "typeProperties": {
    "dataset": {
      "referenceName": "InputFileDataset"
    },
    "timeout": "01:00:00",
    "sleep": 60,
    "minimumSize": 1024,
    "childItems": true
  }
}
```

## External Integration Activities

### Web Activity

**HTTP Request :**
```json
{
  "name": "Call_External_API",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://api.company.com/data/process",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "@{linkedService().properties.typeProperties.apiKey}"
    },
    "body": {
      "value": "@json(concat('{\"processing_date\":\"', variables('processing_date'), '\",\"batch_id\":', pipeline().RunId, '}'))",
      "type": "Expression"
    },
    "authentication": {
      "type": "ClientCertificate",
      "pfx": "@{linkedService().properties.typeProperties.encryptedCredential}",
      "password": "@{linkedService().properties.typeProperties.encryptedPassword}"
    }
  }
}
```

**Teams Notification :**
```json
{
  "name": "Send_Teams_Notification",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://outlook.office.com/webhook/...",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "value": "@concat('{\"text\":\"Pipeline ', pipeline().Pipeline, ' completed successfully. Rows processed: ', activity('Copy_Data').output.rowsCopied, '\"}')",
      "type": "Expression"
    }
  }
}
```

### Azure Function Activity

```json
{
  "name": "Call_Azure_Function",
  "type": "AzureFunctionActivity",
  "typeProperties": {
    "functionName": "ProcessData",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "value": "@json(concat('{\"table\":\"', pipeline().parameters.table_name, '\",\"date\":\"', variables('processing_date'), '\"}'))",
      "type": "Expression"
    }
  },
  "linkedServiceName": {
    "referenceName": "AzureFunctionLinkedService",
    "type": "LinkedServiceReference"
  }
}
```

### Webhook Activity

```json
{
  "name": "Call_External_Service_Webhook",
  "type": "WebHook",
  "typeProperties": {
    "url": "https://service.company.com/webhook/process",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "callbackUrl": "@{activity('WebHook').output.callBackUrl}"
    },
    "timeout": "00:10:00",
    "reportStatusOnCallBack": true
  }
}
```

## Metadata Activities

### Get Metadata

```json
{
  "name": "Get_File_Metadata",
  "type": "GetMetadata",
  "typeProperties": {
    "dataset": {
      "referenceName": "BlobFileDataset"
    },
    "fieldList": [
      "exists",
      "itemName",
      "itemType",
      "size",
      "lastModified",
      "childItems"
    ],
    "storeSettings": {
      "type": "AzureBlobStorageReadSettings",
      "recursive": true
    }
  }
}
```

**Utilisation dans Expression :**
```json
{
  "value": "@activity('Get_File_Metadata').output.size",
  "type": "Expression"
}
```

### Lookup Activity

```json
{
  "name": "Lookup_Config_Table",
  "type": "Lookup",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT * FROM config_tables WHERE active = 1"
    },
    "dataset": {
      "referenceName": "ConfigDatabase"
    },
    "firstRowOnly": false
  }
}
```

**Itérer sur résultats :**
```json
{
  "name": "Process_Each_Config",
  "type": "ForEach",
  "typeProperties": {
    "items": {
      "value": "@activity('Lookup_Config_Table').output.value",
      "type": "Expression"
    }
  }
}
```

## Fabric Workload Activities

### Lakehouse Activity

```json
{
  "name": "Load_To_Lakehouse",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "DelimitedTextSource"
    },
    "sink": {
      "type": "LakehouseSink",
      "tableActionOption": "Append",
      "writeBehavior": "Insert"
    }
  },
  "inputs": [
    { "referenceName": "CSVDataset" }
  ],
  "outputs": [
    { "referenceName": "LakehouseTable" }
  ]
}
```

### KQL Database Activity

```json
{
  "name": "Ingest_To_KQL",
  "type": "Script",
  "typeProperties": {
    "scripts": [
      {
        "type": "Query",
        "text": ".ingest async into table ['RealTimeEvents'] (@'https://storage.../events.csv') with (format='csv', ignoreFirstRecord=true)"
      }
    ]
  },
  "linkedServiceName": {
    "referenceName": "KQLDatabaseConnection"
  }
}
```

## Best Practices

### ✅ Activity Design

```
1. Modularité:
   • Une activity = une responsabilité
   • Réutiliser datasets
   • Paramétrer au maximum

2. Error Handling:
   • Retry policy sur activities instables
   • Timeout approprié
   • Dépendances conditionnelles (On Failure)

3. Performance:
   • Paralléliser quand possible (ForEach isSequential=false)
   • Optimiser DIU pour Copy activities
   • Utiliser staging pour grandes copies
```

### ✅ Naming Conventions

```
Activities:
  • Copy_[Source]_To_[Sink]
  • Transform_[Entity]
  • Validate_[Condition]
  • Send_[Notification]

Variables:
  • processing_date
  • file_count
  • error_message

Parameters:
  • source_table
  • target_environment
  • batch_size
```

## Points Clés

- Copy Data = activity la plus utilisée (DIU optimization)
- Notebook pour transformations Spark complexes
- Dataflow Gen2 pour transformations no-code
- Control flow (If/ForEach/Until) pour orchestration
- Web Activity pour intégrations externes
- Get Metadata + Lookup pour dynamic pipelines
- Error handling avec retry policies et dépendances
- Paramètres et variables pour flexibilité

---

**Prochain fichier :** [03 - Copy Activity Avancé](./03-copy-activity.md)

[⬅️ Fichier précédent](./01-data-factory-pipelines.md) | [⬅️ Retour au README du module](./README.md)
