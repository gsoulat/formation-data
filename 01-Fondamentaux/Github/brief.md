# 🐙 Brief Pratique GitHub - Data Engineering

**Durée estimée :** 6 heures
**Niveau :** Intermédiaire
**Modalité :** Pratique individuelle

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :
- Maîtriser les Pull Requests et le code review
- Gérer les Issues et Projects pour organiser le travail
- Mettre en place des workflows CI/CD avec GitHub Actions
- Utiliser les fonctionnalités de sécurité de GitHub
- Collaborer efficacement sur des projets Data Engineering
- Automatiser les tests et déploiements

---

## 📋 Contexte

Vous êtes Data Engineer chez **CloudData Analytics**. L'équipe a migré le code sur GitHub, mais utilise encore peu les fonctionnalités avancées de la plateforme. Votre mission est de mettre en place un workflow professionnel utilisant l'écosystème complet de GitHub.

---

## 🚀 Partie 1 : Configuration et premiers pas (1h)

### Tâche 1.1 : Configurer votre profil GitHub

Créez ou améliorez votre profil GitHub professionnel :

**Instructions :**
1. Allez sur [github.com](https://github.com)
2. Accédez à votre profil (Settings)
3. Configurez :
   - Photo de profil professionnelle
   - Nom complet
   - Bio (ex: "Data Engineer | Python, SQL, Airflow | Data Pipelines")
   - Localisation
   - Site web ou LinkedIn

**Critères de validation :**
- ✅ Profil complété avec toutes les informations
- ✅ Bio professionnelle

---

### Tâche 1.2 : Configurer l'authentification SSH

**Instructions :**

1. **Générer une clé SSH :**
```bash
# Générer une clé SSH
ssh-keygen -t ed25519 -C "votre.email@example.com"

# Démarrer l'agent SSH
eval "$(ssh-agent -s)"

# Ajouter la clé à l'agent
ssh-add ~/.ssh/id_ed25519

# Afficher la clé publique
cat ~/.ssh/id_ed25519.pub
```

2. **Ajouter la clé à GitHub :**
- Allez dans **Settings** → **SSH and GPG keys**
- Cliquez sur **New SSH key**
- Collez votre clé publique
- Donnez un titre (ex: "MacBook Pro")

3. **Tester la connexion :**
```bash
ssh -T git@github.com
# Résultat attendu : "Hi username! You've successfully authenticated..."
```

**Critères de validation :**
- ✅ Clé SSH configurée
- ✅ Connexion SSH fonctionnelle

---

### Tâche 1.3 : Créer votre repository de travail

Créez un nouveau repository pour ce brief :

**Instructions :**
1. Cliquez sur le bouton **+** → **New repository**
2. Nom : `github-data-pipeline-advanced`
3. Description : "Advanced GitHub features for Data Engineering"
4. Public
5. ✅ Cochez "Add a README file"
6. ✅ Ajoutez un .gitignore (Python)
7. ✅ Choisissez une License (MIT)
8. Cliquez sur **Create repository**

**Critères de validation :**
- ✅ Repository créé sur GitHub
- ✅ README, .gitignore et LICENSE présents

---

### Tâche 1.4 : Cloner et setup local

```bash
# Cloner avec SSH
git clone git@github.com:votre-username/github-data-pipeline-advanced.git

# Entrer dans le dossier
cd github-data-pipeline-advanced

# Créer la structure du projet
mkdir -p src tests data .github/workflows

# Créer des fichiers
touch src/__init__.py src/pipeline.py tests/test_pipeline.py
touch requirements.txt
```

**Créer le fichier requirements.txt :**
```
pandas==2.1.0
pytest==7.4.0
pytest-cov==4.1.0
sqlalchemy==2.0.20
psycopg2-binary==2.9.7
python-dotenv==1.0.0
```

**Créer src/pipeline.py :**
```python
"""
Data Pipeline for ETL operations
"""
import pandas as pd
from typing import Dict, List
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def extract_data(source_path: str) -> pd.DataFrame:
    """Extract data from CSV file"""
    logger.info(f"Extracting data from {source_path}")
    df = pd.read_csv(source_path)
    logger.info(f"Extracted {len(df)} rows")
    return df


def transform_data(df: pd.DataFrame) -> pd.DataFrame:
    """Transform data"""
    logger.info("Transforming data")
    # Remove duplicates
    df = df.drop_duplicates()
    # Remove null values
    df = df.dropna()
    logger.info(f"Transformed to {len(df)} rows")
    return df


def load_data(df: pd.DataFrame, destination: str) -> bool:
    """Load data to destination"""
    logger.info(f"Loading {len(df)} rows to {destination}")
    df.to_csv(destination, index=False)
    logger.info("Load completed")
    return True


def run_pipeline(source: str, destination: str) -> None:
    """Run the complete ETL pipeline"""
    logger.info("Starting pipeline")
    df = extract_data(source)
    df = transform_data(df)
    load_data(df, destination)
    logger.info("Pipeline completed successfully")


if __name__ == "__main__":
    # Test pipeline
    pass
```

**Créer tests/test_pipeline.py :**
```python
"""
Tests for pipeline module
"""
import pytest
import pandas as pd
from src.pipeline import extract_data, transform_data, load_data


def test_transform_data():
    """Test data transformation"""
    # Create test data with duplicates and nulls
    df = pd.DataFrame({
        'id': [1, 2, 2, 3, 4],
        'value': [10, 20, 20, None, 40]
    })

    result = transform_data(df)

    # Should remove duplicates and nulls
    assert len(result) == 3
    assert result['value'].isnull().sum() == 0


def test_extract_data_invalid_path():
    """Test extraction with invalid path"""
    with pytest.raises(FileNotFoundError):
        extract_data("nonexistent.csv")
```

**Committer et pousser :**
```bash
git add .
git commit -m "Initial setup: project structure and pipeline code"
git push origin main
```

**Critères de validation :**
- ✅ Structure de projet créée
- ✅ Code et tests présents
- ✅ Poussé sur GitHub

---

## 🎫 Partie 2 : Issues et gestion de projet (1h30)

### Tâche 2.1 : Créer des Issues

**Scénario :** Vous devez planifier 5 améliorations pour votre pipeline.

**Instructions :**

Créez 5 issues sur GitHub avec les titres et descriptions suivants :

**Issue 1 : Bug - Pipeline fails with empty CSV**
```markdown
## Description
Le pipeline crash lorsqu'un fichier CSV est vide.

## Steps to reproduce
1. Créer un fichier CSV vide
2. Exécuter `run_pipeline('empty.csv', 'output.csv')`
3. Observer l'erreur

## Expected behavior
Le pipeline devrait gérer les fichiers vides gracieusement.

## Environment
- Python 3.11
- pandas 2.1.0
```

**Labels :** `bug`, `priority: high`

---

**Issue 2 : Feature - Add data validation**
```markdown
## Description
Ajouter un module de validation des données avant la transformation.

## Requirements
- Vérifier le schéma (colonnes attendues)
- Vérifier les types de données
- Détecter les anomalies

## Acceptance criteria
- [ ] Module de validation créé
- [ ] Tests unitaires ajoutés
- [ ] Documentation mise à jour
```

**Labels :** `enhancement`, `good first issue`

---

**Issue 3 : Feature - Implement logging to file**
```markdown
## Description
Les logs doivent être sauvegardés dans un fichier en plus de la console.

## Proposed solution
- Utiliser `logging.FileHandler`
- Format JSON pour faciliter l'analyse
- Rotation des logs par taille ou date
```

**Labels :** `enhancement`

---

**Issue 4 : Feature - Add CI/CD with GitHub Actions**
```markdown
## Description
Mettre en place CI/CD pour :
- Exécuter les tests automatiquement sur chaque PR
- Vérifier le code style (black, flake8)
- Générer un rapport de couverture

## Tasks
- [ ] Créer workflow de tests
- [ ] Configurer linting
- [ ] Intégrer codecov
```

**Labels :** `enhancement`, `devops`

---

**Issue 5 : Documentation - Add usage examples**
```markdown
## Description
Le README manque d'exemples d'utilisation concrets.

## To add
- Quick start
- Usage examples
- API reference
- Contribution guide
```

**Labels :** `documentation`

**Critères de validation :**
- ✅ 5 issues créées
- ✅ Descriptions complètes
- ✅ Labels appropriés

---

### Tâche 2.2 : Créer un GitHub Project

**Instructions :**
1. Allez dans l'onglet **Projects**
2. Cliquez sur **New project**
3. Choisissez le template **Board**
4. Nom : "Data Pipeline Development"
5. Créez les colonnes :
   - 📋 Backlog
   - 📝 To Do
   - 🔄 In Progress
   - 👀 Review
   - ✅ Done

6. **Ajoutez vos 5 issues au projet :**
   - Issues #2, #3, #5 → Backlog
   - Issue #1 → To Do (priorité haute)
   - Issue #4 → To Do

**Critères de validation :**
- ✅ Project créé avec colonnes Kanban
- ✅ Issues organisées dans les colonnes

---

### Tâche 2.3 : Créer un Milestone

**Instructions :**
1. Allez dans **Issues** → **Milestones**
2. Cliquez sur **New milestone**
3. Titre : `v1.0.0 - Production Ready`
4. Date : Dans 2 semaines
5. Description : "Première version stable avec validation, logging et CI/CD"

6. **Associez les issues au milestone :**
   - Issues #1, #2, #3, #4 → Milestone v1.0.0

**Critères de validation :**
- ✅ Milestone créé avec date cible
- ✅ Issues liées au milestone

---

## 🔀 Partie 3 : Pull Requests et Code Review (2h)

### Tâche 3.1 : Résoudre l'Issue #1 (Bug)

**Instructions :**

1. **Créer une branche :**
```bash
git checkout main
git pull origin main
git checkout -b fix/empty-csv-handling
```

2. **Modifier src/pipeline.py :**

Ajoutez au début de la fonction `extract_data` :
```python
def extract_data(source_path: str) -> pd.DataFrame:
    """Extract data from CSV file"""
    logger.info(f"Extracting data from {source_path}")
    df = pd.read_csv(source_path)

    # Handle empty CSV
    if df.empty:
        logger.warning("Empty CSV file detected")
        raise ValueError("CSV file is empty")

    logger.info(f"Extracted {len(df)} rows")
    return df
```

3. **Ajouter un test dans tests/test_pipeline.py :**
```python
def test_extract_empty_csv(tmp_path):
    """Test extraction with empty CSV"""
    # Create empty CSV
    empty_csv = tmp_path / "empty.csv"
    empty_csv.write_text("col1,col2\n")

    with pytest.raises(ValueError, match="CSV file is empty"):
        extract_data(str(empty_csv))
```

4. **Committer et pousser :**
```bash
git add .
git commit -m "fix: handle empty CSV files gracefully

- Add validation for empty DataFrames
- Raise ValueError with clear message
- Add test for empty CSV handling

Closes #1"

git push -u origin fix/empty-csv-handling
```

5. **Créer une Pull Request :**
   - Allez sur GitHub
   - Cliquez sur "Compare & pull request"
   - Titre : `Fix: Handle empty CSV files`
   - Description :

```markdown
## 🐛 Bug Fix

Résout le problème du pipeline qui crashait avec des fichiers CSV vides.

## 📝 Changements
- Ajout d'une validation dans `extract_data()`
- Le pipeline raise maintenant une `ValueError` explicite
- Test unitaire ajouté pour vérifier le comportement

## ✅ Tests
- [x] Tests unitaires passent
- [x] Testé avec un CSV vide
- [x] Pas de régression

## 🔗 Liens
Closes #1

## 📸 Screenshot des tests
```
# (Ajoutez un screenshot de pytest passant)
```

---

**NE MERGEZ PAS ENCORE !**

**Critères de validation :**
- ✅ Branche créée et poussée
- ✅ PR créée avec description complète
- ✅ Issue #1 liée avec "Closes #1"

---

### Tâche 3.2 : Faire un Code Review

**Instructions :**

Maintenant, jouez le rôle du reviewer sur votre propre PR :

1. **Allez dans l'onglet "Files changed"**
2. **Ajoutez des commentaires :**
   - Cliquez sur une ligne de code
   - Ajoutez un commentaire constructif

**Exemples de commentaires à ajouter :**

Sur la ligne `raise ValueError("CSV file is empty")` :
```
💡 Suggestion : Peut-être ajouter le nom du fichier dans le message d'erreur pour faciliter le debug ?

Exemple :
`raise ValueError(f"CSV file is empty: {source_path}")`
```

Sur le test :
```
✅ Bon test ! Couvre bien le cas limite.

Question : Devrait-on aussi tester le cas où le CSV a seulement des headers mais aucune ligne de données ?
```

3. **Ajoutez un commentaire général :**
   - Allez en haut de "Files changed"
   - Cliquez sur "Review changes"
   - Choisissez "Comment"
   - Écrivez :
```markdown
Bonne correction ! Le code est clair et bien testé.

Points positifs :
- ✅ Message d'erreur explicite
- ✅ Test unitaire complet
- ✅ Logging approprié

Suggestions :
- Inclure le nom du fichier dans le message d'erreur
- Considérer le cas CSV avec headers seulement
```

**Critères de validation :**
- ✅ Au moins 2 commentaires inline ajoutés
- ✅ Review générale soumise

---

### Tâche 3.3 : Intégrer les feedbacks et merger

**Instructions :**

1. **Intégrer les suggestions :**
```bash
# Modifier src/pipeline.py
# Changer le message d'erreur :
raise ValueError(f"CSV file is empty: {source_path}")

# Ajouter un nouveau test
def test_extract_csv_with_only_headers(tmp_path):
    """Test CSV with only headers"""
    csv_file = tmp_path / "headers_only.csv"
    csv_file.write_text("col1,col2\n")

    with pytest.raises(ValueError):
        extract_data(str(csv_file))

# Committer
git add .
git commit -m "fix: improve error message and add test for headers-only CSV"
git push
```

2. **Approuver et merger la PR :**
   - Retournez sur la PR
   - Cliquez sur "Merge pull request"
   - Choisissez "Squash and merge"
   - Confirmez le merge

3. **Nettoyer localement :**
```bash
git checkout main
git pull origin main
git branch -d fix/empty-csv-handling
```

4. **Vérifier que l'issue #1 est fermée automatiquement**

**Critères de validation :**
- ✅ Feedbacks intégrés
- ✅ PR mergée
- ✅ Issue #1 automatiquement fermée
- ✅ Branche locale supprimée

---

### Tâche 3.4 : Créer une PR pour l'Issue #2 (Data Validation)

**Instructions :**

1. **Créer une branche :**
```bash
git checkout -b feature/data-validation
```

2. **Créer src/validation.py :**
```python
"""
Data validation module
"""
import pandas as pd
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)


