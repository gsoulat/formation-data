# Projet 6 : Migration Synapse vers Fabric

## Objectif
Planifier et exécuter une migration complète d'un environnement Azure Synapse Analytics vers Microsoft Fabric, incluant la validation des données et l'optimisation post-migration.

## Architecture
```
Source: Azure Synapse Analytics
├── Synapse SQL Pool (Dedicated)
├── Synapse Spark Pools
├── Synapse Pipelines
└── Linked Services

Target: Microsoft Fabric
├── Lakehouse (OneLake)
├── Warehouse
├── Notebooks (Spark)
├── Data Pipelines
└── Semantic Models
```

## Flux de Migration
```
Assessment → Planning → Data Migration → Code Migration → Testing → Cutover
     ↓           ↓            ↓              ↓            ↓         ↓
  Inventory   Timeline    ETL Scripts    Notebooks     Validation  Go-Live
  Complexity  Resources   Tables/Views   Pipelines     Performance Monitoring
  Dependencies Risk Plan  Incremental    Connections   Data Quality Rollback
```

## Compétences
- Migration assessment et planning
- Azure Synapse Analytics (SQL Pool, Spark)
- Fabric Lakehouse et Warehouse
- Data pipeline conversion
- Performance benchmarking
- Rollback strategies

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`retail_sales.csv`** (15 MB, 100K lignes) | Simule données du SQL Pool Synapse | → Migration table principale |
| **`customers.csv`** (1.6 MB, 10K clients) | Simule dimension clients Synapse | → Migration dimension |
| **`products.csv`** (63 KB, 500 produits) | Simule dimension produits Synapse | → Migration dimension |

### Simulation de l'Environnement Synapse

**Ce projet simule** une migration depuis :
- **Synapse SQL Pool** : Tables fact et dimensions (utilisez les CSV comme source)
- **Synapse Spark Notebooks** : Code PySpark (le template fourni est compatible)
- **Synapse Pipelines** : JSON pipelines (template fourni)

### Étapes avec les Données Fournies

1. **Assessment** : Analyser la structure des CSV comme si c'était Synapse
2. **Data Migration** : Charger les CSV dans Fabric Lakehouse (simule la migration)
3. **Validation** : Comparer row counts, checksums entre source et target
4. **Performance** : Benchmarker les requêtes sur les données migrées

### Exemple de Migration

```python
# SIMULATION: Charger depuis "Synapse" (fichier local)
synapse_sales = spark.read.csv("Files/synapse_export/retail_sales.csv", header=True)

# MIGRATION: Créer table Delta dans Fabric
synapse_sales.write.format("delta").mode("overwrite").saveAsTable("fabric_sales")

# VALIDATION: Vérifier intégrité
source_count = synapse_sales.count()
target_count = spark.table("fabric_sales").count()
assert source_count == target_count, f"Row count mismatch: {source_count} vs {target_count}"

print(f"✅ Migration validée: {target_count} lignes")
```

## Instructions

### Phase 1: Assessment et Inventory (3h)
1. Inventorier les assets Synapse:
```sql
-- Synapse SQL Pool: List all tables and sizes
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCount,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.type = 'U'
GROUP BY s.name, t.name, p.rows
ORDER BY TotalSpaceKB DESC;
```

2. Analyser les dépendances:
```sql
-- Find table dependencies (foreign keys, views)
SELECT
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    fk.name AS ForeignKeyName
FROM sys.foreign_keys fk;

-- List stored procedures and their dependencies
SELECT
    p.name AS ProcedureName,
    d.referenced_entity_name AS DependsOn,
    d.referenced_class_desc AS DependencyType
FROM sys.procedures p
CROSS APPLY sys.dm_sql_referenced_entities(SCHEMA_NAME(p.schema_id) + '.' + p.name, 'OBJECT') d;
```

3. Documenter les pipelines Synapse:
```python
# Export pipeline definitions
from azure.synapse.artifacts import ArtifactsClient

client = ArtifactsClient(
    endpoint="https://mysynapse.dev.azuresynapse.net",
    credential=DefaultAzureCredential()
)

pipelines = list(client.pipeline.get_pipelines_by_workspace())
pipeline_inventory = []

for pipeline in pipelines:
    details = client.pipeline.get_pipeline(pipeline.name)
    pipeline_inventory.append({
        "name": pipeline.name,
        "activities": len(details.activities),
        "parameters": list(details.parameters.keys()) if details.parameters else [],
        "triggers": get_pipeline_triggers(pipeline.name)
    })
```

