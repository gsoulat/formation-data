# Direct Lake Mode

## Introduction

**Direct Lake** est l'innovation révolutionnaire de Microsoft Fabric, combinant la performance de l'Import avec la fraîcheur des données du DirectQuery, sans compromis.

```
Evolution of Storage Modes:
┌──────────────────────────────────────────┐
│  Import (Legacy)                         │
│  ✅ Fast │ ❌ Stale data │ ❌ Refreshes  │
├──────────────────────────────────────────┤
│  DirectQuery (Legacy)                    │
│  ✅ Fresh │ ❌ Slow │ ❌ Source load     │
├──────────────────────────────────────────┤
│  Direct Lake (Fabric Innovation) 🚀      │
│  ✅ Fast │ ✅ Fresh │ ✅ No copy         │
└──────────────────────────────────────────┘
```

## Architecture Technique

### Comment ça fonctionne

```
Traditional Import:
┌──────────┐  Copy   ┌───────────┐  Query  ┌──────────┐
│ Source   │────────→│  VertiPaq │←────────│ Power BI │
│ (Delta)  │  (ETL)  │  (memory) │ (fast)  │          │
└──────────┘         └───────────┘         └──────────┘
  Latency: Refresh schedule (hours/days)
  Duplication: Yes (source + VertiPaq)

Direct Lake:
┌──────────┐         ┌───────────┐  Query  ┌──────────┐
│ OneLake  │←────────│  VertiPaq │←────────│ Power BI │
│ (Delta)  │  Direct │  (reads   │ (fast)  │          │
└──────────┘  Read   │  Parquet) │         └──────────┘
  Latency: Real-time (seconds)
  Duplication: No (reads directly from Delta)
```

### Technical Details

```
Direct Lake leverages:
┌──────────────────────────────────────────┐
│  1. Delta Lake Format                    │
│     ├─ Parquet files (columnar)          │
│     ├─ Transaction log                   │
│     └─ Metadata (statistics, schema)     │
├──────────────────────────────────────────┤
│  2. VertiPaq Engine                      │
│     ├─ Reads Parquet directly            │
│     ├─ In-memory cache (hot data)        │
│     └─ Columnar compression              │
├──────────────────────────────────────────┤
│  3. OneLake Integration                  │
│     ├─ Single storage (no duplication)   │
│     ├─ ADLS Gen2 compatible              │
│     └─ Unified security                  │
└──────────────────────────────────────────┘

Key innovation:
  VertiPaq can read Parquet files directly
  without importing/copying data first!
```

## Avantages vs Import et DirectQuery

### Performance Comparison

```
Query Performance:
┌──────────────────────────────────────────┐
│  Import:         ███████████ (Fast)      │
│  Direct Lake:    ██████████  (Very Fast) │
│  DirectQuery:    ████        (Slow)      │
└──────────────────────────────────────────┘

Data Freshness:
┌──────────────────────────────────────────┐
│  Import:         ██          (Hours/Days)│
│  Direct Lake:    ███████████ (Seconds)   │
│  DirectQuery:    ███████████ (Real-time) │
└──────────────────────────────────────────┘

Data Volume Limit:
┌──────────────────────────────────────────┐
│  Import:         ███         (GB limit)  │
│  Direct Lake:    ███████████ (TB scale)  │
│  DirectQuery:    ███████████ (Unlimited) │
└──────────────────────────────────────────┘
```

### Feature Matrix

```
Feature             │ Import │ DirectQuery │ Direct Lake
────────────────────┼────────┼─────────────┼────────────
Query Speed         │   ✅   │      ❌     │     ✅
Data Freshness      │   ❌   │      ✅     │     ✅
No Data Duplication │   ❌   │      ✅     │     ✅
Full DAX Support    │   ✅   │      ⚠️     │     ✅
Large Datasets      │   ❌   │      ✅     │     ✅
Offline Access      │   ✅   │      ❌     │     ⚠️
Incremental Refresh │   ✅   │      ❌     │     ✅
Aggregations        │   ✅   │      ⚠️     │     ✅
```

## Lecture Directe depuis OneLake

### Data Flow

```
1. User queries Power BI report
         ↓
2. DAX query sent to VertiPaq engine
         ↓
3. VertiPaq reads Delta table metadata
         ↓
4. VertiPaq identifies relevant Parquet files
         ↓
5. VertiPaq reads Parquet columnar data directly
         ↓
6. VertiPaq applies filters, aggregations
         ↓
7. Results returned to Power BI
         ↓
8. Visual updated

Speed: Milliseconds for most queries!
```

### Caching Strategy

