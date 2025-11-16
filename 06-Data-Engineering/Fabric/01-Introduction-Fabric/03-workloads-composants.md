# Workloads et Composants

Microsoft Fabric intègre **7 workloads principaux**, chacun avec ses propres composants et cas d'usage. Ce fichier détaille en profondeur chaque workload.

## Vue d'Ensemble des 7 Workloads

```
┌────────────────────────────────────────────────────────┐
│                 Microsoft Fabric                        │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│   Data   │   Data   │   Data   │   Data   │ Real-Time  │
│ Engineer │ Warehouse│  Factory │  Science │ Analytics  │
├──────────┼──────────┴──────────┴──────────┴────────────┤
│ Power BI │              Data Activator                  │
└──────────┴──────────────────────────────────────────────┘
```

---

## 1. Data Engineering

### 🎯 Objectif
Construire des pipelines de données à grande échelle avec Apache Spark et Delta Lake.

### 🧩 Composants Principaux

#### Lakehouse
Le composant central du Data Engineering dans Fabric.

**Caractéristiques :**
- Combine Data Lake + Data Warehouse
- Stockage Delta Lake natif
- 2 zones : `Files/` (non-structuré) et `Tables/` (structuré)
- SQL Analytics Endpoint automatique

**Structure typique :**
```
MyLakehouse/
├── Files/
│   ├── bronze/     # Données brutes
│   ├── silver/     # Données nettoyées
│   └── gold/       # Données agrégées
└── Tables/
    ├── customers   # Tables Delta
    ├── orders
    └── products
```

**Use cases :**
- Architecture Medallion (Bronze/Silver/Gold)
- Data Lake pour analytics
- Feature store pour ML

#### Notebooks
Environnement de développement interactif basé sur Jupyter.

**Langages supportés :**
- Python (PySpark)
- Scala
- R
- SQL
- SparkSQL

**Fonctionnalités :**
- Cellules code + markdown
- Visualisations intégrées
- Collaboration en temps réel
- Git integration
- Scheduling

**Magic commands :**
```python
%%pyspark  # Exécuter PySpark
%%sql      # Exécuter SQL
%%configure # Configurer Spark session
%run       # Exécuter autre notebook
```

#### Spark Job Definitions
Jobs Spark compilés pour exécution batch.

**Types :**
- JAR (Java/Scala)
- Python files
- SparkR scripts

**Différence avec Notebooks :**
- Notebooks : développement interactif
- Jobs : exécution batch automatisée

### 📊 Cas d'Usage Data Engineering

1. **ETL/ELT Pipelines**
   - Ingestion de sources multiples
   - Transformations Spark
   - Chargement dans Warehouse/Lakehouse

2. **Data Lake Modernization**
   - Migration depuis HDFS/ADLS
   - Architecture Delta Lake
   - Gouvernance avec Purview

3. **Real-Time Processing**
   - Structured Streaming
   - Event processing
   - IoT data pipelines

---

## 2. Data Warehouse

### 🎯 Objectif
Fournir un entrepôt de données relationnel haute performance pour analytics SQL.

### 🧩 Composants

#### Synapse Data Warehouse
Entrepôt de données massivement parallèle (MPP).

**Architecture :**
```
Compute (SQL Pools)
    ↓
Storage (OneLake)
```

**Caractéristiques :**
- T-SQL complet
- Separation compute/storage
- Scaling automatique
- Caching intelligent

**Tables supportées :**
- Tables régulières
- External tables (via Lakehouse)
- Materialized views

#### Distributions
Stratégies de distribution des données :

**1. Round Robin**
```sql
CREATE TABLE staging_data (...)
WITH (DISTRIBUTION = ROUND_ROBIN);
```
- Distribution aléatoire
- Bon pour staging
- Pas de data movement lors JOIN

**2. Hash Distribution**
```sql
CREATE TABLE fact_sales (...)
WITH (DISTRIBUTION = HASH(customer_id));
```
- Distribution par clé
- Optimal pour grandes tables de fait
- Minimise shuffle lors JOIN sur clé de distribution

**3. Replicated**
```sql
CREATE TABLE dim_product (...)
WITH (DISTRIBUTION = REPLICATE);
```
- Copie complète sur chaque nœud
- Idéal pour petites dimensions (<2GB)
- Zero data movement

