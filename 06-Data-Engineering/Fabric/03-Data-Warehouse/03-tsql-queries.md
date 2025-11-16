# Requêtes T-SQL Avancées

## Introduction

Synapse Data Warehouse supporte **T-SQL complet** avec quelques limitations spécifiques à l'architecture MPP.

```
T-SQL Support in Fabric Warehouse:
├── SELECT queries (full support)
├── CTEs (Common Table Expressions)
├── Window functions
├── JOINs (optimized for MPP)
├── Subqueries
├── MERGE operations
├── Transactions (limitations)
└── Stored procedures
```

## Common Table Expressions (CTEs)

### CTE Simple

```sql
-- CTE basique
WITH sales_summary AS (
    SELECT
        customer_id,
        SUM(amount) as total_sales,
        COUNT(*) as order_count
    FROM fact_sales
    WHERE sale_date >= '2024-01-01'
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    s.total_sales,
    s.order_count
FROM sales_summary s
JOIN dim_customer c ON s.customer_id = c.customer_id
WHERE s.total_sales > 10000;
```

### CTEs Multiples

```sql
-- Plusieurs CTEs
WITH
    monthly_sales AS (
        SELECT
            customer_id,
            YEAR(sale_date) as year,
            MONTH(sale_date) as month,
            SUM(amount) as total
        FROM fact_sales
        GROUP BY customer_id, YEAR(sale_date), MONTH(sale_date)
    ),
    customer_avg AS (
        SELECT
            customer_id,
            AVG(total) as avg_monthly_sales
        FROM monthly_sales
        GROUP BY customer_id
    )
SELECT
    c.customer_name,
    ca.avg_monthly_sales,
    CASE
        WHEN ca.avg_monthly_sales > 5000 THEN 'VIP'
        WHEN ca.avg_monthly_sales > 1000 THEN 'Premium'
        ELSE 'Standard'
    END as customer_tier
FROM customer_avg ca
JOIN dim_customer c ON ca.customer_id = c.customer_id
ORDER BY ca.avg_monthly_sales DESC;
```

### CTE Récursif

```sql
-- Hiérarchie organisationnelle
WITH org_hierarchy AS (
    -- Anchor: Top level
    SELECT
        employee_id,
        employee_name,
        manager_id,
        0 as level
    FROM dim_employee
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: Subordinates
    SELECT
        e.employee_id,
        e.employee_name,
        e.manager_id,
        oh.level + 1
    FROM dim_employee e
    INNER JOIN org_hierarchy oh ON e.manager_id = oh.employee_id
)
SELECT
    employee_id,
    REPLICATE('  ', level) + employee_name as employee_hierarchy,
    level
FROM org_hierarchy
ORDER BY level, employee_name;
```

## Window Functions

### ROW_NUMBER

```sql
-- Ranking clients par ventes
SELECT
    customer_id,
    customer_name,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) as sales_rank
FROM (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(s.amount) as total_sales
    FROM fact_sales s
    JOIN dim_customer c ON s.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
) ranked;
```

### PARTITION BY

```sql
-- Top 3 produits par catégorie
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(s.amount) as total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY p.category
            ORDER BY SUM(s.amount) DESC
        ) as rank_in_category
    FROM fact_sales s
    JOIN dim_product p ON s.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    total_sales,
    rank_in_category
FROM product_sales
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;
```

### RANK vs DENSE_RANK

```sql
SELECT
    customer_id,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) as row_num,
    RANK() OVER (ORDER BY total_sales DESC) as rank,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) as dense_rank
FROM customer_totals;

-- Résultat:
-- customer_id | total_sales | row_num | rank | dense_rank
-- 1           | 10000       | 1       | 1    | 1
-- 2           | 10000       | 2       | 1    | 1  ← Même rank
-- 3           | 8000        | 3       | 3    | 2  ← rank saute à 3, dense_rank = 2
-- 4           | 7000        | 4       | 4    | 3
```

### LEAD et LAG

```sql
-- Comparer ventes mois actuel vs précédent
SELECT
    year,
    month,
    total_sales,
    LAG(total_sales, 1) OVER (ORDER BY year, month) as prev_month_sales,
    LEAD(total_sales, 1) OVER (ORDER BY year, month) as next_month_sales,
    total_sales - LAG(total_sales, 1) OVER (ORDER BY year, month) as month_over_month_change
FROM monthly_sales
ORDER BY year, month;
```