```
Direct Lake Intelligent Caching:
┌──────────────────────────────────────────┐
│  Hot Data (Frequently Accessed)          │
│  ├─ Cached in VertiPaq memory            │
│  ├─ Sub-second query response            │
│  └─ Example: Current month sales         │
├──────────────────────────────────────────┤
│  Warm Data (Occasionally Accessed)       │
│  ├─ Partially cached                     │
│  ├─ Read from Delta on-demand            │
│  └─ Example: Last year sales             │
├──────────────────────────────────────────┤
│  Cold Data (Rarely Accessed)             │
│  ├─ Not cached                           │
│  ├─ Read from OneLake when needed        │
│  └─ Example: Historical data (5+ years)  │
└──────────────────────────────────────────┘

Benefits:
  ✅ Memory efficiency (cache what matters)
  ✅ Fast for common queries
  ✅ Support for large datasets
```

## Prérequis et Limitations

### Requirements

```
✅ Required:
  1. Microsoft Fabric capacity (F SKU)
  2. Data stored in OneLake
  3. Delta Lake table format
  4. Parquet file format (V-Order optimized)
  5. Compatible data types

✅ Recommended:
  • V-Order optimization enabled
  • Delta table optimized (OPTIMIZE command)
  • Appropriate partitioning
  • Regular VACUUM for cleanup
```

### Creating Direct Lake Model

```
Step-by-step:
1. Create Lakehouse with Delta tables
   spark.sql("CREATE TABLE sales (...) USING DELTA")

2. Optimize tables for Direct Lake
   spark.sql("OPTIMIZE sales")
   spark.sql("OPTIMIZE sales ZORDER BY (customer_id)")

3. Create Semantic Model
   Workspace → New → Semantic model
   Source: Lakehouse (auto-detects Direct Lake)

4. Verify mode
   Model settings → Storage mode → "Direct Lake"

5. Create Power BI report
   Connect to semantic model
   Build visualizations
```

### Data Type Support

```
✅ Supported Types:
  • INT, BIGINT, SMALLINT
  • DECIMAL, DOUBLE, FLOAT
  • STRING, VARCHAR
  • DATE, TIMESTAMP
  • BOOLEAN
  • BINARY (with limitations)

❌ Unsupported Types:
  • Complex types (ARRAY, STRUCT, MAP)
  • Custom UDTs

Workaround:
  Flatten complex types in Delta table:
  df.select(col("address.city").alias("city"))
```

### Size Limitations

```
Direct Lake Limits (as of 2024):
┌──────────────────────────────────────────┐
│  Maximum Capacity                        │
│  ├─ F2:    10 GB                         │
│  ├─ F64:   64 GB                         │
│  ├─ F128:  128 GB                        │
│  └─ F2048: 2 TB                          │
├──────────────────────────────────────────┤
│  Per Table                               │
│  └─ Unlimited rows                       │
├──────────────────────────────────────────┤
│  Tables per Model                        │
│  └─ Unlimited (within capacity limit)    │
└──────────────────────────────────────────┘

Note: Limits refer to uncompressed size
      Actual compressed size much smaller
```

## Fallback to DirectQuery

### When Fallback Occurs

```
Automatic fallback to DirectQuery when:
❌ Unsupported data type encountered
❌ Unsupported DAX expression used
❌ Model size exceeds capacity limit
❌ Complex calculated columns
❌ Some advanced DAX functions

Example:
  Model has 100 GB data on F64 (64 GB limit)
  → Automatic fallback to DirectQuery mode
  → Queries still work (but slower)
```

### Detecting Fallback

```
Check storage mode:
1. Model settings → Tables
2. Look for "DirectQuery" instead of "Direct Lake"

Query Performance:
  • Slow queries = likely in DirectQuery mode
  • Check Performance Analyzer

DAX Studio:
  • Connect to model
  • Run query
  • Check "Storage Engine" in query plan
  • "SE" (Storage Engine) = Direct Lake ✅
  • "DirectQuery" = Fallback ❌
```

### Preventing Fallback

```
✅ Best Practices:
1. Keep model size within capacity limit
   • Use partitioning
   • Archive old data
   • Aggregate historical data

2. Avoid unsupported DAX
   • Test measures in DAX Studio
   • Check compatibility list

3. Simplify calculated columns
   • Move logic to source (Spark)
   • Use measures instead

4. Optimize Delta tables
   • OPTIMIZE regularly
   • Z-Order on filter columns
   • VACUUM old versions

5. Monitor capacity usage
   • Fabric Capacity Metrics app
   • Set up alerts
```

## Use Cases Optimaux

### ✅ Perfect for Direct Lake

```
1. Large-scale analytics
   • Sales data (millions of rows)
   • Web analytics (billions of events)
   • IoT telemetry

2. Near real-time dashboards
   • Executive dashboards
   • Operational reports
   • Live KPI monitoring

3. Medallion architecture
   • Bronze/Silver/Gold layers
   • Each layer as Direct Lake model
   • Single source of truth

4. Self-service BI
   • Business users create reports
   • Centralized semantic model
   • Consistent business logic

5. Mixed latency requirements
   • Some data needs to be fresh (Direct Lake)
   • Some can be stale (cached)
```

