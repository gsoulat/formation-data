# Intégration Dataflows

## Introduction

Les **Dataflows Gen2** dans Fabric permettent des transformations **no-code** avec Power Query. Ils s'intègrent parfaitement dans les pipelines pour des ETL accessibles aux analysts.

```
Pipeline Integration:
┌──────────────────────────────────────────┐
│            Pipeline                       │
├──────────────────────────────────────────┤
│  1. Copy Data (staging)                  │
│  2. Dataflow Gen2 (transform) ←────────  │
│  3. Load to destination                  │
└──────────────────────────────────────────┘
```

## Dataflow Gen2 vs Dataflow Gen1

| Feature | Dataflow Gen1 | Dataflow Gen2 (Fabric) |
|---------|---------------|------------------------|
| **Engine** | Power Query Online | Power Query + Enhanced |
| **Destinations** | Power BI, CDM folders | Lakehouse, Warehouse, CDM |
| **Integration** | Power BI only | Full Fabric integration |
| **Incremental Refresh** | Limited | Full support |
| **Query Folding** | Basic | Advanced |
| **Performance** | Standard | Optimized |
| **Notebook Integration** | No | Yes |
| **Pipeline Activity** | Via Power BI | Native activity |

## Création d'un Dataflow

### Via UI

```
1. Workspace → + New item
2. Dataflow Gen2
3. Nom: "Transform_Customer_Data"
4. Get Data → Choose source
5. Transform avec Power Query
6. Set destination → Lakehouse/Warehouse
7. Publish
```

### Power Query Transformations

**Example : Clean Customer Data**

```powerquery
let
    // 1. Source
    Source = Sql.Database("server.database.windows.net", "SalesDB"),
    dbo_customers = Source{[Schema="dbo",Item="customers"]}[Data],

    // 2. Remove duplicates
    RemoveDuplicates = Table.Distinct(dbo_customers, {"email"}),

    // 3. Filter active customers
    FilterActive = Table.SelectRows(RemoveDuplicates, each [is_active] = true),

    // 4. Clean text
    TrimNames = Table.TransformColumns(FilterActive, {
        {"first_name", Text.Trim, type text},
        {"last_name", Text.Trim, type text}
    }),
    ProperCase = Table.TransformColumns(TrimNames, {
        {"first_name", Text.Proper, type text},
        {"last_name", Text.Proper, type text}
    }),

    // 5. Add calculated columns
    FullName = Table.AddColumn(ProperCase, "full_name",
        each [first_name] & " " & [last_name], type text),

    // 6. Format phone
    FormatPhone = Table.TransformColumns(FullName, {
        {"phone", each Text.Replace(Text.Replace(_, "-", ""), " ", ""), type text}
    }),

    // 7. Parse dates
    ParseDates = Table.TransformColumnTypes(FormatPhone, {
        {"created_at", type datetime},
        {"birth_date", type date}
    }),

    // 8. Add age calculation
    AddAge = Table.AddColumn(ParseDates, "age",
        each Duration.Days(DateTime.LocalNow() - [birth_date]) / 365,
        Int64.Type),

    // 9. Merge with country codes
    MergeCountry = Table.NestedJoin(AddAge, {"country_code"}, CountryLookup, {"code"}, "country_info", JoinKind.LeftOuter),
    ExpandCountry = Table.ExpandTableColumn(MergeCountry, "country_info", {"country_name", "region"}),

    // 10. Select final columns
    SelectColumns = Table.SelectColumns(ExpandCountry, {
        "customer_id", "full_name", "email", "phone",
        "country_name", "region", "age", "created_at"
    }),

    // 11. Rename for consistency
    RenameColumns = Table.RenameColumns(SelectColumns, {
        {"country_name", "country"},
        {"created_at", "registration_date"}
    })
in
    RenameColumns
```

## Dataflow Activity dans Pipeline

### Configuration Basique

```json
{
  "name": "Run_Customer_Dataflow",
  "type": "ExecuteDataFlow",
  "typeProperties": {
    "dataflow": {
      "referenceName": "Transform_Customer_Data",
      "type": "DataFlowReference"
    },
    "compute": {
      "coreCount": 8,
      "computeType": "General"
    },
    "traceLevel": "Fine"
  },
  "dependsOn": [
    {
      "activity": "Copy_Raw_Data",
      "dependencyConditions": ["Succeeded"]
    }
  ]
}
```

### Avec Paramètres

