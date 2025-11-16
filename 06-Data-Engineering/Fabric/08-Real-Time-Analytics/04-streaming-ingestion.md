# Streaming Ingestion

## Introduction

**Streaming Ingestion** est le processus d'absorption continue de données en temps réel vers KQL Database, permettant des analyses sur données fraîches avec latence minimale.

```
Streaming Ingestion Pipeline:
┌──────────┐   ┌─────────────┐   ┌───────────┐   ┌──────────┐
│  Source  │ → │ EventStream │ → │ Ingestion │ → │ KQL DB   │
│ (Events) │   │  (Buffer)   │   │ (Process) │   │ (Query)  │
└──────────┘   └─────────────┘   └───────────┘   └──────────┘
     ↓              ↓                  ↓              ↓
   1M/sec      Partitioned        Micro-batch     Sub-second
```

## Modes d'Ingestion

### Streaming vs Batched

```
Streaming Ingestion:
  • Latency: Seconds (1-10s)
  • Use case: Real-time analytics
  • Cost: Higher (continuous processing)
  • Data freshness: Very high

Batched Ingestion:
  • Latency: Minutes to hours
  • Use case: Historical analytics
  • Cost: Lower (scheduled processing)
  • Data freshness: Periodic updates

Hybrid:
  • Hot path: Streaming (recent data)
  • Cold path: Batched (historical data)
  • Best of both worlds
```

### Queued Ingestion

```
Queued Ingestion (default in Fabric):
  1. Data lands in queue (Azure Blob)
  2. Background process picks up
  3. Optimizes and compresses
  4. Writes to KQL Database

Characteristics:
  ✅ High throughput
  ✅ Optimal compression
  ✅ Cost-effective
  ⚠️ Higher latency (minutes)

Use for:
  • Bulk historical data load
  • Large file ingestion
  • Non-time-sensitive data
```

### Direct Streaming

```
Direct Streaming Ingestion:
  1. Data sent directly to KQL engine
  2. Immediate write to storage
  3. Available for query instantly

Characteristics:
  ✅ Low latency (seconds)
  ✅ Real-time availability
  ⚠️ Lower compression (initially)
  ⚠️ Higher cost

Use for:
  • Real-time monitoring
  • Alerts and triggers
  • Time-sensitive analytics
```

## Configuration EventStream → KQL Database

### Setup Process

```
1. Create EventStream
   Workspace → + New → EventStream
   Name: "IoT_Telemetry_Stream"

2. Add Source
   • Event Hub / IoT Hub / Kafka
   • Configure connection
   • Test connectivity

3. Add Destination (KQL Database)
   • Select database
   • Configure table
   • Define mapping
   • Set ingestion mode

4. Deploy and Monitor
   • Start stream
   • Verify data flow
   • Monitor metrics
```

### Destination Configuration

```
KQL Database Destination Settings:
┌─────────────────────────────────────┐
│ Database: IoT_Analytics             │
│ Table: Telemetry                    │
│ Mapping: TelemetryMapping           │
│ Format: JSON                        │
│ Ingestion mode: Streaming           │
│ Batch size: 1000 events             │
│ Batch timeout: 5 seconds            │
└─────────────────────────────────────┘

Batching logic:
  • Wait for 1000 events OR 5 seconds
  • Whichever comes first
  • Balances throughput vs latency
```

## Data Mapping

### JSON to Table Mapping

```kql
// Source JSON:
{
  "device_id": "sensor_001",
  "readings": {
    "temperature": 25.3,
    "humidity": 65.2
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "location": {
    "factory": "A",
    "zone": "North"
  }
}

// Create mapping
.create table Telemetry ingestion json mapping 'FlatMapping'
'['
'  {"column": "DeviceId", "path": "$.device_id"},'
'  {"column": "Temperature", "path": "$.readings.temperature"},'
'  {"column": "Humidity", "path": "$.readings.humidity"},'
'  {"column": "Timestamp", "path": "$.timestamp"},'
'  {"column": "Factory", "path": "$.location.factory"},'
'  {"column": "Zone", "path": "$.location.zone"}'
']'

// Resulting table row:
// DeviceId    | Temperature | Humidity | Timestamp           | Factory | Zone
// sensor_001  | 25.3        | 65.2     | 2024-01-15T10:30:00 | A       | North
```

