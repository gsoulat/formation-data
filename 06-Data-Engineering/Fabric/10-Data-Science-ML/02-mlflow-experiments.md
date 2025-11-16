# MLflow & Experiments

## Introduction

**MLflow** est une plateforme open-source pour gérer le cycle de vie ML, intégrée nativement dans Microsoft Fabric pour le tracking, la reproductibilité et le déploiement.

```
MLflow Components:
┌─────────────────────────────────────────┐
│  MLflow Tracking                        │
│  ├─ Log parameters                      │
│  ├─ Log metrics                         │
│  ├─ Log artifacts                       │
│  └─ Compare experiments                 │
├─────────────────────────────────────────┤
│  MLflow Models                          │
│  ├─ Package models                      │
│  ├─ Model flavors                       │
│  └─ Deployment ready                    │
├─────────────────────────────────────────┤
│  Model Registry                         │
│  ├─ Version control                     │
│  ├─ Stage transitions                   │
│  └─ Annotations                         │
└─────────────────────────────────────────┘
```

## Introduction à MLflow

### Why MLflow?

```
Problems without MLflow:
  ❌ "Which parameters did I use?"
  ❌ "What was the accuracy of that model?"
  ❌ "How do I reproduce this result?"
  ❌ "Which model should we deploy?"

MLflow solves:
  ✅ Track all experiment details
  ✅ Compare model performance
  ✅ Reproduce any experiment
  ✅ Version and deploy models
  ✅ Collaborate with team

Key value:
  Single source of truth for ML experiments
  From experimentation to production
```

### MLflow in Fabric

```
Native integration:
  • Automatic experiment creation
  • UI for visualization
  • Model registry access
  • No additional setup

Access:
  Workspace → Experiments → Your experiment
  See all runs, metrics, parameters

Benefits:
  ✅ Pre-configured (no server setup)
  ✅ Integrated with Lakehouse
  ✅ Fabric permissions apply
  ✅ Shared with team automatically
```

## MLflow Tracking

### Starting an Experiment

```python
import mlflow

# Set experiment (creates if doesn't exist)
mlflow.set_experiment("customer_churn_prediction")

# Or use default (auto-created per notebook)
# Experiment name = notebook name

# View current experiment
experiment = mlflow.get_experiment_by_name("customer_churn_prediction")
print(f"Experiment ID: {experiment.experiment_id}")
print(f"Artifact location: {experiment.artifact_location}")
```

### Basic Tracking

```python
import mlflow

# Start a run
with mlflow.start_run(run_name="baseline_model"):

    # Your ML code here
    from sklearn.linear_model import LogisticRegression

    model = LogisticRegression(C=1.0, max_iter=100)
    model.fit(X_train, y_train)
    accuracy = model.score(X_test, y_test)

    # Log parameters (hyperparameters)
    mlflow.log_param("model_type", "LogisticRegression")
    mlflow.log_param("C", 1.0)
    mlflow.log_param("max_iter", 100)

    # Log metrics (performance)
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("train_size", len(X_train))
    mlflow.log_metric("test_size", len(X_test))

    print(f"Run completed with accuracy: {accuracy:.4f}")

# Run automatically ends at end of 'with' block
# All data persisted to MLflow tracking server
```

## Logging Parameters

### Scalar Parameters

```python
# Log individual parameters
mlflow.log_param("learning_rate", 0.01)
mlflow.log_param("batch_size", 32)
mlflow.log_param("epochs", 100)
mlflow.log_param("optimizer", "adam")

# Log multiple parameters at once
params = {
    "n_estimators": 200,
    "max_depth": 15,
    "min_samples_split": 5,
    "min_samples_leaf": 2,
    "random_state": 42
}
mlflow.log_params(params)

# Parameter types:
# - Numbers (int, float)
# - Strings
# - Booleans (logged as strings)
```

### Nested Parameters

```python
# For complex configurations

model_config = {
    "architecture": "transformer",
    "layers": 12,
    "hidden_size": 768,
    "attention_heads": 12
}

# Log as individual params
for key, value in model_config.items():
    mlflow.log_param(f"model_{key}", value)

# Or serialize to JSON string
import json
mlflow.log_param("model_config", json.dumps(model_config))

# Log preprocessing params separately
mlflow.log_param("preprocessing.scaler", "StandardScaler")
mlflow.log_param("preprocessing.imputer", "mean")
```

