"""
Window Functions - Calculs sur fenêtres de lignes

Ce script montre :
- Ranking functions (ROW_NUMBER, RANK, DENSE_RANK)
- Analytical functions (LEAD, LAG, FIRST_VALUE, LAST_VALUE)
- Aggregate window functions (SUM, AVG avec OVER)
- Window frame specifications
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col
from pyspark.sql.window import Window

# Créer SparkSession
spark = SparkSession.builder \
    .appName("Window Functions") \
    .master("local[*]") \
    .getOrCreate()

print("=" * 80)
print("WINDOW FUNCTIONS")
print("=" * 80)

# ========================================
# DONNÉES DE TEST
# ========================================

# Employés avec salaires
employees = spark.createDataFrame([
    ("Alice", "Sales", 50000),
    ("Bob", "Sales", 60000),
    ("Charlie", "Engineering", 80000),
    ("David", "Engineering", 70000),
    ("Eve", "Sales", 55000),
    ("Frank", "Engineering", 75000),
    ("Grace", "HR", 45000),
    ("Henry", "HR", 48000)
], ["name", "department", "salary"])

employees.createOrReplaceTempView("employees")

# Ventes quotidiennes
daily_sales = spark.createDataFrame([
    ("2024-01-01", 1000),
    ("2024-01-02", 1500),
    ("2024-01-03", 1200),
    ("2024-01-04", 1800),
    ("2024-01-05", 1400),
    ("2024-01-06", 1600),
    ("2024-01-07", 2000)
], ["date", "sales"])

daily_sales.createOrReplaceTempView("daily_sales")

print("\n📋 Données employés:")
employees.show()

print("\n📋 Ventes quotidiennes:")
daily_sales.show()

# ========================================
# 1. RANKING FUNCTIONS
# ========================================
print("\n" + "=" * 80)
print("1. RANKING FUNCTIONS")
print("=" * 80)

# ROW_NUMBER
print("\n✅ ROW_NUMBER - Numéro séquentiel par département:")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num
    FROM employees
    ORDER BY department, row_num
""").show()

# RANK (avec égalités, saute des numéros)
print("\n✅ RANK - Avec égalités (saute):")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
    ORDER BY department, rank
""").show()

# DENSE_RANK (avec égalités, ne saute pas)
print("\n✅ DENSE_RANK - Avec égalités (ne saute pas):")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dense_rank
    FROM employees
    ORDER BY department, dense_rank
""").show()

# Comparaison des 3 rankings
print("\n✅ Comparaison ROW_NUMBER vs RANK vs DENSE_RANK:")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dense_rank
    FROM employees
    ORDER BY department, salary DESC
""").show()

# NTILE - Diviser en N groupes
print("\n✅ NTILE - Diviser en quartiles (4 groupes):")
spark.sql("""
    SELECT
        name,
        salary,
        NTILE(4) OVER (ORDER BY salary DESC) as quartile
    FROM employees
    ORDER BY quartile, salary DESC
""").show()

# ========================================
# 2. TOP N PAR GROUPE
# ========================================
print("\n" + "=" * 80)
print("2. TOP N PAR GROUPE")
print("=" * 80)

# Top 2 salaires par département
print("\n✅ Top 2 salaires par département:")
spark.sql("""
    SELECT * FROM (
        SELECT
            name,
            department,
            salary,
            ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
        FROM employees
    ) ranked
    WHERE rank <= 2
    ORDER BY department, rank
""").show()

# ========================================
# 3. ANALYTICAL FUNCTIONS (LEAD, LAG)
# ========================================
print("\n" + "=" * 80)
print("3. ANALYTICAL FUNCTIONS")
print("=" * 80)

# LEAD - Valeur suivante
print("\n✅ LEAD - Ventes du jour suivant:")
spark.sql("""
    SELECT
        date,
        sales,
        LEAD(sales, 1) OVER (ORDER BY date) as next_day_sales,
        LEAD(sales, 1) OVER (ORDER BY date) - sales as diff_next_day
    FROM daily_sales
""").show()

# LAG - Valeur précédente
print("\n✅ LAG - Ventes du jour précédent:")
spark.sql("""
    SELECT
        date,
        sales,
        LAG(sales, 1) OVER (ORDER BY date) as prev_day_sales,
        sales - LAG(sales, 1) OVER (ORDER BY date) as diff_prev_day
    FROM daily_sales
""").show()

# Comparer avec jour précédent ET suivant
print("\n✅ Comparer avec jour précédent et suivant:")
spark.sql("""
    SELECT
        date,
        sales,
        LAG(sales) OVER (ORDER BY date) as prev_day,
        LEAD(sales) OVER (ORDER BY date) as next_day,
        sales - LAG(sales) OVER (ORDER BY date) as growth
    FROM daily_sales
""").show()

# ========================================
# 4. FIRST_VALUE et LAST_VALUE
# ========================================
print("\n" + "=" * 80)
print("4. FIRST_VALUE et LAST_VALUE")
print("=" * 80)

print("\n✅ Comparer avec le salaire le plus haut/bas du département:")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        FIRST_VALUE(salary) OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) as highest_in_dept,
        LAST_VALUE(salary) OVER (
            PARTITION BY department
            ORDER BY salary DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as lowest_in_dept
    FROM employees
    ORDER BY department, salary DESC
""").show()

# ========================================
# 5. AGGREGATE WINDOW FUNCTIONS
# ========================================
print("\n" + "=" * 80)
print("5. AGGREGATE WINDOW FUNCTIONS")
print("=" * 80)

# Somme cumulative
print("\n✅ Somme cumulative des ventes:")
spark.sql("""
    SELECT
        date,
        sales,
        SUM(sales) OVER (
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_sales
    FROM daily_sales
""").show()

