# Module 8 : Best Practices et CI/CD

> **Durée : 1h30**
>
> Professionnalisez vos déploiements Terraform avec les meilleures pratiques et l'automatisation

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Structurer des projets Terraform professionnels
- ✅ Appliquer les conventions de nommage Azure/AWS
- ✅ Gérer les secrets de manière sécurisée
- ✅ Utiliser les workspaces Terraform
- ✅ Créer des pipelines CI/CD avec Azure DevOps
- ✅ Créer des pipelines CI/CD avec GitHub Actions
- ✅ Automatiser les tests et validations
- ✅ Déployer un projet complet de A à Z

---

## 📁 Structure de Projet Recommandée

### Projet Simple (Petite Équipe)

```
terraform-project/
├── .gitignore
├── README.md
├── backend.tf              # Configuration backend
├── provider.tf             # Configuration providers
├── versions.tf             # Contraintes de versions
├── main.tf                 # Ressources principales
├── variables.tf            # Variables
├── outputs.tf              # Outputs
├── locals.tf               # Locals (optionnel)
├── terraform.tfvars.example # Exemple de variables
├── dev.tfvars             # Variables dev
├── staging.tfvars         # Variables staging
├── prod.tfvars            # Variables prod (non versionné si sensible)
└── modules/               # Modules custom
    ├── network/
    ├── compute/
    └── database/
```

### Projet d'Entreprise (Grande Équipe)

```
terraform-enterprise/
├── .gitignore
├── README.md
├── docs/
│   ├── architecture.md
│   ├── runbook.md
│   └── troubleshooting.md
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── modules/
│   ├── azure-network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── README.md
│   │   └── examples/
│   ├── azure-aks/
│   └── azure-database/
├── scripts/
│   ├── init.sh
│   ├── validate.sh
│   └── deploy.sh
├── tests/
│   ├── integration/
│   └── unit/
└── pipelines/
    ├── azure-pipelines.yml
    └── github-actions.yml
```

---

## 🏷️ Conventions de Nommage

### Nommage Azure

```hcl
# Format recommandé : <type>-<app>-<environnement>-<région>-<instance>

# Resource Groups
"rg-myapp-prod-we-001"         # Resource Group
"rg-networking-shared-we-001"  # RG partagé

# Virtual Networks
"vnet-myapp-prod-we-001"       # Virtual Network
"snet-web-prod-we-001"         # Subnet Web
"snet-app-prod-we-001"         # Subnet App
"snet-db-prod-we-001"          # Subnet Database

# Virtual Machines
"vm-web-prod-we-001"           # VM Web
"vm-app-prod-we-002"           # VM App (instance 2)

# Storage
"stmyappprodwe001"             # Storage Account (no dashes, lowercase)

# Databases
"sql-myapp-prod-we-001"        # SQL Server
"sqldb-myapp-prod-001"         # SQL Database
"psql-myapp-prod-we-001"       # PostgreSQL

# AKS
"aks-myapp-prod-we-001"        # AKS Cluster

# Load Balancers
"lb-myapp-prod-we-001"         # Load Balancer
"pip-lb-myapp-prod-we-001"     # Public IP

# Security
"nsg-web-prod-we-001"          # Network Security Group
"kv-myapp-prod-we-001"         # Key Vault

# Monitoring
"log-myapp-prod-we-001"        # Log Analytics Workspace
"appi-myapp-prod-we-001"       # Application Insights
```

**Abréviations communes :**
```
rg   = Resource Group       vm   = Virtual Machine
vnet = Virtual Network      nic  = Network Interface
snet = Subnet               pip  = Public IP
nsg  = Network Security Group    lb   = Load Balancer
st   = Storage Account      kv   = Key Vault
sql  = SQL Server           sqldb= SQL Database
psql = PostgreSQL           aks  = Azure Kubernetes Service
log  = Log Analytics        appi = Application Insights
```

### Nommage AWS