## Logging Metrics

### Performance Metrics

```python
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score

y_pred = model.predict(X_test)
y_proba = model.predict_proba(X_test)[:, 1]

# Classification metrics
mlflow.log_metric("accuracy", accuracy_score(y_test, y_pred))
mlflow.log_metric("precision", precision_score(y_test, y_pred))
mlflow.log_metric("recall", recall_score(y_test, y_pred))
mlflow.log_metric("f1_score", f1_score(y_test, y_pred))
mlflow.log_metric("roc_auc", roc_auc_score(y_test, y_proba))

# Regression metrics
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

mlflow.log_metric("mse", mean_squared_error(y_test, y_pred))
mlflow.log_metric("rmse", mean_squared_error(y_test, y_pred, squared=False))
mlflow.log_metric("mae", mean_absolute_error(y_test, y_pred))
mlflow.log_metric("r2", r2_score(y_test, y_pred))
```

### Training History (Step Metrics)

```python
# Log metrics over training epochs

for epoch in range(100):
    train_loss = train_one_epoch(model, train_loader)
    val_loss = evaluate(model, val_loader)

    # Log with step number
    mlflow.log_metric("train_loss", train_loss, step=epoch)
    mlflow.log_metric("val_loss", val_loss, step=epoch)

    # Early stopping check
    if val_loss < best_val_loss:
        best_val_loss = val_loss
        mlflow.log_metric("best_val_loss", best_val_loss, step=epoch)

# Creates time-series view in MLflow UI
# Can visualize training curves
```

### Custom Metrics

```python
# Business-specific metrics

# Customer churn: Cost of false negatives
def business_cost(y_true, y_pred):
    # False negative: Missed churning customer = $500 loss
    # False positive: Unnecessary retention effort = $50 cost
    fn_cost = 500
    fp_cost = 50

    fn = ((y_pred == 0) & (y_true == 1)).sum()
    fp = ((y_pred == 1) & (y_true == 0)).sum()

    return fn * fn_cost + fp * fp_cost

total_cost = business_cost(y_test, y_pred)
mlflow.log_metric("business_cost", total_cost)

# Fairness metrics
def demographic_parity(y_pred, protected_attr):
    rate_group_a = y_pred[protected_attr == 0].mean()
    rate_group_b = y_pred[protected_attr == 1].mean()
    return abs(rate_group_a - rate_group_b)

fairness = demographic_parity(y_pred, df["gender"])
mlflow.log_metric("demographic_parity_gap", fairness)
```

## Logging Artifacts

### Files and Visualizations

```python
import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay

# Generate confusion matrix plot
cm = confusion_matrix(y_test, y_pred)
disp = ConfusionMatrixDisplay(cm, display_labels=["No Churn", "Churn"])
disp.plot()

# Save figure
plt.savefig("confusion_matrix.png")

# Log as artifact
mlflow.log_artifact("confusion_matrix.png")

# Log multiple plots
plt.figure()
plt.plot(fpr, tpr)
plt.title("ROC Curve")
plt.savefig("roc_curve.png")
mlflow.log_artifact("roc_curve.png")

# All artifacts stored with run
# Downloadable from UI
```

### Feature Importance

```python
import pandas as pd

# Get feature importance
if hasattr(model, "feature_importances_"):
    importance_df = pd.DataFrame({
        "feature": feature_names,
        "importance": model.feature_importances_
    }).sort_values("importance", ascending=False)

    # Save as CSV
    importance_df.to_csv("feature_importance.csv", index=False)
    mlflow.log_artifact("feature_importance.csv")

    # Plot
    plt.figure(figsize=(10, 6))
    plt.barh(importance_df["feature"][:10], importance_df["importance"][:10])
    plt.title("Top 10 Feature Importance")
    plt.savefig("feature_importance.png")
    mlflow.log_artifact("feature_importance.png")
```

### Data Samples

