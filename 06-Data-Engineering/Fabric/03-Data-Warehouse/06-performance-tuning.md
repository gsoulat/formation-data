# Performance Tuning

## Introduction

L'optimisation des performances dans Synapse Data Warehouse nécessite une approche **multi-facettes** couvrant distributions, indexes, statistiques, et query optimization.

```
Performance Tuning Stack:
├── Distributions (data placement)
├── Indexes (columnstore, clustered)
├── Statistiques (optimizer intelligence)
├── Partitioning (data pruning)
├── Query patterns (JOINs, aggregations)
└── Resource management (concurrency)
```

## Distributions (Critique)

### Impact Performance

```
Mauvaise distribution:
┌─────────────────────────────────────┐
│ Node 1: 80% des données (SKEW)     │ ← Bottleneck!
│ Node 2: 10%                         │
│ Node 3: 10%                         │
└─────────────────────────────────────┘
→ Query time: 60s

Bonne distribution:
┌─────────────────────────────────────┐
│ Node 1: 33%                         │
│ Node 2: 33%                         │
│ Node 3: 34%                         │
└─────────────────────────────────────┘
→ Query time: 5s
```

### Détecter Distribution Skew

```sql
-- Voir distribution des données
SELECT
    distribution_id,
    COUNT(*) as row_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM sys.pdw_nodes_db_partition_stats
WHERE object_id = OBJECT_ID('fact_sales')
    AND index_id IN (0, 1)  -- Heap or clustered
GROUP BY distribution_id
ORDER BY row_count DESC;

-- Résultat attendu (balanced):
-- distribution_id | row_count | percentage
-- 1               | 1,000,000 | 1.67%
-- 2               | 1,000,000 | 1.67%
-- 3               | 1,000,000 | 1.67%
-- ...

-- Résultat problématique (skewed):
-- distribution_id | row_count | percentage
-- 1               | 5,000,000 | 25%  ← SKEW!
-- 2               | 200,000   | 1%
-- 3               | 150,000   | 0.75%
```

### Fixer Distribution Skew

```sql
-- Problème: Distribution sur low cardinality column
CREATE TABLE sales_bad (
    sale_id INT,
    country VARCHAR(2)  -- Seulement quelques valeurs
) WITH (DISTRIBUTION = HASH(country));  -- ❌ Skewed!

-- Solution 1: Choisir high cardinality column
CREATE TABLE sales_good (
    sale_id INT,
    customer_id INT  -- Millions de valeurs uniques
) WITH (DISTRIBUTION = HASH(customer_id));  -- ✅

-- Solution 2: Composite key
CREATE TABLE sales_composite (
    sale_id INT,
    country VARCHAR(2),
    customer_id INT,
    distribution_key AS CAST(country AS VARCHAR) + '_' + CAST(customer_id AS VARCHAR)
) WITH (DISTRIBUTION = HASH(distribution_key));
```

### Data Movement (Query Killer)

```sql
-- Voir data movement dans execution plan
EXPLAIN
SELECT
    f.sale_id,
    c.customer_name
FROM fact_sales f  -- HASH(customer_id)
JOIN dim_region r  -- HASH(region_id)  ← Incompatible!
    ON f.region_id = r.region_id;

-- Résultat plan montre:
-- → ShuffleMove: 1.2 GB transferred
-- → Query time: 45s

-- Fix: Aligner distributions
ALTER TABLE dim_region
REDISTRIBUTE WITH (DISTRIBUTION = REPLICATE);  -- Small table

-- Nouvelle query:
-- → BroadcastMove: 10 MB
-- → Query time: 2s
```

## Indexes

### Clustered Columnstore Index (Default)

```sql
-- Défaut pour grandes tables
CREATE TABLE fact_sales (
    sale_id BIGINT,
    amount DECIMAL(10,2)
)
WITH (CLUSTERED COLUMNSTORE INDEX);

-- Optimal pour:
-- - Tables > 60M rows
-- - Analytics (scans, aggregations)
-- - High compression (5-10x)
```

