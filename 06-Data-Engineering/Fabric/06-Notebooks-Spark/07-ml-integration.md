# ML Integration avec Spark

## Introduction

Fabric Notebooks intègrent **MLlib** (Spark ML) et **SynapseML** pour le machine learning distribué sur grandes données.

```
ML Stack in Fabric:
┌─────────────────────────────────────────┐
│  Scikit-learn, PyTorch, TensorFlow      │
│  (via Pandas UDFs for distributed)      │
├─────────────────────────────────────────┤
│  SynapseML                              │
│  ├─ Deep Learning (ONNX, Cognitive)     │
│  ├─ LightGBM                            │
│  └─ OpenCV                              │
├─────────────────────────────────────────┤
│  Spark MLlib                            │
│  ├─ ML Algorithms                       │
│  ├─ Feature Engineering                 │
│  ├─ Pipelines                           │
│  └─ Model Evaluation                    │
├─────────────────────────────────────────┤
│  Spark DataFrames (distributed data)    │
└─────────────────────────────────────────┘
```

## Spark MLlib Basics

### Feature Engineering

**VectorAssembler:**
```python
from pyspark.ml.feature import VectorAssembler

# Combine features into vector
assembler = VectorAssembler(
    inputCols=["age", "income", "credit_score"],
    outputCol="features"
)

df_features = assembler.transform(df)
df_features.select("features").show(truncate=False)
```

**StringIndexer:**
```python
from pyspark.ml.feature import StringIndexer

# Encode categorical to numeric
indexer = StringIndexer(inputCol="country", outputCol="country_index")
model = indexer.fit(df)
df_indexed = model.transform(df)

df_indexed.select("country", "country_index").show()
```

**OneHotEncoder:**
```python
from pyspark.ml.feature import OneHotEncoder

# One-hot encode categorical
encoder = OneHotEncoder(inputCol="country_index", outputCol="country_vec")
df_encoded = encoder.fit(df_indexed).transform(df_indexed)

df_encoded.select("country", "country_vec").show(truncate=False)
```

**Normalization:**
```python
from pyspark.ml.feature import StandardScaler, MinMaxScaler

# StandardScaler (mean=0, std=1)
scaler = StandardScaler(
    inputCol="features",
    outputCol="scaled_features",
    withMean=True,
    withStd=True
)

scaler_model = scaler.fit(df_features)
df_scaled = scaler_model.transform(df_features)

# MinMaxScaler (range [0, 1])
minmax = MinMaxScaler(inputCol="features", outputCol="scaled_features")
df_minmax = minmax.fit(df_features).transform(df_features)
```

**Bucketing:**
```python
from pyspark.ml.feature import Bucketizer

# Discretize continuous variable
bucketizer = Bucketizer(
    splits=[-float("inf"), 25, 35, 50, float("inf")],
    inputCol="age",
    outputCol="age_bucket"
)

df_bucketed = bucketizer.transform(df)
df_bucketed.select("age", "age_bucket").show()
```

### ML Pipelines

**Creating Pipeline:**
```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, VectorAssembler
from pyspark.ml.classification import LogisticRegression

# Define stages
indexer = StringIndexer(inputCol="category", outputCol="category_index")
assembler = VectorAssembler(
    inputCols=["age", "income", "category_index"],
    outputCol="features"
)
lr = LogisticRegression(featuresCol="features", labelCol="label")

# Create pipeline
pipeline = Pipeline(stages=[indexer, assembler, lr])

# Fit pipeline
model = pipeline.fit(train_df)

# Transform with fitted pipeline
predictions = model.transform(test_df)
```

## Classification

### Logistic Regression

```python
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# Prepare data
train, test = df_features.randomSplit([0.8, 0.2], seed=42)

# Train model
lr = LogisticRegression(
    featuresCol="features",
    labelCol="label",
    maxIter=10,
    regParam=0.01
)

lr_model = lr.fit(train)

# Predict
predictions = lr_model.transform(test)
predictions.select("features", "label", "prediction", "probability").show()

# Evaluate
evaluator = BinaryClassificationEvaluator(labelCol="label")
auc = evaluator.evaluate(predictions)
print(f"AUC: {auc:.4f}")

# Coefficients
print("Coefficients:", lr_model.coefficients)
print("Intercept:", lr_model.intercept)
```

