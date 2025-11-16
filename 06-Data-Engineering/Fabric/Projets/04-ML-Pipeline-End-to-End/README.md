# Projet 4 : ML Pipeline End-to-End

## Vue d'ensemble

Dans ce projet, vous allez développer un **pipeline ML complet** pour prédire le churn client d'un opérateur télécom "TeleConnect". Vous implémenterez toutes les étapes du cycle ML : feature engineering, model training, experiment tracking avec MLflow, et batch scoring en production.

**Durée estimée :** 12-14 heures
**Niveau :** Avancé
**Modules prérequis :** 06, 10

## Contexte Business

### L'entreprise : TeleConnect

TeleConnect est un opérateur de télécommunications avec :
- 5,000+ clients actifs
- Taux de churn actuel : ~35%
- Coût d'acquisition client : $500
- Revenu mensuel moyen par client : $70
- Objectif : Réduire le churn de 35% à 25%

### Problématique

L'équipe marketing constate :
- **Churn élevé** : perte de 35% des clients annuellement
- **Actions réactives** : découverte du churn après le départ
- **Pas de priorisation** : toutes les campagnes de rétention ont le même poids
- **ROI incertain** : pas de mesure de l'efficacité des actions

**Objectif :** Prédire les clients à risque de churn pour actions proactives ciblées.

## Objectifs d'Apprentissage

À la fin de ce projet, vous serez capable de :

- ✅ Effectuer un feature engineering avancé pour le ML
- ✅ Créer et gérer des experiments MLflow
- ✅ Entraîner et comparer plusieurs modèles
- ✅ Optimiser les hyperparamètres
- ✅ Versionner et déployer un modèle via MLflow Registry
- ✅ Implémenter un pipeline de scoring batch
- ✅ Monitorer les performances du modèle
- ✅ Documenter un projet ML complet

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`customer_churn.csv`** (762 KB, 5K clients) | Dataset client avec features comportementales et variable cible `Churn` | → Feature engineering & ML |

### Aperçu du Dataset

```python
# Charger les données dans un notebook Fabric
df_churn = spark.read.csv("Files/raw/customer_churn.csv", header=True, inferSchema=True)

# Structure du dataset
df_churn.printSchema()
"""
Colonnes clés :
- CustomerID: Identifiant unique
- Gender: Genre du client
- Age: Âge
- Tenure: Durée d'abonnement (mois)
- MonthlyCharges: Facture mensuelle
- TotalCharges: Montant total payé
- Contract: Type de contrat (Month-to-month, One year, Two year)
- PaymentMethod: Méthode de paiement
- SeniorCitizen: Senior (0/1)
- Partner/Dependents: Situation familiale
- TechSupport/OnlineSecurity: Services souscrits
- Churn: Variable cible (Yes/No) - ~35% de churn
"""

print(f"Total clients: {df_churn.count()}")
print(f"Taux de churn: {df_churn.filter(col('Churn') == 'Yes').count() / df_churn.count():.2%}")
```

### Caractéristiques du Dataset

- **Déséquilibre contrôlé** : ~35% de churn (réaliste pour télécoms)
- **Mix de features** : Numériques (Age, Tenure, Charges) + Catégorielles (Contract, Services)
- **Patterns réalistes** : Corrélations entre tenure/churn, contrat/churn
- **Prêt pour le ML** : Nécessite feature engineering pour performances optimales

### Chargement dans Fabric

1. **Upload** `customer_churn.csv` dans `Files/raw/`
2. **Créer table Delta** :
   ```python
   df_churn.write.mode("overwrite").saveAsTable("raw_churn")
   ```
3. **Démarrer l'exploration** : Feature engineering documenté ci-dessous

## Architecture Cible

