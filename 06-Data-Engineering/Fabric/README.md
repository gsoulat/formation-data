# Microsoft Fabric - Cours Complet & Préparation DP-700

## Vue d'ensemble

Ce cours complet sur **Microsoft Fabric** vous prépare à maîtriser la plateforme unifiée de données et d'analytics de Microsoft, tout en vous préparant à la certification **DP-700 : Implementing Data Engineering Solutions Using Microsoft Fabric**.

## Objectifs pédagogiques

À l'issue de ce cours, vous serez capable de :

- ✅ Concevoir et implémenter des architectures data complètes avec Fabric
- ✅ Créer et gérer des Lakehouses et Data Warehouses
- ✅ Construire des pipelines d'ingestion et de transformation de données
- ✅ Utiliser Apache Spark dans Fabric pour le traitement distribué
- ✅ Créer des modèles sémantiques et dashboards Power BI
- ✅ Implémenter des solutions d'analytics temps réel avec KQL
- ✅ Sécuriser et gouverner vos données avec Purview
- ✅ Optimiser les performances et gérer les coûts
- ✅ Mettre en place des pratiques DevOps avec Git integration
- ✅ **Réussir la certification DP-700**

## Prérequis

### Connaissances requises
- Bases SQL (requêtes SELECT, JOIN, GROUP BY)
- Concepts de base en data engineering (ETL, data pipeline)
- Notions Azure (abonnement, ressources, portail)
- Familiarité avec Python (pour les notebooks Spark)

### Environnement technique
- Compte Microsoft 365 avec accès Fabric (trial disponible)
- Navigateur web moderne (Edge, Chrome)
- Python 3.8+ (pour développement local)
- VS Code (recommandé)

## Structure du cours

### 🏗️ Fondations (Semaines 1-2)

#### [Module 01 - Introduction à Microsoft Fabric](./01-Introduction-Fabric/)
- Overview de la plateforme et ses composants
- Architecture OneLake
- Workspaces et capacités
- Licences et pricing

#### [Module 02 - Lakehouse](./02-Lakehouse/)
- Concepts et architecture Lakehouse
- Delta Lake et tables optimisées
- OneLake storage et shortcuts
- Architecture Medallion (Bronze/Silver/Gold)

#### [Module 03 - Data Warehouse](./03-Data-Warehouse/)
- Synapse Data Warehouse
- Tables, distributions, partitions
- T-SQL avancé
- Comparaison Warehouse vs Lakehouse

### 🔄 Ingestion & Transformation (Semaines 3-4)

#### [Module 04 - Data Pipelines](./04-Data-Pipelines/)
- Data Factory integration
- Création de pipelines
- Copy activities et transformations
- Orchestration et scheduling
- Chargement incrémental

#### [Module 05 - Dataflows Gen2](./05-Dataflows-Gen2/)
- Power Query integration
- Transformations avec langage M
- Destinations multiples
- Refresh incrémental

#### [Module 06 - Notebooks & Spark](./06-Notebooks-Spark/)
- Notebooks Fabric et Spark pools
- PySpark avancé
- DataFrames et transformations
- Optimisation Spark jobs

### 📊 Analytics & Visualisation (Semaine 5)

#### [Module 07 - Semantic Models & Power BI](./07-Semantic-Models-PowerBI/)
- Modèles sémantiques dans Fabric
- Direct Lake mode
- DAX : CALCULATE, FILTER, contextes
- Performance Analyzer
- Best practices de modélisation

#### [Module 08 - Real-Time Analytics](./08-Real-Time-Analytics/)
- EventStream pour streaming
- KQL Database
- Kusto Query Language (KQL)
- Dashboards temps réel
- Activator et alertes

### 🔒 Sécurité & Gouvernance (Semaine 6)

#### [Module 09 - Sécurité & Gouvernance](./09-Securite-Gouvernance/)
- Workspace security
- Row-Level Security (RLS)
- Column-Level Security (CLS)
- Dynamic Data Masking
- Purview integration et data lineage
- Sensitivity labels et compliance

### 🤖 Data Science & ML (Semaine 7)

#### [Module 10 - Data Science & Machine Learning](./10-Data-Science-ML/)
- ML dans Fabric
- MLflow et experiments
- AutoML Fabric
- Feature Store
- Déploiement de modèles ML
- Pipelines Spark ML

### ⚡ Performance & Administration (Semaine 8)

#### [Module 11 - Optimisation des performances](./11-Optimisation-Performance/)
- V-Order optimization
- Stratégies de partitionnement
- Mécanismes de cache
- Query optimization
- Spark tuning
- Monitoring et troubleshooting

#### [Module 12 - Administration & Monitoring](./12-Administration-Monitoring/)
- Capacités F-SKU
- Capacity management
- Trial vs Premium
- Capacity Metrics App
- Cost optimization
- Log Analytics integration

