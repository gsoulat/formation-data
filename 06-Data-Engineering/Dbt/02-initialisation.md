# Chapitre 2 : Initialisation du projet DBT Cloud

## 🎯 Objectifs
- Créer un nouveau projet dans DBT Cloud
- Configurer la connexion Snowflake
- Comprendre la structure d'un projet DBT
- Créer les premiers fichiers de configuration

## 🚀 Création du projet DBT Cloud

### 1. Accès à DBT Cloud

1. Rendez-vous sur [https://cloud.getdbt.com](https://cloud.getdbt.com)
2. Connectez-vous ou créez un compte si nécessaire
3. Cliquez sur **"Create new project"**

### 2. Configuration de base

1. **Nom du projet** : `analyse-airbnb`
2. **Subdomain** : Laissez le choix par défaut ou personnalisez
3. Cliquez sur **"Continue"**

## ❄️ Configuration de la connexion Snowflake

### 1. Sélection du type de connexion

1. Dans la liste des adaptateurs, sélectionnez **Snowflake**
2. Cliquez sur **"Next"**

### 2. Paramètres de connexion

Remplissez les champs avec les informations du Chapitre 1 :

| Champ | Valeur |
|-------|--------|
| **Account** | Votre nom de compte Snowflake (ex: `xy12345.eu-west-1`) |
| **User** | `dbt` |
| **Password** | `MotDePasseDBT123@` |
| **Role** | `transform` |
| **Database** | `AIRBNB` |
| **Warehouse** | `COMPUTE_WH` |
| **Schema** | `RAW` |

### 3. Test de connexion

1. Cliquez sur **"Test Connection"**
2. Vérifiez que le message "Connection successful" apparaît
3. Cliquez sur **"Continue"**

> ⚠️ **Attention** : Si la connexion échoue, vérifiez vos paramètres Snowflake et assurez-vous que l'utilisateur `dbt` a été créé correctement.

## 📁 Configuration du repository

### 1. Choix du repository

Vous avez deux options :

**Option A : Repository géré par DBT Cloud**
- Sélectionnez "Managed repository"
- DBT Cloud créera automatiquement un repository Git

**Option B : Repository externe (GitHub/GitLab)**
- Connectez votre repository existant
- Suivez les instructions de connexion

Pour ce cours, nous recommandons l'**Option A** pour simplifier.

### 2. Initialisation

1. Cliquez sur **"Initialize dbt project"**
2. Attendez que l'initialisation se termine
3. Vous devriez voir l'IDE DBT Cloud s'ouvrir

## 🏗️ Structure du projet DBT

Explorons la structure créée automatiquement :

```
analyse-airbnb/
├── dbt_project.yml          # Configuration principale du projet
├── README.md                # Documentation du projet
├── models/                  # Dossier des modèles SQL
│   └── example/            # Modèles d'exemple
├── analyses/               # Analyses ad-hoc
├── tests/                  # Tests personnalisés
├── seeds/                  # Fichiers CSV statiques
├── snapshots/              # Historisation des données
└── macros/                 # Fonctions réutilisables
```

## ⚙️ Configuration du fichier `dbt_project.yml`

Le fichier `dbt_project.yml` est le cœur de la configuration. Remplacez son contenu par :

```yaml
# Nom du projet
name: 'analyse_airbnb'
version: '1.0.0'
config-version: 2

# Profil utilisé (correspond au nom dans profiles.yml)
profile: 'analyse_airbnb'

# Dossiers du projet
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

# Dossier de destination des fichiers compilés
target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

# Configuration des modèles
models:
  analyse_airbnb:
    # Configuration pour les modèles dans le dossier exemple
    example:
      +materialized: view

    # Configuration pour nos futurs modèles
    curation:
      +materialized: view
      +schema: curation

    analytics:
      +materialized: table
      +schema: analytics

# Configuration des seeds
seeds:
  analyse_airbnb:
    +enabled: true
    +schema: raw

# Variables du projet
vars:
  # Variables pour les modèles incrémentaux (Chapitre 7)
  inc_database: 'airbnb'
  inc_schema: 'incremental'
```

## 🔧 Configuration de l'environnement de développement

### 1. Environnement de développement

Dans DBT Cloud, configurez votre environnement :

1. Allez dans **Account Settings** → **Projects** → **analyse-airbnb**
2. Dans l'onglet **Environments**, cliquez sur l'environnement "Development"
3. Vérifiez les paramètres :
   - **dbt version** : Dernière version stable (1.7+)
   - **Dataset/Schema** : `dbt_[votre_nom]` (schema personnel de développement)

### 2. Credentials personnelles

1. Dans **Account Settings** → **Credentials**
2. Sélectionnez le projet `analyse-airbnb`
3. Vérifiez que vos credentials Snowflake sont correctes
4. Le **Schema** devrait être `dbt_[votre_nom]` pour le développement

## ✅ Premier test : `dbt debug`

Testons que tout fonctionne correctement :

1. Dans l'IDE DBT Cloud, ouvrez un nouveau **Terminal**
2. Exécutez la commande :

```bash
dbt debug
```

Vous devriez voir une sortie similaire à :

```
Running with dbt=1.7.x
dbt version: 1.7.x
python version: 3.9.x
python path: /usr/local/bin/python
os info: Linux-x86_64-with-glibc2.31

Configuration:
  profiles dir: /root/.dbt
  profiles file: /root/.dbt/profiles.yml
  project dir: /usr/app

All checks passed!
```

## 🧹 Nettoyage des fichiers d'exemple

Supprimez les fichiers d'exemple pour commencer proprement :

1. Supprimez le dossier `models/example/`
2. Dans le terminal, exécutez :

```bash
dbt clean
```

## 📝 Créer les dossiers de notre projet

Créez la structure pour notre projet Airbnb :

```bash
mkdir models/sources
mkdir models/curation
mkdir models/analytics
```

## 🎯 Points clés à retenir

1. **Configuration centralisée** : Le fichier `dbt_project.yml` contrôle tout le projet
2. **Environnements séparés** : Développement vs Production avec des schemas différents
3. **Structure organisée** : Sources → Curation → Analytics
4. **Tests préliminaires** : Toujours vérifier avec `dbt debug`

## 🔍 Vérification finale

Votre projet devrait maintenant avoir cette structure :

```
analyse-airbnb/
├── dbt_project.yml          # ✅ Configuré
├── models/
│   ├── sources/            # ✅ Créé
│   ├── curation/           # ✅ Créé
│   └── analytics/          # ✅ Créé
├── seeds/
├── snapshots/
└── macros/
```

Et la commande `dbt debug` devrait retourner "All checks passed!".

---

**Prochaine étape** : [Chapitre 3 - Premiers modèles](chapitre-3-premiers-modeles.md)