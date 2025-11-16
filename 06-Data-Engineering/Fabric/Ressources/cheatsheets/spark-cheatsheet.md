# PySpark Cheatsheet

## Initialisation

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Dans Fabric, SparkSession existe déjà comme 'spark'
# Sinon, créer :
# spark = SparkSession.builder.appName("MyApp").getOrCreate()
```

## Lecture de Données

```python
# CSV
df = spark.read.format("csv") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .load("Files/data.csv")

# Delta Lake
df = spark.read.format("delta").load("Tables/sales")
df = spark.table("sales")  # Si table enregistrée

# Parquet
df = spark.read.parquet("Files/data.parquet")

# JSON
df = spark.read.json("Files/data.json")

# Avec schéma explicite
schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("name", StringType(), True),
    StructField("amount", DoubleType(), True)
])
df = spark.read.schema(schema).csv("Files/data.csv")
```

## Écriture de Données

```python
# Delta Lake (recommandé)
df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("sales_clean")

# Modes: overwrite, append, ignore, error

# Partitionné
df.write.format("delta") \
    .partitionBy("year", "month") \
    .mode("overwrite") \
    .save("Tables/sales_partitioned")

# CSV
df.write.format("csv") \
    .option("header", "true") \
    .mode("overwrite") \
    .save("Files/output.csv")
```

## Exploration

```python
# Afficher données
df.show(10)
df.show(10, truncate=False)

# Schéma
df.printSchema()

# Colonnes
df.columns  # Liste des colonnes

# Count
df.count()

# Describe (statistiques)
df.describe().show()
df.summary().show()

# Premier/dernier row
df.first()
df.head(5)
df.tail(5)  # Attention: coûteux!
```

## Transformations

### Sélection

```python
# select
df.select("name", "amount").show()
df.select(col("name"), col("amount")).show()

# selectExpr
df.selectExpr("name", "amount * 2 as doubled").show()

# Toutes colonnes + nouvelles
df.select("*", (col("amount") * 1.2).alias("with_tax")).show()
```

### Filtrage

```python
# where / filter (équivalent)
df.where(col("amount") > 100).show()
df.filter("amount > 100").show()

# Multiple conditions
df.where((col("amount") > 100) & (col("country") == "France")).show()

# OR
df.where((col("status") == "Active") | (col("amount") > 1000)).show()

# IN
df.where(col("country").isin(["France", "Germany", "Spain"])).show()

# LIKE
df.where(col("name").like("%Inc%")).show()

# IS NULL / IS NOT NULL
df.where(col("email").isNull()).show()
df.where(col("email").isNotNull()).show()
```

### Nouvelles colonnes

```python
# withColumn
df = df.withColumn("amount_usd", col("amount") * 1.1)

# Colonne conditionnelle
df = df.withColumn("status",
    when(col("amount") > 1000, "High")
    .when(col("amount") > 500, "Medium")
    .otherwise("Low")
)

# Renommer
df = df.withColumnRenamed("old_name", "new_name")

# Supprimer colonnes
df = df.drop("column1", "column2")
```

### Agrégations

```python
# groupBy
df.groupBy("country").count().show()

# Multiples agrégations
df.groupBy("country", "category").agg(
    sum("amount").alias("total_sales"),
    avg("amount").alias("avg_order"),
    count("*").alias("order_count"),
    min("amount").alias("min_amount"),
    max("amount").alias("max_amount")
).show()

# Agrégation sans groupBy
df.agg(
    sum("amount").alias("total"),
    avg("amount").alias("average")
).show()
```

### Jointures

```python
# Inner join
result = df1.join(df2, "common_column", "inner")
result = df1.join(df2, df1.id == df2.customer_id, "inner")

# Left join
result = df1.join(df2, "id", "left")

# Types: inner, left, right, outer, semi, anti
result = df1.join(df2, "id", "left_anti")  # Rows in df1 not in df2
```

### Union

```python
# union (équivalent à UNION ALL en SQL)
combined = df1.union(df2)

# unionByName (par nom de colonne)
combined = df1.unionByName(df2)
```

### Tri

```python
# orderBy / sort
df.orderBy("amount").show()
df.orderBy(col("amount").desc()).show()

# Multiple colonnes
df.orderBy(col("country").asc(), col("amount").desc()).show()
```

### Distinct

```python
# Valeurs distinctes
df.select("country").distinct().show()

# dropDuplicates
df.dropDuplicates(["customer_id"]).show()
df.dropDuplicates().show()  # Sur toutes colonnes
```

## Fonctions

### Fonctions de colonnes

```python
# String
df.withColumn("upper", upper(col("name")))
df.withColumn("lower", lower(col("name")))
df.withColumn("trimmed", trim(col("text")))
df.withColumn("len", length(col("name")))
df.withColumn("substr", substring(col("name"), 1, 3))

# Concat
df.withColumn("full_name", concat(col("first_name"), lit(" "), col("last_name")))

# Regex
df.withColumn("extracted", regexp_extract(col("email"), r"@(.+)", 1))
df.withColumn("replaced", regexp_replace(col("text"), r"[0-9]", "X"))
```

### Fonctions numériques

```python
# Math
df.withColumn("rounded", round(col("amount"), 2))
df.withColumn("ceiled", ceil(col("amount")))
df.withColumn("floored", floor(col("amount")))
df.withColumn("abs", abs(col("delta")))

