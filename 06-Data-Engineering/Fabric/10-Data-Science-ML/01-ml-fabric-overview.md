# ML dans Fabric Overview

## Introduction

**Data Science dans Microsoft Fabric** offre un environnement intégré pour le machine learning, de l'exploration des données au déploiement de modèles.

```
ML Architecture in Fabric:
┌─────────────────────────────────────────────┐
│  Lakehouse Data                             │
│  ├─ Raw data (Bronze)                       │
│  ├─ Cleaned data (Silver)                   │
│  └─ Feature data (Gold)                     │
├─────────────────────────────────────────────┤
│  Data Science Workload                      │
│  ├─ Notebooks (PySpark, Python)             │
│  ├─ MLflow (experiment tracking)            │
│  ├─ AutoML (automated modeling)             │
│  └─ Model Registry (versioning)             │
├─────────────────────────────────────────────┤
│  Deployment & Serving                       │
│  ├─ Batch scoring (pipelines)               │
│  └─ Real-time endpoints (API)               │
└─────────────────────────────────────────────┘
```

## Data Science Workload

### Capabilities

```
Fabric Data Science offers:

✅ Unified platform (no tool switching)
✅ Scalable compute (Spark clusters)
✅ Pre-installed ML libraries
✅ MLflow integration
✅ AutoML for quick modeling
✅ Direct Lakehouse access
✅ GPU support (for deep learning)
✅ Collaborative notebooks

End-to-end workflow:
  Data → Features → Training → Tracking → Deployment → Monitoring
  All within single environment
```

### Key Components

```
1. Data Science Notebooks
   • Interactive development
   • Multiple languages (Python, Spark)
   • Visualizations inline
   • Version control

2. Experiments
   • Track ML runs
   • Compare models
   • Log parameters/metrics
   • Store artifacts

3. Models
   • Model registry
   • Version management
   • Stage transitions
   • Deployment ready

4. ML Items
   • Datasets
   • Feature sets
   • Trained models
   • Scoring scripts
```

## Integration avec Lakehouse

### Data Access

```python
# Direct access to Lakehouse tables

# Read from Lakehouse
df = spark.read.format("delta").load("Tables/customer_features")

# Or using table name
df = spark.table("customer_features")

# Write predictions back
predictions.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("predictions_churn")

Benefits:
  ✅ No data movement needed
  ✅ Delta Lake features (ACID, time travel)
  ✅ Scalable reads with Spark
  ✅ Unified storage layer
```

### Data Exploration

```python
# Explore data before modeling

# Basic statistics
df.describe().show()

# Data profiling
from pyspark.sql import functions as F

profile = df.select([
    F.count("*").alias("total_rows"),
    F.count("customer_id").alias("non_null_customers"),
    F.avg("age").alias("avg_age"),
    F.min("signup_date").alias("earliest_signup"),
    F.max("last_purchase").alias("latest_purchase")
])
profile.show()

# Check for imbalance (classification)
df.groupBy("churn").count().show()
# churn | count
# 0     | 8500
# 1     | 1500
# Imbalanced dataset - need to handle
```

### Feature Storage

```python
# Store features for reuse

# Create feature table
customer_features = df.select(
    "customer_id",
    "age",
    "tenure_months",
    "total_purchases",
    "avg_order_value",
    "recency_days"
)

# Save as Delta table
customer_features.write.format("delta") \
    .mode("overwrite") \
    .option("overwriteSchema", "true") \
    .saveAsTable("feature_store.customer_features")

# Time-versioned with Delta Lake
# Can retrieve features at any point in time
```

## Notebooks pour Data Science

### Creating DS Notebook

```
Steps:
1. Workspace → + New → Notebook
2. Select default Lakehouse
3. Choose language (PySpark recommended)
4. Start coding

Notebook interface:
  ┌──────────────────────────────┐
  │ Lakehouse Explorer (left)    │
  │ Code cells (center)          │
  │ Variable explorer (right)    │
  │ Outputs inline               │
  └──────────────────────────────┘
```

### Example Notebook Structure

