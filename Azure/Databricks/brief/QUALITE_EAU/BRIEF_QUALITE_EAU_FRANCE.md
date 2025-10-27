# Brief Projet Data Engineering - Pipeline Azure pour l'Analyse de la Qualite de l'Eau en France

## Contexte du projet

L'**Agence Nationale de Securite Sanitaire (ANSES)** supervise la qualite de l'eau potable en France. Les resultats de controle sanitaire de la qualite de l'eau distribuee commune par commune sont publies sur data.gouv.fr.

Vous etes missionne pour construire un **pipeline de donnees complet** permettant d'ingerer, transformer et analyser ces donnees de qualite de l'eau pour produire des insights sur la conformite et la qualite de l'eau en France.

---

## Objectifs du projet

### Objectif principal

Construire un pipeline de donnees moderne sur **Azure Databricks** suivant l'architecture **Medallion (Bronze-Silver-Gold)** pour analyser la qualite de l'eau potable en France.

### Objectifs secondaires

1. **Infrastructure Azure** : Configurer Azure Data Lake Storage Gen2 et Databricks
2. **Ingestion automatisee** : Implementer DLT (Data Load Tool) pour ingerer les donnees
3. **CI/CD** : Mettre en place GitHub Actions avec Semantic Release
4. **Qualite des donnees** : Implementer Great Expectations pour valider la qualite
5. **Orchestration** : Automatiser le pipeline avec Databricks Workflows
6. **API** : Exposer les donnees via l'API Databricks

### Schema final attendu

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INFRASTRUCTURE AZURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐      ┌────────────────────────────────────────────┐   │
│  │   data.gouv.fr   │─────▶│   Azure Data Lake Storage Gen2             │   │
│  │   (Source CSV)   │      │                                            │   │
│  └──────────────────┘      └────────────────────────────────────────────┘   │
│                                           │                                 │
│                                           │                                 │
│                                           ▼                                 │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     AZURE DATABRICKS WORKSPACE                        │  │
│  ├───────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    DATA LOAD TOOL (DLT)  https://dlthub.com/ │  │  │
│  │  │  Pipeline d'ingestion automatisee vers Bronze                   │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  │                              ▼                                        │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │              NOTEBOOKS PYSPARK (Databricks Repos)               │  │  │
│  │  │                                                                 │  │  │
│  │  │  01_DLT_Ingestion_Qualite_Eau.py                                │  │  │
│  │  │  02_Silver_Transformation.py                                    │  │  │
│  │  │  03_Gold_Agregations.py                                         │  │  │
│  │  │  04_Quality_Checks.py (Great Expectations)                      │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  │                              ▼                                        │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                   DATABRICKS WORKFLOWS                          │  │  │
│  │  │  Orchestration automatique du pipeline complet                  │  │  │
│  │  │  Schedule : Quotidien (2h00 Europe/Paris)                       │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                           │                                 │
└───────────────────────────────────────────┼─────────────────────────────────┘
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DEVOPS & CI/CD                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐      ┌────────────────────┐      ┌─────────────────┐  │
│  │  GitHub Repo     │─────▶│  GitHub Actions    │─────▶│   Databricks    │  │
│  │                  │      │                    │      │   Deployment    │  │
│  │  - Notebooks     │      │  - CI : Tests      │      │                 │  │
│  │  - Config        │      │  - CD : Deploy     │      │  (Auto Sync)    │  │
│  │  - Scripts       │      │  - Semantic Release│      │                 │  │
│  └──────────────────┘      └────────────────────┘      └─────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘


LEGENDE :
─────────  Flux de donnees
Bronze     Donnees brutes (CSV ingere)
Silver     Donnees nettoyees et enrichies
Gold       Donnees agreges pour l'analyse
DLT        Data Load Tool https://dlthub.com/

```

---

## Dataset - Qualite de l'Eau en France

### Source

**data.gouv.fr** - Resultats du controle sanitaire de la qualite de l'eau distribuee commune par commune

- **URL** : https://www.data.gouv.fr/datasets/resultats-du-controle-sanitaire-de-leau-distribuee-commune-par-commune/
- **Organisme** : Ministere de la Sante et de la Prevention
- **Mise a jour** : Mensuelle
- **Licence** : Licence Ouverte / Open Licence

### Contenu du dataset

**Periode** : 2021-2025 (donnees en temps reel)

**Format** : CSV

**Taille** : ~50-100 MB (selon extraction)

**Principales colonnes** :

#### Identification
- `Code commune INSEE` : Code INSEE de la commune
- `Nom de la commune` : Nom de la commune
- `Code postal` : Code postal
- `Nom de l'installation de distribution` : Nom du reseau de distribution

