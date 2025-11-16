# Partitionnement et Optimisation

## Partitionnement

### Concept

Le partitionnement divise une table en segments plus petits basés sur des valeurs de colonnes.

```
Table non-partitionnée:
└── part-00000.parquet (tout)

Table partitionnée par année:
├── year=2022/
│   └── *.parquet
├── year=2023/
│   └── *.parquet
└── year=2024/
    └── *.parquet
```

### Avantages

✅ **Query Performance** : Partition pruning
✅ **Manageabilité** : Maintenance par partition
✅ **Data Lifecycle** : Delete/Archive par partition

### Partition Pruning

```python
# Query sur table partitionnée par year
df = spark.table("sales").where("year = 2024")

# Spark lit SEULEMENT year=2024/
# Ignore year=2022/, year=2023/
# → Performance boost massive!
```

## Stratégies de Partitionnement

### 1. Par Date (Le Plus Courant)

```python
df.write.format("delta") \
    .partitionBy("year", "month") \
    .saveAsTable("sales")

# Structure créée:
# year=2024/month=01/*.parquet
# year=2024/month=02/*.parquet
```

**Use case :** Time-series data, logs, events

### 2. Par Catégorie

```python
df.write.format("delta") \
    .partitionBy("country", "category") \
    .saveAsTable("products")

# country=FR/category=Electronics/*.parquet
# country=FR/category=Books/*.parquet
```

**Use case :** Données avec filtres fréquents sur catégories

### 3. Par Range

```python
# Partitionnement custom par range
df.withColumn("price_range",
    when(col("price") < 100, "low")
    .when(col("price") < 1000, "medium")
    .otherwise("high")
).write.partitionBy("price_range").saveAsTable("products")
```

### 4. Multi-Column

```python
df.write.partitionBy("year", "month", "day").saveAsTable("logs")

# Attention: Pas trop de niveaux!
# Limite recommandée: 2-3 colonnes max
```

## Taille Optimale des Partitions

### Règles Générales

```
Taille idéale partition: 100 MB - 1 GB
Nombre max partitions: 1000-2000
Fichiers par partition: 1-10
```

### Over-Partitioning (Problème)

```python
# ❌ Mauvais: Trop de partitions
df.write.partitionBy("year", "month", "day", "hour", "minute")

# Résultat: Des milliers de petites partitions
# Problème:
#   - Overhead metadata
#   - Listing files lent
#   - Small files problem
```

### Under-Partitioning (Problème)

```python
# ❌ Mauvais: Pas assez de partitions
df.write.partitionBy("year")  # Sur 10 ans de données

# Résultat: Quelques énormes partitions
# Problème:
#   - Pas de pruning fin
#   - Partitions de plusieurs TB
```

### Sweet Spot

```python
# ✅ Bon: Partitionnement équilibré
# Dataset: 1 TB, 5 ans de données
df.write.partitionBy("year", "month")

# 60 partitions (5 ans × 12 mois)
# ~17 GB par partition
# ✅ Optimal!
```

## V-Order Optimization

### Qu'est-ce que V-Order ?

Compression columnaire propriétaire Microsoft, optimisée pour OneLake.

**Avantages :**
- Compression ~50% meilleure que Parquet
- Lecture ~2x plus rapide (Power BI Direct Lake)
- Compatible Delta Lake

### Activation

```python
# Automatique dans Fabric pour nouvelles tables
df.write.format("delta").saveAsTable("optimized_table")

# Force optimization
spark.sql("OPTIMIZE my_table")
```

### V-Order vs Parquet Standard

| Métrique | Parquet Standard | V-Order |
|----------|------------------|---------|
| Compression Ratio | 1:5 | 1:10 |
| Read Speed (BI) | Baseline | 2x faster |
| Write Speed | Baseline | 10% slower |
| Storage Cost | Baseline | -50% |

## OPTIMIZE Command

### Compaction de Fichiers

```python
# Problème: Beaucoup de petits fichiers
# append, append, append → 1000 petits fichiers

# Solution: OPTIMIZE
spark.sql("OPTIMIZE my_table")

# Résultat: Fichiers regroupés en fichiers optimaux (~1GB)
```

### Syntax

```sql
-- Basic optimize
OPTIMIZE my_table;

-- Optimize partition spécifique
OPTIMIZE my_table WHERE year = 2024;

-- With Z-Ordering
OPTIMIZE my_table ZORDER BY (customer_id, product_id);
```

### Quand Exécuter

```python
# Après plusieurs appends
for batch in batches:
    batch_df.write.mode("append").saveAsTable("my_table")

# Optimize à la fin
spark.sql("OPTIMIZE my_table")

# Ou scheduled (nightly)
```

## Z-Ordering

### Concept

Z-Ordering co-locate des colonnes fréquemment filtrées ensemble.

```python
# Sans Z-Order:
# customer_id=1 réparti dans plein de fichiers

# Avec Z-Order sur customer_id:
# customer_id=1 principalement dans 1-2 fichiers
# → Data skipping efficace
```

### Utilisation

