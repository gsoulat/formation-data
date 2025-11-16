# Performance Optimization

## Introduction

L'optimisation des performances Spark est cruciale pour traiter efficacement de grandes quantités de données et réduire les coûts de compute.

```
Performance Optimization Areas:
┌────────────────────────────────────────┐
│  1. Data Partitioning                  │
│  2. Caching & Persistence              │
│  3. Join Optimization                  │
│  4. Shuffle Reduction                  │
│  5. Resource Configuration             │
│  6. Code Optimization                  │
│  7. Storage Optimization               │
└────────────────────────────────────────┘
```

## Data Partitioning

### Understanding Partitions

```python
# Check current partitions
df = spark.table("sales")
print(f"Number of partitions: {df.rdd.getNumPartitions()}")

# Check partition sizes
from pyspark.sql.functions import spark_partition_id, count

df.groupBy(spark_partition_id()).count().show()
```

### Repartitioning

```python
# Increase partitions (full shuffle)
df_repartitioned = df.repartition(100)

# Repartition by column (for joins/aggregations)
df_repartitioned = df.repartition(100, "country")

# Multiple columns
df_repartitioned = df.repartition(100, "country", "year")
```

### Coalesce

```python
# Decrease partitions (no shuffle)
df_coalesced = df.coalesce(10)

# Use case: Before writing
df.coalesce(1).write.parquet("output/")  # Single file
```

### Optimal Partition Size

```python
# Target: 128MB - 1GB per partition

# Calculate optimal partitions
total_size_mb = 10000  # 10 GB
target_partition_size_mb = 512
optimal_partitions = total_size_mb / target_partition_size_mb

df_optimized = df.repartition(int(optimal_partitions))
```

### Partition Skew Detection

```python
from pyspark.sql.functions import spark_partition_id, count, col

# Check partition distribution
partition_stats = df.groupBy(spark_partition_id().alias("partition")) \
    .agg(count("*").alias("row_count")) \
    .orderBy(col("row_count").desc())

partition_stats.show()

# Identify skewed partitions
avg_rows = partition_stats.select(avg("row_count")).collect()[0][0]
skewed = partition_stats.filter(col("row_count") > avg_rows * 2)
skewed.show()
```

## Caching and Persistence

### Cache Strategies

```python
# Cache in memory (default)
df.cache()
df.count()  # Trigger caching

# Explicit persist with storage level
from pyspark import StorageLevel

# Memory only
df.persist(StorageLevel.MEMORY_ONLY)

# Memory and disk (spill to disk if needed)
df.persist(StorageLevel.MEMORY_AND_DISK)

# Serialized (compressed, less memory)
df.persist(StorageLevel.MEMORY_ONLY_SER)

# Disk only
df.persist(StorageLevel.DISK_ONLY)

# Replicated (2 copies)
df.persist(StorageLevel.MEMORY_AND_DISK_2)
```

### When to Cache

```python
# ✅ Good: Reused DataFrame
df_filtered = df.filter(col("country") == "FR").cache()

# Use multiple times
result1 = df_filtered.groupBy("city").count()
result2 = df_filtered.groupBy("age").avg("amount")
result3 = df_filtered.filter(col("age") > 30).count()

df_filtered.unpersist()

# ❌ Bad: Single use
df.filter(col("country") == "FR").cache().count()  # Wasted cache
```

### Unpersisting

```python
# Free cache memory
df.unpersist()

# Blocking unpersist (wait for completion)
df.unpersist(blocking=True)
```

### Monitoring Cache

```python
# Check cache status
print(df.is_cached)

# Spark UI → Storage tab shows cached RDDs/DataFrames
```

## Join Optimization

### Join Strategies

**Broadcast Hash Join (BHJ):**
```python
from pyspark.sql.functions import broadcast

# For small tables (< 10 MB default)
large_df.join(
    broadcast(small_df),
    "customer_id"
)

# Configure broadcast threshold
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "50MB")
```

**Sort Merge Join (SMJ):**
```python
# Default for large-large joins
# Automatically used when both tables are large

# Disable broadcast to force SMJ
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")

large_df1.join(large_df2, "id")
```

**Shuffle Hash Join:**
```python
# Rarely used, enable if needed
spark.conf.set("spark.sql.join.preferSortMergeJoin", "false")
```

### Join Key Optimization

