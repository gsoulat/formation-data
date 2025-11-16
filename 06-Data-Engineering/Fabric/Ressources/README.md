# Ressources - Microsoft Fabric

Ce dossier contient des ressources complémentaires pour faciliter votre apprentissage et votre travail quotidien avec Microsoft Fabric.

## 📚 Cheatsheets

Des aide-mémoires concis pour les langages et outils principaux :

### [DAX Cheatsheet](./cheatsheets/dax-cheatsheet.md)
Fonctions DAX essentielles pour Power BI et Semantic Models
- Fonctions de base (SUM, COUNT, AVERAGE...)
- Time intelligence (YTD, QTD, YoY...)
- CALCULATE et modificateurs de contexte
- Fonctions de table (FILTER, ALL, VALUES...)
- Exemples pratiques

### [KQL Cheatsheet](./cheatsheets/kql-cheatsheet.md)
Kusto Query Language pour Real-Time Analytics
- Opérateurs de base (where, project, extend...)
- Agrégations (summarize, count, avg...)
- Time series functions
- Joins et unions
- Visualisations (render)

### [Spark Cheatsheet](./cheatsheets/spark-cheatsheet.md)
PySpark pour traitement de données distribué
- DataFrame operations
- Transformations vs Actions
- SQL API
- Optimisations
- UDFs et fonctions avancées

### [M (Power Query) Cheatsheet](./cheatsheets/m-language-cheatsheet.md)
Langage M pour Dataflows Gen2 et Power Query
- Data types et expressions Let
- Fonctions de table (SelectRows, AddColumn, Group, Join...)
- Fonctions de texte, nombres, dates
- Fonctions de liste et record
- Custom functions avec documentation
- Performance tips et query folding

## 📂 Templates

Des modèles réutilisables pour démarrer rapidement :

### [README Templates](./templates/README.md)
Guide complet d'utilisation des templates.

### Notebook Template
- [`notebook-etl-template.py`](./templates/notebook-etl-template.py) - Template ETL complet avec:
  - Gestion des watermarks (incremental load)
  - Data quality validation
  - Logging et monitoring
  - Error handling
  - Extract-Transform-Load pattern

### DAX Measures Template
- [`semantic-model-dax-template.md`](./templates/semantic-model-dax-template.md) - 50+ mesures DAX prêtes à l'emploi:
  - Base measures (Sales, Profit, Margin)
  - Time intelligence (YTD, MTD, YoY Growth)
  - Customer Analytics (CLV, Retention)
  - Product Analytics (Ranking, ABC)
  - KPIs and Targets
  - Dynamic measures

### Pipeline Template
- [`data-pipeline-template.json`](./templates/data-pipeline-template.json) - Template Data Pipeline:
  - Incremental load pattern
  - Watermark management
  - Data quality checks
  - Alerting
  - Logging

### Security Template
- [`rls-security-template.sql`](./templates/rls-security-template.sql) - Row-Level Security:
  - User-permission mapping tables
  - DAX filter expressions
  - Audit logging
  - Maintenance procedures
  - Testing scripts

## 📊 Datasets

Jeux de données d'exemple pour les exercices :

### Sample Data
- `retail_sales.csv` - Données de ventes retail (100K lignes)
- `customer_data.csv` - Base clients (50K clients)
- `product_catalog.json` - Catalogue produits (10K produits)
- `iot_telemetry.json` - Données IoT simulées
- `web_logs.json` - Logs web serveur

### Datasets par taille
- **Small** (< 10 MB) : Tests et développement
- **Medium** (10-100 MB) : Exercices pratiques
- **Large** (100 MB - 1 GB) : Simulation production
- **XLarge** (> 1 GB) : Tests performance (téléchargement séparé)

## 🔗 Liens Utiles

