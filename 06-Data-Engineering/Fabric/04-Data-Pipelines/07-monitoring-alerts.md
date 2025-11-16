# Monitoring et Alerting

## Introduction

Le **monitoring** et **l'alerting** sont cruciaux pour maintenir des pipelines en production. Fabric offre plusieurs outils pour surveiller et diagnostiquer les exécutions.

```
Monitoring Stack:
├── Pipeline Runs (UI)
├── Activity Runs (détails)
├── Monitoring Hub (Fabric)
├── Logs et Diagnostics
├── Metrics et KPIs
└── Alerting (Teams, Email, Webhook)
```

## Monitoring UI

### Pipeline Runs View

```
Fabric UI → Workspace → Pipeline → Monitor

Tableau:
┌────────────┬────────┬──────────┬──────────┬─────────┐
│ Run ID     │ Status │ Start    │ Duration │ Trigger │
├────────────┼────────┼──────────┼──────────┼─────────┤
│ abc-123    │ ✅     │ 08:00    │ 5m 23s   │ Schedule│
│ abc-122    │ ✅     │ 07:00    │ 4m 56s   │ Schedule│
│ abc-121    │ ❌     │ 06:00    │ 2m 10s   │ Manual  │
│ abc-120    │ ⏸️     │ 05:00    │ -        │ Schedule│
└────────────┴────────┴──────────┴──────────┴─────────┘

Statuses:
  ✅ Succeeded
  ❌ Failed
  ⏸️ InProgress
  ⏹️ Cancelled
  ⏭️ Queued
```

**Filtres :**
```
• Date range
• Status (Succeeded/Failed/InProgress)
• Trigger type
• Pipeline name
• Run ID
```

### Activity Runs Détails

```
Click sur Run ID → Activity details:

┌─────────────────┬────────┬──────────┬─────────┐
│ Activity        │ Status │ Duration │ Details │
├─────────────────┼────────┼──────────┼─────────┤
│ Copy_Data       │ ✅     │ 45s      │ [View]  │
│ Transform       │ ✅     │ 3m 15s   │ [View]  │
│ Load_Warehouse  │ ✅     │ 1m 23s   │ [View]  │
│ Send_Notification│ ✅    │ 2s       │ [View]  │
└─────────────────┴────────┴──────────┴─────────┘

Pour chaque activity:
  • Input (parameters, source)
  • Output (résultats, metrics)
  • Error (si failed)
  • JSON détails
```

**Copy Activity Output Example :**
```json
{
  "dataRead": 1073741824,
  "dataWritten": 1073741824,
  "rowsCopied": 1000000,
  "rowsSkipped": 15,
  "copyDuration": 45,
  "throughput": 23814,
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
      "detailedDurations": {
        "queuingDuration": 2,
        "transferDuration": 43
      }
    }
  ]
}
```

## Monitoring Hub (Fabric)

### Vue d'Ensemble

```
Fabric → Monitoring Hub

Sections:
├── Pipeline runs
├── Dataflow refreshes
├── Notebook runs
├── Spark job runs
├── Semantic model refreshes
└── Real-time intelligence
```

**Metrics Globales :**
```
Overview Dashboard:
  ├── Success rate (last 24h)
  ├── Failed runs (last 7 days)
  ├── Average duration
  ├── Total CU consumption
  └── Top 10 longest running pipelines
```

### Filtering et Search

```
Filters:
  • Workspace
  • Item type (Pipeline, Dataflow, Notebook)
  • Status
  • Date range
  • User/Trigger

Search:
  • By Run ID
  • By Pipeline name
  • By Error message
```

## Logging

### Activity-Level Logging

