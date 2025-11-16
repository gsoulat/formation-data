# Notebooks dans Fabric

## Introduction

Les **Notebooks** Fabric permettent l'exécution de code **PySpark**, **Spark SQL**, **Scala**, et **R** pour le traitement distribué de données.

```
Notebook Architecture:
┌────────────────────────────────────────┐
│  Notebook (Interactive coding)         │
├────────────────────────────────────────┤
│  ├─ PySpark (Python)                   │
│  ├─ Spark SQL                          │
│  ├─ Scala                              │
│  └─ R / SparkR                         │
├────────────────────────────────────────┤
│  Spark Cluster (Distributed compute)   │
│  └─ OneLake (Delta Lake storage)       │
└────────────────────────────────────────┘
```

## Création d'un Notebook

### Via UI

```
1. Workspace → + New item
2. Notebook
3. Nom: "Transform_Data"
4. Choose language: PySpark (default)
```

**Interface Notebook :**
```
┌────────────────────────────────────────────────┐
│  [+ Code] [+ Markdown]    [▶ Run] [⏸ Stop]    │
├────────────────────────────────────────────────┤
│  Cell 1 (Code):                                │
│  df = spark.read.table("sales")                │
│  df.show()                                     │
│  ────────────────────────────────────────────  │
│  Output:                                       │
│  +------+--------+-------+                     │
│  |  id  | amount | date  |                     │
│  +------+--------+-------+                     │
├────────────────────────────────────────────────┤
│  Cell 2 (Markdown):                            │
│  ## Data Transformation                        │
│  This cell filters sales > $100                │
├────────────────────────────────────────────────┤
│  Cell 3 (Code):                                │
│  filtered = df.filter(df.amount > 100)         │
└────────────────────────────────────────────────┘
```

## Langages Supportés

### PySpark (Python)

```python
# Cell 1: Load data
df = spark.read.table("bronze_sales")

# Cell 2: Transform
from pyspark.sql.functions import col, sum as _sum

transformed = df.filter(col("amount") > 0) \
    .groupBy("country") \
    .agg(_sum("amount").alias("total_sales"))

# Cell 3: Save
transformed.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("silver_sales_by_country")
```

**Magic Commands :**
```python
# Change cell language
%%sql
SELECT * FROM sales LIMIT 10

%%markdown
# This is a markdown cell
Analysis results below...

%%sh
ls /lakehouse/default/Files/
```

### Spark SQL

```sql
-- Créer SQL cell
%%sql

-- Query
SELECT
    country,
    SUM(amount) as total_sales,
    COUNT(*) as order_count
FROM bronze_sales
WHERE sale_date >= '2024-01-01'
GROUP BY country
ORDER BY total_sales DESC
```

### Scala

```scala
%%scala

// Load data
val df = spark.read.table("sales")

// Transform
val result = df.filter($"amount" > 100)
    .groupBy("country")
    .agg(sum("amount").as("total"))

// Show
result.show()
```

### R / SparkR

```r
%%sparkr

# Load data
df <- sql("SELECT * FROM sales")

# Transform with SparkR
library(SparkR)
result <- summarize(
    groupBy(df, df$country),
    total_sales = sum(df$amount)
)

# Show
showDF(result)
```

## Lakehouse Integration

### Default Lakehouse

```python
# Chaque notebook attaché à un Lakehouse
# Accès automatique via 'spark' object

# Read from Tables
df = spark.table("bronze_sales")

# Read from Files
df = spark.read.parquet("Files/raw/sales.parquet")

# Write to Tables
df.write.format("delta").saveAsTable("silver_sales")

# Write to Files
df.write.parquet("Files/processed/sales.parquet")
```

**Lakehouse Context :**
```python
# Current lakehouse
print(spark.conf.get("spark.lakehouse.name"))

# Lakehouse path
print(spark.conf.get("spark.lakehouse.abfss.path"))

# List tables
spark.sql("SHOW TABLES").show()

# List files
dbutils.fs.ls("Files/")
```

### Multiple Lakehouses

```python
# Attach additional lakehouse
# Via UI: Lakehouse explorer → Add lakehouse

# Access tables from different lakehouse
df = spark.read.table("OtherLakehouse.bronze_customers")

# Or using fully qualified name
df = spark.sql("""
    SELECT * FROM OtherLakehouse.dbo.customers
""")
```

## Spark Session

### Configuration

```python
# Spark session auto-créée (variable 'spark')
print(spark)
# SparkSession - in-memory

# View configuration
spark.conf.get("spark.sql.shuffle.partitions")

# Set configuration
spark.conf.set("spark.sql.shuffle.partitions", "200")

# Temporary config (session only)
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "10485760")
```

### Common Configurations

```python
# Shuffle partitions (default: 200)
spark.conf.set("spark.sql.shuffle.partitions", "100")

# Broadcast join threshold (default: 10MB)
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "52428800")  # 50MB

# Adaptive Query Execution
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Dynamic allocation
spark.conf.set("spark.dynamicAllocation.enabled", "true")
spark.conf.set("spark.dynamicAllocation.minExecutors", "2")
spark.conf.set("spark.dynamicAllocation.maxExecutors", "10")
```

## Variables et State

### Cross-Cell Variables

```python
# Cell 1: Define variable
sales_df = spark.table("sales")
total_amount = sales_df.select(sum("amount")).collect()[0][0]

# Cell 2: Use variable from Cell 1
print(f"Total sales: ${total_amount:,.2f}")

# Cell 3: Modify variable
filtered_df = sales_df.filter(col("country") == "FR")
```

**State persiste across cells in same session**

### Notebook Parameters

