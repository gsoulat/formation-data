# Paramètres et Variables

## Introduction

Les **paramètres** et **variables** permettent de créer des pipelines **dynamiques** et **réutilisables**.

```
Paramètres:
  • Input values (passés à l'exécution)
  • Immutables durant l'exécution
  • Définis au niveau pipeline

Variables:
  • Valeurs mutables
  • Modifiées durant l'exécution
  • Scope: pipeline entier
```

## Pipeline Parameters

### Définition

```json
{
  "name": "ETL_Generic_Pipeline",
  "properties": {
    "parameters": {
      "processing_date": {
        "type": "String",
        "defaultValue": "@utcnow()"
      },
      "source_table": {
        "type": "String"
      },
      "target_environment": {
        "type": "String",
        "defaultValue": "dev"
      },
      "batch_size": {
        "type": "Int",
        "defaultValue": 1000
      },
      "enable_logging": {
        "type": "Bool",
        "defaultValue": true
      },
      "config_array": {
        "type": "Array",
        "defaultValue": ["table1", "table2", "table3"]
      },
      "connection_settings": {
        "type": "Object",
        "defaultValue": {
          "server": "sql.company.com",
          "database": "Production",
          "timeout": 300
        }
      }
    }
  }
}
```

### Types de Paramètres

```
String:
  "source_table": { "type": "String", "defaultValue": "sales" }

Int:
  "batch_size": { "type": "Int", "defaultValue": 1000 }

Float:
  "threshold": { "type": "Float", "defaultValue": 0.95 }

Bool:
  "enable_debug": { "type": "Bool", "defaultValue": false }

Array:
  "regions": { "type": "Array", "defaultValue": ["EMEA", "APAC", "AMER"] }

Object:
  "config": { "type": "Object", "defaultValue": {"key": "value"} }
```

### Utilisation dans Activities

```json
{
  "name": "Copy_Dynamic_Table",
  "type": "Copy",
  "typeProperties": {
    "source": {
      "type": "SqlSource",
      "sqlReaderQuery": "SELECT * FROM @{pipeline().parameters.source_table} WHERE date >= '@{pipeline().parameters.processing_date}'"
    },
    "sink": {
      "type": "LakehouseSink",
      "tableName": "@{concat('bronze_', pipeline().parameters.source_table)}"
    }
  }
}
```

### Passer Paramètres

**Via UI (Debug) :**
```
Pipeline → Debug button

Prompt:
  processing_date: [2024-01-15]
  source_table: [sales]
  batch_size: [500]
```

**Via Trigger :**
```json
{
  "name": "Daily_Trigger",
  "properties": {
    "pipelines": [
      {
        "pipelineReference": {
          "referenceName": "ETL_Generic_Pipeline"
        },
        "parameters": {
          "processing_date": "@formatDateTime(utcnow(), 'yyyy-MM-dd')",
          "source_table": "daily_sales",
          "batch_size": 2000
        }
      }
    ]
  }
}
```

**Via Execute Pipeline Activity :**
```json
{
  "name": "Execute_Child_Pipeline",
  "type": "ExecutePipeline",
  "typeProperties": {
    "pipeline": {
      "referenceName": "ETL_Generic_Pipeline"
    },
    "parameters": {
      "processing_date": {
        "value": "@pipeline().parameters.date",
        "type": "Expression"
      },
      "source_table": {
        "value": "orders",
        "type": "String"
      },
      "batch_size": {
        "value": "@int(pipeline().parameters.batch)",
        "type": "Expression"
      }
    }
  }
}
```

**Via REST API :**
```bash
POST https://management.azure.com/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.DataFactory/factories/{factory}/pipelines/{pipeline}/createRun?api-version=2018-06-01

Body:
{
  "processing_date": "2024-01-15",
  "source_table": "sales",
  "batch_size": 1000
}
```

## Pipeline Variables

### Définition

```json
{
  "name": "Pipeline_With_Variables",
  "properties": {
    "variables": {
      "file_count": {
        "type": "Integer",
        "defaultValue": 0
      },
      "error_message": {
        "type": "String"
      },
      "processing_status": {
        "type": "String",
        "defaultValue": "Started"
      },
      "processed_files": {
        "type": "Array",
        "defaultValue": []
      },
      "watermark_datetime": {
        "type": "String"
      },
      "is_successful": {
        "type": "Boolean",
        "defaultValue": false
      }
    }
  }
}
```

### Set Variable Activity

```json
{
  "name": "Set_File_Count",
  "type": "SetVariable",
  "typeProperties": {
    "variableName": "file_count",
    "value": {
      "value": "@activity('GetMetadata').output.childItems.length",
      "type": "Expression"
    }
  }
}
```

