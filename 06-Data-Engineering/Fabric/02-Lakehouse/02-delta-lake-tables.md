# Delta Lake et Tables

## Introduction à Delta Lake

**Delta Lake** est un layer de stockage open-source qui apporte la fiabilité aux Data Lakes.

### Architecture Delta

```
Delta Table = Parquet Files + Transaction Log

┌─────────────────────────────────────┐
│     Delta Table: customers          │
├─────────────────────────────────────┤
│  _delta_log/                        │
│    ├── 00000000000000000000.json    │ ← Transactions
│    ├── 00000000000000000001.json    │
│    └── 00000000000000000002.json    │
├─────────────────────────────────────┤
│  part-00000-*.parquet               │ ← Data files
│  part-00001-*.parquet               │
│  part-00002-*.parquet               │
└─────────────────────────────────────┘
```

## Format Delta Lake

### Transaction Log

Le `_delta_log` enregistre toutes les opérations :

**Exemple de transaction log :**
```json
{
  "commitInfo": {
    "timestamp": 1699876543210,
    "operation": "WRITE",
    "operationMetrics": {
      "numFiles": "3",
      "numOutputRows": "1000"
    }
  },
  "add": {
    "path": "part-00000-abc123.parquet",
    "size": 12345678,
    "modificationTime": 1699876543210,
    "dataChange": true,
    "stats": "{\"numRecords\":1000,\"minValues\":{\"id\":1},\"maxValues\":{\"id\":1000}}"
  }
}
```

### Parquet Files

Delta utilise Parquet pour le stockage physique des données :
- Format columnaire (optimal pour analytics)
- Compression efficace
- Schema embedded

## ACID Transactions

Delta Lake garantit les propriétés ACID :

### Atomicity (Atomicité)
```python
# Tout ou rien
df.write.format("delta").mode("append").save("Tables/sales")
# Si erreur → Aucune donnée écrite
# Si succès → Toutes les données écrites
```

### Consistency (Cohérence)
```python
# Schema enforcement
df_wrong_schema.write.format("delta").mode("append").save("Tables/sales")
# → Erreur si schéma incompatible
```

### Isolation
```python
# Transaction A et B simultanées
# Chacune voit une version cohérente
# Pas d'interférence
```

### Durability (Durabilité)
```
Une fois committed, les données persistent
Même en cas de crash
```

## Types de Tables Delta

### 1. Managed Tables

```python
# Table gérée par Fabric
df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("sales")

# Données ET métadonnées gérées
# DROP TABLE = supprime données + métadonnées
```

**Localisation :**
```
Tables/sales/
  ├── _delta_log/
  └── *.parquet
```

### 2. External Tables

```python
# Données externes, métadonnées gérées
df.write.format("delta") \
    .mode("overwrite") \
    .save("Files/external/sales")

spark.sql("""
    CREATE TABLE sales_external
    USING DELTA
    LOCATION 'Files/external/sales'
""")

# DROP TABLE = supprime métadonnées seulement
# Données persistent
```

## Opérations CRUD

### Create (INSERT)

```python
# Append
df.write.format("delta") \
    .mode("append") \
    .saveAsTable("sales")

# SQL
spark.sql("""
    INSERT INTO sales
    VALUES (1, 'Product A', 100.0, '2024-01-01')
""")
```

### Read (SELECT)

```python
# PySpark
df = spark.read.format("delta").load("Tables/sales")
df = spark.table("sales")

# SQL
result = spark.sql("SELECT * FROM sales WHERE amount > 100")
```

### Update

```python
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "Tables/sales")

delta_table.update(
    condition = "product_id = 123",
    set = {"price": "price * 1.1"}  # +10% increase
)

# SQL
spark.sql("""
    UPDATE sales
    SET price = price * 1.1
    WHERE product_id = 123
""")
```

### Delete

```python
delta_table.delete("order_date < '2023-01-01'")

# SQL
spark.sql("DELETE FROM sales WHERE order_date < '2023-01-01'")
```

