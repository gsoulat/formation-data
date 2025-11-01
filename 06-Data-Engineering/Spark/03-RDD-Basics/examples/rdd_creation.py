"""
RDD Creation - Différentes façons de créer des RDDs

Ce script montre comment créer des RDDs de différentes manières :
- À partir d'une collection Python (parallelize)
- À partir de fichiers texte
- À partir d'autres RDDs
"""

from pyspark import SparkContext, SparkConf

# Configuration Spark
conf = SparkConf().setAppName("RDD Creation Examples").setMaster("local[*]")
sc = SparkContext(conf=conf)

print("=" * 80)
print("RDD CREATION EXAMPLES")
print("=" * 80)

# ========================================
# 1. Créer un RDD à partir d'une liste Python
# ========================================
print("\n1. Créer RDD depuis une liste Python (parallelize)")
print("-" * 50)

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
numbers_rdd = sc.parallelize(numbers)

print(f"Liste originale : {numbers}")
print(f"RDD créé : {numbers_rdd.collect()}")
print(f"Nombre de partitions : {numbers_rdd.getNumPartitions()}")

# ========================================
# 2. Créer un RDD avec nombre de partitions spécifique
# ========================================
print("\n2. Créer RDD avec partitions spécifiques")
print("-" * 50)

numbers_4_partitions = sc.parallelize(range(1, 21), numSlices=4)
print(f"Données : {list(range(1, 21))}")
print(f"Nombre de partitions : {numbers_4_partitions.getNumPartitions()}")

# Voir le contenu de chaque partition
def show_partition_content(index, iterator):
    yield f"Partition {index}: {list(iterator)}"

partitions_info = numbers_4_partitions.mapPartitionsWithIndex(show_partition_content).collect()
for info in partitions_info:
    print(info)

# ========================================
# 3. Créer un RDD de paires (key-value)
# ========================================
print("\n3. Créer RDD de paires (key-value)")
print("-" * 50)

# Liste de tuples (clé, valeur)
pairs = [
    ("apple", 5),
    ("banana", 3),
    ("orange", 8),
    ("apple", 2),
    ("banana", 7)
]

pairs_rdd = sc.parallelize(pairs)
print(f"Pairs RDD : {pairs_rdd.collect()}")
print(f"Clés uniques : {pairs_rdd.keys().distinct().collect()}")

# ========================================
# 4. Créer un RDD depuis un fichier texte
# ========================================
print("\n4. Créer RDD depuis un fichier texte")
print("-" * 50)

# Créer un fichier texte d'exemple
sample_text = """Apache Spark is a unified analytics engine
for large-scale data processing.
Spark provides high-level APIs in Java, Scala, Python and R.
It is widely used for big data processing."""

# Écrire le fichier
with open("/tmp/spark_sample.txt", "w") as f:
    f.write(sample_text)

# Lire avec Spark
text_rdd = sc.textFile("/tmp/spark_sample.txt")
print(f"Nombre de lignes : {text_rdd.count()}")
print(f"Première ligne : {text_rdd.first()}")
print("\nToutes les lignes :")
for i, line in enumerate(text_rdd.collect(), 1):
    print(f"  Ligne {i}: {line}")

# ========================================
# 5. Créer un RDD depuis une range
# ========================================
print("\n5. Créer RDD depuis une range")
print("-" * 50)

range_rdd = sc.parallelize(range(0, 100, 5))  # 0 à 100 par pas de 5
print(f"RDD depuis range(0, 100, 5) : {range_rdd.collect()}")
print(f"Nombre d'éléments : {range_rdd.count()}")

# ========================================
# 6. Créer un RDD vide
# ========================================
print("\n6. Créer RDD vide")
print("-" * 50)

empty_rdd = sc.parallelize([])
print(f"RDD vide : {empty_rdd.collect()}")
print(f"Nombre d'éléments : {empty_rdd.count()}")
print(f"Est vide ? {empty_rdd.isEmpty()}")

# ========================================
# 7. Créer un RDD depuis un RDD existant (transformation)
# ========================================
print("\n7. Créer RDD depuis un autre RDD")
print("-" * 50)

original_rdd = sc.parallelize([1, 2, 3, 4, 5])
squared_rdd = original_rdd.map(lambda x: x ** 2)

print(f"RDD original : {original_rdd.collect()}")
print(f"RDD au carré : {squared_rdd.collect()}")

# ========================================
# 8. Créer un RDD de strings
# ========================================
print("\n8. Créer RDD de strings")
print("-" * 50)

fruits = ["apple", "banana", "cherry", "date", "elderberry"]
fruits_rdd = sc.parallelize(fruits)

print(f"Fruits : {fruits_rdd.collect()}")
print(f"Fruits en majuscules : {fruits_rdd.map(lambda x: x.upper()).collect()}")

# ========================================
# 9. Créer un RDD de dictionnaires
# ========================================
print("\n9. Créer RDD de dictionnaires")
print("-" * 50)

users = [
    {"name": "Alice", "age": 25, "city": "Paris"},
    {"name": "Bob", "age": 30, "city": "Lyon"},
    {"name": "Charlie", "age": 35, "city": "Marseille"}
]

users_rdd = sc.parallelize(users)
print(f"Users RDD (premier élément) : {users_rdd.first()}")
print(f"Noms : {users_rdd.map(lambda u: u['name']).collect()}")

# ========================================
# 10. Créer un RDD depuis plusieurs fichiers (pattern)
# ========================================
print("\n10. Créer RDD depuis plusieurs fichiers")
print("-" * 50)

# Créer plusieurs fichiers
for i in range(3):
    with open(f"/tmp/file_{i}.txt", "w") as f:
        f.write(f"Content of file {i}\n")
        f.write(f"Line 2 of file {i}\n")

# Lire tous les fichiers avec un pattern
multi_files_rdd = sc.textFile("/tmp/file_*.txt")
print(f"Nombre total de lignes : {multi_files_rdd.count()}")
print(f"Contenu :")
for line in multi_files_rdd.collect():
    print(f"  {line}")

# ========================================
# Récapitulatif
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DES MÉTHODES DE CRÉATION")
print("=" * 80)

print("""
1. sc.parallelize(collection)          - Depuis une liste/collection Python
2. sc.parallelize(data, numSlices=N)   - Avec nombre de partitions
3. sc.textFile("path")                 - Depuis un fichier texte
4. sc.textFile("pattern*.txt")         - Depuis plusieurs fichiers
5. rdd.map/filter/etc.                 - Depuis un autre RDD (transformation)
""")

# Arrêter SparkContext
sc.stop()
print("\n✅ SparkContext arrêté")