### 📊 Cas d'Usage Data Warehouse

1. **Enterprise Data Warehouse**
   - Modélisation dimensionnelle
   - Star/Snowflake schema
   - Historisation (SCD Type 2)

2. **Reporting & Analytics**
   - Requêtes complexes
   - Agrégations lourdes
   - Integration Power BI

3. **Data Marts**
   - Marts métier spécialisés
   - Performance optimisée
   - Sécurité granulaire (RLS)

---

## 3. Data Factory

### 🎯 Objectif
Orchestrer l'ingestion et la transformation de données.

### 🧩 Composants

#### Data Pipelines
Workflows d'orchestration visuels (comme Azure Data Factory).

**Activities disponibles :**

**Data Movement:**
- Copy Data
- Delete Data

**Data Transformation:**
- Dataflow Gen2
- Notebook
- Stored Procedure
- Script (SQL, Python)

**Control Flow:**
- If Condition
- Switch
- ForEach
- Until
- Wait
- Webhook

**Example pipeline :**
```
[Copy Activity] → [Notebook Transform] → [Stored Proc] → [Email Notification]
     ↓ (on failure)
[Log Error] → [Alert]
```

#### Dataflows Gen2
Transformations low-code avec Power Query.

**Caractéristiques :**
- Interface visuelle
- Langage M
- 100+ connecteurs
- Destinations multiples
- Refresh incrémental

**Différence avec Dataflow Gen1 (Power BI) :**
| Feature | Gen1 | Gen2 |
|---------|------|------|
| Destinations | Power BI only | Lakehouse, Warehouse, KQL |
| Staging | Limited | OneLake native |
| Performance | Medium | Optimized |

### 📊 Cas d'Usage Data Factory

1. **Data Integration**
   - Ingestion multi-sources
   - Orchestration complexe
   - Scheduling

2. **Hybrid Scenarios**
   - On-premises → Cloud
   - Multi-cloud integration
   - Legacy system integration

---

## 4. Data Science

### 🎯 Objectif
Développer et déployer des modèles Machine Learning.

### 🧩 Composants

#### ML Notebooks
Notebooks optimisés pour Data Science.

**Libraries pré-installées :**
- scikit-learn
- TensorFlow
- PyTorch
- XGBoost
- LightGBM
- pandas, numpy

**GPU Support :**
- GPU pools disponibles
- Accélération training
- Deep Learning optimisé

#### MLflow Integration
Plateforme de suivi des experiments ML.

**Fonctionnalités :**
- Tracking (params, metrics, artifacts)
- Model Registry
- Model versioning
- Deployment automation

**Example :**
```python
import mlflow

with mlflow.start_run():
    mlflow.log_param("n_estimators", 100)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.sklearn.log_model(model, "model")
```

#### AutoML
Machine Learning automatisé.

**Tâches supportées :**
- Classification
- Regression
- Forecasting (time series)

**Process :**
1. Upload data
2. Select target column
3. Configure (time limit, metrics)
4. Run AutoML
5. Get best model + insights

### 📊 Cas d'Usage Data Science

1. **Predictive Analytics**
   - Churn prediction
   - Demand forecasting
   - Fraud detection

2. **Recommendation Systems**
   - Product recommendations
   - Content personalization

3. **NLP & Computer Vision**
   - Sentiment analysis
   - Image classification
   - Object detection

---

## 5. Real-Time Analytics

### 🎯 Objectif
Analyser des flux de données en temps réel.

### 🧩 Composants

#### EventStream
Ingestion de flux de données.

**Sources :**
- Azure Event Hubs
- Azure IoT Hub
- Kafka
- Custom apps (API)

**Transformations :**
- Filtering
- Aggregations
- Windowing
- Enrichment

**Destinations :**
- KQL Database
- Lakehouse
- Custom endpoints

#### KQL Database
Base de données optimisée pour time-series.

**Basée sur Azure Data Explorer (Kusto).**

**Caractéristiques :**
- Ingestion temps réel (<1 sec latency)
- Requêtes ultra-rapides
- Compression efficace
- Retention policies

#### Kusto Query Language (KQL)
Langage de requête optimisé pour logs/telemetry.