### Handling Nested Arrays

```kql
// Source JSON with array:
{
  "device_id": "sensor_001",
  "alerts": [
    {"type": "high_temp", "severity": "critical"},
    {"type": "low_battery", "severity": "warning"}
  ]
}

// Option 1: Store as dynamic (JSON)
.create table Alerts (
    DeviceId: string,
    AlertData: dynamic  // Stores entire array
)

// Mapping
.create table Alerts ingestion json mapping 'AlertMapping'
'['
'  {"column": "DeviceId", "path": "$.device_id"},'
'  {"column": "AlertData", "path": "$.alerts"}'
']'

// Query nested data
Alerts
| mv-expand Alert = AlertData
| extend AlertType = Alert.type, Severity = Alert.severity
| where Severity == "critical"
```

### Transformation During Ingestion

```kql
// Apply transformations via update policy
.create table RawTelemetry (
    RawData: dynamic
)

.create table ProcessedTelemetry (
    DeviceId: string,
    Temperature: real,
    TemperatureFahrenheit: real,
    Timestamp: datetime,
    IsHigh: bool
)

// Create transformation function
.create function TransformTelemetry() {
    RawTelemetry
    | extend
        DeviceId = tostring(RawData.device_id),
        Temperature = todouble(RawData.temperature),
        Timestamp = todatetime(RawData.timestamp)
    | extend
        TemperatureFahrenheit = Temperature * 9/5 + 32,
        IsHigh = Temperature > 30
    | project DeviceId, Temperature, TemperatureFahrenheit, Timestamp, IsHigh
}

// Apply update policy (automatic transformation)
.alter table ProcessedTelemetry policy update
'[{"IsEnabled": true, "Source": "RawTelemetry", "Query": "TransformTelemetry()", "IsTransactional": false}]'

// Data flows: Source → RawTelemetry → ProcessedTelemetry (automatic)
```

## Throughput et Performance

### Capacity Planning

```
Throughput considerations:
  • Events per second (EPS)
  • Event size (bytes)
  • Total bytes per second
  • Number of partitions

Example calculation:
  EPS: 100,000 events/second
  Event size: 1 KB
  Throughput: 100 MB/second

  Requirements:
    • High-capacity EventStream
    • Multiple partitions (32-64)
    • KQL Database auto-scale enabled
```

### Partitioning Strategy

```
Partition key selection:
  Good keys (high cardinality):
    ✅ device_id (millions of devices)
    ✅ customer_id (millions of customers)
    ✅ transaction_id (unique per event)

  Bad keys (low cardinality):
    ❌ country (200 countries = 200 partitions max)
    ❌ level (3 levels = hot partitions)
    ❌ boolean (2 values)

Configuration:
  Partitions: 32 (balance processing)
  Each partition: ~3,000 EPS
  Total: ~100,000 EPS
```

### Backpressure Handling

```
When downstream can't keep up:

Symptoms:
  • Consumer lag increasing
  • Events queuing up
  • Processing delays

Solutions:
  1. Increase KQL Database capacity
     • More ingestion resources
     • Higher throughput unit

  2. Optimize ingestion
     • Larger batch sizes
     • Less frequent flushes
     • Better compression

  3. Scale EventStream
     • More partitions
     • Higher throughput units

  4. Filter at source
     • Remove unnecessary events
     • Sample high-frequency data

Monitoring:
  • Consumer lag metric
  • Ingestion latency
  • Queue depth
```

## Gestion des Erreurs

### Dead Letter Queue

```
Configure DLQ for failed events:

EventStream → Destination (KQL DB)
  → On error: Send to Dead Letter Queue

DLQ contents:
  • Original event payload
  • Error message
  • Timestamp
  • Retry count

Example errors:
  • Schema mismatch (missing field)
  • Type conversion failure
  • Database unavailable
  • Quota exceeded

Remediation:
  1. Monitor DLQ size
  2. Investigate errors
  3. Fix source data or mapping
  4. Replay events if needed
```