```json
{
  "name": "Set_Processing_Status",
  "type": "SetVariable",
  "typeProperties": {
    "variableName": "processing_status",
    "value": {
      "value": "@if(greater(variables('file_count'), 0), 'Processing', 'No files to process')",
      "type": "Expression"
    }
  }
}
```

### Append Variable Activity

```json
{
  "name": "Append_Processed_File",
  "type": "AppendVariable",
  "typeProperties": {
    "variableName": "processed_files",
    "value": {
      "value": "@concat(item().name, ' - Processed at ', utcnow())",
      "type": "Expression"
    }
  }
}
```

**Use case dans ForEach :**
```json
{
  "activities": [
    {
      "name": "ForEach_File",
      "type": "ForEach",
      "typeProperties": {
        "items": {
          "value": "@activity('GetFileList').output.childItems",
          "type": "Expression"
        },
        "activities": [
          {
            "name": "Process_File",
            "type": "Copy"
          },
          {
            "name": "Track_Processed_File",
            "type": "AppendVariable",
            "typeProperties": {
              "variableName": "processed_files",
              "value": "@item().name"
            }
          }
        ]
      }
    }
  ]
}
```

## System Variables

### Pipeline System Variables

```
@pipeline().Pipeline
  → Nom du pipeline

@pipeline().RunId
  → ID unique de l'exécution (GUID)

@pipeline().TriggerType
  → "ScheduleTrigger", "ManualTrigger", "BlobEventsTrigger", etc.

@pipeline().TriggerName
  → Nom du trigger qui a déclenché

@pipeline().TriggerTime
  → Timestamp du déclenchement

@pipeline().parameters.{param_name}
  → Valeur d'un paramètre

@pipeline().GroupId
  → Workspace ID (Fabric)

@pipeline().DataFactory
  → Nom de la factory/workspace
```

**Exemple :**
```sql
INSERT INTO pipeline_log
VALUES (
    '@{pipeline().RunId}',
    '@{pipeline().Pipeline}',
    '@{pipeline().TriggerType}',
    '@{pipeline().TriggerTime}'
);
```

### Activity System Variables

```
@activity('{activity_name}').output
  → Output de l'activity

@activity('{activity_name}').output.{property}
  → Propriété spécifique

@activity('{activity_name}').error
  → Erreur si failed

@activity('{activity_name}').error.message
  → Message d'erreur

@activity('{activity_name}').error.errorCode
  → Code d'erreur
```

**Exemple :**
```json
{
  "name": "Log_Copy_Results",
  "type": "Script",
  "typeProperties": {
    "scripts": [{
      "text": "INSERT INTO copy_log VALUES ('@{activity('Copy_Data').output.rowsCopied}', '@{activity('Copy_Data').output.dataRead}')"
    }]
  },
  "dependsOn": [
    { "activity": "Copy_Data", "dependencyConditions": ["Succeeded"] }
  ]
}
```

### Trigger System Variables

```
@trigger().startTime
  → Start time du trigger

@trigger().endTime
  → End time (Tumbling Window)

@trigger().scheduledTime
  → Scheduled time

@trigger().outputs.windowStartTime
  → Window start (Tumbling Window)

@trigger().outputs.windowEndTime
  → Window end (Tumbling Window)

@triggerBody()
  → Event data (Event triggers)

@triggerBody().fileName
  → File name (Blob trigger)

@triggerBody().folderPath
  → Folder path (Blob trigger)
```

**Tumbling Window Example :**
```sql
SELECT * FROM events
WHERE event_time >= '@{trigger().outputs.windowStartTime}'
  AND event_time < '@{trigger().outputs.windowEndTime}'
```

**Blob Event Example :**
```json
{
  "name": "Process_New_File",
  "typeProperties": {
    "source": {
      "fileName": "@triggerBody().fileName",
      "folderPath": "@triggerBody().folderPath"
    }
  }
}
```

## Expressions et Functions

### String Functions

```javascript
// Concatenation
@concat('prefix_', pipeline().parameters.table_name, '_suffix')
→ "prefix_sales_suffix"

// Substring
@substring('HelloWorld', 0, 5)
→ "Hello"

// Replace
@replace(pipeline().parameters.file_name, '.csv', '.parquet')
→ "data.parquet"

// ToUpper / ToLower
@toUpper('hello')
→ "HELLO"

@toLower('WORLD')
→ "world"

// Trim
@trim('  spaces  ')
→ "spaces"

// Length
@length('Hello')
→ 5

// Split
@split('a,b,c', ',')
→ ["a", "b", "c"]

// Join
@join(array('a', 'b', 'c'), '-')
→ "a-b-c"
```

