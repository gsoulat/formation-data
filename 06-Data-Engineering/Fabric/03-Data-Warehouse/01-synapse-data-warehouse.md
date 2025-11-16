# Synapse Data Warehouse

## Introduction

Synapse Data Warehouse dans Fabric est un **entrepôt de données relationnel** massivement parallèle (MPP) optimisé pour les workloads analytics.

```
┌─────────────────────────────────────┐
│   Synapse Data Warehouse (Fabric)   │
├─────────────────────────────────────┤
│  Compute Layer (SQL Engine)         │
│    ├─ Query Processing               │
│    ├─ Distributed Execution          │
│    └─ Caching                        │
├─────────────────────────────────────┤
│  Storage Layer (OneLake)             │
│    └─ Delta Lake Format              │
└─────────────────────────────────────┘
```

## Architecture

### Separation Compute/Storage

```
Compute (SQL Pools) ← Elastic scaling
    ↕
Storage (OneLake) ← Persistent
```

**Avantages :**
- Scale compute indépendamment du storage
- Pause compute sans perdre données
- Storage facturé séparément (moins cher)

### Distributed Processing

```
Query:
  SELECT SUM(amount) FROM sales GROUP BY region

Execution:
  ┌─────────┐  ┌─────────┐  ┌─────────┐
  │ Node 1  │  │ Node 2  │  │ Node 3  │
  │ Process │  │ Process │  │ Process │
  │ 1/3 data│  │ 1/3 data│  │ 1/3 data│
  └────┬────┘  └────┬────┘  └────┬────┘
       └──────────┬────────────┘
            ┌─────▼─────┐
            │ Aggregate │
            │  Results  │
            └───────────┘
```

## Différences avec Azure Synapse Analytics

| Feature | Azure Synapse Dedicated Pool | Fabric Warehouse |
|---------|------------------------------|------------------|
| **Licensing** | Standalone (DWU) | Inclus dans Fabric capacity |
| **Storage** | ADLS Gen2 (separate) | OneLake (integrated) |
| **Format** | Proprietary | Delta Lake |
| **Scaling** | Manual (DWU levels) | Auto (dans capacity) |
| **Integration** | External tools | Native Fabric workloads |
| **Cost Model** | Per DWU-hour | Per CU-hour (capacity) |
| **Pause/Resume** | Manual | Auto (capacity) |

## Création d'un Warehouse

### Via UI

```
1. Workspace → + New item
2. Data Warehouse
3. Nom: "SalesWarehouse"
4. Create
```

### Structure Créée

```
SalesWarehouse/
├── Schemas/
│   └── dbo (default)
├── Tables/
├── Views/
├── Stored Procedures/
└── Functions/
```

## Connexion au Warehouse

### 1. Via Fabric UI

```
Workspace → SalesWarehouse → Querying
  └─ SQL query editor intégré
```

### 2. Via SQL Server Management Studio (SSMS)

```
Server: {workspace}.datawarehouse.fabric.microsoft.com
Database: SalesWarehouse
Authentication: Azure Active Directory - Universal with MFA
```

### 3. Via Azure Data Studio

```
Connection type: Microsoft SQL Server
Server: {workspace}.datawarehouse.fabric.microsoft.com
Authentication: Azure Active Directory
```

### 4. Via Python (pyodbc)

```python
import pyodbc

conn_str = (
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER={workspace}.datawarehouse.fabric.microsoft.com;'
    'DATABASE=SalesWarehouse;'
    'Authentication=ActiveDirectoryInteractive'
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

cursor.execute("SELECT TOP 10 * FROM sales")
for row in cursor:
    print(row)
```

### 5. Via Power BI

```
Get Data
  → SQL Server
  → Server: {workspace}.datawarehouse.fabric.microsoft.com
  → Database: SalesWarehouse
  → DirectQuery ou Import
```

## Schémas

### Schéma par Défaut : dbo

```sql
-- Tables dans dbo
CREATE TABLE dbo.customers (...);
```

### Créer Schémas Personnalisés

```sql
-- Schéma pour domaine métier
CREATE SCHEMA sales;
CREATE SCHEMA marketing;
CREATE SCHEMA finance;

-- Tables dans schémas
CREATE TABLE sales.orders (...);
CREATE TABLE marketing.campaigns (...);
CREATE TABLE finance.budgets (...);
```

**Organisation recommandée :**
```
Warehouse
├── staging (données temporaires)
├── bronze (raw)
├── silver (clean)
├── gold (analytics)
└── metadata (config, logs)
```

## Limites et Quotas

### Limites Actuelles

| Resource | Limite |
|----------|--------|
| Taille max warehouse | Dépend capacity |
| Tables max | 100,000 |
| Colonnes par table | 1,024 |
| Taille ligne | 8,060 bytes |
| Indexes par table | 999 |
| Partitions | 15,000 |

### Quotas Capacity

