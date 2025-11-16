# DataFrames Operations Avancées

## Introduction

Ce fichier couvre les opérations avancées sur les DataFrames Spark : manipulations complexes, optimisations, et patterns d'ETL professionnels.

```
DataFrame Operations:
┌──────────────────────────────────────────┐
│  Schema & Types                          │
│  Complex Data Types (arrays, structs)    │
│  Advanced Transformations                │
│  Data Quality & Validation               │
│  Performance Optimization                │
└──────────────────────────────────────────┘
```

## Schema Management

### Inspecting Schema

```python
# Print schema
df.printSchema()

# Get schema object
schema = df.schema
print(type(schema))  # StructType

# Get column names
column_names = df.columns
print(column_names)

# Get column types
dtypes = df.dtypes
for name, dtype in dtypes:
    print(f"{name}: {dtype}")

# Describe DataFrame
df.describe().show()

# Summary statistics
df.summary().show()
```

### Defining Complex Schemas

```python
from pyspark.sql.types import *

# Nested structure
schema = StructType([
    StructField("customer_id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("address", StructType([
        StructField("street", StringType(), True),
        StructField("city", StringType(), True),
        StructField("zipcode", StringType(), True)
    ]), True),
    StructField("orders", ArrayType(StructType([
        StructField("order_id", IntegerType(), False),
        StructField("amount", DoubleType(), True),
        StructField("date", DateType(), True)
    ])), True)
])

df = spark.createDataFrame(data, schema)
```

### Type Casting

```python
from pyspark.sql.functions import col

# Cast column type
df.withColumn("amount", col("amount").cast("double"))
df.withColumn("order_date", col("order_date").cast("date"))

# Using SQL type
df.withColumn("id", col("id").cast(IntegerType()))

# Safe casting with coalesce
df.withColumn(
    "amount",
    coalesce(col("amount").cast("double"), lit(0.0))
)
```

## Complex Data Types

### Arrays

**Creating Arrays:**
```python
from pyspark.sql.functions import array, lit

# Create array column
df.withColumn("colors", array(lit("red"), lit("green"), lit("blue"))).show()

# From existing columns
df.withColumn("coords", array(col("lat"), col("lon"))).show()
```

**Array Operations:**
```python
from pyspark.sql.functions import *

# Array size
df.withColumn("num_items", size(col("items"))).show()

# Array contains
df.filter(array_contains(col("tags"), "urgent")).show()

# Explode array (one row per element)
df.select(col("customer_id"), explode(col("items")).alias("item")).show()

# Explode with position
df.select(
    col("customer_id"),
    posexplode(col("items")).alias("pos", "item")
).show()

# Array aggregation
df.groupBy("country") \
  .agg(collect_list("city").alias("cities")) \
  .show()

# Array distinct
df.groupBy("country") \
  .agg(collect_set("city").alias("unique_cities")) \
  .show()

# Array functions
df.select(
    col("items"),
    array_distinct(col("items")).alias("unique_items"),
    array_sort(col("items")).alias("sorted_items"),
    array_max(col("numbers")).alias("max_value"),
    array_min(col("numbers")).alias("min_value")
).show()
```

### Structs

**Creating Structs:**
```python
from pyspark.sql.functions import struct

# Create struct column
df.withColumn(
    "full_address",
    struct(col("street"), col("city"), col("zipcode"))
).show()
```

**Accessing Struct Fields:**
```python
# Dot notation
df.select(col("address.street"), col("address.city")).show()

# getField()
df.select(col("address").getField("street")).show()

# Select all fields
df.select("address.*").show()
```

### Maps

```python
from pyspark.sql.functions import create_map, map_keys, map_values

# Create map
df.withColumn(
    "attributes",
    create_map(
        lit("color"), col("color"),
        lit("size"), col("size")
    )
).show()

# Map operations
df.select(
    map_keys(col("attributes")).alias("keys"),
    map_values(col("attributes")).alias("values")
).show()
```

## Advanced Transformations

### Conditional Column Creation

```python
from pyspark.sql.functions import when, col, lit

# Multiple conditions
df.withColumn(
    "customer_segment",
    when(col("total_spent") > 10000, "VIP")
    .when(col("total_spent") > 5000, "Premium")
    .when(col("total_spent") > 1000, "Regular")
    .otherwise("Basic")
).show()

# Nested conditions
df.withColumn(
    "discount",
    when(
        (col("country") == "FR") & (col("total_spent") > 1000),
        col("amount") * 0.1
    )
    .when(
        (col("country") == "US") & (col("total_spent") > 2000),
        col("amount") * 0.15
    )
    .otherwise(0)
).show()
```