```python
# Cell 1: Setup
import mlflow
import mlflow.sklearn
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

# Cell 2: Load data
df = spark.table("customers")
print(f"Total records: {df.count()}")

# Cell 3: Feature engineering
from pyspark.sql import functions as F

features_df = df.withColumn(
    "customer_lifetime_value",
    F.col("total_purchases") * F.col("avg_order_value")
)

# Cell 4: Convert to Pandas for sklearn
pandas_df = features_df.toPandas()
X = pandas_df[["age", "tenure", "clv"]]
y = pandas_df["churn"]

# Cell 5: Train model
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# Cell 6: Evaluate
accuracy = model.score(X_test, y_test)
print(f"Accuracy: {accuracy:.4f}")
```

### Visualizations

```python
# Inline visualizations

import matplotlib.pyplot as plt
import seaborn as sns

# Feature distribution
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

axes[0, 0].hist(df["age"], bins=30)
axes[0, 0].set_title("Age Distribution")

axes[0, 1].boxplot(df["tenure_months"])
axes[0, 1].set_title("Tenure Months")

sns.heatmap(df.corr(), annot=True, ax=axes[1, 0])
axes[1, 0].set_title("Feature Correlation")

df["churn"].value_counts().plot(kind="pie", ax=axes[1, 1])
axes[1, 1].set_title("Churn Distribution")

plt.tight_layout()
plt.show()

# Displays directly in notebook
```

## Libraries ML Pré-installées

### Available Libraries

```python
# Pre-installed ML libraries

# Scikit-learn (traditional ML)
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC

# XGBoost (gradient boosting)
import xgboost as xgb
from xgboost import XGBClassifier

# LightGBM (fast gradient boosting)
import lightgbm as lgb
from lightgbm import LGBMClassifier

# CatBoost (categorical features)
from catboost import CatBoostClassifier

# Deep Learning
import tensorflow as tf
import torch
import keras

# NLP
from transformers import pipeline, AutoModelForSequenceClassification

# Computer Vision
import cv2
from PIL import Image
```

### Installing Additional Libraries

```python
# Install custom library (session-scoped)
%pip install shap

# Then use
import shap

# Or system-wide (requires admin)
# Configure in environment settings

# Common additional libraries:
# - SHAP (model interpretation)
# - LIME (local explanations)
# - category_encoders (advanced encoding)
# - imbalanced-learn (SMOTE, oversampling)
```

## GPU Support

### When to Use GPU

```
Use GPU for:
  ✅ Deep learning (neural networks)
  ✅ Large-scale image processing
  ✅ NLP with transformers
  ✅ Large matrix operations

Don't need GPU for:
  ❌ Traditional ML (Random Forest, XGBoost)
  ❌ Small datasets
  ❌ Simple preprocessing
  ❌ Most tabular data tasks

Cost consideration:
  GPU compute more expensive
  Use only when necessary
  Monitor usage
```

### Configuring GPU

```python
# Check GPU availability

import torch
print(f"GPU available: {torch.cuda.is_available()}")
print(f"GPU count: {torch.cuda.device_count()}")

# TensorFlow GPU
import tensorflow as tf
print(f"GPUs: {tf.config.list_physical_devices('GPU')}")

# Use GPU in training
model = model.to('cuda')  # PyTorch
# TensorFlow auto-detects

# Memory management
torch.cuda.empty_cache()  # Clear GPU memory
```

## Comparaison avec Azure ML

### Similarities

```
Both offer:
  ✅ Notebook-based development
  ✅ MLflow tracking
  ✅ Model registry
  ✅ AutoML capabilities
  ✅ Scalable compute
  ✅ GPU support

Shared concepts:
  • Experiments
  • Runs
  • Models
  • Endpoints
```

### Differences

```
Feature              │ Fabric DS        │ Azure ML
─────────────────────┼──────────────────┼─────────────────
Data storage         │ OneLake          │ Azure Blob
Primary compute      │ Spark            │ Compute clusters
Integration          │ Fabric ecosystem │ Azure services
Complexity           │ Simpler          │ More features
Real-time endpoints  │ Limited          │ Full support
MLOps                │ Basic            │ Advanced
Target users         │ Data engineers   │ ML engineers

Choose Fabric when:
  • Already using Fabric for data
  • Need Lakehouse integration
  • Simpler ML workflows
  • Data engineering focus

Choose Azure ML when:
  • Complex MLOps requirements
  • Advanced deployment needs
  • Dedicated ML team
  • Heavy real-time serving
```

### Migration Path

```
Fabric to Azure ML:

Export model from Fabric:
  MLflow model → Download artifact

Import to Azure ML:
  Azure ML workspace → Register model
  Use same MLflow format

Gradual adoption:
  Start with Fabric (prototyping)
  Mature to Azure ML (production ML)
  Both can coexist
```

