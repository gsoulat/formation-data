"""
RDD Transformations - Transformations courantes sur les RDDs

Ce script démontre les transformations les plus utilisées :
- map, filter, flatMap
- distinct, union, intersection
- reduceByKey, groupByKey, mapValues
"""

from pyspark import SparkContext, SparkConf

# Configuration Spark
conf = SparkConf().setAppName("RDD Transformations").setMaster("local[*]")
sc = SparkContext(conf=conf)

print("=" * 80)
print("RDD TRANSFORMATIONS EXAMPLES")
print("=" * 80)

# ========================================
# 1. map() - Transformer chaque élément
# ========================================
print("\n1. map() - Transformer chaque élément")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])
squared = numbers.map(lambda x: x ** 2)

print(f"Original : {numbers.collect()}")
print(f"Au carré : {squared.collect()}")

# Exemple avec strings
names = sc.parallelize(["alice", "bob", "charlie"])
upper_names = names.map(lambda x: x.upper())
print(f"Noms originaux : {names.collect()}")
print(f"En majuscules : {upper_names.collect()}")

# ========================================
# 2. filter() - Filtrer les éléments
# ========================================
print("\n2. filter() - Filtrer les éléments")
print("-" * 50)

numbers = sc.parallelize(range(1, 11))
even_numbers = numbers.filter(lambda x: x % 2 == 0)
greater_than_5 = numbers.filter(lambda x: x > 5)

print(f"Nombres : {numbers.collect()}")
print(f"Pairs : {even_numbers.collect()}")
print(f"> 5 : {greater_than_5.collect()}")

# ========================================
# 3. flatMap() - Map + Aplatir
# ========================================
print("\n3. flatMap() - Map et aplatir")
print("-" * 50)

sentences = sc.parallelize([
    "Hello World",
    "Apache Spark is fast",
    "Big Data Processing"
])

# map() retourne des listes
words_with_map = sentences.map(lambda x: x.split(" "))
print(f"Avec map() : {words_with_map.collect()}")

# flatMap() aplatit
words_with_flatmap = sentences.flatMap(lambda x: x.split(" "))
print(f"Avec flatMap() : {words_with_flatmap.collect()}")

# ========================================
# 4. distinct() - Éliminer les doublons
# ========================================
print("\n4. distinct() - Éliminer les doublons")
print("-" * 50)

