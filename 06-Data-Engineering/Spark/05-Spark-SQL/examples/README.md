# Exemples Spark SQL

Exemples pratiques pour maîtriser Spark SQL et les requêtes sur données distribuées.

## Fichiers

### 1. sql_queries.py
**Requêtes SQL de base** :
- Créer des temporary views
- SELECT, WHERE, ORDER BY, GROUP BY
- Joins (INNER, LEFT, RIGHT, FULL)
- Sous-requêtes et CTEs
- Fonctions d'agrégation
- Combiner SQL et DataFrame API

### 2. window_functions.py
**Window Functions** :
- Ranking: ROW_NUMBER, RANK, DENSE_RANK, NTILE
- Analytical: LEAD, LAG, FIRST_VALUE, LAST_VALUE
- Aggregate windows: SUM, AVG, MIN, MAX
- Window frame specifications
- Top N par groupe
- Sommes cumulatives et moyennes mobiles

### 3. udf_functions.py
**User Defined Functions** :
- UDF standard
- Enregistrer des UDFs pour SQL
- UDF avec décorateur
- Pandas UDF (vectorized, performant)
- UDF d'agrégation
- Validation et traitement custom

## Exécution

```bash
# Se placer dans le dossier
cd 05-Spark-SQL/examples

# Exécuter les scripts
python sql_queries.py
python window_functions.py
python udf_functions.py

# Ou avec spark-submit
spark-submit sql_queries.py
```

## Concepts clés

### Temporary Views

Les **temporary views** permettent d'utiliser SQL sur des DataFrames :

```python
# Créer une view
df.createOrReplaceTempView("users")

# Utiliser SQL
result = spark.sql("SELECT * FROM users WHERE age > 25")
result.show()
```

**Types de views** :
- **Temporary View** : Scope session, namespace default
- **Global Temp View** : Scope application, namespace `global_temp`
- **Table** : Persistante dans le metastore

### Window Functions

Les **window functions** calculent sur un ensemble de lignes liées :

```sql
SELECT
    name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
FROM employees
```

**Composants** :
- `PARTITION BY` : Divise en groupes
- `ORDER BY` : Trie dans chaque groupe
- `ROWS BETWEEN` : Définit la fenêtre

### User Defined Functions (UDF)

Les **UDFs** permettent des fonctions custom :

```python
# Standard UDF
@udf(returnType=StringType())
def my_func(x):
    return x.upper()

# Pandas UDF (recommandé - plus rapide)
@pandas_udf(StringType())
def my_func_pandas(s: pd.Series) -> pd.Series:
    return s.str.upper()
```

## Principales opérations SQL

### SELECT et filtrage
```sql
SELECT col1, col2 FROM table WHERE condition
SELECT DISTINCT col FROM table
SELECT * FROM table ORDER BY col DESC
SELECT * FROM table LIMIT 10
```

### Agrégations
```sql
SELECT
    category,
    COUNT(*) as count,
    AVG(price) as avg_price
FROM products
GROUP BY category
HAVING count > 10
```

### Joins
```sql
-- Inner join
SELECT * FROM t1 JOIN t2 ON t1.id = t2.id

-- Left join
SELECT * FROM t1 LEFT JOIN t2 ON t1.id = t2.id

-- Multiple joins
SELECT * FROM t1
JOIN t2 ON t1.id = t2.id
JOIN t3 ON t2.id = t3.id
```

### Sous-requêtes
```sql
-- Dans WHERE
SELECT * FROM users
WHERE age > (SELECT AVG(age) FROM users)

-- Dans FROM
SELECT * FROM (
    SELECT category, AVG(price) as avg
    FROM products GROUP BY category
) WHERE avg > 100
```

### CTEs
```sql
WITH high_value AS (
    SELECT * FROM orders WHERE amount > 1000
)
SELECT customer_id, COUNT(*) as num_orders
FROM high_value
GROUP BY customer_id
```

## Window Functions courantes