```hcl
# Format : <env>-<app>-<type>-<description>

# VPC et Réseau
"prod-myapp-vpc"               # VPC
"prod-myapp-subnet-public-1a"  # Subnet Public AZ 1a
"prod-myapp-subnet-private-1a" # Subnet Private AZ 1a
"prod-myapp-igw"               # Internet Gateway
"prod-myapp-nat-1a"            # NAT Gateway

# EC2
"prod-myapp-web-001"           # Instance Web
"prod-myapp-app-002"           # Instance App

# ELB
"prod-myapp-alb"               # Application Load Balancer
"prod-myapp-nlb"               # Network Load Balancer

# RDS
"prod-myapp-rds-postgres"      # RDS PostgreSQL

# S3
"prod-myapp-data-bucket"       # S3 Bucket

# EKS
"prod-myapp-eks"               # EKS Cluster

# Security
"prod-myapp-sg-web"            # Security Group Web
"prod-myapp-sg-app"            # Security Group App
```

### Variables Terraform

```hcl
# Utilisez snake_case pour les variables
variable "resource_group_name" {}   # ✅ BON
variable "resourceGroupName" {}     # ❌ MAUVAIS
variable "ResourceGroupName" {}     # ❌ MAUVAIS

# Utilisez des noms descriptifs
variable "rg_name" {}               # ❌ Trop court
variable "resource_group_name" {}   # ✅ Clair

# Ressources : utilisez des noms courts mais clairs
resource "azurerm_resource_group" "main" {}    # ✅ BON
resource "azurerm_resource_group" "rg1" {}     # ❌ Pas clair
resource "azurerm_resource_group" "my_very_long_resource_group_name" {}  # ❌ Trop long
```

---

## 🏗️ Best Practices de Code

### 1. Séparer les Fichiers par Responsabilité

```hcl
# backend.tf - Configuration backend
terraform {
  backend "azurerm" {
    # ...
  }
}

# versions.tf - Contraintes de versions
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# provider.tf - Configuration providers
provider "azurerm" {
  features {}
}

# locals.tf - Variables calculées
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# main.tf - Ressources principales
resource "azurerm_resource_group" "main" {
  # ...
}
```

### 2. Utiliser `locals` pour les Valeurs Calculées

```hcl
locals {
  # Nom du Resource Group construit
  resource_group_name = "${var.project}-${var.environment}-rg"

  # Tags communs
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Timestamp   = timestamp()
    }
  )

  # Liste de subnets calculée
  subnet_cidrs = [
    for i in range(var.subnet_count) :
    cidrsubnet(var.vnet_cidr, 8, i)
  ]
}

# Utilisation
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

### 3. Commenter le Code

```hcl
#
# NETWORKING RESOURCES
#
# Ce bloc crée l'infrastructure réseau complète :
# - Virtual Network avec CIDR 10.0.0.0/16
# - 3 Subnets (web, app, db)
# - Network Security Groups
#

# Virtual Network principal
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Note : DNS servers configurés automatiquement par Azure
  tags = local.common_tags
}