**Performance :**
```
Table: 100M rows, 50 GB raw

Rowstore:
  Storage: 50 GB
  Scan time: 30s

Columnstore:
  Storage: 8 GB (6x compression)
  Scan time: 3s (segment elimination)
```

### Clustered Index (Rowstore)

```sql
-- Pour petites tables ou high update frequency
CREATE TABLE dim_customer (
    customer_id INT NOT NULL,
    customer_name VARCHAR(100)
)
WITH (CLUSTERED INDEX (customer_id));

-- Optimal pour:
-- - Tables < 5M rows
-- - Point lookups (WHERE id = 123)
-- - Frequent updates/deletes
```

### Heap (No Index)

```sql
-- Staging tables
CREATE TABLE staging_loads (
    data VARCHAR(MAX)
)
WITH (
    HEAP,
    DISTRIBUTION = ROUND_ROBIN
);

-- Optimal pour:
-- - Temporary staging
-- - Load puis transform
-- - Aucune query directe
```

### Index Decision Tree

```
Taille table?
  < 5M rows
    └─→ CLUSTERED INDEX

  5M - 60M rows
    ├─ Workload = Analytics → CLUSTERED COLUMNSTORE
    └─ Workload = OLTP → CLUSTERED INDEX

  > 60M rows
    └─→ CLUSTERED COLUMNSTORE
```

## Statistiques

### Importance

```
Sans statistiques:
  Optimizer blind → Mauvais plans
  Exemple: Broadcast 100M rows table → 180s

Avec statistiques:
  Optimizer intelligent → Bon plan
  Exemple: Shuffle small table → 5s
```

### Créer Statistiques

```sql
-- Automatique (recommandé)
ALTER DATABASE my_warehouse
SET AUTO_CREATE_STATISTICS ON;

-- Manuel sur colonnes critiques
CREATE STATISTICS stat_customer_id
ON fact_sales(customer_id)
WITH FULLSCAN;

-- Sur colonnes de JOIN
CREATE STATISTICS stat_product_id
ON fact_sales(product_id);

-- Sur colonnes de WHERE
CREATE STATISTICS stat_sale_date
ON fact_sales(sale_date);
```

### Update Statistiques

```sql
-- Après gros chargement
INSERT INTO fact_sales SELECT * FROM staging_sales;  -- 10M rows

-- Update stats
UPDATE STATISTICS fact_sales;

-- Ou sur colonne spécifique
UPDATE STATISTICS fact_sales(customer_id);

-- Voir dernière update
SELECT
    OBJECT_NAME(object_id) as table_name,
    name as stat_name,
    stats_date(object_id, stats_id) as last_updated
FROM sys.stats
WHERE OBJECT_NAME(object_id) = 'fact_sales';
```

### Monitoring Stats Quality

```sql
-- Stats obsolètes?
SELECT
    t.name as table_name,
    s.name as stat_name,
    sp.last_updated,
    sp.rows as row_count,
    sp.modification_counter as changes_since_update,
    sp.modification_counter * 100.0 / NULLIF(sp.rows, 0) as pct_changed
FROM sys.stats s
JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
JOIN sys.tables t ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE sp.modification_counter > 0
ORDER BY pct_changed DESC;

-- Si pct_changed > 20% → Update recommandé
```

## Partitioning

### Partition Elimination

```sql
-- Table partitionnée par year
CREATE TABLE sales_partitioned (
    sale_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
WITH (
    DISTRIBUTION = HASH(sale_id),
    PARTITION (sale_date RANGE RIGHT FOR VALUES
        ('2022-01-01', '2023-01-01', '2024-01-01')
    )
);

-- Query avec partition elimination
SELECT SUM(amount)
FROM sales_partitioned
WHERE sale_date >= '2024-01-01' AND sale_date < '2025-01-01';

-- Lit SEULEMENT partition 2024
-- Ignore 2022, 2023 partitions
-- → Performance boost énorme
```

### Optimal Partition Strategy

```sql
-- ❌ Mauvais: Trop de partitions
PARTITION (sale_date RANGE RIGHT FOR VALUES
    ('2024-01-01', '2024-01-02', '2024-01-03', ...)  -- 365 partitions/an
);
-- Problème: Small partitions, overhead metadata

-- ✅ Bon: Partitions équilibrées
PARTITION (sale_date RANGE RIGHT FOR VALUES
    ('2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01')  -- Quarterly
);
-- Optimal: ~1-10 GB par partition
```

