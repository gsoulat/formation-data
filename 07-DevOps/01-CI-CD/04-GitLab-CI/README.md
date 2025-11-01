# GitLab CI/CD

## Table des matières

1. [Introduction](#introduction)
2. [Configuration de base](#configuration-de-base)
3. [Syntaxe .gitlab-ci.yml](#syntaxe-gitlab-ciyml)
4. [Pipelines avancés](#pipelines-avancés)
5. [GitLab Runners](#gitlab-runners)
6. [Exemples pratiques](#exemples-pratiques)

---

## Introduction

GitLab CI/CD est intégré nativement à GitLab et offre une solution complète pour l'automatisation des workflows.

### Avantages de GitLab CI/CD

- Intégration native avec GitLab
- Configuration via `.gitlab-ci.yml`
- Runners Docker intégrés
- Artefacts et cache automatiques
- Container Registry intégré
- Auto DevOps (configuration automatique)

---

## Configuration de base

### Structure minimale

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  script:
    - echo "Building the application..."
    - npm install
    - npm run build

test-job:
  stage: test
  script:
    - echo "Running tests..."
    - npm test

deploy-job:
  stage: deploy
  script:
    - echo "Deploying application..."
  only:
    - main
```

---

## Syntaxe .gitlab-ci.yml

### Jobs et stages

```yaml
stages:
  - build
  - test
  - deploy

# Job de build
build:
  stage: build
  image: node:18
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

# Job de test
test:unit:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm run test:unit
  coverage: '/Coverage: \d+\.\d+/'

test:integration:
  stage: test
  image: node:18
  services:
    - postgres:15
  variables:
    POSTGRES_DB: testdb
    POSTGRES_PASSWORD: testpass
  script:
    - npm ci
    - npm run test:integration

# Job de déploiement
deploy:production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://myapp.com
  only:
    - main
  when: manual
```

### Variables et secrets

```yaml
variables:
  NODE_ENV: production
  DATABASE_URL: $DB_URL

job:
  script:
    - echo "Node env: $NODE_ENV"
    - echo "Database: $DATABASE_URL"
  variables:
    CUSTOM_VAR: value
```

### Cache et artifacts

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/

build:
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
```

### Conditions et rules

```yaml
deploy:
  script: ./deploy.sh
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: always
    - if: $CI_COMMIT_BRANCH == "develop"
      when: manual
    - when: never

test:
  script: npm test
  only:
    - branches
  except:
    - main
```

---

## Pipelines avancés

### Pipeline multi-projets

```yaml
# Trigger un autre projet
trigger-downstream:
  stage: deploy
  trigger:
    project: group/downstream-project
    branch: main
    strategy: depend
```

### Templates et extends

```yaml
.deploy_template:
  stage: deploy
  script:
    - ./deploy.sh $ENVIRONMENT
  only:
    - main

deploy:staging:
  extends: .deploy_template
  variables:
    ENVIRONMENT: staging
  environment:
    name: staging

deploy:production:
  extends: .deploy_template
  variables:
    ENVIRONMENT: production
  environment:
    name: production
  when: manual
```

### Includes

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
  - project: 'group/ci-templates'
    file: '/templates/docker.yml'
  - remote: 'https://example.com/ci/template.yml'
  - template: Auto-DevOps.gitlab-ci.yml
```

---

## GitLab Runners

### Types de runners

**Shared Runners** : Partagés entre tous les projets

**Group Runners** : Partagés au niveau du groupe

**Specific Runners** : Dédiés à un projet spécifique

### Installation d'un runner

```bash
# Installation sur Linux
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Enregistrer le runner
sudo gitlab-runner register

# Démarrer le runner
sudo gitlab-runner start
```

### Configuration runner Docker

```toml
# /etc/gitlab-runner/config.toml
[[runners]]
  name = "docker-runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker"
  [runners.docker]
    image = "node:18"
    privileged = false
    volumes = ["/cache"]
```

---

## Exemples pratiques

### Application Node.js complète

Voir : [.gitlab-ci.yml](./.gitlab-ci.yml)

### Docker build et push

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - release

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest

test:
  stage: test
  image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  script:
    - npm test

release:
  stage: release
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
```

---

## Ressources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab CI/CD Examples](https://docs.gitlab.com/ee/ci/examples/)
- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)

---

## Prochaines étapes

Passez à la section suivante : **[05-Jenkins](../05-Jenkins/README.md)**