#### Parametres de qualite
- `Date du prelevement` : Date de l'analyse
- `Code parametre` : Code du parametre analyse (ex: 1340 pour bacteries)
- `Libelle parametre` : Nom du parametre (ex: "Bacteries aerobies revivifiables a 22°C")
- `Resultat` : Valeur mesuree
- `Unite de mesure` : Unite (UFC/mL, mg/L, etc.)
- `Limite de qualite` : Seuil reglementaire
- `Reference de qualite` : Valeur de reference

#### Conformite
- `Conclusion sur le parametre` : Conforme / Non conforme / Conforme avec remarque
- `Appreciation de la conformite` : Evaluation globale

#### Localisation
- `Coordonnee X` : Longitude
- `Coordonnee Y` : Latitude

### Parametres analyses

Les principaux parametres de qualite de l'eau :

**Microbiologie** :
- Bacteries aerobies revivifiables (22°C et 36°C)
- Escherichia coli
- Enterococques
- Bacteries coliformes

**Chimie** :
- Nitrates (NO3)
- Nitrites (NO2)
- Pesticides et metabolites
- Aluminium, Cuivre, Fer, Plomb
- Fluorures, Chlorures
- pH, Conductivite

**Radioactivite** :
- Tritium
- Dose totale indicative

---

## Technologies utilisees

### Cloud et stockage
- **Microsoft Azure** : Cloud provider
- **Azure Data Lake Storage Gen2** : Stockage des donnees 
- **Azure Databricks** : Plateforme de traitement de donnees https://www.youtube.com/watch?v=XHQTfppfaTM

### Ingestion et transformation
- **DLT (Data Load Tool)** : Outil d'ingestion Databricks (OPTIONNEL) sinon requests https://dlthub.com/
- **PySpark** : Transformations de donnees

### Qualite et orchestration
- **Great Expectations** : Validation de la qualite des donnees 
- **Databricks Workflows** : Orchestration des pipelines


### DevOps
- **GitHub** : Versioning du code
- **GitHub Actions** : CI/CD
- **Semantic Release** : Versioning semantique automatique

---

## Architecture du projet

### Architecture Medallion

```
data.gouv.fr
    |
    v
[DLT Ingestion]
    |
    v
Bronze Layer (donnees brutes)
    |
    v
Silver Layer (donnees nettoyees et enrichies)
    |
    v
Gold Layer (donnees agreges pour analyse)
    |
    v
[Visualisations / API]
```

### Zones de donnees

**Bronze** :
- Donnees brutes telles qu'ingerees
- Partitionnement : par annee

**Silver** :
- Donnees nettoyees (types corriges, doublons supprimes)
- Colonnes standardisees
- Enrichissement (geocodage, categories)
- Partitionnement : par annee et departement

**Gold** :
- Tables agreges par cas d'usage :
  - Conformite par commune
  - Evolution temporelle des parametres
  - Carte de qualite par region
  - Top 10 communes les plus/moins conformes
  - Analyse des non-conformites

---

Terraform est autorisée

## Planning detaille - 5 jours (30 heures)

### Jour 1 : Infrastructure Azure et Ingestion DLT (6h)

#### Matin (3h) : Setup Azure

**Objectifs** :
- Creer les ressources Azure necessaires
- Configurer Azure Data Lake Storage Gen2
- Configurer l'acces Databricks au stockage

**Taches** :

1. **Creer un Resource Group** (15 min)

2. **Creer un Azure Data Lake Storage Gen2** (30 min)

3. **Creer les conteneurs source** (30 min)

4. **Telecharger le dataset** (45 min)
   - Telecharger depuis data.gouv.fr
   - Uploader vers Azure Blob Storage ou DBFS

#### Apres-midi (3h) : Pipeline DLT

**Objectifs** :
- Creer un pipeline DLT pour l'ingestion
- Ingerer les donnees dans la zone Bronze
- Tester et valider l'ingestion

**Taches** :

1. **Creer un notebook DLT** : `01_DLT_Ingestion_Qualite_Eau` (1h30)

