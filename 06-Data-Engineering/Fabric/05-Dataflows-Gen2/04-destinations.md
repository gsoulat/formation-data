# Destinations Dataflow

## Introduction

Les **destinations** définissent où les données transformées seront chargées. Dataflows Gen2 supportent plusieurs types de destinations Fabric natives.

```
Supported Destinations:
├── Lakehouse Tables
├── Lakehouse Files
├── Data Warehouse Tables
├── KQL Database
└── Azure destinations (Blob, ADLS Gen2, SQL DB)
```

## Configuration Destination

### Via Publish Settings

```
1. Query pane → Right-click query → Set destination
2. Choose destination type
3. Configure connection
4. Map columns (optional)
5. Configure update method
6. Publish dataflow
```

**Destination Panel :**
```
┌────────────────────────────────────────┐
│  Destination Settings                  │
├────────────────────────────────────────┤
│  Destination type: [Lakehouse Table▼]  │
│  Lakehouse: [DataLakehouse▼]           │
│  Table name: [silver_customers]        │
│  Update method: [Replace▼]             │
│  ├─ Replace                            │
│  ├─ Append                             │
│  └─ (Incremental refresh)              │
└────────────────────────────────────────┘
```

## Lakehouse Table Destination

### Configuration

```
Destination: Lakehouse Table
  ├─ Workspace: [Select workspace]
  ├─ Lakehouse: [Select lakehouse]
  ├─ Table name: silver_customers
  ├─ Update method: Replace / Append
  └─ Column mapping: Automatic / Manual
```

### Update Methods

**Replace (Full Refresh) :**
```
Behavior:
  1. Drop existing table (if exists)
  2. Create new table
  3. Insert all rows from dataflow

Use cases:
  • Small dimensions
  • Daily full refresh acceptable
  • No historical tracking needed

Pros:
  ✅ Simple
  ✅ Always fresh data
  ✅ No merge complexity

Cons:
  ❌ Slow for large tables
  ❌ Loses historical data
  ❌ High compute cost
```

**Append :**
```
Behavior:
  1. Keep existing table
  2. Append new rows at end
  3. No updates or deletes

Use cases:
  • Fact tables (incremental loads)
  • Event logs
  • Time-series data

Pros:
  ✅ Fast
  ✅ Preserves history
  ✅ Low compute

Cons:
  ❌ Can create duplicates
  ❌ No updates to existing rows
  ❌ Manual deduplication needed
```

### Column Mapping

**Automatic :**
```
Dataflow automatically maps:
  • Same column names
  • Compatible types

Example:
  Dataflow: customer_id (Text) → Table: customer_id (String) ✅
  Dataflow: amount (Number) → Table: amount (Decimal) ✅
```

**Manual :**
```
Custom mapping:
  Dataflow Column → Table Column
  ─────────────────────────────
  CustomerID → customer_id
  CustomerName → name
  EmailAddress → email
  (ignore) → created_at (use default)
```

### Schema Options

```
Table doesn't exist:
  ✅ Create automatically
  └─ Schema inferred from dataflow

Table exists:
  ├─ Match schema
  │  └─ Validate types match
  ├─ Add new columns
  │  └─ Missing columns added as NULL
  └─ Error on mismatch (strict mode)
```

## Lakehouse Files Destination

### Configuration

```
Destination: Lakehouse Files
  ├─ Lakehouse: [Select lakehouse]
  ├─ Folder path: Files/bronze/customers/
  ├─ File format: Parquet / CSV / JSON
  └─ Partitioning: None / Column-based
```

### File Formats

**Parquet (Recommended) :**
```
Pros:
  ✅ Columnar format (efficient)
  ✅ High compression (50-80%)
  ✅ Fast queries
  ✅ Schema embedded

Settings:
  • Compression: Snappy / Gzip / None
  • Version: 1.0 / 2.0
```

**CSV :**
```
Pros:
  ✅ Human-readable
  ✅ Universal compatibility

Cons:
  ❌ No compression
  ❌ No schema
  ❌ Slow queries

Settings:
  • Delimiter: , (comma) / ; (semicolon) / \t (tab)
  • Quote character: " (double quote)
  • Encoding: UTF-8 / UTF-16
  • Include header: Yes / No
```

**JSON :**
```
Pros:
  ✅ Nested data support
  ✅ Schema flexibility

Cons:
  ❌ Large file size
  ❌ Slow queries

Settings:
  • Format: Array of objects / Line-delimited
```