### Partition Switching (Fast Loads)

```sql
-- Charger nouvelle partition rapidement
CREATE TABLE staging_q1_2024 (
    sale_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
WITH (
    DISTRIBUTION = HASH(sale_id),
    PARTITION (sale_date RANGE RIGHT FOR VALUES ('2024-01-01'))
);

-- Load data
INSERT INTO staging_q1_2024 SELECT * FROM external_source;

-- Switch partition (metadata operation, instant!)
ALTER TABLE sales_partitioned
SWITCH PARTITION 5 TO staging_q1_2024 PARTITION 1;

-- Résultat: Ajout de 10M rows en <1s
```

## Query Optimization

### JOIN Optimization

```sql
-- ❌ Mauvais: JOIN sans distribution alignment
SELECT f.*, d.*
FROM fact_sales f  -- HASH(customer_id), 100M rows
JOIN dim_region d  -- ROUND_ROBIN, 1000 rows
    ON f.region_id = d.region_id;
-- → Shuffle 100M rows → 60s

-- ✅ Solution 1: REPLICATE small dim
ALTER TABLE dim_region REDISTRIBUTE WITH (DISTRIBUTION = REPLICATE);
-- → Broadcast 1000 rows → 2s

-- ✅ Solution 2: HASH align
ALTER TABLE dim_region REDISTRIBUTE WITH (DISTRIBUTION = HASH(region_id));
-- → No movement → 1s
```

### Filtering Early

```sql
-- ❌ Mauvais: Filtre après JOIN
SELECT c.customer_name, s.amount
FROM fact_sales s
JOIN dim_customer c ON s.customer_id = c.customer_id
WHERE s.sale_date >= '2024-01-01';
-- JOIN 100M rows, puis filtre

-- ✅ Bon: Filtre avant JOIN
SELECT c.customer_name, s.amount
FROM (
    SELECT * FROM fact_sales
    WHERE sale_date >= '2024-01-01'  -- Réduit à 5M rows
) s
JOIN dim_customer c ON s.customer_id = c.customer_id;
-- JOIN seulement 5M rows
```

### Aggregation Pushdown

```sql
-- ✅ Bon: Agrégation avant JOIN
WITH aggregated AS (
    SELECT
        customer_id,
        SUM(amount) as total_sales
    FROM fact_sales
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    a.total_sales
FROM aggregated a
JOIN dim_customer c ON a.customer_id = c.customer_id;

-- Agrégation réduit 100M rows → 1M customers
-- JOIN sur 1M rows seulement
```

### LIMIT Usage

```sql
-- ✅ Utiliser TOP pour limiter résultats
SELECT TOP 1000
    customer_name,
    total_sales
FROM customer_summary
ORDER BY total_sales DESC;

-- Optimizer peut arrêter scan tôt
```

## Concurrency et Resource Management

### Concurrency Slots

```
Fabric Capacity F64:
  - Total concurrency slots: ~64
  - Par query: 1-4 slots selon complexité
  - Max concurrent queries: 16-64

Query simple (1 slot):
  SELECT * FROM dim_customer WHERE id = 123

Query complexe (4 slots):
  SELECT ... FROM fact_sales
  JOIN dim1 JOIN dim2 JOIN dim3
  GROUP BY ... HAVING ...
```

### Resource Classes (Implicite dans Fabric)

```sql
-- Queries complexes obtiennent plus de ressources automatiquement
SELECT
    c.customer_name,
    SUM(s.amount) as total,
    COUNT(DISTINCT s.product_id) as unique_products
FROM fact_sales s  -- 100M rows
JOIN dim_customer c ON s.customer_id = c.customer_id
GROUP BY c.customer_name;

-- Fabric alloue ressources basé sur query complexity
```

### Query Timeouts

```sql
-- Set timeout pour queries longues
SET QUERY_GOVERNOR_COST_LIMIT 3600;  -- 1 heure

-- Pour prévenir runaway queries
```

