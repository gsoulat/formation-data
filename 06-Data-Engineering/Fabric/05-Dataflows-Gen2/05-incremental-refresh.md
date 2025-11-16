# Incremental Refresh

## Introduction

L'**Incremental Refresh** permet de rafraîchir uniquement les données **nouvelles ou modifiées**, réduisant drastiquement le temps de refresh et le coût compute.

```
Full Refresh:
┌─────────────────────────────────────┐
│  Load ALL data (10M rows)           │
│  Duration: 60 minutes               │
│  Cost: High                         │
└─────────────────────────────────────┘

Incremental Refresh:
┌─────────────────────────────────────┐
│  Load only new data (10K rows)      │
│  Duration: 2 minutes                │
│  Cost: Low                          │
└─────────────────────────────────────┘

Performance: 30x faster!
```

## Concept

### Range Parameters

L'incremental refresh utilise deux **paramètres de range** automatiques :

```
RangeStart: Début de la fenêtre de données à charger
RangeEnd: Fin de la fenêtre de données à charger

Example:
  RangeStart = 2024-01-01 00:00:00
  RangeEnd = 2024-01-31 23:59:59

  → Charge seulement données de janvier 2024
```

### Policy Configuration

```
Incremental Refresh Policy:
├─ Archive period: 5 years (historical data)
├─ Incremental period: 3 months (recent data refreshed)
└─ Detect data changes: Yes/No

Behavior:
  • Historical data (5 years): Chargé une fois, jamais re-refreshed
  • Recent data (3 months): Re-refreshed à chaque run
  • New data: Chargé automatiquement
```

## Configuration Incremental Refresh

### Step 1 : Add Range Parameters

```powerquery
// Ces paramètres DOIVENT être nommés exactement:
RangeStart = #datetime(2020, 1, 1, 0, 0, 0) meta [IsParameterQuery=true, Type="DateTime"],
RangeEnd = #datetime(2024, 12, 31, 23, 59, 59) meta [IsParameterQuery=true, Type="DateTime"]
```

**Important :**
```
✅ Noms EXACTS : RangeStart et RangeEnd
✅ Type : DateTime (pas Date)
✅ meta [IsParameterQuery=true] requis
❌ Ne PAS utiliser Date.From() ou autres conversions
```

### Step 2 : Filter Query with Parameters

```powerquery
let
    Source = Sql.Database("server", "SalesDB"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // Filter avec RangeStart et RangeEnd
    FilteredRows = Table.SelectRows(sales, each
        [OrderDate] >= RangeStart
        and [OrderDate] < RangeEnd
    )
in
    FilteredRows
```

**Query Folding Critical :**
```
✅ Filter doit folder vers source:
   SELECT * FROM sales
   WHERE OrderDate >= '2024-01-01'
     AND OrderDate < '2024-02-01'

❌ Si ne folde pas:
   • Toutes données chargées
   • Filter en Power Query
   • Pas de performance gain
```

### Step 3 : Configure Policy

```
1. Dataflow → Settings → Incremental refresh
2. Enable incremental refresh: ✅
3. Configure policy:

   Archive data starting:
     [5] [years▼] before refresh date

   Incrementally refresh data starting:
     [3] [months▼] before refresh date

   Detect data changes: ✅
   ├─ Check for changes in data
   └─ Only refresh if changes detected

   Only refresh complete periods: ✅
   ├─ Don't refresh partial days/months
   └─ Wait until period is complete
```

## Policy Strategies

### Strategy 1 : Time-Series Data

```
Use Case: Daily sales data, append-only

Policy:
  Archive: 5 years
  Incremental: 30 days

Behavior:
  ├─ 2019-01-01 to 2023-12-01 : Historical (never refreshed)
  ├─ 2023-12-01 to 2024-01-01 : Incremental (refreshed daily)
  └─ 2024-01-01+ : New data (loaded on each refresh)

Benefits:
  ✅ Fast refreshes (30 days vs 5 years)
  ✅ Historical data immutable
  ✅ Lower compute cost
```

### Strategy 2 : Frequently Updated Data

```
Use Case: Customer dimension, updates throughout history

Policy:
  Archive: 2 years
  Incremental: 6 months
  Detect changes: ✅

Behavior:
  ├─ Historical (2+ years old): Rarely refreshed
  ├─ Recent (6 months): Always refreshed (captures updates)
  └─ Detect changes: Only refresh if source changed

Benefits:
  ✅ Captures updates in recent period
  ✅ Skips refresh if no changes
  ✅ Balance between freshness and cost
```

### Strategy 3 : Large Fact Tables

