# Mécanismes de Cache

## Introduction

Le **caching** stocke temporairement les données en mémoire ou sur disque rapide pour accélérer les accès répétés.

```
Cache Hierarchy in Fabric:
┌─────────────────────────────┐
│ OneLake Cache (SSD)         │ ← Fastest
├─────────────────────────────┤
│ Spark DataFrame Cache       │
├─────────────────────────────┤
│ Power BI Result Cache       │
├─────────────────────────────┤
│ Delta Lake Checkpoint       │
└─────────────────────────────┘
```

## Spark DataFrame Cache

```python
# Cache DataFrame in memory
df = spark.table("large_table")
df.cache()  # Mark for caching
df.count()  # Trigger caching (action)

# Now subsequent operations are fast
df.filter(col("status") == "active").count()  # Uses cache

# Uncache when done
df.unpersist()
```

### Persistence Levels

```python
from pyspark import StorageLevel

# MEMORY_ONLY (default): Store in memory as deserialized Java objects
df.persist(StorageLevel.MEMORY_ONLY)

# MEMORY_AND_DISK: Spill to disk if memory insufficient
df.persist(StorageLevel.MEMORY_AND_DISK)

# DISK_ONLY: Store on disk only
df.persist(StorageLevel.DISK_ONLY)

# MEMORY_ONLY_SER: Serialized (more memory efficient)
df.persist(StorageLevel.MEMORY_ONLY_SER)

# Recommendation:
# MEMORY_AND_DISK for most cases (safe fallback)
```

## Power BI Result Cache

```
Result caching in Power BI:
  • Query results cached for reuse
  • Same query → instant response
  • Cache invalidated on data refresh

Configuration:
  Dataset settings → Query caching → On

Benefits:
  ✅ Faster dashboard loads
  ✅ Reduced backend load
  ✅ Better user experience

Considerations:
  ⚠️ Stale data between refreshes
  ⚠️ Memory consumption
  ⚠️ Cache invalidation on schema change
```

## OneLake Cache

```
OneLake local SSD cache:
  • Automatically caches frequently accessed data
  • Transparent to users
  • Managed by Fabric

Benefits:
  ✅ Reduces network I/O
  ✅ Lower latency
  ✅ Cost-effective (less egress)

Cannot directly control but:
  • Consistent access patterns help
  • Frequently used tables cached
  • Hot data stays in cache
```

## Cache Strategy

```
When to cache:
  ✅ Data reused multiple times in same job
  ✅ Expensive computations (joins, aggregations)
  ✅ Interactive analysis (Notebook exploration)

When NOT to cache:
  ❌ Data used only once
  ❌ Very large datasets (won't fit in memory)
  ❌ Streaming data (constantly changing)

Memory management:
  df.cache()  # Cache
  # ... use df multiple times ...
  df.unpersist()  # Release memory

Monitor cache usage:
  Spark UI → Storage tab
  Shows cached RDDs/DataFrames
```

## Cache Invalidation

```python
# Force refresh cached data
df.unpersist()
df = spark.table("table_that_changed")
df.cache()

# Clear all caches
spark.catalog.clearCache()

# In Power BI:
# Refresh dataset → Cache cleared
# Schema change → Cache invalidated

# Delta Lake:
# New checkpoint → Previous cache stale
# OPTIMIZE → May invalidate file-level caches
```

---

[⬅️ Précédent](./02-partitioning-strategies.md) | [Prochain ➡️](./04-query-optimization.md)
