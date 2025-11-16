# Templates Fabric

Collection de templates réutilisables pour accélérer le développement sur Microsoft Fabric.

## Templates Disponibles

### 1. Notebook ETL Template
**Fichier:** `notebook-etl-template.py`

Template complet pour pipelines ETL dans Fabric Notebooks avec :
- Configuration paramétrable
- Gestion des watermarks (incremental load)
- Validation de qualité des données
- Logging et monitoring
- Gestion des erreurs
- Pattern Extract-Transform-Load

**Usage:**
```python
# Copier le template dans un nouveau notebook
# Personnaliser les paramètres:
PIPELINE_NAME = "your_pipeline_name"
SOURCE_PATH = "Files/raw/source_data/"
TARGET_TABLE = "lakehouse.your_target_table"
```

### 2. Semantic Model DAX Template
**Fichier:** `semantic-model-dax-template.md`

Collection de 50+ mesures DAX prêtes à l'emploi :
- Mesures de base (Sales, Profit, Margin)
- Time Intelligence (YTD, MTD, YoY Growth)
- Customer Analytics (CLV, Retention, New/Lost)
- Product Analytics (Ranking, ABC Analysis)
- KPIs et Targets
- Dynamic measures

**Usage:**
```dax
-- Copier les mesures dans votre semantic model
-- Adapter les noms de tables et colonnes
Total Sales = SUM(Fact_Sales[SalesAmount])
Sales YoY Growth = ...
```

### 3. Data Pipeline Template
**Fichier:** `data-pipeline-template.json`

Template JSON pour Fabric Data Pipelines avec pattern incremental load :
- Watermark management
- Data quality checks
- Error handling et alertes
- Logging d'exécution
- Paramètres configurables

**Usage:**
1. Importer le JSON dans Fabric Data Pipeline
2. Modifier les paramètres (SourceTable, TargetTable, etc.)
3. Configurer les connexions
4. Tester et déployer

### 4. RLS Security Template
**Fichier:** `rls-security-template.sql`

Template complet pour implémenter Row-Level Security :
- Tables de mapping utilisateur-permissions
- Fonctions de filtrage
- DAX filters pour semantic models
- Audit et monitoring
- Procédures de maintenance
- Tests de validation

**Usage:**
1. Exécuter les scripts CREATE TABLE
2. Populer avec vos données utilisateurs
3. Appliquer les filtres DAX dans votre semantic model
4. Configurer l'audit

## Structure Recommandée

```
Votre_Projet_Fabric/
├── Notebooks/
│   ├── ETL/
│   │   ├── bronze_layer.py (basé sur notebook-etl-template.py)
│   │   ├── silver_layer.py
│   │   └── gold_layer.py
│   └── ML/
│       └── model_training.py
├── Pipelines/
│   ├── daily_incremental.json (basé sur data-pipeline-template.json)
│   └── weekly_full_refresh.json
├── SemanticModels/
│   └── measures.dax (basé sur semantic-model-dax-template.md)
└── Security/
    └── rls_implementation.sql (basé sur rls-security-template.sql)
```

## Bonnes Pratiques

### Personnalisation des Templates
1. **Ne jamais modifier les templates originaux** - Copier et adapter
2. **Documenter les modifications** - Ajouter des commentaires
3. **Versionner** - Utiliser Git pour suivre les changements
4. **Tester** - Valider dans un environnement non-production d'abord

### Naming Conventions
- Notebooks: `<layer>_<domain>_<action>.py` (ex: `bronze_sales_ingestion.py`)
- Pipelines: `<frequency>_<domain>_<type>` (ex: `daily_sales_incremental`)
- Tables: `<layer>_<domain>_<entity>` (ex: `gold_sales_customer_summary`)

### Paramétrage
Toujours externaliser les configurations :
- Chemins de fichiers
- Noms de tables
- Seuils de qualité
- URLs de services

## Guide de Sélection

| Besoin | Template à Utiliser |
|--------|---------------------|
| Ingestion de données | notebook-etl-template.py |
| Rapports Power BI | semantic-model-dax-template.md |
| Orchestration | data-pipeline-template.json |
| Sécurité des données | rls-security-template.sql |

## Contribution

Pour ajouter de nouveaux templates :
1. Créer le fichier avec documentation inline
2. Ajouter une section dans ce README
3. Inclure des exemples d'utilisation
4. Tester dans un environnement Fabric

---

**Dernière mise à jour:** 2024

[⬅️ Retour aux ressources](../README.md)
