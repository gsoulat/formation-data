"""
User Defined Functions (UDF) - Fonctions personnalisées

Ce script montre :
- Créer des UDFs standard
- Enregistrer des UDFs pour SQL
- Pandas UDFs (plus performants)
- UDFs d'agrégation
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, pandas_udf, col
from pyspark.sql.types import StringType, IntegerType, DoubleType, FloatType
import pandas as pd

# Créer SparkSession
spark = SparkSession.builder \
    .appName("UDF Functions") \
    .master("local[*]") \
    .getOrCreate()

print("=" * 80)
print("USER DEFINED FUNCTIONS (UDF)")
print("=" * 80)

# ========================================
# DONNÉES DE TEST
# ========================================

users = spark.createDataFrame([
    (1, "alice", 17, "alice@example.com"),
    (2, "BOB", 25, "bob@EXAMPLE.com"),
    (3, "charlie", 35, "charlie@test.COM"),
    (4, "DAVID", 42, "david@demo.org"),
    (5, "eve", 28, "eve@example.com")
], ["id", "name", "age", "email"])

print("\n📋 Données utilisateurs:")
users.show()

# ========================================
# 1. UDF STANDARD
# ========================================
print("\n" + "=" * 80)
print("1. UDF STANDARD")
print("=" * 80)

# Définir une fonction Python simple
def categorize_age(age):
    """Catégoriser l'âge"""
    if age is None:
        return "Unknown"
    elif age < 18:
        return "Minor"
    elif age < 65:
        return "Adult"
    else:
        return "Senior"

# Créer une UDF
categorize_age_udf = udf(categorize_age, StringType())

# Utiliser l'UDF dans DataFrame API
print("\n✅ Utiliser UDF dans DataFrame API:")
result = users.withColumn("age_category", categorize_age_udf(col("age")))
result.select("name", "age", "age_category").show()

# ========================================
# 2. ENREGISTRER UDF POUR SQL
# ========================================
print("\n" + "=" * 80)
print("2. UDF POUR SQL")
print("=" * 80)

# Enregistrer l'UDF pour l'utiliser en SQL
spark.udf.register("categorize_age", categorize_age, StringType())

# Créer une view
users.createOrReplaceTempView("users")

# Utiliser en SQL
print("\n✅ Utiliser UDF en SQL:")
spark.sql("""
    SELECT
        name,
        age,
        categorize_age(age) as category
    FROM users
""").show()

# ========================================
# 3. UDF AVEC DÉCORATEUR
# ========================================
print("\n" + "=" * 80)
print("3. UDF AVEC DÉCORATEUR")
print("=" * 80)

@udf(returnType=StringType())
def normalize_email(email):
    """Normaliser un email"""
    if email:
        return email.lower().strip()
    return None

@udf(returnType=StringType())
def capitalize_name(name):
    """Capitaliser un nom"""
    if name:
        return name.capitalize()
    return None

print("\n✅ UDFs avec décorateurs:")
result = users \
    .withColumn("name_clean", capitalize_name(col("name"))) \
    .withColumn("email_clean", normalize_email(col("email")))

result.select("name", "name_clean", "email", "email_clean").show(truncate=False)

# ========================================
# 4. UDF AVEC MULTIPLES PARAMÈTRES
# ========================================
print("\n" + "=" * 80)
print("4. UDF AVEC MULTIPLES PARAMÈTRES")
print("=" * 80)

def calculate_discount(age, base_price):
    """Calculer une réduction selon l'âge"""
    if age is None or base_price is None:
        return base_price

    if age < 18:
        return base_price * 0.8  # 20% réduction
    elif age >= 65:
        return base_price * 0.9  # 10% réduction
    else:
        return base_price

calculate_discount_udf = udf(calculate_discount, DoubleType())

# Ajouter une colonne de prix
users_with_price = users.withColumn("base_price", col("id") * 10.0)

print("\n✅ UDF avec multiples paramètres:")
result = users_with_price.withColumn(
    "final_price",
    calculate_discount_udf(col("age"), col("base_price"))
)