```
Use Case: Transaction data, 100M+ rows

Policy:
  Archive: 10 years
  Incremental: 90 days

Behavior:
  First refresh:
    Load 10 years (one-time cost)
    Duration: 2 hours

  Subsequent refreshes:
    Load 90 days only
    Duration: 5 minutes

  ROI: 24x faster!
```

## Partitioning Behind the Scenes

### Automatic Partitioning

```
Incremental refresh crée automatiquement des partitions:

Table partitions (invisible to user):
  ├─ Partition_2019 (2019 data)
  ├─ Partition_2020 (2020 data)
  ├─ ...
  ├─ Partition_2023 (2023 data)
  ├─ Partition_2024_Q1 (Jan-Mar 2024)
  ├─ Partition_2024_Q2 (Apr-Jun 2024)
  └─ Partition_2024_Q3 (Jul-Sep 2024) ← Refreshed

Benefits:
  • Only recent partitions refreshed
  • Historical partitions immutable
  • Queries can prune partitions
```

### Granularity

```
Partition granularity (automatic):
  • Archive period: Yearly partitions
  • Incremental period: Monthly or daily partitions

Example:
  Archive: 5 years → 5 partitions (2019, 2020, 2021, 2022, 2023)
  Incremental: 3 months → 3 partitions (Oct, Nov, Dec 2024)

  Total: 8 partitions (vs 1 monolithic table)
```

## Detect Data Changes

### Configuration

```
Detect data changes: ✅

How it works:
  1. Dataflow queries source for max(updated_at) or similar
  2. Compares to previous refresh
  3. If no change → Skip refresh
  4. If change → Proceed with refresh

Query example:
  SELECT MAX(updated_at) FROM sales
  WHERE OrderDate >= '2024-10-01'
```

### Change Detection Column

```powerquery
// Source doit avoir colonne de change tracking:
// - updated_at (timestamp)
// - version (incrementing number)
// - change_timestamp

let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // Filter avec RangeStart/End ET change detection
    Filtered = Table.SelectRows(sales, each
        [OrderDate] >= RangeStart
        and [OrderDate] < RangeEnd
        and [updated_at] >= DateTime.LocalNow() - #duration(1, 0, 0, 0) // Last 24h
    )
in
    Filtered
```

### Benefits

```
Scenario: No changes in source

Without detect changes:
  • Refresh runs anyway
  • Processes data (no changes found)
  • Writes to destination (same data)
  • Duration: 5 minutes
  • Cost: Wasted compute

With detect changes:
  • Check max(updated_at)
  • No change detected
  • Skip refresh
  • Duration: 5 seconds
  • Cost: Minimal
```

## Only Refresh Complete Periods

### Configuration

```
Only refresh complete periods: ✅

Behavior:
  • Don't refresh partial days/months
  • Wait until period is fully complete

Example (daily partitions):
  Today = 2024-01-15 10:00 AM

  Without option:
    Refreshes 2024-01-15 (partial day, 10 hours)
    → Incomplete data

  With option:
    Skips 2024-01-15 (wait until midnight)
    Refreshes 2024-01-14 (complete day)
    → Complete, accurate data
```

### Use Cases

```
✅ Enable when:
  • Daily reports (wait for full day)
  • Monthly aggregations (wait for month end)
  • SLA: data must be complete

❌ Disable when:
  • Real-time dashboards
  • Intraday updates needed
  • Partial data acceptable
```

## Troubleshooting

### Error: RangeStart/RangeEnd Not Found

```
Error: "The parameters 'RangeStart' and 'RangeEnd' must be defined"

Solutions:
  ✅ Create parameters with EXACT names
  ✅ Type must be DateTime (not Date)
  ✅ Add meta [IsParameterQuery=true]

Example:
  RangeStart = #datetime(2020, 1, 1, 0, 0, 0)
      meta [IsParameterQuery=true, Type="DateTime"]
```

### Error: Query Doesn't Fold

```
Error: "Incremental refresh requires query folding"

Check:
  1. Right-click step → View Native Query
  2. If error → Identify non-folding step

Common causes:
  ❌ Custom M functions on filtered column
  ❌ Text.Proper() before filter
  ❌ Table.Buffer() before filter

Fix:
  ✅ Move filter BEFORE transformations
  ✅ Use folding operations only
  ✅ Test with View Native Query
```

### Slow First Refresh

```
Issue: First refresh takes 2 hours (loading 10 years)

This is EXPECTED:
  • Initial load processes all archive data
  • Creates all partitions
  • One-time cost

Subsequent refreshes:
  • Only incremental period (minutes)
  • Archive partitions untouched
```

### Data Not Updating

