# Spark SQL

## Introduction

**Spark SQL** permet d'exécuter des requêtes SQL standard sur des DataFrames et des tables Delta, offrant une interface familière pour les développeurs SQL.

```
Spark SQL Architecture:
┌──────────────────────────────────────────┐
│  SQL Query (ANSI SQL)                    │
├──────────────────────────────────────────┤
│  Catalyst Optimizer                      │
│  ├─ Parser                               │
│  ├─ Analyzer                             │
│  ├─ Optimizer                            │
│  └─ Code Generator                       │
├──────────────────────────────────────────┤
│  DataFrame API (optimized plan)          │
├──────────────────────────────────────────┤
│  Tungsten Execution Engine               │
└──────────────────────────────────────────┘
```

## SQL Basics

### Executing SQL

```python
# Simple query
result = spark.sql("SELECT * FROM customers")
result.show()

# Assigning to DataFrame
df = spark.sql("SELECT name, age FROM customers WHERE age > 25")

# Multi-line SQL
query = """
SELECT
    country,
    COUNT(*) as customer_count,
    AVG(age) as avg_age
FROM customers
GROUP BY country
ORDER BY customer_count DESC
"""

spark.sql(query).show()
```

### Creating Views

```python
# Temporary view (session-scoped)
df.createOrReplaceTempView("customers_view")
spark.sql("SELECT * FROM customers_view").show()

# Global temporary view (application-scoped)
df.createOrReplaceGlobalTempView("customers_global")
spark.sql("SELECT * FROM global_temp.customers_global").show()

# Drop view
spark.sql("DROP VIEW IF EXISTS customers_view")
```

### CREATE TABLE

```python
# Create table from query
spark.sql("""
    CREATE TABLE customers_france AS
    SELECT * FROM customers
    WHERE country = 'FR'
""")

# Create table with schema
spark.sql("""
    CREATE TABLE customers (
        customer_id INT,
        name STRING,
        email STRING,
        country STRING,
        created_at TIMESTAMP
    )
    USING DELTA
    PARTITIONED BY (country)
""")

# Create if not exists
spark.sql("""
    CREATE TABLE IF NOT EXISTS sales (
        order_id INT,
        customer_id INT,
        amount DECIMAL(10,2),
        order_date DATE
    )
    USING DELTA
""")
```

## SELECT Queries

### Basic SELECT

```python
# All columns
spark.sql("SELECT * FROM customers").show()

# Specific columns
spark.sql("SELECT name, age FROM customers").show()

# With alias
spark.sql("""
    SELECT
        name AS customer_name,
        age AS customer_age
    FROM customers
""").show()

# DISTINCT
spark.sql("SELECT DISTINCT country FROM customers").show()
```

### WHERE Clause

```python
# Simple filter
spark.sql("""
    SELECT * FROM customers
    WHERE age > 25
""").show()

# Multiple conditions
spark.sql("""
    SELECT * FROM customers
    WHERE age > 25 AND country = 'FR'
""").show()

# IN operator
spark.sql("""
    SELECT * FROM customers
    WHERE country IN ('FR', 'US', 'UK')
""").show()

# LIKE operator
spark.sql("""
    SELECT * FROM customers
    WHERE email LIKE '%@gmail.com'
""").show()

# BETWEEN
spark.sql("""
    SELECT * FROM sales
    WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
""").show()

# NULL handling
spark.sql("""
    SELECT * FROM customers
    WHERE email IS NOT NULL
""").show()
```

### ORDER BY

```python
# Ascending (default)
spark.sql("""
    SELECT * FROM customers
    ORDER BY age
""").show()

# Descending
spark.sql("""
    SELECT * FROM customers
    ORDER BY age DESC
""").show()

# Multiple columns
spark.sql("""
    SELECT * FROM customers
    ORDER BY country ASC, age DESC
""").show()

# NULLS handling
spark.sql("""
    SELECT * FROM customers
    ORDER BY email NULLS LAST
""").show()
```

