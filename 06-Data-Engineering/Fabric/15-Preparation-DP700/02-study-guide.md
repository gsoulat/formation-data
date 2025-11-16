# DP-700 Study Guide

## Introduction

Ce guide de préparation structuré vous aidera à organiser votre étude pour l'examen DP-700. Il couvre les ressources recommandées, un plan d'étude suggéré, et les techniques d'apprentissage efficaces pour chaque domaine.

## Plan d'Étude Structuré

### Timeline de Préparation (8-12 semaines)

```python
study_plan = {
    'week_1_2': {
        'focus': 'Fondations',
        'topics': [
            'Architecture Microsoft Fabric',
            'OneLake concepts',
            'Workspace management',
            'Capacity sizing'
        ],
        'activities': [
            'Créer un tenant Fabric trial',
            'Explorer l\'interface',
            'Lire la documentation officielle',
            'Suivre le learning path "Get Started"'
        ],
        'time_commitment': '10-15 heures/semaine'
    },
    'week_3_4': {
        'focus': 'Lakehouse & Data Engineering',
        'topics': [
            'Delta Lake features',
            'Medallion architecture',
            'PySpark transformations',
            'Data pipelines'
        ],
        'activities': [
            'Créer un Lakehouse',
            'Implémenter Bronze/Silver/Gold',
            'Écrire des notebooks Spark',
            'Configurer des pipelines'
        ],
        'time_commitment': '12-18 heures/semaine'
    },
    'week_5_6': {
        'focus': 'Data Warehouse',
        'topics': [
            'Fabric Warehouse vs SQL Pool',
            'T-SQL specifics',
            'Slowly Changing Dimensions',
            'Query optimization'
        ],
        'activities': [
            'Créer un Data Warehouse',
            'Implémenter SCD Type 2',
            'Optimiser des requêtes',
            'Configurer la sécurité'
        ],
        'time_commitment': '12-18 heures/semaine'
    },
    'week_7_8': {
        'focus': 'Semantic Models & Power BI',
        'topics': [
            'Direct Lake mode',
            'DAX fundamentals',
            'Model relationships',
            'RLS/OLS'
        ],
        'activities': [
            'Créer un Direct Lake model',
            'Écrire des mesures DAX',
            'Configurer RLS',
            'Performance tuning'
        ],
        'time_commitment': '12-15 heures/semaine'
    },
    'week_9_10': {
        'focus': 'Real-Time Analytics & Advanced Topics',
        'topics': [
            'Eventstreams',
            'KQL databases',
            'Real-time dashboards',
            'DevOps CI/CD'
        ],
        'activities': [
            'Configurer un stream',
            'Écrire des requêtes KQL',
            'Setup Git integration',
            'Deployment pipelines'
        ],
        'time_commitment': '10-12 heures/semaine'
    },
    'week_11_12': {
        'focus': 'Révision & Practice Tests',
        'topics': [
            'Tous les domaines',
            'Points faibles identifiés',
            'Études de cas',
            'Gestion du temps'
        ],
        'activities': [
            'Tests de pratique',
            'Revoir les erreurs',
            'Réviser les concepts clés',
            'Simulation d\'examen complète'
        ],
        'time_commitment': '15-20 heures/semaine'
    }
}
```

## Ressources par Domaine

### 1. Data Foundation (25-30%)

```python
lakehouse_resources = {
    'must_know_concepts': [
        'Delta Lake table format',
        'ACID transactions in Delta',
        'Time Travel queries',
        'V-Order optimization',
        'OneLake shortcuts (S3, ADLS, GCS)',
        'Medallion architecture implementation'
    ],
    'key_documentation': [
        'docs.microsoft.com/fabric/data-engineering/lakehouse-overview',
        'docs.microsoft.com/fabric/onelake/onelake-shortcuts',
        'delta.io documentation'
    ],
    'hands_on_exercises': [
        'Create lakehouse with Bronze/Silver/Gold',
        'Implement MERGE operations',
        'Use TIME TRAVEL to restore data',
        'Configure shortcuts to external storage',
        'Apply Z-ORDER optimization'
    ],
    'sample_code_topics': [
        'CREATE TABLE with Delta format',
        'OPTIMIZE and VACUUM operations',
        'RESTORE TABLE commands',
        'Shortcut creation via API'
    ]
}
```

