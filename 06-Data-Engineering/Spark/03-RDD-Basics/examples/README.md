# Exemples RDD Basics

Ce dossier contient des exemples pratiques pour apprendre les RDDs (Resilient Distributed Datasets) avec PySpark.

## Fichiers

### 1. rdd_creation.py
Apprendre à créer des RDDs de différentes manières :
- À partir de collections Python (parallelize)
- À partir de fichiers texte
- Avec contrôle du nombre de partitions
- Pair RDDs (key-value)

### 2. rdd_transformations.py
Maîtriser les transformations (lazy) :
- `map`, `filter`, `flatMap`
- `distinct`, `union`, `intersection`
- `reduceByKey`, `groupByKey`, `mapValues`
- `join`, `sortBy`, `sortByKey`

### 3. rdd_actions.py
Comprendre les actions (eager) :
- `collect`, `count`, `first`, `take`
- `reduce`, `fold`, `aggregate`
- `countByValue`, `countByKey`
- `saveAsTextFile`

## Prérequis

```bash
# Installer PySpark
pip install pyspark

# Vérifier l'installation
python -c "import pyspark; print(pyspark.__version__)"
```

## Exécuter les exemples

### Méthode 1 : Ligne de commande

```bash
# Se placer dans le dossier examples
cd 03-RDD-Basics/examples

# Exécuter un script
python rdd_creation.py
python rdd_transformations.py
python rdd_actions.py
```

### Méthode 2 : spark-submit

```bash
# Utiliser spark-submit pour plus de contrôle
spark-submit rdd_creation.py
spark-submit rdd_transformations.py
spark-submit rdd_actions.py
```

### Méthode 3 : Jupyter Notebook

```bash
# Lancer Jupyter avec PySpark
pyspark

# Ou dans un notebook normal
jupyter notebook

# Puis copier/coller les exemples dans les cellules
```

### Méthode 4 : Docker

```bash
# Si vous utilisez Docker (voir module 02-Installation-Setup)
docker exec -it spark-master python /opt/spark-apps/rdd_creation.py
```

## Ordre recommandé

1. **rdd_creation.py** - Commencez ici pour créer vos premiers RDDs
2. **rdd_transformations.py** - Apprenez à transformer les données
3. **rdd_actions.py** - Déclenchez l'exécution et récupérez les résultats

## Configuration Spark

Les exemples utilisent la configuration locale :

```python
conf = SparkConf().setAppName("App Name").setMaster("local[*]")
```

- `local[*]` = mode local avec tous les cœurs CPU disponibles
- `local[4]` = mode local avec 4 cœurs
- `spark://master:7077` = mode cluster

## Points importants

### Lazy Evaluation

Les **transformations** sont lazy (map, filter, etc.) :
```python
rdd2 = rdd1.map(lambda x: x * 2)  # Pas d'exécution
```

Les **actions** sont eager (collect, count, etc.) :
```python
result = rdd2.collect()  # Exécution !
```

### Attention à collect()

⚠️ **N'utilisez pas `collect()` sur de gros datasets** :

```python
# ❌ Risque OutOfMemory
huge_rdd = sc.parallelize(range(10000000))
all_data = huge_rdd.collect()  # Charge tout en RAM du driver

# ✅ Utilisez take() ou saveAsTextFile()
sample = huge_rdd.take(100)
huge_rdd.saveAsTextFile("output/")
```

### Partitionnement

Le nombre de partitions affecte les performances :

```python
# Voir le nombre de partitions
print(rdd.getNumPartitions())

# Règle de base : 2-3x le nombre de CPU cores
rdd = sc.parallelize(data, numSlices=num_cores * 2)
```

## Dépannage

### Erreur : Java not found

```bash
# Installer Java 8 ou 11
sudo apt install openjdk-11-jdk

# Configurer JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

### Erreur : py4j errors

```bash
# Réinstaller PySpark
pip uninstall pyspark
pip install pyspark
```

### Mémoire insuffisante

```python
# Réduire la mémoire utilisée
conf = SparkConf() \
    .setAppName("App") \
    .setMaster("local[*]") \
    .set("spark.driver.memory", "1g") \
    .set("spark.executor.memory", "1g")
```

## Exercices pratiques

Après avoir exécuté les exemples, essayez ces exercices :

### Exercice 1 : Filtrage
Créer un RDD de nombres de 1 à 100 et garder seulement les multiples de 7.

### Exercice 2 : Word Count personnalisé
Compter les mots dans le fichier `/tmp/spark_sample.txt` (créé par `rdd_creation.py`).

### Exercice 3 : Top produits
Avec des données de ventes (produit, quantité), trouver les 5 produits les plus vendus.

### Exercice 4 : Jointure
Créer deux RDDs (users et orders) et les joindre sur user_id.

## Ressources

- [Documentation PySpark RDD](https://spark.apache.org/docs/latest/rdd-programming-guide.html)
- [PySpark API Reference](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.RDD.html)
- Module suivant : [04-DataFrames-API](../../04-DataFrames-API/README.md)

## Spark UI

Pendant l'exécution des scripts, accédez à l'interface web Spark :
- **URL** : http://localhost:4040
- **Informations disponibles** : Jobs, Stages, Tasks, Storage, Environment

Cela vous permet de voir :
- Les transformations et actions exécutées
- Le DAG (Directed Acyclic Graph)
- Les performances de chaque stage
- La distribution des tâches sur les partitions