### MERGE (Upsert)

```python
delta_table.alias("target").merge(
    updates_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(set = {
    "amount": "source.amount",
    "updated_at": "current_timestamp()"
}).whenNotMatchedInsert(values = {
    "id": "source.id",
    "amount": "source.amount",
    "created_at": "current_timestamp()"
}).execute()

# SQL
spark.sql("""
    MERGE INTO sales AS target
    USING updates AS source
    ON target.id = source.id
    WHEN MATCHED THEN
        UPDATE SET amount = source.amount
    WHEN NOT MATCHED THEN
        INSERT (id, amount) VALUES (source.id, source.amount)
""")
```

## Schema Management

### Schema Enforcement

```python
# Schéma défini
schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("amount", DoubleType(), True)
])

df = spark.createDataFrame(data, schema)
df.write.format("delta").mode("overwrite").saveAsTable("products")

# Tentative d'ajout avec schéma incompatible
bad_df.write.format("delta").mode("append").saveAsTable("products")
# → AnalysisException: Schema mismatch
```

### Schema Evolution

```python
# Autoriser l'ajout de colonnes
df_with_new_column.write.format("delta") \
    .mode("append") \
    .option("mergeSchema", "true") \
    .saveAsTable("products")

# Anciennes données auront NULL pour nouvelle colonne
```

### Overwrite Schema

```python
# Remplacer complètement le schéma
df_new_schema.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("products")
```

## Statistiques et Optimisation

### Data Skipping

Delta collecte automatiquement des statistiques :

```python
# Delta stocke min/max par fichier
# Permet de skip les fichiers inutiles

# Query
df = spark.table("sales").where("order_date = '2024-01-15'")

# Delta skips tous les fichiers qui ne contiennent pas cette date
# Performance boost massive!
```

### Z-Ordering

```python
# Organiser données par colonnes fréquemment filtrées
spark.sql("OPTIMIZE sales ZORDER BY (customer_id, product_id)")

# Améliore data skipping
# Meilleure performance pour queries sur ces colonnes
```

## Contraintes

### NOT NULL

```python
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "Tables/customers")

# Ajouter contrainte
delta_table.alter().addConstraint("id_not_null", "id IS NOT NULL").execute()

# Tentative d'insertion avec NULL
# → Erreur
```

### CHECK Constraints

```python
# Contrainte de validation
delta_table.alter().addConstraint(
    "valid_amount",
    "amount >= 0"
).execute()

# Insertion avec amount négatif → Erreur
```

## Concurrent Operations

Delta Lake gère la concurrence :

```python
# Reader A lit version N
reader_df = spark.table("sales")

# Writer B écrit version N+1
writer_df.write.format("delta").mode("append").saveAsTable("sales")

# Reader A continue avec version N (isolation)
# Reader C voit version N+1 (nouvelle lecture)
```

**Optimistic Concurrency Control :**
- Multiple readers : OK
- Multiple writers : Retry avec exponential backoff

## Commandes Utiles

### DESCRIBE

```python
# Voir le schéma
spark.sql("DESCRIBE sales").show()

# Détails de la table
spark.sql("DESCRIBE DETAIL sales").show()
# → Location, format, nombre de fichiers, taille, etc.

# Historique
spark.sql("DESCRIBE HISTORY sales").show()
```

### SHOW

```python
# Lister tables
spark.sql("SHOW TABLES").show()

# Colonnes
spark.sql("SHOW COLUMNS IN sales").show()
```

## Points Clés

- Delta Lake = Parquet + Transaction Log
- ACID transactions garanties
- Schema enforcement & evolution
- CRUD complet (INSERT, UPDATE, DELETE, MERGE)
- Data skipping automatique
- Concurrent operations gérées
- Contraintes et validations possibles

---

**Prochain fichier :** [03 - OneLake Storage](./03-onelake-storage.md)

[⬅️ Fichier précédent](./01-concepts-lakehouse.md) | [⬅️ Retour au README du module](./README.md)
