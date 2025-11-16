# Overview de Microsoft Fabric

## Qu'est-ce que Microsoft Fabric ?

Microsoft Fabric est une **plateforme unifiée de données et d'analytics** (SaaS - Software as a Service) qui rassemble tous les services nécessaires pour gérer le cycle de vie complet de la donnée, de l'ingestion à la consommation.

### Vision : "One Lake, One Platform"

Fabric repose sur un concept révolutionnaire : **un seul lac de données unifié (OneLake)** qui sert de fondation à tous les workloads.

```
┌──────────────────────────────────────────────────────────┐
│                    Microsoft Fabric                       │
├──────────────────────────────────────────────────────────┤
│  Data       Data      Data      Real-Time   Power  Data  │
│  Factory    Warehouse Science   Analytics   BI     Activ │
├──────────────────────────────────────────────────────────┤
│                      OneLake                              │
│           (Unified Data Lake Storage)                     │
└──────────────────────────────────────────────────────────┘
```

## Évolution depuis Power BI / Synapse / Data Factory

### Avant Fabric (paysage fragmenté)

```
Power BI ────┐
             │
Synapse ─────┼──→ Différents services, silos de données
             │
ADF ─────────┤
             │
ADLS Gen2 ───┘
```

**Problèmes :**
- Données dupliquées entre services
- Complexité d'intégration
- Gestion multi-outils
- Coûts de transfert de données
- Courbe d'apprentissage élevée

### Avec Fabric (plateforme unifiée)

```
┌────────────────────────────────────────┐
│         Microsoft Fabric               │
│  ┌─────────────────────────────────┐   │
│  │         OneLake                 │   │
│  │  (Single Source of Truth)       │   │
│  └─────────────────────────────────┘   │
│                  ↕                     │
│  ┌────┬────┬────┬────┬────┬────┐      │
│  │ DF │ DW │ DS │ RTA│ PBI│ DA │      │
│  └────┴────┴────┴────┴────┴────┘      │
└────────────────────────────────────────┘
```

**Avantages :**
- ✅ Données centralisées (zéro copie)
- ✅ Une seule plateforme à maîtriser
- ✅ Intégration native entre workloads
- ✅ Pas de frais de transfert inter-services
- ✅ Gouvernance unifiée

## Les 7 Workloads Principaux

### 1. Data Engineering
**Objectif :** Ingestion et transformation de données à grande échelle

**Composants :**
- **Lakehouse** : Stockage unifié (data lake + warehouse)
- **Notebooks** : Développement Spark (Python, Scala, R, SQL)
- **Spark Jobs** : Traitement distribué

**Use cases :**
- ETL/ELT pipelines
- Data cleaning et transformation
- Architecture Medallion (Bronze/Silver/Gold)

### 2. Data Warehouse
**Objectif :** Analytics SQL haute performance

**Composants :**
- **Synapse Data Warehouse** : Entrepôt de données relationnel
- **T-SQL** : Requêtes et transformations

**Use cases :**
- Modélisation dimensionnelle (star schema)
- Requêtes analytiques complexes
- Reporting BI

### 3. Data Factory
**Objectif :** Orchestration et intégration de données

**Composants :**
- **Data Pipelines** : Orchestration (comme Azure Data Factory)
- **Dataflows Gen2** : Transformations Power Query (low-code)

**Use cases :**
- Ingestion depuis sources multiples (100+ connecteurs)
- Orchestration de workflows complexes
- Chargements incrémentaux

### 4. Data Science
**Objectif :** Machine Learning et IA

**Composants :**
- **Notebooks ML** : Développement de modèles
- **MLflow** : Suivi des experiments
- **AutoML** : Machine learning automatisé

**Use cases :**
- Entraînement de modèles ML
- Déploiement de modèles
- Feature engineering

### 5. Real-Time Analytics
**Objectif :** Analytics en temps réel sur des flux de données

**Composants :**
- **EventStream** : Ingestion de flux (Event Hub, IoT Hub, Kafka)
- **KQL Database** : Base de données optimisée pour le temps réel
- **KQL Queries** : Kusto Query Language

**Use cases :**
- Monitoring et dashboards temps réel
- Analyse de logs
- IoT analytics

### 6. Power BI
**Objectif :** Business Intelligence et visualisation

**Composants :**
- **Semantic Models** : Modèles de données (anciennement Datasets)
- **Reports & Dashboards** : Visualisations interactives
- **Direct Lake** : Mode de connexion révolutionnaire

**Use cases :**
- Reporting self-service
- Dashboards interactifs
- Embedded analytics

### 7. Data Activator
**Objectif :** Automatisation basée sur les données

**Composants :**
- **Triggers** : Détection de conditions
- **Actions** : Notifications, workflows

**Use cases :**
- Alertes automatiques
- Détection d'anomalies
- Actions automatisées (Teams, email, Power Automate)

## Cas d'Usage Principaux

### 1. Analytics End-to-End

```
[Sources]  →  [Data Factory]  →  [Lakehouse]  →  [Data Warehouse]  →  [Power BI]
           Ingestion        Transformation    Modélisation      Visualisation
```

**Exemple :** Retailer qui analyse ses ventes
- Ingestion : données de ventes depuis SAP, e-commerce, magasins
- Transformation : nettoyage, enrichissement dans Lakehouse
- Modélisation : star schema dans Warehouse
- Visualisation : dashboards Power BI pour managers

