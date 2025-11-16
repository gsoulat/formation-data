# Warehouse vs Lakehouse

## Comparaison Architecture

```
┌────────────────────────────────────────────────────────────┐
│              SYNAPSE DATA WAREHOUSE                         │
├────────────────────────────────────────────────────────────┤
│  • SQL-first experience                                    │
│  • MPP engine optimisé                                     │
│  • Structured data seulement                               │
│  • Transactions complètes                                  │
│  • Business intelligence                                   │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                    LAKEHOUSE                                │
├────────────────────────────────────────────────────────────┤
│  • Spark-first experience                                  │
│  • Flexible data formats                                   │
│  • Structured + Semi-structured + Unstructured             │
│  • Data science & ML                                       │
│  • ETL/ELT transformations                                 │
└────────────────────────────────────────────────────────────┘
```

## Différences Fondamentales

| Aspect | Data Warehouse | Lakehouse |
|--------|---------------|-----------|
| **Primary Interface** | T-SQL | PySpark, Spark SQL, Notebooks |
| **Engine** | MPP SQL Engine | Apache Spark |
| **Data Types** | Structured (tables) | Structured + Semi + Unstructured |
| **File Formats** | Delta (managed) | Delta, Parquet, CSV, JSON |
| **Transactions** | Full ACID (SQL) | ACID via Delta Lake |
| **Schema** | Schema-on-write (strict) | Schema-on-read (flexible) |
| **Compute** | SQL pools | Spark executors |
| **Storage** | OneLake (Delta backend) | OneLake (Files + Tables) |
| **Primary Use Case** | BI, Analytics, Reporting | Data Engineering, ML, ETL |
| **Query Language** | T-SQL | Spark SQL, Python, Scala, R |
| **Indexing** | Columnstore, Clustered | Partitioning, Z-Order |
| **Concurrent Users** | High (BI tools) | Medium (data engineers) |
| **Cost Model** | Capacity-based | Capacity-based |

## Quand Utiliser Data Warehouse

### ✅ Use Cases Idéaux

**1. Business Intelligence & Reporting**
```
Scénario: Dashboards Power BI pour execs
- 100+ utilisateurs concurrent
- Requêtes complexes avec JOINs
- Performance < 1s requise
- Données structurées uniquement

→ Data Warehouse optimal
```

**2. SQL-Heavy Workloads**
```sql
-- Requêtes complexes avec CTEs
WITH sales_summary AS (
    SELECT ...
),
customer_segments AS (
    SELECT ...
)
SELECT ...
FROM sales_summary s
JOIN customer_segments c ...;

→ Warehouse optimisé pour ce pattern
```

**3. Existing SQL Skills**
```
Équipe:
- DBAs SQL Server
- Analysts avec T-SQL
- SSMS, Azure Data Studio workflows

→ Warehouse = courbe d'apprentissage minimale
```

**4. Star Schema & OLAP**
```
Data Model:
┌─────────────┐
│  Fact Table │
│   (Sales)   │
└──────┬──────┘
       │
   ┌───┴───┬───────┬────────┐
   │       │       │        │
 Dim     Dim     Dim      Dim
Product Customer Time   Store

→ Warehouse conçu pour star schemas
```

**5. High Concurrency Analytics**
```
Requirements:
- 50-100+ concurrent users
- Interactive queries (<2s)
- Row-level security
- Column-level security

→ Warehouse supporte haute concurrence
```

### ❌ Pas Idéal Pour

- Unstructured data (images, logs bruts)
- Data science / ML workflows
- ETL complexe avec Python
- Semi-structured data (JSON, XML)
- Files-based processing

## Quand Utiliser Lakehouse

### ✅ Use Cases Idéaux

**1. Data Engineering & ETL**
```python
# Transformations complexes avec PySpark
df = spark.read.parquet("bronze/raw_data") \
    .filter(col("date") >= "2024-01-01") \
    .groupBy("customer_id") \
    .agg(
        sum("amount").alias("total"),
        count("*").alias("transactions")
    ) \
    .join(lookup_df, "customer_id")

df.write.format("delta").saveAsTable("silver_customer_summary")

→ Lakehouse excel pour ETL
```

