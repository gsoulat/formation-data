# Hands-on Labs for DP-700

## Introduction

Les laboratoires pratiques sont essentiels pour maîtriser Microsoft Fabric. Ce guide propose des exercices structurés couvrant tous les domaines de l'examen DP-700, avec des scénarios réalistes que vous pourriez rencontrer en production.

## Prérequis

```python
lab_prerequisites = {
    'fabric_trial': {
        'url': 'https://app.fabric.microsoft.com',
        'duration': '60 days free trial',
        'capacity': 'Trial capacity sufficient for labs'
    },
    'sample_data': [
        'AdventureWorks dataset',
        'Contoso Sales dataset',
        'NYC Taxi dataset (public)'
    ],
    'tools': [
        'Power BI Desktop (latest version)',
        'Azure Data Studio',
        'VS Code with Fabric extensions'
    ],
    'knowledge': [
        'Basic SQL',
        'Python fundamentals',
        'Data modeling concepts'
    ]
}
```

## Lab 1: Lakehouse Implementation

### Objectif
Créer un Lakehouse avec architecture Medallion complète.

### Durée estimée
2-3 heures

### Instructions

```python
# Étape 1: Créer le Lakehouse
"""
1. Accéder à votre workspace Fabric
2. Cliquer sur "New" > "Lakehouse"
3. Nommer: "LH_Sales_Analytics"
4. Créer
"""

# Étape 2: Créer la structure Bronze
bronze_setup = """
-- Dans le notebook Spark

# Créer les tables Bronze (raw data)
from pyspark.sql.types import *

# Schéma pour les ventes
sales_schema = StructType([
    StructField("sale_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("product_id", IntegerType(), True),
    StructField("sale_date", StringType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("unit_price", DoubleType(), True),
    StructField("discount", DoubleType(), True)
])

# Simuler l'ingestion de données raw
raw_sales_data = [
    (1, 101, 1001, "2024-01-15", 2, 29.99, 0.0),
    (2, 102, 1002, "2024-01-15", 1, 49.99, 0.1),
    (3, 101, 1003, "2024-01-16", 5, 9.99, 0.0),
    (4, 103, 1001, "2024-01-16", 1, 29.99, 0.05),
    (5, 102, 1004, "2024-01-17", 3, 19.99, 0.0),
    # Inclure des données "sales" avec problèmes
    (6, None, 1001, "2024-01-17", 1, 29.99, 0.0),  # customer_id null
    (7, 104, 1005, "invalid-date", 2, 15.99, 0.0),  # date invalide
    (8, 105, 1006, "2024-01-18", -1, 39.99, 0.0),  # quantité négative
]

df_bronze = spark.createDataFrame(raw_sales_data, sales_schema)

# Sauvegarder en table Bronze
df_bronze.write.format("delta").mode("overwrite").saveAsTable("bronze_sales")

print(f"Bronze layer created with {df_bronze.count()} records")
"""
```

```python
# Étape 3: Transformation vers Silver
silver_transformation = """
from pyspark.sql.functions import *

# Lire depuis Bronze
df_bronze = spark.read.table("bronze_sales")

# Nettoyage et validation
df_silver = df_bronze \
    .filter(col("customer_id").isNotNull()) \
    .filter(col("quantity") > 0) \
    .withColumn(
        "sale_date_clean",
        to_date(col("sale_date"), "yyyy-MM-dd")
    ) \
    .filter(col("sale_date_clean").isNotNull()) \
    .withColumn(
        "total_amount",
        col("quantity") * col("unit_price") * (1 - col("discount"))
    ) \
    .withColumn("ingestion_timestamp", current_timestamp()) \
    .select(
        "sale_id",
        "customer_id",
        "product_id",
        col("sale_date_clean").alias("sale_date"),
        "quantity",
        "unit_price",
        "discount",
        "total_amount",
        "ingestion_timestamp"
    )

# Sauvegarder en Silver avec validation
df_silver.write.format("delta").mode("overwrite").saveAsTable("silver_sales")

# Rapport de qualité
print(f"Bronze records: {df_bronze.count()}")
print(f"Silver records: {df_silver.count()}")
print(f"Records filtered: {df_bronze.count() - df_silver.count()}")
"""
```