def validate_schema(df: pd.DataFrame, expected_columns: List[str]) -> bool:
    """
    Validate that DataFrame has expected columns

    Args:
        df: DataFrame to validate
        expected_columns: List of expected column names

    Returns:
        True if schema is valid

    Raises:
        ValueError: If required columns are missing
    """
    missing_cols = set(expected_columns) - set(df.columns)
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")

    logger.info(f"✅ Schema validation passed: {len(expected_columns)} columns")
    return True


def validate_data_types(df: pd.DataFrame, type_mapping: Dict[str, str]) -> bool:
    """
    Validate data types of columns

    Args:
        df: DataFrame to validate
        type_mapping: Dict mapping column names to expected types

    Returns:
        True if types are valid

    Raises:
        TypeError: If column types don't match
    """
    for col, expected_type in type_mapping.items():
        if col not in df.columns:
            continue

        actual_type = str(df[col].dtype)
        if not actual_type.startswith(expected_type):
            raise TypeError(
                f"Column '{col}' has type '{actual_type}', expected '{expected_type}'"
            )

    logger.info(f"✅ Type validation passed: {len(type_mapping)} columns")
    return True


def detect_anomalies(df: pd.DataFrame) -> Dict[str, Any]:
    """
    Detect data quality issues

    Returns:
        Dict with anomaly information
    """
    anomalies = {}

    # Check for null values
    null_counts = df.isnull().sum()
    if null_counts.any():
        anomalies['null_values'] = null_counts[null_counts > 0].to_dict()

    # Check for duplicates
    dup_count = df.duplicated().sum()
    if dup_count > 0:
        anomalies['duplicate_rows'] = int(dup_count)

    # Check for empty strings in object columns
    for col in df.select_dtypes(include=['object']).columns:
        empty_count = (df[col] == '').sum()
        if empty_count > 0:
            if 'empty_strings' not in anomalies:
                anomalies['empty_strings'] = {}
            anomalies['empty_strings'][col] = int(empty_count)

    if anomalies:
        logger.warning(f"⚠️ Anomalies detected: {anomalies}")
    else:
        logger.info("✅ No anomalies detected")

    return anomalies


