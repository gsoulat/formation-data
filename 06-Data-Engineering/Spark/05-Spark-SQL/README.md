# Spark SQL - Requêtes SQL sur données distribuées

## Table des matières

1. [Introduction à Spark SQL](#introduction-à-spark-sql)
2. [Catalog et Tables](#catalog-et-tables)
3. [Temporary Views](#temporary-views)
4. [Requêtes SQL](#requêtes-sql)
5. [Window Functions](#window-functions)
6. [User Defined Functions (UDF)](#user-defined-functions-udf)
7. [Optimisation avec Catalyst](#optimisation-avec-catalyst)
8. [Exemples pratiques](#exemples-pratiques)

---

## Introduction à Spark SQL

### Qu'est-ce que Spark SQL ?

**Spark SQL** est un module de Spark pour traiter des données structurées en utilisant SQL et l'API DataFrame.

### Pourquoi utiliser Spark SQL ?

**Avantages** :
- Syntaxe SQL familière pour les analystes
- Optimisations automatiques (Catalyst)
- Interopérabilité DataFrame ↔ SQL
- Support des fonctions SQL standard
- Requêtes complexes simplifiées

**Cas d'usage** :
- Analytics et reporting
- Migration depuis bases de données traditionnelles
- Collaboration avec équipes SQL
- Requêtes ad-hoc

### Architecture Spark SQL

```
SQL Query
    ↓
Catalyst Optimizer (Parse → Analyze → Optimize)
    ↓
Logical Plan
    ↓
Physical Plan
    ↓
Tungsten Execution Engine
    ↓
RDD Execution
```

---

## Catalog et Tables

### Qu'est-ce que le Catalog ?

Le **Catalog** est le métastore qui contient :
- Tables (managed et external)
- Databases
- Functions
- Views

### Bases de données

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Spark SQL") \
    .enableHiveSupport() \
    .getOrCreate()

# Créer une base de données
spark.sql("CREATE DATABASE IF NOT EXISTS sales_db")

# Lister les bases de données
spark.sql("SHOW DATABASES").show()

# Utiliser une base de données
spark.sql("USE sales_db")

# Base de données actuelle
spark.sql("SELECT current_database()").show()

# Supprimer une base de données
spark.sql("DROP DATABASE IF EXISTS sales_db CASCADE")
```

### Tables managed vs external

**Managed Tables** :
- Spark gère les données ET les métadonnées
- Suppression de la table = suppression des données

```python
# Créer une managed table
df.write.saveAsTable("users")

# Ou avec SQL
spark.sql("""
    CREATE TABLE users (
        id INT,
        name STRING,
        age INT
    )
""")
```

**External Tables** :
- Spark gère seulement les métadonnées
- Suppression de la table ≠ suppression des données

```python
# Créer une external table
df.write.option("path", "/data/users").saveAsTable("users")

# Ou avec SQL
spark.sql("""
    CREATE EXTERNAL TABLE users (
        id INT,
        name STRING,
        age INT
    )
    LOCATION '/data/users'
""")
```

### Opérations sur tables

```python
# Lister les tables
spark.sql("SHOW TABLES").show()

# Décrire une table
spark.sql("DESCRIBE users").show()
spark.sql("DESCRIBE EXTENDED users").show()

# Voir le DDL
spark.sql("SHOW CREATE TABLE users").show()

# Supprimer une table
spark.sql("DROP TABLE IF EXISTS users")
```

---

## Temporary Views

### Qu'est-ce qu'une view ?

Une **view** est une table virtuelle basée sur le résultat d'une requête SQL.

### Temporary Views

```python
# Créer un DataFrame
df = spark.createDataFrame([
    (1, "Alice", 25, "Paris"),
    (2, "Bob", 30, "Lyon"),
    (3, "Charlie", 35, "Marseille")
], ["id", "name", "age", "city"])

# Créer une temporary view
df.createOrReplaceTempView("users")

# Utiliser SQL sur la view
result = spark.sql("SELECT * FROM users WHERE age > 25")
result.show()
```

### Global Temporary Views

```python
# Créer une global temp view (visible entre sessions)
df.createOrReplaceGlobalTempView("global_users")

# Accéder via global_temp
spark.sql("SELECT * FROM global_temp.global_users").show()
```

### Différences

| Type | Scope | Namespace | Durée |
|------|-------|-----------|-------|
| **Temporary View** | Session | Default | Session |
| **Global Temp View** | Application | global_temp | Application |
| **Table** | Persistante | Database | Permanente |

---

## Requêtes SQL

### SELECT basique

```sql
-- Sélection simple
SELECT * FROM users;

-- Colonnes spécifiques
SELECT name, age FROM users;

-- Avec alias
SELECT name AS full_name, age AS years FROM users;

-- Distinct
SELECT DISTINCT city FROM users;

-- Limit
SELECT * FROM users LIMIT 5;
```

### WHERE - Filtrage

```sql
-- Comparaisons
SELECT * FROM users WHERE age > 25;
SELECT * FROM users WHERE city = 'Paris';
SELECT * FROM users WHERE age BETWEEN 25 AND 35;

-- Opérateurs logiques
SELECT * FROM users WHERE age > 25 AND city = 'Paris';
SELECT * FROM users WHERE city = 'Paris' OR city = 'Lyon';
SELECT * FROM users WHERE age NOT IN (25, 30);

-- Pattern matching
SELECT * FROM users WHERE name LIKE 'A%';  -- Commence par A
SELECT * FROM users WHERE name LIKE '%e';  -- Finit par e
SELECT * FROM users WHERE email RLIKE '.*@gmail.com';  -- Regex

-- NULL
SELECT * FROM users WHERE age IS NULL;
SELECT * FROM users WHERE age IS NOT NULL;
```

### ORDER BY - Tri

```sql
-- Tri croissant
SELECT * FROM users ORDER BY age;

-- Tri décroissant
SELECT * FROM users ORDER BY age DESC;

-- Tri multiple
SELECT * FROM users ORDER BY city, age DESC;

-- NULLS FIRST/LAST
SELECT * FROM users ORDER BY age NULLS FIRST;
```

### GROUP BY - Agrégation

```sql
-- Compter par ville
SELECT city, COUNT(*) as count
FROM users
GROUP BY city;

-- Agrégations multiples
SELECT
    city,
    COUNT(*) as num_users,
    AVG(age) as avg_age,
    MIN(age) as min_age,
    MAX(age) as max_age
FROM users
GROUP BY city;

-- HAVING (filtre après agrégation)
SELECT city, COUNT(*) as count
FROM users
GROUP BY city
HAVING count > 2;
```

### Fonctions d'agrégation

```sql
COUNT(*)              -- Nombre de lignes
COUNT(DISTINCT col)   -- Valeurs uniques
SUM(col)              -- Somme
AVG(col)              -- Moyenne
MIN(col)              -- Minimum
MAX(col)              -- Maximum
STDDEV(col)           -- Écart-type
VARIANCE(col)         -- Variance
COLLECT_LIST(col)     -- Liste des valeurs
COLLECT_SET(col)      -- Set des valeurs (uniques)
```

### JOIN

```sql
-- INNER JOIN
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- LEFT JOIN
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- RIGHT JOIN
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- FULL OUTER JOIN
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

-- CROSS JOIN
SELECT * FROM table1 CROSS JOIN table2;

-- Multiple joins
SELECT o.order_id, c.name, p.product_name
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN products p ON o.product_id = p.id;
```

### Sous-requêtes

```sql
-- Sous-requête dans WHERE
SELECT * FROM users
WHERE age > (SELECT AVG(age) FROM users);

-- Sous-requête dans FROM
SELECT city, avg_salary
FROM (
    SELECT city, AVG(salary) as avg_salary
    FROM employees
    GROUP BY city
) AS city_stats
WHERE avg_salary > 50000;

-- EXISTS
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
);

-- IN
SELECT * FROM users
WHERE city IN (SELECT city FROM top_cities);
```

### CTE (Common Table Expression)

```sql
-- WITH clause
WITH high_earners AS (
    SELECT * FROM employees WHERE salary > 100000
),
departments_stats AS (
    SELECT dept_id, AVG(salary) as avg_salary
    FROM employees
    GROUP BY dept_id
)
SELECT h.name, d.avg_salary
FROM high_earners h
JOIN departments_stats d ON h.dept_id = d.dept_id;
```

### UNION

```sql
-- UNION (élimine les doublons)
SELECT name FROM employees
UNION
SELECT name FROM contractors;

-- UNION ALL (garde les doublons)
SELECT name FROM employees
UNION ALL
SELECT name FROM contractors;
```

---

## Window Functions

### Qu'est-ce qu'une window function ?

Les **window functions** effectuent des calculs sur un ensemble de lignes (fenêtre) liées à la ligne actuelle.

### OVER clause

```sql
SELECT
    name,
    department,
    salary,
    AVG(salary) OVER (PARTITION BY department) as dept_avg_salary
FROM employees;
```

### Ranking Functions

```sql
-- ROW_NUMBER : numéro séquentiel
SELECT
    name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num
FROM employees;

-- RANK : avec égalités (saute des numéros)
SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank
FROM employees;

-- DENSE_RANK : avec égalités (ne saute pas)
SELECT
    name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
FROM employees;

-- NTILE : divise en N groupes
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) as quartile
FROM employees;
```

### Analytical Functions

```sql
-- LEAD : valeur suivante
SELECT
    date,
    revenue,
    LEAD(revenue, 1) OVER (ORDER BY date) as next_day_revenue
FROM daily_sales;

-- LAG : valeur précédente
SELECT
    date,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY date) as prev_day_revenue
FROM daily_sales;

-- FIRST_VALUE et LAST_VALUE
SELECT
    name,
    department,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary DESC) as highest_salary,
    LAST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary DESC) as lowest_salary
FROM employees;
```

### Aggregate Window Functions

```sql
-- Somme cumulative
SELECT
    date,
    sales,
    SUM(sales) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cumulative_sales
FROM daily_sales;

-- Moyenne mobile (3 jours)
SELECT
    date,
    temperature,
    AVG(temperature) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3days
FROM weather;
```

### Window Frame Specification

```sql
-- ROWS : lignes physiques
ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING

-- RANGE : valeurs logiques
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Exemples
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -- Du début à maintenant
ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING          -- 3 avant et 3 après
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING  -- De maintenant à la fin
```

---

## User Defined Functions (UDF)

### Qu'est-ce qu'une UDF ?

Une **UDF** (User Defined Function) permet de créer des fonctions personnalisées utilisables en SQL.

### Créer une UDF simple

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType, IntegerType

# Fonction Python
def categorize_age(age):
    if age < 18:
        return "Minor"
    elif age < 65:
        return "Adult"
    else:
        return "Senior"

# Enregistrer comme UDF
categorize_age_udf = udf(categorize_age, StringType())

# Utiliser dans DataFrame
df = df.withColumn("age_category", categorize_age_udf(col("age")))

# Enregistrer pour SQL
spark.udf.register("categorize_age", categorize_age, StringType())

# Utiliser en SQL
spark.sql("""
    SELECT name, age, categorize_age(age) as category
    FROM users
""").show()
```

### UDF avec décorateur

```python
from pyspark.sql.functions import udf

@udf(returnType=StringType())
def upper_case(s):
    return s.upper() if s else None

# Utiliser
df = df.withColumn("name_upper", upper_case(col("name")))
```

### Pandas UDF (plus performant)

```python
from pyspark.sql.functions import pandas_udf
import pandas as pd

@pandas_udf(StringType())
def upper_case_pandas(s: pd.Series) -> pd.Series:
    return s.str.upper()

# Utiliser
df = df.withColumn("name_upper", upper_case_pandas(col("name")))
```

### UDF d'agrégation

```python
from pyspark.sql.functions import pandas_udf
from pyspark.sql.types import DoubleType

@pandas_udf(DoubleType())
def custom_mean(s: pd.Series) -> float:
    return s.mean()

# Utiliser
df.groupBy("category").agg(custom_mean(col("value")).alias("avg_value")).show()
```

---

## Optimisation avec Catalyst

### Qu'est-ce que Catalyst ?

**Catalyst** est l'optimiseur de requêtes de Spark SQL qui transforme les requêtes en plans d'exécution optimisés.

### Phases d'optimisation

```
1. Analysis      : Résolution des noms, types
2. Logical Optimization : Règles logiques
3. Physical Planning    : Plans physiques
4. Code Generation      : Génération de bytecode
```

### Optimisations automatiques

**Predicate Pushdown** :
```python
# Spark va pousser le filtre au niveau de la lecture
df = spark.read.parquet("data.parquet") \
    .filter(col("age") > 25)

# Parquet ne lira que les blocs nécessaires
```

**Column Pruning** :
```python
# Spark ne lira que les colonnes nécessaires
df = spark.read.parquet("data.parquet") \
    .select("name", "age")

# Ignore les autres colonnes
```

**Constant Folding** :
```sql
-- Spark calcule 2 + 3 une seule fois
SELECT name, age, 2 + 3 as five FROM users;
```

**Join Reordering** :
```python
# Spark réordonne les joins pour minimiser les shuffles
```

### Voir le plan d'exécution

```python
# Plan logique
df.explain(True)

# Plan physique
df.explain()

# Exemple
df = spark.sql("SELECT * FROM users WHERE age > 25")
df.explain(extended=True)

"""
== Parsed Logical Plan ==
...

== Analyzed Logical Plan ==
...

== Optimized Logical Plan ==
...

== Physical Plan ==
...
"""
```

### Adaptive Query Execution (AQE)

Disponible depuis Spark 3.0 :

```python
# Activer AQE
spark.conf.set("spark.sql.adaptive.enabled", "true")

# AQE ajuste dynamiquement :
# - Nombre de partitions après shuffle
# - Stratégie de join
# - Gestion des data skew
```

---

## Exemples pratiques

### 1. Analyse de ventes avec SQL

```python
# Créer des données
sales = spark.createDataFrame([
    ("2024-01-01", "Electronics", "Laptop", 1200, 2),
    ("2024-01-01", "Books", "Python Guide", 40, 5),
    ("2024-01-02", "Electronics", "Phone", 800, 3),
    ("2024-01-02", "Books", "Spark Book", 50, 2),
], ["date", "category", "product", "price", "quantity"])

sales.createOrReplaceTempView("sales")

# Requêtes SQL
spark.sql("""
    SELECT
        category,
        SUM(price * quantity) as total_revenue,
        COUNT(*) as num_sales,
        AVG(price * quantity) as avg_sale
    FROM sales
    GROUP BY category
    ORDER BY total_revenue DESC
""").show()
```

### 2. Window functions - Top N par groupe

```python
employees = spark.createDataFrame([
    ("Alice", "Sales", 50000),
    ("Bob", "Sales", 60000),
    ("Charlie", "Engineering", 80000),
    ("David", "Engineering", 70000),
    ("Eve", "Sales", 55000)
], ["name", "department", "salary"])

employees.createOrReplaceTempView("employees")

# Top 2 salaires par département
spark.sql("""
    SELECT * FROM (
        SELECT
            name,
            department,
            salary,
            ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
        FROM employees
    )
    WHERE rank <= 2
""").show()
```

### 3. Self-join pour comparaisons

```python
spark.sql("""
    SELECT
        a.name as name1,
        b.name as name2,
        a.city
    FROM users a
    JOIN users b ON a.city = b.city AND a.id < b.id
    ORDER BY a.city
""").show()
```

---

## Bonnes pratiques

### 1. Utilisez views pour requêtes complexes

```python
# ✅ Décomposer en steps
df1.createOrReplaceTempView("step1")
df2.createOrReplaceTempView("step2")

result = spark.sql("""
    SELECT * FROM step1
    JOIN step2 ON step1.id = step2.id
""")
```

### 2. Préférez DataFrame API pour transformations simples

```python
# ❌ SQL pour opération simple
spark.sql("SELECT * FROM users WHERE age > 25")

# ✅ DataFrame API (plus lisible)
users_df.filter(col("age") > 25)
```

### 3. Utilisez Pandas UDF au lieu de UDF standard

```python
# ❌ UDF standard (lent)
@udf(StringType())
def process(s):
    return s.upper()

# ✅ Pandas UDF (rapide)
@pandas_udf(StringType())
def process_pandas(s: pd.Series) -> pd.Series:
    return s.str.upper()
```

---

## Résumé

### Concepts clés
- **Catalog** : Métastore (bases, tables, views)
- **Temporary Views** : Tables SQL temporaires sur DataFrames
- **Window Functions** : Calculs sur fenêtres de lignes
- **UDF** : Fonctions personnalisées
- **Catalyst** : Optimiseur automatique

### SQL vs DataFrame API

| Cas | Recommandation |
|-----|----------------|
| Requêtes complexes avec joins | SQL |
| Transformations simples | DataFrame API |
| Collaboration avec analystes SQL | SQL |
| Code programmatique | DataFrame API |

---

## Prochaines étapes

Module suivant : **[06-ETL-Pipelines](../06-ETL-Pipelines/README.md)**

Vous allez apprendre à :
- Lire et écrire différents formats (CSV, JSON, Parquet, Avro)
- Créer des pipelines ETL complets
- Gérer les schemas
- Optimiser les lectures/écritures
