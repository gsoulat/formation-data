# RDD Basics - Resilient Distributed Datasets

## Table des matières

1. [Introduction aux RDDs](#introduction-aux-rdds)
2. [Création de RDDs](#création-de-rdds)
3. [Transformations](#transformations)
4. [Actions](#actions)
5. [Lazy Evaluation](#lazy-evaluation)
6. [Partitionnement](#partitionnement)
7. [Persistence et Cache](#persistence-et-cache)
8. [Exemples pratiques](#exemples-pratiques)

---

## Introduction aux RDDs

### Qu'est-ce qu'un RDD ?

**RDD (Resilient Distributed Dataset)** est la structure de données fondamentale de Spark. C'est une collection immuable et distribuée d'objets qui peut être traitée en parallèle.

### Caractéristiques des RDDs

**Resilient (Résilient)**
- Tolérant aux pannes grâce au lineage (DAG)
- Si une partition est perdue, elle peut être recalculée
- Pas besoin de réplication des données

**Distributed (Distribué)**
- Les données sont divisées en partitions
- Chaque partition peut être traitée sur un nœud différent
- Parallélisme automatique

**Immutable (Immuable)**
- Une fois créé, un RDD ne peut pas être modifié
- Les transformations créent de nouveaux RDDs
- Facilite la tolérance aux pannes

### RDD vs DataFrame

| Caractéristique | RDD | DataFrame |
|-----------------|-----|-----------|
| **Niveau** | Bas niveau | Haut niveau |
| **Optimisation** | Manuelle | Automatique (Catalyst) |
| **Type checking** | Compile-time | Runtime |
| **API** | Fonctionnelle | SQL + Fonctionnelle |
| **Performance** | Moins rapide | Plus rapide |
| **Cas d'usage** | Contrôle fin | Usage général |

**Recommandation** : Utilisez DataFrame par défaut, RDD pour des cas spécifiques nécessitant un contrôle total.

---

## Création de RDDs

### 1. À partir d'une collection (parallelize)

```python
from pyspark import SparkContext

sc = SparkContext("local[*]", "RDD Demo")

# Liste Python → RDD
numbers = [1, 2, 3, 4, 5]
rdd = sc.parallelize(numbers)

print(rdd.collect())  # [1, 2, 3, 4, 5]
```

**Avec nombre de partitions**

```python
# 4 partitions
rdd = sc.parallelize(range(1, 101), numSlices=4)
print(f"Partitions: {rdd.getNumPartitions()}")  # 4
```

### 2. À partir d'un fichier texte

```python
# Lire un fichier texte
rdd = sc.textFile("data/logs.txt")

# Lire plusieurs fichiers
rdd = sc.textFile("data/*.txt")

# Lire depuis HDFS
rdd = sc.textFile("hdfs://namenode:9000/data/file.txt")

# Lire depuis S3
rdd = sc.textFile("s3a://bucket/data/file.txt")
```

### 3. À partir d'autres RDDs (transformations)

```python
rdd1 = sc.parallelize([1, 2, 3])
rdd2 = rdd1.map(lambda x: x * 2)  # Nouveau RDD [2, 4, 6]
```

### 4. À partir d'un DataFrame

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

# DataFrame → RDD
df = spark.range(10)
rdd = df.rdd

print(rdd.collect())  # [Row(id=0), Row(id=1), ...]
```

---

## Transformations

Les transformations sont **lazy** (paresseuses) : elles ne sont pas exécutées immédiatement.

### map()

Applique une fonction à chaque élément.

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])
rdd_squared = rdd.map(lambda x: x ** 2)

print(rdd_squared.collect())  # [1, 4, 9, 16, 25]
```

**Cas d'usage** : Transformer chaque ligne (parser JSON, extraire champs).

```python
# Parser JSON
json_rdd = sc.parallelize(['{"name": "Alice"}', '{"name": "Bob"}'])
import json
names_rdd = json_rdd.map(lambda line: json.loads(line)['name'])
print(names_rdd.collect())  # ['Alice', 'Bob']
```

### filter()

Garde seulement les éléments qui satisfont une condition.

```python
rdd = sc.parallelize([1, 2, 3, 4, 5, 6])
even_rdd = rdd.filter(lambda x: x % 2 == 0)

print(even_rdd.collect())  # [2, 4, 6]
```

**Cas d'usage** : Filtrer des logs, nettoyer des données.

```python
# Filtrer les lignes d'erreur dans des logs
logs = sc.textFile("logs.txt")
errors = logs.filter(lambda line: "ERROR" in line)
```

### flatMap()

Comme `map()`, mais "aplatit" les résultats (1 élément → N éléments).

```python
rdd = sc.parallelize(["Hello World", "Apache Spark"])
words_rdd = rdd.flatMap(lambda line: line.split(" "))

print(words_rdd.collect())  # ['Hello', 'World', 'Apache', 'Spark']
```

**Différence map() vs flatMap()**

```python
rdd = sc.parallelize(["a b", "c d"])

# map() → retourne des listes
map_result = rdd.map(lambda x: x.split(" "))
print(map_result.collect())  # [['a', 'b'], ['c', 'd']]

# flatMap() → aplatit les listes
flatmap_result = rdd.flatMap(lambda x: x.split(" "))
print(flatmap_result.collect())  # ['a', 'b', 'c', 'd']
```

### distinct()

Élimine les doublons.

```python
rdd = sc.parallelize([1, 2, 2, 3, 3, 3, 4])
unique_rdd = rdd.distinct()

print(unique_rdd.collect())  # [1, 2, 3, 4]
```

**Attention** : `distinct()` déclenche un shuffle (coûteux).

### union()

Combine deux RDDs (union).

```python
rdd1 = sc.parallelize([1, 2, 3])
rdd2 = sc.parallelize([3, 4, 5])
union_rdd = rdd1.union(rdd2)

print(union_rdd.collect())  # [1, 2, 3, 3, 4, 5]
```

### intersection()

Garde les éléments présents dans les deux RDDs.

```python
rdd1 = sc.parallelize([1, 2, 3, 4])
rdd2 = sc.parallelize([3, 4, 5, 6])
inter_rdd = rdd1.intersection(rdd2)

print(inter_rdd.collect())  # [3, 4]
```

### subtract()

Soustrait un RDD d'un autre.

```python
rdd1 = sc.parallelize([1, 2, 3, 4])
rdd2 = sc.parallelize([3, 4])
diff_rdd = rdd1.subtract(rdd2)

print(diff_rdd.collect())  # [1, 2]
```

### Transformations sur Pair RDDs (key-value)

```python
# Créer un RDD de paires (key, value)
pairs_rdd = sc.parallelize([("a", 1), ("b", 2), ("a", 3)])

# groupByKey() - Grouper par clé
grouped = pairs_rdd.groupByKey()
print([(k, list(v)) for k, v in grouped.collect()])
# [('a', [1, 3]), ('b', [2])]

# reduceByKey() - Réduire par clé (plus efficace que groupByKey)
reduced = pairs_rdd.reduceByKey(lambda x, y: x + y)
print(reduced.collect())  # [('a', 4), ('b', 2)]

# mapValues() - Transformer seulement les valeurs
mapped = pairs_rdd.mapValues(lambda x: x * 10)
print(mapped.collect())  # [('a', 10), ('b', 20), ('a', 30)]

# keys() et values()
print(pairs_rdd.keys().collect())    # ['a', 'b', 'a']
print(pairs_rdd.values().collect())  # [1, 2, 3]
```

---

## Actions

Les actions **déclenchent l'exécution** et retournent un résultat au driver.

### collect()

Récupère tous les éléments du RDD dans le driver.

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])
result = rdd.collect()

print(result)  # [1, 2, 3, 4, 5]
print(type(result))  # <class 'list'>
```

**⚠️ Attention** : N'utilisez pas `collect()` sur de gros datasets (risque OutOfMemory).

### count()

Compte le nombre d'éléments.

```python
rdd = sc.parallelize(range(1000))
count = rdd.count()

print(count)  # 1000
```

### first()

Retourne le premier élément.

```python
rdd = sc.parallelize([5, 3, 8, 1])
first_elem = rdd.first()

print(first_elem)  # 5
```

### take(n)

Retourne les n premiers éléments.

```python
rdd = sc.parallelize(range(100))
first_5 = rdd.take(5)

print(first_5)  # [0, 1, 2, 3, 4]
```

### top(n)

Retourne les n plus grands éléments.

```python
rdd = sc.parallelize([3, 1, 8, 2, 5])
top_3 = rdd.top(3)

print(top_3)  # [8, 5, 3]
```

### reduce()

Agrège les éléments avec une fonction associative.

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])
sum_result = rdd.reduce(lambda x, y: x + y)

print(sum_result)  # 15
```

**Exemple : Maximum**

```python
max_value = rdd.reduce(lambda x, y: x if x > y else y)
print(max_value)  # 5
```

### foreach()

Applique une fonction à chaque élément (pour effets de bord).

```python
def print_element(x):
    print(f"Element: {x}")

rdd = sc.parallelize([1, 2, 3])
rdd.foreach(print_element)
```

**⚠️ Attention** : `foreach()` s'exécute sur les executors, pas le driver. Pour collecter, utilisez `collect()`.

### saveAsTextFile()

Sauvegarde le RDD dans des fichiers texte.

```python
rdd = sc.parallelize(["Hello", "World", "Spark"])
rdd.saveAsTextFile("output/words")

# Crée : output/words/part-00000, part-00001, etc.
```

---

## Lazy Evaluation

**Principe** : Les transformations ne sont pas exécutées immédiatement. Spark construit un DAG (Directed Acyclic Graph) et optimise l'exécution.

### Exemple

```python
# Ces lignes ne déclenchent AUCUNE exécution
rdd1 = sc.parallelize(range(1000000))           # Transformation
rdd2 = rdd1.filter(lambda x: x % 2 == 0)        # Transformation
rdd3 = rdd2.map(lambda x: x * 2)                # Transformation

# Cette ligne déclenche TOUTE l'exécution
result = rdd3.take(10)  # Action
```

### Pourquoi c'est utile ?

**1. Optimisations**

Spark peut fusionner les opérations pour minimiser les passes sur les données.

```python
# Sans optimisation : 2 passes
# Passe 1 : filter
# Passe 2 : map

# Avec optimisation : 1 seule passe
# Spark fusionne filter + map
```

**2. Pas de calculs inutiles**

```python
rdd = sc.parallelize(range(1000000))
filtered = rdd.filter(lambda x: x > 999990)
result = filtered.take(5)

# Spark s'arrête dès qu'il a trouvé 5 éléments
# Pas besoin de scanner les 1 million d'éléments
```

### Lineage (DAG)

```python
rdd1 = sc.parallelize([1, 2, 3])
rdd2 = rdd1.map(lambda x: x * 2)
rdd3 = rdd2.filter(lambda x: x > 3)

# Voir le lineage
print(rdd3.toDebugString().decode())

# (4) PythonRDD[3] at RDD at PythonRDD.scala:53 []
#  |  MapPartitionsRDD[2] at map at PythonRDD.scala:153 []
#  |  ParallelCollectionRDD[0] at parallelize at PythonRDD.scala:195 []
```

---

## Partitionnement

Les RDDs sont divisés en **partitions** pour permettre le traitement parallèle.

### Nombre de partitions

```python
rdd = sc.parallelize(range(100), numSlices=4)
print(f"Partitions: {rdd.getNumPartitions()}")  # 4
```

### Voir le contenu des partitions

```python
rdd = sc.parallelize([1, 2, 3, 4, 5, 6], numSlices=3)

def show_partition(index, iterator):
    yield f"Partition {index}: {list(iterator)}"

partitions_content = rdd.mapPartitionsWithIndex(show_partition).collect()
for content in partitions_content:
    print(content)

# Partition 0: [1, 2]
# Partition 1: [3, 4]
# Partition 2: [5, 6]
```

### repartition()

Augmente ou diminue le nombre de partitions (déclenche un shuffle).

```python
rdd = sc.parallelize(range(100), numSlices=2)
print(rdd.getNumPartitions())  # 2

rdd_repartitioned = rdd.repartition(8)
print(rdd_repartitioned.getNumPartitions())  # 8
```

### coalesce()

Diminue le nombre de partitions SANS shuffle (plus efficace).

```python
rdd = sc.parallelize(range(100), numSlices=10)
rdd_coalesced = rdd.coalesce(2)
print(rdd_coalesced.getNumPartitions())  # 2
```

**repartition() vs coalesce()**

```python
# Augmenter : utiliser repartition()
rdd.repartition(20)

# Diminuer : utiliser coalesce() (plus rapide)
rdd.coalesce(5)
```

### Partitionnement par clé (Pair RDDs)

```python
pairs = sc.parallelize([("a", 1), ("b", 2), ("a", 3), ("c", 4)])

# partitionBy() - Partitionner par hash de la clé
partitioned = pairs.partitionBy(3)  # 3 partitions

# Avantage : Les opérations comme join() et groupByKey()
# seront plus rapides si les données sont bien partitionnées
```

---

## Persistence et Cache

Par défaut, les RDDs sont recalculés à chaque action. Avec `cache()` ou `persist()`, on peut les garder en mémoire.

### cache()

Garde le RDD en mémoire.

```python
rdd = sc.parallelize(range(1000000))
filtered = rdd.filter(lambda x: x % 2 == 0)

# Cache le RDD en mémoire
filtered.cache()

# Première action : calcule et met en cache
count1 = filtered.count()  # Calcul

# Deuxième action : utilise le cache
count2 = filtered.count()  # Rapide (depuis cache)
```

### persist()

Choisit le niveau de stockage.

```python
from pyspark import StorageLevel

rdd = sc.parallelize(range(1000000))

# Options de storage
rdd.persist(StorageLevel.MEMORY_ONLY)          # En mémoire uniquement
rdd.persist(StorageLevel.MEMORY_AND_DISK)      # Mémoire + disque si déborde
rdd.persist(StorageLevel.DISK_ONLY)            # Disque uniquement
rdd.persist(StorageLevel.MEMORY_ONLY_SER)      # Mémoire sérialisé (économise RAM)
```

### Quand utiliser le cache ?

**✅ Utilisez cache() quand :**
- Le RDD est réutilisé plusieurs fois
- Le calcul est coûteux
- Le dataset tient en mémoire

**❌ N'utilisez PAS cache() quand :**
- Le RDD n'est utilisé qu'une fois
- Le dataset est trop gros pour la mémoire
- Les transformations sont simples et rapides

### unpersist()

Libère le cache.

```python
rdd.cache()
# ... utilisation ...
rdd.unpersist()
```

---

## Exemples pratiques

### 1. Word Count (classique)

```python
# Lire un fichier texte
lines = sc.textFile("data/book.txt")

# Split en mots
words = lines.flatMap(lambda line: line.split(" "))

# Créer paires (mot, 1)
word_pairs = words.map(lambda word: (word, 1))

# Compter par mot
word_counts = word_pairs.reduceByKey(lambda x, y: x + y)

# Trier par fréquence
sorted_counts = word_counts.sortBy(lambda pair: pair[1], ascending=False)

# Top 10 mots
top_10 = sorted_counts.take(10)
print(top_10)
```

**Version compacte**

```python
word_counts = sc.textFile("data/book.txt") \
    .flatMap(lambda line: line.split(" ")) \
    .map(lambda word: (word, 1)) \
    .reduceByKey(lambda x, y: x + y) \
    .sortBy(lambda pair: pair[1], ascending=False)

print(word_counts.take(10))
```

### 2. Analyser des logs

```python
# Lire logs
logs = sc.textFile("data/access.log")

# Filtrer les erreurs 404
errors_404 = logs.filter(lambda line: "404" in line)

# Compter
error_count = errors_404.count()
print(f"Erreurs 404 : {error_count}")

# Extraire les URLs en erreur
def extract_url(line):
    # Exemple: "GET /page.html 404"
    parts = line.split()
    if len(parts) > 1:
        return parts[1]
    return None

error_urls = errors_404.map(extract_url).filter(lambda x: x is not None)
print(error_urls.distinct().collect())
```

### 3. Calcul de statistiques

```python
# Dataset de températures
temps = sc.parallelize([22.5, 18.3, 25.1, 19.8, 23.4, 21.0])

# Moyenne
mean = temps.reduce(lambda x, y: x + y) / temps.count()
print(f"Moyenne : {mean:.2f}")

# Min et Max
min_temp = temps.reduce(lambda x, y: x if x < y else y)
max_temp = temps.reduce(lambda x, y: x if x > y else y)
print(f"Min : {min_temp}, Max : {max_temp}")

# Utiliser des fonctions built-in
stats = temps.stats()  # Retourne count, mean, stdev, max, min
print(stats)
```

### 4. Filtrage avancé

```python
# Dataset de ventes
sales = sc.parallelize([
    ("2024-01-01", "Product A", 100),
    ("2024-01-01", "Product B", 150),
    ("2024-01-02", "Product A", 200),
    ("2024-01-02", "Product C", 80),
])

# Filtrer par date
jan_01 = sales.filter(lambda s: s[0] == "2024-01-01")

# Calculer revenus par produit
product_revenue = sales.map(lambda s: (s[1], s[2])) \
    .reduceByKey(lambda x, y: x + y)

print(product_revenue.collect())
# [('Product A', 300), ('Product B', 150), ('Product C', 80)]
```

---

## Exercices

### Exercice 1 : Compter les nombres pairs

```python
# Créer un RDD de 1 à 100
# Filtrer les nombres pairs
# Compter combien il y en a
```

<details>
<summary>Solution</summary>

```python
rdd = sc.parallelize(range(1, 101))
even_count = rdd.filter(lambda x: x % 2 == 0).count()
print(even_count)  # 50
```
</details>

### Exercice 2 : Moyenne des nombres

```python
# Créer un RDD [10, 20, 30, 40, 50]
# Calculer la moyenne avec reduce()
```

<details>
<summary>Solution</summary>

```python
rdd = sc.parallelize([10, 20, 30, 40, 50])
total = rdd.reduce(lambda x, y: x + y)
count = rdd.count()
average = total / count
print(average)  # 30.0
```
</details>

### Exercice 3 : Top 5 mots

```python
# Prendre le texte : "spark is fast spark is awesome spark is distributed"
# Trouver les 5 mots les plus fréquents
```

<details>
<summary>Solution</summary>

```python
text = "spark is fast spark is awesome spark is distributed"
words = sc.parallelize(text.split())

word_counts = words.map(lambda w: (w, 1)) \
    .reduceByKey(lambda x, y: x + y) \
    .sortBy(lambda pair: pair[1], ascending=False)

print(word_counts.take(5))
# [('spark', 3), ('is', 3), ('fast', 1), ('awesome', 1), ('distributed', 1)]
```
</details>

---

## Bonnes pratiques

### 1. Préférez DataFrame à RDD

```python
# ❌ Évitez
rdd = sc.textFile("data.csv") \
    .map(lambda line: line.split(",")) \
    .filter(lambda fields: int(fields[2]) > 18)

# ✅ Préférez
df = spark.read.csv("data.csv", header=True, inferSchema=True)
df_filtered = df.filter(df.age > 18)
```

### 2. Évitez les collect() sur gros datasets

```python
# ❌ Risque OutOfMemory
all_data = huge_rdd.collect()

# ✅ Utilisez take() ou saveAsTextFile()
sample = huge_rdd.take(100)
huge_rdd.saveAsTextFile("output/")
```

### 3. Utilisez reduceByKey() plutôt que groupByKey()

```python
# ❌ groupByKey() transfert toutes les valeurs
grouped = pairs.groupByKey().mapValues(sum)

# ✅ reduceByKey() réduit localement d'abord
reduced = pairs.reduceByKey(lambda x, y: x + y)
```

### 4. Partitionnez intelligemment

```python
# Règle de base : 2-3x le nombre de CPU cores
num_cores = 8
rdd = sc.parallelize(data, numSlices=num_cores * 2)
```

---

## Résumé des principales opérations

### Transformations (lazy)

| Opération | Description | Exemple |
|-----------|-------------|---------|
| `map(f)` | Applique f à chaque élément | `rdd.map(lambda x: x * 2)` |
| `filter(f)` | Garde éléments où f retourne True | `rdd.filter(lambda x: x > 10)` |
| `flatMap(f)` | Map + aplatit | `rdd.flatMap(lambda x: x.split())` |
| `distinct()` | Élimine doublons | `rdd.distinct()` |
| `union(rdd2)` | Union de deux RDDs | `rdd1.union(rdd2)` |
| `intersection(rdd2)` | Intersection | `rdd1.intersection(rdd2)` |
| `reduceByKey(f)` | Réduit par clé | `pairs.reduceByKey(lambda x,y: x+y)` |
| `groupByKey()` | Groupe par clé | `pairs.groupByKey()` |

### Actions (eager)

| Opération | Description | Exemple |
|-----------|-------------|---------|
| `collect()` | Récupère tous les éléments | `rdd.collect()` |
| `count()` | Compte les éléments | `rdd.count()` |
| `first()` | Premier élément | `rdd.first()` |
| `take(n)` | n premiers | `rdd.take(10)` |
| `reduce(f)` | Agrégation | `rdd.reduce(lambda x,y: x+y)` |
| `foreach(f)` | Applique f (side effects) | `rdd.foreach(print)` |
| `saveAsTextFile()` | Sauve en fichiers | `rdd.saveAsTextFile("out/")` |

---

## Prochaines étapes

Maintenant que vous maîtrisez les RDDs, passez au module suivant :
**[04-DataFrames-API](../04-DataFrames-API/README.md)**

Les DataFrames sont une abstraction haut niveau au-dessus des RDDs, avec optimisations automatiques et API plus simple.