if __name__ == "__main__":
    # Example usage
    df = pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
        'age': [25, 30, 35]
    })

    validate_schema(df, ['id', 'name', 'age'])
    validate_data_types(df, {'id': 'int', 'name': 'object', 'age': 'int'})
    anomalies = detect_anomalies(df)
    print(f"Anomalies: {anomalies}")
```

3. **Créer tests/test_validation.py :**
```python
"""
Tests for validation module
"""
import pytest
import pandas as pd
from src.validation import validate_schema, validate_data_types, detect_anomalies


def test_validate_schema_success():
    """Test successful schema validation"""
    df = pd.DataFrame({'a': [1, 2], 'b': [3, 4]})
    assert validate_schema(df, ['a', 'b']) == True


def test_validate_schema_missing_columns():
    """Test schema validation with missing columns"""
    df = pd.DataFrame({'a': [1, 2]})

    with pytest.raises(ValueError, match="Missing required columns"):
        validate_schema(df, ['a', 'b', 'c'])


def test_validate_data_types_success():
    """Test successful type validation"""
    df = pd.DataFrame({'id': [1, 2], 'name': ['Alice', 'Bob']})

    assert validate_data_types(df, {'id': 'int', 'name': 'object'}) == True


def test_validate_data_types_mismatch():
    """Test type validation with mismatch"""
    df = pd.DataFrame({'id': ['a', 'b']})

    with pytest.raises(TypeError, match="has type"):
        validate_data_types(df, {'id': 'int'})


