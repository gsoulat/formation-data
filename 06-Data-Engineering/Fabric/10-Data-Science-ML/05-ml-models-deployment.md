# Déploiement de Modèles

## Introduction

Le **déploiement de modèles ML** consiste à rendre les modèles entraînés disponibles pour la prédiction sur de nouvelles données en production.

```
Deployment Patterns:
┌─────────────────────────────────────────────┐
│  Training                                    │
│  └─ MLflow Model Registry                   │
│       ├─ Staging → Testing                  │
│       └─ Production → Serving               │
├─────────────────────────────────────────────┤
│  Serving Options                            │
│  ├─ Batch Scoring (scheduled)              │
│  ├─ Real-time API (on-demand)              │
│  └─ Embedded (in application)              │
└─────────────────────────────────────────────┘
```

## Stratégies de Déploiement

### Model Promotion Pipeline

```
Typical workflow:

1. Development
   Train model in notebook
   Log to MLflow

2. Staging
   Register in Model Registry
   Transition to "Staging"
   Run validation tests

3. Production
   After tests pass
   Transition to "Production"
   Monitor performance

4. Retirement
   New model replaces old
   Archive previous version
   Maintain for rollback

Code:
from mlflow.tracking import MlflowClient
client = MlflowClient()

# Promote to staging
client.transition_model_version_stage(
    name="ChurnPredictor",
    version=2,
    stage="Staging"
)

# After validation, promote to production
client.transition_model_version_stage(
    name="ChurnPredictor",
    version=2,
    stage="Production",
    archive_existing_versions=True
)
```

### Deployment Checklist

```
Before deploying:
[ ] Model performance validated
[ ] Input schema documented
[ ] Output format defined
[ ] Error handling tested
[ ] Monitoring configured
[ ] Rollback plan ready
[ ] Stakeholders notified
[ ] Dependencies documented

Critical:
  Don't skip validation steps
  Production failures are costly
  Thorough testing saves time
```

## Batch Scoring

### What is Batch Scoring?

```
Batch Scoring:
  • Process large volumes of data
  • Run on schedule (hourly, daily)
  • High throughput
  • Results stored for later use

Use cases:
  • Daily churn predictions
  • Weekly recommendation updates
  • Monthly fraud scoring
  • Quarterly risk assessment

Benefits:
  ✅ Simple to implement
  ✅ Cost-effective (no always-on service)
  ✅ Handles large datasets
  ✅ Easy monitoring

Limitations:
  ❌ Not real-time
  ❌ Latency (next schedule)
  ❌ Stale predictions between runs
```

### Batch Scoring Pipeline

```python
# Complete batch scoring pipeline

import mlflow
from pyspark.sql import functions as F

def batch_scoring_pipeline():
    """Daily churn prediction pipeline"""

    # 1. Load production model
    model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")

    # 2. Get new data to score
    new_customers = spark.table("feature_store.customer_features") \
        .filter(F.col("last_scored_date") < F.current_date())

    print(f"Scoring {new_customers.count()} customers")

    # 3. Prepare features
    feature_columns = ["age", "tenure_months", "recency_days", "frequency", "monetary_total"]
    features_df = new_customers.select("customer_id", *feature_columns)

    # 4. Score with model
    # Convert to Pandas for sklearn model
    pandas_features = features_df.toPandas()
    predictions = model.predict(pandas_features[feature_columns])

    # 5. Add predictions to DataFrame
    pandas_features["churn_probability"] = predictions
    pandas_features["prediction_date"] = datetime.now()

    # Convert back to Spark
    predictions_df = spark.createDataFrame(pandas_features)

    # 6. Save results
    predictions_df.write.format("delta") \
        .mode("append") \
        .saveAsTable("predictions.customer_churn")

    # 7. Update scoring metadata
    spark.sql(f"""
        UPDATE feature_store.customer_features
        SET last_scored_date = current_date()
        WHERE customer_id IN (
            SELECT customer_id FROM predictions.customer_churn
            WHERE prediction_date = '{datetime.now().date()}'
        )
    """)

    print(f"Batch scoring complete. {len(predictions)} predictions saved.")

    return predictions_df

# Schedule to run daily at 6 AM
# Fabric Pipeline or Notebook Job
```

### Spark UDF for Large Scale