**Définir Paramètres Dataflow :**
```powerquery
// Dataflow parameters
Processing_Date = DateTime.Date(DateTime.LocalNow()) meta [IsParameterQuery=true, Type="Date"],
Source_Table = "customers" meta [IsParameterQuery=true, Type="Text"],
Min_Age = 18 meta [IsParameterQuery=true, Type="Number"]

// Utilisation
let
    Source = Sql.Database("server", "db"),
    Table = Source{[Schema="dbo",Item=Source_Table]}[Data],
    FilterDate = Table.SelectRows(Table, each [date] = Processing_Date),
    FilterAge = Table.SelectRows(FilterDate, each [age] >= Min_Age)
in
    FilterAge
```

**Passer Paramètres depuis Pipeline :**
```json
{
  "name": "Run_Parameterized_Dataflow",
  "type": "ExecuteDataFlow",
  "typeProperties": {
    "dataflow": {
      "referenceName": "Transform_Customer_Data",
      "type": "DataFlowReference",
      "parameters": {
        "Processing_Date": {
          "value": "@formatDateTime(utcnow(), 'yyyy-MM-dd')",
          "type": "Expression"
        },
        "Source_Table": {
          "value": "@pipeline().parameters.table_name",
          "type": "Expression"
        },
        "Min_Age": {
          "value": "21",
          "type": "Int"
        }
      }
    }
  }
}
```

## Destinations Dataflow

### Lakehouse Destination

```powerquery
// Après transformations
let
    FinalData = /* transformations */,

    // Configure Lakehouse destination
    Destination = Lakehouse.Contents("WorkspaceName", "LakehouseName"),
    TargetTable = Destination{[workspaceId="...", lakehouseId="...", item="silver_customers"]}[Data]
in
    FinalData
```

**Settings :**
```
Destination Type: Lakehouse Table
  ├─ Lakehouse: DataLakehouse
  ├─ Table: silver_customers
  ├─ Update method: Replace
  ├─ Partition: year, month
  └─ Create table if not exists: Yes
```

### Warehouse Destination

```powerquery
// Destination vers Data Warehouse
let
    TransformedData = /* transformations */,

    WarehouseDestination = Warehouse.Contents("WorkspaceName", "WarehouseName"),
    TargetTable = WarehouseDestination{[schema="dbo", table="dim_customer"]}
in
    TransformedData
```

**Settings :**
```
Destination Type: Warehouse Table
  ├─ Warehouse: SalesWarehouse
  ├─ Schema: dbo
  ├─ Table: dim_customer
  ├─ Update method: Append
  └─ Distribution: Hash(customer_id)
```

### Custom Destination (Staging Pattern)

```powerquery
// Output to Lakehouse Files for custom processing
let
    ProcessedData = /* transformations */,

    // Write to Files/ folder as Parquet
    OutputPath = Lakehouse.Files("DataLakehouse", "staging/customers/processed.parquet")
in
    ProcessedData
```

## Update Methods

### Replace (Full Refresh)

```
Update Method: Replace

Comportement:
  1. Truncate target table
  2. Insert all rows from dataflow
  3. Rebuild indexes/stats

Use case:
  • Petites dimensions
  • Daily full refresh acceptable
  • Pas de historical tracking
```

### Append

```
Update Method: Append

Comportement:
  1. Insert nouvelles rows à la fin
  2. Pas de delete/update

Use case:
  • Fact tables
  • Log data
  • Time-series events
```

### Incremental Refresh

```
Update Method: Incremental Refresh

Configuration:
  ├─ RangeStart: DateTime parameter
  ├─ RangeEnd: DateTime parameter
  ├─ Detect data changes: Yes
  └─ Only refresh complete days: Yes

Powerquery:
let
    Source = /* data source */,
    FilteredRows = Table.SelectRows(Source,
        each [date] >= RangeStart and [date] < RangeEnd)
in
    FilteredRows

Comportement:
  First run: Load all data
  Subsequent: Only load RangeStart to RangeEnd
```

**Configuration Incrémentale :**
```json
{
  "incrementalRefreshSettings": {
    "enabled": true,
    "rangeStartColumn": "created_date",
    "rangeEndColumn": "created_date",
    "archivePeriodMultiplier": 5,
    "archivePeriodGranularity": "Year",
    "incrementalPeriodMultiplier": 3,
    "incrementalPeriodGranularity": "Month"
  }
}
```

## Query Folding

### Qu'est-ce que Query Folding ?