```
┌─────────────────────────────────────────────────────────────┐
│                     DATA SOURCES                             │
├──────────────────────────────────────────────────────────────┤
│ customer_churn.csv → Lakehouse (raw_churn)                  │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   FEATURE ENGINEERING                        │
├──────────────────────────────────────────────────────────────┤
│ • Data cleaning & preprocessing                              │
│ • Categorical encoding                                       │
│ • Feature creation (interactions, ratios)                   │
│ • Feature selection                                         │
│ • Feature Store (Delta table)                               │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MODEL TRAINING                            │
├──────────────────────────────────────────────────────────────┤
│ • Data split (train/test/validation)                        │
│ • Multiple algorithms (RF, GBM, XGBoost)                    │
│ • Hyperparameter tuning                                     │
│ • Cross-validation                                          │
│ • MLflow Experiment Tracking                                │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MLFLOW REGISTRY                           │
├──────────────────────────────────────────────────────────────┤
│ • Model versioning                                          │
│ • Stage transitions (Staging → Production)                  │
│ • Model metadata & documentation                            │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  BATCH SCORING PIPELINE                      │
├──────────────────────────────────────────────────────────────┤
│ • Load production model                                     │
│ • Score new/existing customers                              │
│ • Save predictions to Lakehouse                             │
│ • Schedule daily execution                                  │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MONITORING & ACTIONS                      │
├──────────────────────────────────────────────────────────────┤
│ • Model performance tracking                                │
│ • Data drift detection                                      │
│ • Automated retraining triggers                             │
│ • Business actions (retention campaigns)                    │
└──────────────────────────────────────────────────────────────┘
```

## Données Source

Utilisez le dataset généré :
- `customer_churn.csv` (5K clients, ~35% churn rate)

**Emplacement :** `/Ressources/datasets/`

**Structure des données :**
```
customer_id          - Identifiant unique
gender               - Male/Female
senior_citizen       - 0/1
partner              - Yes/No
dependents           - Yes/No
tenure_months        - Ancienneté (mois)
phone_service        - Yes/No
multiple_lines       - Yes/No/No phone service
internet_service     - DSL/Fiber optic/No
online_security      - Yes/No/No internet service
...
monthly_charges      - Montant mensuel
total_charges        - Montant total
num_admin_tickets    - Tickets support admin
num_tech_tickets     - Tickets support technique
churn                - Yes/No (target variable)
```

## Phase 1: Setup et Data Exploration (1h)

### 1.1 Configuration de l'environnement

```python
# Notebook: 01_Setup_and_EDA.py

# Import libraries
import mlflow
import mlflow.sklearn
from pyspark.sql import functions as F
from pyspark.sql.types import *
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    f1_score, roc_auc_score, confusion_matrix, classification_report
)
import matplotlib.pyplot as plt
import seaborn as sns

# Set MLflow experiment
mlflow.set_experiment("/ChurnPrediction/TeleConnect")

print("Environment configured successfully")
```

### 1.2 Chargement des Données

```python
# Load raw data
df_raw = spark.read.csv(
    "Files/raw/customer_churn.csv",
    header=True,
    inferSchema=True
)

print(f"Dataset size: {df_raw.count()} rows, {len(df_raw.columns)} columns")
df_raw.printSchema()
df_raw.show(5)

# Check target distribution
df_raw.groupBy("churn").count().show()
# Expected: ~65% No, ~35% Yes

# Save to Lakehouse table
df_raw.write.format("delta").mode("overwrite").saveAsTable("raw_churn_data")
```

### 1.3 Exploratory Data Analysis

```python
# Convert to Pandas for EDA
df_pd = df_raw.toPandas()

# Basic statistics
print("Numerical Features Summary:")
print(df_pd.describe())

# Check for nulls
print("\nMissing Values:")
print(df_pd.isnull().sum())

# Churn rate analysis
churn_rate = df_pd['churn'].value_counts(normalize=True)
print(f"\nChurn Rate: {churn_rate['Yes']*100:.2f}%")

# Visualizations
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# 1. Churn distribution
df_pd['churn'].value_counts().plot(kind='pie', ax=axes[0,0], autopct='%1.1f%%')
axes[0,0].set_title('Churn Distribution')

# 2. Tenure vs Churn
df_pd.boxplot(column='tenure_months', by='churn', ax=axes[0,1])
axes[0,1].set_title('Tenure by Churn Status')

# 3. Monthly charges distribution
df_pd[df_pd['churn']=='Yes']['monthly_charges'].hist(alpha=0.5, label='Churned', ax=axes[1,0])
df_pd[df_pd['churn']=='No']['monthly_charges'].hist(alpha=0.5, label='Retained', ax=axes[1,0])
axes[1,0].legend()
axes[1,0].set_title('Monthly Charges by Churn')

# 4. Contract type vs Churn
pd.crosstab(df_pd['contract'], df_pd['churn'], normalize='index').plot(kind='bar', ax=axes[1,1])
axes[1,1].set_title('Churn Rate by Contract Type')

plt.tight_layout()
plt.savefig('Files/output/eda_plots.png')

# Log EDA to MLflow
with mlflow.start_run(run_name="EDA"):
    mlflow.log_param("dataset_size", len(df_pd))
    mlflow.log_param("churn_rate", f"{churn_rate['Yes']*100:.2f}%")
    mlflow.log_param("num_features", len(df_pd.columns))
    mlflow.log_artifact("Files/output/eda_plots.png")
```

