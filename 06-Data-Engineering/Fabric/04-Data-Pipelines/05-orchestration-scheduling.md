# Orchestration et Scheduling

## Introduction

L'**orchestration** permet de coordonner plusieurs pipelines et workflows. Le **scheduling** automatise l'exécution via triggers.

```
Orchestration Architecture:
┌─────────────────────────────────────────┐
│       Master Pipeline                    │
├─────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌────────┐│
│  │ Extract  │→ │Transform │→ │  Load  ││
│  │ Pipeline │  │ Pipeline │  │Pipeline││
│  └──────────┘  └──────────┘  └────────┘│
├─────────────────────────────────────────┤
│  Trigger: Schedule (Daily 8AM)          │
└─────────────────────────────────────────┘
```

## Types de Triggers

### 1. Schedule Trigger

Exécution basée sur un calendrier.

**Configuration Basique :**
```json
{
  "name": "Daily_8AM_Trigger",
  "type": "ScheduleTrigger",
  "typeProperties": {
    "recurrence": {
      "frequency": "Day",
      "interval": 1,
      "startTime": "2024-01-01T08:00:00Z",
      "endTime": "2024-12-31T23:59:59Z",
      "timeZone": "Central European Standard Time",
      "schedule": {
        "hours": [8],
        "minutes": [0]
      }
    }
  },
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "ETL_Daily_Sales",
        "type": "PipelineReference"
      }
    }
  ]
}
```

**Fréquences Supportées :**

```
Minute:
  frequency: "Minute"
  interval: 15
  → Every 15 minutes

Hour:
  frequency: "Hour"
  interval: 2
  → Every 2 hours

Day:
  frequency: "Day"
  interval: 1
  schedule: { hours: [8, 14, 20] }
  → Daily at 8AM, 2PM, 8PM

Week:
  frequency: "Week"
  interval: 1
  schedule: {
    weekDays: ["Monday", "Wednesday", "Friday"],
    hours: [9]
  }
  → Mon/Wed/Fri at 9AM

Month:
  frequency: "Month"
  interval: 1
  schedule: {
    monthDays: [1, 15],
    hours: [6]
  }
  → 1st and 15th of month at 6AM
```

**Exemples Pratiques :**

```json
// Every business day at 7AM
{
  "recurrence": {
    "frequency": "Week",
    "interval": 1,
    "schedule": {
      "weekDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "hours": [7],
      "minutes": [0]
    },
    "timeZone": "Eastern Standard Time"
  }
}

// First Monday of every month
{
  "recurrence": {
    "frequency": "Month",
    "interval": 1,
    "schedule": {
      "monthlyOccurrences": [
        {
          "day": "Monday",
          "occurrence": 1
        }
      ],
      "hours": [6]
    }
  }
}

// Every 6 hours
{
  "recurrence": {
    "frequency": "Hour",
    "interval": 6,
    "startTime": "2024-01-01T00:00:00Z"
  }
}

// Weekend batch (Sat/Sun at midnight)
{
  "recurrence": {
    "frequency": "Week",
    "interval": 1,
    "schedule": {
      "weekDays": ["Saturday", "Sunday"],
      "hours": [0],
      "minutes": [0]
    }
  }
}
```

### 2. Event-Based Trigger

Déclenché par événements (fichiers, messages, etc.).

**Blob Event Trigger :**
```json
{
  "name": "OnNewFile_Trigger",
  "type": "BlobEventsTrigger",
  "typeProperties": {
    "blobPathBeginsWith": "/container/incoming/",
    "blobPathEndsWith": ".csv",
    "ignoreEmptyBlobs": true,
    "scope": "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{storage}",
    "events": [
      "Microsoft.Storage.BlobCreated"
    ]
  },
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "Process_Incoming_File",
        "type": "PipelineReference"
      },
      "parameters": {
        "fileName": "@triggerBody().fileName",
        "folderPath": "@triggerBody().folderPath"
      }
    }
  ]
}
```

