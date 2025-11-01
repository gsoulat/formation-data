# Production Deployment - Déployer Spark en production

## Modes de déploiement

### 1. Standalone Mode

**Cluster Spark géré par Spark lui-même**

```bash
# Démarrer master
$SPARK_HOME/sbin/start-master.sh

# Démarrer worker
$SPARK_HOME/sbin/start-worker.sh spark://master:7077

# Soumettre un job
spark-submit \
  --master spark://master:7077 \
  --deploy-mode cluster \
  --executor-memory 4G \
  --total-executor-cores 8 \
  my_app.py
```

### 2. YARN (Hadoop)

```bash
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --num-executors 10 \
  --executor-cores 4 \
  --executor-memory 8G \
  --driver-memory 4G \
  my_app.py
```

### 3. Kubernetes

```bash
spark-submit \
  --master k8s://https://kubernetes-api:6443 \
  --deploy-mode cluster \
  --name spark-app \
  --conf spark.kubernetes.container.image=spark:3.5.0 \
  --conf spark.executor.instances=5 \
  --conf spark.executor.memory=4g \
  my_app.py
```

**Configuration Kubernetes** : Voir `kubernetes/spark-on-k8s.yaml`

### 4. Databricks

- Interface web
- Clusters managed
- Notebooks collaboratifs
- Jobs scheduler intégré
- Delta Lake natif

### 5. Cloud Managed Services

**AWS EMR**
```bash
aws emr create-cluster \
  --name "Spark Cluster" \
  --release-label emr-6.15.0 \
  --applications Name=Spark \
  --ec2-attributes KeyName=myKey \
  --instance-type m5.xlarge \
  --instance-count 3
```

**GCP Dataproc**
```bash
gcloud dataproc clusters create spark-cluster \
  --region=us-central1 \
  --zone=us-central1-a \
  --num-workers=3 \
  --worker-machine-type=n1-standard-4
```

**Azure Synapse Analytics / HDInsight**

---

## Configuration production

### spark-submit

```bash
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --name "Production ETL Job" \
  \
  # Ressources
  --num-executors 20 \
  --executor-cores 4 \
  --executor-memory 16G \
  --driver-memory 8G \
  --driver-cores 2 \
  \
  # Configuration
  --conf spark.sql.shuffle.partitions=400 \
  --conf spark.sql.adaptive.enabled=true \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.dynamicAllocation.minExecutors=5 \
  --conf spark.dynamicAllocation.maxExecutors=50 \
  \
  # Monitoring
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=hdfs:///spark-logs \
  \
  # Jars et fichiers
  --jars /path/to/dependencies.jar \
  --files /path/to/config.conf \
  \
  # Application
  my_etl_job.py \
  --input s3://bucket/input \
  --output s3://bucket/output
```

### Configuration recommandée

```python
spark = SparkSession.builder \
    .appName("ProductionJob") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .config("spark.sql.shuffle.partitions", "400") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.sql.parquet.compression.codec", "snappy") \
    .config("spark.network.timeout", "600s") \
    .config("spark.executor.heartbeatInterval", "60s") \
    .getOrCreate()
```

---

## Monitoring et Logging

### Spark UI

- **Jobs** : Durée, stages, tasks
- **Stages** : Shuffle, spill
- **Executors** : Mémoire, CPU
- **SQL** : Plans d'exécution

### History Server

```bash
# Démarrer History Server
$SPARK_HOME/sbin/start-history-server.sh

# Accès: http://localhost:18080
```

### Métriques

```python
# Intégration avec Prometheus/Grafana
spark.conf.set("spark.metrics.conf.*.sink.graphite.class",
               "org.apache.spark.metrics.sink.GraphiteSink")
spark.conf.set("spark.metrics.conf.*.sink.graphite.host", "graphite-server")
spark.conf.set("spark.metrics.conf.*.sink.graphite.port", "2003")
```

### Logging

```python
import logging

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Dans votre code
logger.info("Starting ETL job")
logger.info(f"Processing {df.count()} records")
logger.error("Failed to read data", exc_info=True)
```

---

## Best Practices Production

### 1. Configuration

```python
# Lire config depuis fichier
import configparser

config = configparser.ConfigParser()
config.read('config.ini')

input_path = config.get('paths', 'input')
output_path = config.get('paths', 'output')
```

### 2. Gestion des erreurs

```python
try:
    df = spark.read.parquet(input_path)
    # Traitement
    df.write.parquet(output_path)
except Exception as e:
    logger.error(f"Job failed: {e}", exc_info=True)
    # Notification (email, Slack, etc.)
    raise
finally:
    spark.stop()
```

### 3. Idempotence

```python
# Écriture idempotente
output_path = f"s3://bucket/output/date={date}"

# Nettoyer avant d'écrire
if spark._jvm.org.apache.hadoop.fs.FileSystem \
    .get(spark._jsc.hadoopConfiguration()) \
    .exists(spark._jvm.org.apache.hadoop.fs.Path(output_path)):
    logger.info(f"Deleting existing output: {output_path}")
    # Delete

df.write.mode("overwrite").parquet(output_path)
```

### 4. Schema Validation

```python
from pyspark.sql.types import *

expected_schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("value", DoubleType(), True)
])

df = spark.read.schema(expected_schema).parquet(input_path)

# Validation
assert df.schema == expected_schema, "Schema mismatch"
```

### 5. Data Quality Checks

```python
# Vérifications
assert df.count() > 0, "Empty DataFrame"
assert df.filter(col("id").isNull()).count() == 0, "Null IDs found"

# Métriques qualité
null_counts = df.select([
    sum(col(c).isNull().cast("int")).alias(c)
    for c in df.columns
])
```

---

## Orchestration

### Apache Airflow

```python
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime

dag = DAG(
    'spark_etl_job',
    start_date=datetime(2024, 1, 1),
    schedule_interval='@daily'
)

spark_task = SparkSubmitOperator(
    task_id='run_spark_job',
    application='/path/to/my_job.py',
    name='daily_etl',
    conn_id='spark_default',
    conf={
        'spark.executor.memory': '8g',
        'spark.executor.cores': '4'
    },
    dag=dag
)
```

### Databricks Jobs

Voir `databricks/job-config.json`

---

## Sécurité

### Encryption

```python
# Encryption at rest
spark.conf.set("spark.io.encryption.enabled", "true")

# Encryption in transit
spark.conf.set("spark.network.crypto.enabled", "true")
```

### Authentication

```python
# Kerberos (YARN)
spark-submit \
  --master yarn \
  --principal user@REALM \
  --keytab /path/to/user.keytab \
  my_app.py
```

---

## Checklist Production

- [ ] Schema explicite (pas inferSchema)
- [ ] Logging configuré
- [ ] Gestion d'erreurs robuste
- [ ] Monitoring (métriques, alertes)
- [ ] Configuration externalisée
- [ ] Idempotence
- [ ] Data quality checks
- [ ] Tests (unit + integration)
- [ ] CI/CD pipeline
- [ ] Documentation
- [ ] Runbook pour incidents

---

## Ressources

- [Spark on Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html)
- [AWS EMR Guide](https://docs.aws.amazon.com/emr/)
- [GCP Dataproc](https://cloud.google.com/dataproc/docs)
- [Databricks](https://docs.databricks.com/)

---

**Félicitations ! Vous avez terminé le cours Apache Spark ! 🎉**

Vous maîtrisez maintenant :
- ✅ RDDs et DataFrames
- ✅ Spark SQL
- ✅ Pipelines ETL
- ✅ Optimisations
- ✅ Streaming
- ✅ Topics avancés
- ✅ Déploiement production