## Phase 2: Feature Engineering (3h)

### 2.1 Data Preprocessing

```python
# Notebook: 02_Feature_Engineering.py

# Load raw data
df = spark.table("raw_churn_data")

# Handle categorical variables
from pyspark.ml.feature import StringIndexer, OneHotEncoder

# Columns to encode
categorical_cols = [
    'gender', 'partner', 'dependents', 'phone_service',
    'multiple_lines', 'internet_service', 'online_security',
    'online_backup', 'device_protection', 'tech_support',
    'streaming_tv', 'streaming_movies', 'contract',
    'paperless_billing', 'payment_method'
]

# Binary encode Yes/No columns
binary_cols = ['partner', 'dependents', 'phone_service', 'paperless_billing']
for col in binary_cols:
    df = df.withColumn(
        f"{col}_encoded",
        F.when(F.col(col) == "Yes", 1).otherwise(0)
    )

# Label encode target
df = df.withColumn(
    "churn_label",
    F.when(F.col("churn") == "Yes", 1).otherwise(0)
)

print("Binary encoding complete")
```

### 2.2 Feature Creation

```python
# Create derived features
df_features = df.withColumn(
    # Tenure categories
    "tenure_group",
    F.when(F.col("tenure_months") <= 12, "New")
     .when(F.col("tenure_months") <= 24, "Growing")
     .when(F.col("tenure_months") <= 48, "Mature")
     .otherwise("Loyal")
).withColumn(
    # Monthly to total ratio
    "charge_ratio",
    F.round(F.col("monthly_charges") / F.col("total_charges"), 4)
).withColumn(
    # Average monthly from total
    "avg_charges_per_month",
    F.round(F.col("total_charges") / F.col("tenure_months"), 2)
).withColumn(
    # Total tickets
    "total_tickets",
    F.col("num_admin_tickets") + F.col("num_tech_tickets")
).withColumn(
    # Tickets per tenure
    "tickets_per_month",
    F.round((F.col("num_admin_tickets") + F.col("num_tech_tickets")) / F.col("tenure_months"), 4)
).withColumn(
    # High value customer
    "is_high_value",
    F.when(F.col("monthly_charges") > 80, 1).otherwise(0)
).withColumn(
    # Multiple services
    "num_services",
    (F.when(F.col("phone_service") == "Yes", 1).otherwise(0) +
     F.when(F.col("internet_service") != "No", 1).otherwise(0) +
     F.when(F.col("online_security") == "Yes", 1).otherwise(0) +
     F.when(F.col("online_backup") == "Yes", 1).otherwise(0) +
     F.when(F.col("device_protection") == "Yes", 1).otherwise(0) +
     F.when(F.col("tech_support") == "Yes", 1).otherwise(0) +
     F.when(F.col("streaming_tv") == "Yes", 1).otherwise(0) +
     F.when(F.col("streaming_movies") == "Yes", 1).otherwise(0))
).withColumn(
    # Contract risk score
    "contract_risk",
    F.when(F.col("contract") == "Month-to-month", 3)
     .when(F.col("contract") == "One year", 2)
     .otherwise(1)
)

print(f"Features created. Total columns: {len(df_features.columns)}")
df_features.select(
    "tenure_group", "charge_ratio", "avg_charges_per_month",
    "total_tickets", "tickets_per_month", "num_services", "contract_risk"
).show(5)
```

### 2.3 One-Hot Encoding for Complex Categories

```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler

# Categories to one-hot encode
complex_cats = ['internet_service', 'contract', 'payment_method', 'tenure_group']

# Create indexers and encoders
indexers = [
    StringIndexer(inputCol=col, outputCol=f"{col}_idx", handleInvalid="keep")
    for col in complex_cats
]

encoders = [
    OneHotEncoder(inputCol=f"{col}_idx", outputCol=f"{col}_vec")
    for col in complex_cats
]

# Execute pipeline
pipeline = Pipeline(stages=indexers + encoders)
df_encoded = pipeline.fit(df_features).transform(df_features)

print("One-hot encoding complete")
```

