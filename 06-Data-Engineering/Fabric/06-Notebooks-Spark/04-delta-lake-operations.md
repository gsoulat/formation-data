# Delta Lake Operations avec Spark

## Introduction

**Delta Lake** fournit des transactions ACID, time travel, et schema enforcement sur les data lakes. Cette intégration avec Spark permet des opérations avancées.

```
Delta Lake Architecture:
┌──────────────────────────────────────────┐
│  PySpark DataFrame API                   │
├──────────────────────────────────────────┤
│  Delta Lake API                          │
│  ├─ ACID Transactions                    │
│  ├─ Schema Evolution                     │
│  ├─ Time Travel                          │
│  └─ MERGE Operations                     │
├──────────────────────────────────────────┤
│  Parquet Files + Transaction Log         │
│  (_delta_log/*.json)                     │
└──────────────────────────────────────────┘
```

## Creating Delta Tables

### From DataFrame

```python
# Create Delta table from DataFrame
df = spark.createDataFrame([
    (1, "Alice", 25),
    (2, "Bob", 30)
], ["id", "name", "age"])

# Save as Delta table
df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("customers")

# Save to path
df.write.format("delta") \
    .mode("overwrite") \
    .save("Tables/customers")
```

### With Partitioning

```python
# Partition by column
df.write.format("delta") \
    .mode("overwrite") \
    .partitionBy("country", "year") \
    .saveAsTable("sales")

# Multiple partitions
df.write.format("delta") \
    .partitionBy("year", "month", "day") \
    .save("Tables/sales_partitioned")
```

### With Options

```python
# Delta options
df.write.format("delta") \
    .option("overwriteSchema", "true") \
    .option("mergeSchema", "true") \
    .option("dataChange", "true") \
    .mode("overwrite") \
    .saveAsTable("customers")
```

## Reading Delta Tables

### Basic Read

```python
# Read Delta table
df = spark.read.format("delta").load("Tables/customers")
df.show()

# Read table by name
df = spark.table("customers")
df.show()

# Read with schema
df = spark.read.format("delta") \
    .schema("id INT, name STRING, age INT") \
    .load("Tables/customers")
```

### Time Travel

```python
# Read specific version
df = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("Tables/customers")

# Read by timestamp
df = spark.read.format("delta") \
    .option("timestampAsOf", "2024-01-15 10:00:00") \
    .load("Tables/customers")

# Using SQL
df = spark.sql("""
    SELECT * FROM customers
    VERSION AS OF 5
""")

df = spark.sql("""
    SELECT * FROM customers
    TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

## CRUD Operations

### Insert

```python
# Append new data
new_df = spark.createDataFrame([
    (3, "Charlie", 35)
], ["id", "name", "age"])

new_df.write.format("delta") \
    .mode("append") \
    .saveAsTable("customers")
```

### Update

```python
from delta.tables import DeltaTable

# Get Delta table
delta_table = DeltaTable.forName(spark, "customers")

# Update all rows
delta_table.update(
    set={"age": "age + 1"}
)

# Conditional update
delta_table.update(
    condition="id = 2",
    set={"name": "'Robert'", "age": "31"}
)

# Update with expression
from pyspark.sql.functions import expr

delta_table.update(
    condition=expr("country = 'FR'"),
    set={"status": expr("'active'")}
)
```

### Delete

```python
# Delete rows
delta_table.delete(condition="age < 18")

# Delete all
delta_table.delete()

# Complex condition
delta_table.delete(
    condition="country = 'US' AND last_order_date < '2023-01-01'"
)
```

## MERGE (Upsert)

### Basic Merge

```python
from delta.tables import DeltaTable
from pyspark.sql.functions import col

# Target table
target = DeltaTable.forName(spark, "customers")

# Source data
updates = spark.createDataFrame([
    (2, "Bob", 31),      # Update existing
    (4, "David", 28)     # Insert new
], ["id", "name", "age"])

# Merge
target.alias("target") \
    .merge(
        updates.alias("source"),
        "target.id = source.id"
    ) \
    .whenMatchedUpdateAll() \
    .whenNotMatchedInsertAll() \
    .execute()
