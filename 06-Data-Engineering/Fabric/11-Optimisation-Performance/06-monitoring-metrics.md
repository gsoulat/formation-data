# Monitoring et Métriques

## Capacity Metrics App

```
Microsoft Fabric Capacity Metrics:
  • Monitor capacity utilization
  • Track CU (Capacity Unit) consumption
  • Identify peak usage times
  • Plan capacity scaling

Key metrics:
  • CU seconds (compute consumption)
  • Active users
  • Query durations
  • Throttling events

Access:
  Fabric Admin Portal → Capacity settings → Metrics app
  Or: Install from AppSource
```

## Monitoring Hub

```
Fabric Monitoring Hub:
  Location: Workspace → Monitoring hub

Features:
  • Pipeline runs history
  • Notebook executions
  • Dataflow refreshes
  • Spark job status

View:
  • Start/end times
  • Duration
  • Status (success/failed)
  • Error messages

Filters:
  • By item type
  • By date range
  • By status
  • By user
```

## Spark UI Analysis

```
Access Spark UI:
  Notebook → Monitoring → Spark UI

Key tabs:

1. Jobs tab:
   • Completed jobs
   • Failed jobs
   • Duration per job

2. Stages tab:
   • Task distribution
   • Shuffle read/write
   • Executor time

3. Storage tab:
   • Cached RDDs
   • Memory usage
   • Disk spill

4. Environment tab:
   • Spark configuration
   • System properties

5. Executors tab:
   • Memory usage per executor
   • GC time
   • Task count

Look for:
  ❌ Long stage durations → Optimize query
  ❌ High shuffle → Reduce data movement
  ❌ Executor OOM → Increase memory
  ❌ Uneven tasks → Data skew
```

## Performance Analyzer (Power BI)

```
Built-in Power BI tool:
  View tab → Performance Analyzer

Measures:
  • DAX query time
  • Visual rendering time
  • Other (network, etc.)

Usage:
  1. Start recording
  2. Interact with report
  3. Stop recording
  4. Analyze results

Copy DAX query:
  • Test in DAX Studio
  • Identify bottlenecks
  • Optimize measures

Target:
  • DAX query < 1 second
  • Total page load < 3 seconds
```

## Custom Alerts

```
Set up monitoring alerts:

Examples:
  1. Pipeline failure
     Condition: Status = Failed
     Action: Email notification

  2. Long running query
     Condition: Duration > 10 minutes
     Action: Teams message

  3. Capacity threshold
     Condition: CU usage > 80%
     Action: Scale up warning

  4. Data freshness
     Condition: Last refresh > 2 hours
     Action: Investigate

Tools:
  • Data Activator (Fabric native)
  • Azure Monitor (infrastructure)
  • Power Automate (workflows)
  • Custom dashboards
```

## Log Analytics Integration

```
Export logs to Log Analytics:
  • Long-term retention
  • Advanced querying (KQL)
  • Cross-service correlation
  • Custom dashboards

Setup:
  1. Create Log Analytics workspace
  2. Configure diagnostic settings
  3. Route Fabric logs
  4. Query with KQL

Example KQL query:
  FabricAuditLogs
  | where TimeGenerated > ago(24h)
  | where OperationName == "RefreshDataset"
  | summarize count() by Status
```

## Key Performance Metrics

```
Track regularly:

Data Engineering:
  • Pipeline success rate (>99%)
  • Average refresh time
  • Data latency (source to lakehouse)
  • Storage growth

Analytics:
  • Query response time (<3s)
  • Report load time
  • Active users
  • Cache hit rate

ML:
  • Model training duration
  • Prediction latency
  • Model accuracy drift
  • Feature freshness

Capacity:
  • CU utilization (<80%)
  • Throttling events (0)
  • Cost per workload
  • Peak vs off-peak usage
```

---

[⬅️ Précédent](./05-spark-tuning.md) | [Prochain ➡️](./07-troubleshooting.md)