```python
# Score with Spark UDF (distributed)

import mlflow
from pyspark.sql.functions import pandas_udf
from pyspark.sql.types import DoubleType

# Load model as Spark UDF
@pandas_udf(DoubleType())
def predict_churn_udf(features_df):
    model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")
    return model.predict(features_df)

# Or simpler with mlflow utility
predict_udf = mlflow.pyfunc.spark_udf(
    spark,
    model_uri="models:/ChurnPredictor/Production"
)

# Apply to large dataset
predictions = spark.table("customers") \
    .withColumn(
        "churn_probability",
        predict_udf(F.struct("age", "tenure", "recency", "frequency", "monetary"))
    )

# Fully distributed prediction
# Scales to billions of rows
# Uses Spark cluster resources
```

## Real-Time Inference

### Real-Time vs Batch

```
Real-Time Inference:
  • Immediate response (milliseconds)
  • On-demand prediction
  • Single or few records
  • Always-on service

Use cases:
  • Fraud detection during transaction
  • Product recommendations on website
  • Credit scoring at application
  • Customer service chatbot

Comparison:
  Batch: Score 1M customers overnight, use scores next day
  Real-time: Score single customer when they visit website
```

### REST API Endpoint (Azure ML Integration)

```python
# Deploy to Azure ML for real-time serving

from azureml.core import Workspace, Model
from azureml.core.webservice import AciWebservice, Webservice

# 1. Export model from Fabric MLflow
model_path = mlflow.artifacts.download_artifacts(
    run_id="abc123",
    artifact_path="model"
)

# 2. Register in Azure ML
ws = Workspace.from_config()
azureml_model = Model.register(
    workspace=ws,
    model_path=model_path,
    model_name="ChurnPredictor"
)

# 3. Create scoring script
# score.py
"""
import mlflow
import json

def init():
    global model
    model = mlflow.pyfunc.load_model("model_path")

def run(raw_data):
    data = json.loads(raw_data)
    prediction = model.predict(data)
    return prediction.tolist()
"""

# 4. Deploy as web service
deployment_config = AciWebservice.deploy_configuration(cpu_cores=1, memory_gb=1)
service = Model.deploy(
    workspace=ws,
    name="churn-predictor-api",
    models=[azureml_model],
    inference_config=inference_config,
    deployment_config=deployment_config
)

# 5. Call API
import requests
response = requests.post(
    service.scoring_uri,
    json={"age": 35, "tenure": 24, "recency": 10},
    headers={"Content-Type": "application/json"}
)
print(response.json())
```

### Embedded Scoring (In-Application)

```python
# Embed model directly in application

# Option 1: Load MLflow model in application
import mlflow

# Application startup
model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")

def predict_churn(customer_data):
    """Called when customer visits website"""
    prediction = model.predict([customer_data])
    return float(prediction[0])

# Option 2: Export to ONNX for fast inference
import onnx
from skl2onnx import convert_sklearn

# Convert sklearn model to ONNX
onnx_model = convert_sklearn(sklearn_model, initial_types=initial_types)
onnx.save_model(onnx_model, "model.onnx")

# Use ONNX Runtime in production
import onnxruntime as rt
session = rt.InferenceSession("model.onnx")

def fast_predict(features):
    result = session.run(None, {"input": features})
    return result[0]

# Benefits:
# - Very fast (optimized runtime)
# - No Python dependency
# - Works in C++, Java, JavaScript
```

## MLflow Model Serving

### Local Serving (Development)

```python
# Test model serving locally

# Start MLflow model server
# Command line:
mlflow models serve -m "models:/ChurnPredictor/Production" -p 5000

# Test with curl:
# curl -X POST http://localhost:5000/invocations \
#   -H "Content-Type: application/json" \
#   -d '{"columns": ["age", "tenure", "recency"], "data": [[35, 24, 10]]}'

# Or Python requests:
import requests
response = requests.post(
    "http://localhost:5000/invocations",
    json={
        "columns": ["age", "tenure", "recency"],
        "data": [[35, 24, 10], [42, 36, 5]]
    }
)
print(response.json())
# Output: [0.23, 0.67]  # Churn probabilities
```

### Docker Deployment

