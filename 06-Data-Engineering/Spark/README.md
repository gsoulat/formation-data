# Formation Apache Spark

Bienvenue dans le cours complet sur Apache Spark, le moteur de traitement de données distribué le plus populaire pour le Big Data.

## Vue d'ensemble

Apache Spark est un framework de traitement de données distribué open-source, conçu pour la rapidité, la facilité d'utilisation et l'analyse sophistiquée. Ce cours couvre tous les aspects de Spark, de l'installation aux déploiements en production.

## Qu'est-ce qu'Apache Spark ?

Spark est un moteur d'analyse unifié pour le traitement de données à grande échelle, offrant :
- **Vitesse** : Jusqu'à 100x plus rapide que Hadoop MapReduce
- **Simplicité** : APIs en Python, Scala, Java, R, SQL
- **Généralité** : Batch, streaming, SQL, ML, graph processing
- **Évolutivité** : De votre laptop à des clusters de milliers de machines

## Structure du cours

### [01-Introduction](./01-Introduction/README.md) 🎯
**Découvrir Apache Spark**

- Qu'est-ce que Spark ?
- Architecture de Spark (Driver, Executors, Cluster Manager)
- Comparaison avec Hadoop MapReduce
- Cas d'usage et écosystème
- Concepts clés (RDD, DataFrame, Dataset)

**Durée estimée :** 1 jour

### [02-Installation-Setup](./02-Installation-Setup/README.md) ⚙️
**Installer et configurer Spark**

- Installation locale (standalone)
- Docker et Docker Compose
- Configuration Spark
- Databricks Community Edition
- Jupyter Notebook avec PySpark

**Durée estimée :** 1 jour

### [03-RDD-Basics](./03-RDD-Basics/README.md) 📦
**Resilient Distributed Datasets**

- Création de RDDs
- Transformations (map, filter, flatMap, etc.)
- Actions (collect, count, reduce, etc.)
- Lazy evaluation
- Partitionnement

**Exemples inclus :**
- `rdd_creation.py` - Créer des RDDs
- `rdd_transformations.py` - Transformations courantes
- `rdd_actions.py` - Actions et collect

**Durée estimée :** 2 jours

### [04-DataFrames-API](./04-DataFrames-API/README.md) 📊
**DataFrame API - Abstraction haut niveau**

- Création de DataFrames
- Opérations sur colonnes
- Filtrage et sélection
- Agrégations et groupBy
- Joins
- Schema et types

**Exemples inclus :**
- `dataframe_basics.py` - Opérations de base
- `dataframe_operations.py` - Transformations avancées
- `spark_sql.py` - Requêtes SQL

**Durée estimée :** 3 jours

### [05-Spark-SQL](./05-Spark-SQL/README.md) 🔍
**SQL sur données distribuées**

- Spark SQL et Catalog
- Temporary Views et Tables
- Window Functions
- User Defined Functions (UDF)
- Optimisation de requêtes (Catalyst)

**Exemples inclus :**
- `sql_queries.py` - Requêtes SQL avancées
- `window_functions.py` - Fonctions de fenêtrage
- `udf_functions.py` - UDFs personnalisées

**Durée estimée :** 2 jours

### [06-ETL-Pipelines](./06-ETL-Pipelines/README.md) 🔄
**Extract, Transform, Load avec Spark**

- Lecture de données (CSV, JSON, Parquet, Avro)
- Transformations de données
- Écriture de données (formats et modes)
- Gestion de schémas
- Pipeline ETL complet

**Exemples inclus :**
- `read_csv_parquet.py` - Lecture de différents formats
- `data_transformation.py` - Nettoyage et transformation
- `write_formats.py` - Écriture dans différents formats
- `complete_etl_pipeline.py` - Pipeline ETL de bout en bout

**Durée estimée :** 3 jours

### [07-Performance-Optimization](./07-Performance-Optimization/README.md) ⚡
**Optimiser les performances Spark**

- Partitionnement et repartitionnement
- Caching et persistence
- Broadcast variables
- Accumulateurs
- Tuning de la configuration Spark
- Éviter les shuffles coûteux

**Exemples inclus :**
- `partitioning.py` - Stratégies de partitionnement
- `caching_persistence.py` - Cache et persistence
- `broadcast_joins.py` - Optimisation des joins

**Durée estimée :** 2 jours

### [08-Spark-Streaming](./08-Spark-Streaming/README.md) 📡
**Traitement de données en temps réel**

- Structured Streaming
- Sources et Sinks
- Windowing et watermarks
- Stateful operations
- Intégration Kafka

**Exemples inclus :**
- `streaming_basics.py` - Premiers pas en streaming
- `kafka_integration.py` - Consommer depuis Kafka
- `windowing.py` - Fenêtres temporelles