### LIMIT

```python
# Limit rows
spark.sql("""
    SELECT * FROM customers
    LIMIT 10
""").show()

# Top N
spark.sql("""
    SELECT * FROM customers
    ORDER BY total_spent DESC
    LIMIT 5
""").show()
```

## Aggregations

### GROUP BY

```python
# Simple aggregation
spark.sql("""
    SELECT
        country,
        COUNT(*) as customer_count
    FROM customers
    GROUP BY country
""").show()

# Multiple aggregations
spark.sql("""
    SELECT
        country,
        COUNT(*) as customer_count,
        AVG(age) as avg_age,
        MIN(age) as min_age,
        MAX(age) as max_age
    FROM customers
    GROUP BY country
""").show()

# Multiple grouping columns
spark.sql("""
    SELECT
        country,
        YEAR(created_at) as year,
        COUNT(*) as customer_count
    FROM customers
    GROUP BY country, YEAR(created_at)
""").show()
```

### HAVING

```python
# Filter aggregated results
spark.sql("""
    SELECT
        country,
        COUNT(*) as customer_count
    FROM customers
    GROUP BY country
    HAVING COUNT(*) > 100
""").show()

# Complex HAVING
spark.sql("""
    SELECT
        country,
        AVG(age) as avg_age
    FROM customers
    GROUP BY country
    HAVING AVG(age) > 30 AND COUNT(*) > 50
""").show()
```

### Aggregate Functions

```python
# Common aggregates
spark.sql("""
    SELECT
        COUNT(*) as total_rows,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(amount) as total_sales,
        AVG(amount) as avg_sale,
        MIN(amount) as min_sale,
        MAX(amount) as max_sale,
        STDDEV(amount) as stddev_sale
    FROM sales
""").show()

# Conditional aggregation
spark.sql("""
    SELECT
        COUNT(*) as total_orders,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_orders,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders
    FROM orders
""").show()
```

## JOINs

### INNER JOIN

```python
spark.sql("""
    SELECT
        c.customer_id,
        c.name,
        o.order_id,
        o.amount
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
""").show()
```

### LEFT JOIN

```python
spark.sql("""
    SELECT
        c.customer_id,
        c.name,
        o.order_id,
        o.amount
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
""").show()
```

### RIGHT JOIN

```python
spark.sql("""
    SELECT
        c.customer_id,
        c.name,
        o.order_id,
        o.amount
    FROM customers c
    RIGHT JOIN orders o
        ON c.customer_id = o.customer_id
""").show()
```

### FULL OUTER JOIN

```python
spark.sql("""
    SELECT
        c.customer_id,
        c.name,
        o.order_id,
        o.amount
    FROM customers c
    FULL OUTER JOIN orders o
        ON c.customer_id = o.customer_id
""").show()
```

### CROSS JOIN

```python
# Cartesian product
spark.sql("""
    SELECT
        p.product_name,
        c.country
    FROM products p
    CROSS JOIN countries c
""").show()
```

### Multiple JOINs

```python
spark.sql("""
    SELECT
        c.name,
        o.order_id,
        p.product_name,
        oi.quantity
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN products p
        ON oi.product_id = p.product_id
""").show()
```

## Subqueries

### Scalar Subquery

```python
# Single value subquery
spark.sql("""
    SELECT
        customer_id,
        name,
        total_spent,
        (SELECT AVG(total_spent) FROM customers) as avg_spent
    FROM customers
""").show()
```

### Correlated Subquery

```python
# Subquery referencing outer query
spark.sql("""
    SELECT
        c.customer_id,
        c.name,
        (SELECT COUNT(*)
         FROM orders o
         WHERE o.customer_id = c.customer_id) as order_count
    FROM customers c
""").show()
```

### IN Subquery

```python
spark.sql("""
    SELECT *
    FROM customers
    WHERE customer_id IN (
        SELECT DISTINCT customer_id
        FROM orders
        WHERE amount > 1000
    )
""").show()
```