```python
# Étape 4: Agrégation vers Gold
gold_aggregation = """
# Agrégations business-ready
df_silver = spark.read.table("silver_sales")

# Agrégation par jour et produit
df_gold_daily = df_silver.groupBy("sale_date", "product_id") \
    .agg(
        count("sale_id").alias("transaction_count"),
        sum("quantity").alias("total_quantity"),
        sum("total_amount").alias("total_revenue"),
        avg("discount").alias("avg_discount")
    )

df_gold_daily.write.format("delta").mode("overwrite").saveAsTable("gold_daily_sales")

# Agrégation par client
df_gold_customer = df_silver.groupBy("customer_id") \
    .agg(
        count("sale_id").alias("total_transactions"),
        sum("total_amount").alias("lifetime_value"),
        min("sale_date").alias("first_purchase"),
        max("sale_date").alias("last_purchase")
    )

df_gold_customer.write.format("delta").mode("overwrite").saveAsTable("gold_customer_summary")

print("Gold layer aggregations completed")
"""
```

### Validation

```sql
-- Vérifier les tables créées
SELECT * FROM bronze_sales LIMIT 10;
SELECT * FROM silver_sales LIMIT 10;
SELECT * FROM gold_daily_sales;
SELECT * FROM gold_customer_summary;

-- Vérifier l'historique Delta (Time Travel)
DESCRIBE HISTORY silver_sales;

-- Tester Time Travel
SELECT * FROM silver_sales VERSION AS OF 0;
```

---

## Lab 2: Data Warehouse avec SCD

### Objectif
Implémenter un Data Warehouse avec Slowly Changing Dimension Type 2.

### Durée estimée
2 heures

### Instructions

```sql
-- Étape 1: Créer le Warehouse
-- Dans Fabric: New > Warehouse > "DW_Sales"

-- Étape 2: Créer la dimension client avec SCD Type 2
CREATE TABLE dim_customer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    email VARCHAR(255),
    segment VARCHAR(50),
    region VARCHAR(50),
    is_current BIT DEFAULT 1,
    effective_date DATE,
    end_date DATE,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- Étape 3: Créer la table de staging
CREATE TABLE staging_customer (
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    email VARCHAR(255),
    segment VARCHAR(50),
    region VARCHAR(50)
);

-- Étape 4: Insérer des données initiales
INSERT INTO dim_customer (customer_id, customer_name, email, segment, region, effective_date)
VALUES
    (101, 'John Smith', 'john@email.com', 'Gold', 'North', '2024-01-01'),
    (102, 'Jane Doe', 'jane@email.com', 'Silver', 'South', '2024-01-01'),
    (103, 'Bob Wilson', 'bob@email.com', 'Bronze', 'East', '2024-01-01');

-- Étape 5: Simuler des changements (staging)
INSERT INTO staging_customer VALUES
    (101, 'John Smith', 'john.smith@newemail.com', 'Gold', 'North'),  -- Email changé
    (102, 'Jane Doe', 'jane@email.com', 'Gold', 'South'),             -- Segment changé (Silver -> Gold)
    (103, 'Bob Wilson', 'bob@email.com', 'Bronze', 'East'),           -- Pas de changement
    (104, 'Alice Brown', 'alice@email.com', 'Silver', 'West');        -- Nouveau client
```

```sql
-- Étape 6: Implémenter le MERGE pour SCD Type 2
-- Fermer les enregistrements modifiés
UPDATE dim_customer
SET is_current = 0,
    end_date = GETDATE()
WHERE customer_id IN (
    SELECT s.customer_id
    FROM staging_customer s
    INNER JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.is_current = 1
    AND (
        s.email <> d.email OR
        s.segment <> d.segment OR
        s.region <> d.region OR
        s.customer_name <> d.customer_name
    )
);

-- Insérer les nouvelles versions et nouveaux clients
INSERT INTO dim_customer (customer_id, customer_name, email, segment, region, effective_date)
SELECT
    s.customer_id,
    s.customer_name,
    s.email,
    s.segment,
    s.region,
    GETDATE()
FROM staging_customer s
LEFT JOIN dim_customer d ON s.customer_id = d.customer_id AND d.is_current = 1
WHERE d.customer_key IS NULL  -- Nouveaux clients ou versions mises à jour
   OR (
        s.email <> d.email OR
        s.segment <> d.segment OR
        s.region <> d.region OR
        s.customer_name <> d.customer_name
    );

-- Vérifier les résultats
SELECT * FROM dim_customer ORDER BY customer_id, effective_date;
```

