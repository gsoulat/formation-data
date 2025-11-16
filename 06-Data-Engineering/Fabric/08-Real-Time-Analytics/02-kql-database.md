# KQL Database

## Introduction

**KQL Database** est le moteur de données optimisé pour l'analytics temps réel dans Fabric, basé sur Azure Data Explorer (ADX).

```
KQL Database Architecture:
┌──────────────────────────────────────────┐
│  KQL Database (Fabric)                   │
├──────────────────────────────────────────┤
│  Azure Data Explorer Engine              │
│  ├─ Columnar storage                     │
│  ├─ Distributed processing               │
│  ├─ Time-series optimized                │
│  └─ Sub-second query performance         │
├──────────────────────────────────────────┤
│  Hot cache (SSD) + Cold storage (Blob)   │
└──────────────────────────────────────────┘
```

## Architecture

### Storage Tiers

```
Two-tier storage:
┌─────────────────────────────────────┐
│  Hot Cache (SSD)                    │
│  ├─ Recent data (configurable)     │
│  ├─ Sub-second queries             │
│  └─ Expensive but fast             │
├─────────────────────────────────────┤
│  Cold Storage (Azure Blob)          │
│  ├─ Historical data                 │
│  ├─ Seconds to minutes queries      │
│  └─ Cost-effective                  │
└─────────────────────────────────────┘

Example policy:
  Hot cache: Last 30 days
  Cold storage: 5+ years retention
```

### Distributed Processing

```
Parallel query execution:
  Query → Parsed → Distributed to nodes → Aggregated → Result

Benefits:
  ✅ Billions of rows in seconds
  ✅ Horizontal scaling
  ✅ Fault tolerance
```

## Création et Configuration

### Via UI

```
1. Workspace → + New → KQL Database
2. Name: "IoT_Analytics"
3. Database created with default settings

Default settings:
  • Soft delete: 30 days
  • Hot cache: 31 days
  • Auto-scale: Enabled

Optional configuration:
  • Onelake availability
  • Query limits
  • Security permissions
```

### Tables et Schémas

**Create Table:**
```kql
.create table Telemetry (
    DeviceId: string,
    Temperature: real,
    Humidity: real,
    Timestamp: datetime,
    Location: string
)
```

**Alter Table (add column):**
```kql
.alter-merge table Telemetry (
    Pressure: real
)
```

**Show Schema:**
```kql
.show table Telemetry schema as json
```

**Show Tables:**
```kql
.show tables
```

## Ingestion Mapping

### JSON Mapping

```kql
.create table Telemetry ingestion json mapping 'TelemetryMapping'
'['
'  {"column": "DeviceId", "path": "$.device_id", "datatype": "string"},'
'  {"column": "Temperature", "path": "$.temp", "datatype": "real"},'
'  {"column": "Humidity", "path": "$.humidity", "datatype": "real"},'
'  {"column": "Timestamp", "path": "$.timestamp", "datatype": "datetime"},'
'  {"column": "Location", "path": "$.location", "datatype": "string"}'
']'
```

**Source JSON:**
```json
{
  "device_id": "sensor_001",
  "temp": 25.3,
  "humidity": 65.2,
  "timestamp": "2024-01-15T10:30:00Z",
  "location": "Factory_A"
}
```

### CSV Mapping

```kql
.create table Logs ingestion csv mapping 'LogsMapping'
'['
'  {"column": "Timestamp", "ordinal": 0, "datatype": "datetime"},'
'  {"column": "Level", "ordinal": 1, "datatype": "string"},'
'  {"column": "Message", "ordinal": 2, "datatype": "string"}'
']'
```

## Policies

### Retention Policy

```kql
// Set retention period
.alter table Telemetry policy retention
```
{ "SoftDeletePeriod": "365.00:00:00", "Recoverability": "Enabled" }
```

// Meaning:
// - Keep data for 365 days
// - Soft delete enabled (can recover for 30 days)
// - After retention, data permanently deleted
```

### Caching Policy

```kql
// Set hot cache period
.alter table Telemetry policy caching hot = 30d

// Meaning:
// - Last 30 days in SSD (fast queries)
// - Older data in blob storage (slower but cheaper)
// - Common for time-series analytics
```

### Partitioning Policy

```kql
// Partition by time (automatic for datetime columns)
.alter table Telemetry policy partitioning
```
{
  "EffectiveDateTime": "2024-01-01",
  "PartitionKeys": [
    {
      "ColumnName": "Timestamp",
      "Kind": "UniformRange",
      "Properties": {
        "Reference": "1970-01-01T00:00:00",
        "RangeSize": "1.00:00:00",
        "OverrideCreationTime": false
      }
    }
  ]
}
```

// Benefits:
// - Faster queries (partition pruning)
// - Efficient data management
// - Optimized for time-based queries
```