### Running Total

```sql
-- Cumul des ventes
SELECT
    sale_date,
    daily_sales,
    SUM(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_total
FROM (
    SELECT
        sale_date,
        SUM(amount) as daily_sales
    FROM fact_sales
    GROUP BY sale_date
) daily;
```

### Moving Average

```sql
-- Moyenne mobile 7 jours
SELECT
    sale_date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d
FROM daily_sales
ORDER BY sale_date;
```

## JOIN Optimization

### INNER JOIN

```sql
-- Join optimisé (distributions alignées)
SELECT
    f.sale_id,
    c.customer_name,
    f.amount
FROM fact_sales f  -- HASH(customer_id)
INNER JOIN dim_customer c  -- HASH(customer_id)
    ON f.customer_id = c.customer_id
WHERE f.sale_date >= '2024-01-01';

-- → No data movement (distributions match)
```

### LEFT JOIN avec Filtres

```sql
-- ✅ Bon: Filtre dans WHERE pour table principale
SELECT
    c.customer_name,
    COALESCE(s.total_sales, 0) as total_sales
FROM dim_customer c
LEFT JOIN (
    SELECT customer_id, SUM(amount) as total_sales
    FROM fact_sales
    WHERE sale_date >= '2024-01-01'
    GROUP BY customer_id
) s ON c.customer_id = s.customer_id
WHERE c.country = 'FR';

-- ❌ Mauvais: Filtre après LEFT JOIN
SELECT
    c.customer_name,
    COALESCE(s.total_sales, 0) as total_sales
FROM dim_customer c
LEFT JOIN fact_sales s ON c.customer_id = s.customer_id
WHERE c.country = 'FR' AND s.sale_date >= '2024-01-01';
-- → Change semantique (devient INNER JOIN)
```

### CROSS APPLY

```sql
-- Top 3 ventes par client
SELECT
    c.customer_id,
    c.customer_name,
    top_sales.sale_id,
    top_sales.amount
FROM dim_customer c
CROSS APPLY (
    SELECT TOP 3
        sale_id,
        amount
    FROM fact_sales s
    WHERE s.customer_id = c.customer_id
    ORDER BY amount DESC
) top_sales;
```

### Broadcast Join Hint

```sql
-- Force broadcast pour petite dimension
SELECT
    f.*,
    d.*
FROM fact_sales f
INNER JOIN dim_small d WITH (FORCESEEK)
    ON f.lookup_id = d.id
OPTION (HASH JOIN);
```

## MERGE Operations

### Upsert Simple

```sql
MERGE INTO dim_customer AS target
USING staging_customer AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.email = source.email,
        target.updated_at = CURRENT_TIMESTAMP

WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, email, created_at)
    VALUES (source.customer_id, source.customer_name, source.email, CURRENT_TIMESTAMP);
```

### MERGE avec DELETE

```sql
MERGE INTO fact_sales AS target
USING staging_sales AS source
ON target.sale_id = source.sale_id

WHEN MATCHED AND source.is_deleted = 1 THEN
    DELETE

WHEN MATCHED THEN
    UPDATE SET
        target.amount = source.amount,
        target.updated_at = CURRENT_TIMESTAMP

WHEN NOT MATCHED BY TARGET THEN
    INSERT (sale_id, customer_id, amount, sale_date)
    VALUES (source.sale_id, source.customer_id, source.amount, source.sale_date);
```

### MERGE Complexe avec Conditions

```sql
MERGE INTO product_inventory AS target
USING (
    SELECT
        product_id,
        SUM(quantity) as total_sold
    FROM fact_sales
    WHERE sale_date = CAST(GETDATE() AS DATE)
    GROUP BY product_id
) AS source
ON target.product_id = source.product_id

WHEN MATCHED AND target.stock - source.total_sold >= 0 THEN
    UPDATE SET
        target.stock = target.stock - source.total_sold,
        target.last_updated = CURRENT_TIMESTAMP

WHEN MATCHED AND target.stock - source.total_sold < 0 THEN
    UPDATE SET
        target.stock = 0,
        target.out_of_stock_flag = 1,
        target.last_updated = CURRENT_TIMESTAMP

WHEN NOT MATCHED BY SOURCE THEN
    -- Produits sans vente aujourd'hui
    UPDATE SET target.no_sales_today = 1;
```