### 2.4 Final Feature Selection

```python
# Select final feature columns
feature_columns = [
    # Demographics
    "senior_citizen",
    "partner_encoded",
    "dependents_encoded",

    # Tenure & Charges
    "tenure_months",
    "monthly_charges",
    "total_charges",
    "avg_charges_per_month",
    "charge_ratio",

    # Services
    "phone_service_encoded",
    "paperless_billing_encoded",
    "num_services",
    "is_high_value",

    # Support
    "num_admin_tickets",
    "num_tech_tickets",
    "total_tickets",
    "tickets_per_month",

    # Risk indicators
    "contract_risk"
]

# Add one-hot encoded vectors (expand manually or use VectorAssembler)
# For simplicity, we'll use the numerical features

# Create final feature dataframe
df_final = df_encoded.select(
    "customer_id",
    *feature_columns,
    "churn_label"
)

# Handle nulls
df_final = df_final.na.fill(0)

# Save to Feature Store
df_final.write.format("delta").mode("overwrite").saveAsTable("feature_store.churn_features")

print(f"Feature Store updated: {df_final.count()} rows, {len(feature_columns)} features")
df_final.show(5)

# Log feature engineering to MLflow
with mlflow.start_run(run_name="Feature_Engineering"):
    mlflow.log_param("num_features", len(feature_columns))
    mlflow.log_param("feature_names", str(feature_columns))
    mlflow.log_param("dataset_rows", df_final.count())
```

## Phase 3: Model Training (3h)

### 3.1 Data Preparation

```python
# Notebook: 03_Model_Training.py

import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import roc_auc_score, classification_report

# Load features
df_features = spark.table("feature_store.churn_features").toPandas()

# Prepare X and y
feature_cols = [col for col in df_features.columns if col not in ['customer_id', 'churn_label']]
X = df_features[feature_cols]
y = df_features['churn_label']

print(f"Features: {len(feature_cols)}")
print(f"Samples: {len(X)}")
print(f"Target distribution:\n{y.value_counts(normalize=True)}")

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# Further split for validation
X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, test_size=0.2, random_state=42, stratify=y_train
)

print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")
```

### 3.2 Feature Scaling

```python
from sklearn.preprocessing import StandardScaler

# Scale numerical features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_val_scaled = scaler.transform(X_val)
X_test_scaled = scaler.transform(X_test)

# Save scaler for production
import joblib
joblib.dump(scaler, "Files/models/scaler.pkl")
```

### 3.3 Train Multiple Models

```python
def train_and_log_model(model, model_name, X_train, y_train, X_val, y_val):
    """Train a model and log to MLflow"""

    with mlflow.start_run(run_name=model_name):
        # Train
        model.fit(X_train, y_train)

        # Predictions
        y_pred = model.predict(X_val)
        y_pred_proba = model.predict_proba(X_val)[:, 1]

        # Metrics
        accuracy = accuracy_score(y_val, y_pred)
        precision = precision_score(y_val, y_pred)
        recall = recall_score(y_val, y_pred)
        f1 = f1_score(y_val, y_pred)
        roc_auc = roc_auc_score(y_val, y_pred_proba)

        # Log parameters
        mlflow.log_param("model_type", model_name)
        if hasattr(model, 'get_params'):
            for param, value in model.get_params().items():
                mlflow.log_param(param, value)

        # Log metrics
        mlflow.log_metric("accuracy", accuracy)
        mlflow.log_metric("precision", precision)
        mlflow.log_metric("recall", recall)
        mlflow.log_metric("f1_score", f1)
        mlflow.log_metric("roc_auc", roc_auc)

        # Log model
        mlflow.sklearn.log_model(model, "model")

        # Log feature importance (if available)
        if hasattr(model, 'feature_importances_'):
            importance_df = pd.DataFrame({
                'feature': feature_cols,
                'importance': model.feature_importances_
            }).sort_values('importance', ascending=False)
            importance_df.to_csv("Files/output/feature_importance.csv", index=False)
            mlflow.log_artifact("Files/output/feature_importance.csv")

        print(f"{model_name} - AUC: {roc_auc:.4f}, F1: {f1:.4f}, Recall: {recall:.4f}")

        return model, roc_auc

# Train models
models = [
    (LogisticRegression(max_iter=1000), "LogisticRegression"),
    (RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42), "RandomForest_v1"),
    (GradientBoostingClassifier(n_estimators=100, max_depth=5, random_state=42), "GradientBoosting_v1")
]

results = {}
for model, name in models:
    trained_model, auc = train_and_log_model(model, name, X_train_scaled, y_train, X_val_scaled, y_val)
    results[name] = {'model': trained_model, 'auc': auc}

# Best model so far
best_model_name = max(results, key=lambda k: results[k]['auc'])
print(f"\nBest model: {best_model_name} with AUC: {results[best_model_name]['auc']:.4f}")
```

