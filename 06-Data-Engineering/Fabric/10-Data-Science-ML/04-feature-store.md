# Feature Store

## Introduction

**Feature Store** est un référentiel centralisé pour stocker, gérer et servir des features (variables) ML, assurant réutilisabilité et cohérence.

```
Feature Store Architecture:
┌─────────────────────────────────────────────┐
│  Feature Engineering (Spark/Python)         │
│  ├─ Calculate features                      │
│  └─ Write to Feature Store                  │
├─────────────────────────────────────────────┤
│  Feature Store (Delta Lake Tables)          │
│  ├─ customer_demographics                   │
│  ├─ customer_rfm                            │
│  ├─ product_embeddings                      │
│  └─ transaction_aggregates                  │
├─────────────────────────────────────────────┤
│  Consumers                                  │
│  ├─ Training pipelines                      │
│  ├─ Batch scoring                           │
│  └─ Real-time serving                       │
└─────────────────────────────────────────────┘
```

## Concept de Feature Store

### Why Feature Store?

```
Problems without Feature Store:
  ❌ Duplicate feature computation
     Team A calculates customer age
     Team B calculates same thing differently
     Inconsistent results

  ❌ Training-serving skew
     Features computed one way in training
     Differently in production
     Model fails silently

  ❌ No feature discovery
     Features buried in notebooks
     Teams can't find existing work
     Reinventing the wheel

  ❌ No versioning
     Feature logic changes
     Can't reproduce old models
     No tracking of evolution

Feature Store solves all of these
```

### Key Benefits

```
✅ Reusability
   Create once, use many times
   Across models and teams
   No duplicate effort

✅ Consistency
   Same feature definition everywhere
   Training = serving
   Reliable results

✅ Discovery
   Central catalog of features
   Searchable and documented
   Team collaboration

✅ Versioning
   Track feature changes
   Reproduce any model
   Audit trail

✅ Scalability
   Compute once, serve many
   Efficient storage
   Fast retrieval
```

## Création de Features dans Fabric

### Basic Feature Engineering

```python
from pyspark.sql import functions as F

# Load raw data
customers = spark.table("raw.customers")
orders = spark.table("raw.orders")

# Create customer demographic features
customer_demographics = customers.select(
    "customer_id",
    F.datediff(F.current_date(), F.col("birth_date")).alias("age_days"),
    (F.datediff(F.current_date(), F.col("birth_date")) / 365).cast("int").alias("age_years"),
    F.months_between(F.current_date(), F.col("signup_date")).alias("tenure_months"),
    "country",
    "city",
    F.when(F.col("email").isNotNull(), 1).otherwise(0).alias("has_email"),
    F.when(F.col("phone").isNotNull(), 1).otherwise(0).alias("has_phone")
)

# Save to Feature Store
customer_demographics.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_demographics")

print(f"Created {customer_demographics.count()} customer demographic features")
```

### RFM Features (Recency, Frequency, Monetary)

```python
# Classic e-commerce features

# Calculate RFM from orders
rfm_features = orders.groupBy("customer_id").agg(
    # Recency: Days since last order
    F.datediff(
        F.current_date(),
        F.max("order_date")
    ).alias("recency_days"),

    # Frequency: Number of orders
    F.count("*").alias("frequency"),

    # Monetary: Total spent
    F.sum("amount").alias("monetary_total"),

    # Additional
    F.avg("amount").alias("avg_order_value"),
    F.max("amount").alias("max_order_value"),
    F.min("amount").alias("min_order_value"),
    F.stddev("amount").alias("std_order_value")
)

# Save to Feature Store
rfm_features.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_rfm")
```

### Time-Based Features

