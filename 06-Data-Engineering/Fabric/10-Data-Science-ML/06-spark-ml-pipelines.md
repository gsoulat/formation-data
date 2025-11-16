# Spark ML Pipelines

## Introduction

**Spark MLlib** fournit une API de pipelines pour créer des workflows ML distribuées, combinant préprocessing et modélisation dans une structure reproductible.

```
Spark ML Pipeline Architecture:
┌───────────────────────────────────────────────┐
│  Pipeline                                      │
│  ├─ Stage 1: StringIndexer (Transformer)      │
│  ├─ Stage 2: OneHotEncoder (Transformer)      │
│  ├─ Stage 3: VectorAssembler (Transformer)    │
│  ├─ Stage 4: StandardScaler (Estimator)       │
│  └─ Stage 5: LogisticRegression (Estimator)   │
└───────────────────────────────────────────────┘
        ↓ fit(train_data)
┌───────────────────────────────────────────────┐
│  PipelineModel (fitted)                        │
│  ├─ StringIndexerModel                        │
│  ├─ OneHotEncoderModel                        │
│  ├─ VectorAssembler                           │
│  ├─ StandardScalerModel                       │
│  └─ LogisticRegressionModel                   │
└───────────────────────────────────────────────┘
        ↓ transform(test_data)
    Predictions
```

## Spark MLlib Overview

### What is Spark MLlib?

```
Spark MLlib:
  • Distributed ML library
  • Built on Spark DataFrames
  • Handles big data (billions of rows)
  • Pipeline-based API

Advantages:
  ✅ Scalable (cluster computing)
  ✅ Unified workflow (data + ML)
  ✅ Production ready
  ✅ Reproducible pipelines
  ✅ Built-in parallelization

When to use:
  • Data too large for single machine
  • Need distributed training
  • Production ML pipelines
  • Integration with Spark ecosystem
```

### MLlib vs Scikit-learn

```
Feature            │ Spark MLlib      │ Scikit-learn
───────────────────┼──────────────────┼─────────────
Data size          │ Billions of rows │ Millions max
Compute            │ Distributed      │ Single machine
Data structure     │ DataFrame        │ NumPy/Pandas
Training           │ Distributed      │ In-memory
Deep learning      │ Limited          │ Limited
Algorithm variety  │ Core ML          │ Extensive
Ease of use        │ More complex     │ Simpler

Recommendation:
  Small/medium data: Start with scikit-learn
  Large data: Use Spark MLlib
  Can combine: Feature eng in Spark, train with sklearn
```

## Transformers et Estimators

### Transformers

```python
# Transformers: Apply transformation to data

from pyspark.ml.feature import (
    StringIndexer,
    OneHotEncoder,
    VectorAssembler,
    StandardScaler,
    Bucketizer
)

# StringIndexer: Convert string to index
string_indexer = StringIndexer(
    inputCol="category",
    outputCol="category_index"
)
# "Electronics" → 0, "Clothing" → 1, "Food" → 2

# OneHotEncoder: One-hot encode indices
one_hot_encoder = OneHotEncoder(
    inputCols=["category_index"],
    outputCols=["category_vec"]
)
# 0 → [1, 0, 0], 1 → [0, 1, 0], 2 → [0, 0, 1]

# VectorAssembler: Combine features into vector
assembler = VectorAssembler(
    inputCols=["age", "income", "category_vec"],
    outputCol="features"
)
# Creates single feature vector for ML

# Bucketizer: Bin continuous variables
bucketizer = Bucketizer(
    splits=[0, 18, 35, 50, 65, float("inf")],
    inputCol="age",
    outputCol="age_bucket"
)
# Age bins: 0-18, 18-35, 35-50, 50-65, 65+
```

### Estimators

```python
# Estimators: Learn from data, then transform

from pyspark.ml.feature import StandardScaler, MinMaxScaler
from pyspark.ml.classification import LogisticRegression, RandomForestClassifier

# StandardScaler: Normalizes features (mean=0, std=1)
scaler = StandardScaler(
    inputCol="features",
    outputCol="scaled_features",
    withMean=True,
    withStd=True
)
# Learns mean/std from training data, applies to new data

# MinMaxScaler: Scale to [0, 1] range
min_max_scaler = MinMaxScaler(
    inputCol="features",
    outputCol="scaled_features"
)

# LogisticRegression: Binary classification
lr = LogisticRegression(
    featuresCol="scaled_features",
    labelCol="label",
    maxIter=100,
    regParam=0.01
)

# RandomForestClassifier: Ensemble model
rf = RandomForestClassifier(
    featuresCol="scaled_features",
    labelCol="label",
    numTrees=100,
    maxDepth=10
)
```

### Transformer vs Estimator