### Logical Functions

```javascript
// Equals
@equals(pipeline().parameters.environment, 'prod')
→ true/false

// Not
@not(variables('is_successful'))
→ inverse boolean

// If
@if(greater(variables('file_count'), 0), 'Process', 'Skip')
→ "Process" ou "Skip"

// And
@and(equals(pipeline().parameters.env, 'prod'), variables('is_weekend'))
→ true/false

// Or
@or(equals(variables('status'), 'Failed'), equals(variables('status'), 'Cancelled'))
→ true/false

// Greater / Less
@greater(variables('file_count'), 10)
@less(variables('retry_count'), 3)
@greaterOrEquals(variables('score'), 80)
@lessOrEquals(variables('age'), 18)
```

### Numeric Functions

```javascript
// Add / Sub / Mul / Div
@add(variables('count'), 1)
→ count + 1

@sub(100, variables('discount'))
→ 100 - discount

@mul(variables('price'), 1.2)
→ price * 1.2

@div(variables('total'), variables('quantity'))
→ total / quantity

// Mod
@mod(variables('row_number'), 10)
→ row_number % 10

// Min / Max
@min(10, variables('batch_size'))
@max(1, variables('retry_count'))

// Range
@range(1, 10)
→ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// Int / Float
@int('123')
→ 123

@float('123.45')
→ 123.45
```

### Date/Time Functions

```javascript
// Current time
@utcnow()
→ "2024-01-15T14:30:00Z"

// Format DateTime
@formatDateTime(utcnow(), 'yyyy-MM-dd')
→ "2024-01-15"

@formatDateTime(utcnow(), 'yyyy/MM/dd HH:mm:ss')
→ "2024/01/15 14:30:00"

// Add Days/Hours/Minutes
@addDays(utcnow(), -1)
→ Yesterday

@addHours(utcnow(), 2)
→ 2 hours from now

@addMinutes(utcnow(), 30)
→ 30 minutes from now

// Start/End of period
@startOfDay(utcnow())
→ "2024-01-15T00:00:00Z"

@startOfMonth(utcnow())
→ "2024-01-01T00:00:00Z"

@startOfHour(utcnow())
→ "2024-01-15T14:00:00Z"

// Day/Month/Year
@dayOfMonth(utcnow())
→ 15

@dayOfWeek(utcnow())
→ 1 (Monday = 1, Sunday = 7)

@dayOfYear(utcnow())
→ 15

// Ticks (Unix timestamp)
@ticks(utcnow())
→ 638408730000000000
```

### Array Functions

```javascript
// Length
@length(pipeline().parameters.regions)
→ Number of elements

// Contains
@contains(array('a', 'b', 'c'), 'b')
→ true

// First / Last
@first(array(1, 2, 3))
→ 1

@last(array(1, 2, 3))
→ 3

// Take / Skip
@take(array(1, 2, 3, 4, 5), 3)
→ [1, 2, 3]

@skip(array(1, 2, 3, 4, 5), 2)
→ [3, 4, 5]

// Union / Intersection
@union(array('a', 'b'), array('b', 'c'))
→ ['a', 'b', 'c']

@intersection(array('a', 'b'), array('b', 'c'))
→ ['b']
```

### JSON Functions

```javascript
// Parse JSON string
@json('{"name":"John","age":30}')
→ Object

// Access property
@json(pipeline().parameters.config).server
→ Value of "server" property

// Stringify
@string(variables('config_object'))
→ JSON string
```

## Dynamic Content Patterns

### Pattern 1 : Dynamic Table Names

```json
{
  "source": {
    "query": "SELECT * FROM @{concat('sales_', formatDateTime(utcnow(), 'yyyyMM'))}"
  }
}
```
→ `SELECT * FROM sales_202401`

### Pattern 2 : Dynamic File Paths

```json
{
  "folderPath": "@{concat('bronze/', pipeline().parameters.source_system, '/', formatDateTime(utcnow(), 'yyyy/MM/dd'))}"
}
```
→ `bronze/SAP/2024/01/15/`

### Pattern 3 : Conditional Logic

```json
{
  "tableName": "@{if(equals(pipeline().parameters.environment, 'prod'), 'fact_sales', 'fact_sales_dev')}"
}
```

### Pattern 4 : Dynamic Query Building

```json
{
  "query": "@{concat('SELECT * FROM sales WHERE ', if(empty(pipeline().parameters.region), '1=1', concat('region = ''', pipeline().parameters.region, '''')), ' AND date >= ''', pipeline().parameters.start_date, '''')}"
}
```

