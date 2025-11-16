# Module 10 - Data Science & Machine Learning

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les capacités ML de Fabric
- ✅ Utiliser MLflow pour gérer les experiments
- ✅ Tirer parti d'AutoML dans Fabric
- ✅ Utiliser le Feature Store
- ✅ Déployer des modèles ML en production
- ✅ Créer des pipelines ML avec Spark

## Contenu du module

### [01 - ML dans Fabric Overview](./01-ml-fabric-overview.md)
- Data Science workload dans Fabric
- Architecture ML end-to-end
- Integration avec Lakehouse
- Notebooks pour Data Science
- Libraries ML pré-installées (scikit-learn, TensorFlow, PyTorch)
- GPU support
- Comparaison avec Azure Machine Learning

### [02 - MLflow & Experiments](./02-mlflow-experiments.md)
- Introduction à MLflow
- MLflow tracking
- Logging de paramètres, métriques, artefacts
- MLflow models
- Model registry
- Versioning de modèles
- Comparaison d'experiments
- Best practices

### [03 - AutoML Fabric](./03-automl-fabric.md)
- Qu'est-ce qu'AutoML ?
- Configuration AutoML dans Fabric
- Types de tâches supportées :
  - Classification
  - Regression
  - Forecasting
- Feature engineering automatique
- Model selection et tuning
- Interprétabilité des résultats
- Export et déploiement

### [04 - Feature Store](./04-feature-store.md)
- Concept de Feature Store
- Avantages (réutilisabilité, cohérence)
- Création de features
- Feature engineering at scale avec Spark
- Versioning de features
- Online vs offline serving
- Integration avec training pipelines

### [05 - Déploiement de Modèles](./05-ml-models-deployment.md)
- Stratégies de déploiement
- Batch scoring vs real-time
- MLflow model serving
- Endpoints dans Fabric
- Model monitoring
- A/B testing
- Rollback strategies
- CI/CD pour ML

### [06 - Spark ML Pipelines](./06-spark-ml-pipelines.md)
- Spark MLlib overview
- Pipeline API
- Transformers et Estimators
- Feature engineering avec Spark
- Training distribué
- Hyperparameter tuning
- Model persistence
- Production pipelines

## Exercices pratiques

### Exercice 1 : Premier modèle avec MLflow
1. Créer un notebook Data Science
2. Charger un dataset (classification)
3. Entraîner un modèle scikit-learn
4. Logger avec MLflow (params, metrics, model)
5. Visualiser dans l'UI MLflow

### Exercice 2 : Comparaison d'experiments
1. Entraîner plusieurs modèles (Logistic Regression, Random Forest, XGBoost)
2. Logger tous les résultats
3. Comparer les métriques (accuracy, F1, AUC)
4. Sélectionner le meilleur modèle
5. Enregistrer dans Model Registry

### Exercice 3 : AutoML
1. Lancer AutoML sur un dataset
2. Configurer la tâche (classification)
3. Analyser les résultats
4. Comparer avec modèle manuel
5. Déployer le meilleur modèle

### Exercice 4 : Feature Store
1. Créer un ensemble de features (RFM pour clients)
2. Calculer avec Spark
3. Sauvegarder dans Feature Store
4. Utiliser pour entraînement
5. Versionner les features

### Exercice 5 : Batch Scoring
1. Entraîner un modèle de prédiction de churn
2. Sauvegarder le modèle
3. Créer un pipeline de scoring batch
4. Appliquer sur nouvelles données
5. Sauvegarder les prédictions dans Lakehouse

### Exercice 6 : Spark ML Pipeline complet
1. Charger données dans Spark
2. Feature engineering (StringIndexer, VectorAssembler)
3. Train/test split
4. Créer un Pipeline ML
5. CrossValidator pour tuning
6. Évaluer et sauvegarder

## Quiz

1. Qu'est-ce que MLflow et à quoi sert-il ?
2. Expliquez la différence entre batch scoring et real-time inference
3. Quels sont les avantages d'un Feature Store ?
4. Comment AutoML facilite-t-il le machine learning ?
5. Qu'est-ce qu'un Spark ML Pipeline ?

## Exemples de code

### MLflow tracking

```python
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score

# Charger données
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Démarrer un run MLflow
with mlflow.start_run(run_name="RandomForest_Experiment"):

    # Paramètres
    n_estimators = 100
    max_depth = 10

    # Logger les paramètres
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)

    # Entraîner
    model = RandomForestClassifier(n_estimators=n_estimators, max_depth=max_depth)
    model.fit(X_train, y_train)

    # Prédictions
    y_pred = model.predict(X_test)

    # Métriques
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average='weighted')

    # Logger les métriques
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("f1_score", f1)

    # Logger le modèle
    mlflow.sklearn.log_model(model, "model")

    print(f"Accuracy: {accuracy:.4f}")
    print(f"F1 Score: {f1:.4f}")
```

