# Module 03 - Data Warehouse

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre Synapse Data Warehouse dans Fabric
- ✅ Créer et gérer des tables avec distributions optimales
- ✅ Écrire des requêtes T-SQL avancées
- ✅ Comparer Warehouse vs Lakehouse et choisir le bon outil
- ✅ Utiliser les SQL endpoints efficacement
- ✅ Optimiser les performances des requêtes

## Contenu du module

### [01 - Synapse Data Warehouse](./01-synapse-data-warehouse.md)
- Introduction au Data Warehouse dans Fabric
- Architecture Synapse DW
- Différences avec Azure Synapse Analytics
- Separation compute/storage dans Fabric
- Use cases et positionnement
- Limites et quotas

### [02 - Tables et Distributions](./02-tables-distributions.md)
- Types de tables (dimension, fact, staging)
- Stratégies de distribution :
  - **Round Robin** : distribution aléatoire
  - **Hash** : distribution par clé
  - **Replicated** : réplication complète
- Indexes (clustered, non-clustered, columnstore)
- Partitionnement de tables
- Choix de la bonne stratégie selon le use case

### [03 - T-SQL Avancé](./03-tsql-queries.md)
- SELECT avancé (CTEs, window functions)
- JOIN optimization
- Fonctions analytiques (ROW_NUMBER, RANK, LEAD/LAG)
- MERGE statements
- Transactions et gestion des locks
- Query hints et optimizations
- Gestion des erreurs (TRY/CATCH)

### [04 - Warehouse vs Lakehouse](./04-warehouse-vs-lakehouse.md)
- Comparaison détaillée
- Quand choisir Warehouse ?
- Quand choisir Lakehouse ?
- Pattern hybride
- Migration entre Warehouse et Lakehouse
- Coût et performance

### [05 - SQL Endpoints](./05-sql-endpoints.md)
- SQL Analytics Endpoint du Lakehouse
- Connexion via SSMS, Azure Data Studio
- Requêtes cross-database
- Limitations du SQL endpoint
- Best practices d'utilisation
- Sécurité et authentification

### [06 - Performance Tuning](./06-performance-tuning.md)
- Query execution plans
- Identification des bottlenecks
- Statistiques et mise à jour
- Materialized views
- Result set caching
- Workload management
- Monitoring des requêtes

## Exercices pratiques

### Exercice 1 : Création d'un Data Warehouse
1. Créer un nouveau Warehouse dans Fabric
2. Se connecter via Azure Data Studio
3. Explorer l'interface et les capacités
4. Créer un schéma dédié

### Exercice 2 : Modélisation dimensionnelle
1. Créer des tables de dimension (Customer, Product, Date)
2. Créer une table de fait (Sales)
3. Choisir les bonnes distributions
4. Implémenter les clés surrogate
5. Créer les relations (foreign keys)

### Exercice 3 : Chargement de données
1. Créer des tables staging
2. Charger des données depuis Lakehouse
3. Utiliser MERGE pour upsert
4. Implémenter SCD Type 2 (Slowly Changing Dimension)

### Exercice 4 : Requêtes analytiques
1. Requêtes avec window functions
2. Calculs de running totals
3. Rank des produits par catégorie
4. Analyses temporelles (YoY, MoM)

### Exercice 5 : Optimisation
1. Analyser un execution plan
2. Créer des statistiques
3. Tester différentes stratégies de distribution
4. Créer une materialized view
5. Mesurer les gains de performance

### Exercice 6 : SQL Endpoint
1. Se connecter au SQL endpoint d'un Lakehouse
2. Requêter des tables Delta via T-SQL
3. Créer des vues cross-database
4. Tester les performances vs Warehouse

## Quiz

1. Quelle est la différence entre Hash distribution et Round Robin ?
2. Quand utiliser une table replicated ?
3. Qu'est-ce qu'un SQL Analytics Endpoint ?
4. Expliquez la différence entre Warehouse et Lakehouse dans Fabric
5. Comment optimiser une requête avec un mauvais execution plan ?

## Exemples de code

### Création de tables avec distribution

```sql
-- Table dimension (replicated)
CREATE TABLE dim_customer (
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    created_date DATE
)
WITH (
    DISTRIBUTION = REPLICATE
);

-- Table fact (hash distributed)
CREATE TABLE fact_sales (
    sale_id BIGINT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    sale_date DATE NOT NULL,
    amount DECIMAL(10,2),
    quantity INT
)
WITH (
    DISTRIBUTION = HASH(customer_id),
    CLUSTERED COLUMNSTORE INDEX
)
PARTITION (
    sale_date RANGE RIGHT FOR VALUES ('2024-01-01', '2024-02-01', '2024-03-01')
);
```

### MERGE pour upsert

```sql
MERGE INTO dim_customer AS target
USING staging_customer AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN
    UPDATE SET
        customer_name = source.customer_name,
        email = source.email
WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, email, created_date)
    VALUES (source.customer_id, source.customer_name, source.email, GETDATE());
```

### Window functions

```sql
-- Rank des produits par ventes par catégorie
SELECT
    product_name,
    category,
    total_sales,
    RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) as rank_in_category,
    SUM(total_sales) OVER (PARTITION BY category) as category_total
FROM product_sales;
```

### Query avec CTE et analytics

```sql
WITH monthly_sales AS (
    SELECT
        YEAR(sale_date) as year,
        MONTH(sale_date) as month,
        SUM(amount) as total_sales
    FROM fact_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT
    year,
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, month) as previous_month,
    total_sales - LAG(total_sales) OVER (ORDER BY year, month) as growth
FROM monthly_sales;
```

## Ressources complémentaires

### Documentation officielle
- [Warehouse in Fabric](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)
- [T-SQL reference](https://learn.microsoft.com/sql/t-sql/language-reference)
- [Table distributions](https://learn.microsoft.com/fabric/data-warehouse/tables)

### Patterns
- [Dimensional modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
- [Star schema design](https://learn.microsoft.com/power-bi/guidance/star-schema)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 4-5 heures
- **Total** : 8-10 heures

## Prochaine étape

➡️ [Module 04 - Data Pipelines](../04-Data-Pipelines/)

---

[⬅️ Module précédent](../02-Lakehouse/) | [⬅️ Retour au sommaire](../README.md)
