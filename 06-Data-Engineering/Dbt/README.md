# Formation DBT Cloud - Analyse des données Airbnb

Ce cours vous guidera à travers l'utilisation de DBT Cloud pour transformer et analyser des données Airbnb. Vous apprendrez à construire un pipeline de données robuste en utilisant les bonnes pratiques de l'ingénierie des données.

## 🎯 Objectifs pédagogiques

À la fin de ce cours, vous serez capable de :
- Configurer un projet DBT Cloud connecté à Snowflake
- Créer des modèles de transformation de données
- Implémenter différents types de matérialisations
- Gérer les dépendances et la lignée des données
- Mettre en place des tests de qualité
- Développer des modèles incrémentaux

## 📊 Le jeu de données Airbnb

### Source
Le jeu de données provient de [Inside Airbnb](https://insideairbnb.com/get-the-data/) pour la ville d'Amsterdam, extrait du 11 Mars 2024.

### Structure des données
1. **listings** : Informations sur les logements Airbnb
2. **hosts** : Données sur les hôtes
3. **reviews** : Dates des commentaires par listing

## 📚 Contenu du cours

### [Chapitre 0 : Guide des commandes DBT](docs/chapitre-0-commandes-dbt.md)
- Commandes essentielles de développement
- Workflows typiques et bonnes pratiques
- Sélecteurs avancés et optimisations

### [Chapitre 1 : Configuration de l'environnement](docs/chapitre-1-environnement.md)
- Configuration de Snowflake
- Chargement des données
- Préparation de DBT Cloud

### [Chapitre 2 : Initialisation du projet DBT Cloud](docs/chapitre-2-initialisation.md)
- Création du projet
- Configuration de la connexion Snowflake
- Structure du projet

### [Chapitre 3 : Premiers modèles](docs/chapitre-3-premiers-modeles.md)
- Création des modèles de curation
- Transformation des données hosts et listings
- Bonnes pratiques SQL

### [Chapitre 4 : Matérialisations](docs/chapitre-4-materialisations.md)
- Types de matérialisations (view, table, incremental)
- Configuration des schémas
- Optimisation des performances

### [Chapitre 5 : Lignée et dépendances](docs/chapitre-5-lineage.md)
- Définition des sources
- Gestion des seeds
- Snapshots et historisation

### [Chapitre 6 : Tests de qualité](docs/chapitre-6-tests.md)
- Tests de sources
- Tests de modèles
- Tests unitaires
- Packages DBT Utils

### [Chapitre 7 : Modèles incrémentaux](docs/chapitre-7-incremental.md)
- Configuration incremental
- Gestion des mises à jour
- Optimisation des performances

## 🚀 Prérequis

- Accès à Snowflake
- Compte DBT Cloud
- Connaissance de base en SQL
- Familiarité avec les concepts de data warehousing

## 🛠️ Architecture cible

```
RAW (Sources) → CURATION (Nettoyage) → ANALYTICS (Agrégations)
```

## 📁 Structure du projet

```
dbt-cloud-airbnb/
├── models/
│   ├── sources/
│   ├── curation/
│   └── analytics/
├── seeds/
├── snapshots/
├── tests/
├── macros/
└── docs/
```

---