### Partitioning Files

```
Partition by: year, month

Output structure:
Files/bronze/customers/
  ├── year=2023/
  │   ├── month=01/
  │   │   └── part-0001.parquet
  │   └── month=02/
  │       └── part-0001.parquet
  └── year=2024/
      ├── month=01/
      │   └── part-0001.parquet
      └── month=02/
          └── part-0001.parquet

Benefits:
  ✅ Partition pruning (query only needed folders)
  ✅ Organized by time/category
  ✅ Easy maintenance (delete old partitions)
```

## Data Warehouse Destination

### Configuration

```
Destination: Data Warehouse Table
  ├─ Workspace: [Select workspace]
  ├─ Warehouse: [Select warehouse]
  ├─ Schema: dbo
  ├─ Table name: dim_customer
  ├─ Update method: Replace / Append
  └─ Distribution: Round Robin / Hash / Replicate
```

### Distribution Options

```
Round Robin (Default):
  • Distributes rows evenly
  • Good for staging tables
  WITH (DISTRIBUTION = ROUND_ROBIN)

Hash:
  • Distributes by column hash
  • Good for large tables with JOINs
  WITH (DISTRIBUTION = HASH(customer_id))

Replicate:
  • Copies table to all nodes
  • Good for small dimensions (<2 GB)
  WITH (DISTRIBUTION = REPLICATE)
```

### Table Creation

```sql
-- Dataflow automatically creates:
CREATE TABLE dbo.dim_customer (
    customer_id INT,
    customer_name VARCHAR(200),
    email VARCHAR(200),
    country VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);
```

## Multiple Destinations

### Same Query, Multiple Outputs

```
Query: Cleaned_Customers

Destination 1: Lakehouse Table
  └─ silver_customers (operational)

Destination 2: Warehouse Table
  └─ dim_customer (analytics)

Destination 3: Lakehouse Files
  └─ Files/exports/customers.parquet (archive)

Configuration:
  1. Right-click query
  2. Add destination
  3. Configure each independently
  4. Publish
```

**Behavior :**
```
On refresh:
  1. Dataflow runs transformations once
  2. Results written to all destinations in parallel
  3. All destinations must succeed (or all fail)
```

## Destination Settings

### Connection Credentials

```
Lakehouse/Warehouse:
  • Workspace item picker
  • Automatic authentication (workspace identity)

External (Azure):
  • Connection string
  • Authentication:
    ├─ Account key
    ├─ SAS token
    ├─ Service principal
    └─ Managed identity
```

### Write Settings

**Batch Size :**
```
Default: 10,000 rows per batch

Adjust for:
  • Large rows → Smaller batch (1,000)
  • Small rows → Larger batch (50,000)
  • Network latency → Larger batch
```

**Timeout :**
```
Default: 30 minutes

Increase for:
  • Large datasets (>10M rows)
  • Slow destinations
  • Complex transformations
```

**Retry Policy :**
```
Retries: 3 (default)
Retry interval: 60 seconds

On failure:
  • Retry 3 times
  • If all fail → Dataflow refresh fails
  • Check error logs
```

## Refresh Behavior

### Manual Refresh

```
Dataflow → Refresh now

Behavior:
  1. Run all transformations
  2. Write to destinations
  3. Update "Last refreshed" timestamp
  4. Log success/failure
```

### Scheduled Refresh

```
Dataflow → Settings → Refresh schedule

Options:
  ├─ Frequency: Daily / Weekly / Custom
  ├─ Time: 08:00 AM
  ├─ Time zone: Central European Time
  ├─ Notify on failure: Yes/No
  └─ Email: data-team@company.com

Example schedule:
  • Daily at 8:00 AM
  • Weekdays only
  • Notify on failure
```

### Incremental Refresh

*(Détails dans fichier suivant)*

```
Incremental refresh:
  • Only new/changed data
  • Based on date/time column
  • Reduces refresh time (minutes vs hours)
  • Reduces compute cost
```

## Error Handling

### Destination Errors

**Table Schema Mismatch :**
```
Error: Column 'amount' expects type 'decimal' but got 'string'

Solutions:
  1. Fix transformation (convert type)
  2. Update destination schema
  3. Use manual column mapping
```

**Duplicate Key :**
```
Error: Duplicate key on customer_id (for UNIQUE constraint)

Solutions:
  1. Deduplicate in dataflow
  2. Use MERGE instead of INSERT
  3. Remove UNIQUE constraint (if acceptable)
```

