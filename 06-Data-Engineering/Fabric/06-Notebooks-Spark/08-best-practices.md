# Best Practices

## Introduction

Ce fichier résume les meilleures pratiques pour développer des notebooks Spark professionnels, performants, et maintenables dans Microsoft Fabric.

```
Best Practices Categories:
┌────────────────────────────────────────┐
│  1. Code Organization                  │
│  2. Performance Optimization           │
│  3. Data Quality & Validation          │
│  4. Error Handling                     │
│  5. Documentation                      │
│  6. Testing & Debugging                │
│  7. Security                           │
│  8. Production Readiness               │
└────────────────────────────────────────┘
```

## Code Organization

### ✅ Cell Structure

```python
# Cell 1: Imports et Configuration
from pyspark.sql.functions import col, sum, avg, count
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from datetime import datetime

# Spark configuration
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.shuffle.partitions", "100")

# Cell 2: Parameters (marqué comme "parameters" dans metadata)
# This enables parameterization from pipelines
processing_date = "2024-01-15"
country_filter = "FR"
batch_size = 1000
dry_run = False

# Cell 3: Load Data
sales_df = spark.table("bronze_sales")
customers_df = spark.table("bronze_customers")

# Cell 4: Data Validation
assert sales_df.count() > 0, "Sales data is empty"
assert customers_df.count() > 0, "Customers data is empty"

# Cell 5: Transformations
cleaned_df = sales_df.filter(col("amount") > 0) \
    .dropDuplicates(["order_id"])

# Cell 6: Business Logic
aggregated_df = cleaned_df.groupBy("customer_id") \
    .agg(
        sum("amount").alias("total_sales"),
        count("*").alias("order_count")
    )

# Cell 7: Write Results
if not dry_run:
    aggregated_df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable("silver_customer_summary")

# Cell 8: Validation & Logging
row_count = aggregated_df.count()
print(f"✅ Processed {row_count} customers")
print(f"Processing date: {processing_date}")
```

### ✅ Modular Functions

```python
# Define reusable functions
def load_bronze_data(table_name, date_filter=None):
    """
    Load data from bronze layer with optional date filtering.

    Args:
        table_name (str): Name of the bronze table
        date_filter (str): Optional date to filter (YYYY-MM-DD)

    Returns:
        DataFrame: Loaded data
    """
    df = spark.table(f"bronze_{table_name}")

    if date_filter:
        df = df.filter(col("processing_date") == date_filter)

    print(f"✅ Loaded {df.count()} rows from bronze_{table_name}")
    return df


def validate_dataframe(df, name, min_rows=1):
    """
    Validate DataFrame meets basic quality checks.

    Args:
        df (DataFrame): DataFrame to validate
        name (str): Name for logging
        min_rows (int): Minimum expected row count

    Raises:
        ValueError: If validation fails
    """
    row_count = df.count()

    if row_count < min_rows:
        raise ValueError(f"{name} has {row_count} rows, expected at least {min_rows}")

    print(f"✅ {name} validation passed: {row_count} rows")


def write_delta_table(df, table_name, mode="overwrite", partition_cols=None):
    """
    Write DataFrame to Delta table with consistent settings.

    Args:
        df (DataFrame): DataFrame to write
        table_name (str): Target table name
        mode (str): Write mode (overwrite, append)
        partition_cols (list): Optional partition columns
    """
    writer = df.write.format("delta").mode(mode)

    if partition_cols:
        writer = writer.partitionBy(*partition_cols)

    writer.saveAsTable(table_name)

    row_count = df.count()
    print(f"✅ Wrote {row_count} rows to {table_name}")


# Usage
sales_df = load_bronze_data("sales", "2024-01-15")
validate_dataframe(sales_df, "Sales", min_rows=100)
write_delta_table(aggregated_df, "silver_summary", partition_cols=["year", "month"])
```

### ✅ Configuration Management