### Retry Policies

```
Automatic retry configuration:

Policy:
  Max retries: 3
  Initial delay: 1 second
  Backoff multiplier: 2x
  Max delay: 30 seconds

Retry sequence:
  Attempt 1: Immediate
  Attempt 2: Wait 1 second
  Attempt 3: Wait 2 seconds
  Attempt 4: Wait 4 seconds
  Failed: Send to DLQ

Retryable errors:
  ✅ Temporary database unavailable
  ✅ Throttling (quota exceeded)
  ✅ Network timeout

Non-retryable:
  ❌ Schema mismatch
  ❌ Invalid data format
  ❌ Authentication failure
```

### Schema Evolution

```
Handling schema changes:

Scenario: New field added to events
  Before: {"device_id": "001", "temp": 25}
  After:  {"device_id": "001", "temp": 25, "pressure": 1013}

Option 1: Add column (recommended)
  .alter-merge table Telemetry (Pressure: real)

  Update mapping to include new field
  Old events: Pressure = null
  New events: Pressure = value

Option 2: Use dynamic column
  Store entire payload as dynamic
  Extract fields at query time
  Flexible but slightly slower

Option 3: New table version
  Create Telemetry_v2
  Route new events to v2
  Query with union Telemetry, Telemetry_v2
```

## Monitoring Ingestion

### Key Metrics

```
Essential metrics to monitor:

1. Ingestion latency
   • Time from event creation to query availability
   • Target: < 10 seconds
   • Alert: > 60 seconds

2. Events per second
   • Current throughput
   • Compare to capacity
   • Alert on drop

3. Ingestion failures
   • Count of failed events
   • Error rate percentage
   • Alert: > 1%

4. Consumer lag
   • Events waiting to be processed
   • Increasing = falling behind
   • Alert: > 10,000 events

5. Database size growth
   • MB/hour ingested
   • Retention impact
   • Storage cost projection
```

### Monitoring Commands

```kql
// Ingestion insights
.show ingestion failures

// Returns:
// Table | OperationId | FailureKind | Details | OriginatesFromUpdatePolicy

// Check ingestion metrics
.show table Telemetry ingestion statistics

// Returns:
// Count | Size | Duration | LastUpdated

// Monitor streaming ingestion
.show streamingingestion statistics

// Check database size
.show database IoT_Analytics datastats
```

### Alerting Configuration

```
Set up alerts for:

1. High latency alert
   Condition: Avg latency > 30 seconds for 5 minutes
   Action: Notify ops team
   Severity: High

2. Failed ingestion spike
   Condition: Error rate > 5% for 10 minutes
   Action: PagerDuty alert
   Severity: Critical

3. Consumer lag growing
   Condition: Lag increasing for 15 minutes
   Action: Auto-scale trigger
   Severity: Medium

4. Throughput drop
   Condition: EPS < 50% of baseline for 10 minutes
   Action: Investigate source
   Severity: High

Integration:
  • Data Activator for Fabric-native alerts
  • Azure Monitor for infrastructure
  • Power Automate for workflows
```

## Use Cases Avancés

### Multi-Destination Routing

```
Single EventStream → Multiple destinations

Architecture:
  EventStream
    ├─→ KQL Database (hot analytics)
    ├─→ Lakehouse (cold storage)
    └─→ Custom endpoint (alerts)

Configuration:
  1. Add first destination (KQL DB)
     • All events
     • Real-time queries

  2. Add second destination (Lakehouse)
     • All events (Delta format)
     • Historical analytics
     • Cost-effective storage

  3. Add third destination (Webhook)
     • Filter: Level == "Critical"
     • Only critical events
     • Trigger external alert system

Benefits:
  ✅ Single ingestion point
  ✅ Multiple analytics patterns
  ✅ Cost optimization
```

### Enrichment Pipeline

