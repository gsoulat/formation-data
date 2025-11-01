# DataFrames API - Abstraction haut niveau

## Table des matières

1. [Introduction aux DataFrames](#introduction-aux-dataframes)
2. [Création de DataFrames](#création-de-dataframes)
3. [Schema et types](#schema-et-types)
4. [Sélection et projection](#sélection-et-projection)
5. [Filtrage](#filtrage)
6. [Agrégations](#agrégations)
7. [Joins](#joins)
8. [Opérations sur colonnes](#opérations-sur-colonnes)
9. [Gestion des données manquantes](#gestion-des-données-manquantes)
10. [Exemples pratiques](#exemples-pratiques)

---

## Introduction aux DataFrames

### Qu'est-ce qu'un DataFrame ?

Un **DataFrame** est une collection distribuée de données organisées en colonnes nommées, similaire à une table SQL ou un DataFrame Pandas.

### Pourquoi utiliser DataFrames plutôt que RDDs ?

| Critère | RDD | DataFrame |
|---------|-----|-----------|
| **API** | Fonctionnelle (bas niveau) | SQL + Fonctionnelle (haut niveau) |
| **Optimisation** | Manuelle | Automatique (Catalyst) |
| **Performance** | Moins rapide | Plus rapide |
| **Type safety** | Compile-time | Runtime |
| **Lisibilité** | Moins intuitive | Plus intuitive |

**Recommandation** : Utilisez DataFrames par défaut (sauf besoin spécifique de RDD).

### Architecture DataFrame

```
DataFrame (Vue logique)
    ↓
Catalyst Optimizer (Optimise le plan)
    ↓
Tungsten Execution Engine (Exécution optimisée)
    ↓
RDD (Exécution physique)
```

**Avantages de Catalyst** :
- Optimisation automatique des requêtes
- Predicate pushdown (filtrage anticipé)
- Projection pruning (colonnes non utilisées ignorées)
- Constant folding, expression simplification

---

## Création de DataFrames

### 1. À partir d'une liste de tuples

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DataFrame Demo") \
    .master("local[*]") \
    .getOrCreate()

# Liste de tuples
data = [
    (1, "Alice", 25, "Paris"),
    (2, "Bob", 30, "Lyon"),
    (3, "Charlie", 35, "Marseille")
]

# Créer DataFrame
df = spark.createDataFrame(data, ["id", "name", "age", "city"])
df.show()

# +---+-------+---+---------+
# | id|   name|age|     city|
# +---+-------+---+---------+
# |  1|  Alice| 25|    Paris|
# |  2|    Bob| 30|     Lyon|
# |  3|Charlie| 35|Marseille|
# +---+-------+---+---------+
```

### 2. À partir d'une liste de dictionnaires

```python
data = [
    {"id": 1, "name": "Alice", "age": 25},
    {"id": 2, "name": "Bob", "age": 30},
    {"id": 3, "name": "Charlie", "age": 35}
]

df = spark.createDataFrame(data)
df.show()
```

### 3. À partir d'un RDD

```python
rdd = spark.sparkContext.parallelize([
    (1, "Alice", 25),
    (2, "Bob", 30)
])

df = rdd.toDF(["id", "name", "age"])
df.show()
```

### 4. À partir d'un DataFrame Pandas

```python
import pandas as pd

pandas_df = pd.DataFrame({
    "id": [1, 2, 3],
    "name": ["Alice", "Bob", "Charlie"],
    "age": [25, 30, 35]
})

# Pandas → Spark DataFrame
spark_df = spark.createDataFrame(pandas_df)
spark_df.show()

# Spark → Pandas DataFrame
pandas_df_back = spark_df.toPandas()
```

### 5. À partir de fichiers

```python
# CSV
df_csv = spark.read.csv("data.csv", header=True, inferSchema=True)

# JSON
df_json = spark.read.json("data.json")

# Parquet
df_parquet = spark.read.parquet("data.parquet")

# Options avancées CSV
df_csv = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("delimiter", ";") \
    .option("quote", "\"") \
    .csv("data.csv")
```

### 6. À partir d'une base de données

```python
# JDBC
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/mydb") \
    .option("dbtable", "users") \
    .option("user", "postgres") \
    .option("password", "password") \
    .load()
```

### 7. Créer un DataFrame vide avec schema

```python
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True)
])

empty_df = spark.createDataFrame([], schema)
empty_df.printSchema()
```

### 8. Créer avec spark.range()

```python
# DataFrame avec une colonne "id" de 0 à 9
df = spark.range(10)
df.show()

# Avec start, end, step
df = spark.range(0, 100, 5)  # 0, 5, 10, ..., 95
```

---

## Schema et types

### Afficher le schema

```python
df.printSchema()

# root
#  |-- id: integer (nullable = true)
#  |-- name: string (nullable = true)
#  |-- age: integer (nullable = true)
```

### Types de données Spark

```python
from pyspark.sql.types import *

# Types principaux
IntegerType()       # Entier 32-bit
LongType()          # Entier 64-bit
FloatType()         # Float 32-bit
DoubleType()        # Float 64-bit
StringType()        # String
BooleanType()       # Boolean
DateType()          # Date (sans heure)
TimestampType()     # Timestamp (date + heure)
DecimalType()       # Décimal précis
ArrayType()         # Liste
MapType()           # Dictionnaire
StructType()        # Structure (objet)
```

### Définir un schema explicite

```python
schema = StructType([
    StructField("user_id", IntegerType(), False),  # False = NOT NULL
    StructField("username", StringType(), True),
    StructField("email", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("balance", DoubleType(), True),
    StructField("created_at", TimestampType(), True)
])

df = spark.read.csv("users.csv", schema=schema, header=True)
```

### Inférer le schema automatiquement

```python
# Avec inferSchema (scanne les données)
df = spark.read.csv("data.csv", header=True, inferSchema=True)

# Sans inferSchema (tout est String)
df = spark.read.csv("data.csv", header=True)
```

**⚠️ Attention** : `inferSchema=True` est coûteux (scan complet). En production, définissez le schema explicitement.

### Changer le type d'une colonne (cast)

```python
from pyspark.sql.functions import col

df = df.withColumn("age", col("age").cast("integer"))
df = df.withColumn("balance", col("balance").cast("double"))
```

---

## Sélection et projection

### select() - Sélectionner des colonnes

```python
# Une colonne
df.select("name").show()

# Plusieurs colonnes
df.select("name", "age").show()

# Avec col()
from pyspark.sql.functions import col
df.select(col("name"), col("age")).show()

# Avec df.colonne
df.select(df.name, df.age).show()

# Toutes les colonnes
df.select("*").show()
```

### Renommer des colonnes

```python
# Méthode 1 : alias()
df.select(col("name").alias("username"), col("age")).show()

# Méthode 2 : withColumnRenamed()
df = df.withColumnRenamed("name", "username")

# Renommer plusieurs colonnes
for old_col, new_col in [("name", "username"), ("age", "user_age")]:
    df = df.withColumnRenamed(old_col, new_col)
```

### Ajouter/Modifier des colonnes

```python
# Ajouter une colonne calculée
df = df.withColumn("age_in_5_years", col("age") + 5)

# Modifier une colonne existante
df = df.withColumn("name", upper(col("name")))

# Ajouter une colonne constante
from pyspark.sql.functions import lit
df = df.withColumn("country", lit("France"))
```

### Supprimer des colonnes

```python
# Supprimer une colonne
df = df.drop("age")

# Supprimer plusieurs colonnes
df = df.drop("age", "city")
```

### columns et dtypes

```python
# Liste des colonnes
print(df.columns)  # ['id', 'name', 'age']

# Types des colonnes
print(df.dtypes)  # [('id', 'int'), ('name', 'string'), ('age', 'int')]
```

---

## Filtrage

### filter() / where() - Filtrer les lignes

```python
# Les deux sont équivalents
df.filter(col("age") > 25).show()
df.where(col("age") > 25).show()

# Plusieurs conditions (AND)
df.filter((col("age") > 25) & (col("city") == "Paris")).show()

# Condition OR
df.filter((col("age") < 20) | (col("age") > 60)).show()

# NOT
df.filter(~(col("age") > 30)).show()

# Avec expression SQL
df.filter("age > 25 AND city = 'Paris'").show()
```

### Opérateurs de comparaison

```python
from pyspark.sql.functions import col

# Égalité
df.filter(col("city") == "Paris")

# Différent
df.filter(col("city") != "Paris")

# Comparaisons
df.filter(col("age") > 25)
df.filter(col("age") >= 25)
df.filter(col("age") < 25)
df.filter(col("age") <= 25)

# IN
df.filter(col("city").isin(["Paris", "Lyon"]))

# LIKE (pattern matching)
df.filter(col("name").like("A%"))  # Commence par A

# RLIKE (regex)
df.filter(col("email").rlike(r".*@gmail\.com$"))

# IS NULL / IS NOT NULL
df.filter(col("age").isNull())
df.filter(col("age").isNotNull())

# BETWEEN
df.filter(col("age").between(20, 30))
```

---

## Agrégations

### Fonctions d'agrégation simples

```python
from pyspark.sql.functions import count, sum, avg, min, max, stddev

# Count
df.count()  # Nombre de lignes

# Agrégations sur colonnes
df.select(
    count("*").alias("total"),
    avg("age").alias("avg_age"),
    min("age").alias("min_age"),
    max("age").alias("max_age")
).show()
```

### groupBy() - Grouper les données

```python
# Grouper par une colonne
df.groupBy("city").count().show()

# Grouper et agréger
df.groupBy("city").agg(
    count("*").alias("count"),
    avg("age").alias("avg_age"),
    min("age").alias("min_age"),
    max("age").alias("max_age")
).show()

# Grouper par plusieurs colonnes
df.groupBy("city", "gender").count().show()
```

### agg() - Agrégations multiples

```python
from pyspark.sql.functions import sum, avg, count, max

df.groupBy("department").agg(
    count("*").alias("num_employees"),
    avg("salary").alias("avg_salary"),
    sum("salary").alias("total_salary"),
    max("salary").alias("max_salary")
).show()
```

### Fonctions d'agrégation courantes

```python
from pyspark.sql.functions import *

# Statistiques
count()           # Nombre
countDistinct()   # Nombre d'éléments uniques
sum()             # Somme
avg() / mean()    # Moyenne
min()             # Minimum
max()             # Maximum
stddev()          # Écart-type
variance()        # Variance

# Autres
first()           # Premier élément
last()            # Dernier élément
collect_list()    # Liste des valeurs
collect_set()     # Set des valeurs (uniques)
```

### Exemple complet

```python
sales = spark.createDataFrame([
    ("2024-01-01", "ProductA", 100),
    ("2024-01-01", "ProductB", 150),
    ("2024-01-02", "ProductA", 200),
    ("2024-01-02", "ProductB", 80),
], ["date", "product", "amount"])

# Revenus par produit
product_revenue = sales.groupBy("product").agg(
    sum("amount").alias("total_revenue"),
    count("*").alias("num_sales"),
    avg("amount").alias("avg_sale")
).orderBy("total_revenue", ascending=False)

product_revenue.show()

# +--------+-------------+---------+--------+
# | product|total_revenue|num_sales|avg_sale|
# +--------+-------------+---------+--------+
# |ProductA|          300|        2|   150.0|
# |ProductB|          230|        2|   115.0|
# +--------+-------------+---------+--------+
```

---

## Joins

### Types de joins

```python
# Données
employees = spark.createDataFrame([
    (1, "Alice", 1),
    (2, "Bob", 2),
    (3, "Charlie", 1),
    (4, "David", 3)
], ["emp_id", "name", "dept_id"])

departments = spark.createDataFrame([
    (1, "Sales"),
    (2, "Engineering"),
    (3, "HR")
], ["dept_id", "dept_name"])
```

### Inner Join (défaut)

```python
# JOIN sur colonne commune
result = employees.join(departments, "dept_id")
result.show()

# +-------+------+-------+------------+
# |dept_id|emp_id|   name|   dept_name|
# +-------+------+-------+------------+
# |      1|     1|  Alice|       Sales|
# |      1|     3|Charlie|       Sales|
# |      2|     2|    Bob| Engineering|
# |      3|     4|  David|          HR|
# +-------+------+-------+------------+
```

### Left Outer Join

```python
# Garde toutes les lignes de gauche
result = employees.join(departments, "dept_id", "left")
result.show()
```

### Right Outer Join

```python
# Garde toutes les lignes de droite
result = employees.join(departments, "dept_id", "right")
result.show()
```

### Full Outer Join

```python
# Garde toutes les lignes des deux côtés
result = employees.join(departments, "dept_id", "outer")
result.show()
```

### Join avec colonnes différentes

```python
# Colonnes avec noms différents
result = employees.join(
    departments,
    employees.dept_id == departments.dept_id,
    "inner"
).drop(departments.dept_id)  # Éviter les doublons de colonnes
```

### Join avec plusieurs conditions

```python
result = df1.join(
    df2,
    (df1.id == df2.id) & (df1.date == df2.date),
    "inner"
)
```

### Cross Join (produit cartésien)

```python
# ATTENTION : Très coûteux !
result = df1.crossJoin(df2)
```

---

## Opérations sur colonnes

### Fonctions de string

```python
from pyspark.sql.functions import *

# Manipulation de texte
df = df.withColumn("name_upper", upper(col("name")))
df = df.withColumn("name_lower", lower(col("name")))
df = df.withColumn("name_length", length(col("name")))
df = df.withColumn("name_trimmed", trim(col("name")))

# Substring
df = df.withColumn("first_letter", substring(col("name"), 1, 1))

# Concat
df = df.withColumn("full_name", concat(col("first_name"), lit(" "), col("last_name")))

# Replace
df = df.withColumn("cleaned", regexp_replace(col("text"), r"[^a-zA-Z0-9]", ""))
```

### Fonctions mathématiques

```python
from pyspark.sql.functions import *

df = df.withColumn("abs_value", abs(col("value")))
df = df.withColumn("rounded", round(col("value"), 2))
df = df.withColumn("ceiling", ceil(col("value")))
df = df.withColumn("floor", floor(col("value")))
df = df.withColumn("sqrt", sqrt(col("value")))
```

### Fonctions de date

```python
from pyspark.sql.functions import *

# Date actuelle
df = df.withColumn("today", current_date())
df = df.withColumn("now", current_timestamp())

# Extraire des parties
df = df.withColumn("year", year(col("date")))
df = df.withColumn("month", month(col("date")))
df = df.withColumn("day", dayofmonth(col("date")))

# Différence de dates
df = df.withColumn("days_diff", datediff(col("end_date"), col("start_date")))

# Ajouter/soustraire des jours
df = df.withColumn("next_week", date_add(col("date"), 7))
df = df.withColumn("last_month", add_months(col("date"), -1))

# Formater des dates
df = df.withColumn("formatted", date_format(col("date"), "yyyy-MM-dd"))

# Parser des dates
df = df.withColumn("parsed", to_date(col("date_string"), "yyyy-MM-dd"))
```

### Conditions (when/otherwise)

```python
from pyspark.sql.functions import when

# Simple if-else
df = df.withColumn("age_group",
    when(col("age") < 18, "Minor")
    .when((col("age") >= 18) & (col("age") < 65), "Adult")
    .otherwise("Senior")
)

# Exemple : Catégoriser des scores
df = df.withColumn("grade",
    when(col("score") >= 90, "A")
    .when(col("score") >= 80, "B")
    .when(col("score") >= 70, "C")
    .when(col("score") >= 60, "D")
    .otherwise("F")
)
```

---

## Gestion des données manquantes

### Détecter les valeurs nulles

```python
# Compter les nulls par colonne
from pyspark.sql.functions import col, count, when

df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in df.columns
]).show()
```

### Supprimer les lignes avec nulls

```python
# Supprimer toutes les lignes avec au moins un null
df_clean = df.dropna()

# Supprimer si toutes les colonnes sont null
df_clean = df.dropna(how='all')

# Supprimer si des colonnes spécifiques sont null
df_clean = df.dropna(subset=['age', 'salary'])

# Seuil : garder si au moins 2 valeurs non-null
df_clean = df.dropna(thresh=2)
```

### Remplir les valeurs nulles

```python
# Remplir avec une valeur
df_filled = df.fillna(0)  # Remplir tous les nulls avec 0

# Remplir par colonne
df_filled = df.fillna({"age": 0, "name": "Unknown"})

# Remplacer des valeurs
df_replaced = df.replace(["null", "N/A"], None)
```

---

## Exemples pratiques

### 1. Analyse de ventes e-commerce

```python
# Créer des données
sales = spark.createDataFrame([
    ("2024-01-01", "Electronics", "Laptop", 1200, 2),
    ("2024-01-01", "Books", "Python Guide", 40, 5),
    ("2024-01-02", "Electronics", "Phone", 800, 3),
    ("2024-01-02", "Books", "Spark Book", 50, 2),
    ("2024-01-03", "Electronics", "Laptop", 1200, 1),
], ["date", "category", "product", "price", "quantity"])

# Calculer le revenu
sales = sales.withColumn("revenue", col("price") * col("quantity"))

# Analyse par catégorie
category_stats = sales.groupBy("category").agg(
    count("*").alias("num_orders"),
    sum("revenue").alias("total_revenue"),
    avg("revenue").alias("avg_revenue")
).orderBy("total_revenue", ascending=False)

category_stats.show()
```

### 2. Nettoyage de données utilisateur

```python
# Données avec problèmes
users = spark.createDataFrame([
    (1, " Alice ", 25, "alice@example.com"),
    (2, "BOB", None, "bob@EXAMPLE.com"),
    (3, "charlie", 30, None),
    (4, None, 35, "dave@example.com"),
], ["id", "name", "age", "email"])

# Nettoyage
users_clean = users \
    .dropna(subset=["name"]) \
    .fillna({"age": 0, "email": "unknown@example.com"}) \
    .withColumn("name", trim(col("name"))) \
    .withColumn("name", initcap(col("name"))) \
    .withColumn("email", lower(col("email")))

users_clean.show()
```

### 3. Analyse de logs

```python
# Parser des logs
logs_df = spark.read.text("access.log")

# Extraire des infos avec regex
from pyspark.sql.functions import regexp_extract

logs_parsed = logs_df.select(
    regexp_extract(col("value"), r'(\d+\.\d+\.\d+\.\d+)', 1).alias("ip"),
    regexp_extract(col("value"), r'\"(\w+)\s+([^\s]+)', 1).alias("method"),
    regexp_extract(col("value"), r'\"(\w+)\s+([^\s]+)', 2).alias("url"),
    regexp_extract(col("value"), r'\s(\d{3})\s', 1).alias("status")
)

# Analyser
status_counts = logs_parsed.groupBy("status").count().orderBy("count", ascending=False)
status_counts.show()
```

---

## Bonnes pratiques

### 1. Définir le schema explicitement

```python
# ❌ Éviter (lent)
df = spark.read.csv("large_file.csv", inferSchema=True)

# ✅ Préférer
schema = StructType([...])
df = spark.read.csv("large_file.csv", schema=schema)
```

### 2. Utiliser select() pour réduire les données tôt

```python
# ❌ Éviter (traite toutes les colonnes)
df = spark.read.parquet("data.parquet")
result = df.filter(col("age") > 25).select("name", "age")

# ✅ Préférer (ne charge que les colonnes nécessaires)
df = spark.read.parquet("data.parquet").select("name", "age")
result = df.filter(col("age") > 25)
```

### 3. Cache pour les réutilisations

```python
df_filtered = df.filter(col("active") == True)
df_filtered.cache()

# Multiples utilisations
count = df_filtered.count()
stats = df_filtered.describe()
```

---

## Résumé des opérations principales

### Lecture/Écriture
- `spark.read.csv/json/parquet()` - Lire des fichiers
- `df.write.csv/json/parquet()` - Écrire des fichiers

### Structure
- `df.printSchema()` - Afficher le schema
- `df.columns` - Liste des colonnes
- `df.dtypes` - Types des colonnes

### Visualisation
- `df.show()` - Afficher les données
- `df.head()` / `df.first()` - Première(s) ligne(s)
- `df.describe()` - Statistiques descriptives

### Sélection
- `df.select()` - Sélectionner des colonnes
- `df.filter()` / `df.where()` - Filtrer des lignes
- `df.distinct()` - Valeurs uniques

### Transformation
- `df.withColumn()` - Ajouter/modifier colonne
- `df.withColumnRenamed()` - Renommer colonne
- `df.drop()` - Supprimer colonne

### Agrégation
- `df.groupBy()` - Grouper
- `df.agg()` - Agréger
- `df.orderBy()` / `df.sort()` - Trier

### Joins
- `df1.join(df2, "key")` - Joindre

---

## Prochaines étapes

Module suivant : **[05-Spark-SQL](../05-Spark-SQL/README.md)**

Vous allez apprendre à :
- Utiliser SQL avec Spark
- Créer des vues temporaires
- Window functions
- UDFs (User Defined Functions)