4. Créer matrice de migration:
```
Migration Priority Matrix:
┌─────────────────┬──────────┬────────────┬──────────┐
│ Asset           │ Priority │ Complexity │ Risk     │
├─────────────────┼──────────┼────────────┼──────────┤
│ Sales_Fact      │ High     │ Medium     │ Low      │
│ Customer_Dim    │ High     │ Low        │ Low      │
│ ETL_Pipeline    │ High     │ High       │ Medium   │
│ ML_Training     │ Medium   │ High       │ High     │
│ Legacy_Reports  │ Low      │ Medium     │ Low      │
└─────────────────┴──────────┴────────────┴──────────┘
```

### Phase 2: Environment Setup (2h)
1. Provisionner Fabric workspace:
```python
# Create workspace via API
workspace_config = {
    "displayName": "Synapse_Migration_Workspace",
    "description": "Migrated from Azure Synapse Analytics",
    "capacityId": "capacity-guid"
}

# Create Lakehouse for raw migrated data
lakehouse_config = {
    "displayName": "Migrated_Data_Lake",
    "description": "Raw data migrated from Synapse SQL Pool"
}

# Create Warehouse for dimensional model
warehouse_config = {
    "displayName": "Migrated_DW",
    "description": "Dimensional model migrated from Synapse"
}
```

2. Configurer les connections:
```python
# OneLake shortcut to Azure Data Lake (if keeping source)
shortcut_config = {
    "path": "Files/synapse_backup",
    "target": {
        "adlsGen2": {
            "location": "https://synapsestore.dfs.core.windows.net",
            "subpath": "/synapse/backup"
        }
    }
}
```

3. Set up monitoring:
```python
# Migration monitoring table
migration_log_schema = """
CREATE TABLE migration.execution_log (
    migration_id STRING,
    source_system STRING,
    source_object STRING,
    target_object STRING,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status STRING,
    rows_migrated BIGINT,
    error_message STRING
)
"""
```

### Phase 3: Data Migration (4h)
1. Migration des tables dimension:
```python
# Generic table migration function
def migrate_table(source_table, target_table, batch_size=100000):
    """Migrate table from Synapse to Fabric Lakehouse"""

    migration_id = generate_migration_id()
    log_start(migration_id, source_table, target_table)

    try:
        # Read from Synapse SQL Pool
        synapse_jdbc = "jdbc:sqlserver://mysynapse.sql.azuresynapse.net:1433;database=SQLPool1"

        df = spark.read \
            .format("jdbc") \
            .option("url", synapse_jdbc) \
            .option("dbtable", source_table) \
            .option("user", dbutils.secrets.get("synapse", "username")) \
            .option("password", dbutils.secrets.get("synapse", "password")) \
            .option("fetchsize", batch_size) \
            .load()

        # Write to Fabric Lakehouse
        df.write \
            .format("delta") \
            .mode("overwrite") \
            .option("overwriteSchema", "true") \
            .saveAsTable(target_table)

        rows_migrated = df.count()
        log_success(migration_id, rows_migrated)

        return rows_migrated

    except Exception as e:
        log_error(migration_id, str(e))
        raise

# Migrate dimensions first (no dependencies)
dimensions = ["Dim_Customer", "Dim_Product", "Dim_Date", "Dim_Geography"]
for dim in dimensions:
    migrate_table(f"dbo.{dim}", f"lakehouse.{dim.lower()}")
```

2. Migration des tables de faits (incremental):
```python
def migrate_fact_table_incremental(source_table, target_table, watermark_column):
    """Incremental migration for large fact tables"""

    # Get last watermark
    last_watermark = get_last_watermark(target_table)

    if last_watermark is None:
        # Initial load
        query = f"(SELECT * FROM {source_table}) AS src"
    else:
        # Incremental load
        query = f"""
            (SELECT * FROM {source_table}
             WHERE {watermark_column} > '{last_watermark}') AS src
        """

    df = spark.read.jdbc(
        url=synapse_jdbc,
        table=query,
        properties=jdbc_properties
    )

    # Append to existing table
    df.write \
        .format("delta") \
        .mode("append") \
        .saveAsTable(target_table)

    # Update watermark
    new_watermark = df.agg({watermark_column: "max"}).collect()[0][0]
    update_watermark(target_table, new_watermark)

# Migrate facts incrementally
migrate_fact_table_incremental("dbo.Fact_Sales", "lakehouse.fact_sales", "ModifiedDate")
```

