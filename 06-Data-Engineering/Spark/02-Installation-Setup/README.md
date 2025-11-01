# Installation et Configuration de Spark

## Table des matières

1. [Options d'installation](#options-dinstallation)
2. [Installation locale](#installation-locale)
3. [Docker (Recommandé)](#docker-recommandé)
4. [Databricks Community Edition](#databricks-community-edition)
5. [Configuration Spark](#configuration-spark)
6. [Premier programme Spark](#premier-programme-spark)

---

## Options d'installation

| Option | Difficulté | Temps | Recommandé pour |
|--------|------------|-------|-----------------|
| **pip install pyspark** | ⭐ | 5 min | Débutants, prototypage rapide |
| **Docker** | ⭐⭐ | 10 min | Développement, reproductibilité |
| **Installation manuelle** | ⭐⭐⭐ | 30 min | Production, personnalisation |
| **Databricks** | ⭐ | 10 min | Cloud, collaboration |

---

## Installation locale

### Prérequis

**Java 8 ou 11** (requis)

```bash
# Vérifier Java
java -version

# Si non installé (Ubuntu/Debian)
sudo apt update
sudo apt install openjdk-11-jdk

# macOS
brew install openjdk@11

# Vérifier l'installation
java -version
# java version "11.0.x"
```

**Python 3.7+** (pour PySpark)

```bash
python --version
# Python 3.8.x ou supérieur
```

### Option 1 : pip install (La plus simple)

```bash
# Installer PySpark
pip install pyspark

# Vérifier l'installation
python -c "import pyspark; print(pyspark.__version__)"
# 3.5.0

# Installer avec des dépendances supplémentaires
pip install pyspark[sql,ml]
```

**Avantages :**
- Installation en 1 ligne
- Pas de configuration
- Parfait pour débuter

**Inconvénients :**
- Version unique
- Difficile à personnaliser

### Option 2 : Installation manuelle

```bash
# 1. Télécharger Spark
cd /opt
wget https://archive.apache.org/dist/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz

# 2. Extraire
tar -xzf spark-3.5.0-bin-hadoop3.tgz
sudo mv spark-3.5.0-bin-hadoop3 /opt/spark

# 3. Configurer les variables d'environnement
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc
echo 'export PYSPARK_PYTHON=python3' >> ~/.bashrc

# 4. Recharger
source ~/.bashrc

# 5. Vérifier
spark-shell --version
pyspark --version
```

---

## Docker (Recommandé)

### Installation Docker

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose

# macOS
brew install --cask docker

# Démarrer Docker
sudo systemctl start docker
```

### Docker Compose pour Spark

Créez un fichier `docker-compose.yml` :

```yaml
version: '3'

services:
  spark-master:
    image: bitnami/spark:3.5
    container_name: spark-master
    environment:
      - SPARK_MODE=master
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
      - SPARK_SSL_ENABLED=no
    ports:
      - "8080:8080"  # Spark UI
      - "7077:7077"  # Spark Master
    volumes:
      - ./data:/opt/spark-data
      - ./apps:/opt/spark-apps

  spark-worker-1:
    image: bitnami/spark:3.5
    container_name: spark-worker-1
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=2G
      - SPARK_WORKER_CORES=2
    depends_on:
      - spark-master
    volumes:
      - ./data:/opt/spark-data
      - ./apps:/opt/spark-apps

  spark-worker-2:
    image: bitnami/spark:3.5
    container_name: spark-worker-2
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=2G
      - SPARK_WORKER_CORES=2
    depends_on:
      - spark-master
    volumes:
      - ./data:/opt/spark-data
      - ./apps:/opt/spark-apps

  jupyter:
    image: jupyter/pyspark-notebook:latest
    container_name: spark-jupyter
    ports:
      - "8888:8888"
    environment:
      - JUPYTER_ENABLE_LAB=yes
      - SPARK_MASTER=spark://spark-master:7077
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./data:/home/jovyan/data
    depends_on:
      - spark-master
```

### Lancer l'environnement

```bash
# Créer les dossiers
mkdir -p data apps notebooks

# Lancer les conteneurs
docker-compose up -d

# Vérifier les logs
docker-compose logs -f

# Accéder aux interfaces
# Spark UI: http://localhost:8080
# Jupyter: http://localhost:8888 (token dans les logs)
```

### Utiliser Spark dans un conteneur

```bash
# Shell interactif Python
docker exec -it spark-master pyspark

# Shell interactif Scala
docker exec -it spark-master spark-shell

# Soumettre un job
docker exec -it spark-master spark-submit \
  --master spark://spark-master:7077 \
  /opt/spark-apps/my_app.py
```

---

## Databricks Community Edition

### Inscription

1. Aller sur [Databricks Community Edition](https://community.cloud.databricks.com/)
2. S'inscrire avec email
3. Vérifier l'email

### Créer un cluster

1. Cliquer sur **Compute** dans la barre latérale
2. Cliquer sur **Create Cluster**
3. Configuration :
   - **Cluster Name** : my-cluster
   - **Cluster Mode** : Single Node
   - **Databricks Runtime** : Latest (ex: 13.3 LTS)
4. Cliquer sur **Create Cluster**

### Créer un Notebook

1. Cliquer sur **Workspace** → **Create** → **Notebook**
2. Nom : **Premier Notebook**
3. Langage : **Python**
4. Cluster : Sélectionner votre cluster
5. Cliquer sur **Create**

### Exemple de code

```python
# Le SparkSession est déjà créé dans Databricks
# Variable : spark

# Créer un DataFrame
data = [(1, "Alice", 25), (2, "Bob", 30), (3, "Charlie", 35)]
df = spark.createDataFrame(data, ["id", "name", "age"])

# Afficher
display(df)

# Requête SQL
df.createOrReplaceTempView("users")
spark.sql("SELECT * FROM users WHERE age > 25").show()
```

---

## Configuration Spark

### spark-defaults.conf

Fichier de configuration par défaut (optionnel pour débuter).

```bash
# Créer le fichier
nano $SPARK_HOME/conf/spark-defaults.conf
```

```properties
# Mémoire
spark.driver.memory              2g
spark.executor.memory            2g

# Performance
spark.sql.shuffle.partitions     200
spark.default.parallelism        8

# Logs
spark.eventLog.enabled           true
spark.eventLog.dir               /tmp/spark-events

# Compression
spark.sql.parquet.compression.codec  snappy
```

### Configuration programmatique

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MonApplication") \
    .config("spark.driver.memory", "2g") \
    .config("spark.executor.memory", "2g") \
    .config("spark.sql.shuffle.partitions", "100") \
    .getOrCreate()
```

### Variables d'environnement

```bash
# Dans ~/.bashrc ou ~/.zshrc
export SPARK_HOME=/opt/spark
export PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
```

---

## Premier programme Spark

### Hello World avec PySpark

Créez `hello_spark.py` :

```python
from pyspark.sql import SparkSession

# Créer SparkSession
spark = SparkSession.builder \
    .appName("HelloSpark") \
    .master("local[*]") \
    .getOrCreate()

# Créer un DataFrame simple
data = [
    ("Alice", 25),
    ("Bob", 30),
    ("Charlie", 35)
]

df = spark.createDataFrame(data, ["name", "age"])

# Afficher
print("Hello from Spark!")
df.show()

# Opérations simples
print("\nPersonnes > 25 ans:")
df.filter(df.age > 25).show()

# Statistiques
print("\nAge moyen:")
df.agg({"age": "avg"}).show()

# Arrêter Spark
spark.stop()
```

Exécutez :

```bash
python hello_spark.py
```

Output :

```
Hello from Spark!
+-------+---+
|   name|age|
+-------+---+
|  Alice| 25|
|    Bob| 30|
|Charlie| 35|
+-------+---+

Personnes > 25 ans:
+-------+---+
|   name|age|
+-------+---+
|    Bob| 30|
|Charlie| 35|
+-------+---+

Age moyen:
+--------+
|avg(age)|
+--------+
|    30.0|
+--------+
```

### Jupyter Notebook

```bash
# Option 1: Lancer Jupyter avec PySpark
pyspark

# Option 2: Jupyter normal + import pyspark
jupyter notebook
```

Dans un notebook :

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("NotebookSpark") \
    .getOrCreate()

# Tester
df = spark.range(10)
df.show()
```

---

## Vérification de l'installation

### Checklist

```bash
# 1. Java installé ?
java -version

# 2. Python installé ?
python --version

# 3. PySpark importable ?
python -c "import pyspark; print(pyspark.__version__)"

# 4. Spark shell fonctionne ?
pyspark --version

# 5. Spark UI accessible ?
# Lancer pyspark puis aller sur http://localhost:4040
```

### Test complet

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg

# Créer session
spark = SparkSession.builder \
    .appName("InstallTest") \
    .master("local[*]") \
    .getOrCreate()

# Créer données
data = [(i, i*2) for i in range(1000)]
df = spark.createDataFrame(data, ["id", "value"])

# Opérations
result = df.filter(col("id") > 500) \
    .agg(avg("value").alias("moyenne")) \
    .collect()

print(f"Moyenne : {result[0]['moyenne']}")

# Si ça affiche un nombre, tout fonctionne !
spark.stop()
```

---

## Troubleshooting

### Problème : Java not found

```bash
# Vérifier JAVA_HOME
echo $JAVA_HOME

# Si vide, définir
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
```

### Problème : py4j errors

```bash
# Réinstaller PySpark
pip uninstall pyspark
pip install pyspark
```

### Problème : Mémoire insuffisante

```python
# Réduire la mémoire
spark = SparkSession.builder \
    .config("spark.driver.memory", "1g") \
    .config("spark.executor.memory", "1g") \
    .getOrCreate()
```

---

## Ressources

- [Spark Download](https://spark.apache.org/downloads.html)
- [PySpark Documentation](https://spark.apache.org/docs/latest/api/python/)
- [Databricks Community](https://community.cloud.databricks.com/)

---

## Prochaines étapes

Maintenant que Spark est installé, passez au module suivant :
**[04-DataFrames-API](../04-DataFrames-API/README.md)**

(Note : On va directement aux DataFrames plutôt qu'aux RDDs qui sont de bas niveau)