def test_detect_anomalies_nulls():
    """Test anomaly detection with null values"""
    df = pd.DataFrame({'a': [1, None, 3], 'b': [4, 5, None]})

    anomalies = detect_anomalies(df)

    assert 'null_values' in anomalies
    assert anomalies['null_values']['a'] == 1
    assert anomalies['null_values']['b'] == 1


def test_detect_anomalies_duplicates():
    """Test anomaly detection with duplicates"""
    df = pd.DataFrame({'a': [1, 2, 1], 'b': [3, 4, 3]})

    anomalies = detect_anomalies(df)

    assert 'duplicate_rows' in anomalies
    assert anomalies['duplicate_rows'] == 1


def test_detect_anomalies_empty_strings():
    """Test anomaly detection with empty strings"""
    df = pd.DataFrame({'name': ['Alice', '', 'Bob']})

    anomalies = detect_anomalies(df)

    assert 'empty_strings' in anomalies
    assert anomalies['empty_strings']['name'] == 1
```

4. **Mettre à jour README.md :**

Ajoutez une section :
```markdown
## Features

### Data Validation

Le module de validation permet de vérifier la qualité des données :

```python
from src.validation import validate_schema, validate_data_types, detect_anomalies

# Valider le schéma
validate_schema(df, ['id', 'name', 'age'])

# Valider les types
validate_data_types(df, {'id': 'int', 'name': 'object'})

# Détecter les anomalies
anomalies = detect_anomalies(df)
\```
```

5. **Committer et pousser :**
```bash
git add .
git commit -m "feat: add comprehensive data validation module

- Schema validation with clear error messages
- Data type validation
- Anomaly detection (nulls, duplicates, empty strings)
- Full test coverage
- Documentation updated

Closes #2"

git push -u origin feature/data-validation
```

