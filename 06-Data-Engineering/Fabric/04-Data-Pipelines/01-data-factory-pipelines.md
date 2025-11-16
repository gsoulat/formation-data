# Data Factory Pipelines

## Introduction

**Data Factory** dans Fabric est le service d'orchestration pour créer des workflows ETL/ELT. C'est l'équivalent d'**Azure Data Factory** mais intégré nativement dans Fabric.

```
Data Factory Pipeline:
┌──────────────────────────────────────────┐
│         Pipeline (Orchestration)          │
├──────────────────────────────────────────┤
│  ┌────────┐  ┌────────┐  ┌─────────┐   │
│  │ Copy   │→ │Transform│→│ Notify  │   │
│  │ Data   │  │ Data    │  │ Team    │   │
│  └────────┘  └────────┘  └─────────┘   │
├──────────────────────────────────────────┤
│  Triggers: Schedule, Event, Manual       │
└──────────────────────────────────────────┘
```

## Concepts Fondamentaux

### Pipeline

Un **pipeline** est un workflow logique composé d'**activities** exécutées en séquence ou en parallèle.

```
Pipeline: Daily_ETL
├── Activity 1: Copy from SQL to Lakehouse
├── Activity 2: Transform with Dataflow
├── Activity 3: Load to Warehouse
└── Activity 4: Send email notification
```

### Activities

Les **activities** sont les tâches individuelles dans un pipeline.

**Types d'activities :**
- **Data Movement** : Copy Data
- **Data Transformation** : Dataflow, Notebook, Stored Procedure
- **Control Flow** : If Condition, ForEach, Until, Wait
- **External** : Web, Azure Function, Databricks

### Datasets

Les **datasets** représentent les structures de données (tables, fichiers).

```
Dataset: SQL_Customers
  ┣ Connection: SQL Server
  ┣ Table: dbo.customers
  ┗ Schema: [id, name, email, country]
```

### Linked Services

Les **linked services** sont les connexions aux sources de données.

```
Linked Service: OnPrem_SQL
  ┣ Type: SQL Server
  ┣ Server: sql.company.local
  ┣ Database: Production
  ┗ Authentication: SQL Auth
```

## Création d'un Pipeline

### Via UI

```
1. Workspace → + New item
2. Data pipeline
3. Nom: "ETL_Daily_Sales"
4. Create
```

**Interface Pipeline :**
```
┌───────────────────────────────────────────────┐
│  Pipeline Canvas                               │
│  ┌──────────┐      ┌──────────┐               │
│  │  Copy    │ ───→ │ Notebook │               │
│  │  Data    │      │  Process │               │
│  └──────────┘      └──────────┘               │
├───────────────────────────────────────────────┤
│  Activities Toolbox:                           │
│  [Copy Data] [Dataflow] [Notebook] [If]...    │
└───────────────────────────────────────────────┘
```

### Première Activity : Copy Data

```
1. Drag "Copy data" activity to canvas
2. Configure:
   ┣ Name: "Copy_SQL_to_Lakehouse"
   ┣ Source:
   │  ┣ Dataset: SQL_Sales
   │  ┗ Query: SELECT * FROM sales WHERE date >= '2024-01-01'
   ┗ Sink:
      ┣ Dataset: Lakehouse_Bronze
      ┗ Table: bronze_sales
3. Validate
4. Debug (test run)
```

## Structure d'un Pipeline

### JSON Définition

```json
{
  "name": "ETL_Daily_Sales",
  "properties": {
    "activities": [
      {
        "name": "Copy_Sales_Data",
        "type": "Copy",
        "inputs": [
          {
            "referenceName": "SQL_Sales",
            "type": "DatasetReference"
          }
        ],
        "outputs": [
          {
            "referenceName": "Lakehouse_Bronze_Sales",
            "type": "DatasetReference"
          }
        ],
        "typeProperties": {
          "source": {
            "type": "SqlSource",
            "sqlReaderQuery": "SELECT * FROM sales WHERE sale_date >= '@{formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')}'"
          },
          "sink": {
            "type": "LakehouseSink",
            "writeBehavior": "Append"
          }
        }
      }
    ]
  }
}
```

