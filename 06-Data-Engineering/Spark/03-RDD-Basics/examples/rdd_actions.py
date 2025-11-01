"""
RDD Actions - Actions qui déclenchent l'exécution

Ce script montre les actions principales qui déclenchent l'exécution :
- collect, count, first, take
- reduce, fold, aggregate
- foreach, saveAsTextFile
"""

from pyspark import SparkContext, SparkConf
import time

# Configuration Spark
conf = SparkConf().setAppName("RDD Actions").setMaster("local[*]")
sc = SparkContext(conf=conf)

print("=" * 80)
print("RDD ACTIONS EXAMPLES")
print("=" * 80)

# ========================================
# 1. collect() - Récupérer tous les éléments
# ========================================
print("\n1. collect() - Récupérer tous les éléments")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])
result = numbers.collect()

print(f"RDD : {numbers}")
print(f"collect() résultat : {result}")
print(f"Type : {type(result)}")

print("\n⚠️  ATTENTION : collect() charge TOUT en mémoire du driver")
print("   Ne pas utiliser sur de gros datasets !")

# ========================================
# 2. count() - Compter les éléments
# ========================================
print("\n2. count() - Compter les éléments")
print("-" * 50)

numbers = sc.parallelize(range(1, 101))
count = numbers.count()
even_count = numbers.filter(lambda x: x % 2 == 0).count()

print(f"Nombre total : {count}")
print(f"Nombres pairs : {even_count}")

# ========================================
# 3. first() - Premier élément
# ========================================
print("\n3. first() - Premier élément")
print("-" * 50)

numbers = sc.parallelize([5, 3, 8, 1, 9])
first = numbers.first()

print(f"RDD : {numbers.collect()}")
print(f"Premier élément : {first}")

# ========================================
# 4. take(n) - Prendre les n premiers
# ========================================
print("\n4. take(n) - Prendre les n premiers")
print("-" * 50)

numbers = sc.parallelize(range(1, 101))
first_10 = numbers.take(10)

print(f"Total : {numbers.count()} éléments")
print(f"Les 10 premiers : {first_10}")

# ========================================
# 5. top(n) - Les n plus grands
# ========================================
print("\n5. top(n) - Les n plus grands")
print("-" * 50)

numbers = sc.parallelize([3, 7, 2, 9, 1, 8, 4, 6, 5])
top_3 = numbers.top(3)
top_5 = numbers.top(5)

print(f"RDD : {numbers.collect()}")
print(f"Top 3 : {top_3}")
print(f"Top 5 : {top_5}")

# ========================================
# 6. takeSample() - Échantillon aléatoire
# ========================================
print("\n6. takeSample() - Échantillon aléatoire")
print("-" * 50)

numbers = sc.parallelize(range(1, 101))
sample = numbers.takeSample(withReplacement=False, num=10, seed=42)

print(f"Dataset : 1 à 100")
print(f"Échantillon de 10 : {sorted(sample)}")

# ========================================
# 7. reduce() - Agrégation
# ========================================
print("\n7. reduce() - Agrégation avec fonction")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])

# Somme
sum_result = numbers.reduce(lambda x, y: x + y)
print(f"Somme : {sum_result}")

# Produit
product = numbers.reduce(lambda x, y: x * y)
print(f"Produit : {product}")

# Maximum
max_value = numbers.reduce(lambda x, y: x if x > y else y)
print(f"Maximum : {max_value}")

# Minimum
min_value = numbers.reduce(lambda x, y: x if x < y else y)
print(f"Minimum : {min_value}")

# ========================================
# 8. fold() - Reduce avec valeur initiale
# ========================================
print("\n8. fold() - Reduce avec valeur initiale")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])

# Somme avec valeur initiale 0
sum_fold = numbers.fold(0, lambda x, y: x + y)
print(f"fold(0, +) : {sum_fold}")

# Attention : la valeur initiale est appliquée par partition ET au résultat final
sum_fold_10 = numbers.fold(10, lambda x, y: x + y)
print(f"fold(10, +) : {sum_fold_10}")
print("  ⚠️  Peut donner des résultats surprenants avec plusieurs partitions !")

# ========================================
# 9. aggregate() - Agrégation avancée
# ========================================
print("\n9. aggregate() - Agrégation avancée")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])

# Calculer somme et count en une passe
# aggregate(valeur_init, seqOp, combOp)
sum_and_count = numbers.aggregate(
    (0, 0),  # (somme, count)
    lambda acc, value: (acc[0] + value, acc[1] + 1),  # Combiner avec valeur
    lambda acc1, acc2: (acc1[0] + acc2[0], acc1[1] + acc2[1])  # Combiner accumulateurs
)

total_sum, total_count = sum_and_count
average = total_sum / total_count

print(f"Somme : {total_sum}")
print(f"Count : {total_count}")
print(f"Moyenne : {average}")

# ========================================
# 10. foreach() - Appliquer une fonction (effets de bord)
# ========================================
print("\n10. foreach() - Effets de bord")
print("-" * 50)

numbers = sc.parallelize([1, 2, 3, 4, 5])

print("⚠️  foreach() s'exécute sur les executors, pas le driver")
print("    Les prints peuvent ne pas apparaître ici\n")

# Créer une fonction avec effet de bord
def process_element(x):
    # Sur les executors, pas visible dans ce script
    pass

numbers.foreach(process_element)

# Alternative : utiliser collect() puis boucle normale
print("Utiliser collect() puis boucle pour voir les résultats :")
for num in numbers.collect():
    print(f"  Processing: {num}")

# ========================================
# 11. countByValue() - Compter les occurrences
# ========================================
print("\n11. countByValue() - Compter les occurrences")
print("-" * 50)

