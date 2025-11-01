# GitHub Actions - CI/CD

## Table des matières

1. [Introduction à GitHub Actions](#introduction-à-github-actions)
2. [Concepts de base](#concepts-de-base)
3. [Syntaxe et structure](#syntaxe-et-structure)
4. [Workflows de base](#workflows-de-base)
5. [Workflows avancés](#workflows-avancés)
6. [Secrets et variables](#secrets-et-variables)
7. [Actions réutilisables](#actions-réutilisables)
8. [Débogage et optimisation](#débogage-et-optimisation)
9. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction à GitHub Actions

GitHub Actions est une plateforme CI/CD intégrée à GitHub qui permet d'automatiser les workflows de développement.

### Pourquoi GitHub Actions ?

**Avantages :**
- Intégration native avec GitHub
- Configuration simple (fichiers YAML)
- Marketplace avec 13000+ actions
- Gratuit pour les repos publics
- 2000 minutes/mois gratuites pour les repos privés
- Exécution sur Linux, Windows, macOS
- Conteneurs et services Docker

**Cas d'usage :**
- CI/CD (build, test, deploy)
- Automatisation de tâches
- Gestion des issues et PRs
- Publication de packages
- Génération de documentation

---

## Concepts de base

### Architecture

```
Repository
  └── .github/workflows/
      ├── ci.yml          ← Workflow file
      ├── deploy.yml
      └── release.yml

Workflow
  └── Jobs (parallel by default)
      └── Steps (sequential)
          └── Actions or Commands
```

### Éléments principaux

**Workflow** : Processus automatisé défini dans un fichier YAML

**Event** : Déclencheur du workflow (push, PR, schedule, etc.)

**Job** : Ensemble d'étapes exécutées sur le même runner

**Step** : Tâche individuelle (commande ou action)

**Action** : Application réutilisable pour une tâche

**Runner** : Serveur qui exécute les workflows

---

## Syntaxe et structure

### Structure minimale

```yaml
# .github/workflows/hello.yml
name: Hello World

on: [push]

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo "Hello, World!"
```

### Events (déclencheurs)

```yaml
# Push sur des branches spécifiques
on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'src/**'
      - '**.js'

# Pull requests
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]

# Multiples events
on: [push, pull_request]

# Schedule (cron)
on:
  schedule:
    - cron: '0 0 * * *'  # Tous les jours à minuit

# Workflow dispatch (manuel)
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'

# Release
on:
  release:
    types: [published]
```

### Jobs et Steps

```yaml
jobs:
  # Job 1
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

  # Job 2 (parallèle à build par défaut)
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test

  # Job 3 (attend que build et test soient terminés)
  deploy:
    needs: [build, test]
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: echo "Deploying..."
```

### Runners

```yaml
jobs:
  linux:
    runs-on: ubuntu-latest  # Ubuntu (le plus commun)

  windows:
    runs-on: windows-latest

  macos:
    runs-on: macos-latest

  multi-os:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
```

---

## Workflows de base

### CI basique (Node.js)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [16, 18, 20]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
```

Voir l'exemple complet : [ci-basic.yml](./ci-basic.yml)

### Build et test Docker

```yaml
# .github/workflows/docker.yml
name: Docker Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            myapp:latest
            myapp:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:latest
          format: 'sarif'
          output: 'trivy-results.sarif'
```

Voir l'exemple complet : [docker-build.yml](./docker-build.yml)

### Terraform déploiement

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: ./terraform

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Init
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        if: github.event_name == 'pull_request'

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

Voir l'exemple complet : [terraform-deploy.yml](./terraform-deploy.yml)

---

## Workflows avancés

### Matrix strategy (tests multi-versions)

```yaml
name: Matrix Tests

jobs:
  test:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        include:
          - os: ubuntu-latest
            node-version: 20
            experimental: true
        exclude:
          - os: macos-latest
            node-version: 16

    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

### Artifacts et caching

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # Cache des dépendances
      - name: Cache node modules
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - run: npm ci
      - run: npm run build

      # Upload artifacts
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
          retention-days: 7

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      # Download artifacts
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: dist
          path: dist/

      - name: Deploy
        run: ./deploy.sh
```

### Environnements et approbations

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.myapp.com
    steps:
      - name: Deploy to staging
        run: ./deploy.sh staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com
    steps:
      - name: Deploy to production
        run: ./deploy.sh production
```

### Conditions et expressions

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        if: github.ref == 'refs/heads/main'
        run: ./deploy.sh

      - name: Deploy to staging
        if: github.ref == 'refs/heads/develop'
        run: ./deploy.sh staging

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        run: gh pr comment ${{ github.event.pull_request.number }} --body "Tests passed!"

      - name: Run only on schedule
        if: github.event_name == 'schedule'
        run: ./cleanup.sh

      - name: Success notification
        if: success()
        run: echo "Build succeeded!"

      - name: Failure notification
        if: failure()
        run: echo "Build failed!"
```

### Workflows réutilisables

```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy-token:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ${{ inputs.environment }}
        run: ./deploy.sh ${{ inputs.environment }}
        env:
          TOKEN: ${{ secrets.deploy-token }}
```

```yaml
# .github/workflows/main.yml
name: Main

on: [push]

jobs:
  call-deploy:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: production
    secrets:
      deploy-token: ${{ secrets.DEPLOY_TOKEN }}
```

---

## Secrets et variables

### Secrets

```yaml
# Utiliser dans les workflows
steps:
  - name: Use secret
    run: echo "Secret value: ${{ secrets.MY_SECRET }}"
    env:
      API_KEY: ${{ secrets.API_KEY }}
```

**Configuration dans GitHub :**
1. Repository → Settings → Secrets and variables → Actions
2. New repository secret
3. Nom : `API_KEY`
4. Valeur : votre clé secrète

**Bonnes pratiques :**
- Jamais de secrets en dur dans le code
- Utilisez des secrets pour : API keys, tokens, passwords
- Limiter l'accès aux secrets (environments)
- Rotation régulière des secrets

### Variables d'environnement

```yaml
env:
  NODE_ENV: production
  DATABASE_URL: ${{ secrets.DATABASE_URL }}

jobs:
  build:
    env:
      BUILD_ENV: staging
    runs-on: ubuntu-latest
    steps:
      - name: Build
        env:
          STEP_VAR: value
        run: |
          echo "NODE_ENV: $NODE_ENV"
          echo "BUILD_ENV: $BUILD_ENV"
          echo "STEP_VAR: $STEP_VAR"
```

### Variables GitHub

```yaml
steps:
  - name: Print GitHub context
    run: |
      echo "Repository: ${{ github.repository }}"
      echo "Branch: ${{ github.ref }}"
      echo "Commit SHA: ${{ github.sha }}"
      echo "Actor: ${{ github.actor }}"
      echo "Event: ${{ github.event_name }}"
      echo "Run ID: ${{ github.run_id }}"
      echo "Run number: ${{ github.run_number }}"
```

---

## Actions réutilisables

### Actions populaires

```yaml
# Checkout code
- uses: actions/checkout@v3

# Setup Node.js
- uses: actions/setup-node@v3
  with:
    node-version: '18'

# Setup Python
- uses: actions/setup-python@v4
  with:
    python-version: '3.11'

# Cache
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

# Upload artifacts
- uses: actions/upload-artifact@v3
  with:
    name: my-artifact
    path: path/to/artifact

# Download artifacts
- uses: actions/download-artifact@v3
  with:
    name: my-artifact

# Deploy to GitHub Pages
- uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./public

# Slack notification
- uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Créer une action personnalisée

```yaml
# .github/actions/hello/action.yml
name: 'Hello Action'
description: 'Greet someone'
inputs:
  who-to-greet:
    description: 'Who to greet'
    required: true
    default: 'World'
outputs:
  random-number:
    description: 'Random number'
    value: ${{ steps.random.outputs.number }}
runs:
  using: 'composite'
  steps:
    - run: echo "Hello ${{ inputs.who-to-greet }}"
      shell: bash
    - id: random
      run: echo "number=$(($RANDOM % 100))" >> $GITHUB_OUTPUT
      shell: bash
```

```yaml
# Utiliser l'action
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ./.github/actions/hello
        with:
          who-to-greet: 'GitHub Actions'
```

---

## Débogage et optimisation

### Activer le debug

```bash
# Dans GitHub, ajouter ces secrets
ACTIONS_RUNNER_DEBUG: true
ACTIONS_STEP_DEBUG: true
```

### Logs et debugging

```yaml
steps:
  - name: Debug info
    run: |
      echo "Event: ${{ github.event_name }}"
      echo "Ref: ${{ github.ref }}"
      echo "SHA: ${{ github.sha }}"
      env

  - name: Conditional debug
    if: runner.debug == '1'
    run: |
      ls -la
      pwd
      env
```

### Optimisation des workflows

**1. Caching des dépendances**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

**2. Parallélisation**
```yaml
jobs:
  test-unit:
    runs-on: ubuntu-latest
    steps: [...]

  test-integration:  # Parallèle à test-unit
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: [test-unit, test-integration]  # Attend les deux
    runs-on: ubuntu-latest
    steps: [...]
```

**3. Fail fast**
```yaml
strategy:
  fail-fast: true  # Arrêter tous les jobs si un échoue
  matrix:
    node: [16, 18, 20]
```

**4. Limiter les runs inutiles**
```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
    branches-ignore:
      - 'docs/**'
```

---

## Bonnes pratiques

### Sécurité

```yaml
# Limiter les permissions
permissions:
  contents: read
  pull-requests: write

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Utiliser des versions fixées (tag ou SHA)
      - uses: actions/checkout@8e5e7e5ab8b370d6c329ec480221332ada57f0ab  # v3.5.2

      # Ne pas exposer de secrets dans les logs
      - name: Use secret safely
        run: |
          # Mauvais
          echo "API_KEY=${{ secrets.API_KEY }}"

          # Bon
          curl -H "Authorization: Bearer ${{ secrets.API_KEY }}" https://api.example.com
```

### Structure et organisation

```yaml
name: CI/CD Pipeline

# Description claire
# Author: Team DevOps
# Last updated: 2024-01-15

on:
  push:
    branches: [main, develop]

env:
  NODE_VERSION: '18'
  CACHE_VERSION: v1

jobs:
  # Noms descriptifs
  lint-and-format:
    name: Lint and Format Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v3

      - name: Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}

      # Commenter les étapes complexes
      - name: Run ESLint
        run: npm run lint
        # ESLint config: .eslintrc.json
```

### Gestion des erreurs

```yaml
steps:
  - name: Run tests
    id: tests
    continue-on-error: true
    run: npm test

  - name: Handle test failure
    if: steps.tests.outcome == 'failure'
    run: |
      echo "Tests failed, notifying team..."
      # Envoyer notification

  - name: Always cleanup
    if: always()
    run: ./cleanup.sh
```

---

## Exemples de projets complets

### Application Node.js avec déploiement

Voir : [ci-basic.yml](./ci-basic.yml)

### Application Docker avec Azure

Voir : [docker-build.yml](./docker-build.yml)

### Infrastructure Terraform

Voir : [terraform-deploy.yml](./terraform-deploy.yml)

---

## Exercices pratiques

### Exercice 1 : CI basique
1. Créer un workflow qui teste une app Node.js
2. Ajouter le linting
3. Uploader les résultats de test

### Exercice 2 : Build Docker
1. Créer un workflow qui build une image Docker
2. Pusher sur Docker Hub
3. Scanner l'image pour les vulnérabilités

### Exercice 3 : Déploiement automatique
1. Créer un workflow avec environnements staging/prod
2. Déployer automatiquement sur staging
3. Nécessiter approbation pour production

---

## Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Awesome GitHub Actions](https://github.com/sdras/awesome-actions)
- [GitHub Actions Examples](https://github.com/actions/starter-workflows)

---

## Prochaines étapes

Passez à la section suivante : **[04-GitLab-CI](../04-GitLab-CI/README.md)**
