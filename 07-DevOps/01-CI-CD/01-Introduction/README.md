# Introduction au CI/CD

## Table des matières

1. [Qu'est-ce que le CI/CD ?](#quest-ce-que-le-cicd)
2. [Pourquoi le CI/CD ?](#pourquoi-le-cicd)
3. [Les piliers du CI/CD](#les-piliers-du-cicd)
4. [Pipeline CI/CD](#pipeline-cicd)
5. [Outils populaires](#outils-populaires)
6. [Terminologie](#terminologie)
7. [Prérequis](#prérequis)

---

## Qu'est-ce que le CI/CD ?

**CI/CD** est l'acronyme de **Continuous Integration** (Intégration Continue) et **Continuous Delivery/Deployment** (Livraison/Déploiement Continu).

### Continuous Integration (CI)

L'intégration continue est une pratique de développement logiciel où les développeurs intègrent fréquemment leur code dans un dépôt partagé, idéalement plusieurs fois par jour. Chaque intégration est vérifiée par une compilation automatisée et des tests automatisés.

**Objectifs :**
- Détecter les erreurs rapidement
- Réduire les problèmes d'intégration
- Améliorer la qualité du code
- Faciliter la collaboration

### Continuous Delivery (CD)

La livraison continue étend l'intégration continue en s'assurant que le code est toujours dans un état déployable. Le déploiement en production reste une décision manuelle.

**Objectifs :**
- Code toujours prêt pour la production
- Réduire les risques de déploiement
- Déploiements plus fréquents et fiables

### Continuous Deployment (CD)

Le déploiement continu va plus loin : chaque changement qui passe tous les tests est automatiquement déployé en production, sans intervention humaine.

**Objectifs :**
- Automatisation complète du pipeline
- Feedback immédiat sur le code en production
- Cycles de release extrêmement courts

---

## Pourquoi le CI/CD ?

### Problèmes sans CI/CD

```
Développement traditionnel :
┌─────────────────────────────────────────────────────────────┐
│ Dev 1  Dev 2  Dev 3    →    Intégration    →    Tests      │
│   ↓      ↓      ↓           (1-2 semaines)     (1 semaine)  │
│ [Code] [Code] [Code]    →    ❌ Conflits    →   ❌ Bugs     │
│                              ❌ Complexité       ❌ Stress   │
└─────────────────────────────────────────────────────────────┘
Résultat : Déploiements longs, risqués et stressants
```

### Avantages avec CI/CD

```
Développement avec CI/CD :
┌─────────────────────────────────────────────────────────────┐
│ Dev  →  Commit  →  Build  →  Test  →  Deploy               │
│        (quotidien) (auto)   (auto)    (auto)                │
│                                                               │
│ ✅ Feedback rapide (minutes)                                 │
│ ✅ Détection précoce des bugs                                │
│ ✅ Déploiements fréquents et sûrs                            │
│ ✅ Moins de stress                                           │
└─────────────────────────────────────────────────────────────┘
```

### Bénéfices concrets

**Pour les développeurs :**
- Feedback immédiat sur le code
- Moins de temps passé en débogage
- Réduction du "integration hell"
- Plus de confiance dans le code

**Pour l'entreprise :**
- Time-to-market réduit
- Qualité logicielle améliorée
- Coûts de maintenance réduits
- Satisfaction client accrue

**Métriques d'impact :**
- Fréquence de déploiement : de semaines/mois → jours/heures
- Temps de restauration : de heures/jours → minutes
- Taux d'échec des changements : réduit de 50-70%
- Lead time pour les changements : réduit de 60-80%

---

## Les piliers du CI/CD

### 1. Contrôle de version

```bash
# Tout le code doit être versionné
git init
git add .
git commit -m "Initial commit"
git push origin main
```

**Principes :**
- Un seul dépôt de vérité (single source of truth)
- Branches pour les fonctionnalités
- Commits fréquents et petits
- Messages de commit clairs

### 2. Automatisation des builds

```yaml
# Exemple de build automatique
build:
  script:
    - npm install
    - npm run build
    - npm run test
```

**Objectifs :**
- Build reproductible
- Rapide (< 10 minutes idéalement)
- Échec rapide (fail fast)

### 3. Tests automatisés

```
Pyramide des tests :
        /\
       /E2E\        ← Tests end-to-end (peu)
      /──────\
     /Integration\ ← Tests d'intégration (moyen)
    /────────────\
   /  Unit Tests  \ ← Tests unitaires (beaucoup)
  /────────────────\
```

**Types de tests :**
- Tests unitaires : testent les fonctions individuelles
- Tests d'intégration : testent les interactions entre composants
- Tests E2E : testent l'application complète
- Tests de performance : vérifient les performances
- Tests de sécurité : identifient les vulnérabilités

### 4. Gestion des environnements

```
Code → Dev → Test → Staging → Production
       ↓      ↓       ↓          ↓
      Auto   Auto    Auto     Manuel/Auto
```

**Principes :**
- Environnements identiques (parity)
- Infrastructure as Code (IaC)
- Configuration externe (12-factor app)

### 5. Monitoring et feedback

```
Production → Monitoring → Alertes → Feedback → Développeurs
               ↓
          Logs, Metrics, Traces
```

**Éléments clés :**
- Logs centralisés
- Métriques applicatives
- Alertes intelligentes
- Dashboards temps réel

---

## Pipeline CI/CD

### Anatomie d'un pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                        PIPELINE CI/CD                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. SOURCE         2. BUILD         3. TEST        4. DEPLOY     │
│  ┌──────┐        ┌──────┐        ┌──────┐       ┌──────┐        │
│  │ Git  │   →    │Compile│   →   │ Unit │   →  │ Dev  │        │
│  │Commit│        │ Code  │       │Tests │      │ Env  │        │
│  └──────┘        └──────┘        └──────┘       └──────┘        │
│                       ↓               ↓              ↓            │
│                  ┌──────┐        ┌──────┐       ┌──────┐        │
│                  │Docker│        │ Integ│       │Stage │        │
│                  │Image │        │Tests │       │ Env  │        │
│                  └──────┘        └──────┘       └──────┘        │
│                                      ↓              ↓            │
│                                  ┌──────┐       ┌──────┐        │
│                                  │ E2E  │       │ Prod │        │
│                                  │Tests │       │ Env  │        │
│                                  └──────┘       └──────┘        │
│                                                                   │
│  ← Continuous Integration →   ← Continuous Delivery/Deploy →    │
└─────────────────────────────────────────────────────────────────┘
```

### Exemple de pipeline typique

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # 1. PHASE BUILD
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: npm install
      - name: Build
        run: npm run build
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/

  # 2. PHASE TEST
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run unit tests
        run: npm test
      - name: Run integration tests
        run: npm run test:integration
      - name: Code coverage
        run: npm run coverage

  # 3. PHASE SECURITY
  security:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security scan
        run: npm audit
      - name: SAST scan
        run: npm run security:scan

  # 4. PHASE DEPLOY
  deploy:
    needs: [test, security]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying to production..."
          # Commandes de déploiement
```

---

## Outils populaires

### Plateformes CI/CD complètes

| Outil | Type | Cas d'usage |
|-------|------|-------------|
| **GitHub Actions** | Cloud/Self-hosted | Projets GitHub, open source |
| **GitLab CI/CD** | Cloud/Self-hosted | DevOps complet, auto-hébergé |
| **Azure DevOps** | Cloud/Self-hosted | Écosystème Microsoft |
| **Jenkins** | Self-hosted | Hautement personnalisable |
| **CircleCI** | Cloud | Projets modernes, Docker |
| **Travis CI** | Cloud | Open source, simple |

### Outils spécialisés

**Build & Package :**
- Maven, Gradle (Java)
- npm, yarn (JavaScript)
- pip, poetry (Python)
- Docker, Buildpacks

**Tests :**
- Jest, Mocha (JavaScript)
- JUnit, TestNG (Java)
- pytest (Python)
- Selenium, Cypress (E2E)

**Déploiement :**
- Ansible, Terraform
- Kubernetes, Docker Swarm
- AWS CodeDeploy, Azure Pipelines
- Helm, ArgoCD

**Monitoring :**
- Prometheus, Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Datadog, New Relic
- Sentry, Bugsnag

---

## Terminologie

### Termes essentiels

**Pipeline** : Séquence automatisée d'étapes pour transformer le code en logiciel déployable

**Job** : Unité de travail dans un pipeline (ex: build, test, deploy)

**Stage** : Groupe de jobs qui s'exécutent en parallèle

**Artifact** : Fichier produit par le pipeline (ex: binaire compilé, image Docker)

**Runner** : Machine qui exécute les jobs du pipeline

**Webhook** : Notification HTTP déclenchée par un événement (ex: push, PR)

**Blue/Green Deployment** : Stratégie avec deux environnements identiques, un seul actif

**Canary Release** : Déploiement progressif vers un sous-ensemble d'utilisateurs

**Feature Flag** : Activation/désactivation de fonctionnalités sans déploiement

**Rollback** : Retour à une version précédente en cas de problème

### Métriques CI/CD

**Build Success Rate** : Pourcentage de builds réussis

**Mean Time to Recovery (MTTR)** : Temps moyen pour corriger un incident

**Deployment Frequency** : Fréquence des déploiements en production

**Lead Time** : Temps entre le commit et la mise en production

**Change Failure Rate** : Pourcentage de déploiements causant des incidents

---

## Prérequis

Avant de commencer ce cours, vous devriez avoir :

### Connaissances techniques

- **Git** : Commandes de base, branches, merge
- **CLI** : Utilisation du terminal/shell
- **Développement** : Connaissance d'au moins un langage de programmation
- **Docker** : Concepts de base (recommandé)
- **Cloud** : Notions de base AWS/Azure/GCP (recommandé)

### Outils à installer

```bash
# Git
git --version

# Docker (optionnel mais recommandé)
docker --version

# Un éditeur de code
code --version  # VS Code
```

### Accès aux plateformes

- Compte GitHub (gratuit)
- Compte GitLab (gratuit) - optionnel
- Compte Azure (essai gratuit) - optionnel

---

## Structure du cours

```
01-CI-CD/
├── 01-Introduction/          ← Vous êtes ici
├── 02-Git-Workflows/          ← Stratégies de branches
├── 03-GitHub-Actions/         ← CI/CD avec GitHub
├── 04-GitLab-CI/              ← CI/CD avec GitLab
├── 05-Jenkins/                ← CI/CD avec Jenkins
├── 06-Azure-DevOps/           ← CI/CD avec Azure
└── 07-Best-Practices/         ← Bonnes pratiques avancées
```

---

## Pour aller plus loin

### Lectures recommandées

- [Continuous Delivery - Martin Fowler](https://martinfowler.com/bliki/ContinuousDelivery.html)
- [The Phoenix Project](https://itrevolution.com/product/the-phoenix-project/) - Roman DevOps
- [Accelerate](https://itrevolution.com/product/accelerate/) - Métriques DevOps

### Ressources en ligne

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

---

## Prochaines étapes

Passez à la section suivante : **[02-Git-Workflows](../02-Git-Workflows/README.md)**

Vous allez apprendre :
- Git Flow vs GitHub Flow vs GitLab Flow
- Stratégies de branches
- Gestion des pull requests
- Revue de code automatisée