### 🚀 DevOps & Migration (Semaine 9)

#### [Module 13 - DevOps & CI/CD](./13-DevOps-CI-CD/)
- Git integration dans Fabric
- Branching strategies
- Deployment pipelines
- Azure DevOps integration
- Automation via APIs

#### [Module 14 - Migration & Intégration](./14-Migration-Integration/)
- Migration depuis Azure Synapse
- Architectures hybrides
- Patterns d'intégration
- Sources de données externes
- Scénarios multi-cloud

### 🎓 Préparation Certification (Semaine 10)

#### [Module 15 - Préparation DP-700](./15-Preparation-DP700/)
- Overview de l'examen DP-700
- Skills measured
- Plan d'étude
- Patterns architecturaux
- Use cases et scenarios
- Tips et stratégies
- Questions pratiques
- Labs hands-on

## 🛠️ Projets Pratiques

Les projets vous permettent de mettre en pratique l'ensemble des compétences acquises :

1. **[Lakehouse ETL Pipeline](./Projets/01-Lakehouse-ETL-Pipeline/)** - Pipeline complet d'ingestion et transformation
2. **[Real-Time Dashboard](./Projets/02-Real-Time-Dashboard/)** - Dashboard temps réel avec EventStream et KQL
3. **[Data Warehouse Analytics](./Projets/03-Data-Warehouse-Analytics/)** - Entrepôt de données avec modélisation dimensionnelle
4. **[ML Pipeline End-to-End](./Projets/04-ML-Pipeline-End-to-End/)** - Pipeline ML complet dans Fabric
5. **[Gouvernance & Sécurité](./Projets/05-Gouvernance-Securite/)** - Implémentation sécurité et gouvernance
6. **[Migration Synapse → Fabric](./Projets/06-Migration-Synapse-Fabric/)** - Migration d'une architecture existante

## 📚 Ressources

### [Cheatsheets](./Ressources/cheatsheets/)
- DAX Cheatsheet
- KQL Cheatsheet
- Spark Cheatsheet
- M (Power Query) Cheatsheet

### [Templates](./Ressources/templates/)
- Pipeline templates
- Notebook templates
- Deployment templates

### [Datasets](./Ressources/datasets/)
- Jeux de données pour les exercices et projets

## 🎯 Mapping avec DP-700

| Domaine d'examen DP-700 | % Exam | Modules concernés |
|------------------------|---------|-------------------|
| **Implement and manage an analytics solution** | 25-30% | 01, 04, 05, 12, 13 |
| **Ingest and transform data** | 30-35% | 02, 03, 04, 05, 06 |
| **Monitor and optimize an analytics solution** | 20-25% | 11, 12 |
| **Implement and manage security** | 15-20% | 09, 12 |

## 📅 Planning recommandé (10 semaines)

```
Semaines 1-2  : Fondations (Modules 01-03)
Semaines 3-4  : Ingestion/Transformation (Modules 04-06)
Semaine 5     : Analytics & Visualisation (Modules 07-08)
Semaine 6     : Sécurité & Gouvernance (Module 09)
Semaine 7     : ML & Data Science (Module 10)
Semaine 8     : Performance & Admin (Modules 11-12)
Semaine 9     : DevOps & Migration (Modules 13-14)
Semaine 10    : Préparation exam + Projets (Module 15)
```

## 🔗 Liens utiles

### Documentation officielle
- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [DP-700 Exam Page](https://learn.microsoft.com/certifications/exams/dp-700)
- [Microsoft Learn - Fabric Learning Path](https://learn.microsoft.com/training/browse/?products=fabric)

### Communauté
- [Fabric Community Forum](https://community.fabric.microsoft.com/)
- [Fabric Blog](https://blog.fabric.microsoft.com/)
- [GitHub - Fabric Samples](https://github.com/microsoft/fabric-samples)

## 📝 Évaluation et certification

### Évaluation continue
- Quiz à la fin de chaque module
- Exercices pratiques hands-on
- 6 projets fil rouge avec correction

### Certification DP-700
- **Durée** : 120 minutes
- **Format** : QCM, case studies, questions pratiques
- **Score** : 700/1000 minimum
- **Validité** : 1 an
- **Coût** : ~165 USD

## 🤝 Contribution

Ce cours est maintenu et mis à jour régulièrement. Pour toute suggestion ou correction :
1. Ouvrir une issue
2. Proposer une pull request
3. Contacter les formateurs

## 📜 Licence

© 2025 - Simplon Formation
Ce matériel pédagogique est fourni à des fins éducatives uniquement.

---

**Prêt à démarrer ?** 🚀 Commencez par le [Module 01 - Introduction à Fabric](./01-Introduction-Fabric/)