**Copy Activity Logs :**
```json
{
  "typeProperties": {
    "enableSkipIncompatibleRow": true,
    "redirectIncompatibleRowSettings": {
      "linkedServiceName": "BlobStorage",
      "path": "logs/incompatible_rows"
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

**Log Levels :**
```
None: Pas de logs
Info: Toutes opérations
Warning: Seulement warnings et errors
```

**Log Contents :**
```
logs/copy_activity/
├── {run_id}/
│   ├── summary.json
│   ├── incompatible_rows.csv
│   └── skipped_rows.csv
```

### Custom Logging avec Web Activity

```json
{
  "name": "Log_Pipeline_Start",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://api.company.com/logs",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "value": "@json(concat('{\"pipeline\":\"', pipeline().Pipeline, '\",\"runId\":\"', pipeline().RunId, '\",\"startTime\":\"', utcnow(), '\",\"triggeredBy\":\"', pipeline().TriggerName, '\"}'))",
      "type": "Expression"
    }
  }
}
```

### Database Logging Pattern

**Log Table :**
```sql
CREATE TABLE pipeline_execution_log (
    run_id VARCHAR(100),
    pipeline_name VARCHAR(200),
    status VARCHAR(50),
    start_time DATETIME,
    end_time DATETIME,
    duration_seconds INT,
    trigger_type VARCHAR(50),
    error_message VARCHAR(MAX),
    rows_processed BIGINT,
    created_at DATETIME DEFAULT GETDATE()
);
```

**Log Success :**
```json
{
  "name": "Log_Success",
  "type": "Script",
  "typeProperties": {
    "scripts": [{
      "type": "Query",
      "text": "INSERT INTO pipeline_execution_log (run_id, pipeline_name, status, start_time, end_time, duration_seconds, trigger_type, rows_processed) VALUES ('@{pipeline().RunId}', '@{pipeline().Pipeline}', 'Succeeded', '@{pipeline().TriggerTime}', '@{utcnow()}', @{div(sub(ticks(utcnow()), ticks(pipeline().TriggerTime)), 10000000)}, '@{pipeline().TriggerType}', @{activity('Copy_Data').output.rowsCopied})"
    }]
  },
  "linkedServiceName": {
    "referenceName": "MetadataDatabase"
  },
  "dependsOn": [
    { "activity": "Copy_Data", "dependencyConditions": ["Succeeded"] }
  ]
}
```

**Log Failure :**
```json
{
  "name": "Log_Failure",
  "type": "Script",
  "typeProperties": {
    "scripts": [{
      "type": "Query",
      "text": "INSERT INTO pipeline_execution_log (run_id, pipeline_name, status, start_time, end_time, error_message) VALUES ('@{pipeline().RunId}', '@{pipeline().Pipeline}', 'Failed', '@{pipeline().TriggerTime}', '@{utcnow()}', '@{activity('Copy_Data').error.message}')"
    }]
  },
  "dependsOn": [
    { "activity": "Copy_Data", "dependencyConditions": ["Failed"] }
  ]
}
```

## Metrics et KPIs

### Pipeline Performance Metrics

```sql
-- Average duration par pipeline
SELECT
    pipeline_name,
    AVG(duration_seconds) as avg_duration_sec,
    MIN(duration_seconds) as min_duration_sec,
    MAX(duration_seconds) as max_duration_sec,
    STDEV(duration_seconds) as std_dev
FROM pipeline_execution_log
WHERE created_at >= DATEADD(DAY, -30, GETDATE())
    AND status = 'Succeeded'
GROUP BY pipeline_name
ORDER BY avg_duration_sec DESC;
```

```
Results:
┌─────────────────────┬──────────┬──────────┬──────────┐
│ Pipeline            │ Avg      │ Min      │ Max      │
├─────────────────────┼──────────┼──────────┼──────────┤
│ ETL_Daily_Sales     │ 325s     │ 280s     │ 450s     │
│ Transform_Customers │ 180s     │ 150s     │ 220s     │
│ Load_Warehouse      │ 95s      │ 80s      │ 130s     │
└─────────────────────┴──────────┴──────────┴──────────┘
```

### Success Rate

```sql
SELECT
    pipeline_name,
    COUNT(*) as total_runs,
    SUM(CASE WHEN status = 'Succeeded' THEN 1 ELSE 0 END) as successful_runs,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) as failed_runs,
    CAST(SUM(CASE WHEN status = 'Succeeded' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as success_rate_pct
FROM pipeline_execution_log
WHERE created_at >= DATEADD(DAY, -7, GETDATE())
GROUP BY pipeline_name
ORDER BY success_rate_pct ASC;
```

### Throughput Metrics

```sql
SELECT
    pipeline_name,
    AVG(rows_processed) as avg_rows,
    AVG(CAST(rows_processed AS FLOAT) / NULLIF(duration_seconds, 0)) as avg_rows_per_second
FROM pipeline_execution_log
WHERE status = 'Succeeded'
    AND created_at >= DATEADD(DAY, -7, GETDATE())
GROUP BY pipeline_name
ORDER BY avg_rows_per_second DESC;
```

### SLA Compliance

```sql
-- Pipelines qui dépassent SLA (ex: 10 minutes)
SELECT
    run_id,
    pipeline_name,
    duration_seconds,
    duration_seconds / 60.0 as duration_minutes,
    start_time,
    end_time
FROM pipeline_execution_log
WHERE duration_seconds > 600  -- SLA: 10 minutes
    AND created_at >= DATEADD(DAY, -1, GETDATE())
ORDER BY duration_seconds DESC;
```

## Alerting

### Teams Notification

**Webhook Setup :**
```
1. Teams → Channel → Connectors → Incoming Webhook
2. Configure webhook
3. Copy URL
```

**Pipeline Alert :**
```json
{
  "name": "Send_Teams_Alert",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://outlook.office.com/webhook/{your-webhook-id}",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "value": "@json(concat('{\"@type\":\"MessageCard\",\"@context\":\"https://schema.org/extensions\",\"summary\":\"Pipeline Alert\",\"themeColor\":\"0078D7\",\"title\":\"🚨 Pipeline Failed\",\"sections\":[{\"activityTitle\":\"', pipeline().Pipeline, '\",\"facts\":[{\"name\":\"Run ID:\",\"value\":\"', pipeline().RunId, '\"},{\"name\":\"Error:\",\"value\":\"', activity('Copy_Data').error.message, '\"},{\"name\":\"Time:\",\"value\":\"', utcnow(), '\"}]}]}'))",
      "type": "Expression"
    }
  },
  "dependsOn": [
    { "activity": "Copy_Data", "dependencyConditions": ["Failed"] }
  ]
}
```

**Adaptive Card (Advanced) :**
```json
{
  "body": {
    "type": "AdaptiveCard",
    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
    "version": "1.4",
    "body": [
      {
        "type": "TextBlock",
        "text": "Pipeline Execution Report",
        "weight": "Bolder",
        "size": "Large"
      },
      {
        "type": "FactSet",
        "facts": [
          {
            "title": "Pipeline:",
            "value": "@{pipeline().Pipeline}"
          },
          {
            "title": "Status:",
            "value": "Succeeded"
          },
          {
            "title": "Duration:",
            "value": "@{div(sub(ticks(utcnow()), ticks(pipeline().TriggerTime)), 10000000)}s"
          },
          {
            "title": "Rows Processed:",
            "value": "@{activity('Copy_Data').output.rowsCopied}"
          }
        ]
      }
    ],
    "actions": [
      {
        "type": "Action.OpenUrl",
        "title": "View Run",
        "url": "https://fabric.microsoft.com/..."
      }
    ]
  }
}
```

### Email Notification (via Logic App)

**Logic App Trigger :**
```
HTTP Request Trigger
└─ Body Schema:
   {
     "pipeline": "string",
     "runId": "string",
     "status": "string",
     "errorMessage": "string"
   }