```python
# Cell: Configuration
class Config:
    """Centralized configuration"""

    # Environment
    ENVIRONMENT = "production"  # dev, staging, production

    # Spark settings
    SPARK_SHUFFLE_PARTITIONS = 200 if ENVIRONMENT == "production" else 50
    SPARK_ADAPTIVE_ENABLED = True

    # Data paths
    BRONZE_PATH = "bronze"
    SILVER_PATH = "silver"
    GOLD_PATH = "gold"

    # Business logic
    MIN_ORDER_AMOUNT = 0
    MAX_CUSTOMER_AGE = 120

    # Performance
    CACHE_INTERMEDIATE_RESULTS = True
    BROADCAST_THRESHOLD_MB = 50


# Apply configuration
spark.conf.set("spark.sql.shuffle.partitions", str(Config.SPARK_SHUFFLE_PARTITIONS))
spark.conf.set("spark.sql.adaptive.enabled", str(Config.SPARK_ADAPTIVE_ENABLED).lower())

# Use in code
df = df.filter(col("amount") > Config.MIN_ORDER_AMOUNT)
```

## Performance Optimization

### ✅ Data Loading

```python
# ✅ Good: Define schema, avoid inferSchema
from pyspark.sql.types import *

schema = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("customer_id", IntegerType(), False),
    StructField("amount", DoubleType(), True),
    StructField("order_date", DateType(), True)
])

df = spark.read.schema(schema).csv("Files/raw/orders.csv")

# ✅ Good: Partition pruning
df = spark.read.parquet("Tables/sales") \
    .filter(col("year") == 2024)  # Partition column

# ❌ Bad: Read all partitions then filter
df = spark.read.parquet("Tables/sales")
df = df.filter(col("year") == 2024)
```

### ✅ Transformations

```python
# ✅ Good: Filter early, select only needed columns
df = spark.table("large_table") \
    .select("customer_id", "order_id", "amount", "country") \
    .filter(col("country") == "FR") \
    .filter(col("amount") > 100)

# ❌ Bad: Select all, filter late
df = spark.table("large_table")
df = df.filter(col("country") == "FR")
df = df.filter(col("amount") > 100)
df = df.select("customer_id", "order_id", "amount", "country")
```

### ✅ Caching

```python
# ✅ Good: Cache when reused multiple times
customer_summary = df.groupBy("customer_id") \
    .agg(sum("amount").alias("total")) \
    .cache()

# Multiple uses
high_value = customer_summary.filter(col("total") > 10000)
medium_value = customer_summary.filter(col("total").between(1000, 10000))
low_value = customer_summary.filter(col("total") < 1000)

# Clean up
customer_summary.unpersist()

# ❌ Bad: Cache single-use DataFrame
df.cache().count()  # Only used once
```

### ✅ Joins

```python
from pyspark.sql.functions import broadcast

# ✅ Good: Broadcast small dimension tables
large_sales_df.join(
    broadcast(small_products_df),
    "product_id"
)

# ✅ Good: Pre-partition on join key for multiple joins
sales_partitioned = sales_df.repartition("customer_id")
orders_partitioned = orders_df.repartition("customer_id")

result = sales_partitioned.join(orders_partitioned, "customer_id")
```

### ✅ Aggregations

```python
# ✅ Good: Pre-filter before aggregation
df.filter(col("country") == "FR") \
  .groupBy("city") \
  .agg(sum("amount"))

# ✅ Good: Use appropriate partition count
spark.conf.set("spark.sql.shuffle.partitions", "100")
```

## Data Quality & Validation

### ✅ Input Validation

```python
def validate_input_data(df, name):
    """Comprehensive input validation"""

    # Check not empty
    row_count = df.count()
    if row_count == 0:
        raise ValueError(f"{name}: DataFrame is empty")

    # Check for all nulls in critical columns
    critical_cols = ["customer_id", "order_id", "amount"]
    for col_name in critical_cols:
        if col_name in df.columns:
            null_count = df.filter(col(col_name).isNull()).count()
            if null_count == row_count:
                raise ValueError(f"{name}: Column '{col_name}' is all nulls")

    # Check for duplicates on primary key
    if "order_id" in df.columns:
        duplicate_count = df.groupBy("order_id").count() \
            .filter(col("count") > 1).count()
        if duplicate_count > 0:
            print(f"⚠️ Warning: {duplicate_count} duplicate order_ids in {name}")

    print(f"✅ {name} validation passed: {row_count} rows")
    return df


# Usage
sales_df = validate_input_data(sales_df, "Sales")
```

### ✅ Data Quality Checks