**2. Machine Learning**
```python
# Feature engineering
features_df = spark.table("silver_customer_features")

# Train model
from pyspark.ml.classification import RandomForestClassifier
rf = RandomForestClassifier(featuresCol="features", labelCol="churn")
model = rf.fit(features_df)

# Save model
model.write().save("Models/churn_prediction")

→ Lakehouse intégré avec Spark ML
```

**3. Multi-Format Data**
```
Data Sources:
├── CSV files (legacy systems)
├── JSON (APIs)
├── Parquet (optimized storage)
├── Images (computer vision)
└── Logs (text files)

→ Lakehouse gère tous formats
```

**4. Medallion Architecture**
```
Bronze (raw) → Silver (clean) → Gold (business)

# Python/Spark optimal pour transformations
bronze_df = spark.read.json("Files/bronze/")
silver_df = clean_and_validate(bronze_df)
gold_df = aggregate_business_metrics(silver_df)

→ Lakehouse conçu pour ce pattern
```

**5. Data Science Notebooks**
```python
# Exploratory analysis
import pandas as pd
import matplotlib.pyplot as plt

df = spark.table("customer_data").toPandas()
df.plot(kind='hist', column='age')
plt.show()

→ Lakehouse avec notebooks interactifs
```

### ❌ Pas Idéal Pour

- Pure SQL analytics (pas de Python/Spark)
- Très haute concurrence (100+ users)
- Legacy BI tools (SSMS only)
- Strict ACID sur toutes opérations

## Comparaison Technique Détaillée

### Performance

**Warehouse :**
```sql
-- Query simple optimisée
SELECT
    customer_id,
    SUM(amount) as total
FROM fact_sales
WHERE sale_date >= '2024-01-01'
GROUP BY customer_id;

-- Performance: ~1-2 secondes (10M rows)
-- Columnstore index + MPP = rapide
```

**Lakehouse :**
```python
# Même query en Spark
df = spark.table("fact_sales") \
    .where("sale_date >= '2024-01-01'") \
    .groupBy("customer_id") \
    .sum("amount")

# Performance: ~3-5 secondes (10M rows)
# Spark overhead, mais plus flexible
```

**Verdict :** Warehouse légèrement plus rapide pour SQL pur.

### Flexibilité

**Warehouse :**
```sql
-- ❌ Ne peut pas traiter JSON directement
SELECT * FROM json_file;  -- Erreur

-- Besoin d'importer d'abord
COPY INTO temp_table
FROM 'Files/data.json'
WITH (FILE_TYPE = 'JSON');
```

**Lakehouse :**
```python
# ✅ Lit JSON directement
df = spark.read.json("Files/data.json")
df.select("nested.field").show()
```

**Verdict :** Lakehouse beaucoup plus flexible.

### Scalabilité

**Warehouse :**
- Scale jusqu'à plusieurs TB
- MPP distribué
- Limité par capacité Fabric

**Lakehouse :**
- Scale jusqu'à plusieurs PB
- Spark distribué
- Fichiers OneLake illimités

**Verdict :** Les deux scalent bien, Lakehouse léger avantage pour très gros volumes.

### Coût

**Warehouse :**
- CU consumption élevé pour queries
- Optimisé pour queries rapides
- Storage OneLake séparé

**Lakehouse :**
- CU consumption pour Spark jobs
- Peut être plus économique pour ETL batch
- Storage OneLake inclus

**Verdict :** Dépend du workload. Warehouse = queries fréquentes. Lakehouse = batch processing.

## Patterns d'Utilisation Combinés

### Pattern 1 : Lakehouse → Warehouse

```
Lakehouse (Data Engineering)
  ↓ Transformations Bronze→Silver→Gold
Silver/Gold Tables
  ↓ Shortcuts
Warehouse (Analytics)
  ↓ T-SQL queries
Power BI Reports
```

