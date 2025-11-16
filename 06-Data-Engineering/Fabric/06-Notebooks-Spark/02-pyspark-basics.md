# PySpark Basics

## Introduction

**PySpark** est l'API Python pour Apache Spark, permettant le traitement distribué de grandes quantités de données avec une syntaxe Python familière.

```
PySpark Architecture:
┌─────────────────────────────────────────┐
│  Python Code (PySpark API)              │
├─────────────────────────────────────────┤
│  Py4J (Python-JVM Bridge)               │
├─────────────────────────────────────────┤
│  Spark Core (Scala/JVM)                 │
│  ├─ Catalyst Optimizer                  │
│  ├─ Tungsten Execution Engine           │
│  └─ Cluster Manager                     │
├─────────────────────────────────────────┤
│  Distributed Storage (OneLake/Delta)    │
└─────────────────────────────────────────┘
```

## SparkSession

### Initialization

```python
# Dans Fabric Notebooks, SparkSession est pré-créée
print(spark)
# SparkSession - in-memory

# Version Spark
print(spark.version)
# 3.4.1

# Configuration
print(spark.sparkContext.appName)
print(spark.conf.get("spark.sql.shuffle.partitions"))
```

### Configuration Spark

```python
# Modifier configuration
spark.conf.set("spark.sql.shuffle.partitions", "100")
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Toutes les configurations
for conf in spark.sparkContext.getConf().getAll():
    print(conf)
```

## DataFrames

### Création de DataFrames

**From Python Collections:**
```python
# From list
data = [
    (1, "Alice", 25),
    (2, "Bob", 30),
    (3, "Charlie", 35)
]

df = spark.createDataFrame(data, ["id", "name", "age"])
df.show()
```

**From Dictionary:**
```python
# From list of dictionaries
data = [
    {"id": 1, "name": "Alice", "age": 25},
    {"id": 2, "name": "Bob", "age": 30},
    {"id": 3, "name": "Charlie", "age": 35}
]

df = spark.createDataFrame(data)
df.show()
```

**From Pandas:**
```python
import pandas as pd

pdf = pd.DataFrame({
    'id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35]
})

df = spark.createDataFrame(pdf)
df.show()
```

**With Schema Definition:**
```python
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

schema = StructType([
    StructField("id", IntegerType(), nullable=False),
    StructField("name", StringType(), nullable=True),
    StructField("age", IntegerType(), nullable=True)
])

df = spark.createDataFrame(data, schema)
df.printSchema()
```

### Reading Data

**From Delta Tables:**
```python
# Read table
df = spark.table("sales")

# Read with path
df = spark.read.format("delta").load("Tables/sales")

# Read specific version
df = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("Tables/sales")
```

**From Files:**
```python
# Parquet
df = spark.read.parquet("Files/raw/sales.parquet")

# CSV
df = spark.read.option("header", "true") \
    .option("inferSchema", "true") \
    .csv("Files/raw/sales.csv")

# JSON
df = spark.read.json("Files/raw/sales.json")

# Multiple files
df = spark.read.parquet("Files/raw/*.parquet")
```

**Advanced Read Options:**
```python
# CSV with custom delimiter
df = spark.read \
    .option("header", "true") \
    .option("delimiter", ";") \
    .option("quote", "\"") \
    .option("escape", "\\") \
    .option("encoding", "UTF-8") \
    .option("dateFormat", "dd/MM/yyyy") \
    .csv("Files/raw/sales.csv")

# Schema on read
from pyspark.sql.types import *

schema = StructType([
    StructField("order_id", IntegerType()),
    StructField("customer_id", IntegerType()),
    StructField("amount", DoubleType()),
    StructField("order_date", DateType())
])

df = spark.read.schema(schema).csv("Files/raw/sales.csv")
```

## DataFrame Operations

### Transformations (Lazy)

**Select:**
```python
# Select columns
df.select("name", "age").show()

# Select with alias
df.select(
    col("name").alias("customer_name"),
    col("age")
).show()

# Select with expression
df.select(
    col("name"),
    (col("age") + 10).alias("age_in_10_years")
).show()
```

**Filter / Where:**
```python
# Filter rows
df.filter(col("age") > 25).show()
df.where(col("age") > 25).show()  # Equivalent

# Multiple conditions
df.filter((col("age") > 25) & (col("name") != "Bob")).show()

# Using SQL expression
df.filter("age > 25 AND name != 'Bob'").show()
```

