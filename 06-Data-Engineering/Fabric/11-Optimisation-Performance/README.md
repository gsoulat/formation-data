# Module 11 - Optimisation des Performances

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre et utiliser V-Order optimization
- ✅ Mettre en place des stratégies de partitionnement efficaces
- ✅ Utiliser les mécanismes de cache intelligemment
- ✅ Optimiser les requêtes SQL et DAX
- ✅ Tuner les jobs Spark
- ✅ Monitorer les performances avec les bons outils
- ✅ Troubleshooter les problèmes de performance

## Contenu du module

### [01 - V-Order Optimization](./01-v-order-optimization.md)
- Qu'est-ce que V-Order ?
- Compression columnaire optimisée
- Activation automatique vs manuelle
- Impact sur les performances de lecture
- Comparaison avec Parquet standard
- Best practices
- Coût storage vs gains performance

### [02 - Stratégies de Partitionnement](./02-partitioning-strategies.md)
- Partitionnement de tables Delta
- Partition pruning
- Partitionnement par date (le plus courant)
- Partitionnement multi-colonnes
- Over-partitioning vs under-partitioning
- Z-ordering dans Delta
- Bucketing
- Quand NE PAS partitionner

### [03 - Mécanismes de Cache](./03-caching-mechanisms.md)
- Cache dans Spark (RDD/DataFrame)
- Persistence levels (MEMORY_ONLY, MEMORY_AND_DISK, etc.)
- Result set caching (Power BI)
- OneLake cache
- Cache invalidation
- Stratégies de caching
- Memory management

### [04 - Optimisation de Requêtes](./04-query-optimization.md)
- **SQL** :
  - Execution plans analysis
  - Index usage
  - Join optimization
  - Statistiques
  - Query hints
- **DAX** :
  - Variables pour éviter recalcul
  - CALCULATE optimization
  - Éviter les fonctions coûteuses (FILTER, ALL)
  - Contexte de calcul

### [05 - Spark Tuning](./05-spark-tuning.md)
- Configuration Spark optimale
- Memory tuning (executor, driver)
- Parallelism (partitions, cores)
- Shuffle optimization
- Broadcast variables
- Handling data skew
- Spill to disk troubleshooting
- Adaptive Query Execution (AQE)

### [06 - Monitoring et Métriques](./06-monitoring-metrics.md)
- Capacity Metrics App
- Monitoring Hub dans Fabric
- Spark UI analysis
- Query performance logs
- Performance Analyzer (Power BI)
- Log Analytics integration
- Custom metrics et alertes

### [07 - Troubleshooting](./07-troubleshooting.md)
- Méthodologie de diagnostic
- Performance bottlenecks communs
- Out of memory errors
- Slow queries identification
- Network latency issues
- Timeout errors
- Best practices de résolution

## Exercices pratiques

### Exercice 1 : V-Order activation
1. Créer une table Delta sans V-Order
2. Mesurer les performances de lecture
3. Activer V-Order
4. Comparer les performances
5. Analyser l'impact sur le stockage

### Exercice 2 : Partitionnement optimal
1. Charger un large dataset (plusieurs années)
2. Tester sans partitionnement
3. Partitionner par année/mois
4. Mesurer partition pruning
5. Tester différentes granularités

### Exercice 3 : Cache Spark
1. Créer un DataFrame avec transformations lourdes
2. Exécuter sans cache (mesurer le temps)
3. Ajouter `.cache()`
4. Ré-exécuter et comparer
5. Tester différents storage levels

### Exercice 4 : Optimisation SQL
1. Analyser un execution plan lent
2. Identifier les scans complets (table scans)
3. Ajouter des filtres précoces
4. Utiliser OPTIMIZE et statistiques
5. Mesurer les gains

### Exercice 5 : Tuning Spark job
1. Analyser un job Spark lent dans Spark UI
2. Identifier les stages coûteux
3. Ajuster le nombre de partitions
4. Optimiser les shuffles
5. Mesurer l'amélioration

### Exercice 6 : Monitoring complet
1. Configurer le Capacity Metrics App
2. Analyser l'utilisation des CU
3. Identifier les workloads gourmands
4. Créer des alertes sur seuils
5. Optimiser l'allocation des ressources

## Quiz

1. Qu'est-ce que V-Order et comment améliore-t-il les performances ?
2. Quand devriez-vous NE PAS partitionner une table ?
3. Quelle est la différence entre cache() et persist() dans Spark ?
4. Comment analyser un execution plan SQL ?
5. Qu'est-ce que le data skew et comment le résoudre ?

## Exemples de code

### V-Order

```python
# PySpark - Activer V-Order
df.write.format("delta") \
    .mode("overwrite") \
    .option("delta.checkpoint.writeStatsAsStruct", "true") \
    .option("delta.checkpoint.writeStatsAsJson", "false") \
    .save("Tables/optimized_table")

# SQL - OPTIMIZE avec V-Order
spark.sql("OPTIMIZE sales_table")
```

### Partitionnement