### 2. Data Transformation (25-30%)

```python
transformation_resources = {
    'must_know_concepts': [
        'Dataflows Gen2 vs Gen1',
        'Data Factory pipelines',
        'Notebook development',
        'PySpark DataFrame operations',
        'Orchestration patterns'
    ],
    'key_skills': {
        'pyspark': [
            'read/write Delta tables',
            'filter, select, groupBy, join',
            'window functions',
            'UDFs (User Defined Functions)',
            'broadcast joins'
        ],
        'pipelines': [
            'Copy activity',
            'ForEach loops',
            'If conditions',
            'Parameters and variables',
            'Triggers (scheduled, tumbling)'
        ],
        'power_query': [
            'M language basics',
            'Table transformations',
            'Custom functions',
            'Error handling'
        ]
    },
    'practice_scenarios': [
        'Incremental data loading',
        'Data quality validation',
        'Slowly changing dimension updates',
        'Error handling and retry logic'
    ]
}
```

### 3. Data Warehouse (20-25%)

```python
warehouse_resources = {
    'sql_skills_required': [
        'DDL: CREATE TABLE, ALTER TABLE',
        'DML: INSERT, UPDATE, DELETE, MERGE',
        'CTAS (CREATE TABLE AS SELECT)',
        'Views and stored procedures',
        'Window functions',
        'CTEs (Common Table Expressions)'
    ],
    'fabric_specific': [
        'Automatic distribution (no HASH/ROUND_ROBIN)',
        'Clustered columnstore indexes',
        'Query insights and statistics',
        'Cross-database queries',
        'T-SQL limitations in Fabric'
    ],
    'design_patterns': [
        'Star schema implementation',
        'SCD Type 1 (overwrite)',
        'SCD Type 2 (historical tracking)',
        'Surrogate keys',
        'Date dimension tables'
    ],
    'study_materials': [
        'Kimball Data Warehouse Toolkit (concepts)',
        'Fabric Warehouse documentation',
        'T-SQL reference for Fabric'
    ]
}
```

### 4. Real-Time Analytics (10-15%)

```python
realtime_resources = {
    'kql_essentials': [
        'where, project, extend',
        'summarize, count, sum, avg',
        'bin() for time aggregation',
        'render for visualization',
        'join operations',
        'time series analysis'
    ],
    'eventstream_config': [
        'Source configuration',
        'Transformations in stream',
        'Destination routing',
        'Error handling'
    ],
    'architecture_patterns': [
        'Hot path (real-time)',
        'Cold path (batch)',
        'Lambda architecture',
        'Kappa architecture'
    ],
    'practice_exercises': [
        'Configure Event Hub source',
        'Write KQL queries for aggregation',
        'Create real-time dashboard',
        'Implement windowed analytics'
    ]
}
```

### 5. Semantic Models (15-20%)

```python
semantic_model_resources = {
    'dax_fundamentals': [
        'CALCULATE function',
        'FILTER context',
        'Time intelligence (YTD, QTD, MTD)',
        'SUMX, AVERAGEX iterators',
        'Variables in measures',
        'ALL, REMOVEFILTERS'
    ],
    'direct_lake_specifics': [
        'Prerequisites (Delta format, V-Order)',
        'Fallback to DirectQuery behavior',
        'Performance characteristics',
        'Limitations vs Import mode'
    ],
    'security_implementation': [
        'Row-Level Security (RLS)',
        'Object-Level Security (OLS)',
        'Dynamic RLS with USERNAME()',
        'Testing security roles'
    ],
    'optimization_techniques': [
        'Reduce model complexity',
        'Use calculated columns wisely',
        'Optimize DAX patterns',
        'Monitor query performance'
    ]
}
```