# Conversion
df.withColumn("int_val", col("string_val").cast("int"))
df.withColumn("double_val", col("string_val").cast(DoubleType()))
```

### Fonctions de date

```python
# Date actuelle
df.withColumn("today", current_date())
df.withColumn("now", current_timestamp())

# Extraction
df.withColumn("year", year(col("date")))
df.withColumn("month", month(col("date")))
df.withColumn("day", dayofmonth(col("date")))
df.withColumn("dayofweek", dayofweek(col("date")))

# Date manipulation
df.withColumn("next_week", date_add(col("date"), 7))
df.withColumn("last_month", add_months(col("date"), -1))

# Différence
df.withColumn("days_diff", datediff(col("end_date"), col("start_date")))

// Format
df.withColumn("formatted", date_format(col("date"), "dd/MM/yyyy"))
```

### Fonctions NULL

```python
# coalesce - Première valeur non-null
df.withColumn("value", coalesce(col("col1"), col("col2"), lit(0)))

# isnull / isnotnull
df.where(col("email").isNull())

# fillna
df.fillna(0)  # Remplacer tous les nulls par 0
df.fillna({"amount": 0, "name": "Unknown"})

# dropna
df.dropna()  # Supprimer lignes avec nulls
df.dropna(subset=["email"])  # Seulement si email est null
```

## Window Functions

```python
from pyspark.sql.window import Window

# Définir window
window_spec = Window.partitionBy("country").orderBy(col("amount").desc())

# row_number
df.withColumn("rank", row_number().over(window_spec))

// rank / dense_rank
df.withColumn("rank", rank().over(window_spec))
df.withColumn("dense_rank", dense_rank().over(window_spec))

# lag / lead
df.withColumn("previous", lag("amount", 1).over(window_spec))
df.withColumn("next", lead("amount", 1).over(window_spec))

# Running totals
df.withColumn("running_total", sum("amount").over(
    Window.partitionBy("country").orderBy("date").rowsBetween(Window.unboundedPreceding, Window.currentRow)
))
```

## UDFs (User Defined Functions)

```python
from pyspark.sql.functions import udf

# Définir fonction Python
def categorize(amount):
    if amount > 1000:
        return "High"
    elif amount > 500:
        return "Medium"
    else:
        return "Low"

# Enregistrer comme UDF
categorize_udf = udf(categorize, StringType())

# Utiliser
df.withColumn("category", categorize_udf(col("amount"))).show()

# Alternative avec decorator
@udf(returnType=IntegerType())
def double_value(x):
    return x * 2

df.withColumn("doubled", double_value(col("amount"))).show()
```

## SQL API

```python
# Enregistrer comme view temporaire
df.createOrReplaceTempView("sales")

# Requête SQL
result = spark.sql("""
    SELECT country, SUM(amount) as total_sales
    FROM sales
    WHERE amount > 100
    GROUP BY country
    ORDER BY total_sales DESC
""")

result.show()

# Global temp view (accessible entre sessions)
df.createOrReplaceGlobalTempView("global_sales")
spark.sql("SELECT * FROM global_temp.global_sales").show()
```

## Delta Lake

```python
from delta.tables import DeltaTable

# MERGE (upsert)
delta_table = DeltaTable.forPath(spark, "Tables/sales")

delta_table.alias("target").merge(
    updates_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(set = {
    "amount": "source.amount",
    "updated_at": "current_timestamp()"
}).whenNotMatchedInsert(values = {
    "id": "source.id",
    "amount": "source.amount",
    "created_at": "current_timestamp()"
}).execute()

# Time travel
df_v5 = spark.read.format("delta").option("versionAsOf", 5).load("Tables/sales")
df_date = spark.read.format("delta").option("timestampAsOf", "2024-01-15").load("Tables/sales")

# OPTIMIZE
spark.sql("OPTIMIZE sales")
spark.sql("OPTIMIZE sales ZORDER BY (customer_id)")

# VACUUM
spark.sql("VACUUM sales RETAIN 168 HOURS")

// History
spark.sql("DESCRIBE HISTORY sales").show()
```

## Performance

```python
# Cache
df_cached = df.cache()
df_cached.count()  # Materialize

# Unpersist
df_cached.unpersist()

# Repartition (shuffle)
df_repartitioned = df.repartition(10)
df_repartitioned = df.repartition(10, "country")  # Par colonne

# Coalesce (sans shuffle)
df_coalesced = df.coalesce(1)  # Combiner en 1 partition

// Broadcast join (petite table)
from pyspark.sql.functions import broadcast
result = large_df.join(broadcast(small_df), "key")

# Explain (plan d'exécution)
df.explain()
df.explain(mode="extended")
```

## Best Practices

✅ **DO:**
- Filtrer (`where`) tôt dans la chaîne
- Utiliser `select` pour réduire colonnes
- Cacher (`cache`) DataFrames réutilisés
- Broadcast petites tables dans joins
- Utiliser Delta Lake format

❌ **DON'T:**
- Utiliser `collect()` sur gros DataFrames (OOM!)
- Trop de petites partitions (overhead)
- UDFs Python si fonction built-in existe (performance)
- Lecture/écriture répétée au même path

## Ressources

- [PySpark Documentation](https://spark.apache.org/docs/latest/api/python/)
- [PySpark SQL Functions](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/functions.html)
- [Delta Lake Guide](https://docs.delta.io/)

[⬅️ Retour aux Ressources](../README.md)