### Random Forest

```python
from pyspark.ml.classification import RandomForestClassifier

# Train Random Forest
rf = RandomForestClassifier(
    featuresCol="features",
    labelCol="label",
    numTrees=100,
    maxDepth=5,
    seed=42
)

rf_model = rf.fit(train)

# Predict
predictions = rf_model.transform(test)

# Feature importance
print("Feature Importance:", rf_model.featureImportances)

# Evaluate
from pyspark.ml.evaluation import MulticlassClassificationEvaluator

evaluator = MulticlassClassificationEvaluator(
    labelCol="label",
    predictionCol="prediction",
    metricName="accuracy"
)

accuracy = evaluator.evaluate(predictions)
print(f"Accuracy: {accuracy:.4f}")
```

### Gradient Boosted Trees

```python
from pyspark.ml.classification import GBTClassifier

gbt = GBTClassifier(
    featuresCol="features",
    labelCol="label",
    maxIter=100,
    maxDepth=5
)

gbt_model = gbt.fit(train)
predictions = gbt_model.transform(test)
```

## Regression

### Linear Regression

```python
from pyspark.ml.regression import LinearRegression
from pyspark.ml.evaluation import RegressionEvaluator

# Train model
lr = LinearRegression(
    featuresCol="features",
    labelCol="price",
    maxIter=10,
    regParam=0.3,
    elasticNetParam=0.8
)

lr_model = lr.fit(train)

# Predict
predictions = lr_model.transform(test)

# Metrics
print(f"RMSE: {lr_model.summary.rootMeanSquaredError:.2f}")
print(f"R2: {lr_model.summary.r2:.4f}")

# Evaluate on test
evaluator = RegressionEvaluator(
    labelCol="price",
    predictionCol="prediction",
    metricName="rmse"
)

rmse = evaluator.evaluate(predictions)
print(f"Test RMSE: {rmse:.2f}")
```

### Random Forest Regression

```python
from pyspark.ml.regression import RandomForestRegressor

rf = RandomForestRegressor(
    featuresCol="features",
    labelCol="price",
    numTrees=100,
    maxDepth=5
)

rf_model = rf.fit(train)
predictions = rf_model.transform(test)

# Evaluate
evaluator = RegressionEvaluator(labelCol="price", metricName="r2")
r2 = evaluator.evaluate(predictions)
print(f"R2: {r2:.4f}")
```

## Clustering

### K-Means

```python
from pyspark.ml.clustering import KMeans

# Train K-Means
kmeans = KMeans(
    featuresCol="features",
    k=5,
    seed=42,
    maxIter=20
)

kmeans_model = kmeans.fit(df_features)

# Predict clusters
predictions = kmeans_model.transform(df_features)
predictions.select("features", "prediction").show()

# Cluster centers
centers = kmeans_model.clusterCenters()
for i, center in enumerate(centers):
    print(f"Cluster {i}: {center}")

# Inertia (sum of squared distances)
cost = kmeans_model.summary.trainingCost
print(f"Within Set Sum of Squared Errors: {cost:.2f}")
```

### Bisecting K-Means

```python
from pyspark.ml.clustering import BisectingKMeans

bkm = BisectingKMeans(featuresCol="features", k=5, seed=42)
bkm_model = bkm.fit(df_features)
predictions = bkm_model.transform(df_features)
```

## Model Evaluation

### Binary Classification Metrics

```python
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# AUC-ROC
evaluator = BinaryClassificationEvaluator(
    labelCol="label",
    rawPredictionCol="rawPrediction",
    metricName="areaUnderROC"
)

auc = evaluator.evaluate(predictions)
print(f"AUC-ROC: {auc:.4f}")

# AUC-PR
evaluator.setMetricName("areaUnderPR")
auc_pr = evaluator.evaluate(predictions)
print(f"AUC-PR: {auc_pr:.4f}")
```

### Multiclass Classification Metrics