### Model Registry

```python
import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Enregistrer un modèle
model_uri = "runs:/<run_id>/model"
model_name = "churn_prediction_model"

mlflow.register_model(model_uri, model_name)

# Transition vers Production
client.transition_model_version_stage(
    name=model_name,
    version=1,
    stage="Production"
)

# Charger modèle depuis Registry
model = mlflow.pyfunc.load_model(f"models:/{model_name}/Production")

# Prédire
predictions = model.predict(new_data)
```

### AutoML (pseudo-code)

```python
from fabric.automl import AutoMLClassifier

# Configuration
automl = AutoMLClassifier(
    experiment_name="customer_churn",
    target_column="churn",
    time_limit_minutes=30,
    n_trials=50
)

# Entraînement
automl.fit(train_df)

# Meilleur modèle
best_model = automl.best_model
print(f"Best model: {automl.best_model_name}")
print(f"Best accuracy: {automl.best_score:.4f}")

# Prédictions
predictions = best_model.predict(test_df)
```

### Feature Store

```python
from pyspark.sql import functions as F

# Créer features
customer_features = spark.table("customers") \
    .withColumn("customer_age_years",
                F.datediff(F.current_date(), F.col("birth_date")) / 365) \
    .withColumn("account_tenure_months",
                F.months_between(F.current_date(), F.col("signup_date")))

# RFM features
rfm_features = spark.table("orders") \
    .groupBy("customer_id") \
    .agg(
        F.max("order_date").alias("last_order_date"),
        F.count("*").alias("order_frequency"),
        F.sum("amount").alias("total_spent")
    ) \
    .withColumn("recency_days",
                F.datediff(F.current_date(), F.col("last_order_date")))

# Sauvegarder dans Feature Store
customer_features.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_demographics")

rfm_features.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("feature_store.customer_rfm")
```

### Spark ML Pipeline

```python
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, VectorAssembler, StandardScaler
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# Préparation features
indexer = StringIndexer(inputCol="category", outputCol="category_idx")
assembler = VectorAssembler(
    inputCols=["category_idx", "age", "income"],
    outputCol="features_raw"
)
scaler = StandardScaler(inputCol="features_raw", outputCol="features")

# Modèle
lr = LogisticRegression(featuresCol="features", labelCol="label")

# Pipeline
pipeline = Pipeline(stages=[indexer, assembler, scaler, lr])

# Train/test split
train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)

# Entraînement
model = pipeline.fit(train_df)

# Prédictions
predictions = model.transform(test_df)

# Évaluation
evaluator = BinaryClassificationEvaluator(labelCol="label")
auc = evaluator.evaluate(predictions)
print(f"AUC: {auc:.4f}")

# Sauvegarder
model.write().overwrite().save("Models/churn_pipeline")
```

### Batch Scoring

```python
import mlflow

# Charger modèle depuis MLflow
model = mlflow.pyfunc.load_model("models:/churn_model/Production")

# Charger nouvelles données
new_customers = spark.read.format("delta").load("Tables/new_customers")

# Prédire
predictions_df = new_customers.withColumn(
    "churn_prediction",
    model.predict(new_customers)
)

# Sauvegarder résultats
predictions_df.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("predictions.customer_churn")
```

## Architecture ML

### Pipeline ML end-to-end

```
[Raw Data] → [Feature Engineering] → [Feature Store]
                                            ↓
                                     [Training]
                                            ↓
                                    [MLflow Tracking]
                                            ↓
                                    [Model Registry]
                                            ↓
                                ┌───────────┴───────────┐
                          [Batch Scoring]      [Real-time Endpoint]
                                ↓                       ↓
                        [Predictions Table]      [API Response]
```

## Ressources complémentaires

### Documentation officielle
- [Data Science in Fabric](https://learn.microsoft.com/fabric/data-science/)
- [MLflow documentation](https://mlflow.org/docs/latest/index.html)
- [Spark MLlib](https://spark.apache.org/docs/latest/ml-guide.html)

### Cours et tutoriels
- [Machine Learning with PySpark](https://learn.microsoft.com/training/paths/perform-data-science-azure-databricks/)
- [MLflow tutorial](https://mlflow.org/docs/latest/tutorials-and-examples/tutorial.html)

### Livres
- "Machine Learning with PySpark" - Pramod Singh
- "Feature Engineering for Machine Learning" - Alice Zheng

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 4-5 heures
- **Total** : 8-10 heures

## Prochaine étape

➡️ [Module 11 - Optimisation des performances](../11-Optimisation-Performance/)

---

[⬅️ Module précédent](../09-Securite-Gouvernance/) | [⬅️ Retour au sommaire](../README.md)