### EXISTS Subquery

```python
spark.sql("""
    SELECT *
    FROM customers c
    WHERE EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = c.customer_id
        AND o.status = 'completed'
    )
""").show()
```

## Window Functions

### ROW_NUMBER

```python
spark.sql("""
    SELECT
        customer_id,
        order_date,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC
        ) as row_num
    FROM orders
""").show()
```

### RANK and DENSE_RANK

```python
spark.sql("""
    SELECT
        country,
        customer_name,
        total_spent,
        RANK() OVER (
            PARTITION BY country
            ORDER BY total_spent DESC
        ) as rank,
        DENSE_RANK() OVER (
            PARTITION BY country
            ORDER BY total_spent DESC
        ) as dense_rank
    FROM customers
""").show()
```

### LAG and LEAD

```python
spark.sql("""
    SELECT
        order_date,
        amount,
        LAG(amount, 1) OVER (ORDER BY order_date) as prev_amount,
        LEAD(amount, 1) OVER (ORDER BY order_date) as next_amount,
        amount - LAG(amount, 1) OVER (ORDER BY order_date) as change
    FROM orders
""").show()
```

### Cumulative Aggregations

```python
spark.sql("""
    SELECT
        order_date,
        amount,
        SUM(amount) OVER (
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as running_total,
        AVG(amount) OVER (
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as running_avg
    FROM orders
""").show()
```

### Moving Averages

```python
spark.sql("""
    SELECT
        order_date,
        amount,
        AVG(amount) OVER (
            ORDER BY order_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as moving_avg_7_days
    FROM daily_sales
""").show()
```

## CTEs (Common Table Expressions)

### Single CTE

```python
spark.sql("""
    WITH high_value_customers AS (
        SELECT customer_id, name
        FROM customers
        WHERE total_spent > 10000
    )
    SELECT
        c.name,
        o.order_id,
        o.amount
    FROM high_value_customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
""").show()
```

### Multiple CTEs

```python
spark.sql("""
    WITH
    french_customers AS (
        SELECT * FROM customers
        WHERE country = 'FR'
    ),
    large_orders AS (
        SELECT * FROM orders
        WHERE amount > 1000
    )
    SELECT
        fc.name,
        lo.order_id,
        lo.amount
    FROM french_customers fc
    INNER JOIN large_orders lo
        ON fc.customer_id = lo.customer_id
""").show()
```

### Recursive CTE (Limited Support)

```python
# Note: Spark has limited recursive CTE support
spark.sql("""
    WITH RECURSIVE date_range(dt) AS (
        SELECT DATE '2024-01-01'
        UNION ALL
        SELECT dt + INTERVAL 1 DAY
        FROM date_range
        WHERE dt < DATE '2024-01-31'
    )
    SELECT * FROM date_range
""").show()
```

## CASE Expressions

### Simple CASE

```python
spark.sql("""
    SELECT
        customer_id,
        total_spent,
        CASE
            WHEN total_spent > 10000 THEN 'VIP'
            WHEN total_spent > 5000 THEN 'Premium'
            WHEN total_spent > 1000 THEN 'Regular'
            ELSE 'Basic'
        END as segment
    FROM customers
""").show()
```

### Searched CASE

```python
spark.sql("""
    SELECT
        order_id,
        CASE
            WHEN status = 'completed' AND amount > 1000 THEN 'High Value Completed'
            WHEN status = 'completed' THEN 'Completed'
            WHEN status = 'pending' THEN 'In Progress'
            WHEN status = 'cancelled' THEN 'Cancelled'
            ELSE 'Unknown'
        END as order_status
    FROM orders
""").show()
```

## SET Operations

### UNION