### String Operations

```python
from pyspark.sql.functions import *

# String manipulation
df.select(
    upper(col("name")).alias("upper"),
    lower(col("name")).alias("lower"),
    initcap(col("name")).alias("title_case"),
    length(col("name")).alias("length"),
    trim(col("name")).alias("trimmed"),
    ltrim(col("name")).alias("left_trim"),
    rtrim(col("name")).alias("right_trim")
).show()

# Substring
df.select(
    substring(col("name"), 1, 3).alias("first_3_chars"),
    col("name").substr(1, 3).alias("first_3_chars_alt")
).show()

# Concatenation
df.select(
    concat(col("first_name"), lit(" "), col("last_name")).alias("full_name")
).show()

# Format string
df.select(
    format_string("%s (%d years)", col("name"), col("age")).alias("formatted")
).show()

# Replace
df.select(
    regexp_replace(col("email"), "@.*", "@example.com").alias("masked_email")
).show()

# Extract
df.select(
    regexp_extract(col("email"), "^([^@]+)", 1).alias("username")
).show()

# Split
df.select(
    split(col("tags"), ",").alias("tags_array")
).show()
```

### Date and Time Operations

```python
from pyspark.sql.functions import *

# Current date/time
df.select(
    current_date().alias("today"),
    current_timestamp().alias("now")
).show()

# Extract components
df.select(
    year(col("order_date")).alias("year"),
    month(col("order_date")).alias("month"),
    dayofmonth(col("order_date")).alias("day"),
    dayofweek(col("order_date")).alias("day_of_week"),
    weekofyear(col("order_date")).alias("week"),
    quarter(col("order_date")).alias("quarter")
).show()

# Date arithmetic
df.select(
    date_add(col("order_date"), 7).alias("next_week"),
    date_sub(col("order_date"), 30).alias("last_month"),
    datediff(current_date(), col("order_date")).alias("days_ago"),
    months_between(current_date(), col("order_date")).alias("months_ago")
).show()

# Date formatting
df.select(
    date_format(col("order_date"), "yyyy-MM-dd").alias("iso_date"),
    date_format(col("order_date"), "dd/MM/yyyy").alias("eu_date")
).show()

# Timestamp operations
df.select(
    to_timestamp(col("date_string"), "yyyy-MM-dd HH:mm:ss").alias("timestamp"),
    unix_timestamp(col("timestamp")).alias("epoch"),
    from_unixtime(col("epoch")).alias("datetime")
).show()
```

### Math Operations

```python
from pyspark.sql.functions import *

# Basic math
df.select(
    round(col("amount"), 2).alias("rounded"),
    ceil(col("amount")).alias("ceiling"),
    floor(col("amount")).alias("floor"),
    abs(col("amount")).alias("absolute")
).show()

# Advanced math
df.select(
    sqrt(col("amount")).alias("square_root"),
    pow(col("amount"), 2).alias("squared"),
    log(col("amount")).alias("natural_log"),
    log10(col("amount")).alias("log_base_10"),
    exp(col("amount")).alias("exponential")
).show()

# Rounding
df.select(
    col("amount"),
    round(col("amount") / 10) * 10  # Round to nearest 10
).show()
```

## Pivot and Unpivot

### Pivot (Wide Format)

```python
# Sample data: sales by country and year
sales_df = spark.createDataFrame([
    ("FR", 2022, 1000),
    ("FR", 2023, 1200),
    ("US", 2022, 2000),
    ("US", 2023, 2500)
], ["country", "year", "amount"])

# Pivot: rows to columns
pivoted = sales_df.groupBy("country") \
    .pivot("year") \
    .sum("amount")

pivoted.show()
# +-------+----+----+
# |country|2022|2023|
# +-------+----+----+
# |     FR|1000|1200|
# |     US|2000|2500|
# +-------+----+----+
```

### Unpivot (Long Format)

```python
# Unpivot using stack()
unpivoted = pivoted.selectExpr(
    "country",
    "stack(2, '2022', `2022`, '2023', `2023`) as (year, amount)"
)

unpivoted.show()
# +-------+----+------+
# |country|year|amount|
# +-------+----+------+
# |     FR|2022|  1000|
# |     FR|2023|  1200|
# |     US|2022|  2000|
# |     US|2023|  2500|
# +-------+----+------+
```

