"""
Spark SQL - Requêtes SQL sur DataFrames

Ce script montre comment :
- Créer des temporary views
- Exécuter des requêtes SQL
- Utiliser des agrégations et joins en SQL
- Combiner SQL et DataFrame API
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Créer SparkSession
spark = SparkSession.builder \
    .appName("Spark SQL Queries") \
    .master("local[*]") \
    .getOrCreate()

print("=" * 80)
print("SPARK SQL - REQUÊTES SQL")
print("=" * 80)

# ========================================
# 1. CRÉER DES TEMPORARY VIEWS
# ========================================
print("\n1. Créer des Temporary Views")
print("-" * 50)

# Créer des DataFrames
employees = spark.createDataFrame([
    (1, "Alice", 25, 1, 50000),
    (2, "Bob", 30, 2, 60000),
    (3, "Charlie", 35, 1, 55000),
    (4, "David", 28, 3, 52000),
    (5, "Eve", 32, 2, 58000)
], ["emp_id", "name", "age", "dept_id", "salary"])

departments = spark.createDataFrame([
    (1, "Sales", "Paris"),
    (2, "Engineering", "Lyon"),
    (3, "HR", "Marseille")
], ["dept_id", "dept_name", "location"])

# Créer des views
employees.createOrReplaceTempView("employees")
departments.createOrReplaceTempView("departments")

print("✅ Views créées: employees, departments")

# ========================================
# 2. SELECT BASIQUE
# ========================================
print("\n2. SELECT basique")
print("-" * 50)

print("\n📋 Tous les employés:")
spark.sql("SELECT * FROM employees").show()

print("\n📋 Colonnes spécifiques:")
spark.sql("SELECT name, age, salary FROM employees").show()

print("\n📋 Avec alias:")
spark.sql("""
    SELECT
        name AS employee_name,
        age AS years,
        salary / 12 AS monthly_salary
    FROM employees
""").show()

# ========================================
# 3. WHERE - FILTRAGE
# ========================================
print("\n3. WHERE - Filtrage")
print("-" * 50)

print("\n✅ Age > 28:")
spark.sql("SELECT * FROM employees WHERE age > 28").show()

print("\n✅ Multiples conditions (AND):")
spark.sql("""
    SELECT * FROM employees
    WHERE age > 28 AND salary > 55000
""").show()

print("\n✅ Condition OR:")
spark.sql("""
    SELECT * FROM employees
    WHERE age < 27 OR salary > 57000
""").show()

print("\n✅ IN:")
spark.sql("""
    SELECT * FROM employees
    WHERE dept_id IN (1, 2)
""").show()

print("\n✅ BETWEEN:")
spark.sql("""
    SELECT * FROM employees
    WHERE age BETWEEN 28 AND 32
""").show()

print("\n✅ LIKE (pattern matching):")
spark.sql("""
    SELECT * FROM employees
    WHERE name LIKE 'A%'
""").show()

# ========================================
# 4. ORDER BY - TRI
# ========================================
print("\n4. ORDER BY - Tri")
print("-" * 50)

print("\n✅ Tri par age (croissant):")
spark.sql("SELECT * FROM employees ORDER BY age").show()

print("\n✅ Tri par salary (décroissant):")
spark.sql("SELECT * FROM employees ORDER BY salary DESC").show()

print("\n✅ Tri multiple:")
spark.sql("SELECT * FROM employees ORDER BY dept_id, salary DESC").show()

# ========================================
# 5. GROUP BY - AGRÉGATIONS
# ========================================
print("\n5. GROUP BY - Agrégations")
print("-" * 50)

print("\n✅ Compter par département:")
spark.sql("""
    SELECT dept_id, COUNT(*) as num_employees
    FROM employees
    GROUP BY dept_id
    ORDER BY dept_id
""").show()

print("\n✅ Agrégations multiples:")
spark.sql("""
    SELECT
        dept_id,
        COUNT(*) as num_employees,
        AVG(salary) as avg_salary,
        MIN(salary) as min_salary,
        MAX(salary) as max_salary,
        SUM(salary) as total_salary
    FROM employees
    GROUP BY dept_id
    ORDER BY dept_id
