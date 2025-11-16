# SQL Analytics Endpoints

## Concept

Chaque **Lakehouse** dans Fabric obtient automatiquement un **SQL Analytics Endpoint** qui permet de requêter les tables Delta avec T-SQL, sans créer de Data Warehouse.

```
┌─────────────────────────────────────────┐
│            Lakehouse                     │
├─────────────────────────────────────────┤
│  Tables/                                 │
│    ├── customer_data (Delta)            │
│    ├── sales_data (Delta)               │
│    └── product_catalog (Delta)          │
└──────────────────┬──────────────────────┘
                   │
                   │ Automatic SQL Endpoint
                   ↓
┌─────────────────────────────────────────┐
│      SQL Analytics Endpoint              │
├─────────────────────────────────────────┤
│  • Read-only T-SQL access               │
│  • Automatic creation                   │
│  • OneLake read-through                 │
│  • Power BI integration                 │
└─────────────────────────────────────────┘
```

## Caractéristiques

### Automatique et Read-Only

- **Créé automatiquement** avec chaque Lakehouse
- **Read-only** : SELECT queries seulement
- **Pas d'INSERT/UPDATE/DELETE** (utiliser Spark pour modifications)
- **Synchronisé en temps réel** avec Lakehouse tables

### Architecture

```
User Query (T-SQL)
    ↓
SQL Analytics Endpoint
    ↓
OneLake Read Layer
    ↓
Delta Lake Files
    ↓
Results
```

## Accès au SQL Endpoint

### Via Fabric UI

```
Workspace → Lakehouse
  ├─ Lakehouse view (Spark)
  └─ SQL analytics endpoint view (SQL)  ← Switch ici
```

**Interface SQL Endpoint :**
```
SQL Endpoint View:
├── Schemas
│   └── dbo
├── Tables
│   ├── customer_data
│   ├── sales_data
│   └── product_catalog
└── Views (créées par vous)
```

### Via SSMS (SQL Server Management Studio)

```
Server: {workspace}.datawarehouse.fabric.microsoft.com
Database: {lakehouse_name}
Authentication: Azure Active Directory - Universal with MFA

Connection:
  Server type: Database Engine
  Server name: contoso.datawarehouse.fabric.microsoft.com
  Database: SalesLakehouse
  Authentication: Azure AD MFA
```

### Via Azure Data Studio

```
Connection type: Microsoft SQL Server
Server: {workspace}.datawarehouse.fabric.microsoft.com
Authentication: Azure Active Directory
Database: {lakehouse_name}
```

### Via Python (pyodbc)

```python
import pyodbc

conn_str = (
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=contoso.datawarehouse.fabric.microsoft.com;'
    'DATABASE=SalesLakehouse;'
    'Authentication=ActiveDirectoryInteractive'
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Query Lakehouse tables via T-SQL
cursor.execute("SELECT TOP 10 * FROM customer_data WHERE country = 'FR'")
for row in cursor:
    print(row)

cursor.close()
conn.close()
```

### Via Power BI

```
Get Data
  → SQL Server
  → Server: {workspace}.datawarehouse.fabric.microsoft.com
  → Database: {lakehouse_name}
  → Mode: DirectQuery ou Import
```

## Requêtes T-SQL

### Queries Basiques

```sql
-- SELECT simple
SELECT
    customer_id,
    customer_name,
    country
FROM customer_data
WHERE country = 'FR';

-- Aggregations
SELECT
    country,
    COUNT(*) as customer_count,
    AVG(total_purchases) as avg_purchases
FROM customer_data
GROUP BY country;
```

### JOINs

```sql
-- JOIN entre tables Lakehouse
SELECT
    c.customer_name,
    SUM(s.amount) as total_sales
FROM sales_data s
INNER JOIN customer_data c
    ON s.customer_id = c.customer_id
WHERE s.sale_date >= '2024-01-01'
GROUP BY c.customer_name;
```

### CTEs et Subqueries

```sql
-- CTE
WITH monthly_sales AS (
    SELECT
        customer_id,
        YEAR(sale_date) as year,
        MONTH(sale_date) as month,
        SUM(amount) as total
    FROM sales_data
    GROUP BY customer_id, YEAR(sale_date), MONTH(sale_date)
)
SELECT
    customer_id,
    AVG(total) as avg_monthly_sales
FROM monthly_sales
GROUP BY customer_id;
```

### Window Functions

```sql
-- ROW_NUMBER sur données Lakehouse
SELECT
    customer_id,
    sale_date,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY sale_date DESC
    ) as recency_rank
FROM sales_data;
```

## Vues et Objets SQL

### Créer des Vues

```sql
-- Vue analytics
CREATE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.country,
    COUNT(s.sale_id) as total_orders,
    SUM(s.amount) as total_sales,
    AVG(s.amount) as avg_order_value
FROM customer_data c
LEFT JOIN sales_data s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name, c.country;

-- Query la vue
SELECT * FROM vw_customer_summary WHERE country = 'FR';
```

### Fonctions