# Subnet Web - Accessible depuis Internet via Load Balancer
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  # Service Endpoints pour Storage et Key Vault
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}
```

### 4. Validation des Variables

```hcl
variable "environment" {
  type        = string
  description = "Environnement de déploiement"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "vm_size" {
  type        = string
  description = "Taille de la VM"

  validation {
    condition = can(regex("^(Standard_B|Standard_D)", var.vm_size))
    error_message = "vm_size doit commencer par Standard_B ou Standard_D."
  }
}

variable "location" {
  type        = string
  description = "Région Azure"

  validation {
    condition = contains([
      "West Europe",
      "North Europe",
      "France Central"
    ], var.location)
    error_message = "location doit être une région européenne supportée."
  }
}
```

### 5. Utiliser `terraform fmt` et `terraform validate`

```bash
# Formater automatiquement le code
terraform fmt -recursive

# Valider la syntaxe
terraform validate

# Ajouter au pre-commit hook (voir CI/CD plus bas)
```

---

## 🔐 Gestion des Secrets

### ❌ NE JAMAIS FAIRE

```hcl
# ❌ JAMAIS de secrets en dur dans le code
resource "azurerm_postgresql_flexible_server" "main" {
  administrator_login    = "admin"
  administrator_password = "SuperSecretPassword123!"  # ❌ DANGEREUX !
}

# ❌ JAMAIS versionner les secrets
# terraform.tfvars
db_password = "SuperSecret123!"  # ❌ Ne pas commit ce fichier !
```

### ✅ Solutions Recommandées

#### Option 1 : Variables d'Environnement

```bash
# .env (NON versionné)
export TF_VAR_db_password="SuperSecret123!"
export TF_VAR_admin_password="AnotherSecret456!"
```

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

resource "azurerm_postgresql_flexible_server" "main" {
  administrator_password = var.db_password
}
```

#### Option 2 : Azure Key Vault (Recommandé)

```hcl
# Récupérer un secret depuis Key Vault
data "azurerm_key_vault" "main" {
  name                = "kv-myapp-prod"
  resource_group_name = "rg-shared-prod"
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "db-admin-password"
  key_vault_id = data.azurerm_key_vault.main.id
}

# Utiliser le secret
resource "azurerm_postgresql_flexible_server" "main" {
  administrator_password = data.azurerm_key_vault_secret.db_password.value
}
```

#### Option 3 : AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/myapp/db-password"
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

#### Option 4 : Terraform Cloud Variables

Dans Terraform Cloud :
1. Workspace Settings → Variables
2. Créer une variable `db_password`
3. Cocher "Sensitive"

---

## 🔄 Workspaces Terraform

Les workspaces permettent de gérer plusieurs environnements avec le même code.

### Créer et Utiliser des Workspaces

```bash
# Créer un workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Lister les workspaces
terraform workspace list
# Sortie:
# default
# * dev
#   staging
#   prod

# Changer de workspace
terraform workspace select prod

# Voir le workspace actuel
terraform workspace show
```

### Utiliser le Workspace dans le Code

```hcl
locals {
  # Nom du Resource Group basé sur le workspace
  resource_group_name = "rg-myapp-${terraform.workspace}"

  # Taille de VM selon l'environnement
  vm_size = {
    dev     = "Standard_B2s"
    staging = "Standard_B4ms"
    prod    = "Standard_D4s_v3"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "vm-${terraform.workspace}"
  size = local.vm_size[terraform.workspace]
  # ...
}
```

### Backend avec Workspaces

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate123"
    container_name       = "tfstate"
    key                  = "myapp.terraform.tfstate"
    # Chaque workspace aura son propre state :
    # - env:/dev/myapp.terraform.tfstate
    # - env:/staging/myapp.terraform.tfstate
    # - env:/prod/myapp.terraform.tfstate
  }
}
```

---

## 🚀 CI/CD avec Azure DevOps

### Pipeline Complète

**`azure-pipelines.yml`**

```yaml
# Trigger sur main et develop
trigger:
  branches:
    include:
      - main
      - develop

# Variables globales
variables:
  terraformVersion: '1.6.6'
  azureSubscription: 'Azure-Service-Connection'
  backendResourceGroup: 'rg-terraform-state'
  backendStorageAccount: 'sttfstate123'
  backendContainer: 'tfstate'

