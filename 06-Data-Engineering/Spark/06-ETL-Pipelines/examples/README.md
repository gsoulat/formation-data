# Exemples ETL Pipelines

Un exemple complet de pipeline ETL (Extract, Transform, Load) avec Spark.

## Fichier

### complete_etl_pipeline.py
Pipeline ETL complet pour e-commerce :
- **Extract** : Lire CSV, JSON, Parquet
- **Transform** : Nettoyer, valider, enrichir (joins), agréger
- **Load** : Écrire en Parquet partitionné + exports

## Exécution

```bash
cd 06-ETL-Pipelines/examples
python complete_etl_pipeline.py
```

## Ce que fait le pipeline

### 1. Extract (Lecture)
- Orders depuis CSV (avec schema explicite)
- Customers depuis JSON
- Products depuis Parquet

### 2. Transform (Transformation)
- Nettoyer les données (supprimer nulls, valider)
- Enrichir avec joins (customers + products)
- Calculer des métriques (total_amount)
- Ajouter métadonnées (processed_at, year, month)
- Créer agrégations (daily sales, customer stats, product stats)

### 3. Load (Écriture)
- Orders enrichis → Parquet partitionné (year/month)
- Agrégations → Parquet
- Export → CSV pour BI tools

### 4. Validation
- Relecture des données
- Rapport de statistiques
- Validation des counts

## Structure de sortie

```
output/
├── orders_enriched/
│   ├── year=2024/
│   │   └── month=1/
│   │       └── part-*.parquet
├── daily_category_sales/
│   └── part-*.parquet
├── customer_stats/
│   └── part-*.parquet
├── product_stats/
│   └── part-*.parquet
└── daily_sales_export.csv/
    └── part-*.csv
```

## Concepts clés

### Schema explicite vs inféré

```python
# ❌ Lent (scan complet)
df = spark.read.csv("data.csv", inferSchema=True)

# ✅ Rapide (schema prédéfini)
schema = StructType([...])
df = spark.read.csv("data.csv", schema=schema)
```

### Partitionnement

```python
# Écrire avec partitions
df.write.partitionBy("year", "month").parquet("output/")

# Crée: output/year=2024/month=01/part-*.parquet
#       output/year=2024/month=02/part-*.parquet
```

**Avantages** :
- Lecture plus rapide (skip des partitions non nécessaires)
- Organisé chronologiquement
- Facilite les suppressions (DROP partition)

### Formats de fichiers

| Format | Quand utiliser |
|--------|----------------|
| **Parquet** | Analytics, Data Lake (recommandé) |
| **CSV** | Échange simple, compatibilité |
| **JSON** | Données hiérarchiques, APIs |
| **Avro** | Streaming, schema evolution |

### Modes d'écriture

```python
df.write.mode("overwrite")  # Écrase
df.write.mode("append")     # Ajoute
df.write.mode("ignore")     # Ignore si existe
df.write.mode("error")      # Erreur si existe (défaut)
```

## Pipeline ETL typique

```
Sources              Transform              Destination
-------              ---------              -----------
CSV files    →       Clean         →       Parquet
JSON files   →       Validate      →       Delta Lake
Databases    →       Enrich        →       Data Warehouse
APIs         →       Aggregate     →       BI Tools
```

## Bonnes pratiques

### 1. Schema explicite
Définissez toujours le schema pour de meilleures performances et validation.

### 2. Partitionnement intelligent
- Partitionner par colonnes fréquemment filtrées (date, région)
- Taille partition idéale : 128 MB - 1 GB
- Éviter trop de partitions (< 1000 partitions)

### 3. Format Parquet
Utilisez Parquet pour le stockage final :
- Compression efficace
- Columnar (rapide pour analytics)
- Schema inclus

### 4. Validation
Validez à chaque étape :
```python
assert df.count() > 0, "DataFrame vide"
assert "id" in df.columns, "Colonne manquante"
```

### 5. Gestion des erreurs
```python
try:
    df = spark.read.csv("data.csv", schema=schema)
except Exception as e:
    logging.error(f"Erreur: {e}")
    # Fallback ou alerte
```

### 6. Logging et monitoring
```python
print(f"Lignes lues: {df.count()}")
print(f"Lignes après nettoyage: {df_clean.count()}")
print(f"Lignes rejetées: {df.count() - df_clean.count()}")
```

## Optimisations

### Cache pour réutilisation
```python
df_clean = df.filter(...).cache()

# Multiples utilisations
stats1 = df_clean.groupBy(...).count()
stats2 = df_clean.agg(...)
```

### Broadcast pour petites tables
```python
from pyspark.sql.functions import broadcast

# Broadcast la petite table
df_large.join(broadcast(df_small), "id")
```

### Repartition pour équilibrage
```python
# Repartitionner avant un gros traitement
df = df.repartition(100)
```

## Extensions possibles

Pour aller plus loin :

1. **Incremental loading**
   ```python
   # Lire seulement les nouveaux fichiers
   df = spark.read.parquet("data/year=2024/month=*/day=*")
   ```

2. **Data quality checks**
   ```python
   # Vérifier la qualité
   null_counts = df.select([sum(col(c).isNull().cast("int")).alias(c) for c in df.columns])
   ```

3. **Upsert (merge)**
   ```python
   # Avec Delta Lake
   deltaTable.merge(updates, "id").whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
   ```

4. **Scheduler**
   - Airflow pour orchestration
   - Cron jobs
   - Databricks Jobs

## Ressources

- [Spark I/O Guide](https://spark.apache.org/docs/latest/sql-data-sources.html)
- [Parquet Format](https://parquet.apache.org/)
- Module précédent : [05-Spark-SQL](../../05-Spark-SQL/README.md)
- Module suivant : [07-Performance-Optimization](../../07-Performance-Optimization/README.md)