```sql
-- Fonction inline table-valued
CREATE FUNCTION fn_sales_by_date(@start_date DATE, @end_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT
        customer_id,
        SUM(amount) as total_sales
    FROM sales_data
    WHERE sale_date BETWEEN @start_date AND @end_date
    GROUP BY customer_id
);

-- Utilisation
SELECT * FROM fn_sales_by_date('2024-01-01', '2024-01-31');
```

### Procédures Stockées (Limitations)

```sql
-- ⚠️ Procédures read-only seulement
CREATE PROCEDURE sp_get_top_customers
    @country VARCHAR(50),
    @top_n INT
AS
BEGIN
    SELECT TOP (@top_n)
        customer_id,
        customer_name,
        total_sales
    FROM vw_customer_summary
    WHERE country = @country
    ORDER BY total_sales DESC;
END;

-- Exécution
EXEC sp_get_top_customers @country = 'FR', @top_n = 10;
```

## Limitations SQL Endpoint

### Read-Only

```sql
-- ❌ Ne fonctionne PAS
INSERT INTO customer_data VALUES (...);
UPDATE customer_data SET ...;
DELETE FROM customer_data WHERE ...;
CREATE TABLE new_table (...);

-- ✅ Fonctionne (read-only)
SELECT * FROM customer_data;
CREATE VIEW vw_... AS SELECT ...;
CREATE FUNCTION fn_... RETURNS TABLE AS ...;
```

### Modifications via Spark

```python
# Pour modifier données, utiliser Spark dans Lakehouse
from pyspark.sql.functions import *

# INSERT via Spark
new_data_df.write.format("delta") \
    .mode("append") \
    .saveAsTable("customer_data")

# UPDATE via Spark
from delta.tables import DeltaTable

delta_table = DeltaTable.forName(spark, "customer_data")
delta_table.update(
    condition = "customer_id = 123",
    set = {"country": "'US'"}
)

# DELETE via Spark
delta_table.delete("customer_id = 456")
```

## Performance

### Query Performance

**Avantages :**
- Lecture directe depuis Delta files
- Partition pruning automatique
- Data skipping via Delta stats
- V-Order optimization

**Example avec partition pruning :**
```sql
-- Table partitionnée par year, month
SELECT * FROM sales_data
WHERE sale_date >= '2024-01-01' AND sale_date < '2024-02-01';

-- SQL Endpoint lit SEULEMENT partition year=2024/month=01/
-- Ignore toutes autres partitions
-- → Performance boost
```

### Optimizations

```sql
-- EXPLAIN plan disponible
SET SHOWPLAN_XML ON;
GO

SELECT
    c.customer_name,
    SUM(s.amount) as total
FROM sales_data s
JOIN customer_data c ON s.customer_id = c.customer_id
GROUP BY c.customer_name;

GO
SET SHOWPLAN_XML OFF;
```

## Intégration Power BI

### DirectQuery Mode

```
Power BI Desktop
  → Get Data
  → SQL Server
  → Server: workspace.datawarehouse.fabric.microsoft.com
  → Database: SalesLakehouse
  → Mode: DirectQuery

Avantages:
  - Données toujours à jour
  - Pas de refresh manuel
  - Queries pushed to SQL Endpoint

Inconvénients:
  - Latence sur chaque query
  - Concurrent user limits
```

### Import Mode

```
Mode: Import

Avantages:
  - Performance rapide (données en mémoire)
  - Pas de limite concurrence

Inconvénients:
  - Nécessite refresh
  - Duplicate storage
```

### Direct Lake Mode (Meilleur)

```
Power BI avec Direct Lake:
  → Lit directement OneLake files
  → Pas de SQL Endpoint overhead
  → Performance optimale

Configuration:
  Power BI → Semantic Model
  → Connection mode: Direct Lake
  → Source: Lakehouse tables

✅ Recommandé pour Fabric!
```

## SQL Endpoint vs Data Warehouse

| Feature | SQL Endpoint | Data Warehouse |
|---------|--------------|----------------|
| **Création** | Automatique (Lakehouse) | Manuelle |
| **Modifications** | Read-only | Full DML (INSERT/UPDATE/DELETE) |
| **Distributions** | Pas de contrôle | HASH, REPLICATE, ROUND_ROBIN |
| **Indexes** | Automatique (Delta stats) | Clustered, Columnstore |
| **Transactions** | Via Spark seulement | Full T-SQL transactions |
| **Use Case** | Query Lakehouse data | Full data warehouse |
| **Cost** | Inclus avec Lakehouse | CU consumption |
| **Concurrence** | Moyenne | Élevée |

### Quand Utiliser SQL Endpoint

✅ **Bon pour :**
- Requêter des tables Lakehouse existantes
- BI tools avec T-SQL
- Analysts sans compétences Spark
- Queries read-only
- Prototypage rapide

❌ **Pas bon pour :**
- Modifications fréquentes de données
- Haute concurrence (100+ users)
- Complex distribution strategies
- Full data warehouse features

### Quand Upgrader vers Warehouse

