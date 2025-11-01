# ETL Pipelines - Extract, Transform, Load

## Table des matières

1. [Introduction aux pipelines ETL](#introduction-aux-pipelines-etl)
2. [Lecture de données (Extract)](#lecture-de-données-extract)
3. [Transformation de données (Transform)](#transformation-de-données-transform)
4. [Écriture de données (Load)](#écriture-de-données-load)
5. [Formats de fichiers](#formats-de-fichiers)
6. [Gestion des schemas](#gestion-des-schemas)
7. [Pipeline ETL complet](#pipeline-etl-complet)
8. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction aux pipelines ETL

### Qu'est-ce qu'un pipeline ETL ?

**ETL** signifie **Extract, Transform, Load** :
- **Extract** : Lire les données depuis différentes sources
- **Transform** : Nettoyer, enrichir, agréger les données
- **Load** : Écrire les données vers une destination

### Architecture ETL avec Spark

```
Sources (Extract)
  ├─ Fichiers (CSV, JSON, Parquet, Avro)
  ├─ Bases de données (JDBC)
  ├─ APIs
  └─ Streaming (Kafka, Kinesis)
        ↓
Transformations (Transform)
  ├─ Nettoyage (nulls, doublons)
  ├─ Validation
  ├─ Enrichissement (joins)
  ├─ Agrégations
  └─ Formatage
        ↓
Destinations (Load)
  ├─ Data Lake (Parquet, Delta)
  ├─ Data Warehouse (Snowflake, Redshift)
  ├─ Bases de données
  └─ APIs
```

### Cas d'usage

- **Data Lake ingestion** : Raw → Cleaned → Enriched
- **Data Warehouse loading** : OLTP → OLAP
- **Data migration** : System A → System B
- **Reporting pipelines** : Données → Rapports
- **ML pipelines** : Raw data → Features

---

## Lecture de données (Extract)

### 1. Lire des fichiers CSV

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("ETL").getOrCreate()

# Basic
df = spark.read.csv("data.csv")

# Avec options
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("delimiter", ",") \
    .option("quote", "\"") \
    .option("escape", "\\") \
    .option("nullValue", "NULL") \
    .option("dateFormat", "yyyy-MM-dd") \
    .csv("data.csv")

# Avec schema explicite (recommandé)
from pyspark.sql.types import *

schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("created_at", TimestampType(), True)
])

df = spark.read.csv("data.csv", schema=schema, header=True)
```

### 2. Lire des fichiers JSON

```python
# JSON simple
df = spark.read.json("data.json")

# JSON multiline
df = spark.read \
    .option("multiLine", "true") \
    .json("data.json")

# JSON avec schema
df = spark.read.json("data.json", schema=schema)
```

### 3. Lire des fichiers Parquet

```python
# Parquet (format recommandé)
df = spark.read.parquet("data.parquet")

# Lire plusieurs fichiers
df = spark.read.parquet("data/*.parquet")

# Avec partitions
df = spark.read.parquet("data/year=2024/month=01/")
```

### 4. Lire depuis une base de données (JDBC)

```python
# PostgreSQL
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("dbtable", "users") \
    .option("user", "postgres") \
    .option("password", "password") \
    .option("driver", "org.postgresql.Driver") \
    .load()

# Avec requête custom
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("query", "SELECT * FROM users WHERE age > 25") \
    .option("user", "postgres") \
    .option("password", "password") \
    .load()

# Avec partitionnement (pour grandes tables)
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("dbtable", "large_table") \
    .option("user", "postgres") \
    .option("password", "password") \
    .option("partitionColumn", "id") \
    .option("lowerBound", "1") \
    .option("upperBound", "1000000") \
    .option("numPartitions", "10") \
    .load()
```

### 5. Lire depuis le cloud

```python
# AWS S3
df = spark.read.parquet("s3a://bucket/path/data.parquet")

# Azure Blob Storage
df = spark.read.parquet("wasbs://container@account.blob.core.windows.net/path/")

# Google Cloud Storage
df = spark.read.parquet("gs://bucket/path/data.parquet")
```

### 6. Lire plusieurs fichiers

```python
# Pattern matching
df = spark.read.csv("data/*.csv")
df = spark.read.json("logs/2024/*/events.json")

# Liste de fichiers
files = ["file1.csv", "file2.csv", "file3.csv"]
df = spark.read.csv(files)

# Avec schema et options
df = spark.read \
    .option("header", "true") \
    .schema(schema) \
    .csv("data/2024/*/*.csv")
```

---

## Transformation de données (Transform)

### 1. Nettoyage des données

```python
from pyspark.sql.functions import col, trim, lower, upper, regexp_replace

# Supprimer les nulls
df_clean = df.dropna(subset=["important_column"])

# Remplir les nulls
df_filled = df.fillna({
    "age": 0,
    "name": "Unknown",
    "city": "N/A"
})

# Supprimer les doublons
df_unique = df.dropDuplicates()
df_unique_by_col = df.dropDuplicates(["id", "email"])

# Nettoyer les strings
df_clean = df \
    .withColumn("name", trim(col("name"))) \
    .withColumn("email", lower(col("email"))) \
    .withColumn("phone", regexp_replace(col("phone"), r"[^0-9]", ""))
```

### 2. Validation des données

```python
from pyspark.sql.functions import when, col

# Valider et marquer les erreurs
df_validated = df \
    .withColumn("is_valid_age",
        when((col("age") >= 0) & (col("age") <= 120), True).otherwise(False)
    ) \
    .withColumn("is_valid_email",
        col("email").rlike(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
    )

# Filtrer les données invalides
df_valid = df_validated.filter(
    (col("is_valid_age") == True) &
    (col("is_valid_email") == True)
)

# Séparer valides et invalides
df_valid = df.filter(col("age").between(0, 120))
df_invalid = df.filter(~col("age").between(0, 120))
```

### 3. Enrichissement (Joins)

```python
# Enrichir avec des données de référence
users = spark.read.csv("users.csv", header=True)
countries = spark.read.csv("countries.csv", header=True)

# Join pour enrichir
enriched = users.join(countries, users.country_code == countries.code, "left") \
    .select(
        users["*"],
        countries["country_name"],
        countries["region"]
    )
```

### 4. Agrégations

```python
from pyspark.sql.functions import sum, avg, count, max, min

# Agréger par groupe
summary = df.groupBy("category").agg(
    count("*").alias("num_records"),
    sum("amount").alias("total_amount"),
    avg("amount").alias("avg_amount"),
    max("amount").alias("max_amount"),
    min("amount").alias("min_amount")
)
```

### 5. Transformation de schema

```python
# Renommer des colonnes
df_renamed = df \
    .withColumnRenamed("old_name", "new_name") \
    .withColumnRenamed("qty", "quantity")

# Changer les types
df_typed = df \
    .withColumn("age", col("age").cast("integer")) \
    .withColumn("salary", col("salary").cast("double")) \
    .withColumn("created_at", col("created_at").cast("timestamp"))

# Ajouter des colonnes calculées
from pyspark.sql.functions import current_timestamp, lit

df_enriched = df \
    .withColumn("processed_at", current_timestamp()) \
    .withColumn("source", lit("csv_import")) \
    .withColumn("total_price", col("price") * col("quantity"))
```

### 6. Pivoting et Unpivoting

```python
# Pivot (lignes → colonnes)
pivoted = df.groupBy("date").pivot("category").sum("amount")

# Unpivot (colonnes → lignes)
from pyspark.sql.functions import expr, col

unpivoted = df.selectExpr(
    "id",
    "stack(3, 'col1', col1, 'col2', col2, 'col3', col3) as (column_name, value)"
)
```

---

## Écriture de données (Load)

### 1. Écrire en CSV

```python
# Basic
df.write.csv("output/data.csv")

# Avec options
df.write \
    .mode("overwrite") \
    .option("header", "true") \
    .option("delimiter", ",") \
    .option("quote", "\"") \
    .option("escape", "\\") \
    .csv("output/data.csv")
```

### 2. Écrire en JSON

```python
# JSON
df.write.json("output/data.json")

# JSON avec une seule ligne par fichier
df.write.mode("overwrite").json("output/data.json")
```

### 3. Écrire en Parquet (recommandé)

```python
# Parquet
df.write.parquet("output/data.parquet")

# Avec compression
df.write \
    .mode("overwrite") \
    .option("compression", "snappy") \
    .parquet("output/data.parquet")

# Autres compressions: gzip, lzo, none
```

### 4. Écrire en partitions

```python
# Partitionner par colonnes
df.write \
    .partitionBy("year", "month") \
    .parquet("output/data")

# Crée: output/data/year=2024/month=01/part-*.parquet
#       output/data/year=2024/month=02/part-*.parquet

# Bucket (répartir en N fichiers)
df.write \
    .bucketBy(10, "user_id") \
    .sortBy("timestamp") \
    .saveAsTable("users_bucketed")
```

### 5. Modes d'écriture

```python
# overwrite - Écrase les données existantes
df.write.mode("overwrite").parquet("output/")

# append - Ajoute aux données existantes
df.write.mode("append").parquet("output/")

# ignore - Ne fait rien si existe déjà
df.write.mode("ignore").parquet("output/")

# error (défaut) - Erreur si existe déjà
df.write.mode("error").parquet("output/")
```

### 6. Écrire dans une base de données

```python
# PostgreSQL
df.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("dbtable", "users") \
    .option("user", "postgres") \
    .option("password", "password") \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

# Avec batching
df.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("dbtable", "users") \
    .option("user", "postgres") \
    .option("password", "password") \
    .option("batchsize", "10000") \
    .mode("append") \
    .save()
```

### 7. Écrire vers le cloud

```python
# S3
df.write.parquet("s3a://bucket/output/data.parquet")

# Azure
df.write.parquet("wasbs://container@account.blob.core.windows.net/output/")

# GCS
df.write.parquet("gs://bucket/output/data.parquet")
```

---

## Formats de fichiers

### Comparaison des formats

| Format | Type | Compression | Schema | Cas d'usage |
|--------|------|-------------|--------|-------------|
| **CSV** | Row-based | ❌ | ❌ | Import/export simple, petits fichiers |
| **JSON** | Row-based | ❌ | ❌ | APIs, données semi-structurées |
| **Parquet** | Columnar | ✅ | ✅ | Analytics, Data Lake (recommandé) |
| **Avro** | Row-based | ✅ | ✅ | Streaming, évolution schema |
| **ORC** | Columnar | ✅ | ✅ | Hive, Data Warehouse |

### Quand utiliser quel format ?

**CSV** :
- ✅ Échange de données simples
- ✅ Compatibilité universelle
- ❌ Pas de schema, lent, gros fichiers

**JSON** :
- ✅ Données hiérarchiques
- ✅ APIs
- ❌ Verbeux, lent

**Parquet** (recommandé) :
- ✅ Analytics (lecture de colonnes)
- ✅ Compression efficace
- ✅ Schema évolutif
- ✅ Prédicat pushdown

**Avro** :
- ✅ Streaming
- ✅ Schema evolution
- ✅ Write-heavy workloads

---

## Gestion des schemas

### 1. Inférer le schema

```python
# Spark infère le schema (scan complet)
df = spark.read \
    .option("inferSchema", "true") \
    .csv("data.csv")

# ⚠️ Lent sur gros fichiers
```

### 2. Définir le schema explicitement (recommandé)

```python
from pyspark.sql.types import *

schema = StructType([
    StructField("id", IntegerType(), False),  # NOT NULL
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("email", StringType(), True),
    StructField("salary", DoubleType(), True),
    StructField("created_at", TimestampType(), True)
])

df = spark.read.csv("data.csv", schema=schema, header=True)
```

### 3. Schema avec types complexes

```python
schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("name", StringType(), True),
    StructField("address", StructType([
        StructField("street", StringType(), True),
        StructField("city", StringType(), True),
        StructField("zip", StringType(), True)
    ]), True),
    StructField("tags", ArrayType(StringType()), True),
    StructField("metadata", MapType(StringType(), StringType()), True)
])
```

### 4. Schema evolution

```python
# Lire avec schema merge (Parquet)
df = spark.read \
    .option("mergeSchema", "true") \
    .parquet("data/")

# Ajouter des colonnes manquantes
for col_name in ["new_col1", "new_col2"]:
    if col_name not in df.columns:
        df = df.withColumn(col_name, lit(None))
```

---

## Pipeline ETL complet

### Exemple : Pipeline e-commerce

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# ========== CONFIGURATION ==========
spark = SparkSession.builder \
    .appName("ETL E-commerce") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

# ========== EXTRACT ==========
print("1. Extract - Lecture des données sources")

# Schema pour orders
orders_schema = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("customer_id", IntegerType(), True),
    StructField("product_id", IntegerType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("price", DoubleType(), True),
    StructField("order_date", StringType(), True)
])

# Lire orders (CSV)
orders = spark.read.csv("data/orders.csv", schema=orders_schema, header=True)

# Lire customers (JSON)
customers = spark.read.json("data/customers.json")

# Lire products (Parquet)
products = spark.read.parquet("data/products.parquet")

# ========== TRANSFORM ==========
print("2. Transform - Nettoyage et enrichissement")

# Nettoyer orders
orders_clean = orders \
    .dropna(subset=["order_id", "customer_id", "product_id"]) \
    .filter((col("quantity") > 0) & (col("price") > 0)) \
    .withColumn("order_date", to_date(col("order_date"))) \
    .withColumn("total_amount", col("quantity") * col("price"))

# Enrichir avec customers
orders_enriched = orders_clean.join(
    customers,
    "customer_id",
    "left"
).select(
    orders_clean["*"],
    customers["customer_name"],
    customers["customer_email"],
    customers["customer_city"]
)

# Enrichir avec products
orders_final = orders_enriched.join(
    products,
    "product_id",
    "left"
).select(
    orders_enriched["*"],
    products["product_name"],
    products["category"]
)

# Ajouter des métadonnées
orders_final = orders_final \
    .withColumn("processed_at", current_timestamp()) \
    .withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date")))

# Créer des agrégations
daily_sales = orders_final.groupBy("order_date", "category").agg(
    count("*").alias("num_orders"),
    sum("total_amount").alias("total_revenue"),
    avg("total_amount").alias("avg_order_value")
)

# ========== LOAD ==========
print("3. Load - Écriture des résultats")

# Sauvegarder orders enrichis (partitionné)
orders_final.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet("output/orders_enriched")

# Sauvegarder agrégations
daily_sales.write \
    .mode("overwrite") \
    .parquet("output/daily_sales")

# Sauvegarder dans une DB (pour BI)
daily_sales.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/analytics") \
    .option("dbtable", "daily_sales") \
    .option("user", "postgres") \
    .option("password", "password") \
    .mode("overwrite") \
    .save()

print("✅ ETL Pipeline terminé")
```

---

## Bonnes pratiques

### 1. Définir le schema explicitement

```python
# ❌ Éviter
df = spark.read.csv("large_file.csv", inferSchema=True)

# ✅ Préférer
df = spark.read.csv("large_file.csv", schema=schema)
```

### 2. Utiliser Parquet pour le stockage

```python
# ✅ Format optimal pour analytics
df.write.parquet("output/data.parquet")

# ❌ Éviter CSV pour gros volumes
df.write.csv("output/data.csv")
```

### 3. Partitionner intelligemment

```python
# ✅ Partitionner par colonnes fréquemment filtrées
df.write.partitionBy("year", "month", "day").parquet("output/")

# ❌ Éviter trop de partitions (< 128 MB par partition)
```

### 4. Utiliser le cache pour réutilisations

```python
# Si le DataFrame est réutilisé
df_clean = df.filter(...).select(...)
df_clean.cache()

# Multiples opérations
stats1 = df_clean.groupBy(...).count()
stats2 = df_clean.filter(...).agg(...)
```

### 5. Gérer les erreurs

```python
try:
    df = spark.read.csv("data.csv", schema=schema)
except Exception as e:
    print(f"Erreur lecture: {e}")
    # Fallback ou logging
```

### 6. Validation des données

```python
# Valider avant d'écrire
assert df.count() > 0, "DataFrame vide"
assert "id" in df.columns, "Colonne 'id' manquante"

# Vérifier la qualité
null_counts = df.select([count(when(col(c).isNull(), c)).alias(c) for c in df.columns])
null_counts.show()
```

---

## Résumé

### Formats recommandés

| Usage | Format |
|-------|--------|
| **Analytics, Data Lake** | Parquet |
| **Streaming** | Avro |
| **Échange simple** | CSV, JSON |
| **Data Warehouse** | Parquet, ORC |

### Modes d'écriture

- `overwrite` : Écraser
- `append` : Ajouter
- `ignore` : Ignorer si existe
- `error` : Erreur si existe (défaut)

### Pipeline type

1. **Extract** : Lire depuis sources (CSV, JSON, DB, etc.)
2. **Transform** : Nettoyer, valider, enrichir, agréger
3. **Load** : Écrire vers destinations (Parquet, DB, etc.)

---

## Prochaines étapes

Module suivant : **[07-Performance-Optimization](../07-Performance-Optimization/README.md)**

Vous allez apprendre à :
- Optimiser les performances
- Partitionnement et bucketing
- Caching et persistence
- Éviter les shuffles coûteux