## Best Practices

### Project Structure

```
Recommended notebook organization:

1. 01_data_exploration.ipynb
   • Data profiling
   • Quality checks
   • Initial visualizations

2. 02_feature_engineering.ipynb
   • Feature creation
   • Transformations
   • Feature store updates

3. 03_model_training.ipynb
   • Model experiments
   • Hyperparameter tuning
   • MLflow logging

4. 04_model_evaluation.ipynb
   • Model comparison
   • Performance metrics
   • Interpretation (SHAP)

5. 05_deployment.ipynb
   • Model registration
   • Scoring pipeline
   • Monitoring setup

Clear separation
Reproducible workflow
Easy collaboration
```

### Development Workflow

```
1. Start with Lakehouse data
   Explore, profile, understand

2. Feature engineering
   Create meaningful features
   Store in feature tables

3. Experimentation
   Try multiple algorithms
   Track with MLflow
   Compare results

4. Model selection
   Choose best performer
   Validate on holdout set
   Document decision

5. Production pipeline
   Automate scoring
   Schedule predictions
   Monitor performance

6. Continuous improvement
   Retrain periodically
   Monitor drift
   Update features
```

### Common Pitfalls

```
❌ Not using version control
  Notebooks not tracked
  Can't reproduce results
  Use Git integration

❌ Training on full Spark DataFrame
  Slow for sklearn
  Convert to Pandas for traditional ML
  Use Spark MLlib for distributed

❌ Ignoring data leakage
  Using future information
  Invalid train/test split
  Careful with time-series

❌ No experiment tracking
  Can't remember parameters
  Can't compare models
  Always use MLflow

❌ Skipping data validation
  Garbage in, garbage out
  Check distributions
  Handle missing values
```

## Example: End-to-End ML Project

### Complete Workflow

```python
# 1. Load and explore data
df = spark.table("customer_transactions")
df.printSchema()
df.describe().show()

# 2. Feature engineering
features_df = df.groupBy("customer_id").agg(
    F.count("*").alias("transaction_count"),
    F.sum("amount").alias("total_spent"),
    F.avg("amount").alias("avg_transaction"),
    F.max("date").alias("last_transaction")
).withColumn(
    "recency_days",
    F.datediff(F.current_date(), F.col("last_transaction"))
)

# Join with labels
training_df = features_df.join(
    spark.table("customer_churn"),
    "customer_id"
)

# 3. Prepare for modeling
pandas_df = training_df.toPandas()
X = pandas_df[["transaction_count", "total_spent", "avg_transaction", "recency_days"]]
y = pandas_df["churned"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 4. Train with MLflow tracking
with mlflow.start_run(run_name="churn_prediction"):
    model = RandomForestClassifier(n_estimators=100, max_depth=10)
    model.fit(X_train, y_train)

    accuracy = model.score(X_test, y_test)
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)
    mlflow.log_metric("accuracy", accuracy)
    mlflow.sklearn.log_model(model, "model")

    print(f"Model trained with accuracy: {accuracy:.4f}")

# 5. Register best model
mlflow.register_model(
    f"runs:/{mlflow.active_run().info.run_id}/model",
    "churn_predictor"
)

# 6. Batch scoring
from mlflow.pyfunc import spark_udf

predict_udf = spark_udf(spark, "models:/churn_predictor/Production")
new_customers = spark.table("new_customers")
predictions = new_customers.withColumn("churn_probability", predict_udf())
predictions.write.saveAsTable("churn_predictions")

print("Pipeline complete!")
```

## Points Clés

- Fabric Data Science provides end-to-end ML workflow
- Direct integration with Lakehouse data (Delta Lake)
- Notebooks for interactive development with inline visualizations
- Pre-installed ML libraries: sklearn, XGBoost, LightGBM, TensorFlow, PyTorch
- GPU support for deep learning workloads
- MLflow built-in for experiment tracking and model registry
- Compared to Azure ML: simpler, more integrated, less MLOps features
- Best practices: Organized notebooks, experiment tracking, feature reuse
- Common pitfalls: No version control, data leakage, skipping validation
- End-to-end: Data exploration → Features → Training → Tracking → Deployment

---

**Prochain fichier :** [02 - MLflow & Experiments](./02-mlflow-experiments.md)

[⬅️ Retour au README du module](./README.md)