```python
# Log sample of data for reproducibility

# Training data sample
train_sample = X_train.head(100)
train_sample.to_csv("train_sample.csv", index=False)
mlflow.log_artifact("train_sample.csv")

# Test predictions
predictions_df = pd.DataFrame({
    "actual": y_test,
    "predicted": y_pred,
    "probability": y_proba
})
predictions_df.to_csv("predictions.csv", index=False)
mlflow.log_artifact("predictions.csv")

# Misclassified examples
misclassified = X_test[y_test != y_pred]
misclassified.to_csv("misclassified.csv", index=False)
mlflow.log_artifact("misclassified.csv")
```

## MLflow Models

### Logging Models

```python
# Log trained model

# Scikit-learn
import mlflow.sklearn
mlflow.sklearn.log_model(model, "sklearn_model")

# XGBoost
import mlflow.xgboost
mlflow.xgboost.log_model(xgb_model, "xgboost_model")

# LightGBM
import mlflow.lightgbm
mlflow.lightgbm.log_model(lgb_model, "lightgbm_model")

# PyTorch
import mlflow.pytorch
mlflow.pytorch.log_model(pytorch_model, "pytorch_model")

# TensorFlow/Keras
import mlflow.tensorflow
mlflow.tensorflow.log_model(tf_model, "tensorflow_model")

# Generic Python function
import mlflow.pyfunc
mlflow.pyfunc.log_model("custom_model", python_model=my_custom_model)
```

### Model Input/Output Signature

```python
from mlflow.models.signature import infer_signature

# Infer signature from data
signature = infer_signature(X_train, y_pred)

# Log model with signature
mlflow.sklearn.log_model(
    model,
    "model_with_signature",
    signature=signature,
    input_example=X_train.head(5)
)

# Signature includes:
# - Input schema (feature names, types)
# - Output schema (prediction type)
# - Example input for testing

# Benefits:
# - Validates input at prediction time
# - Self-documenting model
# - Deployment safety
```

### Loading Models

```python
# Load model from run

run_id = "abc123..."  # From MLflow UI

# Load as original type
loaded_model = mlflow.sklearn.load_model(f"runs:/{run_id}/sklearn_model")

# Load as generic pyfunc
loaded_model = mlflow.pyfunc.load_model(f"runs:/{run_id}/sklearn_model")

# Use for prediction
predictions = loaded_model.predict(new_data)

# Load from artifact URI
model = mlflow.sklearn.load_model("file:///path/to/artifact/sklearn_model")
```

## Model Registry

### Registering Models

```python
# Register model after training

with mlflow.start_run():
    model.fit(X_train, y_train)
    mlflow.sklearn.log_model(model, "model")

    # Register to Model Registry
    mlflow.register_model(
        f"runs:/{mlflow.active_run().info.run_id}/model",
        "ChurnPredictor"  # Model name in registry
    )

# Or register existing model
result = mlflow.register_model(
    "runs:/abc123.../model",
    "ChurnPredictor"
)
print(f"Version: {result.version}")
```

### Model Versions

```python
from mlflow.tracking import MlflowClient

client = MlflowClient()

# List all versions
model_name = "ChurnPredictor"
versions = client.search_model_versions(f"name='{model_name}'")

for version in versions:
    print(f"Version {version.version}")
    print(f"  Stage: {version.current_stage}")
    print(f"  Run ID: {version.run_id}")
    print(f"  Created: {version.creation_timestamp}")

# Get specific version
model_version = client.get_model_version(model_name, version=2)
```

### Stage Transitions

```python
# Model lifecycle stages:
# None → Staging → Production → Archived

# Transition to Staging
client.transition_model_version_stage(
    name="ChurnPredictor",
    version=2,
    stage="Staging"
)

# After validation, promote to Production
client.transition_model_version_stage(
    name="ChurnPredictor",
    version=2,
    stage="Production",
    archive_existing_versions=True  # Archive old Production version
)

# Archive old model
client.transition_model_version_stage(
    name="ChurnPredictor",
    version=1,
    stage="Archived"
)
```

### Loading from Registry

```python
# Load model by stage (recommended for production)

# Latest Production version
production_model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")

# Latest Staging version
staging_model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Staging")

# Specific version
specific_model = mlflow.pyfunc.load_model("models:/ChurnPredictor/3")

# Use in scoring pipeline
predictions = production_model.predict(new_customer_data)
```

## Comparing Experiments

### MLflow UI