**Implémentation :**
```python
# Dans Lakehouse: ETL
gold_df = transform_data(bronze_df)
gold_df.write.format("delta").saveAsTable("gold_sales")
```

```sql
-- Dans Warehouse: Créer shortcut
CREATE SHORTCUT gold_sales_shortcut
IN dbo
TARGET 'Lakehouse/Tables/gold_sales';

-- Query via warehouse
SELECT * FROM gold_sales_shortcut
WHERE region = 'EMEA';
```

### Pattern 2 : Warehouse ← Lakehouse via SQL Endpoint

```
Lakehouse Tables
  ↓ SQL Analytics Endpoint (automatic)
T-SQL Queries
  ↓
BI Tools (Power BI, Excel, etc.)
```

**Utilisation :**
```sql
-- SQL Endpoint automatique pour chaque Lakehouse
Server: {workspace}.datawarehouse.fabric.microsoft.com
Database: {lakehouse_name}

-- Query Lakehouse tables avec T-SQL
SELECT * FROM gold_customer_metrics;
```

### Pattern 3 : Hybride (Recommandé)

```
┌─────────────────────────────────────────┐
│           Data Sources                   │
└────────────────┬────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│     Lakehouse (Bronze + Silver)         │
│  • Raw data ingestion                   │
│  • ETL transformations                  │
│  • Data quality checks                  │
└────────────────┬───────────────────────┘
                 ↓
        ┌────────┴─────────┐
        ↓                  ↓
┌───────────────┐  ┌──────────────────┐
│   Lakehouse   │  │   Warehouse      │
│   (Gold ML)   │  │   (Gold BI)      │
├───────────────┤  ├──────────────────┤
│ • ML features │  │ • Star schema    │
│ • Notebooks   │  │ • Aggregations   │
│ • Experiments │  │ • BI optimized   │
└───────┬───────┘  └────────┬─────────┘
        ↓                   ↓
   ┌─────────┐      ┌──────────────┐
   │   ML    │      │   Power BI   │
   │ Models  │      │   Reports    │
   └─────────┘      └──────────────┘
```

## Migration Scenarios

### Lakehouse → Warehouse

**Scénario :** Gold tables prêtes, besoin de haute concurrence BI

```python
# 1. Données dans Lakehouse
gold_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("lakehouse_gold_sales")
```

```sql
-- 2. Créer shortcut dans Warehouse
CREATE SHORTCUT warehouse_sales
TARGET 'Lakehouse/Tables/lakehouse_gold_sales';

-- 3. Optionnel: Créer vue avec business logic
CREATE VIEW vw_sales_summary AS
SELECT
    region,
    product_category,
    SUM(amount) as total_sales
FROM warehouse_sales
GROUP BY region, product_category;

-- 4. Optimiser
CREATE STATISTICS stat_region ON warehouse_sales(region);
```

### Warehouse → Lakehouse

**Scénario :** Besoin de ML sur données Warehouse

```sql
-- 1. Export depuis Warehouse
COPY (
    SELECT * FROM customer_features
) TO 'Files/exports/customer_features.parquet'
WITH (FILE_FORMAT = 'PARQUET');
```

```python
# 2. Lire dans Lakehouse notebook
df = spark.read.parquet("Files/exports/customer_features.parquet")

# 3. ML processing
from pyspark.ml.feature import VectorAssembler
assembler = VectorAssembler(inputCols=features, outputCol="features")
features_df = assembler.transform(df)
```

## Decision Tree

```
┌─────────────────────────────────────────┐
│   Besoin d'unstructured/semi-struct?    │
└───────────┬─────────────────────────────┘
            │
    YES ────┴──→ LAKEHOUSE
            │
            NO
            ↓
┌─────────────────────────────────────────┐
│      Besoin de ML / Data Science?       │
└───────────┬─────────────────────────────┘
            │
    YES ────┴──→ LAKEHOUSE
            │
            NO
            ↓
┌─────────────────────────────────────────┐
│  Primary users = Data Engineers avec    │
│         Python/Spark skills?            │
└───────────┬─────────────────────────────┘
            │
    YES ────┴──→ LAKEHOUSE
            │
            NO
            ↓
┌─────────────────────────────────────────┐
│   Haute concurrence BI (50+ users)?     │
└───────────┬─────────────────────────────┘
            │
    YES ────┴──→ DATA WAREHOUSE
            │
            NO
            ↓
┌─────────────────────────────────────────┐
│    Existing SQL/T-SQL investments?      │
└───────────┬─────────────────────────────┘
            │
    YES ────┴──→ DATA WAREHOUSE
            │
            NO
            ↓
    LAKEHOUSE (default pour nouveaux projets)
```