### Ranking
```sql
ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC)
RANK() OVER (ORDER BY score DESC)
DENSE_RANK() OVER (ORDER BY score DESC)
NTILE(4) OVER (ORDER BY salary)  -- Quartiles
```

### Analytical
```sql
LEAD(value, 1) OVER (ORDER BY date)   -- Valeur suivante
LAG(value, 1) OVER (ORDER BY date)    -- Valeur précédente
FIRST_VALUE(value) OVER (...)         -- Première
LAST_VALUE(value) OVER (...)          -- Dernière
```

### Aggregates
```sql
SUM(sales) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
AVG(temp) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
```

## Bonnes pratiques

### 1. Préférez built-in à UDF
```python
# ❌ UDF pour opération simple
@udf(StringType())
def upper(s):
    return s.upper()

# ✅ Fonction built-in
from pyspark.sql.functions import upper
df.withColumn("name_upper", upper(col("name")))
```

### 2. Utilisez Pandas UDF pour performance
```python
# ❌ UDF standard (lent)
@udf(DoubleType())
def calculate(x):
    return x * 2

# ✅ Pandas UDF (rapide)
@pandas_udf(DoubleType())
def calculate(s: pd.Series) -> pd.Series:
    return s * 2
```

### 3. Utilisez explain() pour optimiser
```python
# Voir le plan d'exécution
query = spark.sql("SELECT ... FROM ... WHERE ...")
query.explain(extended=True)
```

### 4. CTEs pour requêtes complexes
```sql
-- ✅ Lisible avec CTE
WITH step1 AS (...),
     step2 AS (...)
SELECT * FROM step2 WHERE ...

-- ❌ Difficile à lire
SELECT * FROM (
    SELECT * FROM (...)
    WHERE ...
) WHERE ...
```

## Fonctions SQL utiles

### Agrégations
```sql
COUNT(*), COUNT(DISTINCT col)
SUM(col), AVG(col), MIN(col), MAX(col)
STDDEV(col), VARIANCE(col)
COLLECT_LIST(col), COLLECT_SET(col)
```

### Strings
```sql
UPPER(col), LOWER(col), TRIM(col)
SUBSTRING(col, start, len)
CONCAT(col1, col2)
LENGTH(col)
REGEXP_REPLACE(col, pattern, replacement)
```

### Dates
```sql
CURRENT_DATE(), CURRENT_TIMESTAMP()
YEAR(date), MONTH(date), DAY(date)
DATE_ADD(date, days), DATE_SUB(date, days)
DATEDIFF(date1, date2)
TO_DATE(string, format)
```

### Conditionnelles
```sql
CASE
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2
    ELSE default
END

COALESCE(col1, col2, default)  -- Première valeur non-NULL
NULLIF(col1, col2)              -- NULL si égaux
```

## Optimisations Catalyst

Spark SQL optimise automatiquement :

1. **Predicate Pushdown** : Filtre au plus tôt
2. **Column Pruning** : Ne lit que les colonnes nécessaires
3. **Constant Folding** : Calcule les constantes une fois
4. **Join Reordering** : Optimise l'ordre des joins

Voir avec `explain()` :
```python
df.explain(extended=True)
```

## Exercices

### Exercice 1 : Requêtes de base
Créer une view `sales` et trouver :
- Total des ventes par produit
- Top 5 produits
- Ventes moyennes par catégorie

### Exercice 2 : Window Functions
Avec des données d'employés :
- Ranking des salaires par département
- Différence de salaire avec la moyenne du département
- Top 3 salaires par département

### Exercice 3 : UDF
Créer une UDF qui :
- Valide un numéro de téléphone
- Catégorise des scores (A, B, C, D, F)
- Extrait le domaine d'une URL

## Ressources

- [Spark SQL Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)
- [SQL Functions Reference](https://spark.apache.org/docs/latest/api/sql/)
- Module précédent : [04-DataFrames-API](../../04-DataFrames-API/README.md)
- Module suivant : [06-ETL-Pipelines](../../06-ETL-Pipelines/README.md)