## Types d'Activities

### 1. Copy Data Activity

Copie données entre sources et destinations.

```
Copy Activity:
  Source (Input) → Copy → Sink (Output)

Exemples:
  • SQL → Lakehouse
  • CSV → Warehouse
  • API → Blob Storage
  • Lakehouse → SQL
```

**Configuration :**
```
Source:
  ┣ Type: SQL Server
  ┣ Connection: OnPrem_SQL
  ┣ Table/Query: sales_table
  ┗ Partition: date >= '2024-01-01'

Sink:
  ┣ Type: Lakehouse Table
  ┣ Lakehouse: Bronze_Lakehouse
  ┣ Table: bronze_sales
  ┗ Write mode: Append

Settings:
  ┣ Parallel copies: 4
  ┣ DIU (Data Integration Units): 8
  ┗ Fault tolerance: Skip incompatible rows
```

### 2. Notebook Activity

Exécute un Spark notebook.

```python
# Notebook: Transform_Bronze_to_Silver

from pyspark.sql.functions import *

# Read bronze
bronze_df = spark.table("bronze_sales")

# Transform
silver_df = bronze_df \
    .dropDuplicates(["sale_id"]) \
    .filter(col("amount") > 0) \
    .withColumn("sale_date", to_date(col("sale_date")))

# Write silver
silver_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("silver_sales")
```

**Dans Pipeline :**
```
Notebook Activity:
  ┣ Notebook: Transform_Bronze_to_Silver
  ┣ Lakehouse: Bronze_Lakehouse
  ┣ Parameters:
  │  ┗ processing_date: @pipeline().TriggerTime
  ┗ Depends on: Copy_Sales_Data (success)
```

### 3. Dataflow Activity

Exécute un Dataflow Gen2 (Power Query transformations).

```
Dataflow Activity:
  ┣ Dataflow: Clean_Customer_Data
  ┣ Refresh type: Full
  ┗ Destination: Lakehouse
```

### 4. Stored Procedure Activity

Exécute une stored procedure SQL.

```sql
-- Stored procedure
CREATE PROCEDURE sp_aggregate_daily_sales
    @processing_date DATE
AS
BEGIN
    INSERT INTO gold_daily_sales
    SELECT
        sale_date,
        SUM(amount) as total_sales,
        COUNT(*) as order_count
    FROM silver_sales
    WHERE sale_date = @processing_date
    GROUP BY sale_date;
END;
```

**Dans Pipeline :**
```
Stored Procedure Activity:
  ┣ Connection: Warehouse_Connection
  ┣ Procedure: sp_aggregate_daily_sales
  ┗ Parameters:
     ┗ processing_date: @formatDateTime(utcnow(), 'yyyy-MM-dd')
```

### 5. Control Flow Activities

**If Condition :**
```
If Activity: Check_File_Exists
  ┣ Condition: @equals(activity('GetMetadata').output.exists, true)
  ┣ If True:
  │  └─ Copy_Data activity
  ┗ If False:
     └─ Send_Alert_Email activity
```

**ForEach Loop :**
```
ForEach Activity: Process_Multiple_Files
  ┣ Items: @pipeline().parameters.file_list
  ┣ IsSequential: false (parallel)
  ┗ Activities:
     └─ Copy_Data (for each file)
```

**Until Loop :**
```
Until Activity: Wait_For_File
  ┣ Expression: @equals(activity('Check_File').output.exists, true)
  ┣ Timeout: 00:30:00
  ┗ Activities:
     ├─ Check_File (Get Metadata)
     └─ Wait (60 seconds)
```

## Pipeline Execution Flow

### Séquentiel

```
Activity 1 → Activity 2 → Activity 3

Connexions:
  Activity 1 [Success] → Activity 2
  Activity 2 [Success] → Activity 3
```

### Parallèle

```
          ┌─→ Activity 2
Activity 1 ┼─→ Activity 3
          └─→ Activity 4

Tous exécutent en parallèle après Activity 1
```