```
F64 capacity:
  - Concurrent queries: ~10-20
  - Max query duration: 24h
  - Memory per query: Selon disponibilité
```

## Types de Tables

### Tables Régulières

```sql
CREATE TABLE sales (
    sale_id INT NOT NULL,
    customer_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
);
```

### Tables Temporaires

```sql
-- Session-scoped
CREATE TABLE #temp_sales (
    sale_id INT,
    amount DECIMAL(10,2)
);

-- Global temp
CREATE TABLE ##global_temp (
    id INT
);
```

### External Tables

```sql
-- Pointer vers Lakehouse
CREATE EXTERNAL TABLE ext_sales
WITH (
    LOCATION = 'https://onelake.../Lakehouse/Tables/sales',
    DATA_SOURCE = OneLakeSource,
    FILE_FORMAT = DeltaFormat
);
```

## Distributions (voir fichier suivant)

Trois stratégies : ROUND_ROBIN, HASH, REPLICATE

## Indexes

### Clustered Columnstore Index (Default)

```sql
-- Créé automatiquement
CREATE TABLE sales (
    sale_id INT,
    amount DECIMAL(10,2)
);
-- → Columnstore index automatique
```

### Clustered Index

```sql
CREATE TABLE dimension_customer (
    customer_id INT NOT NULL,
    name VARCHAR(100)
)
WITH (
    CLUSTERED INDEX (customer_id)
);
```

### Nonclustered Index

```sql
CREATE NONCLUSTERED INDEX ix_customer_name
ON customers (name);
```

## Partitioning

```sql
-- Table partitionnée par date
CREATE TABLE sales_partitioned (
    sale_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
WITH (
    DISTRIBUTION = HASH(sale_id),
    PARTITION (sale_date RANGE RIGHT FOR VALUES
        ('2023-01-01', '2023-02-01', '2023-03-01'))
);
```

## Statistiques

```sql
-- Créer statistiques
CREATE STATISTICS stat_customer_id ON customers(customer_id);

-- Mettre à jour
UPDATE STATISTICS customers;

-- Auto-create (recommandé)
ALTER DATABASE SalesWarehouse
SET AUTO_CREATE_STATISTICS ON;
```

## Sécurité

### Row-Level Security (RLS)

```sql
-- Fonction de sécurité
CREATE FUNCTION dbo.fn_securitypredicate(@Region VARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS result
WHERE @Region = USER_NAME() OR USER_NAME() = 'Manager';

-- Appliquer policy
CREATE SECURITY POLICY RegionPolicy
ADD FILTER PREDICATE dbo.fn_securitypredicate(Region)
ON dbo.sales
WITH (STATE = ON);
```

### Column-Level Security

```sql
-- Révoquer accès colonne
REVOKE SELECT ON sales(salary) FROM PublicRole;

-- Grant seulement certaines colonnes
GRANT SELECT ON sales(employee_id, name, department) TO AnalystRole;
```

### Dynamic Data Masking

```sql
CREATE TABLE customers (
    customer_id INT,
    email VARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    phone VARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)')
);
```

## Monitoring

### DMVs (Dynamic Management Views)

```sql
-- Queries en cours
SELECT *
FROM sys.dm_pdw_exec_requests
WHERE status = 'Running';

-- Sessions
SELECT *
FROM sys.dm_pdw_exec_sessions
WHERE status = 'Active';

-- Resource utilization
SELECT *
FROM sys.dm_pdw_resource_waits;
```

### Query Store

```sql
-- Activer Query Store
ALTER DATABASE SalesWarehouse
SET QUERY_STORE = ON;

-- Voir top queries
SELECT *
FROM sys.query_store_query
ORDER BY total_duration_ms DESC;
```

## Best Practices

✅ **DO:**
- Utiliser schémas pour organiser
- Créer statistiques sur colonnes de JOIN/WHERE
- Partitionner grandes tables (>100M rows)
- Monitorer avec DMVs
- Implémenter RLS pour sécurité

❌ **DON'T:**
- Trop de small tables (<1M rows → Lakehouse better)
- Ignorer les distributions (impact performance)
- Pas de statistiques (optimizer blind)
- Oublier VACUUM/maintenance

## Migration depuis Synapse Dedicated

```sql
-- Export depuis Synapse Dedicated
EXPORT DATA
INTO 'https://storage.../export/'
FROM dbo.sales;

-- Import dans Fabric Warehouse
COPY INTO sales
FROM 'https://storage.../export/'
WITH (FILE_TYPE = 'PARQUET');
```

## Points Clés

- Warehouse = MPP analytics engine
- Separation compute/storage
- OneLake backend (Delta Lake)
- T-SQL complet supporté
- Distributions cruciales pour performance
- Statistiques essentielles
- RLS/CLS pour sécurité
- Intégré nativement avec Fabric

---

**Prochain fichier :** [02 - Tables et Distributions](./02-tables-distributions.md)

[⬅️ Retour au README du module](./README.md)