## Techniques d'Étude Efficaces

### Active Learning Approach

```python
def active_learning_strategy():
    """Stratégie d'apprentissage actif pour DP-700"""

    strategies = {
        'concept_mapping': {
            'description': 'Créer des cartes mentales des concepts',
            'example': 'Diagramme reliant OneLake, Lakehouse, Warehouse, Shortcuts',
            'benefit': 'Visualise les relations entre composants'
        },
        'teach_back_method': {
            'description': 'Expliquer le concept comme si vous enseigniez',
            'example': 'Expliquer Direct Lake à un collègue',
            'benefit': 'Révèle les lacunes de compréhension'
        },
        'hands_on_labs': {
            'description': 'Pratiquer chaque concept dans Fabric',
            'example': 'Implémenter un pipeline ETL complet',
            'benefit': 'Ancre la théorie dans la pratique'
        },
        'spaced_repetition': {
            'description': 'Réviser à intervalles croissants',
            'schedule': 'Jour 1, Jour 3, Jour 7, Jour 14, Jour 30',
            'benefit': 'Améliore la rétention long terme'
        },
        'practice_questions': {
            'description': 'Répondre à des questions similaires à l\'examen',
            'frequency': 'Quotidiennement',
            'benefit': 'Familiarisation avec le format'
        }
    }

    return strategies

def study_session_template(duration_minutes=90):
    """Template pour une session d'étude productive"""

    session = {
        'warm_up': {
            'duration': 10,
            'activity': 'Review previous session notes'
        },
        'new_content': {
            'duration': 30,
            'activity': 'Learn new concept from documentation'
        },
        'practice': {
            'duration': 35,
            'activity': 'Hands-on implementation in Fabric'
        },
        'review': {
            'duration': 10,
            'activity': 'Summarize key learnings'
        },
        'questions': {
            'duration': 5,
            'activity': 'Answer 2-3 practice questions'
        }
    }

    return session
```

## Checklist de Préparation

### Connaissances Théoriques

- [ ] Architecture OneLake et composants
- [ ] Différences Lakehouse vs Warehouse
- [ ] Delta Lake features (ACID, Time Travel, Schema Evolution)
- [ ] Medallion architecture (Bronze/Silver/Gold)
- [ ] Direct Lake vs Import vs DirectQuery
- [ ] Eventstream et Real-Time Analytics
- [ ] Security model (RLS, OLS, workspace roles)
- [ ] Git integration et Deployment Pipelines
- [ ] Capacity management et monitoring

### Compétences Pratiques

- [ ] Créer et configurer un Lakehouse
- [ ] Écrire des transformations PySpark
- [ ] Configurer des pipelines Data Factory
- [ ] Créer un Data Warehouse avec star schema
- [ ] Implémenter des SCD
- [ ] Écrire des mesures DAX
- [ ] Configurer un semantic model Direct Lake
- [ ] Setup Git integration
- [ ] Configurer des eventstreams
- [ ] Écrire des requêtes KQL

### Soft Skills pour l'Examen

- [ ] Gestion du temps (2 min/question max)
- [ ] Lecture attentive des énoncés
- [ ] Élimination des mauvaises réponses
- [ ] Identification des mots-clés dans les questions
- [ ] Ne pas sur-analyser les questions simples

## Points Clés

- Suivre un plan d'étude structuré sur 8-12 semaines
- Équilibrer théorie (documentation) et pratique (labs)
- Focus sur les domaines avec le plus grand poids (Lakehouse, Transformations)
- Pratiquer régulièrement avec des questions d'examen
- Utiliser un environnement Fabric réel pour les exercices
- Réviser les concepts faibles identifiés lors des tests
- Gérer son temps d'étude efficacement
- Ne pas négliger les domaines minoritaires (Real-Time Analytics)

---

**Navigation** : [Précédent : Exam Overview](./01-exam-overview.md) | [Index](../README.md) | [Suivant : Practice Questions](./03-practice-questions.md)