# Stages : Validate, Plan, Apply
stages:
  #
  # STAGE 1 : VALIDATION
  #
  - stage: Validate
    displayName: 'Terraform Validate'
    jobs:
      - job: ValidateJob
        displayName: 'Validate Terraform Configuration'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          # Installer Terraform
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(terraformVersion)

          # Terraform fmt check
          - script: |
              terraform fmt -check -recursive
            displayName: 'Terraform Format Check'
            workingDirectory: '$(System.DefaultWorkingDirectory)'

          # Terraform init
          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: $(azureSubscription)
              backendAzureRmResourceGroupName: $(backendResourceGroup)
              backendAzureRmStorageAccountName: $(backendStorageAccount)
              backendAzureRmContainerName: $(backendContainer)
              backendAzureRmKey: 'prod.terraform.tfstate'

          # Terraform validate
          - script: |
              terraform validate
            displayName: 'Terraform Validate'
            workingDirectory: '$(System.DefaultWorkingDirectory)'

          # Security scan avec tfsec
          - script: |
              wget https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64
              chmod +x tfsec-linux-amd64
              ./tfsec-linux-amd64 . --format junit > tfsec-results.xml
            displayName: 'Security Scan with tfsec'
            continueOnError: true

          # Publier les résultats
          - task: PublishTestResults@2
            displayName: 'Publish tfsec Results'
            condition: always()
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '**/tfsec-results.xml'

  #
  # STAGE 2 : PLAN (DEV)
  #
  - stage: PlanDev
    displayName: 'Plan - Dev'
    dependsOn: Validate
    condition: succeeded()
    jobs:
      - job: PlanDevJob
        displayName: 'Terraform Plan Dev'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(terraformVersion)

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: $(azureSubscription)
              backendAzureRmResourceGroupName: $(backendResourceGroup)
              backendAzureRmStorageAccountName: $(backendStorageAccount)
              backendAzureRmContainerName: $(backendContainer)
              backendAzureRmKey: 'dev.terraform.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: $(azureSubscription)
              commandOptions: '-var-file="dev.tfvars" -out=tfplan'

          # Sauvegarder le plan
          - task: PublishPipelineArtifact@1
            displayName: 'Publish Plan'
            inputs:
              targetPath: '$(System.DefaultWorkingDirectory)/tfplan'
              artifact: 'tfplan-dev'

  #
  # STAGE 3 : APPLY (DEV)
  #
  - stage: ApplyDev
    displayName: 'Apply - Dev'
    dependsOn: PlanDev
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - deployment: ApplyDevDeployment
        displayName: 'Terraform Apply Dev'
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@0
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(terraformVersion)

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    backendServiceArm: $(azureSubscription)
                    backendAzureRmResourceGroupName: $(backendResourceGroup)
                    backendAzureRmStorageAccountName: $(backendStorageAccount)
                    backendAzureRmContainerName: $(backendContainer)
                    backendAzureRmKey: 'dev.terraform.tfstate'

                # Télécharger le plan
                - task: DownloadPipelineArtifact@2
                  displayName: 'Download Plan'
                  inputs:
                    artifact: 'tfplan-dev'
                    path: '$(System.DefaultWorkingDirectory)'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceNameAzureRM: $(azureSubscription)
                    commandOptions: 'tfplan'

  #
  # STAGE 4 : PLAN (PROD)
  #
  - stage: PlanProd
    displayName: 'Plan - Production'
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: PlanProdJob
        displayName: 'Terraform Plan Production'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(terraformVersion)

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: $(azureSubscription)
              backendAzureRmResourceGroupName: $(backendResourceGroup)
              backendAzureRmStorageAccountName: $(backendStorageAccount)
              backendAzureRmContainerName: $(backendContainer)
              backendAzureRmKey: 'prod.terraform.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: $(azureSubscription)
              commandOptions: '-var-file="prod.tfvars" -out=tfplan'

          - task: PublishPipelineArtifact@1
            displayName: 'Publish Plan'
            inputs:
              targetPath: '$(System.DefaultWorkingDirectory)/tfplan'
              artifact: 'tfplan-prod'

  #
  # STAGE 5 : APPLY (PROD) avec Approbation Manuelle
  #
  - stage: ApplyProd
    displayName: 'Apply - Production'
    dependsOn: PlanProd
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: ApplyProdDeployment
        displayName: 'Terraform Apply Production'
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'production'  # Nécessite une approbation manuelle
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@0
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(terraformVersion)

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    backendServiceArm: $(azureSubscription)
                    backendAzureRmResourceGroupName: $(backendResourceGroup)
                    backendAzureRmStorageAccountName: $(backendStorageAccount)
                    backendAzureRmContainerName: $(backendContainer)
                    backendAzureRmKey: 'prod.terraform.tfstate'

                - task: DownloadPipelineArtifact@2
                  displayName: 'Download Plan'
                  inputs:
                    artifact: 'tfplan-prod'
                    path: '$(System.DefaultWorkingDirectory)'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceNameAzureRM: $(azureSubscription)
                    commandOptions: 'tfplan'
```

---

## 🐙 CI/CD avec GitHub Actions

**`.github/workflows/terraform.yml`**

```yaml
name: 'Terraform CI/CD'

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  TF_VERSION: '1.6.6'
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}