## Materialized Views

### Créer Materialized View

```sql
-- Pré-calculer aggregations coûteuses
CREATE MATERIALIZED VIEW mv_sales_summary
WITH (DISTRIBUTION = HASH(customer_id))
AS
SELECT
    customer_id,
    product_category,
    YEAR(sale_date) as year,
    SUM(amount) as total_sales,
    COUNT(*) as order_count
FROM fact_sales
GROUP BY customer_id, product_category, YEAR(sale_date);

-- Maintenant query la MV (instant!)
SELECT * FROM mv_sales_summary WHERE customer_id = 123;
```

### Refresh Materialized View

```sql
-- Refresh après updates
ALTER MATERIALIZED VIEW mv_sales_summary REBUILD;

-- Ou automatique
ALTER MATERIALIZED VIEW mv_sales_summary
SET (AUTO_REFRESH = ON);
```

### Quand Utiliser

✅ **Bon pour :**
- Aggregations fréquentes
- Queries répétitives
- Complex JOINs réutilisés

❌ **Pas bon pour :**
- Données changeant constamment
- Ad-hoc queries
- Storage limité

## Result Set Caching

### Activer Cache

```sql
-- Database level
ALTER DATABASE my_warehouse
SET RESULT_SET_CACHING ON;

-- Session level
SET RESULT_SET_CACHING ON;

-- Query identique hit cache
SELECT SUM(amount) FROM fact_sales WHERE year = 2024;
-- 1ère exécution: 10s
-- 2ème exécution: 0.1s (from cache)
```

### Cache Invalidation

```
Cache invalided quand:
  - Données sous-jacentes modifiées
  - 48 heures écoulées
  - Cache manuellement cleared
```

## Monitoring Performance

### DMVs Essentiels

```sql
-- 1. Queries en cours
SELECT
    request_id,
    status,
    command,
    total_elapsed_time / 1000.0 as elapsed_sec,
    start_time
FROM sys.dm_pdw_exec_requests
WHERE status NOT IN ('Completed', 'Failed', 'Cancelled')
ORDER BY total_elapsed_time DESC;

-- 2. Data movement operations
SELECT
    request_id,
    step_index,
    operation_type,
    location_type,
    total_elapsed_time / 1000.0 as elapsed_sec
FROM sys.dm_pdw_request_steps
WHERE request_id = 'QID12345'
ORDER BY step_index;

-- 3. Waiting queries
SELECT
    session_id,
    wait_id,
    wait_type,
    wait_time / 1000.0 as wait_sec,
    object_name
FROM sys.dm_pdw_waits
WHERE session_id = 'SID67890'
ORDER BY wait_time DESC;
```

### EXPLAIN Plans

```sql
-- Voir execution plan
EXPLAIN
SELECT
    c.customer_name,
    SUM(s.amount) as total
FROM fact_sales s
JOIN dim_customer c ON s.customer_id = c.customer_id
WHERE s.sale_date >= '2024-01-01'
GROUP BY c.customer_name;

-- Output montre:
-- 1. Data movement (shuffle, broadcast, none)
-- 2. Operations (scan, join, aggregate)
-- 3. Estimated rows
-- 4. Distributions utilisées
```

## Query Tuning Checklist

### ✅ Pré-Query Checks

```sql
-- 1. Statistiques à jour?
SELECT STATS_DATE(object_id, stats_id) as last_update
FROM sys.stats
WHERE object_id = OBJECT_ID('fact_sales');

-- Si > 7 jours ou > 20% changements
UPDATE STATISTICS fact_sales;

-- 2. Distribution appropriée?
SELECT distribution_policy_desc
FROM sys.pdw_table_distribution_properties
WHERE object_id = OBJECT_ID('fact_sales');

-- 3. Index optimal?
SELECT index_type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('fact_sales');
```

### ✅ Query Pattern Checks

