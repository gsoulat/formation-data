# Projet 03 : Streaming IoT en Temps Réel

## Objectif

Traiter en temps réel des données de capteurs IoT (température, humidité, pression) avec Spark Structured Streaming.

## Architecture

```
Capteurs IoT → Kafka → Spark Streaming → Sink (Console/Parquet/DB)
                                      ↓
                               Alertes temps réel
```

## Dataset

Messages JSON envoyés par des capteurs :

```json
{
  "sensor_id": "SENSOR_001",
  "timestamp": "2024-01-10T14:30:00Z",
  "temperature": 22.5,
  "humidity": 65.0,
  "pressure": 1013.25,
  "location": "Building A - Floor 2"
}
```

## Tâches

### Phase 1 : Setup (30 min)

1. **Option A - Kafka** (production) :
   - Installer Kafka localement ou Docker
   - Créer topic `iot-sensors`
   - Producer pour générer des données

2. **Option B - Socket** (simple, pour tests) :
   - Utiliser netcat pour simuler le stream
   - `nc -lk 9999`

3. **Option C - File Stream** (le plus simple) :
   - Monitorer un dossier
   - Générer des fichiers JSON

### Phase 2 : Streaming Pipeline (2h)

1. **Lecture du stream** :
   ```python
   stream_df = spark.readStream \
       .format("kafka") \  # ou "socket" ou "json"
       .load()
   ```

2. **Parsing et validation** :
   - Parser le JSON
   - Valider les valeurs (temperature entre -50 et 50, etc.)
   - Filtrer les données invalides

3. **Transformations** :
   - Convertir timestamp
   - Ajouter des colonnes dérivées (is_alert, severity)
   - Window aggregations (moyenne sur 5 minutes)

4. **Détection d'anomalies** :
   - Température > 30°C : Alerte "HIGH_TEMP"
   - Température < 10°C : Alerte "LOW_TEMP"
   - Humidité > 80% : Alerte "HIGH_HUMIDITY"
   - Changement brusque : > 5°C en 1 minute

5. **Agrégations temps réel** :
   - Moyenne par capteur (tumbling window 5 min)
   - Min/Max par location
   - Nombre d'alertes par type

### Phase 3 : Sinks (1h)

1. **Console** (debugging) :
   ```python
   query = stream_df.writeStream \
       .format("console") \
       .outputMode("update") \
       .start()
   ```

2. **Parquet** (archivage) :
   ```python
   query = stream_df.writeStream \
       .format("parquet") \
       .option("path", "output/iot-data") \
       .option("checkpointLocation", "checkpoint/iot") \
       .trigger(processingTime='10 seconds') \
       .start()
   ```

3. **Kafka** (pour autres consommateurs) :
   ```python
   query = alerts_df.writeStream \
       .format("kafka") \
       .option("topic", "iot-alerts") \
       .start()
   ```

4. **Dashboard en temps réel** (optionnel) :
   - Utiliser foreachBatch pour écrire dans une DB
   - Créer un dashboard avec Grafana/Streamlit

## Livrables

```
03-Streaming-IoT/
├── README.md
├── setup_kafka.sh              # Setup Kafka (optionnel)
├── data_generator.py           # Générer données IoT
├── streaming_pipeline.py       # Pipeline Spark Streaming
├── config/
│   └── kafka_config.properties
├── output/
│   ├── iot-data/              # Données archivées
│   ├── alerts/                # Alertes détectées
│   └── aggregates/            # Métriques temps réel
└── dashboard/
    └── dashboard.py           # Dashboard temps réel (optionnel)
```

## Concepts à maîtriser

### Window Operations

```python
# Tumbling window (5 minutes sans chevauchement)
windowed_avg = stream_df.groupBy(
    window(col("timestamp"), "5 minutes"),
    col("sensor_id")
).agg(avg("temperature"))

# Sliding window (10 min window, slide 5 min)
windowed_avg = stream_df.groupBy(
    window(col("timestamp"), "10 minutes", "5 minutes"),
    col("sensor_id")
).agg(avg("temperature"))
```

### Watermarking

```python
# Gérer les événements en retard (jusqu'à 10 minutes)
stream_df = stream_df.withWatermark("timestamp", "10 minutes")
```

### Stateful Operations

```python
# Maintenir l'état (ex: dernière valeur par capteur)
from pyspark.sql.functions import last

last_values = stream_df.groupBy("sensor_id") \
    .agg(last("temperature").alias("last_temp"))
```

## Alertes à implémenter

1. **Seuils statiques** :
   - Température > 30°C
   - Humidité > 80%

2. **Seuils dynamiques** :
   - Température > moyenne + 2×std_dev

3. **Patterns** :
   - 3 alertes consécutives du même capteur
   - Augmentation continue sur 15 minutes

4. **Anomalies** :
   - Valeur aberrante (z-score > 3)
   - Capteur non responsive (pas de données depuis 10 min)

## Métriques à calculer

- **Temps réel** :
  - Nombre d'événements/seconde
  - Latence de traitement
  - Nombre d'alertes actives

- **Agrégations** :
  - Moyenne/Min/Max par fenêtre de temps
  - Écart-type
  - Percentiles (p50, p95, p99)

## Solution

Voir `streaming_pipeline.py` pour la solution complète.

## Extensions possibles

1. **Machine Learning** :
   - Prédire les pannes de capteurs
   - Détecter les anomalies avec ML

2. **Scalabilité** :
   - Tester avec 1000+ capteurs
   - Optimiser les performances

3. **Enrichissement** :
   - Joindre avec données météo externes
   - Corréler avec événements business

4. **Dashboard** :
   - Visualisation temps réel avec Grafana
   - Alertes par email/Slack

## Critères d'évaluation

- ✅ Pipeline streaming fonctionnel
- ✅ Parsing et validation
- ✅ Window operations correctes
- ✅ Watermarking configuré
- ✅ Détection d'alertes
- ✅ Multiple sinks (console + fichier)
- ✅ Gestion des checkpoints
- ✅ Monitoring (métriques, logs)
- ✅ Code production-ready