## KQL vs SQL

### Query Syntax

```
SQL:
  SELECT DeviceId, AVG(Temperature)
  FROM Telemetry
  WHERE Timestamp > '2024-01-15'
  GROUP BY DeviceId

KQL:
  Telemetry
  | where Timestamp > datetime(2024-01-15)
  | summarize avg(Temperature) by DeviceId

Key differences:
  • KQL uses pipe (|) for chaining
  • SQL uses SELECT...FROM...WHERE...GROUP BY
  • KQL is more readable for analytics
```

### Features Comparison

```
Feature              │ KQL Database │ SQL Database
─────────────────────┼──────────────┼──────────────
Primary use          │ Analytics    │ Transactions
Query language       │ KQL          │ SQL
Time-series          │ Optimized ✅  │ Not optimal
Full-text search     │ Built-in ✅   │ Add-on
Schema flexibility   │ High ✅       │ Strict
ACID transactions    │ Limited ❌    │ Full ✅
Write pattern        │ Append-only  │ CRUD
Query performance    │ Billions/sec │ Millions/sec
```

### When to Use

```
Use KQL Database when:
  ✅ Log analytics
  ✅ IoT telemetry
  ✅ Time-series data
  ✅ Read-heavy workloads
  ✅ Semi-structured data (JSON)

Use SQL Database when:
  ✅ Transactional workloads
  ✅ ACID requirements
  ✅ CRUD operations
  ✅ Referential integrity
  ✅ Complex joins
```

## Data Types

### Common Types

```kql
// Basic types
string      // "Hello World"
int         // 42
long        // 9223372036854775807
real        // 3.14159
bool        // true, false
datetime    // datetime(2024-01-15T10:30:00Z)
timespan    // 1d, 2h, 30m, 45s
guid        // guid(12345678-1234-1234-1234-123456789012)
dynamic     // JSON object/array

// Example table
.create table Events (
    EventId: guid,
    EventType: string,
    Payload: dynamic,
    Timestamp: datetime,
    Duration: timespan,
    Success: bool,
    Value: real
)
```

### Dynamic Type

```kql
// Dynamic = JSON/semi-structured data
// Example event:
{
  "EventId": "abc-123",
  "Payload": {
    "user": "alice",
    "action": "purchase",
    "items": ["item1", "item2"],
    "amount": 150.00
  }
}

// Query nested fields
Events
| extend User = Payload.user
| extend Amount = Payload.amount
| extend ItemCount = array_length(Payload.items)

// Benefits:
// - Schema flexibility
// - No need to pre-define all fields
// - Easy JSON exploration
```

## Security

### Permissions

```
Permission levels:
  • Admin: Full control (create tables, policies)
  • User: Read data, run queries
  • Viewer: Read-only dashboards

Configuration:
  Database → Permissions → Add user/group

Best practice:
  Use least privilege principle
  Assign roles to security groups (not individuals)
```

### Row-Level Security

```kql
// Create security function
.create function with (
    view=true
) UserTelemetry() {
    Telemetry
    | where Location in (
        Users
        | where UserEmail == current_principal()
        | distinct AllowedLocation
    )
}

// Users see only their assigned locations
// Based on current_principal() (logged-in user)
```

## Best Practices

### ✅ Schema Design

```
1. Use appropriate data types
   datetime for timestamps (not string)
   real for decimals (not string)
   guid for unique IDs

2. Avoid wide tables
   Max ~1000 columns
   Normalize if needed (but not like SQL)

3. Use dynamic for flexible data
   Good for JSON payloads
   Extract common fields as typed columns
```

### ✅ Query Optimization

```
1. Filter early (where before summarize)
2. Use time filters (automatic partition pruning)
3. Limit results (top, take)
4. Avoid expensive operations on large datasets
5. Use materialized views for common queries
```

### ✅ Data Management

```
1. Set appropriate retention (don't keep forever)
2. Configure hot cache based on query patterns
3. Monitor storage costs
4. Archive to Lakehouse for long-term storage
```

## Points Clés

- KQL Database = Azure Data Explorer in Fabric
- Optimized for time-series and log analytics
- Two-tier storage: hot cache (SSD) + cold storage (blob)
- Policies: retention, caching, partitioning
- Ingestion mapping for JSON, CSV, Avro
- KQL vs SQL: analytics-focused vs transaction-focused
- Dynamic type for semi-structured JSON data
- Security with permissions and RLS
- Best practices: proper types, early filtering, retention policies

---

**Prochain fichier :** [03 - Kusto Query Language](./03-kusto-query-language.md)

[⬅️ Fichier précédent](./01-eventstream-overview.md) | [⬅️ Retour au README du module](./README.md)