numbers_with_duplicates = sc.parallelize([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
unique_numbers = numbers_with_duplicates.distinct()

print(f"Avec doublons : {numbers_with_duplicates.collect()}")
print(f"Sans doublons : {unique_numbers.collect()}")

# ========================================
# 5. union() - Combiner deux RDDs
# ========================================
print("\n5. union() - Combiner deux RDDs")
print("-" * 50)

rdd1 = sc.parallelize([1, 2, 3])
rdd2 = sc.parallelize([3, 4, 5])
union_rdd = rdd1.union(rdd2)

print(f"RDD 1 : {rdd1.collect()}")
print(f"RDD 2 : {rdd2.collect()}")
print(f"Union : {union_rdd.collect()}")
print(f"Union sans doublons : {union_rdd.distinct().collect()}")

# ========================================
# 6. intersection() - Intersection de deux RDDs
# ========================================
print("\n6. intersection() - Intersection")
print("-" * 50)

rdd1 = sc.parallelize([1, 2, 3, 4, 5])
rdd2 = sc.parallelize([3, 4, 5, 6, 7])
inter = rdd1.intersection(rdd2)

print(f"RDD 1 : {rdd1.collect()}")
print(f"RDD 2 : {rdd2.collect()}")
print(f"Intersection : {inter.collect()}")

# ========================================
# 7. subtract() - Différence entre RDDs
# ========================================
print("\n7. subtract() - Différence")
print("-" * 50)

all_fruits = sc.parallelize(["apple", "banana", "orange", "grape", "kiwi"])
tropical = sc.parallelize(["banana", "kiwi", "mango"])
non_tropical = all_fruits.subtract(tropical)

print(f"Tous fruits : {all_fruits.collect()}")
print(f"Tropicaux : {tropical.collect()}")
print(f"Non tropicaux : {non_tropical.collect()}")

# ========================================
# 8. sample() - Échantillonner
# ========================================
print("\n8. sample() - Échantillonner des données")
print("-" * 50)

large_rdd = sc.parallelize(range(1, 101))
sample = large_rdd.sample(withReplacement=False, fraction=0.1, seed=42)

print(f"Dataset complet : {large_rdd.count()} éléments")
print(f"Échantillon (10%) : {sample.collect()}")

# ========================================
# 9. Transformations sur Pair RDDs - mapValues()
# ========================================
print("\n9. mapValues() - Transformer seulement les valeurs")
print("-" * 50)

pairs = sc.parallelize([("a", 1), ("b", 2), ("c", 3)])
multiplied = pairs.mapValues(lambda x: x * 10)

print(f"Pairs originales : {pairs.collect()}")
print(f"Valeurs x10 : {multiplied.collect()}")

# ========================================
# 10. keys() et values()
# ========================================
print("\n10. keys() et values()")
print("-" * 50)

pairs = sc.parallelize([("name", "Alice"), ("age", 25), ("city", "Paris")])

print(f"Pairs : {pairs.collect()}")
print(f"Clés : {pairs.keys().collect()}")
print(f"Valeurs : {pairs.values().collect()}")

# ========================================
# 11. groupByKey() - Grouper par clé
# ========================================
print("\n11. groupByKey() - Grouper par clé")
print("-" * 50)

sales = sc.parallelize([
    ("apple", 5),
    ("banana", 3),
    ("apple", 8),
    ("orange", 2),
    ("banana", 7)
])

grouped = sales.groupByKey()
# Convertir les valeurs en liste
grouped_list = grouped.mapValues(list)

print(f"Sales originales : {sales.collect()}")
print(f"Groupées par produit :")
for product, quantities in grouped_list.collect():
    print(f"  {product}: {quantities}")

# ========================================
# 12. reduceByKey() - Réduire par clé
# ========================================
print("\n12. reduceByKey() - Réduire par clé (RECOMMANDÉ)")
print("-" * 50)

sales = sc.parallelize([
    ("apple", 5),
    ("banana", 3),
    ("apple", 8),
    ("orange", 2),
    ("banana", 7)
])

# Somme par produit
total_by_product = sales.reduceByKey(lambda x, y: x + y)

print(f"Sales originales : {sales.collect()}")
print(f"Total par produit : {total_by_product.collect()}")

# ========================================
# 13. sortBy() et sortByKey()
# ========================================
print("\n13. sortBy() et sortByKey()")
print("-" * 50)

numbers = sc.parallelize([5, 2, 8, 1, 9, 3])
sorted_asc = numbers.sortBy(lambda x: x)
sorted_desc = numbers.sortBy(lambda x: x, ascending=False)

print(f"Original : {numbers.collect()}")
print(f"Trié (croissant) : {sorted_asc.collect()}")
print(f"Trié (décroissant) : {sorted_desc.collect()}")

# Avec pairs
pairs = sc.parallelize([("z", 1), ("a", 3), ("m", 2)])
sorted_by_key = pairs.sortByKey()
print(f"Pairs triées par clé : {sorted_by_key.collect()}")

# ========================================
# 14. join() - Joindre deux RDDs
# ========================================
print("\n14. join() - Joindre deux Pair RDDs")
print("-" * 50)

users = sc.parallelize([
    (1, "Alice"),
    (2, "Bob"),
    (3, "Charlie")
])

scores = sc.parallelize([
    (1, 95),
    (2, 87),
    (4, 92)  # Pas de user avec id=4
])

joined = users.join(scores)
print(f"Users : {users.collect()}")
print(f"Scores : {scores.collect()}")
print(f"Inner Join : {joined.collect()}")

# Left outer join
left_joined = users.leftOuterJoin(scores)
print(f"Left Outer Join : {left_joined.collect()}")

# ========================================
# 15. cartesian() - Produit cartésien
# ========================================
print("\n15. cartesian() - Produit cartésien")
print("-" * 50)

colors = sc.parallelize(["red", "blue"])
sizes = sc.parallelize(["S", "M", "L"])
combinations = colors.cartesian(sizes)

print(f"Couleurs : {colors.collect()}")
print(f"Tailles : {sizes.collect()}")
print(f"Combinaisons : {combinations.collect()}")

# ========================================
# 16. Exemple complet : Word Count
# ========================================
print("\n16. Exemple complet : Word Count")
print("-" * 50)

text = """
Apache Spark is fast
Spark is easy
Spark is powerful
"""

lines = sc.parallelize(text.strip().split("\n"))

word_counts = lines.flatMap(lambda line: line.split()) \
    .map(lambda word: (word.lower(), 1)) \
    .reduceByKey(lambda x, y: x + y) \
    .sortBy(lambda pair: pair[1], ascending=False)

print("Word counts:")
for word, count in word_counts.collect():
    print(f"  {word}: {count}")

# ========================================
# Récapitulatif
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DES TRANSFORMATIONS")
print("=" * 80)

print("""
Transformations de base:
  - map(f)           : Applique f à chaque élément
  - filter(f)        : Garde éléments où f retourne True
  - flatMap(f)       : Map puis aplatit les résultats
  - distinct()       : Élimine les doublons

Opérations sur ensembles:
  - union(rdd2)      : Combine deux RDDs
  - intersection(rdd2): Éléments communs
  - subtract(rdd2)   : Différence

Pair RDD (key-value):
  - mapValues(f)     : Transforme seulement les valeurs
  - reduceByKey(f)   : Réduit par clé (RECOMMANDÉ)
  - groupByKey()     : Groupe par clé (éviter si possible)
  - sortByKey()      : Trie par clé
  - join()           : Joint deux Pair RDDs

Note: Toutes ces transformations sont LAZY (pas d'exécution immédiate)
""")

# Arrêter SparkContext
sc.stop()
print("✅ SparkContext arrêté")
