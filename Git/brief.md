# 🔧 Brief Pratique Git - Data Engineering

**Durée estimée :** 6 heures
**Niveau :** Débutant à Intermédiaire
**Modalité :** Pratique individuelle

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :
- Créer et gérer un dépôt Git pour un projet Data
- Utiliser les commandes Git essentielles au quotidien
- Gérer les branches et les conflits
- Collaborer efficacement avec d'autres Data Engineers
- Mettre en place un workflow Git professionnel

---

## 📋 Contexte

Vous êtes Data Engineer chez **DataLake Solutions**. L'équipe développe plusieurs pipelines ETL, mais jusqu'à présent, le code n'était pas versionné correctement. Vous devez mettre en place Git pour gérer le code de manière professionnelle et collaborer efficacement.

---

## 🚀 Partie 1 : Premiers pas avec Git (1h30)

### Tâche 1.1 : Configuration de Git

Configurez Git sur votre machine :

```bash
# Configurer votre identité
git config --global user.name "Votre Nom"
git config --global user.email "votre@email.com"

# Configurer l'éditeur
git config --global core.editor "code --wait"

# Améliorer l'affichage
git config --global color.ui auto

# Voir votre configuration
git config --list
```

**Critères de validation :**
- ✅ Nom et email configurés
- ✅ `git config --list` affiche vos informations

---

### Tâche 1.2 : Créer votre premier dépôt

Créez un nouveau projet Data Engineering :

```bash
# Créer un dossier
mkdir data-pipeline-project
cd data-pipeline-project

# Initialiser Git
git init

# Vérifier le statut
git status
```

**Critères de validation :**
- ✅ Dossier `.git/` créé
- ✅ `git status` indique "On branch main" ou "On branch master"

---

### Tâche 1.3 : Créer des fichiers et faire votre premier commit

Créez la structure suivante :

```
data-pipeline-project/
├── README.md
├── requirements.txt
├── src/
│   ├── extract.py
│   ├── transform.py
│   └── load.py
└── data/
    └── .gitkeep
```

**Contenu du README.md :**
```markdown
# Data Pipeline Project

Pipeline ETL pour l'extraction et le traitement de données de ventes.

## Structure
- `src/` : Code source du pipeline
- `data/` : Dossier pour les données (non versionné)

## Installation
pip install -r requirements.txt
```

**Contenu du requirements.txt :**
```
pandas==2.1.0
sqlalchemy==2.0.20
psycopg2-binary==2.9.7
```

**Créer les fichiers Python :**

**src/extract.py :**
```python
import pandas as pd

def extract_data(source_path):
    """Extract data from CSV file"""
    df = pd.read_csv(source_path)
    print(f"Extracted {len(df)} rows")
    return df

if __name__ == "__main__":
    # Test extraction
    pass
```

**Instructions :**
1. Créez tous les fichiers
2. Ajoutez-les au staging area
3. Créez un commit avec le message : "Initial commit: setup project structure"

```bash
git add .
git commit -m "Initial commit: setup project structure"
```

**Critères de validation :**
- ✅ Tous les fichiers créés
- ✅ `git log` montre votre premier commit
- ✅ `git status` indique "nothing to commit, working tree clean"

---

### Tâche 1.4 : Créer un .gitignore

Créez un fichier `.gitignore` pour ne pas versionner les données et fichiers temporaires :

```
# Python
__pycache__/
*.py[cod]
*.so
venv/
env/
.venv/

# Data files
data/*.csv
data/*.json
data/*.parquet
!data/.gitkeep

# Credentials
.env
credentials.json
*.pem

# Jupyter
.ipynb_checkpoints/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
```

**Instructions :**
1. Créez le fichier `.gitignore`
2. Testez en créant un fichier `data/test.csv`
3. Vérifiez que `git status` ne le montre pas
4. Commitez le `.gitignore`

**Critères de validation :**
- ✅ `.gitignore` créé et committé
- ✅ Fichiers dans `data/` sont ignorés sauf `.gitkeep`

---

## 🌿 Partie 2 : Gestion des branches (1h30)

### Tâche 2.1 : Créer et utiliser des branches

**Scénario :** Vous devez développer trois fonctionnalités en parallèle :
1. Fonction de transformation des données
2. Fonction de chargement dans PostgreSQL
3. Système de logs

**Instructions :**