```python
from pyspark.sql.functions import *

def data_quality_report(df):
    """Generate data quality report"""

    print("=" * 50)
    print("DATA QUALITY REPORT")
    print("=" * 50)

    # Row count
    total_rows = df.count()
    print(f"Total rows: {total_rows:,}")

    # Null counts per column
    print("\nNull counts:")
    null_counts = df.select([
        count(when(col(c).isNull(), c)).alias(c)
        for c in df.columns
    ]).collect()[0].asDict()

    for col_name, null_count in null_counts.items():
        if null_count > 0:
            pct = (null_count / total_rows) * 100
            print(f"  {col_name}: {null_count:,} ({pct:.2f}%)")

    # Duplicate check (if has ID column)
    if "id" in df.columns or "order_id" in df.columns:
        id_col = "id" if "id" in df.columns else "order_id"
        duplicate_count = df.groupBy(id_col).count() \
            .filter(col("count") > 1).count()
        print(f"\nDuplicate {id_col}s: {duplicate_count:,}")

    print("=" * 50)


# Usage
data_quality_report(sales_df)
```

### ✅ Outlier Detection

```python
def detect_outliers(df, col_name):
    """Detect outliers using IQR method"""

    # Calculate quartiles
    quantiles = df.approxQuantile(col_name, [0.25, 0.75], 0.01)
    Q1, Q3 = quantiles[0], quantiles[1]
    IQR = Q3 - Q1

    # Define bounds
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    # Count outliers
    outliers = df.filter(
        (col(col_name) < lower_bound) | (col(col_name) > upper_bound)
    )

    outlier_count = outliers.count()
    total_count = df.count()
    pct = (outlier_count / total_count) * 100

    print(f"Outliers in {col_name}:")
    print(f"  Range: [{lower_bound:.2f}, {upper_bound:.2f}]")
    print(f"  Count: {outlier_count:,} ({pct:.2f}%)")

    return outliers


# Usage
amount_outliers = detect_outliers(sales_df, "amount")
```

## Error Handling

### ✅ Try-Except Blocks

```python
def safe_transformation(df):
    """Transformation with comprehensive error handling"""

    try:
        # Attempt transformation
        result = df.filter(col("amount") > 0) \
            .withColumn("year", year(col("order_date"))) \
            .groupBy("year").sum("amount")

        print("✅ Transformation successful")
        return result

    except Exception as e:
        print(f"❌ Transformation failed: {str(e)}")

        # Log error details
        import traceback
        print(traceback.format_exc())

        # Exit notebook with error
        mssparkutils.notebook.exit({
            "status": "failed",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })


# Usage
result_df = safe_transformation(sales_df)
```

### ✅ Graceful Degradation

```python
def load_data_with_fallback(primary_table, fallback_table):
    """Load data with fallback strategy"""

    try:
        # Try primary source
        df = spark.table(primary_table)
        print(f"✅ Loaded from {primary_table}")
        return df

    except Exception as e:
        print(f"⚠️ Failed to load {primary_table}: {e}")

        try:
            # Fallback to alternative source
            df = spark.table(fallback_table)
            print(f"✅ Loaded from fallback {fallback_table}")
            return df

        except Exception as e2:
            print(f"❌ Fallback also failed: {e2}")
            raise ValueError(f"Could not load data from {primary_table} or {fallback_table}")


# Usage
df = load_data_with_fallback("silver_sales", "bronze_sales")
```

## Documentation

### ✅ Markdown Cells

```markdown
# Sales Data Processing

## Purpose
Process daily sales data and create customer summary for reporting.

## Input Tables
- `bronze_sales`: Raw sales transactions
- `bronze_customers`: Customer master data

## Output Tables
- `silver_customer_summary`: Aggregated customer metrics

## Business Logic
1. Filter out invalid transactions (amount <= 0)
2. Deduplicate by order_id
3. Aggregate sales by customer
4. Calculate lifetime value and segment

## Parameters
- `processing_date`: Date to process (YYYY-MM-DD)
- `country_filter`: Optional country code filter
- `dry_run`: If True, skip writing results

## Dependencies
- Module 02 (Lakehouse bronze ingestion) must run first
- Requires Lakehouse access permissions

## Schedule
- Runs daily at 2:00 AM UTC
- Expected duration: 5-10 minutes
```

### ✅ Code Comments