```python
# Features that change over time

# Rolling window features
from pyspark.sql.window import Window

window_30d = Window.partitionBy("customer_id") \
    .orderBy(F.col("date").cast("long")) \
    .rangeBetween(-30 * 86400, 0)  # 30 days in seconds

rolling_features = orders.withColumn(
    "orders_last_30d",
    F.count("*").over(window_30d)
).withColumn(
    "spent_last_30d",
    F.sum("amount").over(window_30d)
).withColumn(
    "avg_spent_last_30d",
    F.avg("amount").over(window_30d)
)

# Time-bucketed features
daily_features = orders.groupBy(
    "customer_id",
    F.date_trunc("day", "order_date").alias("feature_date")
).agg(
    F.count("*").alias("orders_today"),
    F.sum("amount").alias("spent_today")
)

# Save with date partitioning
daily_features.write.format("delta") \
    .partitionBy("feature_date") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_daily_activity")
```

## Feature Engineering at Scale

### Spark Optimizations

```python
# Efficient feature computation with Spark

# Broadcast small tables
from pyspark.sql.functions import broadcast

# Product categories (small table)
categories = spark.table("dim_product_categories")

# Orders (large table)
orders = spark.table("orders")

# Efficient join
orders_enriched = orders.join(
    broadcast(categories),  # Broadcast small table
    "product_id"
)

# Cache frequently used DataFrames
customer_base = spark.table("customers").cache()

# Repartition for balanced processing
orders_repartitioned = orders.repartition(100, "customer_id")

# Use built-in functions (not UDFs)
# Fast: F.when(), F.col(), F.sum()
# Slow: @udf decorated functions
```

### Parallel Feature Computation

```python
# Calculate multiple feature groups in parallel

from concurrent.futures import ThreadPoolExecutor

def compute_rfm_features():
    return orders.groupBy("customer_id").agg(...)

def compute_demographic_features():
    return customers.select(...)

def compute_behavior_features():
    return clickstream.groupBy("customer_id").agg(...)

# Run in parallel
with ThreadPoolExecutor(max_workers=3) as executor:
    rfm_future = executor.submit(compute_rfm_features)
    demo_future = executor.submit(compute_demographic_features)
    behavior_future = executor.submit(compute_behavior_features)

    rfm_df = rfm_future.result()
    demo_df = demo_future.result()
    behavior_df = behavior_future.result()

# Join all features
complete_features = rfm_df.join(demo_df, "customer_id") \
                          .join(behavior_df, "customer_id")

# Save to Feature Store
complete_features.write.saveAsTable("feature_store.customer_complete")
```

## Versioning de Features

### Delta Lake Time Travel

```python
# Feature Store uses Delta Lake for versioning

# Save features with timestamp
from datetime import datetime

feature_version = datetime.now().strftime("%Y%m%d_%H%M%S")

customer_features.write.format("delta") \
    .option("userMetadata", f"version={feature_version}") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_features")

# View history
spark.sql("DESCRIBE HISTORY feature_store.customer_features").show()

# Output:
# version | timestamp | operation | userMetadata
# 5       | 2024-01-20 | WRITE    | version=20240120_100000
# 4       | 2024-01-19 | WRITE    | version=20240119_093000
# ...

# Load specific version (for reproducibility)
old_features = spark.read.format("delta") \
    .option("versionAsOf", 4) \
    .table("feature_store.customer_features")

# Train model with exact same features as before
```

### Feature Schema Evolution

```python
# Add new columns to existing feature table

# Current schema: customer_id, age, tenure
# Add: lifetime_value

# Method 1: ALTER TABLE (add column)
spark.sql("""
    ALTER TABLE feature_store.customer_features
    ADD COLUMN lifetime_value DOUBLE
""")

# Update with values
spark.sql("""
    UPDATE feature_store.customer_features
    SET lifetime_value = monetary_total * 1.2
""")

# Method 2: Overwrite with new schema
new_features = old_features.withColumn(
    "lifetime_value",
    F.col("monetary_total") * 1.2
)

new_features.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("feature_store.customer_features")

# Schema evolution tracked in Delta history
```

## Online vs Offline Serving

### Offline Features (Batch)

