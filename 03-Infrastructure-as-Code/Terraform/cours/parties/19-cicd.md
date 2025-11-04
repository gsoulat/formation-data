# 19 - CI/CD avec Terraform

## 📖 Introduction

L'intégration et le déploiement continus (CI/CD) permettent d'automatiser les déploiements Terraform, garantissant cohérence, traçabilité et réduction des erreurs humaines.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Mettre en place un pipeline CI/CD pour Terraform
- ✅ Automatiser les tests et validations
- ✅ Gérer les déploiements multi-environnements
- ✅ Implémenter des approbations manuelles
- ✅ Sécuriser les credentials dans CI/CD

## 🔄 Pipeline CI/CD type

```
┌─────────────┐     ┌──────────┐     ┌─────────┐     ┌────────┐
│   Git Push  │ --> │ Validate │ --> │  Plan   │ --> │ Apply  │
│   (main)    │     │  & Test  │     │ (auto)  │     │(manual)│
└─────────────┘     └──────────┘     └─────────┘     └────────┘
                         │                │               │
                         ↓                ↓               ↓
                    fmt, validate    terraform plan   terraform apply
                    tflint, checkov   + review         (if approved)
```

## 🎯 GitHub Actions

### Workflow complet

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
  TF_VERSION: '1.9.0'

jobs:
  # ===========================
  # JOB 1: VALIDATION & TESTS
  # ===========================
  validate:
    name: Validate & Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate

      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v3

      - name: TFLint
        run: |
          tflint --init
          tflint -f compact

      - name: Checkov Security Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform
          soft_fail: false

  # ===========================
  # JOB 2: TERRAFORM PLAN
  # ===========================
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: validate
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan
          terraform show -no-color tfplan > plan.txt

      - name: Comment Plan on PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            const output = `#### Terraform Plan 📋
            \`\`\`
            ${plan}
            \`\`\`
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: tfplan

  # ===========================
  # JOB 3: TERRAFORM APPLY
  # ===========================
  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: validate
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve

      - name: Comment on Commit
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.repos.createCommitComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              commit_sha: context.sha,
              body: '✅ Terraform apply successful!'
            });
```

### Configuration des secrets

```bash
# Dans GitHub : Settings > Secrets and variables > Actions

ARM_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARM_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxx
ARM_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARM_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Approbation manuelle

```yaml
# Ajouter un environnement avec protection
# Settings > Environments > New environment : "production"
# ✅ Required reviewers : Ajouter les approbateurs

apply:
  environment:
    name: production  # ← Nécessite une approbation manuelle
```

## 🔵 Azure DevOps

### Pipeline YAML

```yaml
# azure-pipelines.yml
trigger:
  - main

variables:
  - group: terraform-azure-credentials  # Variable group avec credentials
  - name: terraformVersion
    value: '1.9.0'

stages:
  # ===========================
  # STAGE 1: VALIDATION
  # ===========================
  - stage: Validate
    displayName: 'Validate & Test'
    jobs:
      - job: Validate
        displayName: 'Terraform Validation'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: $(terraformVersion)

          - script: terraform fmt -check -recursive
            displayName: 'Format Check'

          - script: |
              terraform init -backend=false
              terraform validate
            displayName: 'Terraform Validate'

          - script: |
              curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
              tflint --init
              tflint
            displayName: 'TFLint'

  # ===========================
  # STAGE 2: PLAN
  # ===========================
  - stage: Plan
    displayName: 'Terraform Plan'
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))
    jobs:
      - job: Plan
        displayName: 'Terraform Plan'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: $(terraformVersion)

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: 'Azure-Service-Connection'
              backendAzureRmResourceGroupName: 'rg-terraform-state'
              backendAzureRmStorageAccountName: 'sttfstate'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'terraform.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: 'Azure-Service-Connection'
              commandOptions: '-out=tfplan'

  # ===========================
  # STAGE 3: APPLY
  # ===========================
  - stage: Apply
    displayName: 'Terraform Apply'
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: Apply
        displayName: 'Terraform Apply'
        environment: 'production'  # Nécessite approbation
        pool:
          vmImage: 'ubuntu-latest'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@1
                  inputs:
                    terraformVersion: $(terraformVersion)

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    backendServiceArm: 'Azure-Service-Connection'
                    backendAzureRmResourceGroupName: 'rg-terraform-state'
                    backendAzureRmStorageAccountName: 'sttfstate'
                    backendAzureRmContainerName: 'tfstate'
                    backendAzureRmKey: 'terraform.tfstate'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceNameAzureRM: 'Azure-Service-Connection'
                    commandOptions: '-auto-approve'