```python
from pyspark.ml.evaluation import MulticlassClassificationEvaluator

# Accuracy
evaluator = MulticlassClassificationEvaluator(
    labelCol="label",
    predictionCol="prediction",
    metricName="accuracy"
)

accuracy = evaluator.evaluate(predictions)
print(f"Accuracy: {accuracy:.4f}")

# Weighted Precision
evaluator.setMetricName("weightedPrecision")
precision = evaluator.evaluate(predictions)
print(f"Precision: {precision:.4f}")

# Weighted Recall
evaluator.setMetricName("weightedRecall")
recall = evaluator.evaluate(predictions)
print(f"Recall: {recall:.4f}")

# F1 Score
evaluator.setMetricName("f1")
f1 = evaluator.evaluate(predictions)
print(f"F1: {f1:.4f}")
```

### Regression Metrics

```python
from pyspark.ml.evaluation import RegressionEvaluator

# RMSE
evaluator = RegressionEvaluator(
    labelCol="price",
    predictionCol="prediction",
    metricName="rmse"
)

rmse = evaluator.evaluate(predictions)
print(f"RMSE: {rmse:.2f}")

# R2
evaluator.setMetricName("r2")
r2 = evaluator.evaluate(predictions)
print(f"R2: {r2:.4f}")

# MAE
evaluator.setMetricName("mae")
mae = evaluator.evaluate(predictions)
print(f"MAE: {mae:.2f}")
```

## Cross-Validation

### Grid Search

```python
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# Build parameter grid
paramGrid = ParamGridBuilder() \
    .addGrid(lr.regParam, [0.01, 0.1, 0.5]) \
    .addGrid(lr.maxIter, [5, 10, 20]) \
    .build()

# Cross-validator
crossval = CrossValidator(
    estimator=lr,
    estimatorParamMaps=paramGrid,
    evaluator=BinaryClassificationEvaluator(),
    numFolds=5,
    seed=42
)

# Fit
cv_model = crossval.fit(train)

# Best model
best_model = cv_model.bestModel
print("Best regParam:", best_model._java_obj.getRegParam())
print("Best maxIter:", best_model._java_obj.getMaxIter())

# Predict with best model
predictions = cv_model.transform(test)
```

### Train-Validation Split

```python
from pyspark.ml.tuning import TrainValidationSplit

# Train-validation split (faster than cross-validation)
tvs = TrainValidationSplit(
    estimator=lr,
    estimatorParamMaps=paramGrid,
    evaluator=BinaryClassificationEvaluator(),
    trainRatio=0.8,
    seed=42
)

tvs_model = tvs.fit(train)
predictions = tvs_model.transform(test)
```

## SynapseML

### LightGBM

```python
from synapse.ml.lightgbm import LightGBMClassifier

# Train LightGBM (gradient boosting, very fast)
lgbm = LightGBMClassifier(
    featuresCol="features",
    labelCol="label",
    numIterations=100,
    learningRate=0.1,
    numLeaves=31,
    objective="binary"
)

lgbm_model = lgbm.fit(train)
predictions = lgbm_model.transform(test)

# Feature importance
print(lgbm_model.getFeatureImportances())
```

### Cognitive Services

```python
from synapse.ml.cognitive import TextSentiment

# Sentiment analysis (requires Azure Cognitive Services)
sentiment = TextSentiment(
    textCol="review_text",
    outputCol="sentiment",
    subscriptionKey="YOUR_KEY",
    location="eastus"
)

# Analyze sentiment
result = sentiment.transform(df)
result.select("review_text", "sentiment.document.sentiment").show()
```

### ONNX Models

```python
from synapse.ml.onnx import ONNXModel

# Load pre-trained ONNX model
onnx_model = ONNXModel() \
    .setModelLocation("path/to/model.onnx") \
    .setFeedDict({"input": "features"}) \
    .setFetchDict({"output": "prediction"})

# Predict
predictions = onnx_model.transform(df)
```

## Distributed Scikit-learn

### Pandas UDF for Distributed Training

```python
from pyspark.sql.functions import pandas_udf, PandasUDFType
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

# Train model per partition
@pandas_udf("double", PandasUDFType.SCALAR)
def train_and_predict(features: pd.Series) -> pd.Series:
    # This runs on each partition
    X_train = ...  # Extract features
    y_train = ...  # Extract labels

    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train)

    predictions = model.predict(features)
    return pd.Series(predictions)

# Apply to DataFrame
df.withColumn("prediction", train_and_predict(col("features")))
```

### GroupBy + Apply