### Conditionnel

```
Activity 1
    ↓
  [If File Exists?]
    ↓         ↓
  YES       NO
    ↓         ↓
Activity 2  Activity 3
```

### Dépendances Complexes

```
Dépendances multiples:

Activity 1 ─┐
Activity 2 ─┼─→ Activity 4 (attend 1 ET 2 ET 3)
Activity 3 ─┘

Conditions de dépendance:
  • Success (green)
  • Failure (red)
  • Completion (blue)
  • Skipped (gray)
```

## Paramètres et Variables

### Pipeline Parameters

```json
{
  "parameters": {
    "processing_date": {
      "type": "String",
      "defaultValue": "@utcnow()"
    },
    "source_table": {
      "type": "String"
    },
    "batch_size": {
      "type": "Int",
      "defaultValue": 1000
    }
  }
}
```

**Utilisation :**
```
Dans query:
  SELECT * FROM @{pipeline().parameters.source_table}
  WHERE date = '@{pipeline().parameters.processing_date}'
```

### Variables

```json
{
  "variables": {
    "file_count": {
      "type": "Integer",
      "defaultValue": 0
    },
    "error_message": {
      "type": "String"
    }
  }
}
```

**Set Variable Activity :**
```
Set Variable: Increment_Counter
  ┣ Variable: file_count
  ┗ Value: @add(variables('file_count'), 1)
```

## Déclencheurs (Triggers)

### 1. Schedule Trigger

```json
{
  "name": "Daily_8AM_Trigger",
  "type": "ScheduleTrigger",
  "properties": {
    "recurrence": {
      "frequency": "Day",
      "interval": 1,
      "schedule": {
        "hours": [8],
        "minutes": [0]
      },
      "timeZone": "Central European Standard Time"
    }
  }
}
```

**Exemples :**
```
Daily à 8h:
  Frequency: Day, Interval: 1, Hour: 8

Toutes les heures:
  Frequency: Hour, Interval: 1

Lundi et Vendredi à 9h:
  Frequency: Week, Days: [Monday, Friday], Hour: 9

Premier jour du mois:
  Frequency: Month, MonthDays: [1], Hour: 6
```

### 2. Event Trigger

```json
{
  "name": "OnNewFile_Trigger",
  "type": "BlobEventsTrigger",
  "properties": {
    "events": ["Microsoft.Storage.BlobCreated"],
    "scope": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{storage}",
    "blobPathBeginsWith": "/container/folder/",
    "blobPathEndsWith": ".csv"
  }
}
```

**Use case :**
```
Trigger pipeline quand:
  • Nouveau fichier dans blob storage
  • Fichier dans OneLake
  • Event Grid event
```

### 3. Tumbling Window Trigger

```json
{
  "name": "Hourly_Tumbling_Window",
  "type": "TumblingWindowTrigger",
  "properties": {
    "frequency": "Hour",
    "interval": 1,
    "startTime": "2024-01-01T00:00:00Z",
    "delay": "00:05:00",
    "maxConcurrency": 1,
    "retryPolicy": {
      "count": 3,
      "intervalInSeconds": 30
    }
  }
}
```

**Avantages :**
```
• Window-based execution
• Automatique retry
• Dependency sur autres windows
• Backfill support
```

## Monitoring et Debugging

### Debug Mode

```
Debug Pipeline:
1. Click "Debug" button
2. Provide parameter values
3. Pipeline exécute en mode debug
4. Voir output de chaque activity en real-time
```

**Debug Output :**
```
Copy_Data activity:
  ✅ Success
  Duration: 45s
  Rows read: 100,000
  Rows written: 100,000
  Throughput: 2,222 rows/sec
```

### Monitoring View

```
Pipeline Runs:
┌─────────────┬────────┬──────────┬─────────┐
│ Run ID      │ Status │ Duration │ Trigger │
├─────────────┼────────┼──────────┼─────────┤
│ abc-123     │ ✅     │ 5m 23s   │ Manual  │
│ abc-122     │ ✅     │ 4m 56s   │ Schedule│
│ abc-121     │ ❌     │ 2m 10s   │ Schedule│
└─────────────┴────────┴──────────┴─────────┘

Click run → Voir activity details:
  ├─ Copy_Data: ✅ (45s)
  ├─ Notebook: ✅ (3m)
  └─ Send_Email: ✅ (2s)
```

