# Module 06 - Notebooks & Spark

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Utiliser les notebooks Fabric efficacement
- ✅ Configurer et gérer les Spark pools
- ✅ Maîtriser PySpark pour le traitement de données
- ✅ Manipuler DataFrames et effectuer des transformations
- ✅ Utiliser Spark SQL pour des requêtes analytiques
- ✅ Travailler avec Delta Lake dans Spark
- ✅ Gérer les libraries et packages
- ✅ Optimiser les jobs Spark

## Contenu du module

### [01 - Notebooks Fabric](./01-notebooks-fabric.md)
- Introduction aux notebooks dans Fabric
- Interface et fonctionnalités
- Cellules (code, markdown, SQL)
- Kernel Spark
- Magic commands (%spark, %sql, %%configure)
- Visualisations intégrées
- Sharing et collaboration
- Versioning avec Git

### [02 - Spark Pools Configuration](./02-spark-pools-configuration.md)
- Architecture Spark dans Fabric
- Starter pools vs custom pools
- Configuration des pools (nodes, cores, memory)
- Auto-scaling
- Session management
- Environment runtime
- High concurrency mode
- Coûts et optimisation

### [03 - PySpark Basics](./03-pyspark-basics.md)
- SparkSession et SparkContext
- RDDs (Resilient Distributed Datasets)
- Transformations vs Actions
- Lazy evaluation
- Partitioning
- Broadcast variables
- Accumulators
- Best practices

### [04 - DataFrames & Transformations](./04-dataframes-transformations.md)
- Création de DataFrames
- Lecture de différentes sources (CSV, JSON, Parquet, Delta)
- Schéma : inféré vs explicite
- Opérations sur DataFrames :
  - select, filter, where
  - groupBy, agg
  - join, union
  - withColumn, drop
  - orderBy, limit
- UDFs (User Defined Functions)
- Window functions

### [05 - Spark SQL](./05-spark-sql.md)
- Introduction à Spark SQL
- Temporary views et global views
- Requêtes SQL sur DataFrames
- Catalog et metastore
- CTEs (Common Table Expressions)
- Jointures optimisées
- Fonctions analytiques
- Performance tuning

### [06 - Delta Lake avec Spark](./06-delta-lake-spark.md)
- API Delta Lake
- Lecture/écriture de tables Delta
- ACID transactions
- Time travel avec PySpark
- MERGE operations (upsert)
- OPTIMIZE et VACUUM
- Change Data Feed
- Delta Live Tables preview

### [07 - Libraries et Packages](./07-libraries-packages.md)
- Installation de packages (pip, conda)
- Libraries pré-installées
- Custom wheels
- Environment management
- .whl upload
- Requirements.txt
- Conda environment
- Dependency conflicts resolution

### [08 - Optimisation Spark Jobs](./08-spark-job-optimization.md)
- Spark UI analysis
- Execution plans (explain)
- Partitioning strategies
- Bucketing
- Caching et persistence
- Broadcast joins
- Skew data handling
- Memory tuning
- Spill to disk troubleshooting

## Exercices pratiques

### Exercice 1 : Premier notebook
1. Créer un notebook Fabric
2. Se connecter à un Lakehouse
3. Charger un DataFrame depuis CSV
4. Afficher les premières lignes et le schéma

### Exercice 2 : Transformations PySpark
1. Charger des données de ventes
2. Filtrer par date
3. Calculer des agrégations (sum, avg, count)
4. Créer des colonnes calculées
5. Joindre avec une table de dimension

### Exercice 3 : Spark SQL
1. Créer des temporary views
2. Écrire des requêtes SQL complexes
3. Utiliser des CTEs
4. Window functions pour ranking
5. Comparer performance SQL vs DataFrame API

### Exercice 4 : Delta Lake operations
1. Écrire un DataFrame en table Delta
2. Effectuer des upserts avec MERGE
3. Requêter une version précédente (time travel)
4. Optimiser la table
5. Analyser le transaction log

### Exercice 5 : Optimisation
1. Charger un large dataset
2. Analyser l'execution plan
3. Appliquer du caching stratégique
4. Optimiser les partitions
5. Mesurer les gains de performance