```python
# Z-Order sur colonnes fréquemment filtrées
spark.sql("OPTIMIZE sales ZORDER BY (customer_id, product_id)")

# Query bénéficie
df = spark.table("sales").where("customer_id = 12345")
# Lecture de 2-3 fichiers au lieu de 100+
```

### Colonnes Candidates

✅ **Bon pour Z-Order :**
- High cardinality
- Colonnes fréquemment dans WHERE
- Colonnes de JOIN

❌ **Mauvais pour Z-Order :**
- Colonnes de partitionnement (déjà optimisées)
- Low cardinality (country, yes/no)
- Rarement filtrées

## VACUUM

### Nettoyage des Anciens Fichiers

```python
# Delta garde anciennes versions (time travel)
# Mais consomme du storage

# VACUUM supprime anciennes versions
spark.sql("VACUUM my_table RETAIN 168 HOURS")  # 7 jours

# Libère espace storage
```

### Retention

```python
# Production: 7-30 jours
spark.sql("VACUUM prod_table RETAIN 168 HOURS")

# Development: 2-7 jours
spark.sql("VACUUM dev_table RETAIN 48 HOURS")

# Compliance: Peut-être plus long
spark.sql("VACUUM compliance_table RETAIN 2160 HOURS")  # 90 jours
```

### Dry Run

```python
# Voir ce qui serait supprimé sans supprimer
spark.sql("VACUUM my_table DRY RUN")
```

## Statistiques

### Collection

```python
# Collecter statistiques
spark.sql("ANALYZE TABLE my_table COMPUTE STATISTICS")

# Avec colonnes
spark.sql("ANALYZE TABLE my_table COMPUTE STATISTICS FOR COLUMNS customer_id, amount")
```

### Utilisation

```
Optimizer utilise statistiques pour:
  - Choisir join strategy (broadcast vs shuffle)
  - Estimer nombre de lignes
  - Optimiser execution plan
```

## Caching

### DataFrame Cache

```python
# Cache en mémoire
df = spark.table("my_table")
df.cache()
df.count()  # Materialize cache

# Queries suivantes = fast (mémoire)
result1 = df.where("amount > 100").count()
result2 = df.groupBy("category").sum("amount")

# Unpersist quand terminé
df.unpersist()
```

### Table Cache

```sql
-- Cache table complète
CACHE TABLE my_table;

-- Query hit cache
SELECT * FROM my_table WHERE ...;

-- Clear cache
UNCACHE TABLE my_table;
```

## Tuning Strategies

### Small Files Problem

```python
# Problème: 10,000 fichiers de 10 MB
# Solution 1: OPTIMIZE
spark.sql("OPTIMIZE my_table")

# Solution 2: Repartition avant écriture
df.repartition(10).write.saveAsTable("my_table")

# Solution 3: Auto-optimize (Fabric setting)
spark.conf.set("spark.databricks.delta.optimizeWrite.enabled", "true")
```

### Large Partitions

```python
# Problème: Partition de 50 GB
# Solution: Ajouter niveau de partitionnement
df.write.partitionBy("year", "month", "day")  # Plus fin

# Ou: Repartition en écriture
df.repartition(50).write.partitionBy("year", "month")
```

### Skewed Data

```python
# Problème: customer_id=999 = 80% des données
# Solution: Salting
df.withColumn("salt", (rand() * 10).cast("int")) \
  .write.partitionBy("customer_id", "salt") \
  .saveAsTable("balanced_table")
```

## Best Practices

### Partitionnement

✅ **DO:**
```python
# Partitionner sur colonnes fréquemment filtrées
.partitionBy("year", "month")

# 100 MB - 1 GB par partition
# 100-1000 partitions totales
```

❌ **DON'T:**
```python
# Trop de colonnes
.partitionBy("year", "month", "day", "hour")

# Low cardinality
.partitionBy("active")  # true/false seulement
```

### Optimization

✅ **DO:**
```sql
-- Regular OPTIMIZE
OPTIMIZE my_table;

-- Z-Order sur colonnes filtrées
OPTIMIZE my_table ZORDER BY (customer_id);

-- VACUUM régulier
VACUUM my_table RETAIN 168 HOURS;
```

❌ **DON'T:**
```sql
-- VACUUM trop agressif
VACUUM my_table RETAIN 0 HOURS;  # Casse time travel!

-- OPTIMIZE trop fréquent
-- (après chaque append → overhead)
```

## Monitoring

```python
# Voir détails table
spark.sql("DESCRIBE DETAIL my_table").show()

# Résultat:
# numFiles: 150
# sizeInBytes: 52428800
# Partitioning: [year, month]

# Historique
spark.sql("DESCRIBE HISTORY my_table").show()
```

## Points Clés

- Partitionner par colonnes fréquemment filtrées
- Taille optimale: 100 MB - 1 GB par partition
- V-Order activation automatique (Fabric)
- OPTIMIZE pour compacter fichiers
- Z-Ordering pour data skipping
- VACUUM pour libérer storage
- Statistiques pour optimizer
- Monitoring régulier

---

**Prochain fichier :** [07 - Time Travel et Versioning](./07-time-travel-versioning.md)

[⬅️ Fichier précédent](./05-schemas-medallion-architecture.md) | [⬅️ Retour au README du module](./README.md)
