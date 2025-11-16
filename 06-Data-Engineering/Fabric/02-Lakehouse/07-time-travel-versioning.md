# Time Travel et Versioning

## Concept

Delta Lake maintient un **historique complet** des modifications grâce au transaction log, permettant de "voyager dans le temps" pour accéder aux versions précédentes.

```
Version 0: Table créée (100 rows)
   ↓
Version 1: + 50 rows appended
   ↓
Version 2: Updated 10 rows
   ↓
Version 3: Deleted 5 rows
   ↓
Version 4 (current): + 30 rows appended
```

## Transaction Log

### Structure

```
my_table/
├── _delta_log/
│   ├── 00000000000000000000.json  ← Version 0
│   ├── 00000000000000000001.json  ← Version 1
│   ├── 00000000000000000002.json  ← Version 2
│   └── 00000000000000000003.json  ← Version 3 (current)
└── *.parquet (data files)
```

### Contenu Transaction Log

```json
{
  "commitInfo": {
    "timestamp": 1699876543000,
    "operation": "WRITE",
    "operationParameters": {
      "mode": "Append",
      "partitionBy": "[\"year\",\"month\"]"
    },
    "operationMetrics": {
      "numFiles": "10",
      "numOutputRows": "50000"
    }
  },
  "add": {
    "path": "year=2024/month=01/part-00000.parquet",
    "size": 12345678,
    "modificationTime": 1699876543000
  }
}
```

## Requêter des Versions Historiques

### Par Numéro de Version

```python
# Version actuelle
df_current = spark.table("my_table")

# Version 5
df_v5 = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("Tables/my_table")

# SQL
df_v5 = spark.sql("SELECT * FROM my_table VERSION AS OF 5")
```

### Par Timestamp

```python
# État au 15 janvier 2024 à 10h
df_date = spark.read.format("delta") \
    .option("timestampAsOf", "2024-01-15 10:00:00") \
    .load("Tables/my_table")

# SQL
df_date = spark.sql("""
    SELECT * FROM my_table
    TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

### DESCRIBE HISTORY

```python
# Voir tout l'historique
history = spark.sql("DESCRIBE HISTORY my_table")
history.show(truncate=False)
```

**Résultat :**
```
+-------+-------------------+-----------+-------+
|version|timestamp          |operation  |userId |
+-------+-------------------+-----------+-------+
|4      |2024-01-15 14:30:00|WRITE      |user@x |
|3      |2024-01-15 12:00:00|DELETE     |user@x |
|2      |2024-01-15 10:00:00|UPDATE     |user@x |
|1      |2024-01-15 08:00:00|WRITE      |user@x |
|0      |2024-01-15 06:00:00|CREATE     |user@x |
+-------+-------------------+-----------+-------+
```

### Filtrer l'Historique

```python
# Seulement les 10 dernières versions
history.limit(10).show()

# Seulement les DELETES
history.where("operation = 'DELETE'").show()

# Dans une période
history.where(
    "timestamp BETWEEN '2024-01-01' AND '2024-01-31'"
).show()
```

## Use Cases Time Travel

### 1. Audit et Compliance

```python
# "Montrez-moi les données au moment du rapport trimestriel"
q1_report_date = "2024-03-31 23:59:59"

df_q1 = spark.sql(f"""
    SELECT * FROM sales
    TIMESTAMP AS OF '{q1_report_date}'
""")

# Garantit reproductibilité des rapports
```

### 2. Rollback après Erreur

```python
# Oops, mauvais DELETE!
spark.sql("DELETE FROM customers WHERE country = 'FR'")  # Erreur!

# Voir l'historique
spark.sql("DESCRIBE HISTORY customers").show()

# Version avant DELETE = version 10
# Version après DELETE = version 11

# Restaurer version 10
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "Tables/customers")
delta_table.restoreToVersion(10)

# Données restaurées! ✅
```

### 3. Analyse de Changements

```python
# Quoi a changé entre version 5 et 10?
v5 = spark.sql("SELECT * FROM my_table VERSION AS OF 5")
v10 = spark.sql("SELECT * FROM my_table VERSION AS OF 10")

# Rows ajoutées
added = v10.exceptAll(v5)
print(f"Added rows: {added.count()}")

# Rows supprimées
deleted = v5.exceptAll(v10)
print(f"Deleted rows: {deleted.count()}")
```

### 4. Debugging

```python
# "Les données étaient correctes hier, mais pas aujourd'hui"
yesterday = spark.sql("""
    SELECT * FROM my_table
    TIMESTAMP AS OF (current_timestamp() - INTERVAL 1 DAY)
""")

today = spark.table("my_table")

# Comparer
diff = today.exceptAll(yesterday)
diff.show()  # Voir ce qui a changé
```

### 5. Data Science Experiments

```python
# Expérience ML reproduisible
training_date = "2024-01-15"

# Dataset identique pour tous les chercheurs
train_df = spark.sql(f"""
    SELECT * FROM features
    TIMESTAMP AS OF '{training_date}'
""")

