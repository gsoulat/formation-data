# Tables et Distributions

## Concept de Distribution

Dans un MPP warehouse, les données sont **distribuées** across compute nodes pour paralléliser les requêtes.

```
Table: 1 million rows

Distribution Strategy:
┌─────────────┬─────────────┬─────────────┐
│   Node 1    │   Node 2    │   Node 3    │
│  333K rows  │  333K rows  │  333K rows  │
└─────────────┴─────────────┴─────────────┘
```

## Les 3 Stratégies de Distribution

### 1. ROUND_ROBIN (Par Défaut)

**Distribution aléatoire** des rows across nodes.

```sql
CREATE TABLE staging_data (
    id INT,
    data VARCHAR(100)
)
WITH (DISTRIBUTION = ROUND_ROBIN);
```

**Avantages :**
- Distribution uniforme garantie
- Rapide à charger (pas de hash calculation)
- Bon pour staging tables

**Inconvénients :**
- Data movement lors des JOINs
- Pas optimal pour analytics

**Use case :** Staging, temporary data

### 2. HASH Distribution

Distribution basée sur le **hash d'une colonne**.

```sql
CREATE TABLE fact_sales (
    sale_id INT,
    customer_id INT,
    amount DECIMAL(10,2)
)
WITH (DISTRIBUTION = HASH(customer_id));
```

**Comment ça marche :**
```
customer_id = 12345
  ↓ hash function
hash = 42
  ↓ modulo number of nodes
node = 42 % 60 = 42
  → Row va sur node 42
```

**Avantages :**
- Données avec même clé = même node
- JOINs sur clé de distribution = zéro data movement
- Performance optimale pour grandes tables

**Inconvénients :**
- Distribution peut être skewed si mauvais choix de colonne
- Hash overhead au chargement

**Use case :** Large fact tables, tables souvent joined

### 3. REPLICATE

**Copie complète** de la table sur chaque node.

```sql
CREATE TABLE dim_product (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50)
)
WITH (DISTRIBUTION = REPLICATE);
```

**Avantages :**
- Zero data movement pour JOINs
- Performance maximale pour petites dimensions

**Inconvénients :**
- Storage multiplié par nombre de nodes
- Chargement plus lent (copie sur tous les nodes)

**Use case :** Small dimension tables (<2 GB)

## Choisir la Bonne Distribution

### Decision Tree

```
Est-ce une petite table (<2 GB)?
  └─ YES → REPLICATE
  └─ NO  ↓

Est-ce une staging table?
  └─ YES → ROUND_ROBIN
  └─ NO  ↓

Table souvent joined sur une colonne?
  └─ YES → HASH(join_column)
  └─ NO  → ROUND_ROBIN
```

### Exemples par Type de Table

**Fact Tables :**
```sql
-- Grande table de faits
CREATE TABLE fact_sales (
    sale_id BIGINT,
    customer_id INT,      -- ← Souvent joined
    product_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
WITH (
    DISTRIBUTION = HASH(customer_id),  -- Clé de distribution
    CLUSTERED COLUMNSTORE INDEX
);
```

**Dimension Tables (Small) :**
```sql
-- Petite dimension (<100K rows)
CREATE TABLE dim_product (
    product_id INT,
    product_name VARCHAR(100)
)
WITH (
    DISTRIBUTION = REPLICATE  -- Copie partout
);
```

**Dimension Tables (Large) :**
```sql
-- Grande dimension (>10M rows)
CREATE TABLE dim_customer (
    customer_id INT,
    customer_name VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(customer_id)  -- Comme fact table
);
```

**Staging Tables :**
```sql
CREATE TABLE staging_loads (
    data VARCHAR(MAX)
)
WITH (
    DISTRIBUTION = ROUND_ROBIN,  -- Rapide à charger
    HEAP                          -- Pas d'index
);
```

## Data Movement

### Types de Movement

**1. Shuffle Move**
```sql
-- Tables avec distributions différentes
SELECT f.*, d.*
FROM fact_sales f  -- HASH(customer_id)
JOIN dim_region d  -- HASH(region_id)
  ON f.region_id = d.region_id

-- → SHUFFLE: Déplace une des tables pour aligner
```

**2. Broadcast Move**
```sql
-- Petite table non-replicated joined avec grande
SELECT f.*, s.*
FROM fact_sales f      -- HASH(customer_id), 100M rows
JOIN small_lookup s    -- ROUND_ROBIN, 100 rows
  ON f.status_code = s.code

-- → BROADCAST: Copie small_lookup sur tous les nodes
```

**3. No Movement**
```sql
-- JOIN sur clé de distribution
SELECT f.*, c.*
FROM fact_sales f       -- HASH(customer_id)
JOIN dim_customer c     -- HASH(customer_id)
  ON f.customer_id = c.customer_id

-- → AUCUN MOVEMENT: Données déjà co-located ✅
```

## Distribution Skew

### Problème