```python
# Créer table partitionnée
df.write.format("delta") \
    .partitionBy("year", "month") \
    .mode("overwrite") \
    .saveAsTable("sales_partitioned")

# Z-ordering pour Delta
spark.sql("OPTIMIZE sales_table ZORDER BY (customer_id, product_id)")

# Lire avec partition pruning (automatique)
filtered = spark.table("sales_partitioned") \
    .filter("year = 2024 AND month = 1")
```

### Cache Spark

```python
# Cache simple
df_cached = df.cache()
df_cached.count()  # Trigger caching

# Persist avec niveau
from pyspark import StorageLevel
df_persisted = df.persist(StorageLevel.MEMORY_AND_DISK)

# Unpersist
df_cached.unpersist()

# Voir les RDDs cachés
spark.sparkContext._jsc.sc().getPersistentRDDs()
```

### Optimisation requêtes

```python
# Projection précoce (sélectionner colonnes tôt)
# BAD
df_bad = spark.table("large_table").filter("date > '2024-01-01'").select("id", "amount")

# GOOD
df_good = spark.table("large_table").select("id", "amount", "date").filter("date > '2024-01-01'")

# Predicate pushdown
df = spark.read.format("delta") \
    .load("Tables/sales") \
    .where("amount > 1000")  # Filtre poussé au niveau storage

# Broadcast join (petite table)
from pyspark.sql.functions import broadcast
result = large_df.join(broadcast(small_dim_df), "key")
```

### Spark tuning configuration

```python
# Configuration optimale (dans notebook)
spark.conf.set("spark.sql.shuffle.partitions", "200")  # Ajuster selon la taille
spark.conf.set("spark.sql.adaptive.enabled", "true")   # AQE
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")

# Memory tuning
spark.conf.set("spark.executor.memory", "8g")
spark.conf.set("spark.driver.memory", "4g")

# Broadcast threshold
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "10485760")  # 10MB
```

### Handling data skew

```python
from pyspark.sql.functions import col, rand

# Ajouter une clé de salting
df_salted = df.withColumn("salt", (rand() * 10).cast("int"))

# Join avec salting
result = df_salted.join(
    dim_df.crossJoin(spark.range(0, 10).toDF("salt")),
    ["key", "salt"]
)

# Retirer salt
result = result.drop("salt")
```

### Monitoring

```python
# Statistiques de table
spark.sql("ANALYZE TABLE sales_table COMPUTE STATISTICS")

# Describe detail
spark.sql("DESCRIBE DETAIL sales_table").show()

# History
spark.sql("DESCRIBE HISTORY sales_table").show(truncate=False)

# Voir les metrics d'un job
from pyspark import TaskContext
def get_partition_id():
    return TaskContext.get().partitionId()

# Query plan
df.explain(mode="extended")
```

## Performance benchmarks

### Lecture performance (exemple typique)

| Configuration | Temps lecture 1GB | CU consommées |
|--------------|-------------------|---------------|
| Parquet non partitionné | 45s | 12 CU |
| Parquet partitionné | 12s | 4 CU |
| Delta sans V-Order | 8s | 3 CU |
| Delta avec V-Order | 3s | 1.5 CU |

### Spark job optimization

| Métrique | Avant | Après | Gain |
|----------|-------|-------|------|
| Durée totale | 15 min | 4 min | 73% |
| Shuffle read | 50 GB | 10 GB | 80% |
| Spill to disk | 20 GB | 0 GB | 100% |

## Checklist d'optimisation

### Tables Delta
- [ ] V-Order activé sur tables fréquemment lues
- [ ] Partitionnement approprié (pas trop, pas trop peu)
- [ ] OPTIMIZE exécuté régulièrement
- [ ] VACUUM pour nettoyer anciennes versions
- [ ] Z-ordering sur colonnes de filtrage

### Spark Jobs
- [ ] Nombre de partitions adapté à la taille des données
- [ ] Broadcast joins pour petites tables (<10MB)
- [ ] Pas de data skew
- [ ] Configuration mémoire appropriée
- [ ] AQE activé

### Requêtes
- [ ] Filtres appliqués tôt
- [ ] Projection (select) minimale
- [ ] Pas de `SELECT *`
- [ ] Statistiques à jour
- [ ] Execution plans analysés

### Power BI / DAX
- [ ] Mesures optimisées avec variables
- [ ] DirectLake utilisé quand possible
- [ ] Pas de colonnes calculées inutiles
- [ ] Aggregations configurées
- [ ] RLS efficace

## Ressources complémentaires

### Documentation officielle
- [V-Order in Fabric](https://learn.microsoft.com/fabric/data-engineering/delta-optimization-and-v-order)
- [Spark performance tuning](https://spark.apache.org/docs/latest/tuning.html)
- [Capacity metrics](https://learn.microsoft.com/fabric/enterprise/metrics-app)

### Guides
- [Delta Lake performance](https://docs.delta.io/latest/optimizations-oss.html)
- [Power BI optimization](https://learn.microsoft.com/power-bi/guidance/power-bi-optimization)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 4-5 heures
- **Total** : 8-10 heures

## Prochaine étape

➡️ [Module 12 - Administration & Monitoring](../12-Administration-Monitoring/)

---

[⬅️ Module précédent](../10-Data-Science-ML/) | [⬅️ Retour au sommaire](../README.md)