3. Migration vers Warehouse (pour requêtes SQL):
```sql
-- Recreate star schema in Fabric Warehouse
CREATE TABLE dbo.Dim_Customer (
    CustomerKey INT NOT NULL,
    CustomerID NVARCHAR(20),
    CustomerName NVARCHAR(100),
    Segment NVARCHAR(50),
    -- ... other columns matching source
    CONSTRAINT PK_DimCustomer PRIMARY KEY NONCLUSTERED (CustomerKey) NOT ENFORCED
);

-- Load from Lakehouse
INSERT INTO dbo.Dim_Customer
SELECT * FROM lakehouse.dim_customer;

-- Create fact table with constraints
CREATE TABLE dbo.Fact_Sales (
    SalesKey BIGINT IDENTITY(1,1),
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    Quantity INT,
    Amount DECIMAL(18,2),
    CONSTRAINT FK_FactSales_DimDate
        FOREIGN KEY (DateKey) REFERENCES dbo.Dim_Date(DateKey) NOT ENFORCED,
    CONSTRAINT FK_FactSales_DimCustomer
        FOREIGN KEY (CustomerKey) REFERENCES dbo.Dim_Customer(CustomerKey) NOT ENFORCED
);
```

### Phase 4: Code Migration (3h)
1. Convertir Synapse Spark notebooks:
```python
# BEFORE (Synapse Spark)
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("SynapseJob").getOrCreate()

# Read from ADLS Gen2
df = spark.read.parquet("abfss://container@storageaccount.dfs.core.windows.net/data/")

# Write to Synapse SQL Pool
df.write \
    .format("com.databricks.spark.sqldw") \
    .option("url", synapse_jdbc_url) \
    .option("tempDir", "abfss://temp@storage.dfs.core.windows.net/temp") \
    .option("forwardSparkAzureStorageCredentials", "true") \
    .option("dbTable", "dbo.OutputTable") \
    .mode("overwrite") \
    .save()

# AFTER (Fabric Spark)
# SparkSession already available
# Read from OneLake
df = spark.read.format("delta").load("Tables/source_data")
# OR
df = spark.table("lakehouse.source_data")

# Write to Lakehouse (native Delta)
df.write \
    .format("delta") \
    .mode("overwrite") \
    .saveAsTable("lakehouse.output_table")

# Key changes:
# 1. No explicit SparkSession creation needed
# 2. Use OneLake paths instead of ADLS
# 3. Native Delta Lake support
# 4. No Synapse SQL connector needed (use Warehouse directly)
```

2. Convertir Synapse Pipelines vers Fabric Data Pipelines:
```json
// BEFORE: Synapse Pipeline Activity
{
    "name": "Copy_Sales_Data",
    "type": "Copy",
    "inputs": [{
        "referenceName": "AzureSqlSource",
        "type": "DatasetReference"
    }],
    "outputs": [{
        "referenceName": "SynapseSqlPoolSink",
        "type": "DatasetReference"
    }],
    "typeProperties": {
        "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT * FROM Sales WHERE Date >= @pipeline().parameters.startDate"
        },
        "sink": {
            "type": "SqlDWSink",
            "allowPolyBase": true,
            "polyBaseSettings": {
                "rejectType": "value",
                "rejectValue": 0
            }
        }
    }
}

// AFTER: Fabric Data Pipeline Activity
{
    "name": "Copy_Sales_Data",
    "type": "Copy",
    "inputs": [{
        "referenceName": "AzureSqlSource",
        "type": "DatasetReference"
    }],
    "outputs": [{
        "referenceName": "FabricLakehouseSink",
        "type": "DatasetReference"  // Lakehouse table
    }],
    "typeProperties": {
        "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT * FROM Sales WHERE Date >= @pipeline().parameters.startDate"
        },
        "sink": {
            "type": "LakehouseTableSink",
            "tableActionOption": "Append"
        }
    }
}
```