**Dynamic Unpivot:**
```python
from pyspark.sql.functions import expr

# Get value columns
value_cols = [c for c in pivoted.columns if c != "country"]
n_cols = len(value_cols)

# Build stack expression
stack_expr = f"stack({n_cols}, {', '.join([f\"'{c}', `{c}`\" for c in value_cols])}) as (year, amount)"

unpivoted = pivoted.selectExpr("country", stack_expr)
unpivoted.show()
```

## Window Functions Avancées

### Ranking

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import *

# Window spec
window = Window.partitionBy("country").orderBy(col("amount").desc())

# Different ranking methods
df.select(
    col("country"),
    col("customer"),
    col("amount"),
    row_number().over(window).alias("row_num"),
    rank().over(window).alias("rank"),
    dense_rank().over(window).alias("dense_rank"),
    percent_rank().over(window).alias("percent_rank"),
    ntile(4).over(window).alias("quartile")
).show()
```

### Lead and Lag

```python
window = Window.partitionBy("customer_id").orderBy("order_date")

# Previous and next values
df.select(
    col("customer_id"),
    col("order_date"),
    col("amount"),
    lag(col("amount"), 1).over(window).alias("previous_amount"),
    lead(col("amount"), 1).over(window).alias("next_amount"),
    col("amount") - lag(col("amount"), 1).over(window).alias("amount_change")
).show()
```

### Cumulative Aggregations

```python
window = Window.partitionBy("country") \
    .orderBy("order_date") \
    .rowsBetween(Window.unboundedPreceding, Window.currentRow)

# Running totals and averages
df.select(
    col("country"),
    col("order_date"),
    col("amount"),
    sum(col("amount")).over(window).alias("running_total"),
    avg(col("amount")).over(window).alias("running_avg"),
    count("*").over(window).alias("running_count")
).show()
```

### Moving Aggregations

```python
# Last 7 days window
window_7d = Window.partitionBy("country") \
    .orderBy("order_date") \
    .rangeBetween(-7 * 86400, 0)  # 7 days in seconds

df.select(
    col("country"),
    col("order_date"),
    col("amount"),
    sum(col("amount")).over(window_7d).alias("last_7_days_total"),
    avg(col("amount")).over(window_7d).alias("last_7_days_avg")
).show()

# Last N rows window
window_3_rows = Window.partitionBy("country") \
    .orderBy("order_date") \
    .rowsBetween(-2, 0)  # Current + 2 previous rows

df.select(
    col("country"),
    col("order_date"),
    col("amount"),
    avg(col("amount")).over(window_3_rows).alias("moving_avg_3")
).show()
```

## Data Quality & Validation

### Null Handling

```python
from pyspark.sql.functions import *

# Count nulls per column
df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in df.columns
]).show()

# Fill nulls with different strategies
df.fillna({
    "name": "Unknown",
    "age": 0,
    "country": "N/A"
}).show()

# Fill with column mean
from pyspark.sql.functions import mean

mean_age = df.select(mean(col("age"))).collect()[0][0]
df.fillna({"age": mean_age}).show()

# Coalesce (first non-null)
df.select(
    coalesce(col("email"), col("backup_email"), lit("no-email@example.com")).alias("email")
).show()
```

### Deduplication

```python
# Simple deduplication
df.dropDuplicates().show()

# By specific columns
df.dropDuplicates(["customer_id"]).show()

# Keep latest record
from pyspark.sql.window import Window

window = Window.partitionBy("customer_id").orderBy(col("updated_at").desc())

deduplicated = df.withColumn("row_num", row_number().over(window)) \
    .filter(col("row_num") == 1) \
    .drop("row_num")

deduplicated.show()
```

### Data Validation

```python
from pyspark.sql.functions import *