2. **Creer le pipeline DLT dans l'UI Databricks** (30 min)
   - Workflows > Delta Live Tables > Create Pipeline
   - Nom : `Pipeline_Qualite_Eau_France`
   - Source : Notebook DLT cree
   - Destination : Azure Data Lake
   - Mode : Triggered (ou Continuous selon besoin)

3. **Executer et valider** (1h)
   - Lancer le pipeline
   - Verifier les logs
   - Valider les donnees dans Bronze

**Livrables Jour 1** :
- [ ] Resource Group Azure cree
- [ ] Azure Data Lake Storage Gen2 configure
- [ ] Conteneurs source crées
- [ ] Dataset telecharge et disponible
- [ ] Notebook DLT cree
- [ ] Pipeline DLT configure et execute
- [ ] Table Bronze creee avec donnees

---

### Jour 2 : GitHub, Versioning et CI/CD (6h)

#### Matin (3h) : Configuration GitHub

**Objectifs** :
- Initialiser un repository GitHub
- Configurer Semantic Release 
- Mettre en place la structure de projet

ressource : 
https://www.youtube.com/watch?v=mxPfbwJ0FiU&t=288s
https://www.youtube.com/watch?v=mah8PV6ugNY&t=394s

https://www.conventionalcommits.org/en/v1.0.0/

**Taches** :

1. **Creer le repository GitHub** (30 min)
   ```bash
   git init
   git remote add origin https://github.com/votre-username/pipeline-qualite-eau.git
   ```

2. **Structure du projet** (1h)
   ```
   pipeline-qualite-eau/
   ├── .github/
   │   └── workflows/
   │       ├── ci.yml
   │       └── release.yml
   ├── notebooks/
   │   ├── 01_DLT_Ingestion_Qualite_Eau.py
   │   ├── 02_bronze_import.py
   │   ├── 03_Silver_Transformation.py
   │   ├── 04_Gold_Agregations.py
   │   └── 05_Quality_Checks.py
   ├── config/
   │   ├── databricks_config.json
   │   └── pipeline_settings.json
   ├── tests/
   │   └── test_transformations.py
   ├── README.md
   └── .gitignore
   ```

3. **Configurer Semantic Release** (1h30)



#### Apres-midi (3h) : GitHub Actions

**Objectifs** :
- Creer un workflow CI/CD
- Automatiser les tests
- Deployer automatiquement vers Databricks

**Taches** :


**Livrables Jour 2** :
- [ ] Repository GitHub initialise
- [ ] Structure de projet creee
- [ ] Semantic Release configure
- [ ] Premier commit semantique effectue

---

#### Apres-midi (3h) : Databricks Repos et Notebooks

**Objectifs** :
- Configurer Databricks Repos
- Synchroniser avec GitHub
- Optimiser les notebooks

**Taches** :

1. **Configurer Databricks Repos** (1h)
   - Repos > Add Repo
   - Connecter GitHub
   - Cloner le repository
   - Configurer le branch tracking

2. **Convertir notebooks en format .py** (1h)

3. **Optimiser les notebooks** (1h)
   - Ajouter des commentaires
   - Creer des fonctions reutilisables
   - Documenter les transformations

**Livrables Jour 3** :
- [ ] Databricks Repos configure et synchronise
- [ ] Documentation ajoutee

---

### Jour 4 : Transformations et Great Expectations (6h)

#### Matin (3h) : Tables Gold

**Objectifs** :
- Creer les tables Gold agreges
- Implementer les analyses metier
- Optimiser les performances

**Taches** :

1. **Notebook Gold** : `03_Gold_Agregations.py` (2h)


2. **Tester les tables Gold** (1h)

#### Apres-midi (3h) : Great Expectations (BONUS)

**Objectifs** :
- Installer Great Expectations
- Creer des expectations pour la qualite des donnees
- Integrer dans le pipeline

**Taches** :

1. **Installer Great Expectations** (15 min)
   ```python
   %pip install great-expectations
   ```

2. **Notebook Quality Checks** : `04_Quality_Checks.py` (2h15)

3. **Integrer dans le pipeline** (30 min)

**Livrables Jour 4** :
- [ ] 6 tables Gold creees
- [ ] Tables optimisees (OPTIMIZE)
- [ ] Great Expectations installe
- [ ] Notebook de validation cree
- [ ] Expectations definies (schema, valeurs, unicite)
- [ ] Rapport de validation genere

---

### Jour 5 : Orchestration et Automatisation (6h)

#### Matin (3h) : Databricks Workflows

**Objectifs** :
- Creer un workflow complet
- Orchestrer les notebooks
- Parametrer l'execution