3. Migrer les procédures stockées:
```sql
-- BEFORE: Synapse SQL Pool Stored Procedure
CREATE PROCEDURE dbo.UpdateSalesSummary
AS
BEGIN
    TRUNCATE TABLE dbo.SalesSummary;

    INSERT INTO dbo.SalesSummary
    SELECT
        d.Year,
        d.Month,
        SUM(f.Amount) as TotalSales,
        COUNT(*) as TransactionCount
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Date d ON f.DateKey = d.DateKey
    GROUP BY d.Year, d.Month;
END;

-- AFTER: Fabric Warehouse Stored Procedure
-- Same syntax, Fabric Warehouse supports T-SQL
CREATE PROCEDURE dbo.UpdateSalesSummary
AS
BEGIN
    -- Fabric Warehouse uses same T-SQL syntax
    DELETE FROM dbo.SalesSummary;  -- No TRUNCATE, use DELETE

    INSERT INTO dbo.SalesSummary
    SELECT
        d.Year,
        d.Month,
        SUM(f.Amount) as TotalSales,
        COUNT(*) as TransactionCount
    FROM dbo.Fact_Sales f
    JOIN dbo.Dim_Date d ON f.DateKey = d.DateKey
    GROUP BY d.Year, d.Month;
END;

-- Alternatively, use Spark notebook for complex transformations
-- Convert to PySpark for more flexibility
```

### Phase 5: Testing et Validation (3h)
1. Data validation - row counts:
```python
def validate_row_counts(source_target_mapping):
    """Compare row counts between source and target"""

    validation_results = []

    for source_table, target_table in source_target_mapping.items():
        # Count source (Synapse)
        source_count = spark.read.jdbc(
            synapse_jdbc,
            f"(SELECT COUNT(*) as cnt FROM {source_table}) t",
            properties=jdbc_properties
        ).collect()[0]['cnt']

        # Count target (Fabric)
        target_count = spark.table(target_table).count()

        match = source_count == target_count

        validation_results.append({
            "source": source_table,
            "target": target_table,
            "source_count": source_count,
            "target_count": target_count,
            "match": match,
            "difference": abs(source_count - target_count)
        })

    return pd.DataFrame(validation_results)

# Validate all migrated tables
mapping = {
    "dbo.Dim_Customer": "lakehouse.dim_customer",
    "dbo.Dim_Product": "lakehouse.dim_product",
    "dbo.Fact_Sales": "lakehouse.fact_sales"
}
validation_df = validate_row_counts(mapping)
print(validation_df)
```

2. Data validation - checksums:
```python
def validate_data_integrity(source_table, target_table, key_columns, value_columns):
    """Compare data checksums between source and target"""

    # Build checksum query
    value_cols_sql = ", ".join([f"CHECKSUM({col})" for col in value_columns])
    key_cols_sql = ", ".join(key_columns)

    # Source checksum (Synapse)
    source_query = f"""
        (SELECT {key_cols_sql},
                CHECKSUM({', '.join(value_columns)}) as row_checksum
         FROM {source_table}) AS src
    """
    source_df = spark.read.jdbc(synapse_jdbc, source_query, properties=jdbc_properties)

    # Target checksum (Fabric)
    target_df = spark.table(target_table).select(
        *key_columns,
        F.hash(*value_columns).alias("row_checksum")
    )

    # Compare
    mismatches = source_df.join(
        target_df,
        on=key_columns,
        how="full_outer"
    ).filter(
        F.col("src.row_checksum") != F.col("target.row_checksum")
    )

    return mismatches

# Validate data integrity
mismatches = validate_data_integrity(
    "dbo.Fact_Sales",
    "lakehouse.fact_sales",
    ["SalesKey"],
    ["Amount", "Quantity", "Discount"]
)
print(f"Mismatched rows: {mismatches.count()}")
```