```python
# ✅ Good: Same key distribution
df1.repartition("customer_id") \
   .join(df2.repartition("customer_id"), "customer_id")

# ❌ Bad: Mismatched partitioning
df1.join(df2, "customer_id")  # May cause shuffle
```

### Skewed Join Handling

```python
from pyspark.sql.functions import rand, lit

# Salting technique for skewed keys
# Add random salt to skewed key
salted_df1 = df1.withColumn("salt", (rand() * 10).cast("int")) \
    .withColumn("salted_key", concat(col("customer_id"), lit("_"), col("salt")))

# Explode other side
from pyspark.sql.functions import explode, array

salted_df2 = df2.withColumn("salt", explode(array(*[lit(i) for i in range(10)]))) \
    .withColumn("salted_key", concat(col("customer_id"), lit("_"), col("salt")))

# Join on salted key
result = salted_df1.join(salted_df2, "salted_key") \
    .drop("salt", "salted_key")
```

### Adaptive Query Execution (AQE)

```python
# Enable AQE (optimizes joins at runtime)
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")

# AQE will:
# - Dynamically coalesce shuffle partitions
# - Handle skewed joins automatically
# - Convert sort-merge to broadcast if small
```

## Shuffle Optimization

### Understanding Shuffle

```python
# Operations that cause shuffle:
# - groupBy, join, repartition, distinct, union
# - orderBy (global sort)

# Check shuffle in execution plan
df.groupBy("country").count().explain()
# Look for "Exchange" operations
```

### Reducing Shuffle

```python
# ✅ Good: Pre-partition before multiple operations
df_partitioned = df.repartition("country")

result1 = df_partitioned.groupBy("country").count()
result2 = df_partitioned.groupBy("country").sum("amount")
# Only 1 shuffle (repartition), not 2

# ❌ Bad: Shuffle for each operation
result1 = df.groupBy("country").count()  # Shuffle 1
result2 = df.groupBy("country").sum("amount")  # Shuffle 2
```

### Shuffle Partition Configuration

```python
# Default: 200 (too many for small data, too few for large)
spark.conf.set("spark.sql.shuffle.partitions", "100")

# Rule of thumb:
# - Small data (<10 GB): 50-100
# - Medium data (10-100 GB): 100-500
# - Large data (>100 GB): 500-2000

# Or use AQE to auto-adjust
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
```

### Local Aggregation

```python
# ✅ Good: Aggregation pushdown
df.groupBy("country").sum("amount")  # Pre-aggregates locally

# Internal: map-side combine before shuffle
```

## Resource Configuration

### Executor Configuration

```python
# Configure executors (if allowed in Fabric)
# Usually managed by Fabric, but good to understand

# Executor memory
spark.conf.set("spark.executor.memory", "8g")

# Executor cores
spark.conf.set("spark.executor.cores", "4")

# Number of executors (dynamic allocation)
spark.conf.set("spark.dynamicAllocation.enabled", "true")
spark.conf.set("spark.dynamicAllocation.minExecutors", "2")
spark.conf.set("spark.dynamicAllocation.maxExecutors", "10")
```

### Memory Management

```python
# Memory fraction for execution/storage
spark.conf.set("spark.memory.fraction", "0.6")  # 60% for execution/storage
spark.conf.set("spark.memory.storageFraction", "0.5")  # 50% of above for storage

# Off-heap memory (for better GC)
spark.conf.set("spark.memory.offHeap.enabled", "true")
spark.conf.set("spark.memory.offHeap.size", "2g")
```

### Parallelism

```python
# Default parallelism
spark.conf.set("spark.default.parallelism", "200")

# Task parallelism = partitions
# Ideal: 2-4 tasks per core
# If 10 executors × 4 cores = 40 cores
# Ideal partitions: 80-160
```

## Code Optimization

### Predicate Pushdown

```python
# ✅ Good: Filter early (pushed to source)
df = spark.read.parquet("large_table.parquet") \
    .filter(col("country") == "FR") \
    .select("id", "amount")

# Spark SQL on Parquet/Delta will only read filtered data

# ❌ Bad: Filter late
df = spark.read.parquet("large_table.parquet")
df = df.select("id", "amount", "country")
df = df.filter(col("country") == "FR")
```

### Column Pruning