---

## Lab 3: Semantic Model Direct Lake

### Objectif
Créer un semantic model Direct Lake avec mesures DAX.

### Durée estimée
1.5 heures

### Instructions

```python
# Étape 1: Préparer les données pour Direct Lake
"""
Dans votre Lakehouse, assurez-vous que les tables Gold sont optimisées:
"""

optimize_for_direct_lake = """
-- Activer V-Order pour performances optimales
ALTER TABLE gold_daily_sales SET TBLPROPERTIES (
    'delta.parquet.vorder.enabled' = 'true'
);

-- Compacter les fichiers
OPTIMIZE gold_daily_sales;
OPTIMIZE gold_customer_summary;

-- Créer une table de dates (dimension temps)
CREATE OR REPLACE TABLE dim_date AS
SELECT
    date as date_key,
    YEAR(date) as year,
    MONTH(date) as month,
    DAY(date) as day,
    QUARTER(date) as quarter,
    WEEKOFYEAR(date) as week_of_year,
    DAYOFWEEK(date) as day_of_week,
    CASE WHEN DAYOFWEEK(date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END as day_type
FROM (
    SELECT explode(sequence(to_date('2024-01-01'), to_date('2024-12-31'), interval 1 day)) as date
);

OPTIMIZE dim_date;
"""
```

```dax
// Étape 2: Créer le Semantic Model
// Dans Fabric: New > Semantic Model > "SM_Sales_Analytics"

// Étape 3: Ajouter les mesures DAX

// Mesure: Total Revenue
Total Revenue =
SUM(gold_daily_sales[total_revenue])

// Mesure: Transaction Count
Transaction Count =
SUM(gold_daily_sales[transaction_count])

// Mesure: Average Transaction Value
Avg Transaction Value =
DIVIDE([Total Revenue], [Transaction Count])

// Mesure: Year-to-Date Revenue
YTD Revenue =
TOTALYTD([Total Revenue], dim_date[date_key])

// Mesure: Month-over-Month Growth
MoM Growth % =
VAR CurrentMonth = [Total Revenue]
VAR PreviousMonth = CALCULATE(
    [Total Revenue],
    DATEADD(dim_date[date_key], -1, MONTH)
)
RETURN
DIVIDE(CurrentMonth - PreviousMonth, PreviousMonth)

// Mesure: Running Total
Running Total =
CALCULATE(
    [Total Revenue],
    FILTER(
        ALLSELECTED(dim_date[date_key]),
        dim_date[date_key] <= MAX(dim_date[date_key])
    )
)
```

### Étape 4: Configurer RLS

```dax
// Créer une table de sécurité
// Security_Users avec colonnes: Email, Region

// Créer un rôle "Regional Sales Manager"
// Filtre sur dim_product ou table appropriée:

[Region] = LOOKUPVALUE(
    Security_Users[Region],
    Security_Users[Email],
    USERPRINCIPALNAME()
)

// Tester avec: View as Role > Regional Sales Manager
```

---

## Lab 4: Real-Time Analytics avec KQL

### Objectif
Configurer un flux d'événements temps réel et créer des requêtes KQL.

### Durée estimée
1.5 heures

### Instructions

```python
# Étape 1: Créer une base KQL
"""
1. Dans Fabric: New > KQL Database > "DB_IoT_Sensors"
2. Noter l'endpoint de la base
"""

# Étape 2: Créer une table pour les événements
kql_create_table = """
.create table SensorEvents (
    DeviceId: string,
    Timestamp: datetime,
    Temperature: real,
    Humidity: real,
    Location: string,
    Status: string
)
"""

# Étape 3: Simuler l'ingestion de données
# Via l'UI Fabric ou script
sample_ingestion = """
.ingest inline into table SensorEvents <|
Device001,2024-01-15T10:00:00Z,22.5,45.2,Building-A,Normal
Device002,2024-01-15T10:00:05Z,23.1,48.7,Building-B,Normal
Device001,2024-01-15T10:01:00Z,22.7,45.5,Building-A,Normal
Device003,2024-01-15T10:01:10Z,35.2,62.1,Building-C,Alert
Device002,2024-01-15T10:02:00Z,23.0,48.9,Building-B,Normal
Device001,2024-01-15T10:02:30Z,42.8,38.1,Building-A,Critical
"""
```

