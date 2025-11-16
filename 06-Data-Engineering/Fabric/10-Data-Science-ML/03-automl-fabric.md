# AutoML Fabric

## Introduction

**AutoML** automatise le processus de machine learning, de la sélection d'algorithmes à l'optimisation d'hyperparamètres, rendant le ML accessible sans expertise approfondie.

```
AutoML Pipeline:
┌──────────┐   ┌───────────┐   ┌─────────────┐   ┌──────────┐
│   Data   │ → │  Feature  │ → │   Model     │ → │   Best   │
│  Input   │   │Engineering│   │  Selection  │   │  Model   │
└──────────┘   └───────────┘   └─────────────┘   └──────────┘
                    ↓               ↓
              Auto-transforms   Tries 50+ models
              Missing values    Hyperparameter tuning
              Encoding          Cross-validation
```

## Qu'est-ce qu'AutoML ?

### Traditional ML vs AutoML

```
Traditional ML workflow:
  1. Data preparation (manual)
  2. Feature engineering (expertise needed)
  3. Algorithm selection (trial and error)
  4. Hyperparameter tuning (grid/random search)
  5. Model evaluation (manual comparison)
  → Hours to days of work

AutoML workflow:
  1. Provide data
  2. Define task (classification, regression)
  3. Click "Run"
  4. Get best model
  → Minutes to hours

Time saved:
  Manual: 10+ hours
  AutoML: 30 minutes
  Result: Often comparable or better
```

### Benefits

```
✅ Democratizes ML (non-experts can use)
✅ Faster prototyping
✅ Explores more algorithms than manual
✅ Consistent methodology
✅ Reduces human bias in model selection
✅ Automatic feature engineering

Limitations:
⚠️ Black box (less interpretability)
⚠️ Compute intensive
⚠️ May not handle specialized domains
⚠️ Still requires domain knowledge for data prep
```

## Configuration AutoML dans Fabric

### Creating AutoML Experiment

```
Via Fabric Portal:
1. Workspace → + New → ML Experiment
2. Select "AutoML"
3. Configure:
   • Name: "ChurnPrediction_AutoML"
   • Task type: Classification
   • Dataset: customer_churn_data
   • Target column: churned
   • Time budget: 60 minutes

Via Notebook:
# Setup AutoML configuration programmatically
from fabric.automl import AutoMLConfig

config = AutoMLConfig(
    task="classification",
    training_data=train_df,
    label_column_name="churned",
    compute_target="spark_cluster",
    experiment_timeout_minutes=60,
    enable_early_stopping=True,
    n_cross_validations=5
)
```

### Dataset Selection

```python
# Prepare data for AutoML

# From Lakehouse table
training_data = spark.table("feature_store.customer_features")

# Join with labels
labeled_data = training_data.join(
    spark.table("customer_churn_labels"),
    "customer_id"
)

# Verify data quality
labeled_data.printSchema()
print(f"Rows: {labeled_data.count()}")
print(f"Columns: {len(labeled_data.columns)}")

# Check target distribution
labeled_data.groupBy("churned").count().show()

# AutoML handles:
# - Missing values (imputation)
# - Categorical encoding (auto-detected)
# - Feature scaling (normalized)
# You focus on: data quality and relevance
```

## Types de Tâches Supportées

### Classification

```python
# Binary Classification
AutoMLConfig(
    task="classification",
    training_data=train_df,
    label_column_name="churned",  # 0 or 1
    primary_metric="AUC_weighted"
)

# Multi-class Classification
AutoMLConfig(
    task="classification",
    training_data=train_df,
    label_column_name="product_category",  # A, B, C, D
    primary_metric="accuracy"
)

# Metrics available:
# - AUC_weighted (default)
# - accuracy
# - norm_macro_recall
# - average_precision_score_weighted
# - precision_score_weighted

Use cases:
  • Customer churn (binary)
  • Fraud detection (binary)
  • Product classification (multi-class)
  • Sentiment analysis (multi-class)
```

### Regression

```python
# Predict continuous values
AutoMLConfig(
    task="regression",
    training_data=train_df,
    label_column_name="sales_amount",
    primary_metric="r2_score"
)

# Metrics available:
# - r2_score (default)
# - normalized_mean_absolute_error
# - normalized_root_mean_squared_error
# - spearman_correlation

Use cases:
  • Sales forecasting
  • Price prediction
  • Demand estimation
  • Customer lifetime value
```

### Forecasting (Time Series)

```python
# Time series prediction
AutoMLConfig(
    task="forecasting",
    training_data=train_df,
    label_column_name="sales",
    time_column_name="date",
    forecast_horizon=30,  # Predict 30 days ahead
    primary_metric="normalized_root_mean_squared_error",
    target_lags=[1, 7, 30],  # Use 1, 7, 30 day lags as features
    target_rolling_window_size=7  # 7-day rolling average
)

# Time series features:
# - Lags (previous values)
# - Rolling windows (moving averages)
# - Calendar features (day, month, holiday)
# - Trend decomposition

Use cases:
  • Sales forecasting
  • Inventory planning
  • Resource demand
  • Financial projections
```