**Branche 1 : feature/transform-data**
```bash
# Créer et basculer sur la branche
git checkout -b feature/transform-data

# Modifier src/transform.py
```

**src/transform.py :**
```python
import pandas as pd

def clean_data(df):
    """Remove duplicates and null values"""
    df = df.drop_duplicates()
    df = df.dropna()
    return df

def transform_sales_data(df):
    """Transform sales data"""
    df['date'] = pd.to_datetime(df['date'])
    df['revenue'] = df['quantity'] * df['price']
    df['year'] = df['date'].dt.year
    df['month'] = df['date'].dt.month
    return df

if __name__ == "__main__":
    # Test transformations
    pass
```

```bash
# Committer
git add src/transform.py
git commit -m "Add data transformation functions"
```

**Branche 2 : feature/load-database**
```bash
# Retour sur main
git checkout main

# Nouvelle branche
git checkout -b feature/load-database

# Modifier src/load.py
```

**src/load.py :**
```python
from sqlalchemy import create_engine
import pandas as pd
import os

def load_to_postgres(df, table_name):
    """Load dataframe to PostgreSQL"""
    db_url = os.getenv('DATABASE_URL', 'postgresql://user:pass@localhost:5432/db')
    engine = create_engine(db_url)

    df.to_sql(table_name, engine, if_exists='replace', index=False)
    print(f"✅ Loaded {len(df)} rows to {table_name}")

if __name__ == "__main__":
    # Test loading
    pass
```

```bash
git add src/load.py
git commit -m "Add PostgreSQL loading function"
```

**Critères de validation :**
- ✅ Deux branches créées : `feature/transform-data` et `feature/load-database`
- ✅ Chaque branche a au moins un commit
- ✅ `git branch` liste toutes vos branches

---

### Tâche 2.2 : Fusionner les branches

**Instructions :**
1. Retournez sur la branche `main`
2. Fusionnez `feature/transform-data`
3. Fusionnez `feature/load-database`
4. Vérifiez que tout fonctionne
5. Supprimez les branches fusionnées

```bash
# Retour sur main
git checkout main

# Merge première branche
git merge feature/transform-data

# Merge deuxième branche
git merge feature/load-database

# Vérifier l'historique
git log --oneline --graph --all

# Supprimer les branches
git branch -d feature/transform-data
git branch -d feature/load-database
```

**Critères de validation :**
- ✅ Les deux branches sont fusionnées dans main
- ✅ Aucun conflit
- ✅ Branches supprimées

---

### Tâche 2.3 : Gérer un conflit

**Scénario :** Créez volontairement un conflit pour apprendre à le résoudre.

**Instructions :**

1. Créez une branche `feature/logging-v1` et modifiez `README.md` :
```bash
git checkout -b feature/logging-v1
```

Ajoutez dans README.md :
```markdown
## Logging
Ce projet utilise le module logging standard de Python.
```

```bash
git add README.md
git commit -m "Add logging info v1"
```

2. Retournez sur `main` et créez une autre branche `feature/logging-v2` :
```bash
git checkout main
git checkout -b feature/logging-v2
```

Ajoutez dans README.md (même emplacement) :
```markdown
## Logging
Nous utilisons structlog pour un logging avancé.
```

```bash
git add README.md
git commit -m "Add logging info v2"
```

3. Fusionnez d'abord `feature/logging-v1` dans main :
```bash
git checkout main
git merge feature/logging-v1
```

4. Tentez de fusionner `feature/logging-v2` (conflit !) :
```bash
git merge feature/logging-v2
# CONFLICT!
```

5. Résolvez le conflit :
- Ouvrez `README.md`
- Vous verrez les marqueurs `<<<<<<<`, `=======`, `>>>>>>>`
- Choisissez la version appropriée ou combinez les deux
- Supprimez les marqueurs

6. Finalisez :
```bash
git add README.md
git commit -m "Merge feature/logging-v2 with conflict resolution"
```

**Critères de validation :**
- ✅ Conflit créé volontairement
- ✅ Conflit résolu manuellement
- ✅ Fusion complétée avec succès

---

## 📤 Partie 3 : Collaboration avec GitHub (2h)

### Tâche 3.1 : Créer un dépôt sur GitHub

