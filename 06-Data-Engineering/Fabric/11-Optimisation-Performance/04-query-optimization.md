# Optimisation de Requêtes

## SQL Optimization

### Execution Plans

```sql
-- View execution plan
EXPLAIN SELECT * FROM sales WHERE customer_id = 123;

-- Key things to look for:
-- ✅ Scan with pushdown (filter applied early)
-- ✅ Broadcast join for small tables
-- ❌ Full table scan (no filter pushdown)
-- ❌ Shuffle for large joins (expensive)
```

### Index Usage

```sql
-- In Fabric Warehouse/SQL endpoints
CREATE INDEX idx_customer ON sales(customer_id);

-- Not needed for:
-- Delta Lake tables (use Z-Order instead)
-- Partitioned tables (partition pruning)

-- Use for:
-- Point lookups in SQL databases
-- Frequently filtered columns
```

### Join Optimization

```sql
-- Small table broadcast
SELECT /*+ BROADCAST(dim_product) */
  s.*, p.product_name
FROM sales s
JOIN dim_product p ON s.product_id = p.product_id;

-- Filter before join (reduce data)
SELECT s.*, c.customer_name
FROM (SELECT * FROM sales WHERE year = 2024) s
JOIN customers c ON s.customer_id = c.customer_id;

-- Sort-Merge join for large tables
SELECT /*+ MERGE(sales, orders) */ ...
```

### Statistics

```sql
-- Update statistics for better query planning
ANALYZE TABLE sales COMPUTE STATISTICS;

-- For specific columns
ANALYZE TABLE sales COMPUTE STATISTICS FOR COLUMNS customer_id, product_id;

-- Check statistics
DESCRIBE EXTENDED sales customer_id;
```

## DAX Optimization

### Variables (Avoid Recalculation)

```dax
-- Bad: Calculates twice
Profit Margin =
DIVIDE(
    SUM(Sales[Revenue]) - SUM(Sales[Cost]),
    SUM(Sales[Revenue])
)

-- Good: Calculate once with VAR
Profit Margin =
VAR Revenue = SUM(Sales[Revenue])
VAR Cost = SUM(Sales[Cost])
RETURN DIVIDE(Revenue - Cost, Revenue)
```

### CALCULATE Optimization

```dax
-- Bad: FILTER on large table
Sales France =
CALCULATE(
    SUM(Sales[Amount]),
    FILTER(Sales, Sales[Country] = "France")
)

-- Good: Simple filter expression
Sales France =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Country] = "France"
)
-- Uses column filter, much faster
```

### Avoid Expensive Functions

```dax
-- Expensive: Row iteration
Bad Measure =
SUMX(
    FILTER(ALL(Sales), Sales[Amount] > 100),
    Sales[Amount] * Sales[Quantity]
)

-- Better: Pre-aggregate or simplify
Good Measure =
CALCULATE(
    SUM(Sales[TotalAmount]),
    Sales[Amount] > 100
)

-- Expensive functions to avoid:
-- FILTER on large tables
-- ALL() when not needed
-- Nested CALCULATE
-- Complex SUMX/AVERAGEX
```

### Context Understanding

```dax
-- Know your context
-- Row context: Inside calculated column
-- Filter context: From slicers, visuals

-- CALCULATE modifies filter context
-- Use REMOVEFILTERS/ALL carefully
-- Test with Performance Analyzer
```

## Query Patterns

```sql
-- Aggregation pushdown (good)
SELECT customer_id, SUM(amount)
FROM sales
GROUP BY customer_id;
-- Aggregation done in storage engine

-- Avoid SELECT * (bad)
SELECT * FROM large_table;
-- Reads all columns

-- Use column selection (good)
SELECT customer_id, amount, order_date
FROM sales;
-- Only reads needed columns
```

---

[⬅️ Précédent](./03-caching-mechanisms.md) | [Prochain ➡️](./05-spark-tuning.md)