```

**Pipeline Call :**
```json
{
  "name": "Trigger_Email_Alert",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://{logic-app-name}.azurewebsites.net/triggers/manual/paths/invoke?...",
    "method": "POST",
    "body": {
      "value": "@json(concat('{\"pipeline\":\"', pipeline().Pipeline, '\",\"runId\":\"', pipeline().RunId, '\",\"status\":\"Failed\",\"errorMessage\":\"', activity('Copy_Data').error.message, '\"}'))",
      "type": "Expression"
    }
  }
}
```

**Logic App Actions :**
```
1. Parse JSON (input body)
2. Compose HTML Email
3. Send Email (Office 365 Outlook connector)
   ├─ To: data-team@company.com
   ├─ Subject: [ALERT] Pipeline @{body('Parse_JSON')?['pipeline']} Failed
   └─ Body: HTML template avec détails
```

### PagerDuty / Opsgenie Integration

```json
{
  "name": "Create_PagerDuty_Incident",
  "type": "WebActivity",
  "typeProperties": {
    "url": "https://api.pagerduty.com/incidents",
    "method": "POST",
    "headers": {
      "Authorization": "Token token={your-api-key}",
      "Content-Type": "application/json",
      "From": "data-pipelines@company.com"
    },
    "body": {
      "incident": {
        "type": "incident",
        "title": "Pipeline @{pipeline().Pipeline} Failed",
        "service": {
          "id": "{service-id}",
          "type": "service_reference"
        },
        "urgency": "high",
        "body": {
          "type": "incident_body",
          "details": "Run ID: @{pipeline().RunId}. Error: @{activity('Copy_Data').error.message}"
        }
      }
    }
  }
}
```

## Monitoring Patterns

### Pattern 1 : Centralized Monitoring Pipeline

```
Master_Monitor_Pipeline:

1. Lookup_All_Pipelines
   └─ SELECT DISTINCT pipeline_name FROM pipeline_execution_log

2. ForEach_Pipeline
   ├─ Get_Latest_Run_Status
   ├─ Check_SLA_Compliance
   ├─ Calculate_Success_Rate
   └─ If_Issues_Detected:
      └─ Send_Alert

3. Generate_Daily_Report
   └─ Email with metrics dashboard
```

### Pattern 2 : Self-Healing Pipeline

```
ETL_With_Auto_Retry:

1. Execute_ETL (try 1)

2. On Failure:
   ├─ Log_Failure
   ├─ Wait (5 minutes)
   ├─ Check_Dependencies (files, database, capacity)
   └─ If_Dependencies_OK:
      ├─ Execute_ETL (try 2)
      └─ On 2nd Failure:
         └─ Alert_Team

3. On Success:
   └─ Clear_Previous_Alerts
```

### Pattern 3 : Proactive Monitoring

```
Health_Check_Pipeline (runs every 15 min):