### Logs et Diagnostics

```
Activity Output:
{
  "effectiveIntegrationRuntime": "AutoResolveIntegrationRuntime",
  "executionDuration": 45,
  "durationInQueue": {
    "integrationRuntimeQueue": 1
  },
  "billingReference": {
    "activityType": "DataMovement",
    "billableDuration": [
      {
        "meterType": "DIU",
        "duration": 0.125,
        "unit": "DIUHours"
      }
    ]
  },
  "dataRead": 104857600,
  "dataWritten": 104857600,
  "rowsCopied": 100000,
  "throughput": 2222
}
```

## Gestion des Erreurs

### Retry Policy

```json
{
  "activities": [
    {
      "name": "Copy_Data_With_Retry",
      "type": "Copy",
      "policy": {
        "timeout": "01:00:00",
        "retry": 3,
        "retryIntervalInSeconds": 60
      }
    }
  ]
}
```

### Dépendances sur Failure

```
Copy_Data
    ↓ [On Failure]
Send_Error_Email

Configuration:
  Activity: Send_Error_Email
  Depends on: Copy_Data (Failed condition)
```

### Try-Catch Pattern

```
Pipeline pattern:

Try:
  ├─ Copy_Data
  └─ Transform_Data

On Success:
  └─ Send_Success_Notification

On Failure:
  ├─ Log_Error
  └─ Send_Alert_Email
```

## Best Practices

### ✅ Design Patterns

```
1. Modularité:
   Pipeline_Master
     ├─ Execute Pipeline: Extract_Data
     ├─ Execute Pipeline: Transform_Data
     └─ Execute Pipeline: Load_Data

2. Idempotence:
   • Utiliser MERGE au lieu de INSERT
   • Truncate-and-load avec transaction
   • Upsert patterns

3. Logging:
   • Log start/end times
   • Log row counts
   • Log errors avec context
```

### ✅ Performance

```
• Utiliser parallelism (ForEach IsSequential=false)
• Optimiser DIU pour Copy activities
• Partitionner grandes tables
• Utiliser incremental loads (watermark)
```

### ❌ Anti-Patterns

```
❌ Éviter:
  • Trop d'activities dans un pipeline (> 40)
  • Nested loops profonds
  • Pas de error handling
  • Hard-coded values (utiliser parameters)
  • Long-running notebooks sans checkpoints
```

## Exemples Complets

### Pipeline ETL Complet

```
Pipeline: Daily_Sales_ETL

1. Get_Processing_Date (Set Variable)
   └─ Value: @formatDateTime(utcnow(), 'yyyy-MM-dd')

2. Copy_SQL_to_Bronze (Copy Data)
   └─ Source: SQL Server
   └─ Sink: Lakehouse bronze_sales

3. Transform_Bronze_to_Silver (Notebook)
   └─ Clean, deduplicate, validate

4. Load_Silver_to_Warehouse (Copy Data)
   └─ Source: Lakehouse silver_sales
   └─ Sink: Warehouse fact_sales

5. Run_Aggregations (Stored Procedure)
   └─ sp_aggregate_daily_metrics

6. Success_Notification (Web Activity)
   └─ POST to Teams webhook

On Failure:
  └─ Error_Notification (Web Activity)
     └─ Send alert email
```

## Points Clés

- Pipeline = orchestration de workflows ETL/ELT
- Activities = tâches individuelles (Copy, Transform, Control)
- Triggers = Schedule, Event, Manual, Tumbling Window
- Paramètres pour flexibilité et réutilisabilité
- Debug mode pour développement
- Monitoring pour production
- Error handling essentiel
- Modularité et idempotence = bonnes pratiques

---

**Prochain fichier :** [02 - Activities et Transformations](./02-activities-transformations.md)

[⬅️ Retour au README du module](./README.md)