## Phase 4: Hyperparameter Tuning (2h)

### 4.1 Grid Search

```python
# Notebook: 04_Hyperparameter_Tuning.py

from sklearn.model_selection import GridSearchCV, RandomizedSearchCV

# Focus on Random Forest (or best performer)
param_grid = {
    'n_estimators': [100, 200, 300],
    'max_depth': [5, 10, 15, 20],
    'min_samples_split': [2, 5, 10],
    'min_samples_leaf': [1, 2, 4],
    'max_features': ['sqrt', 'log2', None]
}

with mlflow.start_run(run_name="RandomForest_GridSearch"):
    # Grid search with cross-validation
    grid_search = GridSearchCV(
        RandomForestClassifier(random_state=42),
        param_grid,
        cv=5,
        scoring='roc_auc',
        n_jobs=-1,
        verbose=1
    )

    grid_search.fit(X_train_scaled, y_train)

    # Best model
    best_rf = grid_search.best_estimator_
    best_params = grid_search.best_params_

    print(f"Best parameters: {best_params}")
    print(f"Best CV AUC: {grid_search.best_score_:.4f}")

    # Evaluate on validation set
    y_pred = best_rf.predict(X_val_scaled)
    y_pred_proba = best_rf.predict_proba(X_val_scaled)[:, 1]

    val_auc = roc_auc_score(y_val, y_pred_proba)
    val_f1 = f1_score(y_val, y_pred)

    # Log everything
    for param, value in best_params.items():
        mlflow.log_param(param, value)

    mlflow.log_metric("best_cv_auc", grid_search.best_score_)
    mlflow.log_metric("val_auc", val_auc)
    mlflow.log_metric("val_f1", val_f1)

    mlflow.sklearn.log_model(best_rf, "best_model")

    print(f"Validation AUC: {val_auc:.4f}, F1: {val_f1:.4f}")

    # Save best run ID
    best_run_id = mlflow.active_run().info.run_id
```

### 4.2 Final Evaluation on Test Set

```python
# Evaluate on holdout test set
with mlflow.start_run(run_name="Final_Test_Evaluation"):
    y_test_pred = best_rf.predict(X_test_scaled)
    y_test_proba = best_rf.predict_proba(X_test_scaled)[:, 1]

    # Final metrics
    test_accuracy = accuracy_score(y_test, y_test_pred)
    test_precision = precision_score(y_test, y_test_pred)
    test_recall = recall_score(y_test, y_test_pred)
    test_f1 = f1_score(y_test, y_test_pred)
    test_auc = roc_auc_score(y_test, y_test_proba)

    mlflow.log_metric("test_accuracy", test_accuracy)
    mlflow.log_metric("test_precision", test_precision)
    mlflow.log_metric("test_recall", test_recall)
    mlflow.log_metric("test_f1", test_f1)
    mlflow.log_metric("test_auc", test_auc)

    # Classification report
    report = classification_report(y_test, y_test_pred)
    print("Final Test Results:")
    print(f"AUC: {test_auc:.4f}")
    print(f"F1 Score: {test_f1:.4f}")
    print(f"Recall: {test_recall:.4f}")
    print(f"\n{report}")

    # Confusion matrix
    cm = confusion_matrix(y_test, y_test_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.title('Confusion Matrix - Final Model')
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.savefig('Files/output/confusion_matrix.png')
    mlflow.log_artifact('Files/output/confusion_matrix.png')

    # ROC Curve
    from sklearn.metrics import roc_curve
    fpr, tpr, _ = roc_curve(y_test, y_test_proba)
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, label=f'ROC (AUC = {test_auc:.4f})')
    plt.plot([0, 1], [0, 1], 'k--')
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curve')
    plt.legend()
    plt.savefig('Files/output/roc_curve.png')
    mlflow.log_artifact('Files/output/roc_curve.png')

    # Save final model artifacts
    mlflow.sklearn.log_model(best_rf, "final_model")
    joblib.dump(best_rf, "Files/models/churn_model.pkl")
    mlflow.log_artifact("Files/models/churn_model.pkl")
    mlflow.log_artifact("Files/models/scaler.pkl")

    final_run_id = mlflow.active_run().info.run_id
```