```
Offline Feature Store:
  Storage: Delta Lake tables
  Access: Spark SQL queries
  Latency: Seconds to minutes
  Use case: Model training, batch scoring

Workflow:
  1. Feature engineering (daily/hourly)
  2. Write to Delta table
  3. Training job reads features
  4. Batch scoring reads features

Example:
  # Batch scoring pipeline
  features = spark.table("feature_store.customer_features")
  predictions = model.transform(features)
  predictions.write.saveAsTable("predictions")
```

### Online Features (Real-Time)

```
Online Feature Store:
  Storage: Key-value store (Redis, Cosmos DB)
  Access: REST API / SDK
  Latency: Milliseconds
  Use case: Real-time inference

Workflow:
  1. Sync from offline store
  2. Cache in low-latency store
  3. Real-time API fetches features
  4. Model makes instant prediction

Example (conceptual):
  # Real-time API request
  customer_id = "C12345"
  features = online_store.get_features(customer_id)
  prediction = model.predict(features)
  return {"churn_probability": prediction}

Fabric limitation:
  No built-in online store
  Use Azure Cosmos DB or Redis
  Custom integration needed
```

### Hybrid Approach

```python
# Common pattern: Offline training, online serving

# 1. Training (offline)
training_features = spark.table("feature_store.customer_features")
model = train_model(training_features)

# 2. Sync to online store (nightly)
# Export features to Cosmos DB
features_df = spark.table("feature_store.customer_features")

features_df.write.format("cosmos.oltp") \
    .option("spark.cosmos.accountEndpoint", endpoint) \
    .option("spark.cosmos.accountKey", key) \
    .option("spark.cosmos.database", "features") \
    .option("spark.cosmos.container", "customer_features") \
    .mode("overwrite") \
    .save()

# 3. Real-time serving (via Azure Function)
# def predict(customer_id):
#     features = cosmos_client.read(customer_id)
#     return model.predict(features)
```

## Integration avec Training Pipelines

### Feature Retrieval

```python
# Training pipeline uses Feature Store

import mlflow

with mlflow.start_run(run_name="churn_model_v2"):

    # Load features from Feature Store
    customer_features = spark.table("feature_store.customer_features")
    rfm_features = spark.table("feature_store.customer_rfm")
    behavior_features = spark.table("feature_store.customer_behavior")

    # Join all feature sets
    training_data = customer_features \
        .join(rfm_features, "customer_id") \
        .join(behavior_features, "customer_id") \
        .join(spark.table("labels.churn"), "customer_id")

    # Log feature versions
    mlflow.log_param("customer_features_version",
                     get_latest_version("feature_store.customer_features"))
    mlflow.log_param("rfm_features_version",
                     get_latest_version("feature_store.customer_rfm"))

    # Train model
    model = train_model(training_data)

    # Log model
    mlflow.sklearn.log_model(model, "model")

print("Model trained with versioned features")
```

### Feature Pipeline Scheduling

```python
# Automated feature refresh

# Pipeline in Fabric Data Pipeline
# or Notebook job scheduler

def daily_feature_refresh():
    """Run daily to update features"""

    # 1. Refresh demographic features (changes slowly)
    customer_demographics = compute_demographic_features()
    customer_demographics.write.saveAsTable("feature_store.customer_demographics")

    # 2. Refresh RFM features (changes daily)
    rfm_features = compute_rfm_features()
    rfm_features.write.saveAsTable("feature_store.customer_rfm")

    # 3. Refresh behavior features (changes frequently)
    behavior_features = compute_behavior_features()
    behavior_features.write.saveAsTable("feature_store.customer_behavior")

    # 4. Log refresh completion
    log_feature_refresh("daily_refresh", datetime.now())

    print(f"Features refreshed at {datetime.now()}")

# Schedule: Run at 2 AM daily
# Monitor: Alert if refresh fails
# Validate: Check feature distributions
```

### Feature Documentation

