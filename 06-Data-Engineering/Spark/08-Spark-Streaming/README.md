# Spark Streaming - Traitement temps réel

## Introduction

**Structured Streaming** est l'API de streaming de Spark basée sur Spark SQL, permettant de traiter des flux de données en temps réel avec la même API que le batch.

### Concepts clés

- **Stream** : Flux continu de données
- **Source** : Origine des données (Kafka, socket, files)
- **Sink** : Destination (console, files, Kafka, DB)
- **Trigger** : Quand traiter les données
- **Watermark** : Gestion des données en retard

---

## Sources et Sinks

### Sources

```python
# Socket (pour tests)
df = spark.readStream.format("socket") \
    .option("host", "localhost") \
    .option("port", 9999) \
    .load()

# Fichiers (monitoring d'un dossier)
df = spark.readStream.format("json") \
    .schema(schema) \
    .load("/data/input/")

# Kafka
df = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", "topic1") \
    .load()
```

### Sinks

```python
# Console (pour tests)
query = df.writeStream \
    .format("console") \
    .start()

# Fichiers
query = df.writeStream \
    .format("parquet") \
    .option("path", "/data/output/") \
    .option("checkpointLocation", "/checkpoint/") \
    .start()

# Kafka
query = df.writeStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("topic", "output_topic") \
    .start()
```

---

## Exemple simple

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder \
    .appName("Streaming Example") \
    .getOrCreate()

# Lire depuis socket
lines = spark.readStream \
    .format("socket") \
    .option("host", "localhost") \
    .option("port", 9999) \
    .load()

# Word count
words = lines.select(explode(split(col("value"), " ")).alias("word"))
word_counts = words.groupBy("word").count()

# Écrire vers console
query = word_counts.writeStream \
    .outputMode("complete") \
    .format("console") \
    .start()

query.awaitTermination()
```

---

## Window Operations

### Tumbling Window

```python
# Fenêtres de 10 minutes sans chevauchement
windowed_counts = df \
    .groupBy(window(col("timestamp"), "10 minutes")) \
    .count()
```

### Sliding Window

```python
# Fenêtres de 10 min, slide de 5 min
windowed_counts = df \
    .groupBy(
        window(col("timestamp"), "10 minutes", "5 minutes")
    ) \
    .count()
```

### Watermark

```python
# Gérer les données en retard (jusqu'à 1h)
df = df.withWatermark("timestamp", "1 hour")

windowed_counts = df \
    .groupBy(window(col("timestamp"), "10 minutes")) \
    .count()
```

---

## Output Modes

```python
# complete : Toute la table résultat
.outputMode("complete")

# append : Seulement nouvelles lignes
.outputMode("append")

# update : Lignes modifiées
.outputMode("update")
```

---

## Triggers

```python
# Processing time trigger (toutes les 10 secondes)
.trigger(processingTime='10 seconds')

# Once (une seule fois puis s'arrête)
.trigger(once=True)

# Continuous (expérimental, latence ultra-faible)
.trigger(continuous='1 second')
```

---

## Checkpointing

```python
# Nécessaire pour fault tolerance
query = df.writeStream \
    .format("parquet") \
    .option("path", "/output/") \
    .option("checkpointLocation", "/checkpoint/") \
    .start()
```

---

## Prochaines étapes

Module suivant : **[09-Advanced-Topics](../09-Advanced-Topics/README.md)**