```
Distribution HASH(country) sur table mondiale:

Node 1: USA (40% des données)  ← Overloaded
Node 2: China (30%)
Node 3: India (15%)
Node 4: Autres (15%)

→ Node 1 bottleneck
→ Mauvaise performance
```

### Détecter le Skew

```sql
-- Voir distribution par node
SELECT
    distribution_id,
    COUNT(*) as row_count
FROM sys.pdw_nodes_db_partition_stats
WHERE object_id = OBJECT_ID('fact_sales')
GROUP BY distribution_id
ORDER BY row_count DESC;
```

### Solutions

**1. Choisir meilleure colonne de distribution**
```sql
-- Mauvais: country (low cardinality)
-- Bon: customer_id (high cardinality)

CREATE TABLE fact_sales (...)
WITH (DISTRIBUTION = HASH(customer_id));
```

**2. Composite Distribution Key**
```sql
-- Créer colonne composite
ALTER TABLE fact_sales
ADD distribution_key AS
    CAST(customer_id AS VARCHAR) + '_' + CAST(order_id AS VARCHAR);

-- Recréer table avec nouvelle distribution
CREATE TABLE fact_sales_new (...)
WITH (DISTRIBUTION = HASH(distribution_key));
```

## Partitioning

### Partitioning vs Distribution

```
Distribution: Across nodes (horizontal)
Partitioning: Within table (vertical by range)

Combinaison:
┌─────────────────────────────────────┐
│ Table partitionnée + distributed     │
├─────────────────────────────────────┤
│ Node 1                               │
│   ├─ Partition 2023-Q1              │
│   ├─ Partition 2023-Q2              │
│   └─ Partition 2023-Q3              │
├─────────────────────────────────────┤
│ Node 2                               │
│   ├─ Partition 2023-Q1              │
│   └─ ...                             │
└─────────────────────────────────────┘
```

### Créer Table Partitionnée

```sql
CREATE TABLE sales_partitioned (
    sale_id INT,
    customer_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    PARTITION (sale_date RANGE RIGHT FOR VALUES
        ('2023-01-01', '2023-04-01', '2023-07-01', '2023-10-01')
    )
);

-- Crée 5 partitions:
-- P1: < 2023-01-01
-- P2: 2023-01-01 to 2023-04-01
-- P3: 2023-04-01 to 2023-07-01
-- P4: 2023-07-01 to 2023-10-01
-- P5: >= 2023-10-01
```

### Partition Elimination

```sql
SELECT * FROM sales_partitioned
WHERE sale_date >= '2023-07-01' AND sale_date < '2023-10-01';

-- Lit SEULEMENT partition P4
-- Ignore P1, P2, P3, P5
-- → Performance boost
```

## Indexes

### Clustered Columnstore Index (Défaut)

```sql
CREATE TABLE fact_sales (...)
WITH (
    CLUSTERED COLUMNSTORE INDEX  -- Défaut si non spécifié
);
```

**Optimal pour :**
- Large tables (>60M rows)
- Analytics (scans, aggregations)
- Compression élevée

### Clustered Index

```sql
CREATE TABLE dim_small (
    id INT PRIMARY KEY
)
WITH (
    CLUSTERED INDEX (id)
);
```

**Optimal pour :**
- Petites tables (<5M rows)
- Lookups fréquents
- Beaucoup d'updates/deletes

### Heap (No Index)

```sql
CREATE TABLE staging (...)
WITH (
    HEAP,
    DISTRIBUTION = ROUND_ROBIN
);
```

**Optimal pour :**
- Staging tables
- Load temporaire
- Pas de queries

## Exemples Complets

### Star Schema Classique

```sql
-- Fact table (large)
CREATE TABLE fact_sales (
    sale_id BIGINT,
    customer_id INT,
    product_id INT,
    store_id INT,
    sale_date DATE,
    amount DECIMAL(10,2)
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (sale_date RANGE RIGHT FOR VALUES
        ('2022-01-01', '2023-01-01', '2024-01-01')
    )
);

-- Dimension (small)
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED INDEX (product_id)
);

-- Dimension (large)
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    country VARCHAR(50)
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
);
```

## Best Practices

✅ **DO:**
- Hash distribute fact tables sur clé de JOIN
- Replicate small dimensions (<2 GB)
- Utiliser high cardinality columns pour distribution
- Partitionner par date pour time-series
- Monitorer skew régulièrement

❌ **DON'T:**
- Distributer sur low cardinality columns
- Replicate large tables (waste storage)
- Trop de partitions (<1M rows par partition)
- Ignorer data movement dans query plans

## Points Clés

- Trois stratégies: ROUND_ROBIN, HASH, REPLICATE
- HASH optimal pour grandes tables joined
- REPLICATE pour petites dimensions
- Data movement = performance killer
- Monitor distribution skew
- Partitioning complète distribution

---

**Prochain fichier :** [03 - T-SQL Avancé](./03-tsql-queries.md)

[⬅️ Fichier précédent](./01-synapse-data-warehouse.md) | [⬅️ Retour au README du module](./README.md)