## Phase 5: Model Registry (1h)

### 5.1 Register Model

```python
# Notebook: 05_Model_Registry.py

# Register the best model
model_uri = f"runs:/{final_run_id}/final_model"
model_name = "ChurnPredictor"

registered_model = mlflow.register_model(model_uri, model_name)

print(f"Model registered: {model_name}")
print(f"Version: {registered_model.version}")
```

### 5.2 Transition to Production

```python
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Get the latest version
latest_version = registered_model.version

# Add description
client.update_model_version(
    name=model_name,
    version=latest_version,
    description=f"""
    Churn Prediction Model for TeleConnect
    - Algorithm: Random Forest
    - Test AUC: {test_auc:.4f}
    - Test Recall: {test_recall:.4f}
    - Features: {len(feature_cols)}
    - Training date: {datetime.now().strftime('%Y-%m-%d')}
    """
)

# Transition to Production
client.transition_model_version_stage(
    name=model_name,
    version=latest_version,
    stage="Production",
    archive_existing_versions=True
)

print(f"Model {model_name} v{latest_version} transitioned to Production")
```

### 5.3 Model Documentation

```python
# Create model card
model_card = f"""
# Model Card: ChurnPredictor

## Model Details
- **Name**: ChurnPredictor
- **Version**: {latest_version}
- **Type**: Classification (Binary)
- **Algorithm**: Random Forest Classifier
- **Framework**: scikit-learn

## Intended Use
- **Primary Use**: Predict customer churn probability
- **Users**: Marketing and Customer Success teams
- **Out-of-Scope**: Real-time predictions, credit scoring

## Training Data
- **Dataset**: TeleConnect customer data
- **Size**: 5,000 customers
- **Features**: {len(feature_cols)} engineered features
- **Target**: Churn (Yes/No)
- **Class Balance**: ~35% churn, ~65% retained

## Performance Metrics
- **ROC AUC**: {test_auc:.4f}
- **Precision**: {test_precision:.4f}
- **Recall**: {test_recall:.4f}
- **F1 Score**: {test_f1:.4f}

## Limitations
- Model trained on historical data; future patterns may differ
- Performance may degrade with data drift
- Requires feature engineering pipeline to be maintained

## Ethical Considerations
- Model should not be used for discriminatory practices
- Predictions are probabilistic, not deterministic
- Human review recommended for high-impact decisions

## Maintenance
- **Retraining Frequency**: Monthly or when AUC drops below 0.70
- **Monitoring**: Track prediction distribution, feature drift
- **Owner**: Data Science Team
"""

# Save model card
with open("Files/models/model_card.md", "w") as f:
    f.write(model_card)

mlflow.log_artifact("Files/models/model_card.md")
print("Model card created and logged")
```

## Phase 6: Batch Scoring Pipeline (2h)

### 6.1 Scoring Notebook