**Custom Event Trigger (Event Grid) :**
```json
{
  "name": "CustomEvent_Trigger",
  "type": "CustomEventsTrigger",
  "typeProperties": {
    "subjectBeginsWith": "/sales/",
    "subjectEndsWith": "/completed",
    "events": [
      "OrderCompleted",
      "PaymentProcessed"
    ],
    "scope": "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.EventGrid/topics/sales-events"
  },
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "Process_Order",
        "type": "PipelineReference"
      },
      "parameters": {
        "eventData": "@triggerBody()"
      }
    }
  ]
}
```

### 3. Tumbling Window Trigger

Exécution périodique avec fenêtres de temps fixes et gestion automatique des retries.

```json
{
  "name": "Hourly_Tumbling_Window",
  "type": "TumblingWindowTrigger",
  "typeProperties": {
    "frequency": "Hour",
    "interval": 1,
    "startTime": "2024-01-01T00:00:00Z",
    "delay": "00:05:00",
    "maxConcurrency": 1,
    "retryPolicy": {
      "count": 3,
      "intervalInSeconds": 300
    },
    "dependsOn": [
      {
        "type": "TumblingWindowTriggerDependencyReference",
        "referenceTrigger": {
          "referenceName": "Upstream_Hourly_Trigger",
          "type": "TriggerReference"
        },
        "offset": "-01:00:00"
      }
    ]
  },
  "pipeline": {
    "pipelineReference": {
      "referenceName": "Process_Hourly_Data",
      "type": "PipelineReference"
    },
    "parameters": {
      "windowStart": "@trigger().outputs.windowStartTime",
      "windowEnd": "@trigger().outputs.windowEndTime"
    }
  }
}
```

**Caractéristiques Tumbling Window :**

```
Avantages:
  ✅ Window-based execution (pas de overlap)
  ✅ Automatique retry avec backoff
  ✅ Dependencies sur autres triggers
  ✅ Backfill support (re-process historical windows)
  ✅ Garanties exactly-once

Use cases:
  • Time-series data processing
  • Aggregations horaires/quotidiennes
  • Workflows avec dépendances temporelles
  • CDC incremental avec windows
```

**Tumbling Window Expressions :**
```
@trigger().outputs.windowStartTime
  → 2024-01-15T10:00:00Z

@trigger().outputs.windowEndTime
  → 2024-01-15T11:00:00Z

Example pipeline query:
SELECT * FROM events
WHERE event_time >= '@{trigger().outputs.windowStartTime}'
  AND event_time < '@{trigger().outputs.windowEndTime}'
```

### 4. Manual Trigger

```json
{
  "name": "Manual_Trigger",
  "type": "ManualTrigger",
  "pipelines": [
    {
      "pipelineReference": {
        "referenceName": "Ad_Hoc_Process",
        "type": "PipelineReference"
      }
    }
  ]
}
```

## Execute Pipeline Activity

### Orchestration Master-Child

```
Master Pipeline:
├─ Execute Pipeline: Extract_Data
├─ Execute Pipeline: Transform_Data
└─ Execute Pipeline: Load_Data
```

**Configuration :**
```json
{
  "name": "Execute_Extract_Pipeline",
  "type": "ExecutePipeline",
  "typeProperties": {
    "pipeline": {
      "referenceName": "Extract_Sales_Data",
      "type": "PipelineReference"
    },
    "waitOnCompletion": true,
    "parameters": {
      "processing_date": {
        "value": "@pipeline().parameters.date",
        "type": "Expression"
      },
      "source_system": {
        "value": "SAP",
        "type": "String"
      }
    }
  }
}
```

**waitOnCompletion :**
```
true:  Master attend fin du child
false: Master continue immédiatement (fire-and-forget)

Exemple:
  waitOnCompletion: true
    Master: 8:00 → Start Child
    Child: 8:00-8:30 (process)
    Master: 8:30 → Continue next activity

  waitOnCompletion: false
    Master: 8:00 → Start Child → Continue immediately
    Child: 8:00-8:30 (process en background)
```