**Durée estimée :** 3 jours

### [09-Advanced-Topics](./09-Advanced-Topics/README.md) 🚀
**Sujets avancés**

- Spark MLlib (Machine Learning)
- Delta Lake (ACID transactions)
- GraphX (Graph processing)
- Arrow et Pandas UDF
- Performance monitoring

**Exemples inclus :**
- `spark_ml.py` - Machine Learning avec MLlib
- `delta_lake.py` - Utilisation de Delta Lake
- `graph_processing.py` - Traitement de graphes

**Durée estimée :** 3 jours

### [10-Production-Deployment](./10-Production-Deployment/README.md) 🏭
**Déployer Spark en production**

- Modes de déploiement (Standalone, YARN, Kubernetes, Mesos)
- Databricks
- EMR (AWS) et Dataproc (GCP)
- Monitoring et logging
- Best practices production

**Configurations incluses :**
- `kubernetes/spark-on-k8s.yaml` - Déploiement Kubernetes
- `databricks/job-config.json` - Configuration Databricks jobs

**Durée estimée :** 2 jours

### [Projets](./Projets/)
**Projets pratiques de bout en bout**

- **01-Analyse-Logs** : Analyser des logs web avec Spark
- **02-ETL-E-commerce** : Pipeline ETL pour données e-commerce
- **03-Streaming-IoT** : Traitement temps réel de données IoT

**Durée estimée :** 1 semaine

---

## Prérequis

### Connaissances requises

- **Python** : Niveau intermédiaire (voir module Python-Basics)
- **SQL** : Requêtes de base
- **Linux** : Ligne de commande
- **Big Data** : Concepts de base (distribué, partitionnement)

### Connaissances recommandées

- **Scala** : Optionnel mais utile
- **Docker** : Pour l'environnement de développement
- **Cloud** : AWS/GCP/Azure pour le déploiement

### Logiciels à installer

```bash
# Python 3.8+
python --version

# Java 8 ou 11
java -version

# Docker (recommandé)
docker --version

# (Optionnel) Scala
scala -version
```

---

## Installation rapide

### Option 1 : Docker (Recommandé pour débuter)

```bash
cd 02-Installation-Setup
docker-compose up -d
```

Accédez à Jupyter : `http://localhost:8888`

### Option 2 : Installation locale

```bash
# Installer PySpark via pip
pip install pyspark

# Tester l'installation
python -c "import pyspark; print(pyspark.__version__)"
```

### Option 3 : Databricks Community Edition

1. S'inscrire sur [Databricks Community Edition](https://community.cloud.databricks.com/)
2. Créer un cluster
3. Importer les notebooks du cours

---

## Parcours d'apprentissage

### Débutant (2 semaines)
1. 01-Introduction
2. 02-Installation-Setup
3. 04-DataFrames-API (focus sur DataFrame, pas RDD)
4. 05-Spark-SQL (bases)
5. 06-ETL-Pipelines (lecture/écriture simple)

### Intermédiaire (4 semaines)
1. Parcours Débutant
2. 03-RDD-Basics
3. 05-Spark-SQL (complet)
4. 06-ETL-Pipelines (complet)
5. 07-Performance-Optimization
6. Projet 01 ou 02

### Avancé (6 semaines)
1. Parcours Intermédiaire
2. 08-Spark-Streaming
3. 09-Advanced-Topics
4. 10-Production-Deployment
5. Les 3 projets pratiques

---

## Concepts clés à maîtriser

### 1. Abstractions Spark

```
RDD (Low-level)
  ↓
DataFrame (High-level, optimisé)
  ↓
Dataset (Type-safe, Scala/Java)
```

**Recommandation** : Utilisez DataFrame API en priorité.

### 2. Architecture Spark

```
Driver Program
  ├─ SparkContext / SparkSession
  └─ Cluster Manager (YARN, K8s, etc.)
      ├─ Executor 1
      │   ├─ Task 1
      │   └─ Task 2
      ├─ Executor 2
      │   ├─ Task 3
      │   └─ Task 4
      └─ Executor N
```

### 3. Lazy Evaluation

```python
# Transformations (lazy)
df = spark.read.csv("data.csv")    # Pas d'exécution
df = df.filter(col("age") > 18)    # Pas d'exécution
df = df.select("name", "age")      # Pas d'exécution

# Action (déclenche l'exécution)
df.show()  # Exécution de toute la chaîne
```

### 4. Transformations vs Actions

**Transformations** (retournent un RDD/DataFrame) :
- `map`, `filter`, `select`, `groupBy`, `join`, etc.

**Actions** (retournent une valeur ou écrivent des données) :
- `collect`, `count`, `show`, `write`, `reduce`, etc.

