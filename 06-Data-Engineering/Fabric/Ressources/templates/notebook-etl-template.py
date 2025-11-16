# Fabric Notebook - ETL Pipeline Template
# ==========================================
# Template for data ingestion and transformation in Fabric Lakehouse
# Author: Data Engineering Team
# Last Updated: 2024

# %% [markdown]
# # ETL Pipeline: [Pipeline Name]
#
# **Purpose:** [Brief description of what this pipeline does]
#
# **Source:** [Data source description]
#
# **Target:** [Target Lakehouse/Warehouse table]
#
# **Schedule:** [Daily/Hourly/On-demand]

# %% Configuration
# Note: In Fabric notebooks, 'spark' is pre-defined. SparkSession import shown for reference.
# from pyspark.sql import SparkSession  # Not needed in Fabric - spark is pre-defined
from pyspark.sql import functions as F
from pyspark.sql.types import LongType, DecimalType, StringType, TimestampType
from pyspark.sql.window import Window
from delta.tables import DeltaTable
from datetime import datetime
import json

# Pipeline Parameters
PIPELINE_NAME = "your_pipeline_name"
SOURCE_PATH = "Files/raw/source_data/"
TARGET_TABLE = "lakehouse.your_target_table"
WATERMARK_TABLE = "lakehouse.etl_watermarks"
LOG_TABLE = "lakehouse.etl_logs"

# Configuration
config = {
    "batch_size": 100000,
    "max_retries": 3,
    "checkpoint_location": f"Files/checkpoints/{PIPELINE_NAME}/",
    "enable_schema_evolution": True
}

# %% Logging Setup
def log_pipeline_event(event_type, message, details=None):
    """Log pipeline events for monitoring"""
    log_entry = {
        "pipeline_name": PIPELINE_NAME,
        "event_type": event_type,
        "message": message,
        "details": json.dumps(details) if details else None,
        "timestamp": datetime.now().isoformat(),
        "run_id": spark.sparkContext.applicationId
    }

    log_df = spark.createDataFrame([log_entry])
    log_df.write.mode("append").saveAsTable(LOG_TABLE)

    print(f"[{event_type}] {message}")

# %% Data Quality Functions
def validate_schema(df, expected_columns):
    """Validate that DataFrame has expected columns"""
    actual_columns = set(df.columns)
    expected_set = set(expected_columns)

    missing = expected_set - actual_columns

    if missing:
        raise ValueError(f"Missing columns: {missing}")

    # Note: Extra columns are allowed (schema evolution)
    return True

def check_data_quality(df, rules):
    """Apply data quality rules and return report"""
    quality_report = {}

    total_rows = df.count()
    quality_report["total_rows"] = total_rows

    # Null check
    for col in df.columns:
        null_count = df.filter(F.col(col).isNull()).count()
        null_pct = (null_count / total_rows * 100) if total_rows > 0 else 0
        quality_report[f"{col}_null_pct"] = round(null_pct, 2)

    # Custom rules
    for rule_name, rule_condition in rules.items():
        failed_count = df.filter(~rule_condition).count()
        quality_report[rule_name] = {
            "passed": total_rows - failed_count,
            "failed": failed_count,
            "pass_rate": round((total_rows - failed_count) / total_rows * 100, 2) if total_rows > 0 else 0
        }

    return quality_report

def remove_duplicates(df, key_columns):
    """Remove duplicate rows based on key columns, keeping latest"""
    window = Window.partitionBy(*key_columns).orderBy(F.col("_ingestion_time").desc())
    return df.withColumn("_row_num", F.row_number().over(window)) \
             .filter(F.col("_row_num") == 1) \
             .drop("_row_num")

# %% Watermark Management
def get_watermark(table_name):
    """Get last processed watermark for incremental load"""
    try:
        watermark_df = spark.table(WATERMARK_TABLE).filter(
            F.col("table_name") == table_name
        )
        if watermark_df.count() > 0:
            return watermark_df.first()["last_watermark"]
    except Exception:
        # Table doesn't exist yet or other error
        pass
    return None

def update_watermark(table_name, new_watermark):
    """Update watermark after successful processing"""
    watermark_data = {
        "table_name": table_name,
        "last_watermark": str(new_watermark),
        "updated_at": datetime.now().isoformat()
    }

    # Upsert watermark
    watermark_df = spark.createDataFrame([watermark_data])

    if spark.catalog.tableExists(WATERMARK_TABLE):
        delta_table = DeltaTable.forName(spark, WATERMARK_TABLE)
        delta_table.alias("target").merge(
            watermark_df.alias("source"),
            "target.table_name = source.table_name"
        ).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
    else:
        watermark_df.write.saveAsTable(WATERMARK_TABLE)

# %% Extract
def extract_data():
    """Extract data from source"""
    log_pipeline_event("EXTRACT_START", f"Starting extraction from {SOURCE_PATH}")

    # Option 1: Read from files
    # df = spark.read.format("parquet").load(SOURCE_PATH)

    # Option 2: Read from external database
    # jdbc_url = "jdbc:sqlserver://server:1433;database=db"
    # df = spark.read.jdbc(url=jdbc_url, table="source_table", properties=props)

    # Option 3: Read from existing Lakehouse table
    # df = spark.table("lakehouse.source_table")

    # Option 4: Incremental load with watermark
    last_watermark = get_watermark(TARGET_TABLE)

    if last_watermark:
        log_pipeline_event("INCREMENTAL", f"Loading data since {last_watermark}")
        df = spark.read.format("parquet").load(SOURCE_PATH) \
            .filter(F.col("modified_date") > last_watermark)
    else:
        log_pipeline_event("FULL_LOAD", "Performing full load")
        df = spark.read.format("parquet").load(SOURCE_PATH)

    # Add metadata columns
    df = df.withColumn("_ingestion_time", F.current_timestamp()) \
           .withColumn("_source_file", F.input_file_name())

    row_count = df.count()
    log_pipeline_event("EXTRACT_COMPLETE", f"Extracted {row_count} rows")

    return df

