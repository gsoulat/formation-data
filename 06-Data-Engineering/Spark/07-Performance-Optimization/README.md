# Performance Optimization - Optimiser les performances Spark

## Table des matières

1. [Principes d'optimisation](#principes-doptimisation)
2. [Partitionnement](#partitionnement)
3. [Caching et Persistence](#caching-et-persistence)
4. [Broadcast Variables](#broadcast-variables)
5. [Optimisations Catalyst](#optimisations-catalyst)
6. [Configuration Spark](#configuration-spark)
7. [Bonnes pratiques](#bonnes-pratiques)

---

## Principes d'optimisation

### Goulots d'étranglement courants

1. **Shuffle** : Répartition des données entre partitions (coûteux)
2. **Spill to disk** : Débordement mémoire → disque
3. **Data skew** : Déséquilibre de données entre partitions
4. **Small files** : Trop de petits fichiers
5. **Large partitions** : Partitions trop grosses

### Méthode d'optimisation

```
1. Mesurer (Spark UI, métriques)
2. Identifier le goulot
3. Optimiser
4. Re-mesurer
```

---

## Partitionnement

### Nombre de partitions optimal

```python
# Règle de base: 2-4x le nombre de cores
num_cores = 8
num_partitions = num_cores * 3  # 24 partitions

df = df.repartition(num_partitions)
```

### Repartition vs Coalesce

```python
# repartition() : Augmente OU diminue (avec shuffle)
df = df.repartition(100)  # Shuffle

# coalesce() : Diminue SANS shuffle (plus rapide)
df = df.coalesce(10)  # Pas de shuffle
```

**Quand utiliser** :
- `repartition()` : Rééquilibrer, augmenter partitions
- `coalesce()` : Réduire partitions avant écriture

### Partitionner par clé

```python
# Partitionner par colonne (utile avant groupBy/join)
df = df.repartition(100, "user_id")

# Les données du même user_id iront dans la même partition
```

### Taille de partition idéale

```
Taille idéale: 128 MB - 1 GB par partition

Trop petites (< 10 MB): Overhead de gestion
Trop grosses (> 2 GB): Risque OOM, lenteur
```

---

## Caching et Persistence

### Quand utiliser cache()

```python
# DataFrame réutilisé plusieurs fois
df_filtered = df.filter(col("age") > 25)
df_filtered.cache()

# Multiples opérations
count = df_filtered.count()
stats = df_filtered.describe()
aggregated = df_filtered.groupBy("city").count()

# Libérer quand fini
df_filtered.unpersist()
```

### Niveaux de persistence

```python
from pyspark import StorageLevel

# En mémoire uniquement
df.persist(StorageLevel.MEMORY_ONLY)

# Mémoire + disque si déborde
df.persist(StorageLevel.MEMORY_AND_DISK)

# Mémoire sérialisé (économise RAM)
df.persist(StorageLevel.MEMORY_ONLY_SER)

# Disque uniquement
df.persist(StorageLevel.DISK_ONLY)
```

**Recommandation** : `MEMORY_AND_DISK` pour la plupart des cas.

### Quand NE PAS cacher

- DataFrame utilisé une seule fois
- Dataset trop gros pour la mémoire
- Transformations simples et rapides

---

## Broadcast Variables

### Broadcast Join

Pour joindre une **petite table** (< 10 MB) avec une **grande table** :

```python
from pyspark.sql.functions import broadcast

# Sans broadcast (shuffle join - lent)
result = large_df.join(small_df, "id")

# Avec broadcast (broadcast join - rapide)
result = large_df.join(broadcast(small_df), "id")
```

**Avantages** :
- Pas de shuffle
- Petite table envoyée à tous les executors
- Beaucoup plus rapide

**Limite** : Table < 10 MB (configurable)

### Configuration broadcast

```python
# Seuil pour auto-broadcast (défaut: 10 MB)
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", 10 * 1024 * 1024)

# Désactiver auto-broadcast
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", -1)
```

---

## Optimisations Catalyst

### Predicate Pushdown

```python
# Spark pousse le filtre au niveau de la lecture
df = spark.read.parquet("large_file.parquet") \
    .filter(col("date") == "2024-01-01")

# Parquet ne lit que les blocs nécessaires ✅
```

### Column Pruning

```python
# Spark ne lit que les colonnes utilisées
df = spark.read.parquet("large_file.parquet") \
    .select("id", "name")  # Ne lit que ces 2 colonnes ✅
```

### Join Reordering

Spark réordonne automatiquement les joins pour minimiser les shuffles.

### Voir le plan d'exécution

```python
# Voir les optimisations appliquées
df.explain(extended=True)

# Ou juste le plan physique
df.explain()
```

---

## Configuration Spark

### Configuration mémoire

```python
spark = SparkSession.builder \
    .appName("OptimizedApp") \
    .config("spark.driver.memory", "4g") \
    .config("spark.executor.memory", "8g") \
    .config("spark.executor.cores", "4") \
    .config("spark.executor.instances", "10") \
    .getOrCreate()
```

### Configuration shuffle

```python
# Nombre de partitions après shuffle
spark.conf.set("spark.sql.shuffle.partitions", "200")  # Défaut

# Ajuster selon votre dataset:
# Petit dataset: 50-100
# Moyen dataset: 200-500
# Gros dataset: 1000+
```

### Configuration compression

```python
# Compression Parquet
spark.conf.set("spark.sql.parquet.compression.codec", "snappy")

# Options: none, snappy, gzip, lzo, brotli, lz4, zstd
```

### Adaptive Query Execution (AQE)

Disponible depuis Spark 3.0 :

```python
# Activer AQE
spark.conf.set("spark.sql.adaptive.enabled", "true")

# AQE optimise dynamiquement:
# - Coalesce des partitions après shuffle
# - Conversion shuffle join → broadcast join
# - Gestion du data skew
```

---

## Bonnes pratiques

### 1. Éviter les shuffles inutiles

```python
# ❌ Plusieurs shuffles
df.repartition(100).groupBy("id").count().repartition(50)

# ✅ Un seul shuffle
df.repartition(100, "id").groupBy("id").count()
```

### 2. Utiliser reduceByKey au lieu de groupByKey

```python
# ❌ groupByKey transfert toutes les valeurs
rdd.groupByKey().mapValues(sum)

# ✅ reduceByKey réduit localement d'abord
rdd.reduceByKey(lambda x, y: x + y)
```

### 3. Filtrer tôt

```python
# ❌ Filtre après transformations
df.select(...).join(...).filter(col("age") > 25)

# ✅ Filtre au plus tôt
df.filter(col("age") > 25).select(...).join(...)
```

### 4. Utiliser Parquet

```python
# ❌ Lent
df = spark.read.csv("large_file.csv", inferSchema=True)

# ✅ Rapide (columnar, compression, predicate pushdown)
df = spark.read.parquet("large_file.parquet")
```

### 5. Partitionner les données

```python
# Écrire avec partitions
df.write.partitionBy("year", "month").parquet("output/")

# Lecture ciblée
df = spark.read.parquet("output/year=2024/month=01/")
```

### 6. Éviter les UDFs

```python
# ❌ UDF (empêche optimisations Catalyst)
@udf(StringType())
def upper(s):
    return s.upper()
df.withColumn("name_upper", upper(col("name")))

# ✅ Fonction built-in
from pyspark.sql.functions import upper
df.withColumn("name_upper", upper(col("name")))
```

### 7. Bucketing pour tables fréquemment jointes

```python
# Créer des buckets
df.write \
    .bucketBy(100, "user_id") \
    .sortBy("timestamp") \
    .saveAsTable("events_bucketed")

# Joins sans shuffle si même bucketing
```

---

## Debugging et monitoring

### Spark UI

Accédez à **http://localhost:4040** pendant l'exécution.

**Informations importantes** :
- **Jobs** : Durée, stages
- **Stages** : Tasks, shuffle read/write
- **Storage** : DataFrames cachés
- **Executors** : Mémoire, CPU usage
- **SQL** : Plans d'exécution

### Métriques à surveiller

1. **Shuffle Read/Write** : Plus c'est bas, mieux c'est
2. **Task Duration** : Chercher les tasks longues (data skew)
3. **GC Time** : Si > 10% du temps task, augmenter mémoire
4. **Spill to Disk** : Signe de mémoire insuffisante

### Logs

```python
# Définir le niveau de log
spark.sparkContext.setLogLevel("WARN")  # ERROR, WARN, INFO, DEBUG
```

---

## Checklist d'optimisation

- [ ] Schema explicite (pas `inferSchema`)
- [ ] Format Parquet pour stockage
- [ ] Partitionnement approprié (128 MB - 1 GB/partition)
- [ ] Cache pour DataFrames réutilisés
- [ ] Broadcast pour petites tables
- [ ] Filtrer au plus tôt
- [ ] Éviter les UDFs (utiliser built-in)
- [ ] `spark.sql.shuffle.partitions` ajusté
- [ ] AQE activé (Spark 3.0+)
- [ ] Monitoring via Spark UI

---

## Prochaines étapes

Module suivant : **[08-Spark-Streaming](../08-Spark-Streaming/README.md)**

Vous allez apprendre à :
- Traiter des données en temps réel
- Structured Streaming
- Intégration Kafka
- Window operations sur streams