## Feature Engineering Automatique

### What AutoML Does

```
Automatic transformations:

1. Missing value imputation
   Numeric: Mean/median
   Categorical: Mode/new category

2. Categorical encoding
   One-hot encoding
   Label encoding
   Target encoding

3. Feature scaling
   StandardScaler
   MinMaxScaler
   RobustScaler

4. Feature generation
   Polynomial features
   Interaction terms
   Time-based features

5. Feature selection
   Remove low variance
   Remove highly correlated
   Importance-based selection

All transparent in results
```

### Custom Feature Engineering

```python
# Pre-process before AutoML

# Create custom features
from pyspark.sql import functions as F

engineered_df = train_df.withColumn(
    "age_category",
    F.when(F.col("age") < 30, "young")
     .when(F.col("age") < 50, "middle")
     .otherwise("senior")
).withColumn(
    "high_value_customer",
    F.when(F.col("total_spent") > 10000, 1).otherwise(0)
).withColumn(
    "tenure_to_age_ratio",
    F.col("tenure_months") / F.col("age")
)

# Let AutoML handle the rest
# Your domain knowledge + AutoML's optimization
# Best of both worlds
```

## Model Selection et Tuning

### Algorithms Tried

```
Classification algorithms:
  • LogisticRegression
  • RandomForest
  • GradientBoosting (LightGBM, XGBoost)
  • SVM
  • K-Nearest Neighbors
  • Decision Trees
  • Neural Networks
  • Ensemble methods

Regression algorithms:
  • LinearRegression
  • ElasticNet
  • RandomForest
  • GradientBoosting
  • SVR
  • Neural Networks

Forecasting:
  • Prophet
  • ARIMA
  • Exponential Smoothing
  • Machine learning models with time features
```

### Hyperparameter Optimization

```
Search strategies:

1. Bayesian optimization
   Smart search based on previous results
   More efficient than grid search

2. Random search
   Random combinations
   Good coverage of space

3. Early stopping
   Stop poorly performing runs
   Save compute resources

Configuration:
  n_trials: 50 (number of models to try)
  early_stopping: True
  timeout: 60 minutes
  cross_validation: 5-fold

Example trials:
  Trial 1: LightGBM(learning_rate=0.1, num_leaves=31)
  Trial 2: RandomForest(n_estimators=100, max_depth=10)
  Trial 3: XGBoost(max_depth=6, eta=0.3)
  ...
  Trial 50: LightGBM(learning_rate=0.05, num_leaves=63)

Best model selected based on primary metric
```

## Interprétabilité des Résultats

### Model Leaderboard

```
After AutoML completes:

Rank | Model                    | AUC    | Accuracy | Duration
-----|--------------------------|--------|----------|----------
1    | VotingEnsemble          | 0.8923 | 0.8456   | 2.3s
2    | StackEnsemble           | 0.8901 | 0.8432   | 3.1s
3    | LightGBMClassifier      | 0.8878 | 0.8398   | 1.2s
4    | XGBoostClassifier       | 0.8865 | 0.8387   | 1.8s
5    | RandomForestClassifier  | 0.8756 | 0.8234   | 0.9s

Insights:
  • Ensemble methods often win
  • Gradient boosting strong performer
  • Trade-off: performance vs interpretability
```

### Feature Importance

```python
# Get feature importance from best model

best_model = automl_run.get_best_model()

# If model supports feature_importances_
if hasattr(best_model, "feature_importances_"):
    importance = pd.DataFrame({
        "feature": feature_names,
        "importance": best_model.feature_importances_
    }).sort_values("importance", ascending=False)

    print("Top 10 important features:")
    print(importance.head(10))

# Visualization
importance.head(10).plot(kind="barh", x="feature", y="importance")
plt.title("Feature Importance")
plt.show()

# Insights:
# - tenure_months: 0.32 (most important)
# - total_spent: 0.24
# - recency_days: 0.18
# - age: 0.12
# Domain validation: Do these make sense?
```

### Model Explanations

```python
# SHAP values for interpretability

import shap

# Get best model
best_model = automl_run.get_best_model()

# Create SHAP explainer
explainer = shap.TreeExplainer(best_model)
shap_values = explainer.shap_values(X_test)

# Summary plot (global importance)
shap.summary_plot(shap_values, X_test)

# Force plot (single prediction explanation)
shap.force_plot(
    explainer.expected_value,
    shap_values[0],
    X_test.iloc[0]
)

# Interpretations:
# High tenure → Decreases churn probability
# High recency (not purchased recently) → Increases churn
# Actionable insights for business
```

## Export et Déploiement

### Exporting Best Model