result.select("name", "age", "base_price", "final_price").show()

# ========================================
# 5. PANDAS UDF (PLUS PERFORMANT)
# ========================================
print("\n" + "=" * 80)
print("5. PANDAS UDF (VECTORIZED)")
print("=" * 80)

# Pandas UDF pour traitement vectorisé
@pandas_udf(StringType())
def upper_case_pandas(s: pd.Series) -> pd.Series:
    """Convertir en majuscules (vectorisé)"""
    return s.str.upper()

@pandas_udf(StringType())
def extract_domain_pandas(s: pd.Series) -> pd.Series:
    """Extraire le domaine d'un email (vectorisé)"""
    return s.str.split('@').str[1]

print("\n✅ Pandas UDF (plus rapide que UDF standard):")
result = users \
    .withColumn("name_upper", upper_case_pandas(col("name"))) \
    .withColumn("email_domain", extract_domain_pandas(col("email")))

result.select("name", "name_upper", "email", "email_domain").show(truncate=False)

# ========================================
# 6. PANDAS UDF D'AGRÉGATION
# ========================================
print("\n" + "=" * 80)
print("6. PANDAS UDF D'AGRÉGATION")
print("=" * 80)

# Créer des données de ventes
sales = spark.createDataFrame([
    ("Electronics", 1200.0),
    ("Electronics", 800.0),
    ("Electronics", 1500.0),
    ("Books", 40.0),
    ("Books", 50.0),
    ("Books", 45.0),
    ("Clothing", 75.0),
    ("Clothing", 120.0)
], ["category", "amount"])

print("\n📋 Données de ventes:")
sales.show()

# UDF d'agrégation personnalisée
@pandas_udf(DoubleType())
def weighted_mean(amounts: pd.Series) -> float:
    """Moyenne pondérée custom"""
    # Exemple simple: donner plus de poids aux valeurs élevées
    weights = amounts / amounts.sum()
    return (amounts * weights).sum()

print("\n✅ Pandas UDF d'agrégation:")
result = sales.groupBy("category").agg(
    weighted_mean(col("amount")).alias("weighted_avg")
)
result.show()

# ========================================
# 7. UDF AVEC TYPES COMPLEXES
# ========================================
print("\n" + "=" * 80)
print("7. UDF AVEC TYPES COMPLEXES")
print("=" * 80)

from pyspark.sql.types import ArrayType

@udf(ArrayType(StringType()))
def split_and_clean(text):
    """Split et nettoie du texte"""
    if text:
        words = text.lower().split()
        return [w.strip() for w in words if len(w) > 2]
    return []

# Créer des données texte
texts = spark.createDataFrame([
    (1, "Hello World from Apache Spark"),
    (2, "Big Data Processing is Fun"),
    (3, "Learn Python and Scala")
], ["id", "text"])

print("\n✅ UDF retournant un Array:")
result = texts.withColumn("words", split_and_clean(col("text")))
result.show(truncate=False)

# ========================================
# 8. EXEMPLE COMPLET: VALIDATION EMAIL
# ========================================
print("\n" + "=" * 80)
print("8. EXEMPLE COMPLET: VALIDATION EMAIL")
print("=" * 80)

import re

@udf(returnType=StringType())
def validate_email(email):
    """Valider et catégoriser un email"""
    if not email:
        return "INVALID"

    email = email.lower().strip()

    # Regex simple pour validation
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if not re.match(pattern, email):
        return "INVALID"

    # Catégoriser par domaine
    if '@gmail.com' in email or '@yahoo.com' in email:
        return "PERSONAL"
    elif '@company.com' in email or '@enterprise.com' in email:
        return "CORPORATE"
    else:
        return "OTHER"

# Enregistrer pour SQL
spark.udf.register("validate_email", validate_email, StringType())

# Données avec emails variés
email_data = spark.createDataFrame([
    (1, "john.doe@gmail.com"),
    (2, "jane@company.com"),
    (3, "invalid-email"),
    (4, "bob.smith@yahoo.com"),
    (5, "alice@test.org"),
    (6, None)
], ["id", "email"])