```
Query Folding = Pousser transformations vers la source

SANS Query Folding:
  Source DB → Transfer 10M rows → Power Query transforme → 100K rows output

AVEC Query Folding:
  Source DB → SQL exécute transformations → Transfer 100K rows → Output

→ 100x moins de données transférées!
```

### Opérations qui Foldent

```powerquery
// ✅ Ces opérations foldent vers SQL
Table.SelectRows(Source, each [amount] > 100)
  → WHERE amount > 100

Table.SelectColumns(Source, {"id", "name"})
  → SELECT id, name

Table.Sort(Source, {{"amount", Order.Descending}})
  → ORDER BY amount DESC

Table.Group(Source, {"category"}, {{"total", each List.Sum([amount])}})
  → GROUP BY category, SUM(amount) as total

Table.Join(Table1, "id", Table2, "id", JoinKind.Inner)
  → INNER JOIN ON id
```

### Opérations qui NE foldent PAS

```powerquery
// ❌ Ces opérations cassent folding
Text.Proper([name])  // Fonctions M custom
Table.AddColumn(each [amount] * 1.2)  // Calculations complexes
Table.Buffer()  // Force load en mémoire
Table.Distinct() après custom functions
```

### Vérifier Query Folding

```
Power Query Editor:
  1. Right-click sur step
  2. "View Native Query"
  3. Si SQL visible → Folding OK ✅
  4. Si erreur → Pas de folding ❌
```

**Optimization :**
```powerquery
// ❌ Mauvais (ne folde pas)
let
    Source = Sql.Database("server", "db"),
    AllData = Source{[Schema="dbo",Item="sales"]}[Data],
    ProperName = Table.TransformColumns(AllData, {"customer", Text.Proper}),
    FilterAmount = Table.SelectRows(ProperName, each [amount] > 100)
in
    FilterAmount

// ✅ Bon (folde optimal)
let
    Source = Sql.Database("server", "db"),
    AllData = Source{[Schema="dbo",Item="sales"]}[Data],
    FilterAmount = Table.SelectRows(AllData, each [amount] > 100), // Folde
    ProperName = Table.TransformColumns(FilterAmount, {"customer", Text.Proper}) // Après
in
    ProperName
// → Filtre 100M rows → 1M rows, PUIS Text.Proper sur 1M seulement
```

## Dataflow Compute

### Compute Settings

```
Compute Types:
  • General: CPU balanced
  • Memory Optimized: Plus de RAM
  • Compute Optimized: Plus de CPU

Core Counts:
  • 8 cores (default)
  • 16 cores
  • 32 cores
  • 64 cores
```

**Performance Impact :**
```
Dataflow: 10M rows, complex transformations

8 cores:
  Duration: 15 min
  Cost: 1x

16 cores:
  Duration: 8 min
  Cost: 2x

32 cores:
  Duration: 5 min
  Cost: 4x

→ Diminishing returns après 16-32 cores
```

### Auto-Compute vs Manual

```json
{
  "compute": {
    "computeType": "General",
    "coreCount": 8  // Manual: Fixed
  }
}

// Ou auto
{
  "compute": "auto"  // Fabric decide
}
```

## Pipeline Orchestration Patterns

### Pattern 1 : Staging → Dataflow → Load

```
Pipeline: ETL_Customer_Data

Activities:
  1. Copy_CSV_to_Staging (Copy Activity)
     └─ Source: Blob CSV files
     └─ Sink: Lakehouse bronze_customers

  2. Transform_Customers (Dataflow Gen2)
     └─ Source: bronze_customers
     └─ Transform: Clean, deduplicate, enrich
     └─ Destination: silver_customers

  3. Load_to_Warehouse (Copy Activity)
     └─ Source: silver_customers
     └─ Sink: Warehouse dim_customer
```

### Pattern 2 : Parallel Dataflows

```
Pipeline: Process_Multiple_Entities

Activities:
  ├─ Transform_Customers (Dataflow)
  ├─ Transform_Products (Dataflow)
  ├─ Transform_Orders (Dataflow)
  └─ (All run in parallel)

  Then:
  └─ Aggregate_Results (Notebook)
```

### Pattern 3 : Conditional Dataflow

```
Pipeline: Smart_Refresh

Activities:
  1. Check_Data_Changed (Lookup)
     └─ Query: SELECT COUNT(*) FROM staging WHERE processed = 0

  2. If_Data_Exists (If Condition)
     └─ Condition: @greater(activity('Check').output.firstRow.count, 0)
     └─ True:
        └─ Run_Dataflow (Dataflow Activity)
     └─ False:
        └─ Skip (Web notification)
```

