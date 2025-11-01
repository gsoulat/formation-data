"""
DataFrame Basics - Opérations de base sur les DataFrames

Ce script couvre :
- Création de DataFrames
- Affichage et inspection
- Sélection et filtrage
- Opérations sur colonnes
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, upper, lower, concat, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

# Créer SparkSession
spark = SparkSession.builder \
    .appName("DataFrame Basics") \
    .master("local[*]") \
    .getOrCreate()

print("=" * 80)
print("DATAFRAME BASICS")
print("=" * 80)

# ========================================
# 1. CRÉATION DE DATAFRAMES
# ========================================
print("\n1. Création de DataFrames")
print("-" * 50)

# Depuis une liste de tuples
data = [
    (1, "Alice", 25, "Paris", 50000),
    (2, "Bob", 30, "Lyon", 60000),
    (3, "Charlie", 35, "Marseille", 55000),
    (4, "David", 28, "Paris", 52000),
    (5, "Eve", 32, "Lyon", 58000)
]

df = spark.createDataFrame(data, ["id", "name", "age", "city", "salary"])
print("\n✅ DataFrame créé depuis une liste de tuples:")
df.show()

# ========================================
# 2. AFFICHAGE ET INSPECTION
# ========================================
print("\n2. Affichage et inspection")
print("-" * 50)

print("\n📋 printSchema() - Structure du DataFrame:")
df.printSchema()

print(f"\n📊 count() - Nombre de lignes: {df.count()}")
print(f"\n📊 columns - Noms des colonnes: {df.columns}")
print(f"\n📊 dtypes - Types des colonnes: {df.dtypes}")

print("\n🔍 head(2) - Les 2 premières lignes:")
for row in df.head(2):
    print(row)

print("\n📈 describe() - Statistiques descriptives:")
df.describe().show()

# ========================================
# 3. SÉLECTION DE COLONNES
# ========================================
print("\n3. Sélection de colonnes (select)")
print("-" * 50)

# Une colonne
print("\n✅ Sélectionner une colonne:")
df.select("name").show(3)

# Plusieurs colonnes
print("\n✅ Sélectionner plusieurs colonnes:")
df.select("name", "age", "city").show(3)

# Avec col()
print("\n✅ Avec col():")
df.select(col("name"), col("age") + 5).show(3)

# Toutes les colonnes
print("\n✅ Toutes les colonnes avec *:")
df.select("*").show(2)

# ========================================
# 4. FILTRAGE DE LIGNES
# ========================================
print("\n4. Filtrage de lignes (filter/where)")
print("-" * 50)

# Filtrer par âge
print("\n✅ Filtrer age > 28:")
df.filter(col("age") > 28).show()

# Multiples conditions (AND)
print("\n✅ Filtrer age > 28 AND city = Paris:")
df.filter((col("age") > 28) & (col("city") == "Paris")).show()

# Condition OR
print("\n✅ Filtrer age < 27 OR salary > 57000:")
df.filter((col("age") < 27) | (col("salary") > 57000)).show()

# Avec SQL string
print("\n✅ Filtrer avec expression SQL:")
df.filter("age > 28 AND city = 'Lyon'").show()

# ========================================
# 5. AJOUTER/MODIFIER DES COLONNES
# ========================================
print("\n5. Ajouter/Modifier des colonnes (withColumn)")
print("-" * 50)

# Ajouter une colonne calculée
df_with_bonus = df.withColumn("salary_with_bonus", col("salary") * 1.1)
print("\n✅ Ajouter colonne salary_with_bonus:")
df_with_bonus.select("name", "salary", "salary_with_bonus").show()

# Ajouter une colonne constante
df_with_country = df.withColumn("country", lit("France"))
print("\n✅ Ajouter colonne constante 'country':")
df_with_country.select("name", "city", "country").show(3)

# Modifier une colonne existante
df_upper = df.withColumn("name", upper(col("name")))
print("\n✅ Modifier name en majuscules:")
df_upper.select("name", "city").show(3)

# ========================================
# 6. RENOMMER DES COLONNES
# ========================================
print("\n6. Renommer des colonnes")
print("-" * 50)

# Méthode 1: alias()
print("\n✅ Avec alias():")
df.select(
    col("name").alias("full_name"),
    col("age").alias("years_old")
).show(3)

# Méthode 2: withColumnRenamed()
df_renamed = df.withColumnRenamed("name", "employee_name")
print("\n✅ Avec withColumnRenamed():")
df_renamed.select("employee_name", "age").show(3)

# ========================================
# 7. SUPPRIMER DES COLONNES
# ========================================
print("\n7. Supprimer des colonnes (drop)")
print("-" * 50)

df_dropped = df.drop("salary")
print("\n✅ Supprimer la colonne 'salary':")
print(f"Colonnes avant: {df.columns}")
print(f"Colonnes après: {df_dropped.columns}")
df_dropped.show(3)

# ========================================
# 8. TRIER LES DONNÉES
# ========================================
print("\n8. Trier les données (orderBy/sort)")
print("-" * 50)

# Tri croissant
print("\n✅ Trier par age (croissant):")
df.orderBy("age").show()

# Tri décroissant
print("\n✅ Trier par salary (décroissant):")
df.orderBy(col("salary").desc()).show()

# Tri multiple
print("\n✅ Trier par city puis age:")
df.orderBy("city", "age").show()

# ========================================
# 9. ÉLIMINER LES DOUBLONS
# ========================================
print("\n9. Éliminer les doublons (distinct/dropDuplicates)")
print("-" * 50)

# Créer un DataFrame avec doublons
data_dup = [
    ("Paris", "France"),
    ("Lyon", "France"),
    ("Paris", "France"),  # Doublon
    ("Marseille", "France"),
    ("Lyon", "France")  # Doublon
]

df_dup = spark.createDataFrame(data_dup, ["city", "country"])
print("\n📋 DataFrame avec doublons:")
df_dup.show()

print("\n✅ Après distinct():")
df_dup.distinct().show()

print("\n✅ dropDuplicates sur colonne 'city':")
df_dup.dropDuplicates(["city"]).show()

# ========================================
# 10. CONDITIONS (WHEN/OTHERWISE)
# ========================================
print("\n10. Conditions (when/otherwise)")
print("-" * 50)

# Catégoriser les âges
df_categorized = df.withColumn("age_category",
    when(col("age") < 30, "Young")
    .when((col("age") >= 30) & (col("age") < 35), "Mid")
    .otherwise("Senior")
)

print("\n✅ Catégoriser les âges:")
df_categorized.select("name", "age", "age_category").show()

# Catégoriser les salaires
df_salary_grade = df.withColumn("salary_grade",
    when(col("salary") >= 58000, "High")
    .when(col("salary") >= 52000, "Medium")
    .otherwise("Low")
)

print("\n✅ Catégoriser les salaires:")
df_salary_grade.select("name", "salary", "salary_grade").show()

# ========================================
# 11. LIMITER LE NOMBRE DE LIGNES
# ========================================
print("\n11. Limiter le nombre de lignes (limit)")
print("-" * 50)

print("\n✅ Les 3 premières lignes:")
df.limit(3).show()

# ========================================
# 12. VALEURS UNIQUES
# ========================================
print("\n12. Valeurs uniques")
print("-" * 50)

print("\n✅ Villes uniques:")
df.select("city").distinct().show()

print("\n✅ Compter les valeurs uniques par ville:")
df.groupBy("city").count().show()

# ========================================
# 13. EXEMPLE COMPLET: NETTOYAGE
# ========================================
print("\n13. Exemple complet: Nettoyage de données")
print("-" * 50)

# Données sales
messy_data = [
    (1, " alice ", 25, "PARIS", 50000),
    (2, "BOB", 30, "lyon", 60000),
    (3, " Charlie ", None, "Marseille", 55000),
    (4, "david", 28, "PARIS", None)
]

messy_df = spark.createDataFrame(messy_data, ["id", "name", "age", "city", "salary"])

print("\n❌ Données avant nettoyage:")
messy_df.show()

# Nettoyage
from pyspark.sql.functions import trim, initcap

clean_df = messy_df \
    .withColumn("name", trim(col("name"))) \
    .withColumn("name", initcap(col("name"))) \
    .withColumn("city", initcap(lower(col("city")))) \
    .fillna({"age": 0, "salary": 0})

print("\n✅ Données après nettoyage:")
clean_df.show()

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DES OPÉRATIONS DE BASE")
print("=" * 80)

print("""
Affichage:
  df.show()              - Afficher les données
  df.printSchema()       - Afficher le schema
  df.describe()          - Statistiques descriptives
  df.count()             - Nombre de lignes

Sélection:
  df.select("col1", "col2")  - Sélectionner colonnes
  df.filter(condition)       - Filtrer lignes
  df.orderBy("col")          - Trier
  df.limit(n)                - Limiter le nombre de lignes
  df.distinct()              - Valeurs uniques

Transformation:
  df.withColumn(name, col)   - Ajouter/modifier colonne
  df.withColumnRenamed()     - Renommer colonne
  df.drop("col")             - Supprimer colonne
  df.fillna(value)           - Remplir les valeurs nulles
  df.dropDuplicates()        - Supprimer doublons
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