```kql
// Étape 4: Requêtes KQL de base

// Compter les événements par statut
SensorEvents
| summarize count() by Status
| render piechart

// Température moyenne par device sur la dernière heure
SensorEvents
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Temperature) by DeviceId
| order by AvgTemp desc

// Détecter les anomalies (température > 30°C)
SensorEvents
| where Temperature > 30
| project Timestamp, DeviceId, Temperature, Status
| order by Timestamp desc

// Agrégation par fenêtre de 5 minutes
SensorEvents
| summarize
    AvgTemp = avg(Temperature),
    MaxTemp = max(Temperature),
    EventCount = count()
    by bin(Timestamp, 5m)
| render timechart

// Alertes: Devices avec plus de 3 événements critiques
SensorEvents
| where Status == "Critical"
| summarize AlertCount = count() by DeviceId
| where AlertCount > 3
```

---

## Lab 5: CI/CD avec Git Integration

### Objectif
Configurer Git integration et deployment pipelines.

### Durée estimée
1 heure

### Instructions

```python
# Étape 1: Configurer Git Repository
"""
1. Créer un repo Azure DevOps ou GitHub
2. Dans Fabric workspace > Settings > Git integration
3. Connecter au repository
4. Sélectionner la branche (ex: main)
5. Définir le dossier racine
"""

# Étape 2: Vérifier la structure versionnée
git_structure = """
repository/
├── workspace-name/
│   ├── Notebook_Transform.Notebook/
│   │   └── notebook-content.py
│   ├── Pipeline_Daily.DataPipeline/
│   │   └── pipeline.json
│   ├── LH_Sales.Lakehouse/
│   │   └── lakehouse-metadata.json
│   └── SM_Analytics.SemanticModel/
│       └── model.bim
"""

# Étape 3: Créer un Deployment Pipeline
"""
1. Dans Fabric Admin > Deployment Pipelines
2. Créer nouveau pipeline: "PL_Sales_Deployment"
3. Assigner les workspaces:
   - Development: WS-Sales-Dev
   - Test: WS-Sales-Test
   - Production: WS-Sales-Prod
"""

# Étape 4: Configurer les règles de déploiement
deployment_rules = {
    "dataSourceRules": [
        {
            "sourceType": "Lakehouse",
            "sourceValue": "LH_Sales_Dev",
            "targetValue": "LH_Sales_Test",
            "applyToStage": "Test"
        },
        {
            "sourceType": "Lakehouse",
            "sourceValue": "LH_Sales_Test",
            "targetValue": "LH_Sales_Prod",
            "applyToStage": "Production"
        }
    ]
}
```

```powershell
# Étape 5: Automatiser avec PowerShell
$deployScript = @"
# Comparer les stages
$comparison = Compare-DeploymentPipelineStages -PipelineId $pipelineId -SourceStage 0 -TargetStage 1

# Déployer si des changements existent
if ($comparison.HasChanges) {
    Deploy-DeploymentPipeline -PipelineId $pipelineId -SourceStage 0 -TargetStage 1
    Write-Host "Deployment to Test completed"
}
"@
```

## Checklist de Validation

Après avoir complété les labs, vérifiez :

- [ ] Lakehouse créé avec Bronze/Silver/Gold
- [ ] Transformations PySpark fonctionnelles
- [ ] Time Travel testé sur Delta tables
- [ ] Data Warehouse avec SCD Type 2
- [ ] Semantic Model Direct Lake créé
- [ ] Mesures DAX calculant correctement
- [ ] RLS configuré et testé
- [ ] Base KQL avec requêtes fonctionnelles
- [ ] Git integration configuré
- [ ] Deployment pipeline opérationnel

## Points Clés

- Pratiquer chaque lab au moins une fois avant l'examen
- Comprendre les erreurs et comment les résoudre
- Documenter vos apprentissages
- Expérimenter avec des variations des exercices
- Chronométrer vos implémentations
- Tester les edge cases (données nulles, volumes)
- Valider les résultats à chaque étape

---

**Navigation** : [Précédent : Practice Questions](./03-practice-questions.md) | [Index](../README.md) | [Suivant : Key Concepts Review](./05-key-concepts-review.md)