### Parallel Execution

```json
{
  "activities": [
    {
      "name": "Process_Region_EMEA",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Process_Region" },
        "parameters": { "region": "EMEA" }
      }
    },
    {
      "name": "Process_Region_APAC",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Process_Region" },
        "parameters": { "region": "APAC" }
      }
    },
    {
      "name": "Process_Region_AMER",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Process_Region" },
        "parameters": { "region": "AMER" }
      }
    }
  ]
}
```

**Note :** Les trois pipelines s'exécutent en parallèle car aucune dépendance.

### Sequential with Dependencies

```json
{
  "activities": [
    {
      "name": "Extract",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Extract_Pipeline" }
      }
    },
    {
      "name": "Transform",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Transform_Pipeline" }
      },
      "dependsOn": [
        {
          "activity": "Extract",
          "dependencyConditions": ["Succeeded"]
        }
      ]
    },
    {
      "name": "Load",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Load_Pipeline" }
      },
      "dependsOn": [
        {
          "activity": "Transform",
          "dependencyConditions": ["Succeeded"]
        }
      ]
    }
  ]
}
```

## Orchestration Patterns

### Pattern 1 : Master ETL Pipeline

```
Master_ETL_Daily:

1. Validate_Prerequisites
   ├─ Check source files exist
   ├─ Check database connectivity
   └─ Verify capacity available

2. Extract (Parallel)
   ├─ Execute: Extract_SQL_Sales
   ├─ Execute: Extract_API_Customers
   └─ Execute: Extract_File_Products

3. Transform (Sequential)
   ├─ Execute: Transform_Bronze_to_Silver
   └─ Execute: Transform_Silver_to_Gold

4. Load (Parallel)
   ├─ Execute: Load_to_Warehouse
   └─ Execute: Load_to_Lakehouse

5. Post_Processing
   ├─ Execute: Update_Metadata
   ├─ Execute: Refresh_Power_BI
   └─ Send_Completion_Notification
```

**Implementation :**
```json
{
  "name": "Master_ETL_Daily",
  "activities": [
    {
      "name": "Validate_Prerequisites",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Validation_Pipeline" },
        "waitOnCompletion": true
      }
    },
    {
      "name": "Extract_Parallel",
      "type": "ForEach",
      "typeProperties": {
        "items": {
          "value": "@pipeline().parameters.source_list",
          "type": "Expression"
        },
        "isSequential": false,
        "batchCount": 5,
        "activities": [
          {
            "name": "Execute_Extract",
            "type": "ExecutePipeline",
            "typeProperties": {
              "pipeline": { "referenceName": "Extract_Generic" },
              "parameters": {
                "source": "@item().source_name"
              }
            }
          }
        ]
      },
      "dependsOn": [
        { "activity": "Validate_Prerequisites", "dependencyConditions": ["Succeeded"] }
      ]
    }
  ]
}
```

### Pattern 2 : Dynamic Pipeline Execution

```
Configuration-Driven ETL:

1. Lookup_Config_Table
   └─ SELECT * FROM config_pipelines WHERE active = 1

2. ForEach_Config
   └─ Execute pipeline dynamically based on config
```

```json
{
  "activities": [
    {
      "name": "Lookup_Pipeline_Config",
      "type": "Lookup",
      "typeProperties": {
        "source": {
          "query": "SELECT pipeline_name, parameters FROM config_pipelines WHERE active = 1"
        },
        "firstRowOnly": false
      }
    },
    {
      "name": "Execute_Each_Pipeline",
      "type": "ForEach",
      "typeProperties": {
        "items": {
          "value": "@activity('Lookup_Pipeline_Config').output.value",
          "type": "Expression"
        },
        "isSequential": false,
        "activities": [
          {
            "name": "Execute_Configured_Pipeline",
            "type": "ExecutePipeline",
            "typeProperties": {
              "pipeline": {
                "referenceName": "@item().pipeline_name",
                "type": "PipelineReference"
              },
              "parameters": "@json(item().parameters)"
            }
          }
        ]
      },
      "dependsOn": [
        { "activity": "Lookup_Pipeline_Config", "dependencyConditions": ["Succeeded"] }
      ]
    }
  ]
}
```