```bash
# Build Docker image for model

# MLflow provides Dockerfile
mlflow models build-docker \
  -m "models:/ChurnPredictor/Production" \
  -n "churn-predictor:v1"

# Run container
docker run -p 5000:8080 churn-predictor:v1

# Deploy to Kubernetes
kubectl apply -f deployment.yaml

# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: churn-predictor
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: churn-predictor
        image: churn-predictor:v1
        ports:
        - containerPort: 8080
```

## Model Monitoring

### Performance Monitoring

```python
# Track model performance over time

def monitor_model_performance():
    """Weekly performance monitoring"""

    # Get recent predictions
    predictions = spark.sql("""
        SELECT
            prediction_date,
            churn_probability,
            actual_churn
        FROM predictions.customer_churn p
        JOIN actuals.customer_churn_actual a
        ON p.customer_id = a.customer_id
        WHERE p.prediction_date >= date_sub(current_date(), 30)
    """)

    # Calculate metrics
    from sklearn.metrics import roc_auc_score, accuracy_score

    y_true = predictions.select("actual_churn").toPandas()
    y_pred = predictions.select("churn_probability").toPandas()

    auc = roc_auc_score(y_true, y_pred)
    accuracy = accuracy_score(y_true, (y_pred > 0.5).astype(int))

    # Log to monitoring system
    mlflow.log_metric("production_auc", auc)
    mlflow.log_metric("production_accuracy", accuracy)

    # Alert if performance degrades
    if auc < 0.75:  # Threshold
        send_alert("Model AUC dropped below threshold", auc)

    print(f"AUC: {auc:.4f}, Accuracy: {accuracy:.4f}")

# Schedule weekly
```

### Data Drift Detection

```python
# Detect when input data distribution changes

from scipy.stats import ks_2samp

def detect_drift(baseline_features, current_features):
    """Compare feature distributions"""

    drift_scores = {}
    drifted_features = []

    for col in baseline_features.columns:
        # Kolmogorov-Smirnov test
        statistic, p_value = ks_2samp(
            baseline_features[col],
            current_features[col]
        )

        drift_scores[col] = {
            "ks_statistic": statistic,
            "p_value": p_value
        }

        if p_value < 0.05:  # Significant drift
            drifted_features.append(col)

    if drifted_features:
        print(f"Drift detected in: {drifted_features}")
        # Consider retraining model

    return drift_scores

# Run monthly
baseline = spark.table("feature_snapshots.jan_2024").toPandas()
current = spark.table("feature_store.customer_features").toPandas()
drift = detect_drift(baseline, current)
```

### Model Versioning Alerts

```python
# Track which model version is in production

def check_model_health():
    """Daily health check"""

    from mlflow.tracking import MlflowClient
    client = MlflowClient()

    # Get production model
    prod_model = client.get_latest_versions("ChurnPredictor", stages=["Production"])[0]

    # Check age
    creation_time = prod_model.creation_timestamp
    age_days = (datetime.now().timestamp() - creation_time / 1000) / 86400

    if age_days > 90:
        send_alert("Production model is over 90 days old. Consider retraining.")

    # Check if newer staging model available
    staging_models = client.get_latest_versions("ChurnPredictor", stages=["Staging"])
    if staging_models:
        print(f"Staging model available (v{staging_models[0].version})")
        print("Consider promoting after validation")

    print(f"Production model: v{prod_model.version}, Age: {age_days:.0f} days")

# Run daily
```

## A/B Testing

### Shadow Deployment

```python
# Test new model alongside production

def score_with_ab_test(customer_data):
    """Score with both models, compare"""

    # Production model (current)
    prod_model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")
    prod_prediction = prod_model.predict(customer_data)

    # Challenger model (new)
    challenger_model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Staging")
    challenger_prediction = challenger_model.predict(customer_data)

    # Log both predictions
    log_ab_test_result({
        "customer_id": customer_data["customer_id"],
        "production_prediction": prod_prediction,
        "challenger_prediction": challenger_prediction,
        "timestamp": datetime.now()
    })

    # Return production result (challenger is shadow)
    return prod_prediction

# After collecting enough data, compare performance
# If challenger is better, promote to production
```

### Traffic Splitting