## Transactions

### Transaction Basique

```sql
BEGIN TRANSACTION;

    UPDATE inventory
    SET stock = stock - 10
    WHERE product_id = 123;

    INSERT INTO sales (product_id, quantity, sale_date)
    VALUES (123, 10, GETDATE());

COMMIT TRANSACTION;
```

### Transaction avec Error Handling

```sql
BEGIN TRY
    BEGIN TRANSACTION;

        -- Étape 1: Vérifier stock
        DECLARE @current_stock INT;
        SELECT @current_stock = stock
        FROM inventory
        WHERE product_id = 123;

        IF @current_stock < 10
            THROW 50000, 'Stock insuffisant', 1;

        -- Étape 2: Déduire stock
        UPDATE inventory
        SET stock = stock - 10
        WHERE product_id = 123;

        -- Étape 3: Enregistrer vente
        INSERT INTO sales (product_id, quantity)
        VALUES (123, 10);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    -- Log error
    INSERT INTO error_log (error_message, error_time)
    VALUES (ERROR_MESSAGE(), GETDATE());

    -- Re-throw
    THROW;
END CATCH;
```

### Isolation Levels

```sql
-- Read Uncommitted (dirty reads possibles)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM fact_sales;

-- Read Committed (défaut)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Repeatable Read
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Serializable (le plus strict)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Snapshot (utilise versioning)
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
```

## Subqueries

### Subquery dans WHERE

```sql
-- Clients avec ventes > moyenne
SELECT
    customer_id,
    customer_name
FROM dim_customer
WHERE customer_id IN (
    SELECT customer_id
    FROM fact_sales
    GROUP BY customer_id
    HAVING SUM(amount) > (
        SELECT AVG(customer_total)
        FROM (
            SELECT SUM(amount) as customer_total
            FROM fact_sales
            GROUP BY customer_id
        ) totals
    )
);
```

### Correlated Subquery

```sql
-- Dernière commande par client
SELECT
    c.customer_id,
    c.customer_name,
    (
        SELECT TOP 1 sale_date
        FROM fact_sales s
        WHERE s.customer_id = c.customer_id
        ORDER BY sale_date DESC
    ) as last_order_date
FROM dim_customer c;
```

### EXISTS vs IN

```sql
-- EXISTS (souvent plus rapide)
SELECT c.*
FROM dim_customer c
WHERE EXISTS (
    SELECT 1
    FROM fact_sales s
    WHERE s.customer_id = c.customer_id
    AND s.sale_date >= '2024-01-01'
);

-- IN (peut être moins performant)
SELECT c.*
FROM dim_customer c
WHERE c.customer_id IN (
    SELECT DISTINCT customer_id
    FROM fact_sales
    WHERE sale_date >= '2024-01-01'
);
```

## Query Hints et Optimization

### Table Hints

```sql
-- Force scan
SELECT * FROM fact_sales WITH (FORCESCAN)
WHERE customer_id = 123;

-- Force seek (index)
SELECT * FROM dim_customer WITH (FORCESEEK)
WHERE customer_id = 123;

-- No lock (read uncommitted)
SELECT * FROM fact_sales WITH (NOLOCK)
WHERE sale_date >= '2024-01-01';
```

### Query Hints

```sql
-- Force hash join
SELECT f.*, c.*
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
OPTION (HASH JOIN);

-- Force merge join
SELECT f.*, c.*
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
OPTION (MERGE JOIN);

-- Max degree of parallelism
SELECT COUNT(*)
FROM fact_sales
OPTION (MAXDOP 4);
```

### EXPLAIN Plan

```sql
-- Voir execution plan
EXPLAIN
SELECT
    c.customer_name,
    SUM(s.amount) as total
FROM fact_sales s
JOIN dim_customer c ON s.customer_id = c.customer_id
GROUP BY c.customer_name;

-- Résultat montre:
-- - Data movement (shuffle, broadcast)
-- - Join type (hash, merge)
-- - Estimated rows
```