```python
from pyspark.sql.functions import pandas_udf, PandasUDFType
from pyspark.sql.types import StructType, StructField, DoubleType

# Define schema for output
schema = StructType([
    StructField("customer_id", StringType()),
    StructField("prediction", DoubleType())
])

# Train model per group
@pandas_udf(schema, PandasUDFType.GROUPED_MAP)
def train_per_customer(pdf: pd.DataFrame) -> pd.DataFrame:
    from sklearn.linear_model import LinearRegression

    X = pdf[["feature1", "feature2"]].values
    y = pdf["target"].values

    model = LinearRegression()
    model.fit(X, y)

    predictions = model.predict(X)

    return pd.DataFrame({
        "customer_id": pdf["customer_id"],
        "prediction": predictions
    })

# Apply grouped model
result = df.groupBy("customer_id").apply(train_per_customer)
```

## Model Persistence

### Save MLlib Model

```python
# Save model
model.write().overwrite().save("Files/models/lr_model")

# Load model
from pyspark.ml.classification import LogisticRegressionModel

loaded_model = LogisticRegressionModel.load("Files/models/lr_model")
predictions = loaded_model.transform(test)
```

### Save Pipeline

```python
# Save entire pipeline
pipeline_model.write().overwrite().save("Files/models/pipeline")

# Load pipeline
from pyspark.ml import PipelineModel

loaded_pipeline = PipelineModel.load("Files/models/pipeline")
predictions = loaded_pipeline.transform(test)
```

### MLflow Integration

```python
import mlflow
import mlflow.spark

# Start MLflow run
with mlflow.start_run():
    # Train model
    model = lr.fit(train)

    # Log parameters
    mlflow.log_param("maxIter", lr.getMaxIter())
    mlflow.log_param("regParam", lr.getRegParam())

    # Log metrics
    predictions = model.transform(test)
    auc = evaluator.evaluate(predictions)
    mlflow.log_metric("auc", auc)

    # Log model
    mlflow.spark.log_model(model, "model")

# Load model from MLflow
logged_model = mlflow.spark.load_model("runs:/<run_id>/model")
```

## Best Practices

### ✅ Data Preparation

```python
# 1. Handle missing values
df = df.fillna({"age": 0, "income": df.agg({"income": "mean"}).collect()[0][0]})

# 2. Encode categoricals
from pyspark.ml.feature import StringIndexer

indexer = StringIndexer(inputCol="category", outputCol="category_index")

# 3. Assemble features
from pyspark.ml.feature import VectorAssembler

assembler = VectorAssembler(
    inputCols=["age", "income", "category_index"],
    outputCol="features"
)

# 4. Scale features
from pyspark.ml.feature import StandardScaler

scaler = StandardScaler(inputCol="features", outputCol="scaled_features")
```

### ✅ Model Selection

```python
# Use pipelines for reproducibility
from pyspark.ml import Pipeline

pipeline = Pipeline(stages=[indexer, assembler, scaler, model])
pipeline_model = pipeline.fit(train)

# Cross-validation for hyperparameters
from pyspark.ml.tuning import CrossValidator

cv = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=paramGrid,
    evaluator=evaluator,
    numFolds=5
)

cv_model = cv.fit(train)
```

### ✅ Performance

```python
# 1. Cache training data
train.cache()
train.count()  # Trigger caching

# 2. Repartition for balanced training
train = train.repartition(100)

# 3. Use checkpointing for iterative algorithms
spark.sparkContext.setCheckpointDir("Files/checkpoints")
```

## Points Clés

- MLlib = Spark's distributed ML library
- Pipelines: chain feature engineering + model training
- Classification: LogisticRegression, RandomForest, GBT
- Regression: LinearRegression, RandomForestRegressor
- Clustering: KMeans, BisectingKMeans
- Feature engineering: VectorAssembler, StringIndexer, OneHotEncoder, StandardScaler
- Cross-validation: ParamGridBuilder + CrossValidator
- SynapseML: LightGBM, Cognitive Services, ONNX
- Model persistence: save/load with MLflow
- Best practices: pipelines, caching, hyperparameter tuning

---

**Prochain fichier :** [08 - Best Practices](./08-best-practices.md)

[⬅️ Fichier précédent](./06-performance-optimization.md) | [⬅️ Retour au README du module](./README.md)