### Exercice 6 : Pipeline Spark complet
1. Bronze : charger raw data
2. Silver : nettoyer et standardiser
3. Gold : agréger pour analytics
4. Optimiser chaque étape
5. Scheduler l'exécution

## Quiz

1. Quelle est la différence entre transformation et action dans Spark ?
2. Qu'est-ce que la lazy evaluation ?
3. Comment créer une temporary view depuis un DataFrame ?
4. Expliquez le concept de partitioning dans Spark
5. Qu'est-ce qu'un broadcast join et quand l'utiliser ?

## Exemples de code

### Chargement et exploration

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, avg, count

# SparkSession est déjà créée dans Fabric
# spark = SparkSession.builder.appName("MyApp").getOrCreate()

# Charger un DataFrame
df = spark.read.format("csv") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .load("Files/sales.csv")

# Explorer
df.show(10)
df.printSchema()
df.count()

# Statistiques
df.describe().show()
```

### Transformations

```python
from pyspark.sql.functions import col, when, year, month

# Filtrer
filtered = df.filter(col("amount") > 100)

# Ajouter colonne
with_status = df.withColumn(
    "status",
    when(col("amount") > 1000, "High")
    .when(col("amount") > 500, "Medium")
    .otherwise("Low")
)

# Extraction date
with_date_parts = df.withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date")))

# Agrégation
agg_df = df.groupBy("category", "region") \
    .agg(
        sum("amount").alias("total_sales"),
        avg("amount").alias("avg_order_value"),
        count("*").alias("order_count")
    )
```

### Spark SQL

```python
# Créer view
df.createOrReplaceTempView("sales")

# Requête SQL
result = spark.sql("""
    SELECT
        category,
        region,
        SUM(amount) as total_sales,
        COUNT(*) as order_count,
        RANK() OVER (PARTITION BY category ORDER BY SUM(amount) DESC) as rank
    FROM sales
    WHERE order_date >= '2024-01-01'
    GROUP BY category, region
    ORDER BY total_sales DESC
""")

result.show()
```

### Delta Lake operations

```python
from delta.tables import DeltaTable

# Écrire en Delta
df.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("sales_delta")

# MERGE (upsert)
delta_table = DeltaTable.forName(spark, "sales_delta")

delta_table.alias("target").merge(
    updates_df.alias("source"),
    "target.order_id = source.order_id"
).whenMatchedUpdate(set = {
    "amount": "source.amount",
    "status": "source.status"
}).whenNotMatchedInsert(values = {
    "order_id": "source.order_id",
    "amount": "source.amount",
    "status": "source.status"
}).execute()

# Time travel
old_version = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("Tables/sales_delta")
```

### UDF

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

# Définir UDF
def categorize_amount(amount):
    if amount > 1000:
        return "Premium"
    elif amount > 500:
        return "Standard"
    else:
        return "Basic"

# Enregistrer UDF
categorize_udf = udf(categorize_amount, StringType())

# Utiliser
df_with_category = df.withColumn("tier", categorize_udf(col("amount")))
```

### Optimisation

```python
# Cache
df_cached = df.cache()
df_cached.count()  # Trigger caching

# Repartition
df_repartitioned = df.repartition(10, "category")

# Broadcast join (petite table)
from pyspark.sql.functions import broadcast
result = large_df.join(broadcast(small_df), "key")

# Explain
df.explain(mode="extended")
```

## Ressources complémentaires

### Documentation officielle
- [Notebooks in Fabric](https://learn.microsoft.com/fabric/data-engineering/how-to-use-notebook)
- [Apache Spark in Fabric](https://learn.microsoft.com/fabric/data-engineering/spark-overview)
- [PySpark API reference](https://spark.apache.org/docs/latest/api/python/)

### Guides
- [Spark performance tuning](https://spark.apache.org/docs/latest/tuning.html)
- [Delta Lake documentation](https://docs.delta.io/)

## Durée estimée

- **Lecture** : 5-6 heures
- **Exercices** : 5-6 heures
- **Total** : 10-12 heures

## Prochaine étape

➡️ [Module 07 - Semantic Models & Power BI](../07-Semantic-Models-PowerBI/)

---

[⬅️ Module précédent](../05-Dataflows-Gen2/) | [⬅️ Retour au sommaire](../README.md)