### 2. Real-Time Analytics

```
[IoT Devices]  →  [EventStream]  →  [KQL Database]  →  [Real-Time Dashboard]
                                            ↓
                                      [Data Activator]
                                            ↓
                                    [Alerts & Actions]
```

**Exemple :** Usine avec monitoring IoT
- Capteurs envoient métriques en temps réel
- KQL Database stocke et analyse
- Dashboards affichent l'état en direct
- Activator envoie des alertes si anomalie

### 3. Data Science & ML

```
[Historical Data]  →  [Lakehouse]  →  [Notebooks]  →  [MLflow]  →  [Model Deployment]
                                    Feature Engineering  Tracking  Batch/Real-time Scoring
```

**Exemple :** Prédiction de churn client
- Données clients dans Lakehouse
- Feature engineering avec Spark
- Entraînement de modèles dans Notebooks
- Tracking avec MLflow
- Déploiement pour scoring batch

## Architecture Technique Simplifiée

```
┌─────────────────────────────────────────────────────────────┐
│                    FABRIC PLATFORM                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 OneLake (Delta Lake)                 │   │
│  │          • ADLS Gen2 under the hood                  │   │
│  │          • Delta format (Parquet + transaction log)  │   │
│  │          • Multi-workspace sharing                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                            ↕                                │
│  ┌────────────────┬────────────────┬──────────────────┐     │
│  │ Compute        │ Storage        │ Metadata         │     │
│  │ • Spark pools  │ • OneLake      │ • Catalog        │     │
│  │ • SQL engines  │ • Shortcuts    │ • Lineage        │     │
│  │ • Dataflows    │ • Mirroring    │ • Governance     │     │
│  └────────────────┴────────────────┴──────────────────┘     │
│                                                              │
│  Powered by Azure (compute, storage, network, security)     │
└─────────────────────────────────────────────────────────────┘
```

## Différences clés avec les solutions concurrentes

| Fonctionnalité | Fabric | Databricks | Snowflake |
|----------------|--------|------------|-----------|
| **Unified platform** | ✅ (7 workloads) | ⚠️ (focus data + ML) | ⚠️ (focus warehouse) |
| **Native BI** | ✅ (Power BI intégré) | ❌ (tiers tools) | ⚠️ (basic viz) |
| **OneLake (no-copy)** | ✅ | ❌ | ❌ |
| **Real-time analytics** | ✅ (KQL native) | ⚠️ (Spark Streaming) | ⚠️ (Snowpipe) |
| **Pricing** | Pay-as-you-go (CU) | DBU-based | Credit-based |
| **Learning curve** | Medium | High | Medium |

## Avantages de Fabric

### 1. Simplicité
- Une seule plateforme au lieu de 5-6 services
- Interface unifiée
- Gestion centralisée

### 2. Performance
- Pas de mouvement de données (OneLake)
- Direct Lake mode (Power BI lit directement Delta)
- Optimisations natives (V-Order)

### 3. Coût
- Pas de frais de transfert inter-services
- Modèle de pricing transparent (Capacity Units)
- Optimisation automatique du stockage

### 4. Productivité
- Intégration native entre workloads
- Réutilisabilité des assets
- Collaboration facilitée

### 5. Gouvernance
- Purview integration native
- Data lineage automatique
- Security centralisée

## Quand utiliser Fabric ?

### ✅ Fabric est idéal pour :

- Projets analytics end-to-end
- Organisations déjà dans l'écosystème Microsoft
- Besoins BI + Data Engineering + Data Science
- Équipes mixtes (business + IT)
- Volonté de simplifier l'architecture data

### ⚠️ À évaluer si :

- Besoins très spécialisés (ex: HPC scientifique)
- Multi-cloud mandatory (AWS/GCP primary)
- Contraintes de souveraineté (données hors Azure)
- Équipes expertes sur autre plateforme (Databricks)

## Roadmap et Évolution

Fabric est en évolution constante. Microsoft sort de nouvelles fonctionnalités mensuellement.

**Fonctionnalités récentes (2024) :**
- Mirroring (réplication depuis bases externes)
- Copilot pour Fabric (IA générative)
- Notebook scheduling amélioré
- Git integration généralisée

**À venir (Roadmap) :**
- Amélioration performance Direct Lake
- Nouveaux connecteurs
- ML features avancées
- Multi-cloud shortcuts

## Ressources pour aller plus loin

- [Documentation officielle Fabric](https://learn.microsoft.com/fabric/)
- [Fabric Blog](https://blog.fabric.microsoft.com/)
- [Fabric Community](https://community.fabric.microsoft.com/)
- [Vidéo : What is Microsoft Fabric?](https://www.youtube.com/watch?v=X_c7gLfJz_Q)

## Points clés à retenir

- Microsoft Fabric est une plateforme SaaS unifiée pour la data et l'analytics
- OneLake est le cœur de Fabric : un lac de données unique partagé
- 7 workloads principaux couvrent tous les besoins (ingestion → consommation)
- Intégration native entre tous les composants = simplicité et performance
- Direct Lake révolutionne le BI (lecture directe depuis OneLake)
- Modèle de pricing par Capacity Units (CU)

---

**Prochain fichier :** [02 - Architecture OneLake](./02-architecture-onelake.md)

[⬅️ Retour au README du module](./README.md)