### Pattern 4 : Incremental with Watermark

```
Pipeline: Incremental_Customer_Updates

Activities:
  1. Get_Last_Update (Lookup)
     └─ SELECT MAX(updated_at) FROM silver_customers

  2. Run_Incremental_Dataflow (Dataflow)
     └─ Parameters:
        └─ last_update: @activity('Get_Last_Update').output.firstRow.max_date

  3. Update_Watermark (Stored Procedure)
```

## Error Handling

### Dataflow-Level Errors

```powerquery
// Dans Dataflow: Error handling
let
    Source = try Sql.Database("server", "db") otherwise null,
    CheckSource = if Source = null then
        error "Cannot connect to source database"
    else
        Source,

    Data = try CheckSource{[Schema="dbo",Item="customers"]}[Data] otherwise #table({}, {}),

    // Continue avec handling
in
    Data
```

### Pipeline-Level Handling

```json
{
  "activities": [
    {
      "name": "Run_Dataflow",
      "type": "ExecuteDataFlow",
      "policy": {
        "timeout": "02:00:00",
        "retry": 2,
        "retryIntervalInSeconds": 300
      }
    },
    {
      "name": "On_Dataflow_Failure",
      "type": "WebActivity",
      "typeProperties": {
        "url": "https://hooks.slack.com/...",
        "method": "POST",
        "body": {
          "text": "Dataflow failed: @{activity('Run_Dataflow').error.message}"
        }
      },
      "dependsOn": [
        {
          "activity": "Run_Dataflow",
          "dependencyConditions": ["Failed"]
        }
      ]
    }
  ]
}
```

## Performance Best Practices

### ✅ Query Folding

```powerquery
// 1. Filtrer tôt (avant transformations)
let
    Source = Sql.Database("server", "db"),
    Data = Source{[Schema="dbo",Item="sales"]}[Data],
    FilterEarly = Table.SelectRows(Data, each [year] = 2024), // Folde!
    Transform = Table.TransformColumns(FilterEarly, ...) // Après
in
    Transform

// 2. Limiter colonnes tôt
let
    Source = Sql.Database("server", "db"),
    Data = Source{[Schema="dbo",Item="sales"]}[Data],
    SelectColumns = Table.SelectColumns(Data, {"id", "amount", "date"}), // Folde!
in
    SelectColumns
```

### ✅ Incremental Refresh

```
For large tables:
  ✅ Enable incremental refresh
  ✅ Partition par date
  ✅ Archive old data

Éviter:
  ❌ Full refresh quotidien sur TB tables
  ❌ Pas de partitioning
```

### ✅ Compute Optimization

```
Match compute to workload:
  • Simple transformations: 8 cores
  • Complex joins/aggregations: 16-32 cores
  • Very large datasets: 32-64 cores

Monitor:
  • Dataflow duration trends
  • Core utilization
  • Memory usage
```

## Monitoring

### Dataflow Run History

```
UI: Dataflow → Settings → Refresh history

Metrics:
  ├─ Start time
  ├─ End time
  ├─ Duration
  ├─ Status (Succeeded/Failed)
  ├─ Rows processed
  ├─ Errors (if any)
  └─ Refresh type (Full/Incremental)
```

### Pipeline Integration Monitoring

```json
{
  "activity": "Run_Dataflow",
  "output": {
    "dataflowRunId": "abc-123-def",
    "status": "Succeeded",
    "duration": 180,
    "refreshType": "Full",
    "rowsRead": 1000000,
    "rowsWritten": 950000,
    "errors": []
  }
}
```

## Points Clés

- Dataflows Gen2 = Power Query no-code transformations
- Intégration native dans pipelines Fabric
- Query folding critique pour performance
- Destinations: Lakehouse, Warehouse, Custom
- Update methods: Replace, Append, Incremental
- Paramètres passés depuis pipeline
- Compute: 8-64 cores selon workload
- Incremental refresh pour grandes tables
- Patterns: Staging, Parallel, Conditional
- Monitoring via refresh history

---

**Prochain fichier :** [05 - Orchestration et Scheduling](./05-orchestration-scheduling.md)

[⬅️ Fichier précédent](./03-copy-activity.md) | [⬅️ Retour au README du module](./README.md)