# Add validation flags
validated = df.withColumn(
    "is_valid",
    (col("amount") > 0) &
    (col("email").rlike("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) &
    (col("age").between(0, 120))
)

# Count invalid records
validated.filter(col("is_valid") == False).count()

# Separate valid and invalid
valid_df = validated.filter(col("is_valid") == True).drop("is_valid")
invalid_df = validated.filter(col("is_valid") == False)
```

### Outlier Detection

```python
from pyspark.sql.functions import *

# IQR method
stats = df.select(
    expr("percentile_approx(amount, 0.25)").alias("Q1"),
    expr("percentile_approx(amount, 0.75)").alias("Q3")
).collect()[0]

Q1, Q3 = stats["Q1"], stats["Q3"]
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# Flag outliers
df.withColumn(
    "is_outlier",
    (col("amount") < lower_bound) | (col("amount") > upper_bound)
).show()

# Z-score method
from pyspark.sql.functions import mean, stddev

stats = df.select(
    mean(col("amount")).alias("mean"),
    stddev(col("amount")).alias("stddev")
).collect()[0]

df.withColumn(
    "z_score",
    (col("amount") - stats["mean"]) / stats["stddev"]
).withColumn(
    "is_outlier",
    abs(col("z_score")) > 3
).show()
```

## ETL Patterns

### Slowly Changing Dimension (SCD Type 2)

```python
from pyspark.sql.functions import *

# Existing dimension
existing = spark.table("dim_customer")

# New data
new_data = spark.read.parquet("Files/raw/customers.parquet")

# Identify changes
changes = new_data.alias("new") \
    .join(
        existing.filter(col("is_current") == True).alias("old"),
        col("new.customer_id") == col("old.customer_id"),
        "left"
    ) \
    .select(
        col("new.*"),
        when(col("old.customer_id").isNull(), "INSERT")
        .when(
            (col("new.name") != col("old.name")) |
            (col("new.email") != col("old.email")),
            "UPDATE"
        )
        .otherwise("NO_CHANGE")
        .alias("change_type")
    )

# Close old records
to_close = changes.filter(col("change_type") == "UPDATE") \
    .select("customer_id")

existing.alias("e") \
    .join(to_close.alias("c"), col("e.customer_id") == col("c.customer_id")) \
    .select("e.*") \
    .withColumn("is_current", lit(False)) \
    .withColumn("end_date", current_date()) \
    .write.mode("append").saveAsTable("dim_customer")

# Insert new records
new_records = changes.filter(col("change_type").isin(["INSERT", "UPDATE"])) \
    .withColumn("start_date", current_date()) \
    .withColumn("end_date", lit(None).cast("date")) \
    .withColumn("is_current", lit(True))

new_records.write.mode("append").saveAsTable("dim_customer")
```

### Incremental Load

```python
# Get last load timestamp
last_load = spark.sql("SELECT MAX(updated_at) FROM silver_customers").collect()[0][0]

# Load only new/changed data
incremental = spark.read.parquet("Files/bronze/customers.parquet") \
    .filter(col("updated_at") > last_load)

# Merge with existing
from delta.tables import DeltaTable

target = DeltaTable.forName(spark, "silver_customers")

target.alias("target") \
    .merge(
        incremental.alias("source"),
        "target.customer_id = source.customer_id"
    ) \
    .whenMatchedUpdateAll() \
    .whenNotMatchedInsertAll() \
    .execute()
```

## Performance Optimization

### Predicate Pushdown

```python
# ✅ Good: Filter early
df = spark.read.parquet("Files/large_table.parquet") \
    .filter(col("country") == "FR") \
    .select("customer_id", "amount")

# ❌ Bad: Filter late
df = spark.read.parquet("Files/large_table.parquet") \
    .select("customer_id", "amount", "country") \
    .filter(col("country") == "FR")
```

### Column Pruning

```python
# ✅ Good: Select only needed columns
df = spark.read.parquet("Files/large_table.parquet") \
    .select("customer_id", "amount")

# ❌ Bad: Select all columns
df = spark.read.parquet("Files/large_table.parquet")
result = df.select("customer_id", "amount")
```

### Broadcast Joins

```python
from pyspark.sql.functions import broadcast

# For small tables (< 10 MB)
large_df.join(
    broadcast(small_df),
    "customer_id"
)
```

### Repartitioning

```python
# Too many small partitions
df.coalesce(10).write.parquet("output")

# Too few large partitions
df.repartition(100).write.parquet("output")

# Optimal partitioning by column
df.repartition(50, "country").write.parquet("output")
```

## Points Clés

- Schema management: define, inspect, cast types
- Complex types: arrays (explode, collect_list), structs, maps
- String operations: upper, lower, concat, regexp
- Date operations: extract components, arithmetic, formatting
- Pivot/unpivot for reshaping data
- Window functions: ranking, lead/lag, cumulative, moving
- Data quality: null handling, deduplication, validation
- ETL patterns: SCD Type 2, incremental loads, merges
- Performance: predicate pushdown, column pruning, broadcast joins

---

**Prochain fichier :** [04 - Delta Lake Operations](./04-delta-lake-operations.md)

[⬅️ Fichier précédent](./02-pyspark-basics.md) | [⬅️ Retour au README du module](./README.md)