**WithColumn:**
```python
# Add new column
df.withColumn("age_plus_10", col("age") + 10).show()

# Modify existing column
df.withColumn("age", col("age") * 2).show()

# Multiple columns
df.withColumn("age_doubled", col("age") * 2) \
  .withColumn("is_adult", col("age") >= 18) \
  .show()
```

**Drop:**
```python
# Drop column
df.drop("age").show()

# Drop multiple columns
df.drop("age", "name").show()
```

**Rename:**
```python
# Rename column
df.withColumnRenamed("name", "customer_name").show()

# Rename multiple
df.withColumnRenamed("name", "customer_name") \
  .withColumnRenamed("age", "customer_age") \
  .show()
```

**Distinct / DropDuplicates:**
```python
# Distinct rows
df.distinct().show()

# Drop duplicates on specific columns
df.dropDuplicates(["name"]).show()
```

**OrderBy / Sort:**
```python
# Sort ascending
df.orderBy("age").show()
df.sort("age").show()  # Equivalent

# Sort descending
df.orderBy(col("age").desc()).show()

# Multiple columns
df.orderBy(col("age").desc(), col("name").asc()).show()
```

**Limit:**
```python
# Limit rows
df.limit(10).show()

# Top N
df.orderBy(col("age").desc()).limit(5).show()
```

### Actions (Trigger Execution)

**Show:**
```python
# Show first 20 rows
df.show()

# Show N rows
df.show(5)

# Show without truncation
df.show(truncate=False)

# Show with vertical format
df.show(5, vertical=True)
```

**Count:**
```python
# Count rows
row_count = df.count()
print(f"Total rows: {row_count}")
```

**Collect:**
```python
# Collect all rows to driver (CAUTION: can cause OOM)
rows = df.collect()
for row in rows:
    print(row.name, row.age)
```

**Take:**
```python
# Take first N rows
rows = df.take(5)
for row in rows:
    print(row)
```

**First / Head:**
```python
# Get first row
first_row = df.first()
print(first_row)

# Get first N rows
first_5 = df.head(5)
```

**ToPandas:**
```python
# Convert to Pandas (for small datasets)
pdf = df.toPandas()
print(type(pdf))  # pandas.DataFrame
```

## Built-in Functions

### Column Functions

```python
from pyspark.sql.functions import *

# String functions
df.select(
    upper(col("name")).alias("upper_name"),
    lower(col("name")).alias("lower_name"),
    length(col("name")).alias("name_length")
).show()

# Math functions
df.select(
    round(col("amount"), 2).alias("rounded"),
    abs(col("amount")).alias("absolute"),
    sqrt(col("amount")).alias("square_root")
).show()

# Date functions
df.select(
    current_date().alias("today"),
    current_timestamp().alias("now"),
    year(col("order_date")).alias("year"),
    month(col("order_date")).alias("month"),
    dayofmonth(col("order_date")).alias("day")
).show()
```

### Conditional Expressions

**When / Otherwise:**
```python
# Simple condition
df.withColumn(
    "age_category",
    when(col("age") < 30, "Young")
    .otherwise("Senior")
).show()

# Multiple conditions
df.withColumn(
    "age_category",
    when(col("age") < 20, "Teen")
    .when(col("age") < 30, "Young Adult")
    .when(col("age") < 60, "Adult")
    .otherwise("Senior")
).show()
```

**Case:**
```python
# Using expr with CASE
df.withColumn(
    "age_category",
    expr("""
        CASE
            WHEN age < 20 THEN 'Teen'
            WHEN age < 30 THEN 'Young Adult'
            WHEN age < 60 THEN 'Adult'
            ELSE 'Senior'
        END
    """)
).show()
```

### Null Handling

```python
# Check for null
df.filter(col("name").isNull()).show()
df.filter(col("name").isNotNull()).show()

# Fill nulls
df.fillna({"age": 0, "name": "Unknown"}).show()

# Drop rows with nulls
df.dropna().show()  # Drop if any column is null
df.dropna(subset=["age"]).show()  # Drop if age is null
df.dropna(thresh=2).show()  # Drop if less than 2 non-null values
```

## Aggregations

### GroupBy

