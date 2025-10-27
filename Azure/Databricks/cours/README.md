# Formation Azure Databricks

Formation complète sur Azure Databricks couvrant Data Engineering, Analytics et Machine Learning.

## 📋 Vue d'ensemble

Cette formation vous apprend à utiliser Azure Databricks, la plateforme d'analyse unifiée basée sur Apache Spark. Vous découvrirez comment construire des pipelines de données robustes, effectuer des analyses à grande échelle et déployer des modèles de Machine Learning en production.

**Durée totale :** 4-5 heures
**Niveau :** Intermédiaire
**Prérequis :**
- Connaissance de base d'Azure
- Notions de programmation Python ou SQL
- Compréhension des concepts de Big Data (recommandé)
- Un abonnement Azure actif pour les exercices pratiques

## 🎯 Objectifs pédagogiques

À l'issue de cette formation, vous serez capable de :

- ✅ Comprendre l'architecture et les composants d'Azure Databricks
- ✅ Créer et gérer des workspaces et clusters
- ✅ Développer dans des notebooks avec Python, SQL, Scala et R
- ✅ Traiter des données massives avec Apache Spark
- ✅ Implémenter une architecture Lakehouse avec Delta Lake
- ✅ Orchestrer des pipelines avec Databricks Workflows
- ✅ Développer et déployer des modèles ML avec MLflow
- ✅ Optimiser les performances et gérer les coûts
- ✅ Appliquer les bonnes pratiques de sécurité et gouvernance

## 📚 Structure du cours

### Partie 1 : Introduction à Azure Databricks (30 min)
- Qu'est-ce qu'Azure Databricks ?
- Architecture et composants clés
- Cas d'usage et avantages
- Databricks vs autres solutions Azure
- Lakehouse Architecture

### Partie 2 : Configuration et Workspace (40 min)
- Création d'un workspace Databricks
- Configuration réseau et sécurité
- Gestion des clusters
- Types de clusters et configurations
- Autoscaling et optimisation des coûts

### Partie 3 : Notebooks et langages (45 min)
- Introduction aux notebooks
- Python, SQL, Scala et R
- Magic commands et widgets
- Visualisations de données
- Collaboration et partage

### Partie 4 : Apache Spark et traitement de données (50 min)
- Architecture Apache Spark
- DataFrames et Datasets
- Transformations et actions
- Spark SQL
- Optimisation des performances

### Partie 5 : Delta Lake et gestion des données (45 min)
- Introduction à Delta Lake
- Transactions ACID
- Time Travel et versioning
- Optimisation et maintenance
- Streaming avec Delta Lake

### Partie 6 : Workflows et orchestration (40 min)
- Databricks Workflows
- Création de Jobs et Tasks
- Gestion des dépendances
- Planification et déclenchement
- Monitoring et alertes

### Partie 7 : Machine Learning et MLflow (50 min)
- MLflow et ML lifecycle
- Tracking d'expériences
- Model Registry
- AutoML
- Déploiement et serving
- MLOps

## 🚀 Utilisation

### Option 1 : Consultation directe

Ouvrez simplement le fichier `index.html` dans votre navigateur pour accéder au cours complet.

```bash
# Depuis le terminal
open cours/index.html

# Ou avec un navigateur spécifique
firefox cours/index.html
chrome cours/index.html
```

### Option 2 : Serveur local

Pour une meilleure expérience, lancez un serveur HTTP local :

```bash
# Avec Python 3
cd cours
python -m http.server 8000

# Avec Node.js
npx http-server cours -p 8000

# Puis ouvrez http://localhost:8000 dans votre navigateur
```

### Option 3 : Hébergement web

Hébergez le contenu sur un serveur web (Apache, Nginx, Azure Static Web Apps, etc.) pour le rendre accessible à votre équipe.

## 📖 Parcours d'apprentissage recommandé

### Semaine 1 : Fondamentaux
- **Jour 1 :** Parties 1 et 2 - Introduction et configuration
- **Jour 2 :** Partie 3 - Notebooks et langages
- **Jour 3 :** Partie 4 - Apache Spark
- **Jour 4 :** Exercices pratiques sur les parties 1-4

### Semaine 2 : Data Engineering avancé
- **Jour 1 :** Partie 5 - Delta Lake
- **Jour 2 :** Partie 6 - Workflows
- **Jour 3 :** Partie 7 - Machine Learning
- **Jour 4 :** Projet fil rouge complet
- **Jour 5 :** Brief pratique (voir `brief.md`)

## 🛠️ Technologies utilisées

- **Frontend :** HTML5, CSS3, JavaScript
- **Styling :** CSS Grid et Flexbox personnalisés
- **Syntax highlighting :** Prism.js
- **Fonts :** Google Fonts (Inter, JetBrains Mono)

## 📊 Contenu du repository

```
Azure/Databricks/
├── brief.md                  # Brief d'exercice pratique
├── cours/
│   ├── index.html           # Page d'accueil du cours
│   ├── README.md            # Ce fichier
│   ├── assets/
│   │   └── styles.css       # Feuille de style CSS
│   └── parties/
│       ├── partie1.html     # Introduction
│       ├── partie2.html     # Configuration
│       ├── partie3.html     # Notebooks
│       ├── partie4.html     # Spark
│       ├── partie5.html     # Delta Lake
│       ├── partie6.html     # Workflows
│       └── partie7.html     # Machine Learning
```

## 🎓 Certifications et ressources

### Certifications Microsoft recommandées
- **DP-203:** Data Engineering on Microsoft Azure
- **DP-100:** Designing and Implementing a Data Science Solution on Azure

### Documentation officielle
- [Azure Databricks Documentation](https://docs.microsoft.com/azure/databricks/)
- [Databricks Knowledge Base](https://kb.databricks.com/)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [Delta Lake Documentation](https://docs.delta.io/)

### Ressources complémentaires
- [Databricks Academy](https://academy.databricks.com/)
- [Databricks Community Edition](https://community.cloud.databricks.com/) (gratuit)
- [Microsoft Learn - Databricks](https://learn.microsoft.com/training/browse/?products=azure-databricks)

## 💡 Bonnes pratiques

1. **Sécurité**
   - Toujours utiliser Premium tier en production
   - Configurer l'authentification Azure AD
   - Activer les audit logs
   - Utiliser des secrets pour les credentials

2. **Performance**
   - Activer l'autoscaling sur les clusters
   - Utiliser Delta Lake pour toutes les tables
   - Optimiser régulièrement avec OPTIMIZE et Z-ORDER
   - Monitorer l'utilisation avec Azure Cost Management

3. **Développement**
   - Intégrer Git pour le version control
   - Utiliser des notebooks paramétrables avec widgets
   - Documenter le code avec des cellules Markdown
   - Tester le code avant de déployer en production

4. **MLOps**
   - Tracker toutes les expériences avec MLflow
   - Utiliser Model Registry pour la gestion des versions
   - Implémenter des tests de validation automatiques
   - Monitorer les modèles en production

## 🤝 Support et contributions

Pour des questions ou suggestions d'amélioration :
- Contactez l'équipe de formation Simplon
- Consultez la documentation officielle Azure Databricks
- Participez aux forums Databricks Community

## 📝 Notes de version

**Version 1.0 (2024)**
- Cours complet sur Azure Databricks
- 7 modules couvrant tous les aspects
- Exemples de code Python et SQL
- Exercices pratiques et brief
- Compatible avec Databricks Runtime 13.x

## 📄 Licence

Ce contenu de formation est destiné à un usage pédagogique dans le cadre de la formation Simplon.

---

**Bonne formation ! 🚀**