jobs:
  #
  # JOB 1 : VALIDATION
  #
  terraform-validate:
    name: 'Terraform Validate'
    runs-on: ubuntu-latest

    steps:
      # Checkout du code
      - name: Checkout
        uses: actions/checkout@v4

      # Installer Terraform
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      # Format check
      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      # Init
      - name: Terraform Init
        run: terraform init

      # Validate
      - name: Terraform Validate
        run: terraform validate

      # Security scan avec tfsec
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          soft_fail: true

  #
  # JOB 2 : PLAN
  #
  terraform-plan:
    name: 'Terraform Plan'
    needs: terraform-validate
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, prod]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file="${{ matrix.environment }}.tfvars" \
            -out=tfplan-${{ matrix.environment }} \
            -no-color
        continue-on-error: true

      # Sauvegarder le plan
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan-${{ matrix.environment }}
          path: tfplan-${{ matrix.environment }}

      # Commenter la PR avec le résultat du plan
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan (${{ matrix.environment }}): \`${{ steps.plan.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`

            </details>

            *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  #
  # JOB 3 : APPLY (DEV - Auto)
  #
  terraform-apply-dev:
    name: 'Terraform Apply Dev'
    needs: terraform-plan
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: development

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: tfplan-dev

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan-dev

  #
  # JOB 4 : APPLY (PROD - Manuel avec Approbation)
  #
  terraform-apply-prod:
    name: 'Terraform Apply Production'
    needs: terraform-plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.example.com

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: tfplan-prod

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan-prod

      # Notification Slack
      - name: Slack Notification
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment completed!'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🧪 Tests Automatisés

### Pre-commit Hooks

**`.pre-commit-config.yaml`**

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
```

**Installation :**

```bash
# Installer pre-commit
pip install pre-commit

# Installer les hooks
pre-commit install

# Tester manuellement
pre-commit run --all-files
```

### Tests avec Terratest (Go)

**`tests/network_test.go`**

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestNetworkModule(t *testing.T) {
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/azure-network",
        Vars: map[string]interface{}{
            "resource_group_name": "rg-test",
            "location":            "West Europe",
            "vnet_name":           "vnet-test",
        },
    })

    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    vnetID := terraform.Output(t, terraformOptions, "vnet_id")
    assert.Contains(t, vnetID, "vnet-test")
}
```

**Exécution :**

```bash
cd tests
go test -v -timeout 30m
```

---

## 📝 Points Clés à Retenir

1. **Structure** : Organiser clairement les fichiers et dossiers
2. **Nommage** : Suivre les conventions Azure/AWS
3. **Secrets** : Ne JAMAIS les versionner, utiliser Key Vault/Secrets Manager
4. **Workspaces** : Pour gérer plusieurs environnements
5. **CI/CD** : Automatiser validate → plan → apply
6. **Tests** : Pre-commit hooks + tests automatisés
7. **Approbations** : Approbation manuelle requise pour la production

---

## ✅ Quiz Final

1. Quelle est la structure de projet recommandée pour une grande équipe ?
2. Comment gérer les secrets de manière sécurisée ?
3. À quoi servent les workspaces Terraform ?
4. Quelles sont les étapes d'un pipeline CI/CD Terraform ?
5. Pourquoi utiliser des pre-commit hooks ?

---

## 🎓 Félicitations !

Vous avez terminé la formation Terraform ! Vous êtes maintenant capable de :

- ✅ Maîtriser les concepts de l'Infrastructure as Code
- ✅ Créer des infrastructures complètes sur Azure et AWS
- ✅ Utiliser des variables, outputs et modules
- ✅ Gérer le state de manière professionnelle
- ✅ Créer des modules réutilisables
- ✅ Automatiser les déploiements avec CI/CD
- ✅ Appliquer les best practices de l'industrie

### Prochaines Étapes

1. **Pratiquer** : Créez vos propres projets Terraform
2. **Contribuer** : Publiez des modules sur le Terraform Registry
3. **Certifications** : HashiCorp Certified: Terraform Associate
4. **Communauté** : Rejoignez r/Terraform, HashiCorp forums
5. **Veille** : Suivez les releases Terraform et providers

---

## 📚 Ressources Complémentaires

### Documentation
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [AWS Naming Conventions](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)

### Outils
- [tfsec](https://github.com/aquasecurity/tfsec) - Security scanner
- [terraform-docs](https://github.com/terraform-docs/terraform-docs) - Generate docs
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform) - Pre-commit hooks
- [terratest](https://terratest.gruntwork.io/) - Testing framework

### Certifications
- [HashiCorp Certified: Terraform Associate](https://www.hashicorp.com/certification/terraform-associate)

---

[⬅️ Module précédent](07-modules.md) | [🏠 Retour à l'accueil](../README.md)

---

**Merci d'avoir suivi cette formation ! 🚀**

_Formation Data Engineering - Simplon - 2025_
