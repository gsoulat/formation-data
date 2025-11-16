# EventStream Overview

## Introduction

**EventStream** est le service de streaming de données dans Microsoft Fabric, permettant l'ingestion, la transformation, et le routage d'événements en temps réel.

```
EventStream Architecture:
┌──────────────┐   ┌─────────────┐   ┌──────────────┐
│   Sources    │ → │ EventStream │ → │ Destinations │
│  (Event Hub, │   │ (Process &  │   │  (KQL DB,    │
│   IoT Hub,   │   │  Transform) │   │   Lakehouse, │
│   Kafka)     │   │             │   │   Custom)    │
└──────────────┘   └─────────────┘   └──────────────┘
```

## Qu'est-ce qu'EventStream ?

### Définition

```
EventStream = Managed streaming service in Fabric

Capabilities:
  ✅ Ingest millions of events/second
  ✅ Transform data in-flight
  ✅ Route to multiple destinations
  ✅ No infrastructure management
  ✅ Built-in monitoring

Use cases:
  • IoT telemetry processing
  • Log analytics
  • Real-time fraud detection
  • Live dashboards
  • Operational monitoring
```

### Architecture

```
Underlying technology:
┌──────────────────────────────────────────┐
│  EventStream (Fabric UI)                 │
├──────────────────────────────────────────┤
│  Event Processor Host                    │
│  ├─ Apache Kafka compatible              │
│  ├─ Partitioned streams                  │
│  └─ Exactly-once delivery                │
├──────────────────────────────────────────┤
│  Azure Event Hubs (backend)              │
│  ├─ High throughput                      │
│  ├─ Low latency                          │
│  └─ Scalable                             │
└──────────────────────────────────────────┘
```

## Sources Supportées

### Azure Event Hubs

```
Most common source for enterprise streaming

Configuration:
  • Connection string
  • Consumer group
  • Namespace
  • Event Hub name

Example:
  Event Hub: iot-telemetry-hub
  Consumer Group: $Default
  Throughput: 1M events/minute

Use case:
  Application logs, IoT data, business events
```

### Azure IoT Hub

```
Specialized for IoT devices

Features:
  • Device registry
  • Device-to-cloud messaging
  • Cloud-to-device messaging
  • Security (X.509 certificates)

Configuration:
  • IoT Hub connection string
  • Consumer group
  • Built-in endpoint

Use case:
  Temperature sensors, machinery telemetry, GPS trackers
```

### Apache Kafka

```
Open-source streaming platform

Configuration:
  • Kafka bootstrap servers
  • Topic name
  • Consumer group
  • Security (SASL, SSL)

Example:
  Servers: kafka-broker1:9092,kafka-broker2:9092
  Topic: sales-events
  Group: fabric-consumer

Use case:
  Event-driven microservices, log aggregation
```

### Custom Endpoints

```
For custom applications

Options:
  • REST API ingestion
  • SDK-based ingestion (Python, C#, Java)
  • Sample data generator (testing)

Example:
  POST https://eventstream-endpoint.fabric.microsoft.com/ingest
  Headers: Authorization: Bearer <token>
  Body: {"event": "purchase", "amount": 150.00}

Use case:
  Custom applications, legacy systems integration
```

## Destinations

### KQL Database

```
Primary destination for real-time analytics

Benefits:
  ✅ Sub-second query performance
  ✅ Time-series optimized
  ✅ KQL query language
  ✅ Real-time dashboards

Configuration:
  • Database name
  • Table name (auto-create or existing)
  • Mapping (JSON → table columns)

Data flow:
  EventStream → KQL Database → KQL Queries → Dashboards
```

### Lakehouse

```
For long-term storage and batch analytics

Benefits:
  ✅ Delta Lake format
  ✅ Batch + streaming unified
  ✅ Cost-effective storage
  ✅ Spark processing

Configuration:
  • Lakehouse name
  • Table name
  • File format (Delta)

Data flow:
  EventStream → Lakehouse Tables → Spark Notebooks
```

### Custom Applications

```
External systems and services

Options:
  • Webhooks (HTTP POST)
  • Azure Functions
  • Power Automate
  • Third-party services

Example:
  Webhook → Azure Function → Custom processing

Use case:
  Real-time alerts, external integrations, custom logic
```

## Création d'EventStream

### Via UI

```
Step-by-step:
1. Workspace → + New → EventStream
2. Name: "IoT_Telemetry_Stream"
3. Add source:
   • Select "Event Hub"
   • Configure connection
   • Test connection
4. Add destination:
   • Select "KQL Database"
   • Choose database
   • Define table schema
5. Deploy and monitor

Visual representation:
  [Event Hub] ──→ [EventStream] ──→ [KQL Database]
```

### Transformations

```
In-flight data transformations:

Operations:
  • Filter: Remove unwanted events
  • Project: Select specific fields
  • Aggregate: Group events (tumbling/hopping windows)
  • Expand: Flatten nested JSON
  • Join: Enrich with reference data

Example:
  Source (JSON):
    {"device_id": "sensor001", "temp": 25.3, "timestamp": "..."}

  Transform (Filter + Project):
    | where temp > 20
    | project device_id, temp

  Destination:
    Table with device_id, temp columns
```