```
Enrich streaming data with reference data:

Stream: Order events
Reference: Customer master data

Architecture:
  [Order Events] → [EventStream] → [KQL DB: Orders]
                         ↓
                   [Join with Customer]
                         ↓
                   [KQL DB: EnrichedOrders]

KQL enrichment function:
.create function EnrichOrders() {
    RawOrders
    | join kind=inner (Customers) on CustomerId
    | project
        OrderId,
        OrderDate,
        Amount,
        CustomerName,
        CustomerSegment,
        Region
}

// Apply as update policy
.alter table EnrichedOrders policy update
'[{"Source": "RawOrders", "Query": "EnrichOrders()"}]'

Result:
  Raw orders enriched with customer attributes
  Real-time customer segmentation
  Regional analytics
```

### Deduplication

```
Handle duplicate events in stream:

Scenario:
  IoT device retransmits on network failure
  Same event received multiple times

Solution: Deduplication table
.create table Telemetry_Deduped (
    EventId: string,
    DeviceId: string,
    Temperature: real,
    Timestamp: datetime
)

// Deduplication function
.create function DeduplicateTelemetry() {
    RawTelemetry
    | summarize arg_max(ingestion_time(), *) by EventId
    // Keep only first occurrence of each EventId
}

Alternative: Query-time deduplication
Telemetry
| summarize arg_min(Timestamp, *) by EventId
| project-away EventId1  // Remove duplicate column

Trade-offs:
  ✅ Ingestion-time: Clean data, higher ingestion cost
  ✅ Query-time: Simple ingestion, query overhead
```

## Best Practices

### Design Principles

```
1. Right-size batching
   • Small batches: Lower latency, higher cost
   • Large batches: Higher latency, better throughput
   • Balance: 1000-10000 events or 5-30 seconds

2. Schema design
   • Flat structure (avoid deep nesting)
   • Appropriate data types (datetime, not string)
   • Include ingestion metadata

3. Partition strategy
   • High-cardinality key
   • Even distribution
   • Avoid hot spots

4. Error handling
   • DLQ always enabled
   • Monitor error rates
   • Automate remediation
```

### Performance Optimization

```
1. Optimize payload size
   ❌ Bad: Include unnecessary fields
   ✅ Good: Only required fields

2. Use appropriate serialization
   ✅ JSON: Readable, flexible
   ✅ Avro: Compact, schema registry
   ❌ XML: Verbose, slow parsing

3. Compression
   Enable GZIP for JSON payloads
   Reduces bandwidth 60-80%
   Small CPU overhead

4. Indexing strategy
   KQL Database auto-indexes
   Partition by time (automatic)
   Consider column ordering
```

### Operational Excellence

```
1. Monitoring checklist
   □ Latency dashboard
   □ Throughput metrics
   □ Error rate alerts
   □ Consumer lag tracking

2. Runbooks
   □ High latency investigation
   □ Failed ingestion recovery
   □ Scale-up procedures
   □ Schema change process

3. Testing
   □ Load testing (peak traffic)
   □ Failure scenarios (source down)
   □ Schema evolution tests
   □ Recovery procedures

4. Documentation
   □ Architecture diagram
   □ Data flow documentation
   □ Mapping specifications
   □ SLA definitions
```

## Points Clés

- Streaming ingestion = continuous data flow with low latency (seconds)
- Queued vs Direct streaming: trade-off between throughput and latency
- EventStream to KQL Database: configure mapping, batching, error handling
- Data mapping: JSON path expressions to table columns
- Update policies: automatic transformation during ingestion
- Throughput planning: events/second, partition strategy, capacity
- Error handling: DLQ, retry policies, schema evolution
- Monitoring: latency, throughput, failures, consumer lag
- Advanced patterns: multi-destination, enrichment, deduplication
- Best practices: right-size batching, optimize payload, monitor continuously

---

**Prochain fichier :** [05 - Real-Time Dashboards](./05-real-time-dashboards.md)

[⬅️ Fichier précédent](./03-kusto-query-language.md) | [⬅️ Retour au README du module](./README.md)