```python
# Load bronze sales data
# Filter: Only completed orders from last 30 days
sales_df = spark.table("bronze_sales") \
    .filter(col("status") == "completed") \
    .filter(col("order_date") >= date_sub(current_date(), 30))

# Data quality: Remove invalid records
# Business rule: Amount must be positive and < $100,000
valid_sales = sales_df.filter(
    (col("amount") > 0) &
    (col("amount") < 100000)
)

# Deduplication strategy: Keep latest record by updated_at
from pyspark.sql.window import Window

window = Window.partitionBy("order_id").orderBy(col("updated_at").desc())

deduplicated = valid_sales.withColumn("row_num", row_number().over(window)) \
    .filter(col("row_num") == 1) \
    .drop("row_num")

# Aggregation: Calculate customer lifetime value
# Includes: total sales, order count, average order value, last order date
customer_summary = deduplicated.groupBy("customer_id") \
    .agg(
        sum("amount").alias("lifetime_value"),
        count("*").alias("order_count"),
        avg("amount").alias("avg_order_value"),
        max("order_date").alias("last_order_date")
    )
```

### ✅ Function Docstrings

```python
def calculate_customer_segment(df):
    """
    Calculate customer segment based on lifetime value.

    Segmentation rules:
    - VIP: lifetime_value > $10,000
    - Premium: $5,000 < lifetime_value <= $10,000
    - Regular: $1,000 < lifetime_value <= $5,000
    - Basic: lifetime_value <= $1,000

    Args:
        df (DataFrame): DataFrame with customer_id and lifetime_value columns

    Returns:
        DataFrame: Input DataFrame with additional 'segment' column

    Example:
        >>> customers_df = calculate_customer_segment(customer_summary)
        >>> customers_df.groupBy("segment").count().show()
    """
    from pyspark.sql.functions import when, col

    return df.withColumn(
        "segment",
        when(col("lifetime_value") > 10000, "VIP")
        .when(col("lifetime_value") > 5000, "Premium")
        .when(col("lifetime_value") > 1000, "Regular")
        .otherwise("Basic")
    )
```

## Testing & Debugging

### ✅ Unit Testing Patterns

```python
def test_transformation():
    """Test transformation logic with sample data"""

    # Create test data
    test_data = spark.createDataFrame([
        (1, "A", 100),
        (2, "B", 200),
        (3, "A", -50),  # Invalid (negative amount)
        (4, "C", 0),     # Invalid (zero amount)
    ], ["id", "category", "amount"])

    # Apply transformation
    result = test_data.filter(col("amount") > 0) \
        .groupBy("category") \
        .sum("amount")

    # Assertions
    assert result.count() == 2, "Expected 2 categories"

    result_dict = {row["category"]: row["sum(amount)"] for row in result.collect()}
    assert result_dict["A"] == 100, "Category A should have 100"
    assert result_dict["B"] == 200, "Category B should have 200"

    print("✅ All tests passed")


# Run tests
test_transformation()
```

### ✅ Debugging Utilities

```python
def inspect_dataframe(df, name, sample_rows=5):
    """Comprehensive DataFrame inspection"""

    print(f"\n{'='*60}")
    print(f"DATAFRAME INSPECTION: {name}")
    print(f"{'='*60}")

    # Schema
    print("\nSchema:")
    df.printSchema()

    # Row count
    print(f"\nRow count: {df.count():,}")

    # Sample data
    print(f"\nSample ({sample_rows} rows):")
    df.show(sample_rows, truncate=False)

    # Statistics
    print("\nStatistics:")
    df.describe().show()

    # Partition count
    print(f"\nPartition count: {df.rdd.getNumPartitions()}")

    print(f"{'='*60}\n")


# Usage
inspect_dataframe(sales_df, "Sales Data")
```

### ✅ Execution Plan Analysis

```python
def analyze_query_plan(df, name):
    """Analyze and print query execution plan"""

    print(f"\nQUERY PLAN: {name}")
    print("="*60)

    # Logical plan
    print("\nLogical Plan:")
    df.explain(extended=False)

    # Check for potential issues
    plan_string = df._jdf.queryExecution().toString()

    if "Exchange" in plan_string:
        print("\n⚠️ Contains shuffle operations")

    if "BroadcastHashJoin" in plan_string:
        print("\n✅ Uses broadcast join")

    if "SortMergeJoin" in plan_string:
        print("\n⚠️ Uses sort-merge join (consider broadcast if possible)")

    print("="*60)


# Usage
analyze_query_plan(result_df, "Customer Summary Query")
```

## Security

### ✅ Credential Management

```python
# ✅ Good: Use mssparkutils for secrets
db_password = mssparkutils.credentials.getSecret(
    "https://myvault.vault.azure.net/",
    "database-password"
)

df = spark.read.format("jdbc") \
    .option("url", "jdbc:sqlserver://server.database.windows.net") \
    .option("dbtable", "sales") \
    .option("user", "admin") \
    .option("password", db_password) \
    .load()

# ❌ Bad: Hardcoded credentials
db_password = "MyPassword123!"  # NEVER DO THIS
```