6. **Créer la Pull Request avec un template complet :**
```markdown
## 🎯 Feature: Data Validation Module

Implémentation d'un module de validation complet pour assurer la qualité des données.

## 📝 Changements

### Nouveau fichier : `src/validation.py`
- `validate_schema()` : Vérifie que les colonnes attendues sont présentes
- `validate_data_types()` : Valide les types de données
- `detect_anomalies()` : Détecte les problèmes de qualité (nulls, duplicates, empty strings)

### Tests : `tests/test_validation.py`
- 7 tests unitaires couvrant tous les cas
- Couverture à 100% du module

### Documentation
- README mis à jour avec exemples d'utilisation

## ✅ Checklist

- [x] Code implémenté
- [x] Tests unitaires ajoutés (7 tests)
- [x] Tests passent localement
- [x] Documentation mise à jour
- [x] Pas de régression

## 🔗 Liens

Closes #2

## ⚠️ Points d'attention pour reviewers

- Vérifier que les messages d'erreur sont clairs
- Suggérer d'autres types d'anomalies à détecter
- Vérifier la gestion des edge cases

## 📊 Coverage

Tests coverage: 100% du module validation
```

**NE MERGEZ PAS ENCORE - Passez à la tâche suivante**

**Critères de validation :**
- ✅ Module de validation complet créé
- ✅ Tests unitaires complets
- ✅ PR créée avec description détaillée
- ✅ Issue #2 liée

---

## ⚙️ Partie 4 : GitHub Actions - CI/CD (1h30)

### Tâche 4.1 : Créer un workflow de tests

**Instructions :**

1. **Créer le fichier `.github/workflows/tests.yml` :**
```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}

    - name: Cache pip packages
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest pytest-cov
        pip install -r requirements.txt

    - name: Run tests with coverage
      run: |
        pytest tests/ --cov=src --cov-report=xml --cov-report=term

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v4
      with:
        file: ./coverage.xml
        fail_ci_if_error: false
```

2. **Créer le fichier `.github/workflows/lint.yml` :**
```yaml
name: Code Quality

on:
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install linters
      run: |
        pip install black flake8 mypy

    - name: Check code formatting with Black
      run: |
        black --check src/ tests/ || echo "⚠️ Code needs formatting"

    - name: Lint with Flake8
      run: |
        flake8 src/ tests/ --max-line-length=100 --extend-ignore=E203,W503

    - name: Type check with MyPy
      run: |
        mypy src/ --ignore-missing-imports || echo "⚠️ Type hints need improvement"
```

3. **Ajouter à votre branche actuelle (feature/data-validation) :**
```bash
git add .github/
git commit -m "ci: add GitHub Actions workflows for tests and linting"
git push
```

4. **Vérifier que les workflows s'exécutent :**
   - Allez sur votre PR
   - Vérifiez l'onglet "Checks"
   - Les workflows devraient s'exécuter automatiquement

**Critères de validation :**
- ✅ Fichiers workflows créés
- ✅ Workflows s'exécutent sur la PR
- ✅ Tests passent

---

### Tâche 4.2 : Protéger la branche main

**Instructions :**

1. Allez dans **Settings** → **Branches**
2. Cliquez sur **Add branch protection rule**
3. Branch name pattern : `main`
4. Configurez :
   - ✅ **Require a pull request before merging**
     - Require approvals : 1
     - ✅ Dismiss stale reviews
   - ✅ **Require status checks to pass before merging**
     - Ajoutez les checks : "test", "lint"
     - ✅ Require branches to be up to date
   - ✅ **Require conversation resolution before merging**
5. Cliquez sur **Create**

**Critères de validation :**
- ✅ Branch protection activée
- ✅ Impossible de push directement sur main

---

### Tâche 4.3 : Merger la PR avec les CI checks

**Instructions :**

1. Retournez sur votre PR `feature/data-validation`
2. Vérifiez que tous les checks sont verts ✅
3. Si des checks échouent, corrigez :
```bash
# Formater le code
black src/ tests/

# Commit et push
git add .
git commit -m "style: format code with black"
git push
```

4. Une fois tous les checks verts :
   - Cliquez sur "Merge pull request"
   - Choisissez "Squash and merge"
   - Confirmez

5. **Nettoyage :**
```bash
git checkout main
git pull origin main
git branch -d feature/data-validation
```

6. **Déplacer les issues dans GitHub Project :**
   - Issue #1 → Done
   - Issue #2 → Done

**Critères de validation :**
- ✅ Tous les CI checks passent
- ✅ PR mergée avec succès
- ✅ Issues fermées automatiquement
- ✅ Project mis à jour

---

## 🔒 Partie 5 : Sécurité et bonnes pratiques (1h)

### Tâche 5.1 : Activer Dependabot

**Instructions :**

1. **Allez dans Settings → Code security and analysis**
2. **Activez :**
   - ✅ Dependabot alerts
   - ✅ Dependabot security updates

3. **Créer `.github/dependabot.yml` :**
```yaml
version: 2
updates:
  # Python dependencies
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "votre-username"
    labels:
      - "dependencies"
      - "python"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "github-actions"
```