---

## Comparaison des technologies

| Technologie | Cas d'usage | Vitesse | Complexité |
|-------------|-------------|---------|------------|
| **Hadoop MapReduce** | Batch lourd | ⭐ | ⭐⭐⭐ |
| **Apache Spark** | Batch + Streaming | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Apache Flink** | Streaming temps réel | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Pandas** | Données en mémoire | ⭐⭐⭐ | ⭐ |
| **Dask** | Pandas distribué | ⭐⭐⭐ | ⭐⭐ |

### Quand utiliser Spark ?

**✅ Utilisez Spark pour :**
- Traiter des volumes de données > 10 GB
- ETL/ELT sur données distribuées
- Analyse de données à grande échelle
- Machine Learning distribué
- Streaming avec état (stateful)

**❌ N'utilisez PAS Spark pour :**
- Petits datasets (< 1 GB) → Utilisez Pandas
- Streaming ultra low-latency (< 100ms) → Utilisez Flink
- OLTP (transactions) → Utilisez une base de données
- Traitement simple de fichiers → Utilisez des scripts

---

## Écosystème Spark

```
Apache Spark
├── Spark Core (RDD)
├── Spark SQL (DataFrames, SQL)
├── Spark Streaming (Structured Streaming)
├── MLlib (Machine Learning)
└── GraphX (Graph processing)

Intégrations
├── Sources de données
│   ├── HDFS, S3, Azure Blob
│   ├── Kafka, Kinesis
│   ├── JDBC (MySQL, PostgreSQL)
│   └── NoSQL (Cassandra, MongoDB)
│
├── Formats
│   ├── Parquet, ORC
│   ├── Avro, JSON
│   └── Delta Lake, Iceberg
│
└── Clusters
    ├── YARN (Hadoop)
    ├── Kubernetes
    ├── Mesos
    └── Databricks, EMR, Dataproc
```

---

## Ressources

### Documentation officielle
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [PySpark API Reference](https://spark.apache.org/docs/latest/api/python/)
- [Databricks Documentation](https://docs.databricks.com/)

### Livres recommandés
- **"Learning Spark"** (2nd Edition) - Jules S. Damji et al.
- **"Spark: The Definitive Guide"** - Bill Chambers & Matei Zaharia
- **"High Performance Spark"** - Holden Karau & Rachel Warren

### Cours en ligne
- [Databricks Academy](https://academy.databricks.com/)
- [Spark on Coursera](https://www.coursera.org/learn/scala-spark-big-data)
- [Udemy Spark Courses](https://www.udemy.com/topic/apache-spark/)

### Communautés
- [Spark Users Mailing List](https://spark.apache.org/community.html)
- [Stack Overflow - apache-spark](https://stackoverflow.com/questions/tagged/apache-spark)
- [Reddit - r/apachespark](https://reddit.com/r/apachespark)

---

## Certifications

- **Databricks Certified Associate Developer for Apache Spark**
- **Databricks Certified Data Engineer Associate**
- **Cloudera Spark and Hadoop Developer**

---

## FAQ

**Q: Spark ou Pandas ?**
A: Pandas pour < 10 GB en mémoire, Spark pour > 10 GB distribué.

**Q: PySpark ou Scala Spark ?**
A: PySpark pour la simplicité et l'écosystème Python. Scala pour les meilleures performances.

**Q: Quelle version de Spark ?**
A: Utilisez la dernière version stable (3.5+ en 2024).

**Q: Combien de mémoire pour Spark ?**
A: Minimum 4 GB pour le développement, 8+ GB recommandé.

**Q: Spark est-il gratuit ?**
A: Oui, Spark est open-source (Apache 2.0). Databricks/EMR sont payants.

---

## Contribution

Pour améliorer ce cours :
1. Ouvrir une issue pour signaler des erreurs
2. Proposer des pull requests
3. Partager vos retours d'expérience

---

## Roadmap du cours

```
Semaine 1 : Fondamentaux
  ├─ Introduction à Spark
  ├─ Installation
  └─ DataFrames API

Semaine 2 : SQL et ETL
  ├─ Spark SQL
  ├─ ETL Pipelines
  └─ Mini-projet ETL

Semaine 3 : Performance
  ├─ Optimisation
  ├─ Partitionnement
  └─ Caching

Semaine 4 : Streaming
  ├─ Structured Streaming
  ├─ Kafka integration
  └─ Projet streaming

Semaine 5-6 : Production
  ├─ Advanced topics
  ├─ Déploiement
  └─ Projet final complet
```

---

**Bon apprentissage avec Apache Spark ! 🚀**

"Spark is the Swiss Army knife of Big Data" - Anonymous Data Engineer