**Résultat sans region :**
```sql
SELECT * FROM sales WHERE 1=1 AND date >= '2024-01-01'
```

**Résultat avec region :**
```sql
SELECT * FROM sales WHERE region = 'EMEA' AND date >= '2024-01-01'
```

### Pattern 5 : Looping avec Range

```json
{
  "name": "Process_Last_7_Days",
  "type": "ForEach",
  "typeProperties": {
    "items": {
      "value": "@range(0, 7)",
      "type": "Expression"
    },
    "activities": [
      {
        "name": "Process_Day",
        "type": "Copy",
        "typeProperties": {
          "source": {
            "query": "SELECT * FROM sales WHERE date = '@{formatDateTime(addDays(utcnow(), mul(item(), -1)), 'yyyy-MM-dd')}'"
          }
        }
      }
    ]
  }
}
```

## Configuration-Driven Pipelines

### Metadata Table Pattern

**Config Table :**
```sql
CREATE TABLE pipeline_config (
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    source_query VARCHAR(MAX),
    partition_column VARCHAR(50),
    active BIT
);

INSERT INTO pipeline_config VALUES
('dbo.customers', 'bronze_customers', 'SELECT * FROM dbo.customers WHERE date >= ''@date''', 'customer_id', 1),
('dbo.orders', 'bronze_orders', 'SELECT * FROM dbo.orders WHERE date >= ''@date''', 'order_id', 1),
('dbo.products', 'bronze_products', 'SELECT * FROM dbo.products', NULL, 1);
```

**Pipeline :**
```json
{
  "activities": [
    {
      "name": "Lookup_Config",
      "type": "Lookup",
      "typeProperties": {
        "source": {
          "query": "SELECT * FROM pipeline_config WHERE active = 1"
        },
        "firstRowOnly": false
      }
    },
    {
      "name": "ForEach_Table",
      "type": "ForEach",
      "typeProperties": {
        "items": {
          "value": "@activity('Lookup_Config').output.value",
          "type": "Expression"
        },
        "activities": [
          {
            "name": "Copy_Dynamic",
            "type": "Copy",
            "typeProperties": {
              "source": {
                "query": "@replace(item().source_query, '@date', pipeline().parameters.processing_date)"
              },
              "sink": {
                "tableName": "@item().target_table"
              }
            }
          }
        ]
      }
    }
  ]
}
```

## Best Practices

### ✅ Naming Conventions

```
Parameters:
  • camelCase ou snake_case
  • Descriptifs: processing_date, source_table
  • Pas de: p1, param, x

Variables:
  • snake_case recommandé
  • Prefixes pour scope: temp_file_count, final_status
  • Descriptifs et clairs

Expressions:
  • Commentaires si complexe
  • Découper en étapes si > 3 fonctions imbriquées
```

### ✅ Default Values

```json
{
  "parameters": {
    "processing_date": {
      "type": "String",
      "defaultValue": "@formatDateTime(utcnow(), 'yyyy-MM-dd')"
    },
    "batch_size": {
      "type": "Int",
      "defaultValue": 1000
    },
    "enable_debug": {
      "type": "Bool",
      "defaultValue": false
    }
  }
}
```

→ Pipeline peut run sans paramètres obligatoires

### ✅ Type Safety

```javascript
// ❌ Mauvais
@activity('Lookup').output.count  // Peut être string!

// ✅ Bon
@int(activity('Lookup').output.count)  // Force Int

// ✅ Safe null check
@if(empty(activity('Lookup').output), 0, int(activity('Lookup').output.count))
```

### ✅ Reusability

```
Créer pipelines génériques:
  • Generic_Copy_SQL_to_Lakehouse
    └─ Parameters: source_query, target_table, partition_columns
  • Generic_Transform_Bronze_to_Silver
    └─ Parameters: source_table, target_table, business_rules

Appeler depuis Master:
  • Execute_Pipeline avec parameters différents
```

## Points Clés

- Parameters = input values (immutables)
- Variables = mutable state durant exécution
- System variables (@pipeline, @activity, @trigger)
- Rich expression language (string, math, date, logic)
- Dynamic content avec @{...} syntax
- Configuration-driven pipelines via metadata
- Type safety important (@int, @float, @bool)
- Default values pour flexibilité
- Naming conventions pour lisibilité
- Reusability via paramètres génériques

---

**Prochain fichier :** [07 - Monitoring et Alerting](./07-monitoring-alerts.md)

[⬅️ Fichier précédent](./05-orchestration-scheduling.md) | [⬅️ Retour au README du module](./README.md)