```python
# ✅ Good: Select only needed columns early
df = spark.read.parquet("wide_table.parquet") \
    .select("id", "amount", "country")

# ❌ Bad: Read all columns
df = spark.read.parquet("wide_table.parquet")
# ... later use only 3 columns
```

### Avoiding UDFs

```python
from pyspark.sql.functions import udf, when, col

# ❌ Bad: Python UDF (slow, no optimization)
@udf("string")
def categorize_age(age):
    if age < 30:
        return "Young"
    else:
        return "Senior"

df.withColumn("category", categorize_age(col("age")))

# ✅ Good: Built-in functions
df.withColumn(
    "category",
    when(col("age") < 30, "Young").otherwise("Senior")
)

# ✅ Better: Pandas UDF (vectorized, faster)
from pyspark.sql.functions import pandas_udf
import pandas as pd

@pandas_udf("string")
def categorize_age_pandas(ages: pd.Series) -> pd.Series:
    return ages.apply(lambda x: "Young" if x < 30 else "Senior")

df.withColumn("category", categorize_age_pandas(col("age")))
```

### Lazy Evaluation

```python
# Transformations are lazy (chained, optimized)
df2 = df.filter(col("amount") > 100)
df3 = df2.select("id", "amount")
df4 = df3.groupBy("country").sum("amount")

# Action triggers optimized execution
df4.show()

# Spark optimizes entire chain before execution
```

### Avoid collect()

```python
# ❌ Bad: Collect large data to driver
all_rows = df.collect()  # OOM if data is large
for row in all_rows:
    process(row)

# ✅ Good: Process in Spark
df.foreach(lambda row: process(row))

# ✅ Better: Use transformations
result = df.map(lambda row: process(row))
```

## Storage Optimization

### File Format

```python
# Parquet: Columnar, compressed, fast
df.write.parquet("output/")

# ORC: Similar to Parquet, better compression
df.write.orc("output/")

# Avro: Row-based, good for write-heavy
df.write.format("avro").save("output/")

# ❌ Bad: CSV/JSON for large data
df.write.csv("output/")  # No compression, no schema
```

### Compression

```python
# Parquet with compression
df.write.option("compression", "snappy").parquet("output/")

# Compression codecs:
# - snappy: Fast, moderate compression (default)
# - gzip: Slow, high compression
# - lz4: Very fast, low compression
# - zstd: Balanced speed/compression

# Configure globally
spark.conf.set("spark.sql.parquet.compression.codec", "snappy")
```

### Partitioning Strategy

```python
# ✅ Good: Low cardinality partitions
df.write.partitionBy("country", "year") \
    .parquet("output/")
# ~200 countries × 10 years = 2,000 partitions ✅

# ❌ Bad: High cardinality partitions
df.write.partitionBy("customer_id") \
    .parquet("output/")
# Millions of partitions = slow metadata operations ❌
```

### Bucketing

```python
# Bucketing (for joins on same key)
df.write.bucketBy(100, "customer_id") \
    .sortBy("order_date") \
    .saveAsTable("orders_bucketed")

# Benefits:
# - No shuffle on joins with same bucketing
# - Pre-sorted for faster queries
```

## Delta Lake Optimizations

### Z-Ordering

```python
from delta.tables import DeltaTable

# Z-Order for co-location of related data
delta_table = DeltaTable.forName(spark, "sales")
delta_table.optimize().executeZOrderBy("customer_id", "product_id")

# Benefits:
# - Faster filters on Z-Ordered columns
# - Better data skipping
```

### OPTIMIZE

```python
# Compact small files
delta_table.optimize().executeCompaction()

# Target file size (default: 1 GB)
spark.conf.set("spark.databricks.delta.optimize.maxFileSize", "1073741824")
```

### Data Skipping

```python
# Delta automatically collects statistics
# Min/max values per file enable data skipping

# Enable data skipping stats
spark.conf.set("spark.databricks.delta.stats.skipping", "true")

# Query uses stats to skip files
df = spark.table("sales").filter(col("order_date") == "2024-01-15")
# Skips files where max(order_date) < '2024-01-15'
```

## Monitoring and Debugging

### Spark UI

```
Access Spark UI:
1. Fabric Notebook → Monitoring → Spark UI
2. View stages, tasks, storage, executors

Key metrics:
- Stage duration
- Shuffle read/write
- GC time
- Task skew
```

### Query Execution Plan