### ✅ Data Masking

```python
from pyspark.sql.functions import regexp_replace, sha2

# Mask sensitive data
masked_df = df.withColumn(
    "email_masked",
    regexp_replace(col("email"), "^(.{3}).*(@.*)", "$1***$2")
) \
.withColumn(
    "ssn_hashed",
    sha2(col("ssn"), 256)
)

# Remove PII before saving to lower environments
production_df = df.select("customer_id", "amount", "order_date")
test_df = production_df.limit(1000)  # Sample for testing
```

## Production Readiness

### ✅ Logging

```python
import logging
from datetime import datetime

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def log_execution_start(notebook_name):
    """Log execution start"""
    logger.info(f"{'='*60}")
    logger.info(f"Notebook: {notebook_name}")
    logger.info(f"Start time: {datetime.now()}")
    logger.info(f"{'='*60}")

def log_execution_end(notebook_name, status, metrics=None):
    """Log execution end"""
    logger.info(f"{'='*60}")
    logger.info(f"Notebook: {notebook_name}")
    logger.info(f"End time: {datetime.now()}")
    logger.info(f"Status: {status}")
    if metrics:
        logger.info(f"Metrics: {metrics}")
    logger.info(f"{'='*60}")

# Usage
log_execution_start("Customer Summary ETL")

try:
    # Process data
    result_df = process_sales_data()

    log_execution_end("Customer Summary ETL", "SUCCESS", {
        "rows_processed": result_df.count()
    })

except Exception as e:
    log_execution_end("Customer Summary ETL", "FAILED", {
        "error": str(e)
    })
    raise
```

### ✅ Exit with Results

```python
# Return results to pipeline
result = {
    "status": "success",
    "rows_processed": row_count,
    "processing_date": processing_date,
    "execution_time_seconds": execution_time,
    "tables_written": ["silver_customer_summary", "gold_customer_metrics"]
}

mssparkutils.notebook.exit(result)
```

## Summary Checklist

### Before Deploying to Production

- [ ] **Code Organization**
  - [ ] Cells logically organized
  - [ ] Parameters cell defined
  - [ ] Reusable functions extracted
  - [ ] Configuration centralized

- [ ] **Performance**
  - [ ] Schema defined (not inferred)
  - [ ] Filters applied early
  - [ ] Small tables broadcasted
  - [ ] Appropriate partitioning
  - [ ] Caching for reused DataFrames
  - [ ] Execution plans reviewed

- [ ] **Data Quality**
  - [ ] Input validation implemented
  - [ ] Null handling defined
  - [ ] Duplicate checks in place
  - [ ] Outlier detection (if applicable)

- [ ] **Error Handling**
  - [ ] Try-except blocks for critical sections
  - [ ] Graceful degradation for failures
  - [ ] Meaningful error messages

- [ ] **Documentation**
  - [ ] Markdown cells explain purpose
  - [ ] Complex logic commented
  - [ ] Function docstrings complete
  - [ ] Dependencies documented

- [ ] **Testing**
  - [ ] Unit tests for transformations
  - [ ] Sample data tested
  - [ ] Edge cases validated

- [ ] **Security**
  - [ ] No hardcoded credentials
  - [ ] Secrets from Key Vault
  - [ ] PII properly masked

- [ ] **Production**
  - [ ] Logging implemented
  - [ ] Metrics tracked
  - [ ] Exit results defined
  - [ ] Monitoring configured

## Points Clés

- Organization: Structured cells, modular functions, centralized config
- Performance: Filter early, broadcast small tables, cache wisely
- Quality: Validate inputs, detect outliers, handle nulls
- Errors: Try-except, graceful degradation, meaningful messages
- Documentation: Markdown cells, comments, docstrings
- Testing: Unit tests, sample data, edge cases
- Security: No hardcoded secrets, mask PII
- Production: Logging, metrics, monitoring, exit results
- Review execution plans and Spark UI
- Follow medallion architecture (bronze → silver → gold)

---

**Module Complete!** Vous avez maintenant toutes les compétences pour créer des notebooks Spark professionnels dans Microsoft Fabric.

[⬅️ Fichier précédent](./07-ml-integration.md) | [⬅️ Retour au README du module](./README.md)
