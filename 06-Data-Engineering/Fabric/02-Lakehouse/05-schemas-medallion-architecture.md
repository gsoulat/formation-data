# Architecture Medallion

## Concept

L'**architecture Medallion** est un pattern de design pour organiser les données dans un Lakehouse en **trois couches** : Bronze, Silver et Gold.

```
┌──────────────────────────────────────────────────────┐
│                   GOLD Layer                          │
│            (Business & Analytics Ready)               │
│                                                       │
│  • Agregated data                                    │
│  • Business metrics                                  │
│  • Highly curated                                    │
│  • Optimized for consumption                         │
└───────────────────────┬──────────────────────────────┘
                        ↑
┌───────────────────────┴──────────────────────────────┐
│                  SILVER Layer                         │
│              (Cleaned & Conformed)                    │
│                                                       │
│  • Validated data                                    │
│  • Deduplicated                                      │
│  • Standardized                                      │
│  • Quality checked                                   │
└───────────────────────┬──────────────────────────────┘
                        ↑
┌───────────────────────┴──────────────────────────────┐
│                  BRONZE Layer                         │
│                  (Raw Data)                           │
│                                                       │
│  • Data as-is from source                            │
│  • Minimal transformation                            │
│  • Historical archive                                │
│  • Immutable                                         │
└──────────────────────────────────────────────────────┘
                        ↑
                   Data Sources
```

## Les Trois Couches

### Bronze Layer (Raw)

**Objectif :** Ingestion brute, archivage historique

**Caractéristiques :**
- Données brutes "as-is"
- Format original ou Parquet/Delta
- Aucune transformation
- Immutable (append-only généralement)
- Archive historique complète

**Structure :**
```
Bronze Lakehouse
├── Files/
│   ├── source1/
│   │   └── YYYY/MM/DD/
│   │       ├── file1.csv
│   │       └── file2.csv
│   └── source2/
└── Tables/
    ├── bronze_source1_table1
    └── bronze_source2_table2
```

**Exemple :**
```python
# Ingestion brute
raw_df = spark.read.csv("external_source/sales.csv")

# Écriture en Bronze (minimal transformation)
raw_df.withColumn("ingestion_timestamp", current_timestamp()) \
    .write.format("delta") \
    .mode("append") \
    .saveAsTable("bronze_sales")
```

### Silver Layer (Cleaned)

**Objectif :** Données nettoyées, validées, standardisées

**Caractéristiques :**
- Deduplicated
- Validated (data quality checks)
- Standardized (formats, naming)
- Enriched (lookups, calculated columns)
- Schema enforced
- Type conversions

**Structure :**
```
Silver Lakehouse
└── Tables/
    ├── silver_customers (deduplicated, validated)
    ├── silver_orders (enriched with customer info)
    └── silver_products (standardized categories)
```

**Transformations typiques :**
```python
from pyspark.sql.functions import *

# Bronze → Silver
silver_df = bronze_df \
    .dropDuplicates(["order_id"]) \
    .filter(col("amount") > 0) \
    .withColumn("order_date", to_date(col("order_date_str"), "yyyy-MM-dd")) \
    .withColumn("country_code", upper(trim(col("country")))) \
    .join(lookup_df, "product_id", "left")

silver_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("silver_orders")
```

### Gold Layer (Business)

**Objectif :** Données agrégées, prêtes pour analytics

**Caractéristiques :**
- Business-level aggregations
- Denormalized pour performance
- Optimized pour reporting
- Business logic appliquée
- Métriques calculées
- Souvent en star schema

**Structure :**
```
Gold Lakehouse
└── Tables/
    ├── gold_sales_by_region_daily
    ├── gold_customer_360
    ├── gold_product_performance
    └── gold_monthly_revenue
```

**Exemple :**
```python
# Silver → Gold (aggregation)
gold_df = silver_orders \
    .groupBy("region", "date") \
    .agg(
        sum("amount").alias("total_sales"),
        count("order_id").alias("order_count"),
        avg("amount").alias("avg_order_value")
    )

gold_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("gold_sales_by_region_daily")
```

## Implémentation dans Fabric

### Option 1 : Trois Lakehouses Séparés

```
Workspace
├── Lakehouse_Bronze
├── Lakehouse_Silver
└── Lakehouse_Gold
```

**Avantages :**
- Séparation claire
- Sécurité granulaire (RLS différente par layer)
- Scaling indépendant

**Inconvénients :**
- Gestion de 3 lakehouses
- Permissions multiples

### Option 2 : Un Lakehouse avec Organisation par Table

```
Lakehouse_Unified
└── Tables/
    ├── bronze_*
    ├── silver_*
    └── gold_*
```

**Avantages :**
- Simple à gérer
- Un seul endroit

**Inconvénients :**
- Sécurité moins granulaire
- Peut devenir désordonné

### Option 3 (Recommandé) : Hybride

```
Lakehouse_Data
├── Files/
│   ├── bronze/ (raw files)
│   ├── silver/ (processed files)
│   └── gold/ (exports)
└── Tables/
    ├── bronze_*
    ├── silver_*
    └── gold_*
```

## Data Flow Pipeline

### Pipeline Bronze

```python
# Pipeline 1: Ingestion vers Bronze
def ingest_to_bronze():
    # Source → Bronze
    df = read_from_source()
    df.withColumn("_ingested_at", current_timestamp()) \
      .write.format("delta") \
      .mode("append") \
      .saveAsTable("bronze_raw_data")
```