4. **Committer :**
```bash
git checkout -b config/dependabot
git add .github/dependabot.yml
git commit -m "chore: configure Dependabot for automated dependency updates"
git push -u origin config/dependabot
```

5. **Créer une PR et merger rapidement**

**Critères de validation :**
- ✅ Dependabot activé
- ✅ Configuration commitée

---

### Tâche 5.2 : Ajouter des secrets

**Instructions :**

1. **Allez dans Settings → Secrets and variables → Actions**
2. **Cliquez sur New repository secret**
3. **Créez les secrets suivants :**
   - Nom : `DATABASE_URL`
   - Value : `postgresql://user:password@localhost:5432/mydb`

   - Nom : `API_KEY`
   - Value : `test-api-key-12345`

4. **Créer un workflow de déploiement `.github/workflows/deploy.yml` :**
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        pip install -r requirements.txt

    - name: Run deployment tests
      env:
        DATABASE_URL: ${{ secrets.DATABASE_URL }}
        API_KEY: ${{ secrets.API_KEY }}
      run: |
        echo "Running deployment tests..."
        pytest tests/ -v

    - name: Deploy notification
      run: |
        echo "✅ Deployment successful for ${{ github.ref_name }}"
```

5. **Committer :**
```bash
git checkout main
git pull
git checkout -b feat/deployment-workflow
git add .github/workflows/deploy.yml
git commit -m "feat: add deployment workflow with secrets"
git push -u origin feat/deployment-workflow
```

6. **Créer une PR et merger**

**Critères de validation :**
- ✅ Secrets configurés
- ✅ Workflow de déploiement créé

---

### Tâche 5.3 : Créer une release avec tag

**Instructions :**

1. **Créer un tag :**
```bash
git checkout main
git pull origin main

# Créer un tag annoté
git tag -a v1.0.0 -m "Release v1.0.0 - Production Ready

Features:
- Complete ETL pipeline
- Data validation module
- CI/CD with GitHub Actions
- Comprehensive test suite"

# Pousser le tag
git push origin v1.0.0
```

2. **Créer une Release sur GitHub :**
   - Allez dans l'onglet **Releases**
   - Cliquez sur **Draft a new release**
   - Choisissez le tag `v1.0.0`
   - Titre : `v1.0.0 - Production Ready`
   - Description :

```markdown
## 🎉 First Production Release

Cette version marque la première release stable du pipeline de données.

## ✨ Features

- ✅ ETL Pipeline complet (extract, transform, load)
- ✅ Module de validation des données
- ✅ Gestion des erreurs robuste
- ✅ CI/CD automatisé avec GitHub Actions
- ✅ Tests unitaires avec 90%+ coverage
- ✅ Linting et formatage automatique

## 📦 Installation

\```bash
pip install -r requirements.txt
\```

## 🚀 Usage

\```python
from src.pipeline import run_pipeline

run_pipeline('input.csv', 'output.csv')
\```

## 🐛 Bug Fixes

- Fixed: Pipeline now handles empty CSV files (#1)

## 🙏 Contributors

- @votre-username

## 📊 Stats

- 5 Issues closed
- 4 Pull Requests merged
- 15 commits
- 200+ lines of code
```

3. **Cliquez sur "Publish release"**

4. **Vérifier que le workflow deploy.yml s'exécute**

**Critères de validation :**
- ✅ Tag créé et poussé
- ✅ Release publiée sur GitHub
- ✅ Workflow de déploiement déclenché

---

## 📚 Partie 6 : Documentation et finitions (30 min)

### Tâche 6.1 : Améliorer le README

**Instructions :**

Mettez à jour votre README.md avec un template complet :

