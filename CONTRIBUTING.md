# Guide de Contribution

Ce document explique comment contribuer au projet Formation Data Engineer.

## Table des matières

- [Configuration de l'environnement](#configuration-de-lenvironnement)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Commits Conventionnels](#commits-conventionnels)
- [Semantic Release](#semantic-release)
- [Workflow de développement](#workflow-de-développement)

## Configuration de l'environnement

### 1. Installation de pre-commit

Pre-commit vérifie automatiquement votre code avant chaque commit pour détecter les secrets, valider la syntaxe, et appliquer le formatage.

```bash
# Installer pre-commit
pip install pre-commit

# Activer les hooks dans le repository
pre-commit install

# Installer le hook pour les messages de commit
pre-commit install --hook-type commit-msg
```

### 2. Installation de Node.js et semantic-release

```bash
# Installer les dépendances npm
npm install

# Installer husky (hooks git)
npm run prepare
```

## Pre-commit Hooks

Les hooks suivants sont activés et s'exécutent automatiquement avant chaque commit:

### Détection de secrets

- **detect-secrets**: Détecte les secrets/credentials dans le code
- **gitleaks**: Détection avancée de secrets (clés API, tokens, passwords)
- **detect-private-key**: Détecte les clés privées SSH/PEM
- **detect-aws-credentials**: Détecte les credentials AWS

### Validation Terraform

- **terraform_fmt**: Formate automatiquement les fichiers `.tf`
- **terraform_validate**: Valide la syntaxe Terraform
- **terraform_tfsec**: Analyse de sécurité du code Terraform

### Autres vérifications

- **check-yaml**: Valide les fichiers YAML
- **check-json**: Valide les fichiers JSON
- **check-merge-conflict**: Détecte les marqueurs de merge conflict
- **check-added-large-files**: Empêche le commit de fichiers > 1MB
- **trailing-whitespace**: Supprime les espaces en fin de ligne

### Exécuter manuellement

```bash
# Exécuter tous les hooks sur tous les fichiers
pre-commit run --all-files

# Exécuter un hook spécifique
pre-commit run detect-secrets --all-files
pre-commit run terraform_fmt --all-files

# Mettre à jour les versions des hooks
pre-commit autoupdate
```

### Bypass (à utiliser avec précaution)

```bash
# Skip les pre-commit hooks (DÉCONSEILLÉ)
git commit --no-verify -m "votre message"
```

## Commits Conventionnels

Ce projet utilise les **Conventional Commits** pour générer automatiquement le changelog et les versions.

### Format des commits

```
<type>(<scope>): <description>

[corps optionnel]

[footer optionnel]
```

### Types de commits

| Type       | Description                                      | Impact version |
|------------|--------------------------------------------------|----------------|
| `feat`     | Nouvelle fonctionnalité                          | MINOR (0.x.0)  |
| `fix`      | Correction de bug                                | PATCH (0.0.x)  |
| `docs`     | Documentation uniquement                         | PATCH          |
| `style`    | Formatage (n'affecte pas le code)               | Aucun          |
| `refactor` | Refactoring (ni bug ni fonctionnalité)          | PATCH          |
| `perf`     | Amélioration de performance                      | PATCH          |
| `test`     | Ajout ou modification de tests                   | Aucun          |
| `build`    | Changements du système de build                  | Aucun          |
| `ci`       | Changements de la CI/CD                          | Aucun          |
| `chore`    | Tâches de maintenance                            | Aucun          |
| `revert`   | Annulation d'un commit précédent                 | PATCH          |

### Breaking Changes

Pour indiquer un changement majeur (MAJOR version - x.0.0):

```bash
git commit -m "feat!: nouvelle API incompatible"
# OU
git commit -m "feat: nouvelle API

BREAKING CHANGE: l'ancienne API est supprimée"
```

### Exemples de commits

```bash
# Nouvelle fonctionnalité
git commit -m "feat(terraform): add hetzner cloud examples"

# Correction de bug
git commit -m "fix(azure): correct variable type in main.tf"

# Documentation
git commit -m "docs(readme): update installation instructions"

# Refactoring
git commit -m "refactor(aws): simplify networking configuration"

# Breaking change
git commit -m "feat(gcp)!: migrate to terraform 1.6"
```

### Commitizen (assistant de commit)

Pour vous aider à créer des commits conformes:

```bash
# Utiliser commitizen pour créer un commit
npm run commit

# Ou directement
npx git-cz
```

Commitizen vous guidera interactivement pour créer le commit.

## Semantic Release

Semantic Release génère automatiquement les versions et le changelog basé sur vos commits.

### Fonctionnement

1. Analyse les commits depuis la dernière version
2. Détermine le type de version (major, minor, patch)
3. Génère le changelog
4. Crée un tag Git
5. Crée une release GitHub

### Règles de versioning

- **Breaking changes** (`feat!:` ou `BREAKING CHANGE:`) → Version MAJOR (1.0.0 → 2.0.0)
- **Features** (`feat:`) → Version MINOR (1.0.0 → 1.1.0)
- **Fixes** (`fix:`, `perf:`, `refactor:`) → Version PATCH (1.0.0 → 1.0.1)
- **Autres** (`docs:`, `style:`, `test:`, etc.) → Pas de nouvelle version

### Exécution

```bash
# Dry-run (voir ce qui serait publié sans publier)
npm run release:dry

# Publier une nouvelle version
npm run release
```

### CI/CD

Semantic-release devrait être exécuté dans la CI/CD (GitHub Actions, GitLab CI, etc.) après chaque merge sur la branche principale:

```yaml
# Exemple GitHub Actions
name: Release
on:
  push:
    branches:
      - main

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Workflow de développement

### 1. Créer une branche

```bash
git checkout -b feature/ma-nouvelle-fonctionnalite
```

### 2. Développer et commiter

```bash
# Modifier des fichiers
vim 03-Infrastructure-as-Code/Terraform/aws/exemple.tf

# Les pre-commit hooks s'exécutent automatiquement
git add .
git commit -m "feat(aws): add new example for EC2"
```

### 3. Push et Pull Request

```bash
git push origin feature/ma-nouvelle-fonctionnalite
```

Créer une Pull Request sur GitHub vers `main`.

### 4. Merge et Release

Une fois la PR mergée:
- Semantic-release s'exécute automatiquement
- Une nouvelle version est créée si nécessaire
- Le CHANGELOG.md est mis à jour
- Une release GitHub est créée

## Résolution de problèmes

### Pre-commit échoue avec des secrets détectés

```bash
# Voir quels secrets ont été détectés
pre-commit run detect-secrets --all-files

# Auditer les secrets détectés
detect-secrets audit .secrets.baseline

# Si c'est un faux positif, marquer comme tel dans .secrets.baseline
```

### Terraform validation échoue

```bash
# Formater tous les fichiers Terraform
terraform fmt -recursive .

# Valider un module spécifique
cd 03-Infrastructure-as-Code/Terraform/aws
terraform init
terraform validate
```

### Commit rejeté par commitlint

Assurez-vous que votre message suit le format:
```
<type>(<scope>): <description>
```

Exemple valide:
```bash
git commit -m "feat(terraform): add oracle cloud examples"
```

## Ressources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Pre-commit](https://pre-commit.com/)
- [Semantic Release](https://semantic-release.gitbook.io/)
- [Commitizen](https://github.com/commitizen/cz-cli)