3. Performance benchmarking:
```python
# Benchmark queries on both systems
benchmark_queries = [
    ("Total Sales by Year", """
        SELECT Year, SUM(Amount) as TotalSales
        FROM Fact_Sales f
        JOIN Dim_Date d ON f.DateKey = d.DateKey
        GROUP BY Year
    """),
    ("Top Customers", """
        SELECT TOP 100 CustomerName, SUM(Amount) as Revenue
        FROM Fact_Sales f
        JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
        GROUP BY CustomerName
        ORDER BY Revenue DESC
    """),
    ("Monthly Trend", """
        SELECT Year, Month, SUM(Amount), COUNT(*)
        FROM Fact_Sales f
        JOIN Dim_Date d ON f.DateKey = d.DateKey
        WHERE Year >= 2023
        GROUP BY Year, Month
        ORDER BY Year, Month
    """)
]

def benchmark_query(query_name, query, system="fabric"):
    """Measure query execution time"""
    import time

    start = time.time()
    if system == "synapse":
        spark.read.jdbc(synapse_jdbc, f"({query}) t", properties=jdbc_properties).collect()
    else:
        spark.sql(query).collect()
    end = time.time()

    return {"query": query_name, "system": system, "duration_seconds": end - start}

# Run benchmarks
results = []
for name, query in benchmark_queries:
    results.append(benchmark_query(name, query, "synapse"))
    results.append(benchmark_query(name, query, "fabric"))

benchmark_df = pd.DataFrame(results)
print(benchmark_df.pivot(index="query", columns="system", values="duration_seconds"))
```

### Phase 6: Cutover et Post-Migration (2h)
1. Plan de cutover:
```
Cutover Checklist:
□ Final data sync (incremental)
□ Disable Synapse pipelines
□ Update connection strings
□ Redirect reports to Fabric
□ Enable Fabric pipelines
□ Monitor for errors (24h)
□ User acceptance testing
□ Performance validation
□ Rollback plan ready
```

2. Monitoring post-migration:
```python
# Post-migration health check
def post_migration_health_check():
    checks = {
        "data_freshness": check_data_freshness(),
        "pipeline_success_rate": check_pipeline_success(),
        "query_performance": check_query_performance(),
        "error_rate": check_error_logs(),
        "user_adoption": check_user_activity()
    }

    # Alert on issues
    for check_name, result in checks.items():
        if not result["healthy"]:
            send_alert(f"Migration issue: {check_name}", result["details"])

    return checks

# Schedule daily health checks
post_migration_health_check()
```

3. Rollback procedure (if needed):
```python
# Rollback plan
def execute_rollback():
    """
    Rollback steps if migration fails:
    1. Stop Fabric pipelines
    2. Re-enable Synapse pipelines
    3. Revert connection strings
    4. Notify stakeholders
    5. Document issues encountered
    """

    # Stop Fabric pipelines
    disable_fabric_pipelines(workspace_id)

    # Re-enable Synapse
    enable_synapse_pipelines(synapse_workspace)

    # Revert report connections
    revert_report_connections()

    # Send notifications
    notify_stakeholders("Migration rollback executed", details)

    # Log for post-mortem
    log_rollback_event(timestamp, reason, affected_systems)
```

4. Documentation finale:
```
Migration Documentation:
├── Executive Summary
│   ├── Timeline
│   ├── Success metrics
│   └── Lessons learned
├── Technical Details
│   ├── Architecture comparison
│   ├── Code changes
│   └── Performance improvements
├── Operational Runbook
│   ├── New monitoring procedures
│   ├── Troubleshooting guide
│   └── Support escalation
└── User Training
    ├── New features in Fabric
    ├── Changed workflows
    └── FAQ
```

## Livrables
- [ ] Assessment complet (inventory, dependencies, complexity)
- [ ] Migration plan détaillé avec timeline
- [ ] Tous les tables migrées et validées
- [ ] Notebooks/Scripts convertis
- [ ] Pipelines migrées
- [ ] Tests de validation passés (counts, checksums)
- [ ] Performance benchmark (before/after)
- [ ] Cutover checklist complété
- [ ] Documentation post-migration
- [ ] Runbook opérationnel

## Critères d'évaluation
- Assessment thoroughness (20%)
- Data migration accuracy (30%)
- Code conversion quality (20%)
- Testing coverage (15%)
- Documentation completeness (15%)

## Métriques de succès
```
Data Integrity:
  ✓ 100% row count match
  ✓ 99.99% data accuracy (checksums)
  ✓ All foreign keys preserved

Performance:
  ✓ Query performance ≥ Synapse (or justified trade-offs)
  ✓ Pipeline execution time comparable
  ✓ No timeout errors

Operations:
  ✓ Zero data loss
  ✓ < 4 hour cutover window
  ✓ Successful rollback test
  ✓ All users trained
```

---

**Durée estimée: 14-18 heures**

**Note:** Ce projet simule un scénario de migration réel. Dans un environnement de production, prévoir des ressources supplémentaires pour la coordination avec les équipes business, les tests utilisateurs, et la gestion du changement.

[⬅️ Retour aux projets](../README.md)