```python
# Define parameters (special cell at top)
# Tagged as "parameters" in notebook

country = "FR"  # Default value
start_date = "2024-01-01"
batch_size = 1000

# Use in notebook
df = spark.table("sales") \
    .filter(col("country") == country) \
    .filter(col("sale_date") >= start_date) \
    .limit(batch_size)
```

**Pass parameters when running from Pipeline :**
```json
{
  "name": "Run_Notebook",
  "type": "SparkNotebook",
  "typeProperties": {
    "notebook": {"referenceName": "Transform_Data"},
    "parameters": {
      "country": "US",
      "start_date": "2024-01-15",
      "batch_size": 5000
    }
  }
}
```

## Utilities (mssparkutils)

### Filesystem Operations

```python
# List files/folders
mssparkutils.fs.ls("Files/")

# Create directory
mssparkutils.fs.mkdirs("Files/processed/")

# Copy file
mssparkutils.fs.cp("Files/raw/data.csv", "Files/archive/data.csv")

# Move file
mssparkutils.fs.mv("Files/temp/data.csv", "Files/processed/data.csv")

# Delete file
mssparkutils.fs.rm("Files/temp/old_file.csv")

# Read file content
content = mssparkutils.fs.head("Files/config.txt", 100)
print(content)
```

### Notebook Utilities

```python
# Exit notebook with return value
result = {"status": "success", "rows_processed": 1000}
mssparkutils.notebook.exit(result)

# Run another notebook
result = mssparkutils.notebook.run(
    "OtherNotebook",
    timeout_seconds=600,
    arguments={"param1": "value1"}
)

# Get workspace context
workspace_id = mssparkutils.env.getWorkspaceId()
```

### Credentials

```python
# Get secret from Key Vault (if configured)
secret = mssparkutils.credentials.getSecret(
    "https://myvault.vault.azure.net/",
    "database-password"
)

# Use in connection
df = spark.read.format("jdbc") \
    .option("url", "jdbc:sqlserver://server.database.windows.net") \
    .option("dbtable", "sales") \
    .option("user", "admin") \
    .option("password", secret) \
    .load()
```

## Execution et Debugging

### Run Cells

```
Run current cell: Shift + Enter
Run all cells: Notebook → Run all
Run cells above: Notebook → Run cells above
Run cells below: Notebook → Run cells below
Stop execution: ⏸ Stop button
```

### Cell Output

```python
# Display DataFrame
df.show()

# Limit output
df.show(20, truncate=False)

# Display as pandas (for small data)
df.limit(100).toPandas()

# Count
print(f"Total rows: {df.count()}")

# Display HTML
from IPython.display import display, HTML
display(HTML("<h1>Results</h1>"))
```

### Debugging

```python
# Print debugging
print(f"Processing {df.count()} rows")

# Display execution plan
df.explain(extended=True)

# Display physical plan
df.explain(mode="formatted")

# Check dataframe schema
df.printSchema()

# Show sample data
df.show(5)

# Describe statistics
df.describe().show()
```

## Visualizations

### Built-in Charts

```python
# Load data
df = spark.sql("""
    SELECT country, SUM(amount) as total_sales
    FROM sales
    GROUP BY country
""")

# Display chart (click chart icon in output)
display(df)

# Chart types available in UI:
# - Bar chart
# - Line chart
# - Pie chart
# - Scatter plot
# - Map
```

### Matplotlib

```python
import matplotlib.pyplot as plt

# Convert to Pandas for plotting
pdf = df.toPandas()

# Create plot
plt.figure(figsize=(10, 6))
plt.bar(pdf['country'], pdf['total_sales'])
plt.xlabel('Country')
plt.ylabel('Total Sales')
plt.title('Sales by Country')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Plotly

```python
import plotly.express as px

# Interactive plot
pdf = df.toPandas()
fig = px.bar(pdf, x='country', y='total_sales', title='Sales by Country')
fig.show()
```

## Best Practices

### ✅ Cell Organization

```python
# Cell 1: Imports and setup
from pyspark.sql.functions import col, sum, avg
from datetime import datetime

# Cell 2: Parameters
PROCESSING_DATE = "2024-01-15"
COUNTRY_FILTER = "FR"

# Cell 3: Load data
sales_df = spark.table("bronze_sales")

# Cell 4: Transform
filtered_df = sales_df.filter(col("sale_date") == PROCESSING_DATE)

# Cell 5: Save results
filtered_df.write.format("delta").mode("overwrite").saveAsTable("output")

# Cell 6: Validation
print(f"Rows written: {filtered_df.count()}")
```

### ✅ Markdown Documentation

```markdown
# Data Processing Notebook

## Purpose
Process daily sales data and aggregate by country

## Input
- Table: `bronze_sales`
- Date: 2024-01-15

## Output
- Table: `silver_sales_by_country`

## Steps
1. Load raw sales data
2. Filter by date
3. Aggregate by country
4. Save to silver layer
```

### ✅ Error Handling

```python
try:
    df = spark.table("bronze_sales")
    result = df.filter(col("amount") > 0)
    result.write.format("delta").mode("overwrite").saveAsTable("output")
    print("✅ Success")
except Exception as e:
    print(f"❌ Error: {str(e)}")
    # Log error
    mssparkutils.notebook.exit({"status": "failed", "error": str(e)})
```

## Points Clés

- Notebooks = interactive coding (PySpark, SQL, Scala, R)
- Lakehouse integration automatique
- Spark session pré-configurée
- Parameters pour réutilisabilité
- mssparkutils pour filesystem et utilities
- Visualizations intégrées
- Cell-by-cell execution
- State persiste across cells
- Pipeline integration possible
- Magic commands (%%sql, %%markdown, etc.)

---

**Prochain fichier :** [02 - PySpark Basics](./02-pyspark-basics.md)

[⬅️ Retour au README du module](./README.md)