## Exemples Concrets

### Exemple 1 : Retail Analytics

**Besoin :**
- Données transactionnelles (structured)
- 100 business analysts avec SQL
- Power BI dashboards
- Row-level security par région

**Solution :** **Data Warehouse**

```sql
-- Star schema optimisé
CREATE TABLE fact_sales (...) WITH (DISTRIBUTION = HASH(customer_id));
CREATE TABLE dim_customer (...) WITH (DISTRIBUTION = REPLICATE);

-- RLS par région
CREATE SECURITY POLICY regional_policy
ADD FILTER PREDICATE dbo.fn_region_filter(region)
ON dbo.fact_sales;
```

### Exemple 2 : IoT Data Platform

**Besoin :**
- Millions d'events JSON par heure
- Streaming ingestion
- ML pour anomaly detection
- Batch aggregations

**Solution :** **Lakehouse**

```python
# Ingest JSON streams
streaming_df = spark.readStream \
    .format("json") \
    .schema(iot_schema) \
    .load("Files/iot_events/")

# Transform et ML
anomalies_df = detect_anomalies(streaming_df)

# Write to Delta
anomalies_df.writeStream \
    .format("delta") \
    .outputMode("append") \
    .table("iot_anomalies")
```

### Exemple 3 : Financial Services

**Besoin :**
- Données structurées transactionnelles
- Compliance & audit trails
- Complex SQL queries
- + ML pour fraud detection

**Solution :** **Hybride (Les deux)**

```
Warehouse:
- Transaction tables (ACID strict)
- Reporting & compliance
- Auditors access

Lakehouse:
- ML feature engineering
- Fraud detection models
- Data science notebooks

Connection: Shortcuts entre les deux
```

## Best Practices

### ✅ Warehouse Best Practices

```sql
-- 1. Distributions optimales
CREATE TABLE fact_sales (...) WITH (DISTRIBUTION = HASH(customer_id));

-- 2. Replicate small dimensions
CREATE TABLE dim_product (...) WITH (DISTRIBUTION = REPLICATE);

-- 3. Partitioning par date
CREATE TABLE sales (...) WITH (
    PARTITION (sale_date RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01'))
);

-- 4. Statistiques à jour
UPDATE STATISTICS fact_sales;

-- 5. RLS pour sécurité
CREATE SECURITY POLICY ...;
```

### ✅ Lakehouse Best Practices

```python
# 1. Medallion architecture
bronze → silver → gold

# 2. Delta format partout
.write.format("delta").saveAsTable(...)

# 3. Partitioning stratégique
.partitionBy("year", "month")

# 4. OPTIMIZE régulier
spark.sql("OPTIMIZE my_table ZORDER BY (customer_id)")

# 5. VACUUM pour cleanup
spark.sql("VACUUM my_table RETAIN 168 HOURS")
```

## Points Clés

- **Warehouse** = SQL-first, BI, haute concurrence, structured
- **Lakehouse** = Spark-first, ML, ETL, multi-format
- Patterns hybrides souvent optimaux
- SQL Endpoint permet queries T-SQL sur Lakehouse
- Shortcuts permettent partage données
- Choisir selon équipe skills + use case
- Warehouse ≈ OLAP traditionnel
- Lakehouse ≈ Modern data platform

---

**Prochain fichier :** [05 - SQL Analytics Endpoints](./05-sql-endpoints.md)

[⬅️ Fichier précédent](./03-tsql-queries.md) | [⬅️ Retour au README du module](./README.md)