""").show()

print("\n✅ HAVING (filtre après agrégation):")
spark.sql("""
    SELECT dept_id, AVG(salary) as avg_salary
    FROM employees
    GROUP BY dept_id
    HAVING avg_salary > 53000
""").show()

# ========================================
# 6. JOINS
# ========================================
print("\n6. JOINS")
print("-" * 50)

print("\n✅ INNER JOIN:")
spark.sql("""
    SELECT e.name, e.salary, d.dept_name, d.location
    FROM employees e
    INNER JOIN departments d ON e.dept_id = d.dept_id
    ORDER BY e.name
""").show()

print("\n✅ Statistiques par département (avec JOIN):")
spark.sql("""
    SELECT
        d.dept_name,
        d.location,
        COUNT(*) as num_employees,
        AVG(e.salary) as avg_salary
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
    GROUP BY d.dept_name, d.location
    ORDER BY avg_salary DESC
""").show()

# ========================================
# 7. SOUS-REQUÊTES
# ========================================
print("\n7. Sous-requêtes")
print("-" * 50)

print("\n✅ Employés au-dessus de la moyenne:")
spark.sql("""
    SELECT name, salary
    FROM employees
    WHERE salary > (SELECT AVG(salary) FROM employees)
    ORDER BY salary DESC
""").show()

print("\n✅ Sous-requête dans FROM:")
spark.sql("""
    SELECT dept_id, avg_salary
    FROM (
        SELECT dept_id, AVG(salary) as avg_salary
        FROM employees
        GROUP BY dept_id
    ) AS dept_stats
    WHERE avg_salary > 54000
""").show()

# ========================================
# 8. CTE (Common Table Expression)
# ========================================
print("\n8. CTE - Common Table Expression")
print("-" * 50)

print("\n✅ WITH clause:")
result = spark.sql("""
    WITH high_earners AS (
        SELECT * FROM employees WHERE salary > 54000
    ),
    dept_stats AS (
        SELECT dept_id, AVG(salary) as avg_salary
        FROM employees
        GROUP BY dept_id
    )
    SELECT
        h.name,
        h.salary,
        d.avg_salary as dept_avg
    FROM high_earners h
    JOIN dept_stats d ON h.dept_id = d.dept_id
""")
result.show()

# ========================================
# 9. FONCTIONS D'AGRÉGATION
# ========================================
print("\n9. Fonctions d'agrégation")
print("-" * 50)

print("\n✅ Statistiques globales:")
spark.sql("""
    SELECT
        COUNT(*) as total_employees,
        COUNT(DISTINCT dept_id) as num_departments,
        SUM(salary) as total_payroll,
        AVG(salary) as avg_salary,
        MIN(salary) as min_salary,
        MAX(salary) as max_salary,
        STDDEV(salary) as salary_stddev
    FROM employees
""").show()

# ========================================
# 10. ANALYSE DE VENTES
# ========================================
print("\n10. Exemple complet: Analyse de ventes")
print("-" * 50)

# Créer des données de ventes
sales = spark.createDataFrame([
    ("2024-01-01", "Electronics", "Laptop", 1200, 2),
    ("2024-01-01", "Books", "Python Guide", 40, 5),
    ("2024-01-02", "Electronics", "Phone", 800, 3),
    ("2024-01-02", "Books", "Spark Book", 50, 2),
    ("2024-01-03", "Electronics", "Laptop", 1200, 1),
    ("2024-01-03", "Books", "Python Guide", 40, 3),
    ("2024-01-04", "Electronics", "Mouse", 25, 4),
], ["date", "category", "product", "price", "quantity"])

sales.createOrReplaceTempView("sales")

print("\n📋 Données de ventes:")
spark.sql("SELECT * FROM sales").show()

# Analyse 1: Revenus par catégorie
print("\n✅ Revenus totaux par catégorie:")
spark.sql("""
    SELECT
        category,
        SUM(price * quantity) as total_revenue,
        COUNT(*) as num_orders,
        AVG(price * quantity) as avg_order_value
    FROM sales
    GROUP BY category
    ORDER BY total_revenue DESC
