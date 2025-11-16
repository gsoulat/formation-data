# V-Order Optimization

## Introduction

**V-Order** est une optimisation de stockage propriétaire Microsoft qui réorganise les données Parquet pour des lectures ultra-rapides dans Fabric.

```
V-Order vs Standard Parquet:
Standard Parquet: Row groups → Columns → Compression
V-Order Parquet:  Row groups → Columns → Sorted → Optimized compression

Performance: Up to 50% faster reads in Power BI Direct Lake
```

## Qu'est-ce que V-Order ?

```
V-Order optimization:
  • Special sorting within row groups
  • Enhanced compression (dictionary, RLE)
  • Optimized for analytical queries
  • Fabric-specific optimization

Benefits:
  ✅ Faster Power BI Direct Lake queries
  ✅ Better compression ratios
  ✅ Reduced I/O operations
  ✅ Lower query latency
```

## Activation

### Automatique (par défaut dans Fabric)

```python
# V-Order enabled by default in Fabric Spark
df.write.format("delta").mode("overwrite").saveAsTable("sales")
# V-Order automatically applied
```

### Manuelle

```python
# Force V-Order on write
df.write.format("delta") \
    .option("parquet.vorder.enabled", "true") \
    .mode("overwrite") \
    .saveAsTable("sales")

# Optimize existing table with V-Order
spark.sql("OPTIMIZE sales VORDER")

# Check if V-Order applied
spark.sql("DESCRIBE DETAIL sales").select("properties").show(truncate=False)
```

## Impact sur les Performances

```
Benchmarks (typical):
  Standard Parquet read: 10 seconds
  V-Order Parquet read: 5-7 seconds
  Improvement: 30-50%

Best gains for:
  • High cardinality columns
  • String columns
  • Direct Lake semantic models
  • Analytical aggregations

Minimal gains for:
  • Already sorted data
  • Simple primary key lookups
  • Very small tables
```

## Coût vs Bénéfice

```
Write cost:
  • ~10-20% slower writes (sorting overhead)
  • Slightly more CPU during write

Storage:
  • Often smaller files (better compression)
  • Typical 10-30% size reduction

Read benefit:
  • 30-50% faster reads
  • Lower memory consumption
  • Better cache utilization

Recommendation:
  ✅ Enable for analytical tables (read-heavy)
  ⚠️ Consider for write-heavy tables (benchmark)
  ✅ Always for Direct Lake sources
```

## Best Practices

```
1. Enable V-Order for:
   • Fact tables (millions of rows)
   • Dimension tables used in joins
   • Direct Lake sources
   • Reporting tables

2. Combine with Z-Order for multi-column optimization:
   OPTIMIZE sales ZORDER BY (customer_id, product_id) VORDER

3. Re-optimize after large inserts:
   After loading millions of rows
   OPTIMIZE table VORDER

4. Monitor compression:
   Check file sizes before/after
   Expect 10-30% reduction
```

---

[⬅️ Retour au README du module](./README.md) | [Prochain ➡️](./02-partitioning-strategies.md)