**Permission Denied :**
```
Error: User does not have INSERT permission on table

Solutions:
  1. Grant permissions on destination
  2. Use service account with proper roles
  3. Check workspace access
```

### Partial Failures

```
Scenario: 3 destinations configured

Destination 1 (Lakehouse): ✅ Success
Destination 2 (Warehouse): ❌ Failed (timeout)
Destination 3 (Files): ⏸️ Not attempted

Behavior:
  • Entire refresh fails
  • No partial commits
  • All destinations must succeed

Recovery:
  1. Fix failing destination
  2. Re-run refresh
  3. All destinations re-process
```

## Monitoring

### Refresh History

```
Dataflow → Settings → Refresh history

Table:
┌──────────┬────────┬──────────┬──────────┐
│ Date/Time│ Status │ Duration │ Rows     │
├──────────┼────────┼──────────┼──────────┤
│ 08:00 AM │ ✅     │ 5m 23s   │ 100,000  │
│ 07:00 AM │ ✅     │ 4m 56s   │ 98,500   │
│ 06:00 AM │ ❌     │ 2m 10s   │ 0        │
└──────────┴────────┴──────────┴──────────┘

Details (click row):
  ├─ Query execution times
  ├─ Destination write times
  ├─ Rows written per destination
  └─ Error messages (if failed)
```

### Destination Metrics

```
Per destination:
  • Rows written
  • Data volume (MB)
  • Write duration
  • Success/Failure

Example:
  Lakehouse Table (silver_customers):
    Rows: 100,000
    Size: 15 MB
    Duration: 2m 10s
    Status: ✅

  Warehouse Table (dim_customer):
    Rows: 100,000
    Size: 15 MB
    Duration: 3m 15s
    Status: ✅
```

## Best Practices

### ✅ Destination Selection

```
Lakehouse Tables:
  ✅ Operational data
  ✅ Frequent updates
  ✅ Spark processing downstream
  ✅ Delta Lake features needed

Warehouse Tables:
  ✅ Analytics/BI
  ✅ SQL queries
  ✅ Star schema dimensions/facts
  ✅ Power BI Direct Query

Lakehouse Files:
  ✅ Archives
  ✅ Unstructured data
  ✅ External tool processing
  ✅ Data sharing
```

### ✅ Update Methods

```
Replace:
  ✅ Small tables (<1M rows)
  ✅ Full refresh acceptable
  ✅ Simple logic

Append:
  ✅ Large fact tables
  ✅ Time-series data
  ✅ No updates needed

Incremental:
  ✅ Large tables (>10M rows)
  ✅ Frequent updates
  ✅ Cost optimization critical
```

### ✅ Performance

```
1. Partitioning:
   • File destinations: partition by date
   • Table destinations: let Delta/Warehouse handle

2. Batch size:
   • Default 10K rows usually optimal
   • Increase for small rows
   • Decrease for large/complex rows

3. Parallel writes:
   • Multiple destinations write in parallel
   • Ensure destinations can handle load

4. Compression:
   • Files: Use Parquet with Snappy
   • Tables: Automatic (Delta, Columnstore)
```

### ✅ Error Prevention

```
1. Schema validation:
   • Test with sample data first
   • Validate types match
   • Handle nulls appropriately

2. Deduplication:
   • Before writing to destination
   • Based on business key
   • Keep latest or aggregate

3. Permissions:
   • Verify access before scheduling
   • Use service accounts
   • Test manually first

4. Monitoring:
   • Set up failure alerts
   • Review refresh history regularly
   • Monitor row counts for anomalies
```

## Points Clés

- Destinations: Lakehouse Tables/Files, Warehouse, KQL, Azure
- Update methods: Replace (full), Append (add only), Incremental (new/changed)
- Lakehouse Tables = Delta Lake (operational, Spark)
- Warehouse Tables = Analytics (SQL, BI, star schema)
- Lakehouse Files = Archives (Parquet recommended)
- Multiple destinations per query (parallel writes)
- Schema mapping automatic ou manual
- Refresh: manual, scheduled, ou triggered
- Error handling: all-or-nothing per refresh
- Monitoring via refresh history

---

**Prochain fichier :** [05 - Incremental Refresh](./05-incremental-refresh.md)

[⬅️ Fichier précédent](./03-transformations.md) | [⬅️ Retour au README du module](./README.md)
