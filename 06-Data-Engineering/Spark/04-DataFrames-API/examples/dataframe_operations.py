"""
DataFrame Operations - Transformations avancées

Ce script couvre :
- Agrégations (groupBy, agg)
- Joins (inner, left, right, outer)
- Window functions
- Fonctions avancées sur colonnes
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.window import Window

# Créer SparkSession
spark = SparkSession.builder \
    .appName("DataFrame Operations") \
    .master("local[*]") \
    .getOrCreate()

print("=" * 80)
print("DATAFRAME ADVANCED OPERATIONS")
print("=" * 80)

# ========================================
# 1. AGRÉGATIONS SIMPLES
# ========================================
print("\n1. Agrégations simples")
print("-" * 50)

sales = spark.createDataFrame([
    ("2024-01-01", "ProductA", 100, 2),
    ("2024-01-01", "ProductB", 150, 1),
    ("2024-01-02", "ProductA", 200, 3),
    ("2024-01-02", "ProductC", 80, 4),
    ("2024-01-03", "ProductB", 150, 2),
], ["date", "product", "price", "quantity"])

# Calculer revenue
sales = sales.withColumn("revenue", col("price") * col("quantity"))

print("\n📋 Données de ventes:")
sales.show()

# Agrégations globales
print("\n✅ Statistiques globales:")
sales.select(
    count("*").alias("total_orders"),
    sum("revenue").alias("total_revenue"),
    avg("revenue").alias("avg_revenue"),
    min("revenue").alias("min_revenue"),
    max("revenue").alias("max_revenue")
).show()

# ========================================
# 2. GROUP BY
# ========================================
print("\n2. GroupBy - Grouper et agréger")
print("-" * 50)

# Grouper par produit
print("\n✅ Revenus par produit:")
product_revenue = sales.groupBy("product").agg(
    sum("revenue").alias("total_revenue"),
    count("*").alias("num_orders"),
    avg("revenue").alias("avg_revenue")
).orderBy(col("total_revenue").desc())

product_revenue.show()

# Grouper par date
print("\n✅ Revenus par date:")
daily_revenue = sales.groupBy("date").agg(
    sum("revenue").alias("daily_revenue"),
    count("*").alias("num_orders")
).orderBy("date")

daily_revenue.show()

# ========================================
# 3. JOINS
# ========================================
print("\n3. Joins - Joindre des DataFrames")
print("-" * 50)

# Créer deux DataFrames
employees = spark.createDataFrame([
    (1, "Alice", 1),
    (2, "Bob", 2),
    (3, "Charlie", 1),
    (4, "David", 3),
    (5, "Eve", 2)
], ["emp_id", "name", "dept_id"])

departments = spark.createDataFrame([
    (1, "Sales", "Paris"),
    (2, "Engineering", "Lyon"),
    (3, "HR", "Marseille"),
    (4, "Marketing", "Nice")  # Pas d'employés
], ["dept_id", "dept_name", "location"])

print("\n📋 Employés:")
employees.show()

print("\n📋 Départements:")
departments.show()

# Inner Join (défaut)
print("\n✅ INNER JOIN:")
inner_result = employees.join(departments, "dept_id", "inner")
inner_result.show()

# Left Join
print("\n✅ LEFT JOIN:")
left_result = employees.join(departments, "dept_id", "left")
left_result.show()

# Right Join
print("\n✅ RIGHT JOIN:")
right_result = employees.join(departments, "dept_id", "right")
right_result.show()

# Full Outer Join
print("\n✅ FULL OUTER JOIN:")
outer_result = employees.join(departments, "dept_id", "outer")
outer_result.show()

# ========================================
# 4. JOIN AVEC COLONNES DIFFÉRENTES
# ========================================
print("\n4. Join avec colonnes de noms différents")
print("-" * 50)

# Données
orders = spark.createDataFrame([
    (1, 101, 100),
    (2, 102, 200),
    (3, 101, 150)
], ["order_id", "customer_id", "amount"])

customers = spark.createDataFrame([
    (101, "Alice"),
    (102, "Bob"),
    (103, "Charlie")
], ["id", "customer_name"])

print("\n📋 Orders:")
orders.show()

print("\n📋 Customers:")
customers.show()

# Join avec condition explicite
print("\n✅ Join orders et customers:")
result = orders.join(customers, orders.customer_id == customers.id, "inner") \
    .select("order_id", "customer_name", "amount")
result.show()

# ========================================
# 5. FONCTIONS STRING
# ========================================
print("\n5. Fonctions sur les strings")
print("-" * 50)

text_data = spark.createDataFrame([
    (1, " Hello World ", "john.doe@example.com"),
    (2, "Apache Spark", "jane.smith@test.com"),
    (3, "Big Data", "bob.wilson@demo.org")
], ["id", "text", "email"])

print("\n📋 Données originales:")
text_data.show(truncate=False)

# Manipulation de strings
text_processed = text_data \
    .withColumn("text_upper", upper(col("text"))) \
    .withColumn("text_lower", lower(col("text"))) \
    .withColumn("text_trim", trim(col("text"))) \
    .withColumn("text_length", length(col("text"))) \
    .withColumn("email_domain", regexp_extract(col("email"), r'@(.+)$', 1))

print("\n✅ Après traitement:")
text_processed.select("text", "text_upper", "text_length", "email_domain").show(truncate=False)

# ========================================
# 6. FONCTIONS DATE
# ========================================
print("\n6. Fonctions sur les dates")
print("-" * 50)

# Créer des données avec dates
date_data = spark.createDataFrame([
    (1, "2024-01-15"),
    (2, "2024-02-20"),
    (3, "2024-03-10")
], ["id", "date_str"])

# Parser et manipuler les dates
date_processed = date_data \
    .withColumn("date", to_date(col("date_str"))) \
    .withColumn("year", year(col("date"))) \
    .withColumn("month", month(col("date"))) \
    .withColumn("day", dayofmonth(col("date"))) \
    .withColumn("day_of_week", dayofweek(col("date"))) \
    .withColumn("next_week", date_add(col("date"), 7)) \
    .withColumn("last_month", add_months(col("date"), -1))

print("\n✅ Manipulation de dates:")
date_processed.show()

# Différence de dates
date_diff = date_data \
    .withColumn("date", to_date(col("date_str"))) \
    .withColumn("today", current_date()) \
    .withColumn("days_ago", datediff(current_date(), col("date")))

print("\n✅ Différence avec aujourd'hui:")
date_diff.select("date", "today", "days_ago").show()

# ========================================
# 7. WINDOW FUNCTIONS
# ========================================
print("\n7. Window Functions")
print("-" * 50)

# Données de ventes par employé
emp_sales = spark.createDataFrame([
    ("Alice", "Sales", 10000),
    ("Bob", "Sales", 12000),
    ("Charlie", "Engineering", 15000),
    ("David", "Engineering", 13000),
    ("Eve", "Sales", 11000),
    ("Frank", "Engineering", 14000)
], ["name", "department", "sales"])

print("\n📋 Ventes par employé:")
emp_sales.show()

# Ranking par département
window_spec = Window.partitionBy("department").orderBy(col("sales").desc())

ranked = emp_sales \
    .withColumn("rank", rank().over(window_spec)) \
    .withColumn("dense_rank", dense_rank().over(window_spec)) \
    .withColumn("row_number", row_number().over(window_spec))

print("\n✅ Ranking par département:")
ranked.show()

# Somme cumulative
window_cumsum = Window.partitionBy("department").orderBy("sales").rowsBetween(Window.unboundedPreceding, Window.currentRow)

cumulative = emp_sales \
    .withColumn("cumulative_sales", sum("sales").over(window_cumsum)) \
    .withColumn("avg_sales_dept", avg("sales").over(Window.partitionBy("department")))

print("\n✅ Somme cumulative par département:")
cumulative.orderBy("department", "sales").show()

# ========================================
# 8. PIVOT ET UNPIVOT
# ========================================
print("\n8. Pivot - Transformer lignes en colonnes")
print("-" * 50)

# Données
pivot_data = spark.createDataFrame([
    ("2024-Q1", "ProductA", 1000),
    ("2024-Q1", "ProductB", 1500),
    ("2024-Q2", "ProductA", 1200),
    ("2024-Q2", "ProductB", 1800),
    ("2024-Q3", "ProductA", 1100),
    ("2024-Q3", "ProductB", 1600)
], ["quarter", "product", "revenue"])

print("\n📋 Données avant pivot:")
pivot_data.show()

# Pivot
pivoted = pivot_data.groupBy("quarter").pivot("product").sum("revenue")
print("\n✅ Après pivot:")
pivoted.show()

# ========================================
# 9. UNION ET UNIONBYNAME
# ========================================
print("\n9. Union - Combiner des DataFrames")
print("-" * 50)

df1 = spark.createDataFrame([
    (1, "Alice"),
    (2, "Bob")
], ["id", "name"])

df2 = spark.createDataFrame([
    (3, "Charlie"),
    (4, "David")
], ["id", "name"])

print("\n📋 DataFrame 1:")
df1.show()

print("\n📋 DataFrame 2:")
df2.show()

# Union
combined = df1.union(df2)
print("\n✅ Union des deux DataFrames:")
combined.show()

# ========================================
# 10. COLLECT_LIST ET COLLECT_SET
# ========================================
print("\n10. Collect_list et collect_set")
print("-" * 50)

orders_data = spark.createDataFrame([
    (1, "ProductA"),
    (1, "ProductB"),
    (1, "ProductA"),  # Doublon
    (2, "ProductC"),
    (2, "ProductD")
], ["customer_id", "product"])

print("\n📋 Commandes:")
orders_data.show()

# Grouper et collecter en liste
grouped = orders_data.groupBy("customer_id").agg(
    collect_list("product").alias("products_list"),
    collect_set("product").alias("products_set")
)

print("\n✅ Produits par client (list vs set):")
grouped.show(truncate=False)

# ========================================
# 11. EXEMPLE COMPLET: ANALYSE VENTES E-COMMERCE
# ========================================
print("\n11. Exemple complet: Analyse e-commerce")
print("-" * 50)

# Données détaillées
detailed_sales = spark.createDataFrame([
    ("2024-01-01", "Electronics", "Laptop", 1200, 2, "Alice"),
    ("2024-01-01", "Books", "Python Guide", 40, 5, "Bob"),
    ("2024-01-02", "Electronics", "Phone", 800, 3, "Alice"),
    ("2024-01-02", "Books", "Spark Book", 50, 2, "Charlie"),
    ("2024-01-03", "Electronics", "Laptop", 1200, 1, "Bob"),
    ("2024-01-03", "Electronics", "Mouse", 25, 4, "Alice"),
    ("2024-01-04", "Books", "Python Guide", 40, 3, "David"),
], ["date", "category", "product", "price", "quantity", "customer"])

# Calculer revenue
detailed_sales = detailed_sales.withColumn("revenue", col("price") * col("quantity"))

print("\n📋 Toutes les ventes:")
detailed_sales.show()

# Analyse 1: Top produits
print("\n✅ Top 3 produits par revenue:")
top_products = detailed_sales.groupBy("product").agg(
    sum("revenue").alias("total_revenue"),
    sum("quantity").alias("total_quantity")
).orderBy(col("total_revenue").desc()).limit(3)

top_products.show()

# Analyse 2: Revenus par catégorie et date
print("\n✅ Revenus par catégorie et date:")
category_daily = detailed_sales.groupBy("date", "category").agg(
    sum("revenue").alias("daily_revenue")
).orderBy("date", "category")

category_daily.show()

# Analyse 3: Top clients
print("\n✅ Top clients:")
top_customers = detailed_sales.groupBy("customer").agg(
    count("*").alias("num_orders"),
    sum("revenue").alias("total_spent")
).orderBy(col("total_spent").desc())

top_customers.show()

# Analyse 4: Panier moyen par catégorie
print("\n✅ Panier moyen par catégorie:")
avg_basket = detailed_sales.groupBy("category").agg(
    avg("revenue").alias("avg_order_value"),
    count("*").alias("num_orders")
).orderBy(col("avg_order_value").desc())

avg_basket.show()

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF DES OPÉRATIONS AVANCÉES")
print("=" * 80)

print("""
Agrégations:
  df.groupBy("col").agg(...)     - Grouper et agréger
  sum(), avg(), count(), min(), max() - Fonctions d'agrégation
  collect_list(), collect_set()  - Collecter en liste/set

Joins:
  df1.join(df2, "key", "type")   - Types: inner, left, right, outer

Window Functions:
  Window.partitionBy()           - Partitionner
  rank(), dense_rank(), row_number() - Ranking
  lead(), lag()                  - Valeurs suivante/précédente

Transformations:
  upper(), lower(), trim()       - Manipulation strings
  to_date(), year(), month()     - Manipulation dates
  when().otherwise()             - Conditions

Autres:
  df.pivot("col")                - Pivoter
  df1.union(df2)                 - Combiner DataFrames
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