### Documentation Officielle
- [Microsoft Fabric Documentation](https://learn.microsoft.com/fabric/)
- [Power BI Documentation](https://learn.microsoft.com/power-bi/)
- [Azure Data Factory](https://learn.microsoft.com/azure/data-factory/)
- [Apache Spark](https://spark.apache.org/docs/latest/)

### Learning Paths Microsoft Learn
- [Get started with Microsoft Fabric](https://learn.microsoft.com/training/paths/get-started-fabric/)
- [Implement a Lakehouse with Microsoft Fabric](https://learn.microsoft.com/training/paths/implement-lakehouse-microsoft-fabric/)
- [DP-700 Certification Path](https://learn.microsoft.com/training/courses/dp-700)

### Communauté
- [Fabric Community Forum](https://community.fabric.microsoft.com/)
- [Power BI Community](https://community.powerbi.com/)
- [r/MicrosoftFabric (Reddit)](https://reddit.com/r/microsoftfabric)
- [Stack Overflow - fabric tag](https://stackoverflow.com/questions/tagged/microsoft-fabric)

### Blogs
- [Microsoft Fabric Blog](https://blog.fabric.microsoft.com/)
- [Power BI Blog](https://powerbi.microsoft.com/blog/)
- [SQLBI Blog (DAX experts)](https://www.sqlbi.com/blog/)

### YouTube Channels
- [Microsoft Fabric](https://www.youtube.com/@MicrosoftFabric)
- [Guy in a Cube](https://www.youtube.com/c/GuyinaCube)
- [SQLBI](https://www.youtube.com/user/sqlbi)

### Outils
- [DAX Studio](https://daxstudio.org/) - Query and optimize DAX
- [Tabular Editor](https://tabulareditor.com/) - Advanced model editing
- [Azure Storage Explorer](https://azure.microsoft.com/features/storage-explorer/) - Explore OneLake
- [VS Code with extensions](https://code.visualstudio.com/) - Development

### GitHub Repositories
- [Microsoft Fabric Samples](https://github.com/microsoft/fabric-samples)
- [Power BI Samples](https://github.com/microsoft/PowerBI-visuals)
- [Awesome Fabric](https://github.com/topics/microsoft-fabric)

## 📖 Livres Recommandés

### DAX & Power BI
- **"The Definitive Guide to DAX" (2nd Ed)** - Russo & Ferrari (SQLBI)
- **"Analyzing Data with Power BI and Power Pivot for Excel"** - Russo & Ferrari

### Data Engineering
- **"Fundamentals of Data Engineering"** - Joe Reis & Matt Housley
- **"Designing Data-Intensive Applications"** - Martin Kleppmann

### Spark
- **"Learning Spark" (2nd Ed)** - Damji, Wenig, Das, Lee
- **"Spark: The Definitive Guide"** - Chambers & Zaharia

### Architecture & Patterns
- **"The Data Warehouse Toolkit" (3rd Ed)** - Kimball & Ross
- **"Building the Data Lakehouse"** - Bill Inmon

## 🎯 Certifications

### Microsoft Fabric & Data
- **DP-700** : Implementing Data Engineering Solutions Using Microsoft Fabric
- **DP-600** : Implementing Analytics Solutions Using Microsoft Fabric
- **PL-300** : Microsoft Power BI Data Analyst
- **DP-203** : Data Engineering on Microsoft Azure

### Autres certifications utiles
- **AZ-900** : Azure Fundamentals
- **DP-900** : Azure Data Fundamentals
- **AI-900** : Azure AI Fundamentals

## 💡 Tips & Best Practices

### Fabric en Général
- Toujours utiliser OneLake pour le stockage centralisé
- Privilégier Direct Lake pour Power BI quand possible
- Documenter vos solutions
- Utiliser Git integration pour version control

### Performance
- Partitionner les grandes tables par date
- Activer V-Order sur tables fréquemment lues
- Utiliser shortcuts plutôt que copier des données
- OPTIMIZE régulièrement les tables Delta

### Sécurité
- Implémenter RLS pour données sensibles
- Utiliser sensitivity labels
- Principe du moindre privilège
- Audit logs activés

### Coûts
- Right-size vos capacités
- Auto-pause pour dev/test
- Scheduler les jobs batch off-peak
- Monitor avec Capacity Metrics App

## 📬 Contribution

Vous avez des ressources utiles à partager ? N'hésitez pas à contribuer :

1. Ajouter votre ressource dans le dossier approprié
2. Mettre à jour ce README
3. Créer une pull request

## 📝 Licence

Ces ressources sont fournies à des fins éducatives uniquement.

---

[⬅️ Retour au sommaire du cours](../README.md)