# Moyenne mobile (3 jours)
print("\n✅ Moyenne mobile sur 3 jours:")
spark.sql("""
    SELECT
        date,
        sales,
        AVG(sales) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as moving_avg_3days
    FROM daily_sales
""").show()

# Comparer avec la moyenne du département
print("\n✅ Comparer salaire avec moyenne du département:")
spark.sql("""
    SELECT
        name,
        department,
        salary,
        AVG(salary) OVER (PARTITION BY department) as dept_avg_salary,
        salary - AVG(salary) OVER (PARTITION BY department) as diff_from_avg
    FROM employees
    ORDER BY department, salary DESC
""").show()

# ========================================
# 6. WINDOW FRAME SPECIFICATIONS
# ========================================
print("\n" + "=" * 80)
print("6. WINDOW FRAME SPECIFICATIONS")
print("=" * 80)

print("\n✅ Différentes fenêtres:")
spark.sql("""
    SELECT
        date,
        sales,
        -- Somme depuis le début jusqu'à maintenant
        SUM(sales) OVER (
            ORDER BY date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumsum_start_to_current,

        -- Somme des 2 jours précédents + aujourd'hui
        SUM(sales) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as sum_3days,

        -- Somme de 1 avant à 1 après (fenêtre de 3)
        SUM(sales) OVER (
            ORDER BY date
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ) as sum_window_3
    FROM daily_sales
""").show()

# ========================================
# 7. EXEMPLE COMPLET: ANALYSE RH
# ========================================
print("\n" + "=" * 80)
print("7. EXEMPLE COMPLET: ANALYSE RH")
print("=" * 80)

print("\n✅ Analyse complète des salaires:")
result = spark.sql("""
    SELECT
        name,
        department,
        salary,

        -- Ranking dans le département
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank,

        -- Salaire moyen du département
        ROUND(AVG(salary) OVER (PARTITION BY department), 2) as dept_avg_salary,

        -- Différence avec la moyenne
        ROUND(salary - AVG(salary) OVER (PARTITION BY department), 2) as diff_from_avg,

        -- Pourcentage vs moyenne
        ROUND((salary / AVG(salary) OVER (PARTITION BY department) - 1) * 100, 2) as pct_vs_avg,

        -- Salaire le plus haut du département
        FIRST_VALUE(salary) OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) as highest_in_dept,

        -- Quartile
        NTILE(4) OVER (ORDER BY salary DESC) as salary_quartile

    FROM employees
    ORDER BY department, salary DESC
""")

result.show(truncate=False)

# ========================================
# 8. UTILISER WINDOW FUNCTIONS EN DATAFRAME API
# ========================================
print("\n" + "=" * 80)
print("8. WINDOW FUNCTIONS EN DATAFRAME API")
print("=" * 80)

from pyspark.sql.functions import row_number, rank, dense_rank, lag, lead, avg, sum as spark_sum
from pyspark.sql.window import Window

# Définir une window spec
window_spec = Window.partitionBy("department").orderBy(col("salary").desc())

# Appliquer des window functions
print("\n✅ Window functions avec DataFrame API:")
result_df = employees \
    .withColumn("row_num", row_number().over(window_spec)) \
    .withColumn("rank", rank().over(window_spec)) \
    .withColumn("dept_avg_salary", avg("salary").over(Window.partitionBy("department")))

result_df.orderBy("department", "salary").show()

# ========================================
# 9. RUNNING TOTALS ET PERCENTAGES
# ========================================
print("\n" + "=" * 80)
print("9. RUNNING TOTALS ET PERCENTAGES")
print("=" * 80)

print("\n✅ Pourcentage du total et cumul:")
spark.sql("""
    SELECT
        date,
        sales,

        -- Pourcentage du total
        ROUND(sales * 100.0 / SUM(sales) OVER (), 2) as pct_of_total,

        -- Somme cumulative
        SUM(sales) OVER (ORDER BY date) as cumulative_sales,

        -- Pourcentage cumulatif
        ROUND(
            SUM(sales) OVER (ORDER BY date) * 100.0 / SUM(sales) OVER (),
            2
        ) as cumulative_pct

    FROM daily_sales
""").show()

# ========================================
# RÉCAPITULATIF
# ========================================
print("\n" + "=" * 80)
print("RÉCAPITULATIF WINDOW FUNCTIONS")
print("=" * 80)

print("""
Ranking Functions:
  ROW_NUMBER()      - Numéro séquentiel (pas d'égalités)
  RANK()            - Ranking avec égalités (saute des numéros)
  DENSE_RANK()      - Ranking avec égalités (ne saute pas)
  NTILE(n)          - Divise en n groupes égaux

Analytical Functions:
  LEAD(col, n)      - Valeur n lignes après
  LAG(col, n)       - Valeur n lignes avant
  FIRST_VALUE(col)  - Première valeur de la fenêtre
  LAST_VALUE(col)   - Dernière valeur de la fenêtre

Aggregate Functions:
  SUM() OVER (...)  - Somme sur fenêtre
  AVG() OVER (...)  - Moyenne sur fenêtre
  MIN/MAX/COUNT     - Autres agrégations

Window Specification:
  PARTITION BY      - Diviser en groupes
  ORDER BY          - Trier dans chaque groupe
  ROWS BETWEEN      - Définir la fenêtre (frame)

Frame Specifications:
  UNBOUNDED PRECEDING       - Depuis le début
  CURRENT ROW               - Ligne actuelle
  UNBOUNDED FOLLOWING       - Jusqu'à la fin
  N PRECEDING/FOLLOWING     - N lignes avant/après
""")

# Arrêter SparkSession
spark.stop()
print("\n✅ SparkSession arrêtée")
