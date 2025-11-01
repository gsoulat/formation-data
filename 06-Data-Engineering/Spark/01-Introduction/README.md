# Introduction à Apache Spark

## Table des matières

1. [Qu'est-ce qu'Apache Spark ?](#quest-ce-quapache-spark)
2. [Historique et évolution](#historique-et-évolution)
3. [Architecture de Spark](#architecture-de-spark)
4. [Composants de Spark](#composants-de-spark)
5. [Spark vs Hadoop MapReduce](#spark-vs-hadoop-mapreduce)
6. [Cas d'usage](#cas-dusage)
7. [Concepts clés](#concepts-clés)

---

## Qu'est-ce qu'Apache Spark ?

**Apache Spark** est un moteur d'analyse unifié pour le traitement de données à grande échelle, avec des modules intégrés pour le streaming, SQL, le machine learning et le traitement de graphes.

### Caractéristiques principales

**Vitesse**
- Traitement en mémoire (RAM) plutôt que disque
- Jusqu'à 100x plus rapide que Hadoop MapReduce
- Optimisations avec Catalyst (SQL) et Tungsten (exécution)

**Facilité d'utilisation**
- APIs dans plusieurs langages : Python, Scala, Java, R, SQL
- API haut niveau (DataFrame) similaire à Pandas/SQL
- Mode interactif (REPL) pour l'exploration

**Généralité**
- Un seul moteur pour batch, streaming, ML, graphes
- Pas besoin de multiples outils spécialisés

**Évolutivité**
- Du laptop (mode local) aux clusters de milliers de machines
- Support de multiples gestionnaires de cluster (YARN, Kubernetes, Mesos)

---

## Historique et évolution

**2009** : Projet de recherche à UC Berkeley AMPLab

**2010** : Open-source sous licence BSD

**2013** : Don à Apache Software Foundation

**2014** : Spark 1.0 - Production ready

**2016** : Spark 2.0 - Structured Streaming, DataFrame unifié

**2020** : Spark 3.0 - Adaptive Query Execution, support Python 3.8+

**2023** : Spark 3.5 - Spark Connect, améliorations performances

### Timeline des versions

```
Spark 1.x (2014-2015)
  ├─ RDD API
  ├─ DataFrame API (1.3)
  └─ MLlib, GraphX

Spark 2.x (2016-2020)
  ├─ Dataset API unifié
  ├─ Structured Streaming
  ├─ Catalyst optimizer amélioré
  └─ Spark SQL mature

Spark 3.x (2020-present)
  ├─ Adaptive Query Execution (AQE)
  ├─ Dynamic Partition Pruning
  ├─ Support Kubernetes amélioré
  └─ Spark Connect (3.4+)
```

---

## Architecture de Spark

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────┐
│              APPLICATION (Driver Program)            │
│                                                       │
│  ┌───────────────────────────────────────────────┐  │
│  │          SparkContext / SparkSession          │  │
│  └───────────────────────────────────────────────┘  │
│                         │                            │
└─────────────────────────┼────────────────────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │     Cluster Manager            │
          │  (YARN / Kubernetes / Mesos)  │
          └───────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
    ┌────────┐       ┌────────┐       ┌────────┐
    │Executor│       │Executor│       │Executor│
    │        │       │        │       │        │
    │ Cache  │       │ Cache  │       │ Cache  │
    │        │       │        │       │        │
    │Task│Task│     │Task│Task│     │Task│Task│
    └────────┘       └────────┘       └────────┘
```

### Composants principaux

**Driver Program**
- Point d'entrée de l'application Spark
- Contient le code de l'application (fonction `main`)
- Crée le SparkContext/SparkSession
- Distribue les tâches aux executors

**Cluster Manager**
- Alloue les ressources (CPU, mémoire)
- Types : Standalone, YARN, Kubernetes, Mesos
- Gère le cycle de vie des executors

**Executors**
- Processus qui exécutent les tâches
- Stockent les données en cache
- Retournent les résultats au driver
- Un executor = 1 JVM par nœud worker

**Tasks**
- Unité de travail la plus petite
- Exécutées sur une partition de données
- Parallélisées à travers les executors

### Flux d'exécution

```
1. Driver crée SparkSession
       ↓
2. Driver construit le DAG (Directed Acyclic Graph)
       ↓
3. DAG Scheduler divise en stages
       ↓
4. Task Scheduler crée les tasks
       ↓
5. Cluster Manager alloue les executors
       ↓
6. Executors exécutent les tasks
       ↓
7. Résultats retournés au driver
```

---

## Composants de Spark

### Spark Core

Le moteur d'exécution de base qui fournit :
- Gestion de la mémoire
- Tolérance aux pannes
- Planification des tâches
- Interaction avec le stockage
- API RDD de bas niveau

### Spark SQL

Module pour travailler avec des données structurées :
- DataFrames et Datasets
- Support SQL standard
- Lecture/écriture de multiples formats (Parquet, JSON, CSV, etc.)
- Optimiseur de requêtes (Catalyst)
- Connecteurs JDBC/ODBC

### Spark Streaming (Structured Streaming)

Traitement de flux de données en temps réel :
- API unifiée avec batch (DataFrame)
- Exactement une fois (exactly-once) sémantique
- Intégration avec Kafka, Kinesis, etc.
- Fenêtrage et agrégations temporelles

### MLlib

Bibliothèque de machine learning distribué :
- Algorithmes ML (classification, régression, clustering)
- Feature engineering
- Pipelines ML
- Évaluation de modèles

### GraphX

Framework de traitement de graphes :
- Graph construction
- Algorithmes de graphes (PageRank, Connected Components)
- API Pregel pour graphes

---

## Spark vs Hadoop MapReduce

| Critère | Hadoop MapReduce | Apache Spark |
|---------|------------------|--------------|
| **Vitesse** | Disque (slow) | Mémoire (fast) |
| **Performance** | 1x (baseline) | 10-100x |
| **Facilité** | Complexe (Java) | Simple (Python/Scala/SQL) |
| **API** | Bas niveau | Haut niveau |
| **Streaming** | Non natif | Oui (Structured Streaming) |
| **ML** | Mahout (séparé) | MLlib (intégré) |
| **Interactif** | Non | Oui (shell, notebooks) |
| **Tolérance pannes** | Réplication | Lineage (DAG) |

### Pourquoi Spark est plus rapide ?

**1. In-Memory Computing**
```
MapReduce:
Input → Map → Write to disk → Reduce → Write to disk → Output

Spark:
Input → Transformations in memory → Output
```

**2. DAG Execution**
```
MapReduce: Chaque job est indépendant
Spark: Optimise toute la chaîne d'opérations
```

**3. Lazy Evaluation**
- Spark ne calcule que quand une action est appelée
- Permet d'optimiser le plan d'exécution

---

## Cas d'usage

### 1. ETL/ELT à grande échelle

```python
# Exemple : Nettoyer et transformer des logs
df = spark.read.json("s3://logs/2024/")
df_clean = df.filter(col("status") == 200) \
    .select("user_id", "timestamp", "url") \
    .withColumn("date", to_date("timestamp"))

df_clean.write.parquet("s3://clean-data/logs/")
```

**Cas réels :**
- Migration de bases de données
- Transformation de formats (JSON → Parquet)
- Enrichissement de données

### 2. Analyse de données

```python
# Exemple : Analytics e-commerce
sales = spark.read.parquet("s3://sales/")

daily_revenue = sales.groupBy("date", "product") \
    .agg(sum("amount").alias("revenue")) \
    .orderBy(desc("revenue"))

daily_revenue.show()
```

**Cas réels :**
- Dashboards analytics
- Rapports quotidiens
- Détection d'anomalies

### 3. Machine Learning

```python
from pyspark.ml import Pipeline
from pyspark.ml.classification import RandomForestClassifier

# Entraîner un modèle sur des milliards de lignes
rf = RandomForestClassifier(labelCol="label")
model = rf.fit(training_data)

predictions = model.transform(test_data)
```

**Cas réels :**
- Systèmes de recommandation
- Détection de fraude
- Prédiction de churn

### 4. Streaming temps réel

```python
# Exemple : Traiter des events IoT en temps réel
stream = spark.readStream \
    .format("kafka") \
    .option("subscribe", "iot-events") \
    .load()

alerts = stream.filter(col("temperature") > 100)

query = alerts.writeStream \
    .format("console") \
    .start()
```

**Cas réels :**
- Monitoring d'applications
- Processing d'events IoT
- Analyse de clickstream

---

## Concepts clés

### 1. RDD (Resilient Distributed Dataset)

API de bas niveau, collection distribuée immuable.

```python
rdd = sc.parallelize([1, 2, 3, 4, 5])
result = rdd.map(lambda x: x * 2).collect()
# [2, 4, 6, 8, 10]
```

**Caractéristiques :**
- Immutable
- Distribué (partitionné)
- Resilient (tolérant aux pannes via lineage)
- Lazy evaluation

### 2. DataFrame

API haut niveau, optimisée, similaire à Pandas ou table SQL.

```python
df = spark.createDataFrame([
    (1, "Alice", 25),
    (2, "Bob", 30)
], ["id", "name", "age"])

df.filter(col("age") > 25).show()
```

**Avantages :**
- Optimisations automatiques (Catalyst)
- Schema pour validation
- Compatible SQL
- Performances meilleures que RDD

### 3. Lazy Evaluation

Les transformations ne sont pas exécutées immédiatement.

```python
# Ces lignes ne déclenchent PAS d'exécution
df = spark.read.csv("data.csv")      # Transformation
df2 = df.filter(col("age") > 18)     # Transformation
df3 = df2.select("name", "age")      # Transformation

# Cette ligne déclenche TOUTE l'exécution
df3.show()  # Action
```

**Bénéfices :**
- Optimisation du plan d'exécution
- Moins de passes sur les données
- Meilleures performances

### 4. Transformations vs Actions

**Transformations** (lazy) :
- `map`, `filter`, `select`, `join`, `groupBy`
- Retournent un nouveau RDD/DataFrame

**Actions** (eager) :
- `collect`, `count`, `show`, `save`, `reduce`
- Déclenchent l'exécution
- Retournent une valeur ou écrivent des données

### 5. Partitionnement

Les données sont divisées en partitions pour le parallélisme.

```python
# 4 partitions
df = spark.read.csv("data.csv").repartition(4)

# Voir le nombre de partitions
print(df.rdd.getNumPartitions())
```

**Règle de base :**
- Nombre de partitions ≈ 2-3x le nombre de cœurs CPU
- Taille partition idéale : 128 MB - 1 GB

---

## Écosystème Spark

```
┌─────────────────────────────────────────┐
│         Apache Spark Ecosystem           │
├─────────────────────────────────────────┤
│                                           │
│  Langages                                │
│  ├─ Python (PySpark)                     │
│  ├─ Scala (natif)                        │
│  ├─ Java                                 │
│  ├─ R (SparkR)                           │
│  └─ SQL                                  │
│                                           │
│  Storage                                 │
│  ├─ HDFS                                 │
│  ├─ S3, Azure Blob, GCS                  │
│  ├─ Databases (JDBC)                     │
│  └─ NoSQL (Cassandra, HBase)             │
│                                           │
│  Formats                                 │
│  ├─ Parquet, ORC (columnar)              │
│  ├─ Avro (row-based)                     │
│  ├─ JSON, CSV                            │
│  └─ Delta Lake, Iceberg                  │
│                                           │
│  Deployment                              │
│  ├─ Databricks                           │
│  ├─ AWS EMR                              │
│  ├─ GCP Dataproc                         │
│  ├─ Azure Synapse                        │
│  └─ On-premise (YARN, K8s)               │
└─────────────────────────────────────────┘
```

---

## Quand utiliser Spark ?

### ✅ Utilisez Spark pour :

- Traiter des données > 10 GB
- ETL/ELT distribué
- Analyse de données massives
- Machine Learning à grande échelle
- Streaming avec état (stateful)
- Requêtes SQL sur data lake

### ❌ N'utilisez PAS Spark pour :

- Petits datasets (< 1 GB) → Pandas
- OLTP (transactions) → PostgreSQL, MySQL
- Streaming ultra low-latency (< 100ms) → Flink
- Traitement simple de fichiers → Scripts shell/Python

---

## Prochaines étapes

Passez au module suivant : **[02-Installation-Setup](../02-Installation-Setup/README.md)**

Vous allez apprendre à :
- Installer Spark localement
- Configurer un environnement Docker
- Utiliser Databricks
- Lancer votre premier programme Spark