1. Check_Source_Connectivity
   └─ Test connection to all sources

2. Check_Capacity_Available
   └─ Query Fabric capacity metrics

3. Check_File_Availability
   └─ Validate expected files present

4. Check_Downstream_Dependencies
   └─ Verify warehouse/lakehouse accessible

5. If_Any_Check_Failed:
   └─ Preventive_Alert (before main ETL runs)
```

## Troubleshooting

### Common Errors et Solutions

**Error: Timeout**
```
Error: Activity timeout after 02:00:00

Cause:
  • Query trop lent
  • Trop de données
  • Network issues

Solutions:
  1. Increase timeout dans policy
  2. Optimize query (indexes, partitions)
  3. Partition Copy Activity (parallelize)
  4. Check source database performance
```

**Error: Out of Memory**
```
Error: Out of memory exception

Cause:
  • Dataset trop large pour compute
  • Complex transformations

Solutions:
  1. Increase Dataflow compute cores
  2. Enable staging pour Copy Activity
  3. Process en batches (ForEach avec partition)
  4. Optimize transformations (reduce shuffle)
```

**Error: Permission Denied**
```
Error: Access denied to resource

Cause:
  • Permissions insuffisantes
  • Expired credentials

Solutions:
  1. Verify linked service credentials
  2. Check RBAC roles (Lakehouse, Warehouse)
  3. Refresh service principal secret
  4. Check firewall rules
```

**Error: Incompatible Schema**
```
Error: Column 'amount' type mismatch (String vs Decimal)

Cause:
  • Source schema changed
  • Type conversion error

Solutions:
  1. Enable skipIncompatibleRows (temporarily)
  2. Add column mapping avec type conversion
  3. Fix source data
  4. Update sink schema
```

### Debugging Steps

```
1. Check Pipeline Run:
   ├─ Status et duration
   ├─ Trigger type et time
   └─ Input parameters

2. Check Activity Runs:
   ├─ Which activity failed?
   ├─ Error message
   └─ Input/Output JSON

3. Check Logs:
   ├─ Copy activity logs
   ├─ Incompatible rows
   └─ Custom logs (database, blob)

4. Reproduce Locally:
   ├─ Debug mode dans UI
   ├─ Same parameters
   └─ Isolate issue

5. Fix et Re-run:
   ├─ Apply fix
   ├─ Rerun failed pipeline (UI button)
   └─ Monitor fix
```

## Best Practices

### ✅ Logging Strategy

```
1. Log Levels:
   • DEV: Info (verbose)
   • STAGING: Warning
   • PROD: Warning + Success summary

2. Log Retention:
   • Detailed logs: 30 days
   • Summary logs: 1 year
   • Compliance logs: 7 years

3. What to Log:
   ✅ Run ID, Pipeline name, Start/End time
   ✅ Rows processed, Duration
   ✅ Errors avec full stack trace
   ✅ Parameters values
   ❌ Pas de PII (emails, SSN, etc.)
   ❌ Pas de secrets (passwords, keys)
```

### ✅ Alerting Strategy

```
1. Alert Tiers:
   • Critical (P1): Production pipelines failed
     → PagerDuty + Teams + Email
   • High (P2): SLA breach
     → Teams + Email
   • Medium (P3): Performance degradation
     → Teams only
   • Low (P4): Warnings
     → Email digest daily

2. Alert Frequency:
   • Immediate: Critical errors
   • Batched: Warnings (hourly digest)
   • Daily: Performance reports

3. Alert Content:
   ✅ What failed
   ✅ When it failed
   ✅ Error message
   ✅ Link to run details
   ✅ Suggested next steps
```

### ✅ Monitoring Dashboards

```
Create dashboards showing:
  1. Real-time:
     ├─ Active runs
     ├─ Failed runs (last 24h)
     └─ Current capacity usage

  2. Historical:
     ├─ Success rate trends
     ├─ Duration trends
     ├─ Throughput trends
     └─ SLA compliance

  3. Operational:
     ├─ Top 10 slowest pipelines
     ├─ Top 10 error-prone pipelines
     └─ Capacity consumption by pipeline
```

## Points Clés

- Monitoring UI pour pipeline et activity runs
- Monitoring Hub pour vue d'ensemble Fabric
- Custom logging (database, blob, API)
- Metrics: duration, success rate, throughput, SLA
- Alerting via Teams, Email, PagerDuty
- Error handling patterns (retry, self-healing)
- Proactive monitoring (health checks)
- Debugging: logs, reproduce, isolate, fix
- Alert tiers (Critical, High, Medium, Low)
- Dashboards pour visibility continue

---

**Prochain fichier :** [08 - CI/CD et Deployment](./08-cicd-deployment.md)

[⬅️ Fichier précédent](./06-parameters-variables.md) | [⬅️ Retour au README du module](./README.md)