# %% Transform
def transform_data(df):
    """Apply transformations to data"""
    log_pipeline_event("TRANSFORM_START", "Starting transformations")

    # Schema validation
    expected_columns = ["id", "name", "value", "created_date", "modified_date"]
    validate_schema(df, expected_columns)

    # Data type standardization
    df = df.withColumn("id", F.col("id").cast(LongType())) \
           .withColumn("name", F.trim(F.upper(F.col("name")))) \
           .withColumn("value", F.col("value").cast(DecimalType(18, 2))) \
           .withColumn("created_date", F.to_date("created_date")) \
           .withColumn("modified_date", F.to_timestamp("modified_date"))

    # Handle nulls
    df = df.fillna({
        "value": 0.0,
        "name": "UNKNOWN"
    })

    # Business logic transformations
    df = df.withColumn("value_category",
        F.when(F.col("value") > 1000, "HIGH")
         .when(F.col("value") > 100, "MEDIUM")
         .otherwise("LOW")
    )

    # Add calculated fields
    df = df.withColumn("year", F.year("created_date")) \
           .withColumn("month", F.month("created_date"))

    # Remove duplicates (Window already imported at top)
    df = remove_duplicates(df, ["id"])

    # Data quality checks
    quality_rules = {
        "value_positive": F.col("value") >= 0,
        "name_not_empty": F.length(F.col("name")) > 0,
        "valid_date": F.col("created_date").isNotNull()
    }

    quality_report = check_data_quality(df, quality_rules)
    log_pipeline_event("QUALITY_CHECK", "Data quality validation", quality_report)

    # Fail if critical quality issues
    if quality_report.get("value_positive", {}).get("pass_rate", 0) < 95:
        raise ValueError("Critical quality issue: Too many negative values")

    log_pipeline_event("TRANSFORM_COMPLETE", f"Transformed {df.count()} rows")

    return df

# %% Load
def load_data(df):
    """Load data into target table"""
    log_pipeline_event("LOAD_START", f"Loading data to {TARGET_TABLE}")

    # Option 1: Overwrite (full refresh)
    # df.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(TARGET_TABLE)

    # Option 2: Append (incremental)
    # df.write.mode("append").saveAsTable(TARGET_TABLE)

    # Option 3: Merge/Upsert (recommended for incremental)
    if spark.catalog.tableExists(TARGET_TABLE):
        delta_table = DeltaTable.forName(spark, TARGET_TABLE)

        delta_table.alias("target").merge(
            df.alias("source"),
            "target.id = source.id"
        ).whenMatchedUpdate(
            condition="source.modified_date > target.modified_date",
            set={
                "name": "source.name",
                "value": "source.value",
                "value_category": "source.value_category",
                "modified_date": "source.modified_date",
                "_ingestion_time": "source._ingestion_time"
            }
        ).whenNotMatchedInsertAll().execute()

        log_pipeline_event("MERGE_COMPLETE", "Delta merge completed")
    else:
        # First load - create table
        df.write.format("delta") \
          .partitionBy("year", "month") \
          .saveAsTable(TARGET_TABLE)
        log_pipeline_event("TABLE_CREATED", f"Created new table {TARGET_TABLE}")

    # Update watermark
    max_watermark = df.agg(F.max("modified_date")).collect()[0][0]
    if max_watermark:
        update_watermark(TARGET_TABLE, max_watermark)

    # Optimize table periodically
    # spark.sql(f"OPTIMIZE {TARGET_TABLE} ZORDER BY (id)")

    log_pipeline_event("LOAD_COMPLETE", f"Successfully loaded data to {TARGET_TABLE}")

# %% Main Execution
def run_pipeline():
    """Main ETL pipeline execution"""
    start_time = datetime.now()
    log_pipeline_event("PIPELINE_START", f"Starting {PIPELINE_NAME}")

    try:
        # Extract
        raw_df = extract_data()

        if raw_df.count() == 0:
            log_pipeline_event("NO_DATA", "No new data to process")
            return

        # Transform
        transformed_df = transform_data(raw_df)

        # Load
        load_data(transformed_df)

        # Success
        duration = (datetime.now() - start_time).total_seconds()
        log_pipeline_event("PIPELINE_SUCCESS", f"Pipeline completed in {duration:.2f} seconds")

    except Exception as e:
        log_pipeline_event("PIPELINE_ERROR", f"Pipeline failed: {str(e)}")
        raise

# Execute pipeline
if __name__ == "__main__":
    run_pipeline()

# %% Post-execution Validation
# Uncomment to run after pipeline
"""
# Check table stats
spark.sql(f"DESCRIBE DETAIL {TARGET_TABLE}").show()

# Sample output
spark.table(TARGET_TABLE).show(10)

# Recent ingestion stats
spark.sql(f'''
    SELECT
        DATE(_ingestion_time) as load_date,
        COUNT(*) as row_count,
        MIN(modified_date) as min_date,
        MAX(modified_date) as max_date
    FROM {TARGET_TABLE}
    GROUP BY DATE(_ingestion_time)
    ORDER BY load_date DESC
    LIMIT 5
''').show()
"""