```markdown
# 📊 GitHub Data Pipeline Advanced

![Tests](https://github.com/votre-username/github-data-pipeline-advanced/workflows/Tests/badge.svg)
![Code Quality](https://github.com/votre-username/github-data-pipeline-advanced/workflows/Code%20Quality/badge.svg)
![Python Version](https://img.shields.io/badge/python-3.9%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

Pipeline ETL avancé pour Data Engineering avec fonctionnalités GitHub complètes.

## 🎯 Features

- ✅ Pipeline ETL complet (Extract, Transform, Load)
- ✅ Module de validation des données
- ✅ Gestion robuste des erreurs
- ✅ CI/CD avec GitHub Actions
- ✅ Tests automatisés avec 90%+ coverage
- ✅ Code quality checks (Black, Flake8, MyPy)

## 🚀 Quick Start

\```bash
# Cloner le projet
git clone git@github.com:votre-username/github-data-pipeline-advanced.git
cd github-data-pipeline-advanced

# Installer les dépendances
pip install -r requirements.txt

# Lancer le pipeline
python -m src.pipeline
\```

## 📦 Installation

\```bash
pip install -r requirements.txt
\```

## 🔧 Usage

### Pipeline de base

\```python
from src.pipeline import run_pipeline

# Exécuter le pipeline complet
run_pipeline('input.csv', 'output.csv')
\```

### Validation des données

\```python
from src.validation import validate_schema, detect_anomalies
import pandas as pd

df = pd.read_csv('data.csv')

# Valider le schéma
validate_schema(df, ['id', 'name', 'value'])

# Détecter les anomalies
anomalies = detect_anomalies(df)
print(f"Anomalies trouvées: {anomalies}")
\```

## 🏗️ Architecture

\```
github-data-pipeline-advanced/
├── .github/
│   ├── workflows/
│   │   ├── tests.yml          # Tests automatisés
│   │   ├── lint.yml           # Code quality
│   │   └── deploy.yml         # Déploiement
│   └── dependabot.yml         # Mises à jour auto
├── src/
│   ├── __init__.py
│   ├── pipeline.py            # Pipeline ETL principal
│   └── validation.py          # Validation des données
├── tests/
│   ├── test_pipeline.py
│   └── test_validation.py
├── requirements.txt
└── README.md
\```

## 🧪 Tests

\```bash
# Lancer tous les tests
pytest tests/

# Avec coverage
pytest tests/ --cov=src --cov-report=html

# Ouvrir le rapport
open htmlcov/index.html
\```

## 🎨 Code Quality

\```bash
# Formater le code
black src/ tests/

# Linting
flake8 src/ tests/ --max-line-length=100

# Type checking
mypy src/
\```

## 🚀 CI/CD

Le projet utilise GitHub Actions pour :
- ✅ Tests automatiques sur Python 3.9, 3.10, 3.11
- ✅ Vérification du code style
- ✅ Type checking
- ✅ Déploiement sur tag

## 🤝 Contributing

Les contributions sont les bienvenues !

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit vos changements (`git commit -m 'feat: add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour plus de détails.

## 📄 License

Ce projet est sous license MIT - voir [LICENSE](LICENSE) pour plus de détails.

## 👥 Authors

