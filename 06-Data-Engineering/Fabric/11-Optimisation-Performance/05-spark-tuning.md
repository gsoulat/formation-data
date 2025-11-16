# Spark Tuning

## Configuration Spark

### Memory Settings

```python
# Executor memory
spark.conf.set("spark.executor.memory", "8g")
spark.conf.set("spark.executor.memoryOverhead", "2g")

# Driver memory
spark.conf.set("spark.driver.memory", "4g")

# Memory fraction for storage vs execution
spark.conf.set("spark.memory.storageFraction", "0.5")

# Recommendations:
# Executor: 8-16GB typical
# Overhead: 10-20% of executor memory
# Driver: 4-8GB (higher for large results)
```

### Parallelism

```python
# Number of partitions
spark.conf.set("spark.sql.shuffle.partitions", "200")
# Default 200, adjust based on data size and cluster

# Partition recommendations:
# Small data (<1GB): 20-50 partitions
# Medium data (1-100GB): 100-500 partitions
# Large data (>100GB): 500-2000 partitions

# Target: 100-200MB per partition

# Check partitions
df.rdd.getNumPartitions()

# Repartition if needed
df = df.repartition(100)  # Shuffle-based
df = df.coalesce(50)  # No shuffle (reduce only)
```

## Shuffle Optimization

```python
# Shuffle = data redistribution across cluster
# Expensive operation (network I/O)

# Minimize shuffles:
# 1. Broadcast small tables
from pyspark.sql.functions import broadcast
df.join(broadcast(small_df), "key")

# 2. Avoid repartition when possible
# Use coalesce to reduce partitions

# 3. Pre-partition data
# Write data partitioned by join keys

# 4. Use Adaptive Query Execution
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
```

## Handling Data Skew

```python
# Skew = uneven data distribution
# Problem: Some tasks take much longer

# Detect skew:
df.groupBy("key").count().orderBy(F.desc("count")).show()
# If one key has 90% of data = skew

# Solutions:

# 1. Salting (add random suffix to keys)
df = df.withColumn("salted_key",
    F.concat(F.col("key"), F.lit("_"), (F.rand() * 10).cast("int")))

# 2. Broadcast if one table is small
df.join(broadcast(small_df), "key")

# 3. Adaptive Query Execution handles skew
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes", "256MB")
```

## Adaptive Query Execution (AQE)

```python
# Enable AQE (Spark 3.0+)
spark.conf.set("spark.sql.adaptive.enabled", "true")

# AQE features:
# 1. Dynamic partition coalescing
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
# Automatically merges small partitions

# 2. Skew join handling
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
# Splits skewed partitions

# 3. Broadcast join conversion
spark.conf.set("spark.sql.adaptive.autoBroadcastJoinThreshold", "10MB")
# Switches to broadcast if runtime stats show small table

# Benefits:
# Automatic optimization based on runtime data
# Reduces manual tuning
# Handles data skew dynamically
```

## Common Tuning Patterns

```python
# 1. Spill to disk (OOM)
# Problem: Executor running out of memory
spark.conf.set("spark.memory.offHeap.enabled", "true")
spark.conf.set("spark.memory.offHeap.size", "2g")

# 2. Slow joins
# Use broadcast for small tables (<10MB)
# Pre-sort data for sort-merge join

# 3. Too many small files
# Coalesce before writing
df.coalesce(10).write.saveAsTable("table")

# 4. Long task times
# Check for skew
# Increase partitions (more parallelism)
# Filter data earlier in pipeline
```

## Monitoring Spark Jobs

```
Spark UI access:
  Notebook → Monitoring → Spark UI

Key metrics:
  • Task duration (look for outliers = skew)
  • Shuffle read/write (minimize)
  • GC time (< 10% is good)
  • Failed tasks (investigate)

Common bottlenecks:
  • Data skew → Uneven task times
  • Insufficient memory → Spill to disk
  • Too few partitions → Underutilized cluster
  • Too many partitions → Overhead
```

---

[⬅️ Précédent](./04-query-optimization.md) | [Prochain ➡️](./06-monitoring-metrics.md)