```python
# Simple aggregation
df.groupBy("country") \
  .count() \
  .show()

# Multiple aggregations
df.groupBy("country") \
  .agg(
      count("*").alias("order_count"),
      sum("amount").alias("total_amount"),
      avg("amount").alias("avg_amount"),
      min("amount").alias("min_amount"),
      max("amount").alias("max_amount")
  ) \
  .show()
```

### Aggregate Functions

```python
from pyspark.sql.functions import *

# Using agg()
df.agg(
    count("*").alias("total_rows"),
    sum("amount").alias("total_sales"),
    avg("amount").alias("avg_sale"),
    stddev("amount").alias("stddev_sale")
).show()

# Distinct count
df.agg(
    countDistinct("customer_id").alias("unique_customers")
).show()

# Collect list/set
df.groupBy("country") \
  .agg(
      collect_list("city").alias("cities"),
      collect_set("city").alias("unique_cities")
  ) \
  .show()
```

### Window Functions

```python
from pyspark.sql.window import Window

# Define window
window_spec = Window.partitionBy("country").orderBy(col("amount").desc())

# Row number
df.withColumn(
    "row_num",
    row_number().over(window_spec)
).show()

# Rank
df.withColumn(
    "rank",
    rank().over(window_spec)
).withColumn(
    "dense_rank",
    dense_rank().over(window_spec)
).show()

# Running total
window_unbounded = Window.partitionBy("country") \
    .orderBy("order_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

df.withColumn(
    "running_total",
    sum("amount").over(window_unbounded)
).show()

# Moving average
window_moving = Window.partitionBy("country") \
    .orderBy("order_date") \
    .rowsBetween(-3, 0)  # Last 3 rows + current

df.withColumn(
    "moving_avg",
    avg("amount").over(window_moving)
).show()
```

## Joins

### Join Types

```python
# Sample DataFrames
customers = spark.createDataFrame([
    (1, "Alice"),
    (2, "Bob"),
    (3, "Charlie")
], ["customer_id", "name"])

orders = spark.createDataFrame([
    (101, 1, 100.0),
    (102, 2, 200.0),
    (103, 1, 150.0),
    (104, 4, 300.0)  # No matching customer
], ["order_id", "customer_id", "amount"])

# Inner join (default)
customers.join(orders, "customer_id", "inner").show()

# Left join
customers.join(orders, "customer_id", "left").show()

# Right join
customers.join(orders, "customer_id", "right").show()

# Outer join
customers.join(orders, "customer_id", "outer").show()

# Left anti join (rows in left NOT in right)
customers.join(orders, "customer_id", "left_anti").show()

# Left semi join (rows in left that ARE in right)
customers.join(orders, "customer_id", "left_semi").show()
```

### Join Conditions

```python
# Multiple columns
df1.join(df2, ["customer_id", "country"], "inner")

# Custom condition
df1.join(
    df2,
    (df1.customer_id == df2.customer_id) & (df1.date == df2.date),
    "inner"
)

# Aliasing to avoid ambiguity
df1.alias("a").join(
    df2.alias("b"),
    col("a.customer_id") == col("b.customer_id"),
    "inner"
).select("a.*", "b.order_id", "b.amount")
```

### Broadcast Join

```python
from pyspark.sql.functions import broadcast

# Broadcast small table (< 10 MB)
large_df.join(
    broadcast(small_df),
    "customer_id",
    "inner"
).show()
```

## UDFs (User-Defined Functions)

### Creating UDFs

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType, IntegerType

# Simple UDF
def categorize_age(age):
    if age < 20:
        return "Teen"
    elif age < 30:
        return "Young Adult"
    elif age < 60:
        return "Adult"
    else:
        return "Senior"

categorize_udf = udf(categorize_age, StringType())

# Use UDF
df.withColumn("age_category", categorize_udf(col("age"))).show()
```

### Pandas UDFs

```python
from pyspark.sql.functions import pandas_udf
import pandas as pd

# Pandas UDF (vectorized, faster)
@pandas_udf(StringType())
def categorize_age_pandas(ages: pd.Series) -> pd.Series:
    def categorize(age):
        if age < 20:
            return "Teen"
        elif age < 30:
            return "Young Adult"
        elif age < 60:
            return "Adult"
        else:
            return "Senior"
    return ages.apply(categorize)