```python
# Document features for discoverability

feature_catalog = {
    "customer_demographics": {
        "description": "Basic customer attributes",
        "features": [
            {"name": "age_years", "type": "int", "description": "Customer age in years"},
            {"name": "tenure_months", "type": "float", "description": "Months since signup"},
            {"name": "country", "type": "string", "description": "Customer country"}
        ],
        "refresh": "daily",
        "owner": "data_engineering_team"
    },
    "customer_rfm": {
        "description": "Recency, Frequency, Monetary features",
        "features": [
            {"name": "recency_days", "type": "int", "description": "Days since last purchase"},
            {"name": "frequency", "type": "int", "description": "Total order count"},
            {"name": "monetary_total", "type": "float", "description": "Total lifetime spend"}
        ],
        "refresh": "daily",
        "owner": "analytics_team"
    }
}

# Save catalog as table
catalog_df = spark.createDataFrame([feature_catalog])
catalog_df.write.saveAsTable("feature_store.feature_catalog")

# Team can query: What features are available?
# Reduces duplication, improves collaboration
```

## Best Practices

### Feature Naming

```
Consistent naming convention:

Pattern: <entity>_<feature_name>_<aggregation>

Examples:
  customer_age_years
  customer_orders_count
  customer_spent_total
  customer_spent_avg_30d
  product_views_last_week

Benefits:
  • Self-documenting
  • Easy to search
  • Clear entity relationship
  • Aggregation explicit
```

### Data Quality

```python
# Validate features before storing

from pyspark.sql import functions as F

def validate_features(df):
    """Check feature quality"""

    # 1. No duplicate keys
    key_count = df.count()
    distinct_keys = df.select("customer_id").distinct().count()
    assert key_count == distinct_keys, "Duplicate keys found"

    # 2. No nulls in required columns
    null_counts = df.select([
        F.sum(F.col(c).isNull().cast("int")).alias(c)
        for c in df.columns
    ]).collect()[0]

    for col, null_count in null_counts.asDict().items():
        if null_count > 0:
            print(f"Warning: {col} has {null_count} nulls")

    # 3. Value ranges
    stats = df.describe().toPandas()
    print("Feature statistics:")
    print(stats)

    # 4. Distribution checks
    # Detect sudden shifts indicating data issues

    print("Validation passed!")
    return True

# Run before saving to Feature Store
if validate_features(new_features):
    new_features.write.saveAsTable("feature_store.customer_features")
```

### Feature Reuse

```python
# Maximize reuse across models

# Instead of:
# Model 1: Calculate customer_age inline
# Model 2: Calculate customer_age inline (slightly different)

# Do:
# Feature Store: customer_age (canonical definition)
# Model 1: Read from Feature Store
# Model 2: Read from Feature Store

# Example: Multiple models using same features
churn_model_data = spark.table("feature_store.customer_features")
ltv_model_data = spark.table("feature_store.customer_features")
segmentation_data = spark.table("feature_store.customer_features")

# All use same feature definitions
# Consistency guaranteed
# Compute once, use many times
```

## Points Clés

- Feature Store centralizes feature storage for ML
- Benefits: Reusability, consistency, discovery, versioning
- Create features with Spark: Demographics, RFM, time-based
- Scale with Spark: Broadcast joins, caching, built-in functions
- Delta Lake provides versioning and time travel
- Offline store (Delta): Training, batch scoring (seconds latency)
- Online store (Redis/Cosmos): Real-time serving (milliseconds)
- Integrate with training pipelines: Log feature versions in MLflow
- Schedule feature refresh: Daily/hourly depending on change rate
- Best practices: Consistent naming, data validation, maximize reuse
- Document features in catalog for team discovery

---

**Prochain fichier :** [05 - Déploiement de Modèles](./05-ml-models-deployment.md)

[⬅️ Fichier précédent](./03-automl-fabric.md) | [⬅️ Retour au README du module](./README.md)