### ⚠️ Consider Alternatives

```
Use Import when:
  ❌ Data sources outside OneLake
  ❌ Need offline access (Power BI Desktop)
  ❌ Complex data transformations in Power Query

Use DirectQuery when:
  ❌ Data source is not Delta Lake
  ❌ Direct connection to SQL Server/Warehouse
  ❌ Compliance requires no data copy

Use Composite when:
  ❌ Mix of Import + Direct Lake
  ❌ Aggregations for performance
  ❌ Hybrid scenarios
```

## Monitoring & Optimization

### Performance Monitoring

```
Tools:
1. Performance Analyzer (Power BI)
   • Analyze visual performance
   • Identify slow queries
   • DAX query duration

2. DAX Studio
   • Server timings
   • Query plans
   • Storage engine queries

3. Fabric Capacity Metrics
   • Capacity utilization
   • Memory usage
   • Throttling events

Metrics to watch:
  ✅ Query duration < 1 second (good)
  ⚠️ Query duration 1-5 seconds (ok)
  ❌ Query duration > 5 seconds (investigate)
```

### Optimization Techniques

**1. Delta Table Optimization:**
```sql
-- Compact small files
OPTIMIZE sales;

-- Z-Order for faster filters
OPTIMIZE sales ZORDER BY (customer_id, order_date);

-- Enable V-Order
ALTER TABLE sales
SET TBLPROPERTIES ('delta.parquet.vorder.enabled' = 'true');

-- Clean old versions
VACUUM sales RETAIN 168 HOURS;
```

**2. Model Optimization:**
```
• Remove unused columns
• Hide technical columns
• Use appropriate data types (int vs string)
• Minimize calculated columns
• Create aggregation tables for large fact tables
```

**3. DAX Optimization:**
```dax
-- ❌ Bad: FILTER on large table
Sales Amount =
CALCULATE(
    SUM(Sales[Amount]),
    FILTER(
        ALL(Sales),
        Sales[Country] = "FR"
    )
)

-- ✅ Good: Use CALCULATE filter argument
Sales Amount =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Country] = "FR"
)
```

## Example: Create Direct Lake Model

### Step 1: Prepare Delta Table

```python
# In Fabric Notebook
from pyspark.sql.functions import *

# Load data
df = spark.read.parquet("Files/raw/sales.parquet")

# Transform
sales_clean = df.filter(col("amount") > 0) \
    .withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date")))

# Write as Delta with V-Order
sales_clean.write.format("delta") \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .option("delta.parquet.vorder.enabled", "true") \
    .saveAsTable("sales")

# Optimize
spark.sql("OPTIMIZE sales ZORDER BY (customer_id, product_id)")
```

### Step 2: Create Semantic Model

```
1. Workspace → + New → Semantic model
2. Name: "Sales Analytics"
3. Source: Lakehouse → Select your lakehouse
4. Select tables:
   ✅ sales
   ✅ customers
   ✅ products
   ✅ date_dim
5. Create
```

### Step 3: Configure Model

```
Model View in Power BI:
1. Define relationships
   sales[customer_id] → customers[customer_id]
   sales[product_id] → products[product_id]
   sales[order_date] → date_dim[date]

2. Hide technical columns
   sales[customer_id], sales[product_id] = Hidden

3. Create measures
   Total Sales = SUM(sales[amount])
   Order Count = COUNTROWS(sales)

4. Verify Direct Lake mode
   Settings → Storage mode → "Direct Lake" ✅

5. Publish
```

### Step 4: Validate Performance

```
1. Create test report
2. Add visuals (table, chart)
3. Run Performance Analyzer
4. Check query duration < 1 second

5. Open DAX Studio
6. Connect to model
7. Run query:
   EVALUATE SUMMARIZE(sales, sales[year], "Total", SUM(sales[amount]))
8. Check query plan shows "Storage Engine" (not DirectQuery)
```

## Points Clés

- Direct Lake = révolution Fabric (Import speed + DirectQuery freshness)
- Lecture directe des fichiers Parquet Delta sans copie
- VertiPaq lit le format Delta nativement
- Prérequis: OneLake, Delta Lake, V-Order
- Caching intelligent (hot/warm/cold data)
- Fallback to DirectQuery si limitations dépassées
- Optimal pour large-scale analytics temps-réel
- Monitoring via Performance Analyzer et DAX Studio
- Optimization: OPTIMIZE, Z-Order, V-Order sur Delta tables
- Limite de taille selon SKU Fabric (F2-F2048)

---

**Prochain fichier :** [03 - Import vs DirectQuery vs Direct Lake](./03-import-vs-directquery.md)

[⬅️ Fichier précédent](./01-semantic-models-overview.md) | [⬅️ Retour au README du module](./README.md)
