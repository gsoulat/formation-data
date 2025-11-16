# Troubleshooting

## Méthodologie de Diagnostic

```
Systematic approach:
1. Identify symptoms (slow, failing, errors)
2. Gather evidence (logs, metrics, error messages)
3. Isolate problem (which component?)
4. Form hypothesis
5. Test solution
6. Document findings
```

## Common Bottlenecks

### Out of Memory (OOM)

```
Symptoms:
  • "Java heap space" error
  • Executor lost
  • Job killed

Causes:
  • Data too large for executor
  • Skewed partition
  • Too many cached objects

Solutions:
  # Increase memory
  spark.conf.set("spark.executor.memory", "16g")

  # Enable off-heap
  spark.conf.set("spark.memory.offHeap.enabled", "true")

  # Reduce partition size
  spark.conf.set("spark.sql.shuffle.partitions", "400")

  # Clear cache
  spark.catalog.clearCache()

  # Filter data earlier
  df.filter(condition).groupBy()  # Not: groupBy().filter()
```

### Slow Queries

```
Diagnosis:
  1. Check execution plan (EXPLAIN)
  2. Look for full table scans
  3. Identify missing partition pruning
  4. Check for data skew

Solutions:
  # Add filters on partition columns
  WHERE year = 2024 AND month = 6

  # Use appropriate indexes/Z-Order
  OPTIMIZE table ZORDER BY (customer_id)

  # Simplify complex joins
  # Break into smaller steps

  # Reduce data volume
  SELECT only needed columns
  Filter early in query
```

### Network/Timeout Errors

```
Symptoms:
  • "Connection timed out"
  • "Network unreachable"
  • Slow data transfers

Causes:
  • Network congestion
  • Large data shuffles
  • Remote data source issues

Solutions:
  # Increase timeout
  spark.conf.set("spark.network.timeout", "600s")

  # Reduce shuffle data
  Use broadcast joins

  # Check data source connectivity
  Test connection separately

  # Use local data (OneLake)
  Avoid cross-region transfers
```

### Pipeline Failures

```
Common errors:

1. "Resource not found"
   • Check table/file exists
   • Verify permissions
   • Correct path spelling

2. "Schema mismatch"
   • Source schema changed
   • Update pipeline mapping
   • Check data types

3. "Capacity exceeded"
   • Wait for capacity
   • Optimize workload
   • Scale up capacity

4. "Authentication failed"
   • Credentials expired
   • Refresh connection
   • Check service principal

Troubleshooting steps:
  1. Read error message carefully
  2. Check activity run details
  3. Review input/output
  4. Test individual components
  5. Check activity logs
```

## Diagnostic Tools

```
Fabric tools:
  • Monitoring Hub (run history)
  • Spark UI (job details)
  • Activity logs (audit trail)
  • Capacity Metrics (resource usage)

External tools:
  • DAX Studio (Power BI)
  • Azure Data Studio (SQL)
  • Log Analytics (centralized logging)
  • Azure Monitor (infrastructure)

Quick checks:
  # Table exists?
  spark.catalog.tableExists("table_name")

  # Data preview
  df.limit(10).show()

  # Schema check
  df.printSchema()

  # Row count
  df.count()

  # Partition info
  spark.sql("DESCRIBE DETAIL table").show()
```

## Best Practices

```
1. Preventive monitoring
   Set up alerts before issues
   Regular health checks
   Track trends over time

2. Document solutions
   Keep runbook of common issues
   Share with team
   Update as platform evolves

3. Test changes
   Benchmark before/after
   Test at scale (not sample data)
   Validate in non-prod first

4. Incremental debugging
   Isolate one variable at a time
   Don't change multiple things
   Measure impact of each change

5. Know your baselines
   Normal query time: X seconds
   Typical memory usage: Y GB
   Expected refresh duration: Z minutes
   Compare to baselines when troubleshooting
```

---

**Module 11 complet!** Vous maîtrisez maintenant l'optimisation des performances dans Fabric.

[⬅️ Précédent](./06-monitoring-metrics.md) | [⬅️ Retour au README](./README.md)