### Pattern 3 : Error Handling & Retry

```
Resilient ETL:

1. Try: Execute_Main_Pipeline

2. On Failure:
   ├─ Log_Error
   ├─ Wait (5 min)
   ├─ Retry: Execute_Main_Pipeline (attempt 2)
   └─ On 2nd Failure:
      ├─ Log_Critical_Error
      └─ Send_Alert
```

```json
{
  "activities": [
    {
      "name": "Execute_Main_ETL",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Main_ETL" }
      },
      "policy": {
        "timeout": "02:00:00",
        "retry": 0
      }
    },
    {
      "name": "Log_First_Failure",
      "type": "Copy",
      "typeProperties": {
        "source": {
          "query": "INSERT INTO error_log VALUES ('@{activity('Execute_Main_ETL').error.message}')"
        }
      },
      "dependsOn": [
        { "activity": "Execute_Main_ETL", "dependencyConditions": ["Failed"] }
      ]
    },
    {
      "name": "Wait_Before_Retry",
      "type": "Wait",
      "typeProperties": {
        "waitTimeInSeconds": 300
      },
      "dependsOn": [
        { "activity": "Log_First_Failure", "dependencyConditions": ["Succeeded"] }
      ]
    },
    {
      "name": "Retry_Main_ETL",
      "type": "ExecutePipeline",
      "typeProperties": {
        "pipeline": { "referenceName": "Main_ETL" }
      },
      "dependsOn": [
        { "activity": "Wait_Before_Retry", "dependencyConditions": ["Succeeded"] }
      ]
    },
    {
      "name": "Send_Critical_Alert",
      "type": "WebActivity",
      "typeProperties": {
        "url": "https://alerts.company.com/critical",
        "method": "POST",
        "body": {
          "message": "ETL failed twice: @{activity('Retry_Main_ETL').error.message}"
        }
      },
      "dependsOn": [
        { "activity": "Retry_Main_ETL", "dependencyConditions": ["Failed"] }
      ]
    }
  ]
}
```

### Pattern 4 : Waterfall Dependencies

```
Daily ETL avec dépendances:

8:00 - Extract_Sales
  ↓
9:00 - Extract_Customers (dépend de Sales)
  ↓
10:00 - Transform_Combined (dépend des deux)
  ↓
11:00 - Load_Warehouse
```

**Avec Tumbling Windows :**
```json
// Trigger 1: Extract Sales (hourly)
{
  "name": "Extract_Sales_Trigger",
  "type": "TumblingWindowTrigger",
  "typeProperties": {
    "frequency": "Hour",
    "interval": 1,
    "startTime": "2024-01-01T08:00:00Z"
  },
  "pipeline": { "referenceName": "Extract_Sales" }
}

// Trigger 2: Extract Customers (depends on Sales +1h)
{
  "name": "Extract_Customers_Trigger",
  "type": "TumblingWindowTrigger",
  "typeProperties": {
    "frequency": "Hour",
    "interval": 1,
    "startTime": "2024-01-01T09:00:00Z",
    "dependsOn": [
      {
        "type": "TumblingWindowTriggerDependencyReference",
        "referenceTrigger": { "referenceName": "Extract_Sales_Trigger" },
        "offset": "-01:00:00"
      }
    ]
  },
  "pipeline": { "referenceName": "Extract_Customers" }
}
```

## Scheduling Best Practices

### ✅ Timing Strategies

```
1. Off-Peak Execution:
   • Heavy ETL: 10PM - 6AM
   • Incremental updates: Every 2 hours during day
   • Reports refresh: 6AM (ready for business)

2. Staggered Starts:
   • Pipeline A: 8:00 AM
   • Pipeline B: 8:15 AM
   • Pipeline C: 8:30 AM
   → Évite concurrent capacity spikes

3. Buffer Time:
   • Start: 8:00 AM
   • SLA: Data ready by 10:00 AM
   → 2h buffer for retries/issues
```