```
Transformer:
  • Has transform() method
  • Applies same transformation to any data
  • Example: VectorAssembler, StringIndexer

Estimator:
  • Has fit() method
  • Learns parameters from data
  • fit() returns a Transformer (fitted model)
  • Example: StandardScaler, LogisticRegression

Flow:
  Estimator.fit(train_data) → Transformer
  Transformer.transform(new_data) → Output
```

## Pipeline API

### Creating Pipeline

```python
from pyspark.ml import Pipeline

# Define stages
stages = [
    # 1. String indexing
    StringIndexer(inputCol="category", outputCol="category_idx"),

    # 2. One-hot encoding
    OneHotEncoder(inputCols=["category_idx"], outputCols=["category_vec"]),

    # 3. Assemble features
    VectorAssembler(
        inputCols=["age", "income", "category_vec"],
        outputCol="features"
    ),

    # 4. Scale features
    StandardScaler(inputCol="features", outputCol="scaled_features"),

    # 5. Train classifier
    LogisticRegression(featuresCol="scaled_features", labelCol="label")
]

# Create pipeline
pipeline = Pipeline(stages=stages)

# Fit pipeline on training data
pipeline_model = pipeline.fit(train_df)

# Transform test data
predictions = pipeline_model.transform(test_df)

# Full preprocessing + prediction in single transform()
```

### Pipeline Benefits

```
Why use pipelines?

1. Reproducibility
   Same preprocessing for train and test
   No train-test leakage
   Consistent transformations

2. Simplicity
   Encapsulate entire workflow
   Single object to save/load
   Easy to deploy

3. Automation
   fit() trains everything
   transform() applies everything
   No manual step tracking

4. Tuning
   Tune entire pipeline with CrossValidator
   Grid search over all stages
   Optimal hyperparameters

Example of leakage prevention:
  # Wrong (leakage):
  scaler.fit(full_data)  # Uses test data!
  train_scaled = scaler.transform(train_data)
  test_scaled = scaler.transform(test_data)

  # Right (pipeline):
  pipeline.fit(train_data)  # Only sees train
  # Scaler fitted on train, applied to test correctly
```

## Feature Engineering avec Spark

### String Handling

```python
from pyspark.ml.feature import StringIndexer, IndexToString

# StringIndexer with unknown handling
indexer = StringIndexer(
    inputCol="product_category",
    outputCol="category_idx",
    handleInvalid="keep"  # Assign index to unknown
)

# IndexToString: Reverse indexer (for interpretation)
converter = IndexToString(
    inputCol="prediction",
    outputCol="predicted_label",
    labels=["No Churn", "Churn"]
)

# Usage in pipeline
train_df = indexer.fit(train_df).transform(train_df)
# 'Electronics' → 0
# 'Clothing' → 1
# 'Unknown' → 2 (if seen at test time)
```

### Numerical Features

```python
from pyspark.ml.feature import (
    QuantileDiscretizer,
    PolynomialExpansion,
    Interaction
)

# QuantileDiscretizer: Equal-frequency bins
discretizer = QuantileDiscretizer(
    numBuckets=10,  # Deciles
    inputCol="income",
    outputCol="income_bucket"
)

# PolynomialExpansion: Polynomial features
poly = PolynomialExpansion(
    degree=2,
    inputCol="features",
    outputCol="poly_features"
)
# [a, b] → [a, b, a², ab, b²]

# Interaction: Feature interactions
interaction = Interaction(
    inputCols=["age_vec", "income_vec"],
    outputCol="age_income_interaction"
)
```

### Text Features

```python
from pyspark.ml.feature import (
    Tokenizer,
    HashingTF,
    IDF,
    Word2Vec
)

# Tokenizer: Split text into words
tokenizer = Tokenizer(
    inputCol="review_text",
    outputCol="words"
)

# HashingTF: Term frequency
hashing_tf = HashingTF(
    inputCol="words",
    outputCol="raw_features",
    numFeatures=10000
)

# IDF: Inverse document frequency
idf = IDF(
    inputCol="raw_features",
    outputCol="tfidf_features"
)

# Word2Vec: Word embeddings
word2vec = Word2Vec(
    inputCol="words",
    outputCol="word_embeddings",
    vectorSize=100,
    minCount=5
)

# Complete NLP pipeline
nlp_pipeline = Pipeline(stages=[
    tokenizer,
    hashing_tf,
    idf,
    # Then classifier...
])
```

## Training Distribué

### How Spark Distributes Training

```
Distributed training in Spark:

Data partitioning:
  Training data split across cluster nodes
  Each node processes local partition

Algorithm parallelization:
  • Tree-based: Build trees in parallel
  • Linear models: Distributed gradient descent
  • K-means: Parallel distance calculations

Example: RandomForest
  Spark RandomForestClassifier:
    - Data split across executors
    - Each executor builds subset of trees
    - Trees combined into forest
    - Automatic parallelization

  Configuration:
    rf = RandomForestClassifier(
        numTrees=100,  # Distributed across nodes
        maxDepth=15,
        seed=42
    )
```