""").show()

# Analyse 2: Top produits
print("\n✅ Top 3 produits:")
spark.sql("""
    SELECT
        product,
        category,
        SUM(quantity) as total_quantity,
        SUM(price * quantity) as total_revenue
    FROM sales
    GROUP BY product, category
    ORDER BY total_revenue DESC
    LIMIT 3
""").show()

# Analyse 3: Ventes quotidiennes
print("\n✅ Ventes quotidiennes:")
spark.sql("""
    SELECT
        date,
        COUNT(*) as num_orders,
        SUM(price * quantity) as daily_revenue
    FROM sales
    GROUP BY date
    ORDER BY date
""").show()

# Analyse 4: Produits par catégorie
print("\n✅ Nombre de produits distincts par catégorie:")
spark.sql("""
    SELECT
        category,
        COUNT(DISTINCT product) as num_products,
        SUM(quantity) as total_units_sold
    FROM sales
    GROUP BY category
""").show()

# ========================================
# 11. COMBINER SQL ET DATAFRAME API
# ========================================
print("\n11. Combiner SQL et DataFrame API")
print("-" * 50)

# Utiliser SQL puis DataFrame API
print("\n✅ SQL → DataFrame API:")
sql_result = spark.sql("SELECT * FROM employees WHERE age > 28")
final_result = sql_result.filter(col("salary") > 54000).orderBy(col("salary").desc())
final_result.show()

# Utiliser DataFrame API puis SQL
print("\n✅ DataFrame API → SQL:")
df_filtered = employees.filter(col("dept_id").isin(1, 2))
df_filtered.createOrReplaceTempView("filtered_employees")
spark.sql("SELECT * FROM filtered_employees ORDER BY salary DESC").show()

# ========================================
# 12. FONCTIONS STRING ET DATE
# ========================================
print("\n12. Fonctions String et Date")
print("-" * 50)

# Créer des données avec dates
events = spark.createDataFrame([
    (1, "Meeting with client", "2024-01-15 10:00:00"),
    (2, "Project deadline", "2024-02-20 17:00:00"),
    (3, "Team lunch", "2024-03-10 12:30:00")
], ["id", "title", "event_date"])

events.createOrReplaceTempView("events")

print("\n✅ Manipulation de strings:")
spark.sql("""
    SELECT
        id,
        title,
        UPPER(title) as title_upper,
        LOWER(title) as title_lower,
        LENGTH(title) as title_length,
        SUBSTRING(title, 1, 7) as first_7_chars
    FROM events
""").show(truncate=False)

print("\n✅ Manipulation de dates:")
spark.sql("""
    SELECT
        id,
        title,
        event_date,
        TO_DATE(event_date) as date_only,
        YEAR(event_date) as year,
        MONTH(event_date) as month,
        DAYOFMONTH(event_date) as day,
        DAYOFWEEK(event_date) as day_of_week
    FROM events
""").show()

# ========================================
# 13. EXPLAIN - VOIR LE PLAN D'EXÉCUTION
# ========================================
print("\n13. Voir le plan d'exécution")
print("-" * 50)

query = spark.sql("""
    SELECT e.name, d.dept_name
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
    WHERE e.salary > 54000
""")

print("\n✅ Plan d'exécution:")
query.explain(extended=True)

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF SQL")
print("=" * 80)

print("""
Commandes SQL de base:
  SELECT ... FROM ...           - Sélection
  WHERE                         - Filtrage
  ORDER BY                      - Tri
  GROUP BY                      - Agrégation
  HAVING                        - Filtre après agrégation

Joins:
  INNER JOIN                    - Intersection
  LEFT JOIN                     - Toutes les lignes de gauche
  RIGHT JOIN                    - Toutes les lignes de droite
  FULL OUTER JOIN               - Toutes les lignes

Fonctions d'agrégation:
  COUNT, SUM, AVG, MIN, MAX     - Statistiques
  COUNT(DISTINCT col)           - Valeurs uniques
  STDDEV, VARIANCE              - Écart-type, variance

Sous-requêtes et CTE:
  WHERE col IN (SELECT ...)     - Sous-requête
  WITH name AS (...)            - CTE (Common Table Expression)

Temporary Views:
  df.createOrReplaceTempView()  - Créer une view SQL
  spark.sql("SELECT ...")       - Exécuter du SQL
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