```

### Conditional Merge

```python
target.alias("t") \
    .merge(
        source.alias("s"),
        "t.customer_id = s.customer_id"
    ) \
    .whenMatchedUpdate(
        condition="s.updated_at > t.updated_at",
        set={
            "name": "s.name",
            "email": "s.email",
            "updated_at": "s.updated_at"
        }
    ) \
    .whenNotMatchedInsert(
        values={
            "customer_id": "s.customer_id",
            "name": "s.name",
            "email": "s.email",
            "created_at": "s.updated_at",
            "updated_at": "s.updated_at"
        }
    ) \
    .execute()
```

### SCD Type 2 with Merge

```python
from pyspark.sql.functions import current_timestamp, lit

# Merge for SCD Type 2
target.alias("t") \
    .merge(
        source.alias("s"),
        "t.customer_id = s.customer_id AND t.is_current = true"
    ) \
    .whenMatchedUpdate(
        condition="""
            s.name != t.name OR
            s.email != t.email
        """,
        set={
            "is_current": "false",
            "end_date": "current_timestamp()"
        }
    ) \
    .execute()

# Insert new versions
new_versions = source.alias("s") \
    .join(
        target.filter("is_current = true").alias("t"),
        "s.customer_id = t.customer_id",
        "left"
    ) \
    .filter(
        col("t.customer_id").isNull() |
        (col("s.name") != col("t.name")) |
        (col("s.email") != col("t.email"))
    ) \
    .select(
        col("s.*"),
        current_timestamp().alias("start_date"),
        lit(None).cast("timestamp").alias("end_date"),
        lit(True).alias("is_current")
    )

new_versions.write.format("delta") \
    .mode("append") \
    .saveAsTable("customers")
```

## Schema Evolution

### Schema Enforcement

```python
# Schema mismatch causes error
new_df = spark.createDataFrame([
    (5, "Eve")  # Missing 'age' column
], ["id", "name"])

# This will fail
new_df.write.format("delta") \
    .mode("append") \
    .saveAsTable("customers")
# Error: Column 'age' is missing
```

### Merge Schema

```python
# Allow schema evolution
new_df = spark.createDataFrame([
    (5, "Eve", 40, "eve@example.com")
], ["id", "name", "age", "email"])

# Add new column
new_df.write.format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .saveAsTable("customers")

# Now 'email' column exists
spark.table("customers").printSchema()
```

### Overwrite Schema

```python
# Replace schema completely
new_schema_df = spark.createDataFrame([
    (1, "Product A", 99.99),
    (2, "Product B", 149.99)
], ["id", "product_name", "price"])

new_schema_df.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("customers")
```

## Optimization

### OPTIMIZE

```python
from delta.tables import DeltaTable

# Optimize table (compact small files)
delta_table = DeltaTable.forName(spark, "customers")
delta_table.optimize().executeCompaction()

# Optimize with Z-Ordering
delta_table.optimize() \
    .executeZOrderBy("country", "city")

# SQL syntax
spark.sql("OPTIMIZE customers")
spark.sql("OPTIMIZE customers ZORDER BY (country, city)")
```

### VACUUM

```python
# Remove old files (default: 7 days retention)
delta_table.vacuum()

# Custom retention (hours)
delta_table.vacuum(168)  # 7 days

# SQL syntax
spark.sql("VACUUM customers")
spark.sql("VACUUM customers RETAIN 168 HOURS")

# Disable retention check (DANGEROUS)
spark.conf.set("spark.databricks.delta.retentionDurationCheck.enabled", "false")
delta_table.vacuum(0)
```

### ANALYZE

```python
# Collect table statistics
spark.sql("ANALYZE TABLE customers COMPUTE STATISTICS")

# Collect column statistics
spark.sql("ANALYZE TABLE customers COMPUTE STATISTICS FOR COLUMNS id, country")

# View statistics
spark.sql("DESCRIBE EXTENDED customers").show(truncate=False)
```

## Transaction Log

### Viewing History

```python
# Get table history
delta_table = DeltaTable.forName(spark, "customers")
history = delta_table.history()
history.show()

# SQL syntax
spark.sql("DESCRIBE HISTORY customers").show()

# Filter history
history.filter("operation = 'MERGE'").show()
history.orderBy("timestamp").show()
```

### History Details

```python
# Last 10 operations
history.limit(10).select(
    "version",
    "timestamp",
    "operation",
    "operationParameters",
    "readVersion",
    "isBlindAppend"
).show(truncate=False)
```

## Change Data Feed

### Enable CDC

```python
# Enable Change Data Feed
spark.sql("""
    ALTER TABLE customers
    SET TBLPROPERTIES (delta.enableChangeDataFeed = true)
""")