```python
# Get best model from AutoML run

best_run = automl_run.get_best_run()
best_model = automl_run.get_best_model()

# Save to MLflow
import mlflow

with mlflow.start_run():
    mlflow.sklearn.log_model(
        best_model,
        "automl_best_model",
        registered_model_name="ChurnPredictor_AutoML"
    )

# Download model artifacts
best_run.download_artifacts("outputs/model", local_path="./automl_model")

# Model package includes:
# - Trained model
# - Preprocessing pipeline
# - Feature transformations
# - Scoring script
```

### Register in Model Registry

```python
# Register for production use

from mlflow.tracking import MlflowClient

client = MlflowClient()

# Register model
model_uri = f"runs:/{best_run.run_id}/outputs/model"
model_name = "ChurnPredictor_AutoML"

mlflow.register_model(model_uri, model_name)

# Transition to Production
client.transition_model_version_stage(
    name=model_name,
    version=1,
    stage="Production"
)

print(f"Model registered and promoted to Production")
```

### Batch Scoring

```python
# Use AutoML model for predictions

# Load production model
model = mlflow.pyfunc.load_model("models:/ChurnPredictor_AutoML/Production")

# New data
new_customers = spark.table("new_customers")

# Predict
predictions = model.predict(new_customers.toPandas())

# Save results
result_df = new_customers.withColumn(
    "churn_probability",
    predictions
)

result_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("churn_predictions")

print(f"Predictions saved for {result_df.count()} customers")
```

## Comparaison avec Modèle Manuel

### When to Use AutoML

```
✅ Use AutoML when:
  • Quick baseline needed
  • Many features, unsure which matter
  • Limited ML expertise
  • Time constraints
  • Exploring different algorithms

✅ Use manual modeling when:
  • Deep domain expertise required
  • Specialized algorithms needed
  • Interpretability critical
  • Custom preprocessing required
  • Fine-grained control needed

Hybrid approach (recommended):
  1. Start with AutoML (baseline)
  2. Analyze results
  3. Improve with domain knowledge
  4. Compare manual vs AutoML
  5. Deploy best performer
```

### Comparison Example

```python
# Compare AutoML vs Manual model

# AutoML results
automl_auc = 0.8923
automl_accuracy = 0.8456

# Manual model (domain-informed)
manual_auc = 0.8756
manual_accuracy = 0.8234

# Manual model v2 (after feature engineering insights from AutoML)
manual_v2_auc = 0.8967
manual_v2_accuracy = 0.8512

print("Comparison:")
print(f"AutoML: AUC={automl_auc:.4f}")
print(f"Manual v1: AUC={manual_auc:.4f}")
print(f"Manual v2: AUC={manual_v2_auc:.4f}")

# Learning: Use AutoML insights to improve manual model
# Best result often comes from combining approaches
```

## Best Practices

### Data Preparation

```
1. Clean data first
   Remove duplicates
   Handle obvious errors
   Validate data types

2. Remove leakage
   No future information
   No target-correlated IDs
   Check for data snooping

3. Balanced datasets
   Address class imbalance
   Stratified sampling
   AutoML can handle but help it

4. Sufficient data
   More data = better results
   Minimum: 100 rows per class
   Ideally: 1000+ rows
```

### Configuration Tips

```
1. Set reasonable time budget
   Too short: Misses good models
   Too long: Diminishing returns
   Start: 30-60 minutes

2. Choose right primary metric
   Business aligned
   Classification: AUC for imbalanced
   Regression: R2 or RMSE based on needs

3. Cross-validation
   5-fold standard
   More folds for small data
   Fewer folds for large data

4. Enable early stopping
   Saves compute
   Stops poor performers quickly
   Focus on promising algorithms
```

### Post-AutoML

```
After AutoML completes:

1. Review leaderboard
   Are results reasonable?
   Compare top models

2. Analyze feature importance
   Do important features make sense?
   Any surprises? (potential issues)

3. Check for overfitting
   Train vs validation performance
   Cross-validation variance

4. Validate with holdout
   Test on completely unseen data
   Real-world performance estimate

5. Business validation
   Show to stakeholders
   Does model behavior make sense?
   Edge cases handled correctly?
```

## Points Clés

- AutoML automates model selection, feature engineering, and hyperparameter tuning
- Task types: Classification, Regression, Forecasting
- Automatic feature engineering: Imputation, encoding, scaling
- Tries 50+ algorithms with different configurations
- Model leaderboard ranks results by primary metric
- Feature importance and SHAP for interpretability
- Export best model to MLflow Registry
- Compare AutoML vs manual: Often complementary approaches
- Best practices: Clean data, set right metric, validate thoroughly
- Use AutoML for fast baseline, refine with domain expertise

---

**Prochain fichier :** [04 - Feature Store](./04-feature-store.md)

[⬅️ Fichier précédent](./02-mlflow-experiments.md) | [⬅️ Retour au README du module](./README.md)