```python
# Notebook: 06_Batch_Scoring.py
# Schedule this notebook to run daily

import mlflow
from datetime import datetime

# Load production model
model_name = "ChurnPredictor"
model = mlflow.pyfunc.load_model(f"models:/{model_name}/Production")

# Load scaler
scaler = joblib.load("Files/models/scaler.pkl")

# Load current customer features
df_customers = spark.table("feature_store.churn_features").toPandas()

# Prepare features
feature_cols = [col for col in df_customers.columns if col not in ['customer_id', 'churn_label']]
X = df_customers[feature_cols]
X_scaled = scaler.transform(X)

# Score customers
churn_probabilities = model.predict(pd.DataFrame(X_scaled, columns=feature_cols))

# Note: MLflow pyfunc may return different format; adjust as needed
if isinstance(churn_probabilities, np.ndarray) and len(churn_probabilities.shape) > 1:
    probabilities = churn_probabilities[:, 1]
else:
    probabilities = churn_probabilities

# Create predictions dataframe
predictions_df = df_customers[['customer_id']].copy()
predictions_df['churn_probability'] = probabilities
predictions_df['churn_prediction'] = (probabilities > 0.5).astype(int)
predictions_df['risk_category'] = pd.cut(
    probabilities,
    bins=[0, 0.3, 0.6, 1.0],
    labels=['Low', 'Medium', 'High']
)
predictions_df['scored_at'] = datetime.now()

# Save to Lakehouse
spark_predictions = spark.createDataFrame(predictions_df)
spark_predictions.write.format("delta").mode("append").saveAsTable("predictions.customer_churn_scores")

print(f"Scored {len(predictions_df)} customers")
print(f"High risk customers: {(predictions_df['risk_category'] == 'High').sum()}")

# Summary statistics
print("\nRisk Category Distribution:")
print(predictions_df['risk_category'].value_counts())
```

### 6.2 Monitoring and Alerts

```python
# Check for model drift
def check_model_performance():
    """Monitor model predictions for drift"""

    # Load recent predictions
    recent_predictions = spark.sql("""
        SELECT
            DATE(scored_at) as score_date,
            AVG(churn_probability) as avg_probability,
            STDDEV(churn_probability) as std_probability,
            SUM(CASE WHEN risk_category = 'High' THEN 1 ELSE 0 END) as high_risk_count,
            COUNT(*) as total_scored
        FROM predictions.customer_churn_scores
        WHERE scored_at >= DATE_SUB(CURRENT_DATE, 30)
        GROUP BY DATE(scored_at)
        ORDER BY score_date
    """).toPandas()

    # Check for anomalies
    latest = recent_predictions.iloc[-1]
    historical_mean = recent_predictions['avg_probability'].mean()
    historical_std = recent_predictions['avg_probability'].std()

    drift_detected = abs(latest['avg_probability'] - historical_mean) > 2 * historical_std

    if drift_detected:
        print("WARNING: Potential model drift detected!")
        # Trigger alert or retraining

    return recent_predictions

check_model_performance()
```

## Livrables

### Checklist Technique
- [ ] EDA complet avec visualisations
- [ ] 15+ features engineered
- [ ] Feature Store (Delta table)
- [ ] MLflow experiment avec 5+ runs
- [ ] Hyperparameter tuning avec GridSearchCV
- [ ] Model AUC > 0.75 sur test set
- [ ] Model registered dans MLflow Registry
- [ ] Model transitionné en Production
- [ ] Batch scoring notebook fonctionnel
- [ ] Model card documentation
- [ ] Monitoring setup

### Documentation Requise
- [ ] Rapport EDA
- [ ] Feature engineering documentation
- [ ] MLflow experiment comparison
- [ ] Model card complet
- [ ] Guide de maintenance
- [ ] Runbook pour scoring batch

### Métriques de Succès
```
Model Performance:
  ✓ ROC AUC > 0.75
  ✓ Recall > 0.65 (catch most churners)
  ✓ Precision > 0.50 (reasonable false positive rate)
  ✓ F1 Score > 0.60

Production Readiness:
  ✓ Model versioned in MLflow
  ✓ Reproducible training pipeline
  ✓ Automated scoring pipeline
  ✓ Monitoring in place

Business Impact:
  ✓ High-risk customers identified
  ✓ Actionable insights for marketing
  ✓ Measurable ROI potential
```

## Critères d'Évaluation

- Feature engineering quality et créativité (25%)
- MLflow tracking et experiment management (25%)
- Model performance et validation (25%)
- Production pipeline robustness (25%)

## Extensions Possibles

1. **AutoML** : Utiliser Fabric AutoML pour découverte de modèles
2. **Deep Learning** : Tester des réseaux de neurones
3. **Explainability** : Ajouter SHAP values pour interprétabilité
4. **Real-time Scoring** : API de scoring temps réel
5. **A/B Testing** : Comparer différents modèles en production
6. **Automated Retraining** : Trigger de retraining sur drift

---

**Durée estimée: 12-14 heures**

**Données requises :** `customer_churn.csv` dans `/Ressources/datasets/`

[⬅️ Retour aux projets](../README.md)