**Example :**
```kql
Logs
| where TimeGenerated > ago(1h)
| where Level == "Error"
| summarize count() by bin(TimeGenerated, 5m)
| render timechart
```

### 📊 Cas d'Usage Real-Time Analytics

1. **IoT Monitoring**
   - Sensor data analysis
   - Predictive maintenance
   - Anomaly detection

2. **Application Monitoring**
   - Log analytics
   - Performance monitoring
   - Error tracking

3. **Business Metrics**
   - Real-time dashboards
   - KPI tracking
   - Alerting

---

## 6. Power BI

### 🎯 Objectif
Business Intelligence et visualisation de données.

### 🧩 Composants

#### Semantic Models
Modèles de données (anciennement "Datasets").

**Types de connexion :**

**1. Import**
- Données en mémoire
- Performance maximale
- Refresh scheduling requis

**2. DirectQuery**
- Requêtes temps réel
- Pas de limite de taille
- Performance dépend de la source

**3. Direct Lake (NOUVEAU dans Fabric)**
- Lecture directe depuis OneLake
- Performance Import
- Fraîcheur DirectQuery
- **Game changer !**

#### Reports & Dashboards
Visualisations interactives.

**Fonctionnalités :**
- 100+ visualisations
- Interactivité (cross-filtering)
- Drill-through
- Bookmarks
- Mobile layouts

#### Paginated Reports
Rapports formatés pour impression (style SSRS).

### 📊 Cas d'Usage Power BI

1. **Self-Service BI**
   - Rapports adhoc
   - Exploration interactive
   - Data-driven decisions

2. **Operational Reporting**
   - Dashboards KPI
   - Monitoring temps réel
   - Alertes automatiques

---

## 7. Data Activator

### 🎯 Objectif
Automatisation basée sur les données (no-code).

### 🧩 Composants

#### Triggers
Détection de conditions sur les données.

**Types de conditions :**
- Seuils (> 100, < 50)
- Changements (augmentation de 20%)
- Patterns (absence de données)
- Anomalies

#### Actions
Réactions automatiques.

**Actions disponibles :**
- Email notifications
- Teams messages
- Power Automate flows
- Webhooks

**Example :**
```
Trigger: Sales dropped > 20% vs yesterday
  ↓
Action: Send Teams alert to Sales Manager
```

### 📊 Cas d'Usage Data Activator

1. **Alerting**
   - SLA violations
   - Threshold breaches
   - Anomaly alerts

2. **Process Automation**
   - Trigger workflows
   - Update systems
   - Notify stakeholders

---

## Interactions Entre Workloads

### Scénario 1 : Analytics End-to-End

```
[Sources]
  ↓
[Data Factory] → Ingestion
  ↓
[Data Engineering] → Transformation (Lakehouse)
  ↓
[Data Warehouse] → Modélisation (Star schema)
  ↓
[Power BI] → Visualisation (Direct Lake)
  ↓
[Data Activator] → Alertes
```

### Scénario 2 : ML Pipeline

```
[Data Engineering] → Feature engineering
  ↓
[Data Science] → Model training (MLflow)
  ↓
[Data Engineering] → Batch scoring
  ↓
[Power BI] → Predictions visualization
```

### Scénario 3 : Real-Time Monitoring

```
[IoT Devices]
  ↓
[Real-Time Analytics] → EventStream + KQL
  ↓
[Power BI] → Real-time dashboard
  ↓
[Data Activator] → Alerts
```

## Choisir le Bon Workload

| Besoin | Workload Recommandé |
|--------|---------------------|
| ETL large échelle | Data Engineering (Spark) |
| Requêtes SQL complexes | Data Warehouse |
| Ingestion orchestrée | Data Factory |
| Machine Learning | Data Science |
| Streaming analytics | Real-Time Analytics |
| Visualisation BI | Power BI |
| Alertes automatiques | Data Activator |

## Points Clés à Retenir

- 7 workloads couvrent tout le cycle de vie de la donnée
- Chaque workload a ses composants spécialisés
- Integration native entre tous les workloads
- OneLake unifie le stockage
- Choisir le bon workload selon le use case

---

**Prochain fichier :** [04 - Workspaces et Capacités](./04-workspaces-capacites.md)

[⬅️ Fichier précédent](./02-architecture-onelake.md) | [⬅️ Retour au README du module](./README.md)