```python
# UNION (removes duplicates)
spark.sql("""
    SELECT customer_id FROM customers_france
    UNION
    SELECT customer_id FROM customers_usa
""").show()

# UNION ALL (keeps duplicates)
spark.sql("""
    SELECT customer_id FROM customers_france
    UNION ALL
    SELECT customer_id FROM customers_usa
""").show()
```

### INTERSECT

```python
spark.sql("""
    SELECT customer_id FROM customers_2023
    INTERSECT
    SELECT customer_id FROM customers_2024
""").show()
```

### EXCEPT

```python
# Customers in 2023 but not in 2024
spark.sql("""
    SELECT customer_id FROM customers_2023
    EXCEPT
    SELECT customer_id FROM customers_2024
""").show()
```

## Advanced SQL Features

### PIVOT

```python
spark.sql("""
    SELECT * FROM (
        SELECT country, year, amount
        FROM sales
    )
    PIVOT (
        SUM(amount)
        FOR year IN (2022, 2023, 2024)
    )
""").show()
```

### LATERAL VIEW (Explode)

```python
spark.sql("""
    SELECT
        customer_id,
        tag
    FROM customers
    LATERAL VIEW explode(tags) t AS tag
""").show()

# Multiple LATERAL VIEWs
spark.sql("""
    SELECT
        customer_id,
        item,
        size
    FROM customers
    LATERAL VIEW explode(items) i AS item
    LATERAL VIEW explode(sizes) s AS size
""").show()
```

### TABLESAMPLE

```python
# Sample 10% of rows
spark.sql("""
    SELECT * FROM large_table
    TABLESAMPLE (10 PERCENT)
""").show()

# Sample N rows
spark.sql("""
    SELECT * FROM large_table
    TABLESAMPLE (1000 ROWS)
""").show()
```

## DML Operations

### INSERT

```python
# Insert values
spark.sql("""
    INSERT INTO customers
    VALUES (1, 'Alice', 'alice@example.com', 'FR')
""")

# Insert from query
spark.sql("""
    INSERT INTO customers_archive
    SELECT * FROM customers
    WHERE created_at < '2023-01-01'
""")

# Insert overwrite
spark.sql("""
    INSERT OVERWRITE TABLE customers_france
    SELECT * FROM customers
    WHERE country = 'FR'
""")
```

### UPDATE

```python
# Update all rows
spark.sql("""
    UPDATE customers
    SET status = 'active'
""")

# Conditional update
spark.sql("""
    UPDATE customers
    SET status = 'inactive'
    WHERE last_order_date < '2023-01-01'
""")
```

### DELETE

```python
# Delete with condition
spark.sql("""
    DELETE FROM customers
    WHERE status = 'deleted'
""")
```

### MERGE

```python
spark.sql("""
    MERGE INTO customers target
    USING customers_updates source
    ON target.customer_id = source.customer_id
    WHEN MATCHED THEN
        UPDATE SET
            name = source.name,
            email = source.email
    WHEN NOT MATCHED THEN
        INSERT (customer_id, name, email, country)
        VALUES (source.customer_id, source.name, source.email, source.country)
""")
```

## Functions

### String Functions

```python
spark.sql("""
    SELECT
        name,
        UPPER(name) as upper_name,
        LOWER(name) as lower_name,
        LENGTH(name) as name_length,
        SUBSTRING(name, 1, 3) as first_3_chars,
        CONCAT(first_name, ' ', last_name) as full_name,
        TRIM(name) as trimmed,
        REPLACE(email, '@gmail.com', '@example.com') as masked_email
    FROM customers
""").show()
```

### Date Functions

```python
spark.sql("""
    SELECT
        order_date,
        YEAR(order_date) as year,
        MONTH(order_date) as month,
        DAY(order_date) as day,
        DAYOFWEEK(order_date) as day_of_week,
        DATE_ADD(order_date, 7) as next_week,
        DATE_SUB(order_date, 30) as last_month,
        DATEDIFF(CURRENT_DATE(), order_date) as days_ago,
        DATE_FORMAT(order_date, 'yyyy-MM-dd') as formatted_date
    FROM orders
""").show()
```

