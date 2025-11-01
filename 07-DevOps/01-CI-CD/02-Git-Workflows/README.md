# Git Workflows et Stratégies de Branches

## Table des matières

1. [Pourquoi un workflow Git ?](#pourquoi-un-workflow-git)
2. [Git Flow](#git-flow)
3. [GitHub Flow](#github-flow)
4. [GitLab Flow](#gitlab-flow)
5. [Trunk-Based Development](#trunk-based-development)
6. [Comparaison des workflows](#comparaison-des-workflows)
7. [Pull Requests et Code Review](#pull-requests-et-code-review)
8. [Conventions de nommage](#conventions-de-nommage)
9. [Bonnes pratiques](#bonnes-pratiques)

---

## Pourquoi un workflow Git ?

Un workflow Git définit comment votre équipe utilise Git pour collaborer efficacement. Un bon workflow :

- Facilite la collaboration
- Réduit les conflits de merge
- Permet des releases fréquentes et sûres
- Simplifie les rollbacks
- Améliore la traçabilité

---

## Git Flow

### Vue d'ensemble

Git Flow est un workflow robuste avec plusieurs branches principales, idéal pour les projets avec releases planifiées.

```
master (production)
  │
  ├─── hotfix/critical-bug ───┐
  │                            ↓
  │                         (merge)
  │                            │
  ↓                            │
release/v2.0 ────────────────┐│
  │                          ↓↓
develop (staging)         master
  │
  ├─── feature/login ───────→│
  │                    (merge)│
  ├─── feature/payment ──────→│
  │                            │
  └────────────────────────────┘
```

### Branches principales

**main (ou master)** : Code en production
- Toujours stable et déployable
- Chaque commit = une version de production
- Tags pour les versions (v1.0.0, v2.0.0)

**develop** : Branche de développement
- Contient les dernières fonctionnalités
- Base pour les features branches
- État "staging"

### Branches de support

**feature/** : Nouvelles fonctionnalités
```bash
# Créer une feature branch
git checkout develop
git checkout -b feature/user-authentication

# Travailler sur la feature
git add .
git commit -m "feat: add login form"

# Merger dans develop
git checkout develop
git merge --no-ff feature/user-authentication
git branch -d feature/user-authentication
git push origin develop
```

**release/** : Préparation d'une nouvelle version
```bash
# Créer une release branch
git checkout develop
git checkout -b release/v2.0.0

# Corrections mineures, mise à jour de version
git commit -m "chore: bump version to 2.0.0"

# Merger dans main ET develop
git checkout main
git merge --no-ff release/v2.0.0
git tag -a v2.0.0 -m "Release version 2.0.0"

git checkout develop
git merge --no-ff release/v2.0.0

git branch -d release/v2.0.0
git push origin --all && git push origin --tags
```

**hotfix/** : Corrections urgentes en production
```bash
# Créer une hotfix branch depuis main
git checkout main
git checkout -b hotfix/critical-security-issue

# Corriger le bug
git commit -m "fix: patch critical security vulnerability"

# Merger dans main ET develop
git checkout main
git merge --no-ff hotfix/critical-security-issue
git tag -a v2.0.1 -m "Hotfix: security patch"

git checkout develop
git merge --no-ff hotfix/critical-security-issue

git branch -d hotfix/critical-security-issue
git push origin --all && git push origin --tags
```

### Avantages et inconvénients

**Avantages :**
- Très structuré et organisé
- Séparation claire entre développement et production
- Parfait pour les releases planifiées
- Support facile pour plusieurs versions en parallèle

**Inconvénients :**
- Complexe pour les petites équipes
- Beaucoup de branches à gérer
- Peut ralentir le déploiement continu
- Overhead pour les projets simples

**Cas d'usage :**
- Logiciels avec releases planifiées (ex: tous les 2 mois)
- Applications nécessitant plusieurs versions en support
- Grandes équipes avec processus formels

---

## GitHub Flow

### Vue d'ensemble

GitHub Flow est un workflow simple et léger, axé sur les déploiements continus.

```
main (production - toujours déployable)
  │
  ├─── feature/add-search ────→│
  │         ↓                   │
  │     [Pull Request]          │
  │         ↓                   │
  │     [Code Review]           │
  │         ↓                   │
  │     [CI Tests]          (merge)
  │         ↓                   │
  │     [Approved]              ↓
  └─────────────────────────→ main → Deploy
```

### Workflow

**1. Créer une branche depuis main**
```bash
# Toujours partir de main
git checkout main
git pull origin main

# Créer une feature branch
git checkout -b feature/add-user-profile
```

**2. Faire des commits**
```bash
git add .
git commit -m "feat: add user profile page"
git commit -m "test: add profile page tests"
git commit -m "docs: update user profile documentation"
```

**3. Ouvrir une Pull Request**
```bash
# Pousser la branche
git push origin feature/add-user-profile

# Sur GitHub, créer une Pull Request
# Title: Add user profile page
# Description: Implements user profile with avatar upload
```

**4. Discussion et Code Review**
```markdown
# Dans la Pull Request
Reviewer: "Could you add input validation?"
Developer: "Done! Added in commit abc123"
```

**5. Tests automatiques**
```yaml
# .github/workflows/pr.yml
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm test
      - run: npm run lint
```

**6. Déployer et tester (optionnel)**
```bash
# Déployer sur un environnement de review
gh pr deploy feature/add-user-profile --env=preview
```

**7. Merger vers main**
```bash
# Via l'interface GitHub ou CLI
gh pr merge 123 --squash
```

**8. Déploiement automatique**
```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: ./deploy.sh
```

### Avantages et inconvénients

**Avantages :**
- Simple et facile à comprendre
- Parfait pour le déploiement continu
- Encourage les petits changements fréquents
- Adapté au développement agile

**Inconvénients :**
- Nécessite une excellente couverture de tests
- Main doit TOUJOURS être stable
- Moins adapté aux releases planifiées
- Peut nécessiter des feature flags

**Cas d'usage :**
- Applications web modernes
- Projets avec déploiement continu
- Petites et moyennes équipes
- Startups et projets agiles

---

## GitLab Flow

### Vue d'ensemble

GitLab Flow combine les avantages de Git Flow et GitHub Flow, avec des branches d'environnement.

```
main (développement)
  │
  ├─── feature/new-dashboard ──→│
  │                       (merge)│
  │                              ↓
  └───────────────────────────→ main
                                  │
                                  ├─→ staging → Deploy staging
                                  │
                                  └─→ production → Deploy prod
```

### Workflow avec environnements

**1. Développement sur main**
```bash
# Feature branches mergent dans main
git checkout main
git checkout -b feature/notifications

# Développement...
git commit -m "feat: add push notifications"

# Pull Request vers main
git push origin feature/notifications
```

**2. Merge dans main = Déploiement en dev**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy-dev

deploy-dev:
  stage: deploy-dev
  script:
    - echo "Deploying to dev environment"
    - ./deploy.sh dev
  only:
    - main
```

**3. Promotion vers staging**
```bash
# Quand prêt pour staging
git checkout staging
git merge main
git push origin staging

# Déclenche automatiquement le déploiement staging
```

**4. Promotion vers production**
```bash
# Après validation en staging
git checkout production
git merge staging
git push origin production

# Déclenche automatiquement le déploiement prod
```

### Workflow avec releases

```
main
  │
  ├─── feature/api-v2 ──→│
  │                      │
  └──────────────────────┘
                          │
                          ├─→ release/v1.0 → Hotfixes v1.0
                          │
                          └─→ release/v2.0 → Support v2.0
```

### Avantages et inconvénients

**Avantages :**
- Flexible et adaptable
- Support des environnements multiples
- Bon compromis entre Git Flow et GitHub Flow
- Facilite les hotfixes

**Inconvénients :**
- Peut être complexe au début
- Nécessite une bonne CI/CD
- Doit être adapté au projet

**Cas d'usage :**
- Projets avec plusieurs environnements
- Applications nécessitant validation avant production
- Équipes utilisant GitLab
- Projets avec cycles de release variés

---

## Trunk-Based Development

### Vue d'ensemble

Développement basé sur une seule branche principale (trunk/main), avec des branches de courte durée.

```
main (trunk)
  │
  ├─── tiny-feature-1 (< 2 jours) ──→│
  │                            (merge)│
  ├─── tiny-feature-2 (< 1 jour) ───→│
  │                                   │
  │  [Feature Flags pour grosses features]
  │                                   │
  └───────────────────────────────────┘
      Déploiement continu
```

### Principes clés

**1. Branches de courte durée**
```bash
# Créer une petite feature (< 2 jours de travail)
git checkout -b add-button
git commit -m "feat: add submit button"
git push origin add-button

# Merger rapidement (dans les 24h)
git checkout main
git merge add-button
git push origin main
```

**2. Feature Flags**
```javascript
// Activer/désactiver des features sans déploiement
if (featureFlags.isEnabled('newDashboard')) {
  return <NewDashboard />;
} else {
  return <OldDashboard />;
}
```

**3. Commits directement sur main (experts)**
```bash
# Pour les développeurs seniors/experts
git checkout main
git pull origin main
# Faire un petit changement
git commit -m "fix: typo in button label"
git push origin main
```

### Configuration CI/CD

```yaml
# .github/workflows/trunk.yml
name: Trunk-Based Development

on:
  push:
    branches: [main]

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # Tests ultra-rapides (< 5 min)
      - name: Run fast tests
        run: npm test

      # Build
      - name: Build
        run: npm run build

      # Déploiement automatique
      - name: Deploy
        run: ./deploy.sh

      # Tests post-déploiement
      - name: Smoke tests
        run: npm run test:smoke

      # Rollback automatique si échec
      - name: Rollback on failure
        if: failure()
        run: ./rollback.sh
```

### Avantages et inconvénients

**Avantages :**
- Déploiements ultra-fréquents
- Moins de conflits de merge
- Feedback très rapide
- Simplifie le workflow

**Inconvénients :**
- Nécessite une discipline d'équipe
- Tests doivent être ultra-rapides
- Feature flags peuvent compliquer le code
- Nécessite une CI/CD robuste

**Cas d'usage :**
- Équipes matures et disciplinées
- Projets avec déploiement continu intensif
- Tech companies (Google, Facebook, etc.)
- Applications cloud-native

---

## Comparaison des workflows

| Critère | Git Flow | GitHub Flow | GitLab Flow | Trunk-Based |
|---------|----------|-------------|-------------|-------------|
| **Complexité** | Élevée | Faible | Moyenne | Faible |
| **Branches** | Multiples | Une (main) | Environnements | Une (main) |
| **Déploiement** | Planifié | Continu | Mixte | Ultra-continu |
| **Taille équipe** | Grande | Petite/Moyenne | Moyenne/Grande | Moyenne |
| **Durée de vie branches** | Longue | Courte | Courte/Moyenne | Très courte |
| **Courbe d'apprentissage** | Élevée | Faible | Moyenne | Moyenne |
| **Release frequency** | Semaines/Mois | Jours | Variable | Heures |

### Quand utiliser quel workflow ?

```
Choisissez Git Flow si :
✓ Releases planifiées (ex: v1.0, v2.0)
✓ Support de multiples versions
✓ Grande équipe avec processus formels
✓ Logiciel desktop ou mobile

Choisissez GitHub Flow si :
✓ Déploiement continu
✓ Application web moderne
✓ Équipe agile
✓ Main toujours prête pour production

Choisissez GitLab Flow si :
✓ Multiples environnements (dev/staging/prod)
✓ Besoin de validation avant production
✓ Cycles de release variés
✓ Utilisation de GitLab

Choisissez Trunk-Based si :
✓ Déploiements multiples par jour
✓ Équipe mature et disciplinée
✓ Excellente couverture de tests
✓ Culture DevOps forte
```

---

## Pull Requests et Code Review

### Anatomie d'une bonne Pull Request

```markdown
# Title: Add user authentication system

## Description
Implements JWT-based authentication with refresh tokens.

## Changes
- Add login/logout endpoints
- Implement JWT middleware
- Add user session management
- Update security headers

## Testing
- Unit tests: `npm test`
- E2E tests: `npm run test:e2e`
- Manual testing on staging: https://staging.app.com

## Screenshots
[Login page screenshot]
[Dashboard after login]

## Checklist
- [x] Tests added/updated
- [x] Documentation updated
- [x] No breaking changes
- [x] Security review done
```

### Code Review best practices

**Pour les auteurs :**
```bash
# Avant d'ouvrir une PR
1. Tests passent en local
2. Code formaté (linter)
3. Commits bien nommés
4. Description claire
5. Changements limités (< 400 lignes idéalement)
```

**Pour les reviewers :**
```markdown
# Checklist de review
- [ ] Code lisible et maintenable
- [ ] Tests suffisants
- [ ] Pas de code dupliqué
- [ ] Sécurité (injection SQL, XSS, etc.)
- [ ] Performance acceptable
- [ ] Documentation à jour
```

### Automatisation de la review

```yaml
# .github/workflows/pr-checks.yml
name: PR Checks

on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run linter
        run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: npm test

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Security scan
        run: npm audit

  size-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check bundle size
        run: npm run size-check
```

---

## Conventions de nommage

### Branches

```bash
# Features
feature/user-authentication
feature/payment-integration
feat/dark-mode

# Bug fixes
bugfix/login-error
fix/memory-leak

# Hotfixes
hotfix/critical-security-issue
hotfix/production-crash

# Releases
release/v1.2.0
release/2024-q1

# Documentation
docs/api-documentation
docs/readme-update

# Refactoring
refactor/user-service
refactor/database-queries
```

### Commits (Conventional Commits)

```bash
# Format: <type>(<scope>): <subject>

# Features
git commit -m "feat: add user profile page"
git commit -m "feat(auth): implement OAuth2 login"

# Bug fixes
git commit -m "fix: resolve login timeout issue"
git commit -m "fix(api): handle null pointer exception"

# Documentation
git commit -m "docs: update API documentation"
git commit -m "docs(readme): add installation instructions"

# Tests
git commit -m "test: add unit tests for user service"
git commit -m "test(e2e): add login flow test"

# Chores
git commit -m "chore: update dependencies"
git commit -m "chore(deps): bump axios to v1.0.0"

# Refactoring
git commit -m "refactor: simplify authentication logic"

# Performance
git commit -m "perf: optimize database queries"

# Breaking changes
git commit -m "feat!: redesign API endpoints

BREAKING CHANGE: /api/users is now /api/v2/users"
```

---

## Bonnes pratiques

### Commits

**DO :**
- Commits petits et atomiques
- Messages clairs et descriptifs
- Un commit = une tâche logique
- Commiter fréquemment

**DON'T :**
- Gros commits avec multiples changements
- Messages vagues ("fix bug", "update code")
- Commiter du code non testé
- Commiter des secrets (API keys, passwords)

### Branches

**DO :**
```bash
# Synchroniser régulièrement avec main
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# Nettoyer les branches mergées
git branch --merged | grep -v "main" | xargs git branch -d
```

**DON'T :**
```bash
# Garder des branches obsolètes
# Laisser des branches non mergées longtemps
# Oublier de supprimer après merge
```

### Pull Requests

**DO :**
- PRs petites et focalisées (< 400 lignes)
- Description détaillée
- Tests inclus
- Review rapide (< 24h)
- Répondre aux commentaires

**DON'T :**
- PRs massives (> 1000 lignes)
- Description vide
- PR sans tests
- Laisser des PRs ouvertes des semaines
- Ignorer les commentaires de review

### Protection de branches

```yaml
# Exemple de règles GitHub
main:
  protection:
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - continuous-integration
      - security-scan
    enforce_admins: true
    restrictions:
      push: []  # Personne ne peut push directement
```

---

## Exercices pratiques

### Exercice 1 : GitHub Flow

1. Créer une feature branch
2. Faire 3 commits
3. Ouvrir une Pull Request
4. Merger dans main

### Exercice 2 : Git Flow

1. Créer une feature branch depuis develop
2. Merger dans develop
3. Créer une release branch
4. Merger dans main et develop

### Exercice 3 : Code Review

1. Ouvrir une PR sur un projet existant
2. Faire une review de code
3. Proposer des améliorations
4. Approuver et merger

---

## Ressources

- [Git Flow Original](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)
- [GitLab Flow Documentation](https://docs.gitlab.com/ee/topics/gitlab_flow.html)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## Prochaines étapes

Passez à la section suivante : **[03-GitHub-Actions](../03-GitHub-Actions/README.md)**

Vous allez apprendre à implémenter ces workflows avec GitHub Actions !
