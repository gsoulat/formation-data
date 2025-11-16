# Stratégies de Partitionnement

## Introduction

Le **partitionnement** divise les données en segments pour accélérer les requêtes en évitant de lire des données non pertinentes (partition pruning).

```
Partitioning Example:
sales/
├── year=2022/
│   ├── month=01/
│   ├── month=02/
│   └── ...
├── year=2023/
└── year=2024/

Query: WHERE year = 2024
→ Only reads year=2024 folder (prunes 2022, 2023)
```

## Partitionnement par Date

```python
# Most common pattern
df.write.format("delta") \
    .partitionBy("year", "month") \
    .mode("overwrite") \
    .saveAsTable("sales")

# Or extract from timestamp
from pyspark.sql import functions as F

df.withColumn("year", F.year("order_date")) \
  .withColumn("month", F.month("order_date")) \
  .write.format("delta") \
  .partitionBy("year", "month") \
  .saveAsTable("sales")
```

### Partition Pruning

```sql
-- Query with partition filter
SELECT * FROM sales WHERE year = 2024 AND month = 6;
-- Only reads year=2024/month=06/ (pruning works)

-- Query without partition filter
SELECT * FROM sales WHERE customer_id = 123;
-- Reads ALL partitions (no pruning, slow!)

-- Best practice: Always filter on partition columns first
```

## Granularité

```
Over-partitioning (too many small partitions):
  ❌ year/month/day/hour for 1M rows
  Result: Thousands of tiny files (< 1MB each)
  Problem: File system overhead, slow listing

Under-partitioning (too few, large partitions):
  ❌ year only for 10B rows
  Result: Few huge partitions (100GB each)
  Problem: Still reads too much data

Right balance:
  ✅ Target: 100MB - 1GB per partition
  ✅ For 10GB table: ~10-100 partitions
  ✅ For 1TB table: ~1000-10000 partitions
```

## Z-Ordering

```sql
-- Sort data within partitions for co-location
OPTIMIZE sales ZORDER BY (customer_id, product_id)

-- Benefits:
-- Queries on customer_id skip irrelevant files
-- Even without partitioning

-- When to use:
-- High-cardinality columns used in filters
-- Multiple columns in WHERE clause
-- Columns not suitable for partitioning
```

## When NOT to Partition

```
Don't partition:
  ❌ Small tables (< 1GB)
  ❌ Frequently changing partition columns
  ❌ Low-cardinality columns (< 10 values)
  ❌ Columns rarely used in WHERE

Better alternatives:
  • Small tables: No partitioning
  • High-cardinality: Z-Order instead
  • Many filters: Combination of Z-Order + selective partitioning
```

## Best Practices

```python
# 1. Partition by time (most queries filter by date)
.partitionBy("year", "month")

# 2. Keep partition count manageable (100-10000)
# Not: partitionBy("user_id") with millions of users

# 3. Use Z-Order for secondary columns
OPTIMIZE table ZORDER BY (customer_id)

# 4. Monitor partition sizes
spark.sql("DESCRIBE DETAIL sales").show()

# 5. Compact small files periodically
OPTIMIZE sales
```

---

[⬅️ Précédent](./01-v-order-optimization.md) | [Prochain ➡️](./03-caching-mechanisms.md)