### ✅ Dependency Management

```
1. Explicit Dependencies:
   ✅ Use dependsOn in activities
   ✅ Use Tumbling Window trigger dependencies
   ❌ Pas de hard-coded delays (Wait 30min)

2. Dynamic Wait:
   ✅ Until loop checking for file/data
   ❌ Fixed Wait activity

3. Idempotence:
   ✅ Pipeline peut re-run sans corruption
   ✅ MERGE/UPSERT au lieu de INSERT
   ✅ Truncate-and-load avec transaction
```

### ✅ Concurrency Control

```json
{
  "concurrency": 1,
  "maximumRetryAttempts": 3,
  "retryIntervalInSeconds": 300
}
```

```
concurrency: 1
  → Seulement une instance à la fois
  → Si 8:00 AM run pas terminé, 9:00 AM attend

concurrency: 5
  → Maximum 5 instances parallèles
  → Pour event-based triggers (multiple files)
```

## Monitoring Orchestration

### Pipeline Runs Monitoring

```sql
-- Query via Fabric Monitoring API
GET /pipelines/runs?lastUpdatedAfter=2024-01-15T00:00:00Z&lastUpdatedBefore=2024-01-16T00:00:00Z

Response:
{
  "value": [
    {
      "runId": "abc-123",
      "pipelineName": "Master_ETL_Daily",
      "status": "Succeeded",
      "runStart": "2024-01-15T08:00:00Z",
      "runEnd": "2024-01-15T10:23:15Z",
      "durationInMs": 8595000,
      "parameters": {
        "processing_date": "2024-01-15"
      },
      "invokedBy": {
        "name": "Daily_8AM_Trigger",
        "invokedByType": "ScheduleTrigger"
      }
    }
  ]
}
```

### Trigger Monitoring

```
Fabric UI: Pipeline → Triggers → [Trigger Name] → Monitor

Métriques:
  ├─ Last trigger time
  ├─ Next scheduled time
  ├─ Success rate (last 30 days)
  ├─ Average duration
  └─ Failed runs (with errors)
```

### Alerting

```json
{
  "name": "Monitor_and_Alert",
  "activities": [
    {
      "name": "Check_Pipeline_Status",
      "type": "WebActivity",
      "typeProperties": {
        "url": "https://management.azure.com/.../pipelineruns/...",
        "method": "GET",
        "authentication": { "type": "MSI" }
      }
    },
    {
      "name": "If_Failed",
      "type": "IfCondition",
      "typeProperties": {
        "expression": {
          "value": "@equals(activity('Check_Pipeline_Status').output.status, 'Failed')",
          "type": "Expression"
        },
        "ifTrueActivities": [
          {
            "name": "Send_Teams_Alert",
            "type": "WebActivity",
            "typeProperties": {
              "url": "https://outlook.office.com/webhook/...",
              "method": "POST",
              "body": {
                "text": "🚨 Pipeline @{pipeline().Pipeline} failed at @{utcNow()}"
              }
            }
          }
        ]
      }
    }
  ]
}
```

## Points Clés

- Schedule Trigger = calendrier fixed (daily, hourly, etc.)
- Event Trigger = réaction aux événements (fichiers, messages)
- Tumbling Window = windows temporelles avec retry automatique
- Execute Pipeline = orchestration master-child
- Patterns: Master ETL, Dynamic config, Error handling
- waitOnCompletion contrôle synchrone vs asynchrone
- Dependencies critiques pour data consistency
- Concurrency = 1 pour éviter overlap
- Stagger starts pour éviter capacity spikes
- Monitoring et alerting essentiels en production

---

**Prochain fichier :** [06 - Paramètres et Variables](./06-parameters-variables.md)

[⬅️ Fichier précédent](./04-dataflows-integration.md) | [⬅️ Retour au README du module](./README.md)