# Enable at creation
df.write.format("delta") \
    .option("delta.enableChangeDataFeed", "true") \
    .saveAsTable("customers")
```

### Read Changes

```python
# Read changes between versions
changes = spark.read.format("delta") \
    .option("readChangeFeed", "true") \
    .option("startingVersion", 5) \
    .option("endingVersion", 10) \
    .table("customers")

changes.show()

# Columns:
# - All original columns
# - _change_type (insert, update_preimage, update_postimage, delete)
# - _commit_version
# - _commit_timestamp
```

### CDC Processing

```python
# Process CDC data
changes.filter(col("_change_type") == "insert") \
    .drop("_change_type", "_commit_version", "_commit_timestamp") \
    .show()

# Get latest state per key
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number

window = Window.partitionBy("id").orderBy(col("_commit_version").desc())

latest = changes.filter(col("_change_type") != "update_preimage") \
    .withColumn("rn", row_number().over(window)) \
    .filter(col("rn") == 1) \
    .drop("rn", "_change_type", "_commit_version", "_commit_timestamp")

latest.show()
```

## Clone

### Shallow Clone

```python
# Shallow clone (metadata only)
spark.sql("""
    CREATE TABLE customers_clone
    SHALLOW CLONE customers
""")

# With version
spark.sql("""
    CREATE TABLE customers_clone
    SHALLOW CLONE customers
    VERSION AS OF 5
""")
```

### Deep Clone

```python
# Deep clone (copy data)
spark.sql("""
    CREATE TABLE customers_backup
    DEEP CLONE customers
""")