# Entraîner modèle
model = train_model(train_df)

# Résultats reproductibles car dataset identique
```

## Restauration

### Restore to Version

```python
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "Tables/my_table")

# Restaurer à version 5
delta_table.restoreToVersion(5)

# Nouvelle version créée (not destructive!)
# Version 11 = état de version 5
```

### Restore to Timestamp

```python
# Restaurer à une date
delta_table.restoreToTimestamp("2024-01-15 10:00:00")
```

### SQL Syntax

```sql
RESTORE TABLE my_table TO VERSION AS OF 5;

RESTORE TABLE my_table TO TIMESTAMP AS OF '2024-01-15';
```

## Retention et VACUUM

### Retention Period

```python
# Par défaut: 30 jours de time travel

# Après VACUUM, versions anciennes supprimées
spark.sql("VACUUM my_table RETAIN 168 HOURS")  # 7 jours

# Time travel disponible seulement sur les 7 derniers jours
```

### Configuration Retention

```python
# Augmenter retention pour compliance
spark.sql("""
    ALTER TABLE my_table
    SET TBLPROPERTIES (
        'delta.logRetentionDuration' = '90 days',
        'delta.deletedFileRetentionDuration' = '90 days'
    )
""")

# VACUUM respecte cette config
spark.sql("VACUUM my_table")  # Garde 90 jours
```

### Danger: VACUUM trop Agressif

```python
# ❌ DANGER: Casse time travel!
spark.sql("VACUUM my_table RETAIN 0 HOURS")

# ✅ Plus de time travel possible!
# Fichiers supprimés immédiatement
# NE JAMAIS faire en production
```

## Change Data Feed

### Activer CDC

```python
# Activer change data capture
spark.sql("""
    ALTER TABLE my_table
    SET TBLPROPERTIES (delta.enableChangeDataFeed = true)
""")
```

### Lire les Changes

```python
# Changes entre version 5 et 10
changes = spark.read.format("delta") \
    .option("readChangeDataFeed", "true") \
    .option("startingVersion", 5) \
    .option("endingVersion", 10) \
    .table("my_table")

changes.show()
```

**Colonnes supplémentaires :**
```
_change_type: insert, update_preimage, update_postimage, delete
_commit_version: numéro de version
_commit_timestamp: timestamp
```

### Use Cases CDC

1. **Incremental Processing**
```python
# Traiter seulement les changements
last_processed_version = get_last_processed()
changes = read_changes_since(last_processed_version)
process_incremental(changes)
```

2. **Auditing**
```python
# Log toutes modifications
audit_log = changes.where("_change_type = 'delete'")
audit_log.write.saveAsTable("audit_deletes")
```

3. **Downstream Updates**
```python
# Propager changements à autre système
for change in changes.collect():
    if change._change_type == "insert":
        insert_to_downstream(change)
    elif change._change_type == "delete":
        delete_from_downstream(change)
```

## Versioning Best Practices

### Documentation

```python
# Ajouter metadata aux commits
spark.sql("""
    INSERT INTO my_table
    SELECT * FROM source
""").option("userMetadata", "Daily batch load 2024-01-15")
```

### Tagging Versions

```python
# "Tag" une version importante
important_version = get_current_version()
save_version_tag("Q1_2024_snapshot", important_version)

# Restaurer plus tard
restore_to_tag("Q1_2024_snapshot")
```

### Monitoring

```python
# Nombre de versions
version_count = spark.sql("DESCRIBE HISTORY my_table").count()

# Taille du transaction log
log_size = get_delta_log_size("Tables/my_table/_delta_log")

# Alert si log trop grand
if version_count > 10000:
    print("WARNING: Many versions, consider VACUUM")
```

## Limitations

### Storage Cost

```
Chaque version garde références aux fichiers
Time travel = storage cost
Exemple:
  - Version 1: 100 GB
  - Version 2: +50 GB
  - Version 3: +50 GB
  Total storage: 200 GB (pour garder tout l'historique)
```

### Performance

```python
# Version très ancienne = peut être lent
df = spark.sql("SELECT * FROM my_table VERSION AS OF 0")

# Raison: Doit rejouer beaucoup de transactions
# Solution: Periodic OPTIMIZE + VACUUM
```

## Points Clés

- Time travel via VERSION AS OF ou TIMESTAMP AS OF
- DESCRIBE HISTORY pour voir l'historique
- Restore pour rollback
- VACUUM supprime anciennes versions (attention!)
- Change Data Feed pour CDC
- Retention configurable (défaut 30 jours)
- Storage cost à considérer
- Essentiel pour audit, debugging, reproducibilité

---

**Module 02 COMPLET** ✅

[⬅️ Fichier précédent](./06-partitioning-optimization.md) | [➡️ Module suivant : Data Warehouse](../../03-Data-Warehouse/) | [⬅️ Retour au README du module](./README.md)