```
Signaux qu'il faut passer à Warehouse:

1. Besoin de DML (INSERT/UPDATE/DELETE) en T-SQL
2. Concurrence > 50 users
3. Besoin de distributions optimisées
4. RLS/CLS complexe
5. Performance critique pour BI
6. Legacy BI tools dependency
```

## Exemples Pratiques

### Exemple 1 : Reporting Simple

```sql
-- Lakehouse contient données ETL
-- SQL Endpoint pour reporting

-- Rapport ventes par région
CREATE VIEW vw_sales_by_region AS
SELECT
    c.country,
    c.region,
    COUNT(DISTINCT s.customer_id) as unique_customers,
    COUNT(s.sale_id) as total_orders,
    SUM(s.amount) as total_revenue,
    AVG(s.amount) as avg_order_value
FROM sales_data s
JOIN customer_data c ON s.customer_id = c.customer_id
WHERE s.sale_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY c.country, c.region;

-- Power BI connecte à cette vue
```

### Exemple 2 : Data Quality Checks

```sql
-- Vérifier qualité via SQL Endpoint
SELECT
    'Missing customer names' as check_name,
    COUNT(*) as failed_count
FROM customer_data
WHERE customer_name IS NULL OR customer_name = ''

UNION ALL

SELECT
    'Negative sales amounts' as check_name,
    COUNT(*) as failed_count
FROM sales_data
WHERE amount < 0

UNION ALL

SELECT
    'Future dates' as check_name,
    COUNT(*) as failed_count
FROM sales_data
WHERE sale_date > GETDATE();
```

### Exemple 3 : Federated Queries

```sql
-- Query across Lakehouse + external data
SELECT
    l.customer_id,
    l.total_lakehouse_sales,
    e.external_revenue
FROM (
    SELECT customer_id, SUM(amount) as total_lakehouse_sales
    FROM sales_data
    GROUP BY customer_id
) l
FULL OUTER JOIN OPENROWSET(
    BULK 'https://external.blob.core.windows.net/data/revenue.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0'
) AS e
ON l.customer_id = e.customer_id;
```

## Sécurité

### Row-Level Security (RLS)

```sql
-- Créer fonction security
CREATE FUNCTION dbo.fn_security_predicate(@region VARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS result
    WHERE @region = USER_NAME() OR IS_MEMBER('AdminRole') = 1;

-- Appliquer policy
CREATE SECURITY POLICY RegionalSalesPolicy
ADD FILTER PREDICATE dbo.fn_security_predicate(region)
ON dbo.sales_data
WITH (STATE = ON);

-- Users voient seulement leur région
```

### Permissions

```sql
-- Grant SELECT sur tables
GRANT SELECT ON customer_data TO [analyst@company.com];

-- Grant EXECUTE sur procédures
GRANT EXECUTE ON sp_get_top_customers TO [analyst@company.com];

-- Deny sur colonnes sensibles
DENY SELECT ON customer_data(credit_card) TO [analyst@company.com];
```

## Monitoring

### DMVs (Dynamic Management Views)

```sql
-- Queries actives
SELECT
    session_id,
    start_time,
    status,
    command,
    wait_type,
    wait_time
FROM sys.dm_exec_requests
WHERE status = 'running';

-- Sessions
SELECT
    session_id,
    login_name,
    host_name,
    program_name,
    login_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
```

### Query Performance

```sql
-- Top queries par durée
SELECT TOP 10
    query_hash,
    total_elapsed_time / execution_count as avg_duration_ms,
    execution_count,
    total_logical_reads / execution_count as avg_reads
FROM sys.dm_exec_query_stats
ORDER BY avg_duration_ms DESC;
```

## Best Practices

✅ **DO:**
```sql
-- Créer vues pour business logic
CREATE VIEW vw_clean_sales AS
SELECT * FROM sales_data WHERE amount > 0;

-- Filtrer tôt
SELECT * FROM sales_data
WHERE sale_date >= '2024-01-01'  -- Partition pruning

-- Utiliser CTEs pour lisibilité
WITH filtered AS (SELECT ...)
SELECT * FROM filtered;
```

❌ **DON'T:**
```sql
-- Tenter des modifications
UPDATE sales_data SET ...;  -- ❌ Erreur

-- SELECT * sans filtre
SELECT * FROM huge_table;  -- ❌ Lent

-- Ignorer partition columns
WHERE YEAR(sale_date) = 2024;  -- ❌ Pas de partition pruning
```

## Points Clés

- SQL Endpoint = read-only T-SQL sur Lakehouse
- Automatiquement créé avec chaque Lakehouse
- Parfait pour BI tools et analysts SQL
- Pas de DML (utiliser Spark pour modifications)
- Performance optimisée via Delta Lake
- Power BI Direct Lake meilleur que DirectQuery
- Upgrade vers Warehouse si besoin full SQL features
- RLS/CLS supportés

---

**Prochain fichier :** [06 - Performance Tuning](./06-performance-tuning.md)

[⬅️ Fichier précédent](./04-warehouse-vs-lakehouse.md) | [⬅️ Retour au README du module](./README.md)