```
Access:
  Workspace → Experiments → Your experiment

Features:
  • Table view of all runs
  • Sort by metric (accuracy desc)
  • Filter by parameters
  • Compare selected runs
  • Visualize metric distributions

Comparison view:
  Run A vs Run B vs Run C
  Side-by-side parameter comparison
  Metric differences highlighted
  Overlaid training curves
```

### Programmatic Comparison

```python
# Search runs programmatically

runs = mlflow.search_runs(
    experiment_names=["customer_churn_prediction"],
    filter_string="metrics.accuracy > 0.8",
    order_by=["metrics.f1_score DESC"]
)

print(runs[["run_id", "params.model_type", "metrics.accuracy", "metrics.f1_score"]])

# Find best run
best_run = runs.iloc[0]
print(f"Best run: {best_run['run_id']}")
print(f"Accuracy: {best_run['metrics.accuracy']:.4f}")
print(f"F1 Score: {best_run['metrics.f1_score']:.4f}")

# Load best model
best_model = mlflow.sklearn.load_model(f"runs:/{best_run['run_id']}/model")
```

### Visualization

```python
# Compare runs visually

import pandas as pd
import matplotlib.pyplot as plt

# Get all runs
runs_df = mlflow.search_runs(experiment_ids=["1"])

# Plot accuracy vs F1 score by model type
fig, ax = plt.subplots(figsize=(10, 6))

for model_type in runs_df["params.model_type"].unique():
    subset = runs_df[runs_df["params.model_type"] == model_type]
    ax.scatter(
        subset["metrics.accuracy"],
        subset["metrics.f1_score"],
        label=model_type,
        s=100
    )

ax.set_xlabel("Accuracy")
ax.set_ylabel("F1 Score")
ax.legend()
plt.title("Model Comparison")
plt.show()
```

## Best Practices

### Experiment Organization

```
1. Meaningful experiment names
   "customer_churn_v2_feature_engineering"
   Not "experiment_1"

2. Descriptive run names
   "RandomForest_100trees_maxdepth10"
   "XGBoost_learning_rate_0.01"

3. Consistent parameter logging
   Always log same params for comparison
   Use standard naming convention

4. Log everything
   Parameters (even defaults)
   All relevant metrics
   Artifacts for debugging
   Data versioning info

5. Document in description
   mlflow.set_tag("mlflow.note.content",
                  "Testing feature engineering approach 2")
```

### Reproducibility

```python
# Ensure reproducible experiments

import random
import numpy as np

# Set random seeds
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# Log seeds
mlflow.log_param("random_seed", SEED)
mlflow.log_param("np_seed", SEED)

# Log data version
mlflow.log_param("data_version", "v2024-01-15")
mlflow.log_param("feature_set", "rfm_v3")

# Log environment
mlflow.log_param("sklearn_version", sklearn.__version__)
mlflow.log_param("python_version", sys.version)

# Save train/test split indices
mlflow.log_artifact("train_indices.npy")
mlflow.log_artifact("test_indices.npy")

# Complete reproducibility chain
```

### Common Mistakes

```
❌ Not logging enough
  Can't reproduce, can't debug
  Log more than you think you need

❌ Inconsistent metrics
  Accuracy in run 1, F1 in run 2
  Log all metrics for all runs

❌ Forgetting to end runs
  Always use 'with' statement
  Or explicitly call mlflow.end_run()

❌ No artifact cleanup
  Temporary files left behind
  Clean up after logging

❌ Not using registry
  Models scattered across runs
  Centralize in Model Registry
```

## Points Clés

- MLflow tracks parameters, metrics, artifacts, and models
- Experiments organize related runs for comparison
- Log parameters (hyperparameters) and metrics (performance)
- Artifacts store files: plots, data samples, feature importance
- Model logging supports multiple frameworks (sklearn, XGBoost, TensorFlow)
- Model Registry provides version control and stage management (Staging, Production)
- Compare runs in UI or programmatically to find best model
- Best practices: Meaningful names, consistent logging, reproducibility
- Common pitfalls: Under-logging, inconsistent metrics, not using registry
- Use stage transitions for controlled model deployment

---

**Prochain fichier :** [03 - AutoML Fabric](./03-automl-fabric.md)

[⬅️ Fichier précédent](./01-ml-fabric-overview.md) | [⬅️ Retour au README du module](./README.md)