```
Issue: Recent data not showing updates

Possible causes:
  1. Incremental period too short
     → Increase from 1 month to 3 months

  2. Source column filter wrong
     → Verify [updated_at] vs [created_at]

  3. Detect changes skipping refresh
     → Check source has new max(updated_at)

  4. Only complete periods enabled
     → Today's data not loaded yet (partial day)
```

## Performance Comparison

### Example: 100M Row Table

```
Full Refresh:
┌─────────────────────────────────────┐
│  Query source: 30 min               │
│  Transform: 15 min                  │
│  Load destination: 20 min           │
│  Total: 65 minutes                  │
│  Rows processed: 100,000,000        │
│  Cost: High                         │
└─────────────────────────────────────┘

Incremental Refresh (90 days):
┌─────────────────────────────────────┐
│  Query source: 30 sec               │
│  Transform: 1 min                   │
│  Load destination: 2 min            │
│  Total: 3.5 minutes                 │
│  Rows processed: 500,000            │
│  Cost: Low                          │
└─────────────────────────────────────┘

Performance: 18x faster
Cost: 200x less compute
```

### Real-World Impact

```
Scenario: Daily refresh at 8 AM

Without Incremental:
  • 65 min duration
  • Finishes: 9:05 AM
  • Data ready: After 9 AM

With Incremental:
  • 3.5 min duration
  • Finishes: 8:03 AM
  • Data ready: By 8:05 AM

Impact:
  ✅ Faster time-to-insight
  ✅ Earlier SLA compliance
  ✅ Lower capacity consumption
```

## Advanced Patterns

### Hybrid Approach

```powerquery
// Combine incremental + full refresh for different queries

// Query 1: Recent data (incremental)
RecentSales = Table.SelectRows(Source, each
    [OrderDate] >= RangeStart
    and [OrderDate] < RangeEnd
)

// Query 2: Dimensions (full refresh, small tables)
Customers = Source{[Schema="dbo",Item="customers"]}[Data]

// Query 3: Aggregations (incremental)
SalesSummary = Table.Group(RecentSales, ...)
```

### Watermark Pattern

```powerquery
// Alternative: Manual watermark (if source doesn't support incremental)

let
    // Get last loaded timestamp
    LastLoadTime = DateTime.From(
        try Table.SelectRows(
            Sql.Database("server", "metadata"),
            each [table_name] = "sales"
        ){0}[last_load_time]
        otherwise #datetime(2020, 1, 1, 0, 0, 0)
    ),

    // Load only new data
    Source = Sql.Database("server", "SalesDB"),
    NewData = Table.SelectRows(Source, each
        [updated_at] > LastLoadTime
    ),

    // Update watermark after load
    // (via separate pipeline step)
in
    NewData
```

## Best Practices

### ✅ Policy Selection

```
Small tables (<1M rows):
  • Don't use incremental refresh
  • Full refresh is fast enough
  • Simplicity > optimization

Medium tables (1-10M rows):
  • Incremental: 30-90 days
  • Archive: 2-5 years
  • Detect changes: Yes

Large tables (10M+ rows):
  • Incremental: 90-180 days
  • Archive: 5-10 years
  • Detect changes: Yes
  • Only complete periods: Yes
```

### ✅ Column Selection

```
Date/Time column requirements:
  ✅ Indexed in source (for performance)
  ✅ Never null
  ✅ Monotonically increasing
  ✅ Granular enough (datetime, not just date)

Good columns:
  ✅ created_at, updated_at, order_date, transaction_time

Bad columns:
  ❌ year (too coarse)
  ❌ last_modified (can go backwards)
  ❌ nullable_date (null handling issues)
```

### ✅ Testing

```
1. Initial Setup:
   • Set short periods for testing (7 days archive, 1 day incremental)
   • Verify partitions created correctly
   • Check query folding works

2. Validate:
   • Run full refresh
   • Verify row counts match source
   • Check no data loss

3. Test Incremental:
   • Add new data to source
   • Run refresh
   • Verify only new data processed

4. Production:
   • Increase to production periods
   • Monitor first few refreshes
   • Adjust as needed
```

## Points Clés

- Incremental refresh = charge seulement nouvelles données
- RangeStart/RangeEnd parameters requis (noms exacts)
- Policy: archive period (historical) + incremental period (recent)
- Query folding CRITIQUE pour performance
- Detect changes = skip refresh si pas de changements
- Only complete periods = wait for full day/month
- Performance: 10-100x faster pour grandes tables
- First refresh = slow (load all archive)
- Subsequent = fast (only incremental)
- Best for tables >1M rows avec date/time column

---

**Prochain fichier :** [06 - Best Practices](./06-best-practices.md)

[⬅️ Fichier précédent](./04-destinations.md) | [⬅️ Retour au README du module](./README.md)
