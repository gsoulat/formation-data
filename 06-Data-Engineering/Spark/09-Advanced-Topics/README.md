# Advanced Topics - Sujets avancés

## 1. Machine Learning avec MLlib

### Pipeline ML

```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# Préparer features
assembler = VectorAssembler(
    inputCols=["feature1", "feature2", "feature3"],
    outputCol="features"
)

scaler = StandardScaler(
    inputCol="features",
    outputCol="scaled_features"
)

# Modèle
rf = RandomForestClassifier(
    featuresCol="scaled_features",
    labelCol="label"
)

# Pipeline
pipeline = Pipeline(stages=[assembler, scaler, rf])

# Entraîner
model = pipeline.fit(train_df)

# Prédire
predictions = model.transform(test_df)

# Évaluer
evaluator = BinaryClassificationEvaluator()
auc = evaluator.evaluate(predictions)
print(f"AUC: {auc}")
```

### Algorithmes disponibles

- **Classification** : Logistic Regression, Random Forest, Gradient Boosted Trees, Naive Bayes
- **Regression** : Linear Regression, Random Forest, GBT
- **Clustering** : K-Means, Bisecting K-Means, GMM
- **Collaborative Filtering** : ALS

---

## 2. Delta Lake

### Qu'est-ce que Delta Lake ?

**Delta Lake** ajoute des transactions ACID sur Data Lakes (Parquet).

```python
# Écrire en Delta
df.write.format("delta").save("/data/delta-table")

# Lire Delta
df = spark.read.format("delta").load("/data/delta-table")

# UPDATE
from delta.tables import DeltaTable

deltaTable = DeltaTable.forPath(spark, "/data/delta-table")
deltaTable.update(
    condition="id = 5",
    set={"status": "'inactive'"}
)

# DELETE
deltaTable.delete("status = 'inactive'")

# MERGE (upsert)
deltaTable.alias("target").merge(
    updates.alias("source"),
    "target.id = source.id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Time Travel
df = spark.read.format("delta") \
    .option("versionAsOf", 5) \
    .load("/data/delta-table")
```

### Avantages

- ✅ Transactions ACID
- ✅ Time travel
- ✅ Schema enforcement & evolution
- ✅ MERGE operations (upsert)
- ✅ Optimizations (compaction, Z-ordering)

---

## 3. GraphX

### Graph Processing

```python
from pyspark import SparkContext
from pyspark.sql import SQLContext

sc = SparkContext.getOrCreate()
sqlContext = SQLContext(sc)

# Créer un graphe (nécessite RDD API)
vertices = sc.parallelize([
    (1, "Alice"),
    (2, "Bob"),
    (3, "Charlie")
])

edges = sc.parallelize([
    (1, 2, "friend"),
    (2, 3, "friend")
])

# GraphX nécessite Scala - Utilisez GraphFrames en Python
from graphframes import GraphFrame

vertices_df = spark.createDataFrame([(1, "Alice"), (2, "Bob")], ["id", "name"])
edges_df = spark.createDataFrame([(1, 2, "friend")], ["src", "dst", "relationship"])

g = GraphFrame(vertices_df, edges_df)

# PageRank
results = g.pageRank(resetProbability=0.15, maxIter=10)
results.vertices.show()

# Connected Components
cc = g.connectedComponents()
cc.show()
```

---

## 4. Pandas UDF

### Vectorized UDFs

```python
from pyspark.sql.functions import pandas_udf
import pandas as pd

# Scalar Pandas UDF
@pandas_udf("double")
def multiply_by_2(s: pd.Series) -> pd.Series:
    return s * 2

df.withColumn("doubled", multiply_by_2("value")).show()

# Grouped Map Pandas UDF
@pandas_udf("id long, value double", PandasUDFType.GROUPED_MAP)
def normalize(pdf):
    pdf['value'] = (pdf['value'] - pdf['value'].mean()) / pdf['value'].std()
    return pdf

df.groupby("group").apply(normalize).show()
```

**Avantages** :
- 10-100x plus rapide que UDF standard
- Vectorisation avec NumPy/Pandas
- Utilise Apache Arrow

---

## 5. Koalas (pandas API sur Spark)

```python
import databricks.koalas as ks

# Koalas DataFrame (API Pandas, exécution Spark)
kdf = ks.DataFrame({
    'A': [1, 2, 3],
    'B': [4, 5, 6]
})

# Opérations Pandas
kdf['C'] = kdf['A'] + kdf['B']
kdf.groupby('A').sum()

# Conversion
spark_df = kdf.to_spark()
pandas_df = kdf.to_pandas()
```

---

## 6. Arrow et interopérabilité

```python
# Activer Arrow pour conversions rapides Spark ↔ Pandas
spark.conf.set("spark.sql.execution.arrow.pyspark.enabled", "true")

# Conversion rapide
pandas_df = spark_df.toPandas()  # Utilise Arrow
spark_df = spark.createDataFrame(pandas_df)  # Utilise Arrow
```

---

## Prochaines étapes

Module suivant : **[10-Production-Deployment](../10-Production-Deployment/README.md)**