## Fonctions Analytiques Avancées

### PERCENT_RANK

```sql
-- Percentile de chaque client
SELECT
    customer_id,
    total_sales,
    PERCENT_RANK() OVER (ORDER BY total_sales) as percentile
FROM customer_sales;
```

### NTILE

```sql
-- Diviser en quartiles
SELECT
    customer_id,
    total_sales,
    NTILE(4) OVER (ORDER BY total_sales) as quartile
FROM customer_sales;

-- Résultat:
-- Q1: 25% bottom
-- Q2: 25-50%
-- Q3: 50-75%
-- Q4: 25% top
```

### FIRST_VALUE / LAST_VALUE

```sql
SELECT
    sale_date,
    amount,
    FIRST_VALUE(amount) OVER (
        PARTITION BY YEAR(sale_date), MONTH(sale_date)
        ORDER BY sale_date
    ) as first_day_of_month,
    LAST_VALUE(amount) OVER (
        PARTITION BY YEAR(sale_date), MONTH(sale_date)
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_day_of_month
FROM fact_sales;
```

## Pivoting et Unpivoting

### PIVOT

```sql
-- Transformer lignes en colonnes
SELECT *
FROM (
    SELECT
        product_category,
        YEAR(sale_date) as year,
        amount
    FROM fact_sales
) source
PIVOT (
    SUM(amount)
    FOR year IN ([2022], [2023], [2024])
) pivot_table;

-- Résultat:
-- category    | 2022   | 2023   | 2024
-- Electronics | 50000  | 60000  | 70000
-- Books       | 20000  | 25000  | 30000
```

### UNPIVOT

```sql
-- Transformer colonnes en lignes
SELECT
    product_id,
    metric,
    value
FROM product_metrics
UNPIVOT (
    value FOR metric IN (q1_sales, q2_sales, q3_sales, q4_sales)
) unpivot_table;
```

## Requêtes Temporelles

### Date Range Queries

```sql
-- Ventes des 30 derniers jours
SELECT *
FROM fact_sales
WHERE sale_date >= DATEADD(DAY, -30, GETDATE());

-- Même mois année dernière
SELECT *
FROM fact_sales
WHERE sale_date >= DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))
AND sale_date < DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0));
```

### Grouping par Période

```sql
-- Agrégation par semaine
SELECT
    DATEPART(YEAR, sale_date) as year,
    DATEPART(WEEK, sale_date) as week,
    SUM(amount) as weekly_sales
FROM fact_sales
GROUP BY DATEPART(YEAR, sale_date), DATEPART(WEEK, sale_date)
ORDER BY year, week;
```

## Best Practices

✅ **DO:**
```sql
-- Filtrer tôt
WITH filtered AS (
    SELECT * FROM fact_sales WHERE sale_date >= '2024-01-01'
)
SELECT * FROM filtered JOIN dim_customer ...;

-- Utiliser CTEs pour lisibilité
WITH sales_summary AS (...),
     customer_summary AS (...)
SELECT ...;

-- Statistiques à jour
UPDATE STATISTICS fact_sales;
```

❌ **DON'T:**
```sql
-- Éviter SELECT *
SELECT * FROM fact_sales;  -- Trop de données

-- Éviter fonctions sur colonnes indexées
WHERE YEAR(sale_date) = 2024;  -- Empêche index usage
-- Préférer:
WHERE sale_date >= '2024-01-01' AND sale_date < '2025-01-01';

-- Éviter curseurs
DECLARE cursor_sales CURSOR FOR ...;  -- Lent!
-- Préférer set-based operations
```

## Points Clés

- CTEs pour queries complexes et lisibles
- Window functions pour analytics avancés
- MERGE pour upserts efficaces
- Transactions avec error handling
- EXPLAIN pour comprendre execution plans
- Optimiser JOINs avec distributions alignées
- Éviter curseurs, préférer set-based ops
- Statistiques à jour essentielles

---

**Prochain fichier :** [04 - Warehouse vs Lakehouse](./04-warehouse-vs-lakehouse.md)

[⬅️ Fichier précédent](./02-tables-distributions.md) | [⬅️ Retour au README du module](./README.md)