email_data.createOrReplaceTempView("email_data")

print("\n📋 Données emails:")
email_data.show(truncate=False)

print("\n✅ Validation des emails:")
spark.sql("""
    SELECT
        email,
        validate_email(email) as email_type
    FROM email_data
""").show(truncate=False)

# Statistiques
print("\n✅ Distribution des types d'emails:")
spark.sql("""
    SELECT
        validate_email(email) as email_type,
        COUNT(*) as count
    FROM email_data
    GROUP BY validate_email(email)
""").show()

# ========================================
# 9. COMPARAISON PERFORMANCE: UDF vs PANDAS UDF
# ========================================
print("\n" + "=" * 80)
print("9. PERFORMANCE: UDF vs PANDAS UDF")
print("=" * 80)

import time

# Créer un dataset plus grand
large_df = spark.range(10000).withColumn("value", col("id") * 1.5)

# UDF standard
@udf(DoubleType())
def multiply_by_2_udf(x):
    return x * 2

# Pandas UDF
@pandas_udf(DoubleType())
def multiply_by_2_pandas(s: pd.Series) -> pd.Series:
    return s * 2

print("\n⏱️  Benchmark UDF standard:")
start = time.time()
result_udf = large_df.withColumn("result", multiply_by_2_udf(col("value")))
result_udf.count()  # Trigger execution
udf_time = time.time() - start
print(f"Temps UDF standard: {udf_time:.4f}s")

print("\n⏱️  Benchmark Pandas UDF:")
start = time.time()
result_pandas = large_df.withColumn("result", multiply_by_2_pandas(col("value")))
result_pandas.count()  # Trigger execution
pandas_time = time.time() - start
print(f"Temps Pandas UDF: {pandas_time:.4f}s")

print(f"\n✅ Pandas UDF est {udf_time/pandas_time:.2f}x plus rapide !")

# ========================================
# 10. BONNES PRATIQUES
# ========================================
print("\n" + "=" * 80)
print("10. BONNES PRATIQUES")
print("=" * 80)

print("""
✅ Bonnes pratiques pour les UDFs:

1. Préférez les fonctions built-in de Spark
   ❌ UDF pour upper()
   ✅ Utilisez F.upper()

2. Utilisez Pandas UDF pour de meilleures performances
   ❌ @udf(StringType())
   ✅ @pandas_udf(StringType())

3. Gérez les valeurs NULL
   ❌ def my_func(x): return x.upper()
   ✅ def my_func(x): return x.upper() if x else None

4. Spécifiez toujours le type de retour
   ❌ udf(my_func)
   ✅ udf(my_func, StringType())

5. Évitez les UDFs dans les opérations critiques
   - Les UDFs empêchent certaines optimisations Catalyst
   - Préférez SQL/DataFrame API built-in quand possible

6. Testez vos UDFs en local d'abord
   - Vérifiez avec des données variées (NULL, edge cases)

Ordre de préférence:
  1. Built-in functions (F.upper, F.when, etc.)
  2. Pandas UDF (vectorized, rapide)
  3. UDF standard (en dernier recours)
""")

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF UDF")
print("=" * 80)

print("""
Créer une UDF:
  def my_func(x):
      return x * 2

  my_udf = udf(my_func, IntegerType())
  df.withColumn("result", my_udf(col("value")))

Enregistrer pour SQL:
  spark.udf.register("my_func", my_func, IntegerType())
  spark.sql("SELECT my_func(value) FROM table")

Avec décorateur:
  @udf(returnType=StringType())
  def my_func(x):
      return x.upper()

Pandas UDF (recommandé):
  @pandas_udf(StringType())
  def my_func(s: pd.Series) -> pd.Series:
      return s.str.upper()

Types de retour courants:
  StringType(), IntegerType(), DoubleType(),
  ArrayType(StringType()), StructType([...])
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