```sql
-- ❌ Éviter
SELECT * FROM huge_table;  -- Trop de colonnes
WHERE YEAR(date_col) = 2024;  -- Fonction sur colonne
SELECT DISTINCT * FROM ...;  -- DISTINCT coûteux

-- ✅ Préférer
SELECT col1, col2 FROM huge_table;  -- Colonnes nécessaires seulement
WHERE date_col >= '2024-01-01' AND date_col < '2025-01-01';  -- Range
GROUP BY col1, col2;  -- Au lieu de DISTINCT
```

## Troubleshooting Performance

### Scenario 1 : Query Lente

```sql
-- Étape 1: Identifier query
SELECT TOP 5
    request_id,
    command,
    total_elapsed_time / 1000 as elapsed_sec
FROM sys.dm_pdw_exec_requests
WHERE status = 'Completed'
ORDER BY total_elapsed_time DESC;

-- Étape 2: Analyser steps
SELECT
    step_index,
    operation_type,
    location_type,
    total_elapsed_time / 1000 as step_sec
FROM sys.dm_pdw_request_steps
WHERE request_id = 'QID12345'
ORDER BY total_elapsed_time DESC;

-- Étape 3: Identifier bottleneck
-- Si "ShuffleMove" domine → Distribution problem
-- Si "OnOperation" lent → Index/Stats problem
```

### Scenario 2 : Data Movement Excessif

```sql
-- Problème détecté
EXPLAIN SELECT ...;
-- → ShuffleMove: 50 GB

-- Solution 1: Aligner distributions
ALTER TABLE table1 REDISTRIBUTE WITH (DISTRIBUTION = HASH(join_key));

-- Solution 2: REPLICATE small table
ALTER TABLE small_table REDISTRIBUTE WITH (DISTRIBUTION = REPLICATE);
```

### Scenario 3 : Concurrency Issues

```sql
-- Queries en attente
SELECT
    session_id,
    wait_type,
    wait_time / 1000.0 as wait_sec
FROM sys.dm_pdw_waits
WHERE state = 'Waiting'
ORDER BY wait_time DESC;

-- Solution: Capacity scaling ou query optimization
```

## Best Practices Summary

### ✅ Tables

```sql
-- Fact tables (large)
CREATE TABLE fact_sales (...)
WITH (
    DISTRIBUTION = HASH(customer_id),  -- High cardinality
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (sale_date RANGE RIGHT FOR VALUES (...))
);

-- Dimensions (small)
CREATE TABLE dim_product (...)
WITH (
    DISTRIBUTION = REPLICATE,  -- < 2 GB
    CLUSTERED INDEX (product_id)
);

-- Dimensions (large)
CREATE TABLE dim_customer (...)
WITH (
    DISTRIBUTION = HASH(customer_id),  -- Align avec fact
    CLUSTERED COLUMNSTORE INDEX
);
```

### ✅ Maintenance

```sql
-- Weekly
UPDATE STATISTICS fact_sales;
REBUILD INDEX idx_columnstore ON fact_sales;

-- Monthly
ALTER INDEX idx_columnstore ON fact_sales REORGANIZE;

-- Quarterly
DBCC PDW_SHOWSPACEUSED('fact_sales');  -- Check growth
```

### ✅ Queries

```sql
-- Toujours filtrer tôt
WITH filtered AS (
    SELECT * FROM fact_sales
    WHERE sale_date >= '2024-01-01'  -- Partition elimination
)
SELECT ... FROM filtered ...;

-- Utiliser EXISTS au lieu de IN pour grandes tables
WHERE EXISTS (SELECT 1 FROM ... WHERE ...);

-- Limiter résultats
SELECT TOP 1000 ... ORDER BY ...;
```

## Points Clés

- Distributions = #1 facteur performance
- Statistiques à jour critiques
- Columnstore pour grandes tables analytics
- Partitioning pour time-series data
- Aligner distributions pour JOINs
- REPLICATE small dimensions
- Monitor DMVs régulièrement
- EXPLAIN plans pour comprendre queries
- Materialized views pour aggregations répétées
- Result set caching automatique

---

**Module 03 COMPLET** ✅

[⬅️ Fichier précédent](./05-sql-endpoints.md) | [➡️ Module suivant : Data Pipelines](../../04-Data-Pipelines/) | [⬅️ Retour au README du module](./README.md)