### Pipeline Silver

```python
# Pipeline 2: Bronze → Silver
def bronze_to_silver():
    bronze_df = spark.table("bronze_raw_data")

    silver_df = bronze_df \
        .dropDuplicates() \
        .filter(col("amount").isNotNull()) \
        .withColumn("amount", col("amount").cast("double")) \
        .filter(col("amount") > 0)

    silver_df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable("silver_cleaned_data")
```

### Pipeline Gold

```python
# Pipeline 3: Silver → Gold
def silver_to_gold():
    silver_df = spark.table("silver_cleaned_data")

    gold_df = silver_df \
        .groupBy("category", "date") \
        .agg(
            sum("amount").alias("total_sales"),
            count("*").alias("transactions")
        )

    gold_df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable("gold_sales_summary")
```

## Data Quality

### Bronze Layer

```python
# Minimal checks
bronze_df.write \
    .option("badRecordsPath", "Files/quarantine/bronze/") \
    .format("delta") \
    .save("Tables/bronze_data")
```

### Silver Layer

```python
from pyspark.sql.functions import *

# Data Quality checks
silver_df = bronze_df.filter(
    (col("id").isNotNull()) &
    (col("amount") > 0) &
    (col("date") >= "2020-01-01") &
    (col("email").rlike(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"))
)

# Log rejected rows
rejected_df = bronze_df.exceptAll(silver_df)
rejected_df.write.mode("append").saveAsTable("data_quality_rejects")
```

### Gold Layer

```python
# Business validations
assert gold_df.filter(col("total_sales") < 0).count() == 0, "Negative sales detected"
assert gold_df.groupBy("date").count().filter(col("count") > 1).count() == 0, "Duplicates"
```

## Optimisations par Layer

### Bronze
- Format Delta pour ACID
- Partitionné par date d'ingestion
- Compression ZSTD (high compression)

```python
bronze_df.write \
    .format("delta") \
    .partitionBy("ingestion_date") \
    .option("compression", "zstd") \
    .save("Tables/bronze_data")
```

### Silver
- Partitionné par business key
- Z-Ordering sur colonnes fréquemment filtrées
- V-Order activated

```python
silver_df.write \
    .format("delta") \
    .partitionBy("country", "year") \
    .save("Tables/silver_data")

spark.sql("OPTIMIZE silver_data ZORDER BY (customer_id)")
```

### Gold
- Denormalized pour performance
- Statistics collectées
- Caching pour queries fréquentes

```python
spark.sql("OPTIMIZE gold_sales")
spark.sql("ANALYZE TABLE gold_sales COMPUTE STATISTICS")
```

## Gouvernance

### Data Lineage

```
Source System
    ↓ [Pipeline: ingest_bronze]
Bronze Layer
    ↓ [Notebook: clean_data]
Silver Layer
    ↓ [Pipeline: aggregate_gold]
Gold Layer
    ↓ [Power BI Direct Lake]
Reports
```

**Documentation :**
```python
# Metadata table
lineage = [
    {"source": "ERP_Sales", "target": "bronze_sales", "pipeline": "ingest_daily"},
    {"source": "bronze_sales", "target": "silver_sales", "notebook": "transform_sales"},
    {"source": "silver_sales", "target": "gold_revenue", "pipeline": "aggregate_revenue"}
]
```

### Retention Policies

**Bronze :** Long terme (années)
```python
# Pas de VACUUM fréquent
spark.sql("VACUUM bronze_sales RETAIN 8760 HOURS")  # 1 an
```

**Silver :** Moyen terme (mois)
```python
spark.sql("VACUUM silver_sales RETAIN 2160 HOURS")  # 90 jours
```

**Gold :** Court terme (semaines)
```python
spark.sql("VACUUM gold_sales RETAIN 168 HOURS")  # 7 jours
```

## Best Practices

✅ **DO:**
- Bronze = immutable, append-only
- Documenter transformations Silver
- Gold optimisé pour use case spécifique
- Automated testing à chaque layer
- Monitoring data quality

❌ **DON'T:**
- Transformation lourde en Bronze
- Skip Silver (Bronze direct to Gold)
- Trop de layers (keep it simple)
- Dupliquer données entre layers

## Exemple Complet

```python
# Bronze
raw_df = spark.read.csv("source/sales.csv")
raw_df.write.format("delta").mode("append").saveAsTable("bronze_sales")

# Silver
bronze_df = spark.table("bronze_sales")
silver_df = bronze_df \
    .dropDuplicates(["order_id"]) \
    .filter(col("amount") > 0) \
    .withColumn("order_date", to_date(col("order_date")))

silver_df.write.format("delta").mode("overwrite").saveAsTable("silver_sales")

# Gold
silver_df = spark.table("silver_sales")
gold_df = silver_df.groupBy("product_category", "region") \
    .agg(sum("amount").alias("total_revenue"))

gold_df.write.format("delta").mode("overwrite").saveAsTable("gold_revenue_by_category")
```

## Points Clés

- Medallion = Bronze (raw) → Silver (clean) → Gold (business)
- Bronze : immutable, archive complète
- Silver : validated, deduplicated
- Gold : aggregated, optimized
- Séparation claire des responsabilités
- Data quality checks à chaque layer
- Optimisations spécifiques par layer

---

**Prochain fichier :** [06 - Partitionnement et Optimisation](./06-partitioning-optimization.md)

[⬅️ Fichier précédent](./04-shortcuts.md) | [⬅️ Retour au README du module](./README.md)