## Use Cases Typiques

### IoT Telemetry

```
Scenario:
  Factory sensors → Real-time monitoring

Architecture:
  [1000+ Sensors] → [IoT Hub] → [EventStream] → [KQL DB] → [Dashboard]
                                      ↓
                                 [Activator] → [Alerts]

Data:
  {
    "sensor_id": "machine_001_temp",
    "value": 85.2,
    "unit": "celsius",
    "timestamp": "2024-01-15T10:30:00Z"
  }

Analytics:
  • Real-time temperature monitoring
  • Anomaly detection (overheating)
  • Predictive maintenance
  • Historical trends
```

### Log Analytics

```
Scenario:
  Application logs → Error detection

Architecture:
  [Web Apps] → [Event Hub] → [EventStream] → [KQL DB] → [Queries]
                                                            ↓
                                                      [Error Dashboard]

Data:
  {
    "timestamp": "2024-01-15T10:30:05Z",
    "level": "ERROR",
    "message": "Database connection failed",
    "service": "auth-service",
    "trace_id": "abc123"
  }

Analytics:
  • Error rate monitoring
  • Slow request detection
  • Service health metrics
  • Root cause analysis
```

### Fraud Detection

```
Scenario:
  Financial transactions → Real-time scoring

Architecture:
  [Transactions] → [Event Hub] → [EventStream] → [ML Scoring] → [Action]
                                      ↓
                                 [KQL DB] → [Dashboards]

Data:
  {
    "transaction_id": "txn_123",
    "amount": 5000,
    "location": "Paris",
    "user_id": "user_456",
    "timestamp": "2024-01-15T10:30:10Z"
  }

Analytics:
  • Real-time fraud scoring
  • Anomaly detection
  • Pattern recognition
  • Immediate blocking
```

## Configuration Avancée

### Partitioning

```
Distribute load across partitions

Configuration:
  Partition key: device_id
  Number of partitions: 32

Benefits:
  ✅ Parallel processing
  ✅ Ordered events (within partition)
  ✅ Scalability

Best practice:
  Use high-cardinality key (e.g., device_id, user_id)
  Avoid hot partitions (uneven distribution)
```

### Checkpointing

```
Track processing progress

Purpose:
  • Fault tolerance
  • Exactly-once delivery
  • Resume after failure

Configuration:
  Checkpoint interval: 60 seconds
  Storage: Automatic (managed by Fabric)

Behavior:
  Event processed → Checkpoint updated → Safe to commit
  Failure → Resume from last checkpoint
```

### Error Handling

```
Manage failed events

Options:
  • Dead letter queue (store failed events)
  • Retry policy (automatic retries)
  • Skip and log (continue processing)

Configuration:
  Max retries: 3
  Retry delay: 10 seconds
  Dead letter: Enabled

Monitoring:
  • Failed event count
  • Retry rate
  • Dead letter queue size
```

## Monitoring

### Metrics

```
Key metrics to monitor:

Ingestion:
  • Events/second (throughput)
  • Bytes/second (data volume)
  • Latency (time from source to destination)

Processing:
  • Backlog (events waiting)
  • Consumer lag (behind source)
  • Processing errors

Health:
  • Source connectivity
  • Destination availability
  • Partition balance

Dashboard:
  Fabric Workspace → EventStream → Monitoring tab
```

### Alerts

```
Set up proactive alerts:

Examples:
  • Consumer lag > 1000 events
  • Error rate > 1%
  • Throughput drop > 50%

Integration:
  Data Activator → Teams/Email notification
  Power Automate → Custom workflow
```

## Best Practices

### ✅ Source Configuration

```
1. Use appropriate throughput units
   • Start small, scale as needed
   • Monitor utilization

2. Partition strategy
   • High cardinality key
   • Even distribution
   • Avoid hot spots

3. Consumer groups
   • Separate groups for different consumers
   • Avoid conflicts
```

### ✅ Transformation

```
1. Filter early
   • Reduce data volume at source
   • Lower processing cost

2. Flatten nested JSON
   • Easier querying downstream
   • Better performance

3. Add metadata
   • ingestion_time
   • source_id
   • processing_id
```

### ✅ Destination

```
1. Schema management
   • Define schema explicitly
   • Handle schema evolution

2. Batching
   • Optimal batch size (1000-10000 events)
   • Balance latency vs throughput

3. Error handling
   • Dead letter queue enabled
   • Monitor failures
   • Retry policy configured
```

## Points Clés

- EventStream = managed streaming service in Fabric
- Sources: Event Hub, IoT Hub, Kafka, custom endpoints
- Destinations: KQL Database, Lakehouse, custom apps
- Transformations: filter, project, aggregate in-flight
- Use cases: IoT telemetry, log analytics, fraud detection
- Partitioning for scalability and parallel processing
- Checkpointing for fault tolerance and exactly-once delivery
- Monitor throughput, latency, errors continuously
- Configure alerts for proactive monitoring
- Best practices: filter early, batch appropriately, handle errors

---

**Prochain fichier :** [02 - KQL Database](./02-kql-database.md)

[⬅️ Retour au README du module](./README.md)