```python
# Explain plan
df.explain()

# Extended explain
df.explain(extended=True)

# Cost-based explain
df.explain(mode="cost")

# Formatted explain
df.explain(mode="formatted")
```

### Metrics Collection

```python
from pyspark.sql.functions import *

# Execution time
import time

start = time.time()
df.count()
end = time.time()
print(f"Execution time: {end - start:.2f}s")

# Query metrics
spark.sparkContext.statusTracker().getJobIdsForGroup()
```

## Performance Checklist

### ✅ Data Loading

```python
# 1. Use appropriate file format
df = spark.read.parquet("data.parquet")  # ✅ Not CSV

# 2. Define schema (avoid inferSchema)
schema = StructType([...])
df = spark.read.schema(schema).parquet("data.parquet")

# 3. Partition pruning
df = spark.read.parquet("data.parquet") \
    .filter(col("year") == 2024)  # Partition column
```

### ✅ Transformations

```python
# 1. Filter early
df = df.filter(...).select(...)  # ✅ Not select().filter()

# 2. Use built-in functions
df = df.withColumn("x", when(...))  # ✅ Not UDF

# 3. Pre-partition for multiple operations
df = df.repartition("key")
result1 = df.groupBy("key").count()
result2 = df.groupBy("key").sum("amount")
```

### ✅ Joins

```python
# 1. Broadcast small tables
large_df.join(broadcast(small_df), "key")

# 2. Pre-partition on join key
df1.repartition("key").join(df2.repartition("key"), "key")

# 3. Enable AQE
spark.conf.set("spark.sql.adaptive.enabled", "true")
```

### ✅ Aggregations

```python
# 1. Reduce data before aggregation
df.filter(...).groupBy(...).agg(...)

# 2. Use appropriate shuffle partitions
spark.conf.set("spark.sql.shuffle.partitions", "100")

# 3. Cache if reused
df.cache()
result1 = df.groupBy(...).count()
result2 = df.groupBy(...).sum(...)
df.unpersist()
```

### ✅ Writing

```python
# 1. Coalesce for fewer files
df.coalesce(10).write.parquet("output/")

# 2. Partition appropriately
df.write.partitionBy("year", "month").parquet("output/")

# 3. Use compression
df.write.option("compression", "snappy").parquet("output/")
```

## Common Performance Issues

### Issue: Too Many Small Files

```python
# Problem
df.write.parquet("output/")  # 1000 files of 1 MB each

# Solution
df.coalesce(10).write.parquet("output/")  # 10 files of 100 MB each
```

### Issue: Data Skew

```python
# Problem: Uneven partition sizes
df.groupBy("customer_id").count().show()
# customer_123: 1M rows
# customer_456: 10K rows

# Solution: Salting
from pyspark.sql.functions import rand

df.withColumn("salt", (rand() * 10).cast("int")) \
  .groupBy("customer_id", "salt") \
  .agg(...) \
  .groupBy("customer_id") \
  .agg(...)
```

### Issue: Excessive Shuffles

```python
# Problem
df.groupBy("a").count()  # Shuffle 1
df.groupBy("a").sum("x")  # Shuffle 2

# Solution: Pre-partition
df_partitioned = df.repartition("a")
df_partitioned.groupBy("a").count()  # No shuffle
df_partitioned.groupBy("a").sum("x")  # No shuffle
```

### Issue: OOM (Out of Memory)

```python
# Problem
all_data = df.collect()  # Brings all data to driver

# Solution: Process in Spark
df.foreach(lambda row: process(row))
# Or write to storage
df.write.parquet("output/")
```

## Points Clés

- Partitioning: 128MB-1GB per partition optimal
- Caching: Use for reused DataFrames, unpersist when done
- Joins: Broadcast small tables, pre-partition on join key
- Shuffle: Minimize with pre-partitioning, use AQE
- Code: Filter early, select columns, avoid Python UDFs
- Storage: Parquet with compression, partition strategically
- Delta: OPTIMIZE, Z-Order, data skipping
- Monitoring: Spark UI, explain plans, execution metrics
- AQE: Enable for automatic runtime optimizations
- Avoid: collect(), high cardinality partitioning, CSV

---

**Prochain fichier :** [07 - ML Integration](./07-ml-integration.md)

[⬅️ Fichier précédent](./05-spark-sql.md) | [⬅️ Retour au README du module](./README.md)