### Performance Considerations

```python
# Optimize distributed training

# 1. Repartition for balanced load
train_df = train_df.repartition(100)  # Adjust based on cluster size

# 2. Cache frequently used DataFrame
train_df.cache()
train_df.count()  # Force caching

# 3. Broadcast small tables
from pyspark.sql.functions import broadcast
joined_df = large_df.join(broadcast(small_lookup), "key")

# 4. Optimize shuffle partitions
spark.conf.set("spark.sql.shuffle.partitions", 100)

# 5. Choose algorithm wisely
# Fast: RandomForest, GBTClassifier
# Slow: Some linear models with many iterations
# Very slow: CrossValidator with large grid

# 6. Use sample for experimentation
sample_df = train_df.sample(fraction=0.1, seed=42)
# Prototype on 10%, then scale to 100%
```

## Hyperparameter Tuning

### CrossValidator

```python
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# Define model
lr = LogisticRegression(
    featuresCol="features",
    labelCol="label"
)

# Parameter grid
param_grid = ParamGridBuilder() \
    .addGrid(lr.regParam, [0.001, 0.01, 0.1]) \
    .addGrid(lr.elasticNetParam, [0.0, 0.5, 1.0]) \
    .addGrid(lr.maxIter, [50, 100, 200]) \
    .build()

# 3 × 3 × 3 = 27 combinations

# Evaluator
evaluator = BinaryClassificationEvaluator(
    labelCol="label",
    metricName="areaUnderROC"
)

# CrossValidator
cv = CrossValidator(
    estimator=lr,
    estimatorParamMaps=param_grid,
    evaluator=evaluator,
    numFolds=5  # 5-fold cross-validation
)

# Total: 27 param combos × 5 folds = 135 model fits!

# Fit CrossValidator
cv_model = cv.fit(train_df)

# Best model
best_model = cv_model.bestModel
print(f"Best regParam: {best_model.getRegParam()}")
print(f"Best elasticNetParam: {best_model.getElasticNetParam()}")
```

### TrainValidationSplit

```python
from pyspark.ml.tuning import TrainValidationSplit

# Faster alternative to CrossValidator (single split)
tvs = TrainValidationSplit(
    estimator=lr,
    estimatorParamMaps=param_grid,
    evaluator=evaluator,
    trainRatio=0.8  # 80% train, 20% validation
)

# 27 param combos × 1 split = 27 model fits (faster!)

tvs_model = tvs.fit(train_df)

# Use when:
# - Large dataset (cross-validation too slow)
# - Quick experimentation
# - Enough data for single split
```

### Pipeline Tuning

```python
# Tune entire pipeline, not just model

pipeline = Pipeline(stages=[
    StringIndexer(...),
    VectorAssembler(...),
    StandardScaler(...),
    RandomForestClassifier(...)
])

# Grid includes preprocessing parameters
param_grid = ParamGridBuilder() \
    .addGrid(pipeline.getStages()[3].numTrees, [50, 100, 200]) \
    .addGrid(pipeline.getStages()[3].maxDepth, [5, 10, 15]) \
    .addGrid(pipeline.getStages()[2].withMean, [True, False]) \
    .build()

# CrossValidator on pipeline
cv = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=param_grid,
    evaluator=evaluator,
    numFolds=3
)

cv_model = cv.fit(train_df)
best_pipeline = cv_model.bestModel
```

## Model Persistence

### Save and Load Pipeline

```python
# Save trained pipeline
pipeline_model.write().overwrite().save("Models/churn_pipeline_v1")

# Or save to Lakehouse table path
pipeline_model.write().overwrite().save("abfss://...@onelake/Models/churn_pipeline_v1")

# Load later
from pyspark.ml import PipelineModel
loaded_pipeline = PipelineModel.load("Models/churn_pipeline_v1")

# Use for predictions
new_predictions = loaded_pipeline.transform(new_data)

# Save includes:
# - All transformers (StringIndexerModel, etc.)
# - All fitted estimators (ScalerModel, LRModel)
# - Pipeline structure
# - Metadata
```

### Version Control