**Taches** :

1. **Creer le workflow via UI** (1h30)

Dans Databricks :
- Workflows > Create Job
- Nom : `Pipeline_Qualite_Eau_Complet`

OU

2. **Creer le workflow via API** (1h30)

Script `scripts/create_workflow.py`

#### Apres-midi (3h) : API et Documentation

**Objectifs** :
- Exposer les donnees via API
- Documenter le projet
- Finaliser les livrables

** SUPER BONUS ** :
- Faire du monitoring https://www.youtube.com/watch?v=U9ctDgoVDIc

**Taches** :

1. **Exposer les donnees via API** (1h30)

Creer `scripts/api_qualite_eau.py`

2. **Documentation README.md** (1h)

3. **Rapport final** (30 min)

Creer `RAPPORT_FINAL.md` avec :
- Resume du projet
- Architecture implementee
- Tables creees
- Insights principaux
- Difficultes rencontrees
- Ameliorations futures

**Livrables Jour 5** :
- [ ] Workflow Databricks cree
- [ ] Orchestration testee
- [ ] Script de workflow via API
- [ ] API REST creee
- [ ] Documentation complete
- [ ] Rapport final redige

---

## Livrables finaux

le lien github

---

## Ressources complementaires

### Documentation officielle

- [Azure Databricks](https://learn.microsoft.com/azure/databricks/)
- [Delta Live Tables](https://docs.databricks.com/delta-live-tables/index.html)
- [Great Expectations](https://docs.greatexpectations.io/)
- [Databricks Workflows](https://docs.databricks.com/workflows/index.html)
- [Semantic Release](https://semantic-release.gitbook.io/)

### Delta Lake

**Documentation** :
- [Delta Lake - Documentation officielle](https://docs.delta.io/)
- [Delta Lake sur Azure Databricks](https://learn.microsoft.com/azure/databricks/delta/)

**Tutoriels video** :
- [Delta Lake Tutorial - Introduction et fonctionnalités](https://www.youtube.com/watch?v=ydZtja4WXWI) - Guide complet sur Delta Lake : ACID transactions, Time Travel, et optimisations

**Fonctionnalités clés** :
- Transactions ACID pour la fiabilité des données
- Time Travel pour l'audit et le rollback
- Schema enforcement et evolution
- OPTIMIZE et Z-ORDER pour les performances
- Upserts avec MERGE
- Change Data Feed (CDC)

### Semantic Release et Conventional Commits

**Documentation** :
- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) - Specification des commits semantiques
- [Semantic Release - Documentation officielle](https://semantic-release.gitbook.io/)

**Tutoriels video** :
- [Semantic Release Tutorial - Automatiser vos releases GitHub](https://www.youtube.com/watch?v=mxPfbwJ0FiU&t=288s) - Guide complet sur la configuration et l'utilisation de Semantic Release

**Formats de commits** :
```
feat: ajouter la validation des donnees avec Great Expectations
fix: corriger l'encodage des noms de colonnes
docs: mettre a jour le README avec les instructions d'installation
chore: configurer le workflow GitHub Actions
refactor: reorganiser la structure des notebooks
perf: optimiser la requete SQL pour les agregations
test: ajouter des tests unitaires pour les transformations
```

### Tutoriels

- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)
- [GitHub Actions pour Databricks](https://docs.github.com/actions)
- [Azure Data Lake Storage Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)

### Dataset

- [Data.gouv.fr - Qualite de l'eau](https://www.data.gouv.fr/fr/datasets/resultats-du-controle-sanitaire-de-la-qualite-de-leau-distribuee-commune-par-commune/)
- [ANSES - Qualite de l'eau](https://www.anses.fr/fr/content/la-qualit%C3%A9-de-l%E2%80%99eau-du-robinet-en-france)


---

## Conclusion

Ce projet vous permet de maitriser :

- L'architecture Medallion complete sur Azure
- DLT pour l'ingestion automatisee
- Great Expectations pour la qualite des donnees
- GitHub Actions et Semantic Release pour le CI/CD
- Databricks Workflows pour l'orchestration
- L'API Databricks pour l'automatisation

**Duree totale** : 30 heures sur 5 jours

**Niveau** : Intermediaire/Avance

**Prerequis** :
- Connaissances Azure de base
- Python et SQL
- Git et GitHub

Bon projet !

---

**Date de creation** : Octobre 2025
**Version** : 1.0