```python
# Route percentage of traffic to new model

import random

def predict_with_traffic_split(customer_data):
    """10% traffic to new model"""

    if random.random() < 0.10:
        # 10% to challenger
        model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Staging")
        version = "staging"
    else:
        # 90% to production
        model = mlflow.pyfunc.load_model("models:/ChurnPredictor/Production")
        version = "production"

    prediction = model.predict(customer_data)

    # Log version used
    log_prediction(customer_data["customer_id"], prediction, version)

    return prediction

# Gradually increase traffic to new model:
# Week 1: 10%
# Week 2: 25%
# Week 3: 50%
# Week 4: 100% (full cutover)
```

## Rollback Strategies

### Quick Rollback

```python
# Rollback to previous model version

from mlflow.tracking import MlflowClient

def rollback_model():
    """Emergency rollback to previous production"""

    client = MlflowClient()

    # Get current production
    current_prod = client.get_latest_versions(
        "ChurnPredictor",
        stages=["Production"]
    )[0]

    print(f"Current production: v{current_prod.version}")

    # Archive current production
    client.transition_model_version_stage(
        name="ChurnPredictor",
        version=current_prod.version,
        stage="Archived"
    )

    # Get previous version (now archived)
    archived_versions = client.search_model_versions(
        f"name='ChurnPredictor' and current_stage='Archived'"
    )

    # Find most recent archived (previous production)
    previous_prod = sorted(archived_versions, key=lambda x: x.version, reverse=True)[0]

    # Promote back to production
    client.transition_model_version_stage(
        name="ChurnPredictor",
        version=previous_prod.version,
        stage="Production"
    )

    print(f"Rolled back to v{previous_prod.version}")

# Execute rollback
rollback_model()
```

### Blue-Green Deployment

```
Blue-Green Strategy:
  Blue: Current production environment
  Green: New model environment

Process:
  1. Deploy new model to Green
  2. Test Green thoroughly
  3. Switch traffic Blue → Green
  4. Monitor Green performance
  5. If issues, switch back to Blue
  6. Keep Blue as backup

Benefits:
  ✅ Zero downtime
  ✅ Instant rollback
  ✅ Full testing before switch

Implementation in Fabric:
  Use separate endpoints or model versions
  Switch via configuration, not deployment
```

## CI/CD pour ML

### Automated Pipeline

```yaml
# GitHub Actions for ML model deployment

name: ML Model CI/CD
on:
  push:
    branches: [main]

jobs:
  train-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Train model
        run: python train.py
        env:
          MLFLOW_TRACKING_URI: ${{ secrets.MLFLOW_URI }}

      - name: Validate model
        run: python validate.py
        # Tests: accuracy > 0.8, AUC > 0.75

      - name: Register model
        if: success()
        run: python register_model.py

      - name: Deploy to staging
        run: python deploy_staging.py

      - name: Run integration tests
        run: python test_staging.py

      - name: Promote to production
        if: success()
        run: python promote_production.py

      - name: Notify team
        run: |
          echo "Model deployed to production"
          # Send Teams/Slack notification
```

### MLOps Best Practices

```
1. Version everything
   • Code (Git)
   • Data (Delta Lake)
   • Models (MLflow)
   • Features (Feature Store)

2. Automate testing
   • Unit tests for code
   • Data validation tests
   • Model performance tests
   • Integration tests

3. Monitor continuously
   • Model performance metrics
   • Data drift detection
   • Prediction latency
   • Error rates

4. Document thoroughly
   • Model card (purpose, limitations)
   • Input/output schemas
   • Deployment procedures
   • Rollback instructions

5. Review and approve
   • Code review for training scripts
   • Model review for production promotion
   • Stakeholder sign-off
```

## Points Clés

- Deployment strategies: Model promotion pipeline (Staging → Production)
- Batch scoring: Scheduled, high-throughput, cost-effective
- Real-time inference: Low latency, on-demand, always-on
- MLflow serving: Local testing, Docker, Kubernetes deployment
- Monitor: Performance metrics, data drift, model age
- A/B testing: Shadow deployment, traffic splitting, gradual rollout
- Rollback: Quick version transitions, blue-green deployment
- CI/CD: Automated pipelines for training, testing, deployment
- MLOps: Version everything, automate tests, monitor continuously
- Best practices: Thorough validation, monitoring, documentation

---

**Prochain fichier :** [06 - Spark ML Pipelines](./06-spark-ml-pipelines.md)

[⬅️ Fichier précédent](./04-feature-store.md) | [⬅️ Retour au README du module](./README.md)