1. Allez sur [GitHub](https://github.com)
2. Créez un nouveau repository : `data-pipeline-project`
3. Ne cochez PAS "Initialize with README" (vous avez déjà un projet local)

**Critères de validation :**
- ✅ Repository créé sur GitHub

---

### Tâche 3.2 : Lier votre dépôt local à GitHub

```bash
# Ajouter le remote
git remote add origin https://github.com/votre-username/data-pipeline-project.git

# Vérifier
git remote -v

# Pousser le code
git push -u origin main
```

**Critères de validation :**
- ✅ Remote configuré
- ✅ Code visible sur GitHub

---

### Tâche 3.3 : Workflow Pull Request

**Scénario :** Vous devez ajouter une fonctionnalité de validation de données.

1. **Créer une branche :**
```bash
git checkout -b feature/data-validation
```

2. **Créer un nouveau fichier `src/validate.py` :**
```python
import pandas as pd

def validate_schema(df, expected_columns):
    """Validate dataframe schema"""
    missing_cols = set(expected_columns) - set(df.columns)
    if missing_cols:
        raise ValueError(f"Missing columns: {missing_cols}")
    return True

def validate_data_quality(df):
    """Check data quality"""
    issues = []

    # Check for nulls
    null_counts = df.isnull().sum()
    if null_counts.any():
        issues.append(f"Null values found: {null_counts[null_counts > 0].to_dict()}")

    # Check for duplicates
    dup_count = df.duplicated().sum()
    if dup_count > 0:
        issues.append(f"Found {dup_count} duplicate rows")

    return issues

if __name__ == "__main__":
    # Tests
    df = pd.DataFrame({
        'id': [1, 2, 3],
        'value': [10, 20, 30]
    })

    print("✅ Schema valid:", validate_schema(df, ['id', 'value']))
    print("Issues:", validate_data_quality(df))
```

3. **Committer et pousser :**
```bash
git add src/validate.py
git commit -m "Add data validation module"
git push -u origin feature/data-validation
```

4. **Créer une Pull Request sur GitHub :**
- Allez sur GitHub
- Cliquez sur "Compare & pull request"
- Ajoutez une description :
```markdown
## Ajout d'un module de validation

### Changements
- Nouvelle fonction de validation de schéma
- Nouvelle fonction de validation de qualité des données

### Tests
- [x] Testé localement avec des données de test
- [x] Pas de régression

### À reviewer
- Vérifier la logique de validation
- Suggérer des améliorations
```

5. **Merger la PR :**
- Cliquez sur "Merge pull request"
- Confirmez le merge

6. **Mettre à jour votre dépôt local :**
```bash
git checkout main
git pull origin main
git branch -d feature/data-validation
```

**Critères de validation :**
- ✅ Branche créée et poussée sur GitHub
- ✅ Pull Request créée et mergée
- ✅ Dépôt local à jour

---

## 🕰️ Partie 4 : Historique et debugging (1h)

### Tâche 4.1 : Explorer l'historique

```bash
# Historique complet
git log

# Format condensé
git log --oneline

# Avec graphe
git log --oneline --graph --all

# Filtrer par auteur
git log --author="Votre Nom"

# Derniers 5 commits
git log -5

# Chercher dans les messages de commit
git log --grep="validation"
```

**Critères de validation :**
- ✅ Vous savez afficher l'historique de différentes manières

---

### Tâche 4.2 : Voir les modifications d'un commit

```bash
# Détails d'un commit spécifique
git show <commit-hash>

# Voir uniquement les fichiers modifiés
git show --name-only <commit-hash>

# Voir les stats
git show --stat <commit-hash>
```

---

### Tâche 4.3 : Retrouver qui a modifié une ligne

```bash
# Voir qui a modifié chaque ligne d'un fichier
git blame src/extract.py

# Format plus lisible
git blame -L 1,10 src/extract.py
```

---

### Tâche 4.4 : Chercher dans l'historique

**Scénario :** Vous avez introduit un bug mais ne savez pas quand.

```bash
# Chercher un mot dans tous les commits
git log -S "extract_data"

# Voir les différences
git log -p -S "extract_data"
```

**Critères de validation :**
- ✅ Vous savez retrouver qui a modifié une ligne
- ✅ Vous savez chercher dans l'historique

---

## 🔄 Partie 5 : Workflows avancés (30 min)

### Tâche 5.1 : Utiliser git stash

**Scénario :** Vous êtes en train de coder, mais on vous demande de corriger un bug urgent.

```bash
# Vous êtes en train de modifier extract.py
# Sauvegarder temporairement
git stash

# Corriger le bug sur une autre branche
git checkout -b hotfix/urgent-bug
# ... corrections ...
git commit -am "Fix urgent bug"
git checkout main
git merge hotfix/urgent-bug

# Récupérer votre travail en cours
git stash pop
```

**Critères de validation :**
- ✅ Vous savez mettre de côté des modifications
- ✅ Vous savez les récupérer

---

### Tâche 5.2 : Modifier le dernier commit

**Scénario :** Vous avez oublié un fichier dans le dernier commit.

```bash
# Faire votre commit
git commit -m "Add feature X"

# Oups, j'ai oublié un fichier !
git add fichier_oublie.py

# Modifier le dernier commit
git commit --amend --no-edit
```

---

### Tâche 5.3 : Créer des tags

**Scénario :** Vous venez de finaliser la version 1.0.0 de votre pipeline.

```bash
# Créer un tag annoté
git tag -a v1.0.0 -m "Release version 1.0.0 - Production ready"

# Voir les tags
git tag

# Pousser le tag
git push origin v1.0.0

# Voir les détails d'un tag
git show v1.0.0
```

**Critères de validation :**
- ✅ Tag créé et poussé sur GitHub
- ✅ Visible dans l'interface GitHub (Releases)

---

## 🎁 Bonus : Automatisation (Optionnel)

### Bonus 1 : Git Aliases

Créez des raccourcis pour vos commandes fréquentes :

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual 'log --oneline --graph --all'

# Utilisation
git st  # au lieu de git status
git visual  # pour voir le graphe
```

### Bonus 2 : Pre-commit hooks

Créez un hook pour vérifier le code avant chaque commit :

```bash
# Créer le fichier .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Contenu de pre-commit :**
```bash
#!/bin/bash

# Vérifier qu'on ne commite pas de secrets
if git diff --cached | grep -i "password\|secret\|api_key"; then
    echo "❌ Attention ! Vous tentez de commiter des secrets !"
    exit 1
fi

echo "✅ Pre-commit check passed"
exit 0
```

---

## 📤 Livrables

À la fin du brief, vous devez avoir :

1. **Un dépôt Git local et sur GitHub** contenant :
   - Structure de projet complète
   - Plusieurs commits significatifs
   - Historique propre avec branches fusionnées

2. **Un fichier RECAP.md** documentant :
   - Les commandes Git que vous avez apprises
   - Les difficultés rencontrées et comment vous les avez résolues
   - Un schéma de votre workflow Git

3. **Captures d'écran** :
   - Historique Git avec `git log --graph`
   - Pull Request sur GitHub
   - Release avec tag

---

## ✅ Critères d'Évaluation

| Critère | Points |
|---------|--------|
| Configuration Git correcte | 10 |
| Structure de projet et commits | 15 |
| Utilisation des branches | 20 |
| Résolution de conflits | 15 |
| Workflow GitHub (PR, merge) | 20 |
| Exploration de l'historique | 10 |
| Documentation (RECAP.md) | 10 |

**Total : 100 points**

---

## 💡 Conseils

- 💾 **Commitez souvent** : Mieux vaut beaucoup de petits commits qu'un gros
- 📝 **Messages clairs** : Expliquez le "pourquoi", pas seulement le "quoi"
- 🌿 **Une branche = une fonctionnalité** : Ne mélangez pas plusieurs tâches
- 🔄 **Pull avant de push** : Évitez les conflits en restant à jour
- 🚫 **N'utilisez jamais `--force`** sans être sûr de ce que vous faites
- 📖 **Lisez les messages d'erreur** : Git est très explicite

---

## 🆘 Commandes de secours

Si vous êtes perdu :

```bash
# Où suis-je ?
git status

# Qu'est-ce qui a changé ?
git diff

# Annuler mes modifications locales
git restore .

# Voir l'historique
git log --oneline

# Revenir à un état précédent (sans perdre les commits)
git revert <commit-hash>
```

---

## 📚 Ressources

- [Pro Git Book (gratuit)](https://git-scm.com/book/fr/v2)
- [Learn Git Branching (interactif)](https://learngitbranching.js.org/?locale=fr_FR)
- [Oh Shit, Git!?](https://ohshitgit.com/fr)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

---

**Bon courage ! 🚀**
