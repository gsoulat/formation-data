# Formation Simplon - DevOps, Cloud & Data Engineering

Bienvenue dans le repository de formation Simplon ! Ce dépôt contient l'ensemble des ressources pédagogiques pour les parcours DevOps, Cloud et Data Engineering.

## Table des matières

- [À propos](#à-propos)
- [Structure du repository](#structure-du-repository)
- [Technologies couvertes](#technologies-couvertes)
- [Prérequis](#prérequis)
- [Comment utiliser ce repository](#comment-utiliser-ce-repository)
- [Parcours d'apprentissage](#parcours-dapprentissage)
- [Contribution](#contribution)
- [Support](#support)

## À propos

Ce repository regroupe des formations complètes sur les technologies cloud, DevOps et data engineering utilisées en entreprise. Chaque module contient :

- Des cours théoriques (HTML/Markdown)
- Des exercices pratiques
- Des datasets réels
- Des projets guidés (briefs)
- Des ressources complémentaires

## Structure du repository

```
Formation/
├── 00-Brief/              # Projets et cas d'usage réels
├── 01-Basics/             # Technologies fondamentales
│   ├── Bash-Zsh/          # Shell scripting
│   ├── Docker/            # Containerisation
│   ├── Git/               # Gestion de version
│   └── Github/            # Collaboration et CI/CD
├── 02-Python/             # Python et outils data
│   └── DltHub/            # Data Load Tool
├── 03-Devops/             # Pratiques DevOps (à venir)
├── Azure/                 # Écosystème Azure
│   ├── Databricks/        # Analytics et Big Data
│   └── Hadoop/            # Traitement distribué
├── Dbt/                   # Data Build Tool
├── Kubernetes/            # Orchestration de containers
├── MongoDb/               # Base de données NoSQL
├── snowflake/             # Data Warehouse cloud
└── Terraform/             # Infrastructure as Code
    └── azure/             # Terraform pour Azure
```

## Technologies couvertes

### Fondamentaux
- **Bash/Zsh** - Shell scripting et automatisation
- **Git/Github** - Contrôle de version et collaboration
- **Docker** - Containerisation d'applications
- **SQL** - Requêtes et modélisation de données

### Infrastructure as Code
- **Terraform** - Provisionnement d'infrastructure
  - 8 modules de cours
  - 10 exercices pratiques Azure
  - Configuration provider Azure

### Orchestration & Container
- **Kubernetes** - Orchestration de containers
  - 9 modules de cours (déploiements, services, volumes, etc.)
  - Gestion de clusters
  - Helm et applications cloud-native

### Cloud Platforms
- **Azure**
  - Databricks - Analytics et Machine Learning
  - Hadoop - Traitement Big Data
- **Snowflake** - Data Warehouse moderne
  - 8 modules de cours
  - 4 datasets réels (Airbnb, E-commerce, Finance, SaaS)
  - Configuration et monitoring

### Data Engineering
- **Dbt** - Transformation de données
  - 10 modules (commandes, modèles, tests, variables)
  - Best practices data engineering
- **DltHub** - Data Load Tool
- **MongoDb** - Base de données NoSQL
  - 7 modules (introduction → data engineering)

### DevOps (à venir)
- CI/CD pipelines
- Monitoring et observabilité
- GitOps

## Prérequis

### Outils à installer

Consultez le guide d'installation détaillé : [Terraform Azure - README](Terraform/azure/00-README.md)

**Essentiels :**
- Git
- Docker
- Terminal (Bash/Zsh)
- Éditeur de code (VS Code recommandé)

**Cloud & IaC :**
- Azure CLI
- Terraform
- kubectl

**Data :**
- Python 3.8+
- pip/poetry

### Comptes requis

- **GitHub** - Gestion de code
- **Azure** - Cloud computing (subscription active)
- **Snowflake** - Data warehouse (compte trial disponible)

## Comment utiliser ce repository

### 1. Cloner le repository

```bash
git clone <url-du-repo>
cd Formation
```

### 2. Choisir un parcours

Consultez la section [Parcours d'apprentissage](#parcours-dapprentissage) ci-dessous.

### 3. Suivre les modules

Chaque dossier de cours contient :
- Un `README.md` ou `index.html` comme point d'entrée
- Des parties numérotées pour suivre l'ordre
- Des exercices pratiques
- Des ressources complémentaires

### 4. Réaliser les projets

Les briefs de projets sont disponibles dans `00-Brief/` :
- NYC Taxi Data Pipeline
- Data Quality
- ECO2 - RTE Energy Data
- Et plus encore...

## Parcours d'apprentissage

### Parcours Débutant (2-3 mois)

1. **Fondamentaux**
   - 01-Basics/Bash-Zsh
   - 01-Basics/Git
   - 01-Basics/Github
   - 01-Basics/Docker

2. **Premier projet**
   - Choisir un brief simple dans 00-Brief/

### Parcours DevOps (3-4 mois)

1. **Bases** (voir Parcours Débutant)
2. **Infrastructure**
   - Terraform
   - Kubernetes
3. **Projet d'infrastructure**
   - Brief infrastructure avec Terraform

### Parcours Cloud Engineer (4-5 mois)

1. **Bases** + **DevOps**
2. **Cloud Azure**
   - Azure/Databricks
   - Azure/Hadoop
   - Terraform/azure
3. **Data Warehouse**
   - snowflake

### Parcours Data Engineering (4-6 mois)

1. **Bases Python & Docker**
2. **Bases de données**
   - MongoDb
   - SQL
   - snowflake
3. **Transformation de données**
   - Dbt
   - DltHub
4. **Big Data**
   - Azure/Databricks
   - Azure/Hadoop
5. **Projets data**
   - NYC Taxi Pipeline
   - Data Quality

## Contribution

Ce repository est maintenu pour les formations Simplon. Pour toute suggestion :

1. Ouvrir une issue pour discuter du changement
2. Fork le projet
3. Créer une branche (`git checkout -b feature/amelioration`)
4. Commit avec convention ([voir guide](/.github/SEMANTIC_RELEASE.md))
5. Push et créer une Pull Request

### Convention de commits

Ce projet utilise **Semantic Release**. Format des commits :

```
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore
Scopes: terraform, docker, kubernetes, dbt, etc.
```

Exemples :
```bash
feat(kubernetes): ajout cours sur les StatefulSets
fix(terraform): correction configuration Azure provider
docs(readme): mise à jour installation
```

Voir le guide complet : [SEMANTIC_RELEASE.md](.github/SEMANTIC_RELEASE.md)

## Releases

Les releases sont automatiquement créées et documentées dans [CHANGELOG.md](CHANGELOG.md).

Dernières releases : https://github.com/VOTRE_USERNAME/Formation/releases

## Support

### Documentation officielle

Chaque module contient ses propres références vers la documentation officielle.

### Ressources utiles

- [Terraform Docs](https://www.terraform.io/docs)
- [Kubernetes Docs](https://kubernetes.io/docs)
- [Azure Docs](https://docs.microsoft.com/azure/)
- [Snowflake Docs](https://docs.snowflake.com/)
- [Dbt Docs](https://docs.getdbt.com/)

### Aide

- Ouvrir une issue pour les bugs ou questions
- Consulter les README de chaque module
- Contacter votre formateur Simplon

## Statistiques

- **13 technologies** couvertes
- **80+ modules** de cours
- **10+ projets** pratiques
- **4 datasets** réels inclus
- **Mises à jour** régulières

## Licence

Ce contenu est destiné à un usage pédagogique dans le cadre des formations Simplon.

---

**Simplon Formation** - Apprenez par la pratique, formez-vous aux métiers du numérique

Bonne formation ! 🚀