words = sc.parallelize(["apple", "banana", "apple", "orange", "banana", "apple"])
counts = words.countByValue()

print(f"Mots : {words.collect()}")
print(f"Occurrences : {dict(counts)}")

# ========================================
# 12. countByKey() - Compter par clé (Pair RDD)
# ========================================
print("\n12. countByKey() - Compter par clé")
print("-" * 50)

pairs = sc.parallelize([
    ("fruit", "apple"),
    ("fruit", "banana"),
    ("vegetable", "carrot"),
    ("fruit", "orange"),
    ("vegetable", "tomato")
])

counts_by_key = pairs.countByKey()
print(f"Pairs : {pairs.collect()}")
print(f"Count par catégorie : {dict(counts_by_key)}")

# ========================================
# 13. saveAsTextFile() - Sauvegarder en fichiers
# ========================================
print("\n13. saveAsTextFile() - Sauvegarder")
print("-" * 50)

words = sc.parallelize(["hello", "world", "spark", "rdd", "actions"])

output_path = "/tmp/spark_output"
import shutil
import os

# Supprimer le dossier s'il existe
if os.path.exists(output_path):
    shutil.rmtree(output_path)

words.saveAsTextFile(output_path)
print(f"✅ Sauvegardé dans : {output_path}")

# Lister les fichiers créés
files = os.listdir(output_path)
print(f"Fichiers créés : {files}")

# Lire le contenu
print("Contenu des fichiers :")
for filename in sorted(files):
    if filename.startswith("part-"):
        filepath = os.path.join(output_path, filename)
        with open(filepath, "r") as f:
            print(f"  {filename}: {f.read().strip()}")

# ========================================
# 14. stats() - Statistiques basiques
# ========================================
print("\n14. stats() - Statistiques")
print("-" * 50)

numbers = sc.parallelize([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
statistics = numbers.stats()

print(f"Count : {statistics.count()}")
print(f"Mean  : {statistics.mean()}")
print(f"StDev : {statistics.stdev():.2f}")
print(f"Min   : {statistics.min()}")
print(f"Max   : {statistics.max()}")

# ========================================
# 15. Démonstration : Lazy vs Actions
# ========================================
print("\n15. Lazy Evaluation vs Actions")
print("-" * 50)

print("Créer un RDD et appliquer des transformations...")
start = time.time()

# Transformations (lazy - pas d'exécution)
rdd = sc.parallelize(range(1, 1000001))
filtered = rdd.filter(lambda x: x % 2 == 0)
mapped = filtered.map(lambda x: x * 2)

transform_time = time.time() - start
print(f"⏱️  Temps pour les transformations : {transform_time:.4f}s")
print("   (Quasi instantané car lazy !)")

print("\nMaintenant, appeler une action (count)...")
start = time.time()

count = mapped.count()

action_time = time.time() - start
print(f"⏱️  Temps pour l'action : {action_time:.4f}s")
print(f"   Résultat : {count} éléments")

# ========================================
# 16. Exemple complet : Analyse de logs
# ========================================
print("\n16. Exemple : Analyse de logs web")
print("-" * 50)

# Simuler des logs web
logs = sc.parallelize([
    "192.168.1.1 - GET /index.html 200",
    "192.168.1.2 - GET /about.html 200",
    "192.168.1.1 - POST /login 200",
    "192.168.1.3 - GET /missing.html 404",
    "192.168.1.2 - GET /index.html 200",
    "192.168.1.4 - GET /error.html 500",
    "192.168.1.3 - GET /admin 403",
    "192.168.1.1 - GET /contact.html 200"
])

# Analyse
total_requests = logs.count()
print(f"Total requêtes : {total_requests}")

# Compter les codes de statut
status_codes = logs.map(lambda line: line.split()[-1])
status_distribution = status_codes.countByValue()

print("\nDistribution des codes de statut :")
for status, count in sorted(status_distribution.items()):
    print(f"  {status}: {count}")

# Compter les requêtes par IP
ips = logs.map(lambda line: (line.split()[0], 1))
requests_by_ip = ips.reduceByKey(lambda x, y: x + y)

print("\nRequêtes par IP :")
for ip, count in requests_by_ip.collect():
    print(f"  {ip}: {count}")

# Trouver les erreurs (4xx, 5xx)
errors = logs.filter(lambda line: line.split()[-1][0] in ['4', '5'])
error_count = errors.count()
print(f"\nNombre d'erreurs (4xx/5xx) : {error_count}")

if error_count > 0:
    print("Détail des erreurs :")
    for error_log in errors.collect():
        print(f"  {error_log}")

# ========================================
# Récapitulatif
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DES ACTIONS")
print("=" * 80)

print("""
Actions courantes:
  - collect()        : Récupère TOUS les éléments (⚠️  risque OOM)
  - count()          : Compte les éléments
  - first()          : Premier élément
  - take(n)          : n premiers éléments
  - top(n)           : n plus grands éléments

Agrégations:
  - reduce(f)        : Agrège avec fonction
  - fold(init, f)    : Reduce avec valeur initiale
  - aggregate()      : Agrégation avancée

Comptages:
  - countByValue()   : Compte occurrences de chaque valeur
  - countByKey()     : Compte par clé (Pair RDD)

Sauvegarde:
  - saveAsTextFile() : Sauvegarde en fichiers texte
  - foreach(f)       : Applique f (effets de bord)

Statistiques:
  - stats()          : count, mean, stdev, min, max

⚡ RAPPEL : Les actions déclenchent l'exécution !
""")

# Arrêter SparkContext
sc.stop()
print("✅ SparkContext arrêté")
