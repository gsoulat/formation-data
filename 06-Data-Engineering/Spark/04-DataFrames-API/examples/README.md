# Exemples DataFrames API

Exemples pratiques pour maîtriser l'API DataFrame de Spark.

## Fichiers

### 1. dataframe_basics.py
**Opérations de base** :
- Création de DataFrames (depuis listes, fichiers, etc.)
- Affichage et inspection (show, printSchema, describe)
- Sélection de colonnes (select)
- Filtrage de lignes (filter/where)
- Ajout/modification/suppression de colonnes
- Tri et dédoublonnage
- Conditions (when/otherwise)

### 2. dataframe_operations.py
**Opérations avancées** :
- Agrégations (groupBy, agg)
- Joins (inner, left, right, outer, full)
- Window functions (rank, cumulative sum)
- Fonctions sur strings et dates
- Pivot/Unpivot
- Union de DataFrames
- Analyse e-commerce complète

## Exécution

```bash
# Se placer dans le dossier
cd 04-DataFrames-API/examples

# Exécuter les scripts
python dataframe_basics.py
python dataframe_operations.py

# Ou avec spark-submit
spark-submit dataframe_basics.py
spark-submit dataframe_operations.py
```

## Concepts clés

### DataFrame vs RDD

**Utilisez DataFrame** (recommandé) :
- API haut niveau, plus intuitive
- Optimisations automatiques (Catalyst)
- Plus rapide que RDD
- Compatible SQL

**Utilisez RDD** (cas spécifiques) :
- Contrôle fin nécessaire
- Opérations custom complexes

### Lazy Evaluation

Les transformations ne s'exécutent que lors d'une action :

```python
df = spark.read.csv("data.csv")      # Lazy
df_filtered = df.filter(col("age") > 25)  # Lazy
df_filtered.show()                    # Action → Exécution !
```

### Optimisation Catalyst

Spark optimise automatiquement vos requêtes :
- Predicate pushdown (filtre au plus tôt)
- Column pruning (ne lit que les colonnes nécessaires)
- Constant folding

## Principales opérations

### Lecture/Écriture
```python
# Lire
df = spark.read.csv("data.csv", header=True, inferSchema=True)
df = spark.read.json("data.json")
df = spark.read.parquet("data.parquet")

# Écrire
df.write.csv("output/")
df.write.parquet("output/")
df.write.mode("overwrite").parquet("output/")
```

### Transformation
```python
# Sélection
df.select("col1", "col2")
df.filter(col("age") > 25)

# Ajout/modification
df.withColumn("new_col", col("old_col") * 2)
df.withColumnRenamed("old", "new")
df.drop("col")

# Tri
df.orderBy("col")
df.orderBy(col("col").desc())
```

### Agrégation
```python
# GroupBy
df.groupBy("category").count()
df.groupBy("category").agg(
    sum("price").alias("total"),
    avg("price").alias("average")
)
```

### Joins
```python
# Inner join
df1.join(df2, "key")

# Left join
df1.join(df2, "key", "left")

# Multiple conditions
df1.join(df2, (df1.id == df2.id) & (df1.date == df2.date))
```

## Bonnes pratiques

### 1. Définir le schema explicitement
```python
# ❌ Lent (scan complet)
df = spark.read.csv("data.csv", inferSchema=True)

# ✅ Rapide
from pyspark.sql.types import *
schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("name", StringType(), True)
])
df = spark.read.csv("data.csv", schema=schema)
```

### 2. Sélectionner tôt
```python
# ❌ Éviter (charge toutes les colonnes)
df = spark.read.parquet("data/")
result = df.filter(col("age") > 25).select("name", "age")

# ✅ Préférer (ne charge que les colonnes nécessaires)
result = spark.read.parquet("data/").select("name", "age").filter(col("age") > 25)
```

### 3. Utiliser cache() pour réutilisations
```python
df_filtered = df.filter(col("active") == True)
df_filtered.cache()

# Multiples utilisations
count = df_filtered.count()
stats = df_filtered.describe()
```

### 4. Préférer reduceByKey à groupByKey
```python
# ❌ groupByKey transfert toutes les valeurs
grouped = pairs_df.groupBy("key").agg(...)

# ✅ reduceByKey réduit localement
# (Utilisez groupBy().agg() qui est optimisé)
```

## Fonctions utiles

### Agrégations
```python
from pyspark.sql.functions import *

count(), countDistinct()
sum(), avg(), min(), max()
stddev(), variance()
first(), last()
collect_list(), collect_set()
```

### Strings
```python
upper(), lower(), trim()
substring(), concat()
regexp_extract(), regexp_replace()
split(), length()
```

### Dates
```python
current_date(), current_timestamp()
year(), month(), dayofmonth()
date_add(), date_sub()
datediff(), add_months()
to_date(), date_format()
```

### Conditions
```python
when(condition, value).otherwise(default)
```

### Window
```python
from pyspark.sql.window import Window

Window.partitionBy("col").orderBy("col2")
rank(), dense_rank(), row_number()
lead(), lag()
```

## Exercices

### Exercice 1 : Analyse de ventes
Créer un DataFrame de ventes et calculer :
- Revenus totaux par produit
- Top 3 produits
- Ventes moyennes par jour

### Exercice 2 : Nettoyage de données
Avec des données "sales", nettoyer :
- Supprimer les doublons
- Remplir les valeurs nulles
- Normaliser les noms (trim, initcap)

### Exercice 3 : Joins multiples
Joindre 3 tables : orders, customers, products
Calculer le revenu par client et par catégorie de produit

### Exercice 4 : Window Functions
Calculer le ranking des employés par département basé sur leur salaire
Ajouter une colonne avec le salaire moyen du département

## Ressources

- [DataFrame API Docs](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/dataframe.html)
- [SQL Functions Reference](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/functions.html)
- Module précédent : [03-RDD-Basics](../../03-RDD-Basics/README.md)
- Module suivant : [05-Spark-SQL](../../05-Spark-SQL/README.md)
