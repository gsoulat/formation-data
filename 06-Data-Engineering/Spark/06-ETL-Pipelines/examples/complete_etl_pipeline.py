"""
Pipeline ETL complet - Exemple e-commerce

Ce script montre un pipeline ETL complet :
1. Extract : Lire depuis CSV, JSON, Parquet
2. Transform : Nettoyer, valider, enrichir, agréger
3. Load : Écrire en Parquet partitionné
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import os

# Créer SparkSession
spark = SparkSession.builder \
    .appName("Complete ETL Pipeline") \
    .master("local[*]") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

print("=" * 80)
print("PIPELINE ETL COMPLET - E-COMMERCE")
print("=" * 80)

# ========================================
# PRÉPARER LES DONNÉES DE TEST
# ========================================
print("\n📦 Préparation des données de test...")

# Créer des dossiers
os.makedirs("data", exist_ok=True)
os.makedirs("output", exist_ok=True)

# Créer des données de commandes (CSV)
orders_data = spark.createDataFrame([
    (1, 101, 1001, 2, 50.0, "2024-01-15"),
    (2, 102, 1002, 1, 100.0, "2024-01-15"),
    (3, 101, 1003, 3, 25.0, "2024-01-16"),
    (4, 103, 1001, 1, 50.0, "2024-01-16"),
    (5, 102, 1004, 2, 75.0, "2024-01-17"),
    (6, None, 1001, 1, 50.0, "2024-01-17"),  # customer_id NULL (invalide)
    (7, 104, None, 1, 100.0, "2024-01-18"),  # product_id NULL (invalide)
], ["order_id", "customer_id", "product_id", "quantity", "price", "order_date"])

orders_data.write.mode("overwrite").option("header", "true").csv("data/orders.csv")

# Créer des données clients (JSON)
customers_data = spark.createDataFrame([
    (101, "Alice", "alice@example.com", "Paris"),
    (102, "Bob", "bob@example.com", "Lyon"),
    (103, "Charlie", "charlie@example.com", "Marseille"),
    (104, "David", "david@example.com", "Paris"),
], ["customer_id", "name", "email", "city"])

customers_data.write.mode("overwrite").json("data/customers.json")

# Créer des données produits (Parquet)
products_data = spark.createDataFrame([
    (1001, "Laptop", "Electronics", 50.0),
    (1002, "Python Book", "Books", 100.0),
    (1003, "USB Cable", "Electronics", 25.0),
    (1004, "Notebook", "Office", 75.0),
], ["product_id", "product_name", "category", "base_price"])

products_data.write.mode("overwrite").parquet("data/products.parquet")

print("✅ Données de test créées")

# ========================================
# 1. EXTRACT - LECTURE DES DONNÉES
# ========================================
print("\n" + "=" * 80)
print("1. EXTRACT - Lecture des données sources")
print("=" * 80)

# Définir le schema pour orders
orders_schema = StructType([
    StructField("order_id", IntegerType(), False),
    StructField("customer_id", IntegerType(), True),
    StructField("product_id", IntegerType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("price", DoubleType(), True),
    StructField("order_date", StringType(), True)
])

# Lire orders (CSV avec schema explicite)
print("\n📄 Lecture orders.csv...")
orders = spark.read.csv("data/orders.csv", schema=orders_schema, header=True)
print(f"  Lignes lues: {orders.count()}")
orders.show()

# Lire customers (JSON)
print("\n📄 Lecture customers.json...")
customers = spark.read.json("data/customers.json")
print(f"  Lignes lues: {customers.count()}")
customers.show()

# Lire products (Parquet)
print("\n📄 Lecture products.parquet...")
products = spark.read.parquet("data/products.parquet")
print(f"  Lignes lues: {products.count()}")
products.show()

# ========================================
# 2. TRANSFORM - TRANSFORMATION
# ========================================
print("\n" + "=" * 80)
print("2. TRANSFORM - Nettoyage et enrichissement")
print("=" * 80)

# 2.1 Nettoyage des données
print("\n🧹 Étape 2.1 : Nettoyage des données")

# Supprimer les lignes avec nulls critiques
orders_valid = orders.dropna(subset=["order_id", "customer_id", "product_id"])
print(f"  Lignes avant nettoyage: {orders.count()}")
print(f"  Lignes après nettoyage: {orders_valid.count()}")
print(f"  Lignes supprimées: {orders.count() - orders_valid.count()}")

# Valider les valeurs
orders_clean = orders_valid.filter(
    (col("quantity") > 0) &
    (col("price") > 0)
)

# Convertir la date
orders_clean = orders_clean.withColumn("order_date", to_date(col("order_date")))

# Calculer le montant total
orders_clean = orders_clean.withColumn("total_amount", col("quantity") * col("price"))

print("\n✅ Orders après nettoyage:")
orders_clean.show()

# 2.2 Enrichissement avec les clients
print("\n🔗 Étape 2.2 : Enrichissement avec clients")

orders_with_customers = orders_clean.join(
    customers,
    "customer_id",
    "left"
).select(
    orders_clean["*"],
    customers["name"].alias("customer_name"),
    customers["email"].alias("customer_email"),
    customers["city"].alias("customer_city")
)

print("✅ Orders enrichi avec customers:")
orders_with_customers.show()

# 2.3 Enrichissement avec les produits
print("\n🔗 Étape 2.3 : Enrichissement avec produits")

orders_enriched = orders_with_customers.join(
    products,
    "product_id",
    "left"
).select(
    orders_with_customers["*"],
    products["product_name"],
    products["category"]
)

print("✅ Orders enrichi avec products:")
orders_enriched.show(truncate=False)

# 2.4 Ajouter des métadonnées
print("\n📝 Étape 2.4 : Ajout de métadonnées")

orders_final = orders_enriched \
    .withColumn("processed_at", current_timestamp()) \
    .withColumn("year", year(col("order_date"))) \
    .withColumn("month", month(col("order_date"))) \
    .withColumn("day", dayofmonth(col("order_date")))

print("✅ Orders final avec métadonnées:")
orders_final.select("order_id", "product_name", "total_amount", "year", "month", "processed_at").show()

# 2.5 Créer des agrégations
print("\n📊 Étape 2.5 : Créer des agrégations")

# Agrégation par jour et catégorie
daily_category_sales = orders_final.groupBy("order_date", "category").agg(
    count("*").alias("num_orders"),
    sum("total_amount").alias("total_revenue"),
    avg("total_amount").alias("avg_order_value"),
    sum("quantity").alias("total_quantity")
).orderBy("order_date", "category")

print("✅ Ventes quotidiennes par catégorie:")
daily_category_sales.show()

# Agrégation par client
customer_stats = orders_final.groupBy("customer_id", "customer_name", "customer_city").agg(
    count("*").alias("num_orders"),
    sum("total_amount").alias("total_spent"),
    avg("total_amount").alias("avg_order_value")
).orderBy(col("total_spent").desc())

print("✅ Statistiques par client:")
customer_stats.show()

# Agrégation par produit
product_stats = orders_final.groupBy("product_id", "product_name", "category").agg(
    count("*").alias("num_orders"),
    sum("quantity").alias("total_quantity_sold"),
    sum("total_amount").alias("total_revenue")
).orderBy(col("total_revenue").desc())

print("✅ Statistiques par produit:")
product_stats.show()

# ========================================
# 3. LOAD - ÉCRITURE DES RÉSULTATS
# ========================================
print("\n" + "=" * 80)
print("3. LOAD - Écriture des résultats")
print("=" * 80)

# 3.1 Sauvegarder orders enrichis (partitionné par date)
print("\n💾 Étape 3.1 : Sauvegarde orders enrichis (partitionné)")

output_path_orders = "output/orders_enriched"
orders_final.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(output_path_orders)

print(f"✅ Orders enrichis sauvegardés dans: {output_path_orders}")

# Vérifier les partitions créées
import subprocess
result = subprocess.run(["find", output_path_orders, "-name", "*.parquet"], capture_output=True, text=True)
print(f"  Fichiers créés: {len(result.stdout.strip().split())}")

# 3.2 Sauvegarder les agrégations
print("\n💾 Étape 3.2 : Sauvegarde des agrégations")

# Daily sales
daily_category_sales.write \
    .mode("overwrite") \
    .parquet("output/daily_category_sales")
print("✅ daily_category_sales sauvegardé")

# Customer stats
customer_stats.write \
    .mode("overwrite") \
    .parquet("output/customer_stats")
print("✅ customer_stats sauvegardé")

# Product stats
product_stats.write \
    .mode("overwrite") \
    .parquet("output/product_stats")
print("✅ product_stats sauvegardé")

# 3.3 Sauvegarder une version CSV pour export
print("\n💾 Étape 3.3 : Export CSV pour BI tools")

daily_category_sales.coalesce(1).write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv("output/daily_sales_export.csv")

print("✅ CSV export créé")

# ========================================
# 4. VALIDATION ET RAPPORTS
# ========================================
print("\n" + "=" * 80)
print("4. VALIDATION ET RAPPORTS")
print("=" * 80)

# Relire les données sauvegardées pour validation
print("\n🔍 Validation des données sauvegardées:")

orders_reloaded = spark.read.parquet(output_path_orders)
print(f"  Orders enrichis: {orders_reloaded.count()} lignes")

daily_reloaded = spark.read.parquet("output/daily_category_sales")
print(f"  Daily sales: {daily_reloaded.count()} lignes")

# Rapport final
print("\n📊 RAPPORT FINAL:")
print("-" * 50)
print(f"📥 Données source:")
print(f"  - Orders: {orders.count()} lignes")
print(f"  - Customers: {customers.count()} lignes")
print(f"  - Products: {products.count()} lignes")

print(f"\n🧹 Après nettoyage:")
print(f"  - Orders valides: {orders_clean.count()} lignes")
print(f"  - Lignes rejetées: {orders.count() - orders_clean.count()}")

print(f"\n📊 Agrégations:")
print(f"  - Daily sales: {daily_category_sales.count()} lignes")
print(f"  - Customers: {customer_stats.count()} lignes")
print(f"  - Products: {product_stats.count()} lignes")

print(f"\n💰 Revenus totaux: ${orders_final.select(sum('total_amount')).collect()[0][0]:.2f}")

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DU PIPELINE ETL")
print("=" * 80)

print("""
✅ Pipeline ETL terminé avec succès !

Étapes exécutées:
  1. EXTRACT
     ✓ Lecture de 3 sources (CSV, JSON, Parquet)
     ✓ Schema explicite pour validation

  2. TRANSFORM
     ✓ Nettoyage (suppression nulls, validation)
     ✓ Enrichissement (2 joins)
     ✓ Calculs (montants, métadonnées)
     ✓ Agrégations (daily, customer, product)

  3. LOAD
     ✓ Parquet partitionné (year/month)
     ✓ Agrégations en Parquet
     ✓ Export CSV pour BI

  4. VALIDATION
     ✓ Relecture et vérification
     ✓ Rapport de statistiques

Outputs:
  📁 output/orders_enriched/          (partitionné)
  📁 output/daily_category_sales/
  📁 output/customer_stats/
  📁 output/product_stats/
  📁 output/daily_sales_export.csv/
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