```

## 🚀 GitLab CI/CD

```yaml
# .gitlab-ci.yml
variables:
  TF_VERSION: '1.9.0'
  TF_ROOT: ${CI_PROJECT_DIR}

image:
  name: hashicorp/terraform:${TF_VERSION}
  entrypoint: ['']

stages:
  - validate
  - plan
  - apply

before_script:
  - cd ${TF_ROOT}
  - export ARM_CLIENT_ID=${ARM_CLIENT_ID}
  - export ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET}
  - export ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}
  - export ARM_TENANT_ID=${ARM_TENANT_ID}

validate:
  stage: validate
  script:
    - terraform fmt -check -recursive
    - terraform init -backend=false
    - terraform validate

plan:
  stage: plan
  script:
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan
  only:
    - merge_requests

apply:
  stage: apply
  script:
    - terraform init
    - terraform apply -auto-approve
  when: manual
  only:
    - main
```

## 🔐 Sécurité CI/CD

### 1. Utiliser des Service Principals

```bash
# Créer un SP dédié pour CI/CD
az ad sp create-for-rbac \
  --name "terraform-cicd-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/${SUBSCRIPTION_ID}"
```

### 2. Limiter les permissions

```bash
# Créer un rôle custom avec permissions minimales
az role definition create --role-definition '{
  "Name": "Terraform CI/CD",
  "Description": "Minimum permissions for Terraform CI/CD",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Storage/storageAccounts/*",
    "Microsoft.Network/virtualNetworks/*"
  ],
  "AssignableScopes": ["/subscriptions/'${SUBSCRIPTION_ID}'"]
}'
```

### 3. Secrets management

```yaml
# ✅ Bon : Utiliser les secrets du CI/CD
env:
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}

# ❌ Mauvais : Secrets en clair
env:
  ARM_CLIENT_SECRET: "mon-secret"  # Ne JAMAIS faire ça !
```

### 4. État distant sécurisé

```hcl
# Utiliser un backend avec chiffrement
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatesecure"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    # Chiffrement activé automatiquement
  }
}
```

## 📋 Bonnes pratiques CI/CD

### 1. Séparer les environnements

```yaml
# GitHub Actions
jobs:
  deploy-dev:
    environment: development
  deploy-staging:
    environment: staging
  deploy-prod:
    environment: production  # Avec approbation
```

### 2. Utiliser des plans sauvegardés

```bash
# Plan
terraform plan -out=tfplan

# Apply du plan exact (pas de surprises)
terraform apply tfplan
```

### 3. Notifications

```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "❌ Terraform apply failed for ${{ github.repository }}"
      }
```

### 4. Gestion des erreurs

```yaml
- name: Terraform Apply
  id: apply
  run: terraform apply -auto-approve
  continue-on-error: true

- name: Rollback on Failure
  if: steps.apply.outcome == 'failure'
  run: |
    echo "Apply failed, investigating..."
    terraform state list
```

## 📊 Métriques et monitoring

### Terraform Cloud

[Terraform Cloud](https://app.terraform.io/) offre :
- 🔐 État distant sécurisé
- 👥 Collaboration d'équipe
- 🔄 Runs automatiques
- 📊 Historique des déploiements
- 💬 Intégration Slack/GitHub

### Atlantis

[Atlantis](https://www.runatlantis.io/) est un outil self-hosted pour :
- 🤖 Plans automatiques sur PR
- 💬 Commentaires sur les PR
- 🔒 Verrouillage des déploiements
- 📋 Workflow GitOps

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Créer des pipelines CI/CD (GitHub Actions, Azure DevOps, GitLab)
- ✅ Automatiser validation, plan et apply
- ✅ Implémenter des approbations manuelles
- ✅ Sécuriser les credentials
- ✅ Gérer les environnements multiples
- ✅ Notifications et rollbacks

## ➡️ Prochaine étape

Vous avez maintenant toutes les compétences nécessaires ! Il est temps de mettre tout ça en pratique avec le **projet final** !

**Prochain module** : [20 - Projet guidé : Infrastructure complète](./20-projet-final.md)

---

🚀 Parfait ! Vos déploiements sont automatisés. Place au projet final !