# With timestamp
spark.sql("""
    CREATE TABLE customers_backup
    DEEP CLONE customers
    TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

## Restore

### Restore Table

```python
from delta.tables import DeltaTable

# Restore to version
delta_table = DeltaTable.forName(spark, "customers")
delta_table.restoreToVersion(5)

# Restore to timestamp
delta_table.restoreToTimestamp("2024-01-15 10:00:00")

# SQL syntax
spark.sql("RESTORE TABLE customers TO VERSION AS OF 5")
spark.sql("RESTORE TABLE customers TO TIMESTAMP AS OF '2024-01-15'")
```

## Constraints

### Add Constraints

```python
# NOT NULL constraint
spark.sql("""
    ALTER TABLE customers
    CHANGE COLUMN email SET NOT NULL
""")

# CHECK constraint
spark.sql("""
    ALTER TABLE customers
    ADD CONSTRAINT age_check CHECK (age >= 0 AND age <= 120)
""")

# Multiple constraints
spark.sql("""
    ALTER TABLE customers
    ADD CONSTRAINT valid_email CHECK (email LIKE '%@%.%')
""")
```

### Drop Constraints

```python
# Drop constraint
spark.sql("""
    ALTER TABLE customers
    DROP CONSTRAINT age_check
""")
```

## Advanced Patterns

### Incremental Processing

```python
# Get last processed version
last_version = spark.sql("""
    SELECT MAX(processed_version)
    FROM processing_metadata
    WHERE table_name = 'customers'
""").collect()[0][0] or 0

# Read changes since last version
changes = spark.read.format("delta") \
    .option("readChangeFeed", "true") \
    .option("startingVersion", last_version + 1) \
    .table("customers")

# Process changes
processed = changes.filter(col("_change_type").isin(["insert", "update_postimage"])) \
    .drop("_change_type", "_commit_version", "_commit_timestamp")

# Write results
processed.write.format("delta") \
    .mode("append") \
    .saveAsTable("processed_customers")

# Update metadata
current_version = changes.agg(max("_commit_version")).collect()[0][0]
spark.sql(f"""
    UPDATE processing_metadata
    SET processed_version = {current_version}
    WHERE table_name = 'customers'
""")
```

### Partition Evolution

```python
# Add partition column
spark.sql("""
    ALTER TABLE sales
    ADD COLUMNS (region STRING)
""")

# Repartition existing data
df = spark.table("sales")

df.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .partitionBy("region", "year", "month") \
    .saveAsTable("sales")
```

### Multi-Hop Architecture

```python
# Bronze → Silver → Gold

# Bronze: Raw data
bronze_df.write.format("delta") \
    .mode("append") \
    .saveAsTable("bronze_sales")

# Silver: Cleaned data
silver_df = spark.table("bronze_sales") \
    .filter(col("amount") > 0) \
    .dropDuplicates(["order_id"]) \
    .withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date")))

silver_df.write.format("delta") \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .saveAsTable("silver_sales")

# Gold: Business aggregates
gold_df = spark.table("silver_sales") \
    .groupBy("country", "year", "month") \
    .agg(
        sum("amount").alias("total_sales"),
        count("*").alias("order_count"),
        avg("amount").alias("avg_order_value")
    )

gold_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("gold_sales_monthly")
```

## Monitoring & Debugging

### Table Details

```python
# Table details
spark.sql("DESCRIBE DETAIL customers").show(truncate=False)

# Shows:
# - format (delta)
# - id (unique table ID)
# - name
# - location
# - createdAt
# - lastModified
# - partitionColumns
# - numFiles
# - sizeInBytes
```

### File Statistics

```python
# Count files
details = spark.sql("DESCRIBE DETAIL customers").collect()[0]
print(f"Number of files: {details['numFiles']}")
print(f"Size: {details['sizeInBytes'] / 1024 / 1024:.2f} MB")

# File sizes
from pyspark.sql.functions import input_file_name, count

spark.table("customers") \
    .withColumn("file", input_file_name()) \
    .groupBy("file") \
    .agg(count("*").alias("rows")) \
    .show(truncate=False)
```

### Transaction Details

```python
# Last operation
last_op = delta_table.history(1).select(
    "version",
    "timestamp",
    "operation",
    "operationMetrics"
).collect()[0]

print(f"Version: {last_op['version']}")
print(f"Operation: {last_op['operation']}")
print(f"Metrics: {last_op['operationMetrics']}")
```

## Best Practices

### ✅ Partitioning Strategy

```python
# Good: Low cardinality partitions
df.write.format("delta") \
    .partitionBy("country", "year") \  # ~200 countries × 10 years = 2,000 partitions
    .saveAsTable("sales")

# Bad: High cardinality partitions
df.write.format("delta") \
    .partitionBy("customer_id") \  # Millions of partitions!
    .saveAsTable("sales")
```

### ✅ Regular Optimization

```python
# Schedule regular OPTIMIZE
# - After large writes
# - Weekly for active tables
# - Monthly for archive tables

from delta.tables import DeltaTable

delta_table = DeltaTable.forName(spark, "sales")

# Optimize and Z-Order
delta_table.optimize() \
    .executeZOrderBy("customer_id", "order_date")

# Vacuum old files
delta_table.vacuum(168)  # 7 days
```

### ✅ Use MERGE for Upserts

```python
# ✅ Good: Single MERGE operation
target.merge(source, "target.id = source.id") \
    .whenMatchedUpdateAll() \
    .whenNotMatchedInsertAll() \
    .execute()

# ❌ Bad: Separate DELETE + INSERT
target.delete("id IN (SELECT id FROM source)")
source.write.mode("append").saveAsTable("target")
```

### ✅ Enable Change Data Feed

```python
# For tables that need CDC
spark.sql("""
    ALTER TABLE customers
    SET TBLPROPERTIES (delta.enableChangeDataFeed = true)
""")

# Benefits:
# - Track changes over time
# - Incremental processing
# - Audit trail
```

## Points Clés

- Delta Lake = ACID transactions + time travel + schema evolution
- CRUD: insert (append), update, delete, merge (upsert)
- Time travel: read data as of version or timestamp
- Schema evolution: mergeSchema, overwriteSchema
- OPTIMIZE: compact small files, Z-Order for co-location
- VACUUM: remove old files (retention period)
- Change Data Feed: track all changes (insert/update/delete)
- Clone: shallow (metadata) or deep (data copy)
- Constraints: NOT NULL, CHECK for data quality
- Best practices: partition wisely, optimize regularly, use MERGE

---

**Prochain fichier :** [05 - Spark SQL](./05-spark-sql.md)

[⬅️ Fichier précédent](./03-dataframes-operations.md) | [⬅️ Retour au README du module](./README.md)