```python
# Version models with metadata

import json
from datetime import datetime

model_version = "v2.1.0"
model_path = f"Models/churn_pipeline_{model_version}"

# Save model
pipeline_model.write().overwrite().save(model_path)

# Save metadata
metadata = {
    "version": model_version,
    "created_at": datetime.now().isoformat(),
    "training_data": "feature_store.customer_features",
    "auc_score": 0.8756,
    "accuracy": 0.8234,
    "features": ["age", "tenure", "recency", "frequency", "monetary"],
    "algorithm": "RandomForestClassifier",
    "hyperparameters": {
        "numTrees": 100,
        "maxDepth": 10
    },
    "author": "data_science_team"
}

# Save metadata as JSON
spark.sparkContext.parallelize([json.dumps(metadata)]) \
    .saveAsTextFile(f"{model_path}/metadata")

# Load with metadata
loaded_model = PipelineModel.load(model_path)
loaded_metadata = spark.read.text(f"{model_path}/metadata").collect()[0][0]
print(json.loads(loaded_metadata))
```

## Production Pipelines

### Complete Example

```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, VectorAssembler, StandardScaler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder
import mlflow

# 1. Load data
data = spark.table("feature_store.customer_features") \
    .join(spark.table("labels.churn"), "customer_id")

train_df, test_df = data.randomSplit([0.8, 0.2], seed=42)

# 2. Create pipeline
pipeline = Pipeline(stages=[
    StringIndexer(inputCol="country", outputCol="country_idx", handleInvalid="keep"),
    VectorAssembler(
        inputCols=["age", "tenure_months", "recency_days", "frequency", "monetary_total", "country_idx"],
        outputCol="features"
    ),
    StandardScaler(inputCol="features", outputCol="scaled_features"),
    RandomForestClassifier(featuresCol="scaled_features", labelCol="churned")
])

# 3. Hyperparameter tuning
param_grid = ParamGridBuilder() \
    .addGrid(pipeline.getStages()[3].numTrees, [100, 200]) \
    .addGrid(pipeline.getStages()[3].maxDepth, [10, 15]) \
    .build()

evaluator = BinaryClassificationEvaluator(labelCol="churned")

cv = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=param_grid,
    evaluator=evaluator,
    numFolds=5
)

# 4. Train with MLflow tracking
with mlflow.start_run(run_name="spark_ml_pipeline"):
    # Fit
    cv_model = cv.fit(train_df)
    best_model = cv_model.bestModel

    # Evaluate
    predictions = best_model.transform(test_df)
    auc = evaluator.evaluate(predictions)

    # Log to MLflow
    mlflow.log_param("algorithm", "RandomForestClassifier")
    mlflow.log_param("best_numTrees", best_model.stages[-1].getNumTrees)
    mlflow.log_param("best_maxDepth", best_model.stages[-1].getMaxDepth())
    mlflow.log_metric("auc", auc)

    # Save model
    best_model.write().overwrite().save("Models/production_pipeline")
    mlflow.log_artifact("Models/production_pipeline")

    print(f"Best AUC: {auc:.4f}")

# 5. Register for production
mlflow.register_model(
    f"runs:/{mlflow.active_run().info.run_id}/Models/production_pipeline",
    "ChurnPipeline_Spark"
)
```

### Batch Inference Pipeline

```python
# Scheduled production inference

def daily_churn_predictions():
    """Daily batch scoring with Spark Pipeline"""

    # Load production model
    model = PipelineModel.load("Models/production_pipeline")

    # Get new customers to score
    new_customers = spark.table("feature_store.customer_features") \
        .filter(F.col("needs_scoring") == True)

    # Score
    predictions = model.transform(new_customers) \
        .select(
            "customer_id",
            F.col("probability").getItem(1).alias("churn_probability"),
            F.current_timestamp().alias("scored_at")
        )

    # Save predictions
    predictions.write.format("delta") \
        .mode("append") \
        .saveAsTable("predictions.daily_churn")

    # Update scoring status
    spark.sql("""
        UPDATE feature_store.customer_features
        SET needs_scoring = False
        WHERE customer_id IN (SELECT customer_id FROM predictions.daily_churn)
    """)

    print(f"Scored {predictions.count()} customers")

# Schedule daily at 6 AM
```

## Points Clés

- Spark MLlib provides distributed ML on big data
- Transformers: Apply fixed transformations (StringIndexer, VectorAssembler)
- Estimators: Learn from data, produce transformers (StandardScaler, LogisticRegression)
- Pipeline: Chain stages for reproducible workflows
- Feature engineering: String handling, numerical transformations, text processing
- Distributed training: Automatic parallelization across cluster
- Hyperparameter tuning: CrossValidator, TrainValidationSplit, ParamGridBuilder
- Model persistence: Save entire pipeline, load for scoring
- Production: Combine with MLflow for tracking and registry
- Best practices: Cache data, optimize partitions, version models

---

**Module 10 complet!** Vous maîtrisez maintenant le Data Science et ML dans Fabric: MLflow, AutoML, Feature Store, déploiement de modèles, et Spark ML Pipelines.

[⬅️ Fichier précédent](./05-ml-models-deployment.md) | [⬅️ Retour au README du module](./README.md)