- [@votre-username](https://github.com/votre-username) - Initial work

## 🙏 Acknowledgments

- Inspiré par les best practices Data Engineering
- GitHub Actions documentation
- Python testing best practices

## 📞 Contact

Pour toute question : votre.email@example.com

---

⭐ Si ce projet vous a été utile, n'hésitez pas à lui donner une étoile !
```

**Committer :**
```bash
git checkout main
git pull
git checkout -b docs/improve-readme
git add README.md
git commit -m "docs: comprehensive README with badges and examples"
git push -u origin docs/improve-readme
```

**Créer une PR et merger**

**Critères de validation :**
- ✅ README complet avec badges
- ✅ Documentation claire
- ✅ Exemples d'utilisation

---

### Tâche 6.2 : Créer un CONTRIBUTING.md

Créez un fichier `CONTRIBUTING.md` :

```markdown
# Contributing to GitHub Data Pipeline Advanced

Merci de votre intérêt pour contribuer à ce projet ! 🎉

## 🚀 Comment contribuer

### Signaler un bug

1. Vérifiez que le bug n'a pas déjà été signalé dans les [Issues](../../issues)
2. Créez une nouvelle issue avec le template "Bug Report"
3. Décrivez le bug de manière détaillée
4. Incluez les steps to reproduce
5. Mentionnez votre environnement (OS, Python version, etc.)

### Proposer une feature

1. Créez une issue avec le template "Feature Request"
2. Décrivez la fonctionnalité en détail
3. Expliquez pourquoi elle serait utile
4. Proposez une implémentation si possible

### Soumettre une Pull Request

1. **Fork le projet**
2. **Créez une branche feature :**
   \```bash
   git checkout -b feature/ma-nouvelle-feature
   \```

3. **Faites vos modifications**
4. **Ajoutez des tests**
5. **Vérifiez que tout passe :**
   \```bash
   pytest tests/
   black src/ tests/
   flake8 src/ tests/
   \```

6. **Commit avec un message clair :**
   \```bash
   git commit -m "feat: add amazing feature"
   \```

   Suivez le format Conventional Commits :
   - `feat:` nouvelle fonctionnalité
   - `fix:` correction de bug
   - `docs:` documentation
   - `test:` ajout de tests
   - `refactor:` refactoring
   - `chore:` maintenance

7. **Push et créez une PR**

## 📋 Checklist avant de soumettre

- [ ] Tests ajoutés et qui passent
- [ ] Code formaté avec Black
- [ ] Pas de warnings Flake8
- [ ] Documentation mise à jour
- [ ] CHANGELOG mis à jour (si applicable)

## 🎨 Style Guide

- Suivre PEP 8
- Utiliser Black pour le formatage
- Max line length: 100
- Docstrings pour toutes les fonctions publiques
- Type hints encouragés

## 🧪 Tests

- Couverture minimum : 80%
- Tests unitaires obligatoires pour nouvelles features
- Tests d'intégration pour les workflows

## 📝 Commit Messages

Format : `type(scope): description`

Exemples :
- `feat(validation): add email validation`
- `fix(pipeline): handle None values in transform`
- `docs(readme): update installation instructions`

## 🤝 Code Review

- Soyez respectueux et constructif
- Proposez des solutions, pas seulement des critiques
- Acceptez les feedbacks avec ouverture
- Les reviews sont là pour améliorer le code

## ❓ Questions

Si vous avez des questions, n'hésitez pas à :
- Ouvrir une issue
- Me contacter : votre.email@example.com

Merci de contribuer ! 🙏
```

**Committer :**
```bash
git add CONTRIBUTING.md
git commit -m "docs: add contributing guidelines"
git push
```

**Critères de validation :**
- ✅ CONTRIBUTING.md créé
- ✅ Guidelines claires

---

## 📤 Livrables

À la fin du brief, vous devez avoir :

### 1. Repository GitHub complet avec :
- ✅ Code source du pipeline
- ✅ Module de validation
- ✅ Tests unitaires (couverture > 80%)
- ✅ 3+ workflows GitHub Actions fonctionnels
- ✅ Branch protection sur main
- ✅ README complet avec badges
- ✅ CONTRIBUTING.md

### 2. Issues et Project management :
- ✅ 5+ issues créées et fermées
- ✅ GitHub Project avec colonnes Kanban
- ✅ Milestone v1.0.0 complété

### 3. Pull Requests :
- ✅ Minimum 4 PR créées et mergées
- ✅ Code reviews effectués
- ✅ Tous les CI checks passent

### 4. Release :
- ✅ Tag v1.0.0 créé
- ✅ Release publiée sur GitHub
- ✅ Notes de release complètes

### 5. Sécurité :
- ✅ Dependabot activé
- ✅ Secrets configurés
- ✅ Branch protection activée

### 6. Documentation :
- ✅ README professionnel
- ✅ Guide de contribution
- ✅ Exemples d'utilisation

---

## ✅ Critères d'Évaluation

| Critère | Points |
|---------|--------|
| Configuration du repository (SSH, README, structure) | 10 |
| Issues et gestion de projet (Project, Milestone) | 15 |
| Pull Requests et Code Review | 20 |
| GitHub Actions (Tests, Lint, Deploy) | 20 |
| Sécurité (Dependabot, Secrets, Branch protection) | 15 |
| Documentation (README, CONTRIBUTING) | 10 |
| Release et Tags | 10 |

**Total : 100 points**

**Bonus (+10 points) :**
- Couverture de tests > 90%
- Workflow supplémentaire créatif
- Documentation exceptionnelle

---

## 💡 Conseils

### Workflow quotidien
- 🔄 **Sync souvent** : `git pull origin main` avant de créer une branche
- 🌿 **Branches descriptives** : `feature/add-validation`, `fix/csv-bug`
- 📝 **PR descriptions complètes** : Aidez les reviewers à comprendre
- ✅ **CI Green** : Ne mergez jamais avec des checks qui échouent
- 🏷️ **Labels pertinents** : Facilitent l'organisation

### Code Review
- 👀 **Lisez tout** avant de commenter
- 💬 **Soyez constructif** : Proposez des solutions
- ⏱️ **Répondez rapidement** : Ne bloquez pas vos collègues
- 🤝 **Acceptez les feedbacks** : C'est pour améliorer le code

### GitHub Actions
- 📦 **Cache les dépendances** : Gagnez du temps
- 🎯 **Tests ciblés** : Ne testez que ce qui a changé
- 🚀 **Parallélisez** : Matrix builds pour tester plusieurs versions
- 🔒 **Secrets sécurisés** : Ne jamais les hardcoder

---

## 🆘 Troubleshooting

### CI checks échouent
```bash
# Lancer les tests localement
pytest tests/

# Formater le code
black src/ tests/

# Vérifier le linting
flake8 src/ tests/ --max-line-length=100
```

### Conflit de merge
```bash
# Mettre à jour main
git checkout main
git pull origin main

# Rebase votre branche
git checkout feature/ma-branche
git rebase main

# Résoudre les conflits
# Éditer les fichiers marqués
git add .
git rebase --continue
```

### Branch protection bloque le merge
- Vérifiez que tous les CI checks sont verts
- Assurez-vous d'avoir au moins une approbation
- Résolvez toutes les conversations

---

## 📚 Ressources

### Documentation officielle
- [GitHub Docs](https://docs.github.com)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitHub CLI](https://cli.github.com)

### Tutorials
- [GitHub Skills](https://skills.github.com)
- [GitHub Learning Lab](https://lab.github.com)

### Tools
- [GitHub Desktop](https://desktop.github.com)
- [VS Code GitHub Integration](https://code.visualstudio.com/docs/editor/github)

### Best Practices
- [Conventional Commits](https://www.conventionalcommits.org)
- [Semantic Versioning](https://semver.org)
- [Keep a Changelog](https://keepachangelog.com)

---

## 🎓 Pour aller plus loin

### Après ce brief, explorez :
- **GitHub Advanced Security** : Code scanning, Secret scanning
- **GitHub Packages** : Héberger vos packages Python
- **GitHub Codespaces** : Dev environment dans le cloud
- **GitHub Projects (Beta)** : Nouvelle version avec tables et roadmaps
- **GitHub API** : Automatiser avec l'API REST ou GraphQL
- **GitHub Apps** : Créer des intégrations personnalisées

---

**Bon courage ! 🚀**

*N'oubliez pas : GitHub n'est pas juste un hébergeur de code, c'est une plateforme complète pour la collaboration et le DevOps !*
