# Module 02 - Lakehouse

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre le concept de Lakehouse et son positionnement
- ✅ Créer et gérer des Lakehouses dans Fabric
- ✅ Travailler avec Delta Lake et tables optimisées
- ✅ Utiliser les shortcuts pour virtualiser des données
- ✅ Implémenter une architecture Medallion (Bronze/Silver/Gold)
- ✅ Optimiser les tables avec partitionnement et V-Order
- ✅ Utiliser le time travel et le versioning

## Contenu du module

### [01 - Concepts Lakehouse](./01-concepts-lakehouse.md)
- Qu'est-ce qu'un Lakehouse ?
- Lakehouse vs Data Lake vs Data Warehouse
- Avantages du pattern Lakehouse
- Architecture lambda vs kappa
- Use cases typiques

### [02 - Delta Lake et Tables](./02-delta-lake-tables.md)
- Introduction à Delta Lake
- Format Delta (transaction log, parquet files)
- Types de tables : managed vs external
- ACID transactions dans Fabric
- Schema enforcement et evolution
- Operations CRUD sur tables Delta

### [03 - OneLake Storage](./03-onelake-storage.md)
- Organisation du stockage dans OneLake
- Dossiers `Files` vs `Tables`
- Formats supportés (parquet, CSV, JSON, Delta)
- Accès via ADLS API
- Intégration avec Azure Storage Explorer
- Sécurité et permissions

### [04 - Shortcuts](./04-shortcuts.md)
- Concept de shortcut (virtualisation de données)
- Types de shortcuts : OneLake, S3, ADLS Gen2, Dataverse
- Création de shortcuts via UI et API
- Use cases : fédération de données, data mesh
- Limitations et bonnes pratiques

### [05 - Architecture Medallion](./05-schemas-medallion-architecture.md)
- Pattern Medallion (Bronze/Silver/Gold)
- **Bronze** : Raw data (données brutes)
- **Silver** : Cleaned & validated data
- **Gold** : Business-level aggregates
- Implémentation dans Lakehouse
- Naming conventions
- Data lineage entre couches

### [06 - Partitionnement et Optimisation](./06-partitioning-optimization.md)
- Stratégies de partitionnement
- Partitionnement par date, région, catégorie
- V-Order optimization (compression columnaire)
- OPTIMIZE et VACUUM commands
- Z-Ordering
- Statistiques et indexes

### [07 - Time Travel et Versioning](./07-time-travel-versioning.md)
- Historique des versions Delta
- Requêtes time travel (VERSION AS OF, TIMESTAMP AS OF)
- DESCRIBE HISTORY
- Restauration de versions précédentes
- Rétention et nettoyage (VACUUM)
- Gestion des snapshots

## Exercices pratiques

### Exercice 1 : Création de Lakehouse
1. Créer un nouveau Lakehouse
2. Uploader des fichiers CSV dans `Files`
3. Convertir en tables Delta dans `Tables`
4. Explorer la structure dans OneLake

### Exercice 2 : Ingestion de données
1. Importer des données depuis Azure Blob Storage
2. Créer une table Delta managed
3. Valider les transactions ACID
4. Inspecter le transaction log

### Exercice 3 : Architecture Medallion
1. Créer 3 Lakehouses (Bronze, Silver, Gold)
2. Charger des données raw dans Bronze
3. Nettoyer et transformer vers Silver
4. Agréger et calculer des métriques dans Gold

### Exercice 4 : Shortcuts
1. Créer un shortcut vers ADLS Gen2
2. Accéder aux données sans copie
3. Créer un shortcut OneLake entre lakehouses
4. Tester les performances

### Exercice 5 : Optimisation
1. Créer une table partitionnée par date
2. Appliquer V-Order optimization
3. Comparer les performances avant/après
4. Exécuter OPTIMIZE et VACUUM

### Exercice 6 : Time Travel
1. Effectuer plusieurs modifications sur une table
2. Visualiser l'historique avec DESCRIBE HISTORY
3. Requêter une version spécifique
4. Restaurer une version précédente

## Quiz

1. Quelle est la différence principale entre un Lakehouse et un Data Warehouse ?
2. Qu'est-ce que Delta Lake apporte par rapport au Parquet simple ?
3. Expliquez le concept de shortcut dans Fabric
4. Décrivez l'architecture Medallion et ses 3 couches
5. À quoi sert V-Order optimization ?
6. Comment requêter une table Delta à une date précise ?

## Exemples de code

### Créer une table Delta
```sql
CREATE TABLE sales_bronze (
    order_id STRING,
    customer_id STRING,
    amount DECIMAL(10,2),
    order_date DATE
)
USING DELTA
PARTITIONED BY (order_date);
```

### Time travel
```sql
-- Version spécifique
SELECT * FROM sales_bronze VERSION AS OF 5;

-- Timestamp
SELECT * FROM sales_bronze TIMESTAMP AS OF '2025-01-01 12:00:00';

-- Historique
DESCRIBE HISTORY sales_bronze;
```

### Optimization
```python
# PySpark
from delta.tables import DeltaTable

# Optimize
spark.sql("OPTIMIZE sales_bronze")

# Vacuum (supprime les fichiers de plus de 7 jours)
spark.sql("VACUUM sales_bronze RETAIN 168 HOURS")
```

## Ressources complémentaires

### Documentation officielle
- [Lakehouse in Fabric](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)
- [Delta Lake documentation](https://docs.delta.io/)
- [OneLake shortcuts](https://learn.microsoft.com/fabric/onelake/onelake-shortcuts)

### Patterns architecturaux
- [Medallion Architecture](https://learn.microsoft.com/azure/databricks/lakehouse/medallion)
- [Data Lake best practices](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-best-practices)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 3-4 heures
- **Total** : 7-9 heures

## Prochaine étape

➡️ [Module 03 - Data Warehouse](../03-Data-Warehouse/)

---

[⬅️ Module précédent](../01-Introduction-Fabric/) | [⬅️ Retour au sommaire](../README.md)