# Use Pandas UDF
df.withColumn("age_category", categorize_age_pandas(col("age"))).show()
```

## Writing Data

### To Delta Tables

```python
# Write to table
df.write.format("delta") \
  .mode("overwrite") \
  .saveAsTable("silver_customers")

# Write modes
df.write.mode("overwrite").saveAsTable("table")  # Replace
df.write.mode("append").saveAsTable("table")      # Append
df.write.mode("ignore").saveAsTable("table")      # Skip if exists
df.write.mode("error").saveAsTable("table")       # Error if exists (default)
```

### To Files

```python
# Parquet
df.write.parquet("Files/output/customers.parquet")

# CSV
df.write.option("header", "true") \
  .csv("Files/output/customers.csv")

# JSON
df.write.json("Files/output/customers.json")

# With partitioning
df.write.partitionBy("country", "year") \
  .parquet("Files/output/customers.parquet")
```

## Performance Tips

### Lazy Evaluation

```python
# Transformations are lazy (not executed yet)
df2 = df.filter(col("age") > 25)
df3 = df2.select("name", "age")
df4 = df3.orderBy("age")

# Action triggers execution
df4.show()  # Now all transformations execute
```

### Caching

```python
# Cache DataFrame in memory
df.cache()
df.count()  # First action: loads into cache

# Subsequent actions use cache
df.filter(col("age") > 25).count()  # Fast!

# Unpersist when done
df.unpersist()
```

### Partition Management

```python
# Check partitions
print(df.rdd.getNumPartitions())

# Repartition (shuffle)
df_repartitioned = df.repartition(10)

# Coalesce (no shuffle, only decrease)
df_coalesced = df.coalesce(5)

# Repartition by column
df_repartitioned = df.repartition(10, "country")
```

## Common Patterns

### Deduplication

```python
# Keep first occurrence
df.dropDuplicates(["customer_id"]).show()

# Keep latest (by timestamp)
from pyspark.sql.window import Window

window = Window.partitionBy("customer_id").orderBy(col("updated_at").desc())

df.withColumn("row_num", row_number().over(window)) \
  .filter(col("row_num") == 1) \
  .drop("row_num") \
  .show()
```

### Pivoting

```python
# Pivot
df.groupBy("country") \
  .pivot("year") \
  .sum("amount") \
  .show()

# Unpivot (using stack)
df.selectExpr(
    "country",
    "stack(3, '2022', year_2022, '2023', year_2023, '2024', year_2024) as (year, amount)"
).show()
```

### ETL Pattern

```python
# Extract
raw_df = spark.read.parquet("Files/bronze/sales.parquet")

# Transform
from pyspark.sql.functions import *

cleaned_df = raw_df \
    .filter(col("amount") > 0) \
    .withColumn("amount_eur", col("amount") * 0.85) \
    .withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date"))) \
    .dropDuplicates(["order_id"])

# Load
cleaned_df.write.format("delta") \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .saveAsTable("silver_sales")
```

## Best Practices

### ✅ Schema Definition

```python
# Always define schema for CSV/JSON
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("amount", DoubleType(), True)
])

df = spark.read.schema(schema).csv("data.csv")
```

### ✅ Column Selection

```python
# Select only needed columns early
df.select("id", "name", "amount") \
  .filter(col("amount") > 100) \
  .groupBy("name") \
  .sum("amount")
```

### ✅ Broadcast Small Tables

```python
# For joins with small tables (<10 MB)
from pyspark.sql.functions import broadcast

large_df.join(broadcast(small_df), "id")
```

### ✅ Avoid collect()

```python
# ❌ Bad: Collects all data to driver
all_rows = df.collect()

# ✅ Good: Process in Spark
df.groupBy("country").count().show()
```

## Points Clés

- SparkSession = entry point pour toutes opérations Spark
- DataFrames = distributed collections (immuables, lazy)
- Transformations (lazy) = filter, select, groupBy, join
- Actions (eager) = show, count, collect, write
- Built-in functions (col, when, sum, avg, etc.)
- UDFs pour logique custom (prefer Pandas UDFs)
- Joins: inner, left, right, outer, anti, semi
- Window functions pour analytics complexes
- Cache pour réutilisation de DataFrames
- Lazy evaluation = optimizations before execution

---

**Prochain fichier :** [03 - DataFrames Operations](./03-dataframes-operations.md)

[⬅️ Fichier précédent](./01-notebooks-fabric.md) | [⬅️ Retour au README du module](./README.md)