### Math Functions

```python
spark.sql("""
    SELECT
        amount,
        ROUND(amount, 2) as rounded,
        CEIL(amount) as ceiling,
        FLOOR(amount) as floor,
        ABS(amount) as absolute,
        SQRT(amount) as square_root,
        POW(amount, 2) as squared
    FROM orders
""").show()
```

### Conditional Functions

```python
spark.sql("""
    SELECT
        amount,
        IF(amount > 1000, 'High', 'Low') as category,
        COALESCE(discount, 0) as final_discount,
        NULLIF(amount, 0) as non_zero_amount
    FROM orders
""").show()
```

## Performance Optimization

### EXPLAIN

```python
# Show execution plan
spark.sql("""
    EXPLAIN
    SELECT country, COUNT(*)
    FROM customers
    GROUP BY country
""").show()

# Extended explain
spark.sql("""
    EXPLAIN EXTENDED
    SELECT * FROM customers WHERE age > 25
""").show()

# Cost-based explain
spark.sql("""
    EXPLAIN COST
    SELECT * FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
""").show()
```

### CACHE TABLE

```python
# Cache table in memory
spark.sql("CACHE TABLE customers")

# Lazy cache (on first access)
spark.sql("CACHE LAZY TABLE customers")

# Uncache
spark.sql("UNCACHE TABLE customers")
```

### Broadcast Hint

```python
# Hint to broadcast small table
spark.sql("""
    SELECT /*+ BROADCAST(c) */ *
    FROM large_orders l
    INNER JOIN customers c
        ON l.customer_id = c.customer_id
""").show()
```

## Best Practices

### ✅ Use CTEs for Readability

```python
# ✅ Good: Clear and readable
spark.sql("""
    WITH monthly_sales AS (
        SELECT
            country,
            YEAR(order_date) as year,
            MONTH(order_date) as month,
            SUM(amount) as total_sales
        FROM orders
        GROUP BY country, YEAR(order_date), MONTH(order_date)
    )
    SELECT
        country,
        year,
        AVG(total_sales) as avg_monthly_sales
    FROM monthly_sales
    GROUP BY country, year
""")
```

### ✅ Filter Early

```python
# ✅ Good: Filter before JOIN
spark.sql("""
    SELECT c.name, o.amount
    FROM (SELECT * FROM customers WHERE country = 'FR') c
    INNER JOIN orders o ON c.customer_id = o.customer_id
""")

# ❌ Bad: Filter after JOIN
spark.sql("""
    SELECT c.name, o.amount
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.country = 'FR'
""")
```

### ✅ Use Broadcast for Small Tables

```python
# ✅ Good: Broadcast small dimension
spark.sql("""
    SELECT /*+ BROADCAST(d) */ f.*, d.name
    FROM fact_sales f
    INNER JOIN dim_product d ON f.product_id = d.product_id
""")
```

## Points Clés

- Spark SQL = ANSI SQL sur DataFrames/Delta tables
- CREATE TABLE pour définir tables Delta
- SELECT avec WHERE, ORDER BY, LIMIT
- Aggregations: GROUP BY, HAVING, COUNT, SUM, AVG
- JOINs: INNER, LEFT, RIGHT, FULL OUTER, CROSS
- Subqueries: scalar, correlated, IN, EXISTS
- Window functions: ROW_NUMBER, RANK, LAG, LEAD, SUM OVER
- CTEs pour readability (WITH clause)
- CASE expressions pour conditional logic
- SET operations: UNION, INTERSECT, EXCEPT
- DML: INSERT, UPDATE, DELETE, MERGE
- EXPLAIN pour visualiser query plan
- Broadcast hint pour small table joins

---

**Prochain fichier :** [06 - Performance Optimization](./06-performance-optimization.md)

[⬅️ Fichier précédent](./04-delta-lake-operations.md) | [⬅️ Retour au README du module](./README.md)
