# 20 - Projet guidé : Infrastructure complète

## 📖 Introduction

Félicitations ! Vous êtes arrivé au projet final. Vous allez créer une infrastructure complète Azure en utilisant toutes les compétences acquises durant cette formation.

## 🎯 Objectifs du projet

À la fin de ce projet, vous aurez :

- ✅ Déployé une infrastructure multi-tier complète
- ✅ Utilisé modules, variables, outputs
- ✅ Implémenté un backend distant
- ✅ Géré plusieurs environnements
- ✅ Appliqué les bonnes pratiques de sécurité
- ✅ Mis en place CI/CD

## 🏗️ Architecture cible

```
┌─────────────────────────────────────────────────────┐
│                  Azure Subscription                  │
│                                                       │
│  ┌────────────────────────────────────────────────┐ │
│  │         Resource Group (par environnement)      │ │
│  │                                                  │ │
│  │  ┌──────────────────┐    ┌─────────────────┐  │ │
│  │  │  Virtual Network  │    │  Storage Account │  │ │
│  │  │  - Subnet Web     │    │  - Logs          │  │ │
│  │  │  - Subnet App     │    │  - Data          │  │ │
│  │  │  - Subnet Data    │    │  - Backups       │  │ │
│  │  └──────────────────┘    └─────────────────┘  │ │
│  │                                                  │ │
│  │  ┌──────────────────┐    ┌─────────────────┐  │ │
│  │  │   Virtual Machine │    │   SQL Database  │  │ │
│  │  │   - Web Server    │    │   - Production  │  │ │
│  │  └──────────────────┘    └─────────────────┘  │ │
│  │                                                  │ │
│  │  ┌──────────────────┐    ┌─────────────────┐  │ │
│  │  │    Key Vault     │    │ Load Balancer   │  │ │
│  │  │    - Secrets     │    │ - Public IP     │  │ │
│  │  └──────────────────┘    └─────────────────┘  │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## 📁 Structure du projet

```
projet-final/
├── README.md
├── .gitignore
├── versions.tf
├── providers.tf
├── backend.tf
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
│
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
└── .github/
    └── workflows/
        └── terraform.yml
```

## 🚀 Étape 1 : Configuration de base

### versions.tf

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

### providers.tf

```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}

provider "random" {}
```

### backend.tf

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate${var.suffix}"
    container_name       = "tfstate"
    key                  = "${var.environment}.terraform.tfstate"
  }
}
```

### variables.tf

```hcl
# ==============================================================================
# GENERAL
# ==============================================================================
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

# ==============================================================================
# NETWORK
# ==============================================================================
variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
    }
    data = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

# ==============================================================================
# COMPUTE
# ==============================================================================
variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "vm_count" {
  description = "Number of VMs"
  type        = number
}

# ==============================================================================
# DATABASE
# ==============================================================================
variable "sql_admin_username" {
  description = "SQL admin username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

# ==============================================================================
# TAGS
# ==============================================================================
variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

### locals.tf

```hcl
locals {
  # Nom de ressources
  resource_prefix = "${var.project}-${var.environment}"

  # Tags communs
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.additional_tags
  )

  # Configuration par environnement
  env_config = {
    dev = {
      vm_size       = "Standard_B2s"
      vm_count      = 1
      sql_sku       = "Basic"
      enable_backup = false
    }
    staging = {
      vm_size       = "Standard_D2s_v3"
      vm_count      = 2
      sql_sku       = "S1"
      enable_backup = true
    }
    prod = {
      vm_size       = "Standard_D4s_v3"
      vm_count      = 3
      sql_sku       = "S3"
      enable_backup = true
    }
  }

  config = local.env_config[var.environment]
}
```

## 🔧 Étape 2 : Module Network

### modules/network/variables.tf

```hcl
variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}
```

### modules/network/main.tf

```hcl
# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space

  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = "subnet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}

# Network Security Groups
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.subnets

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG - Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}
```

### modules/network/outputs.tf

```hcl
output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}
```

## 📦 Étape 3 : Module Storage

### modules/storage/main.tf

```hcl
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  for_each = var.storage_accounts

  name                      = "${each.key}${random_string.suffix.result}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = each.value.tier
  account_replication_type  = each.value.replication
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = false

  tags = var.tags
}
```

## 🎓 Étape 4 : Main.tf (assemblage)

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location

  tags = local.common_tags
}

# Network Module
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "vnet-${local.resource_prefix}"
  address_space       = var.vnet_address_space
  subnets             = var.subnets

  tags = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_accounts = {
    stlogs   = { tier = "Standard", replication = "LRS" }
    stdata   = { tier = "Standard", replication = "GRS" }
    stbackup = { tier = "Standard", replication = "LRS" }
  }

  tags = local.common_tags
}
```

## 🔐 Étape 5 : Sécurité avec Key Vault

```hcl
# Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true

  tags = local.common_tags
}

# Stocker le mot de passe SQL
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.main.id
}
```

## ⚙️ Étape 6 : Fichiers tfvars

### environments/dev.tfvars

```hcl
subscription_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
environment       = "dev"
location          = "West Europe"
vm_size           = "Standard_B2s"
vm_count          = 1
sql_admin_password = "DevP@ssw0rd123!"  # À remplacer par Key Vault en prod

additional_tags = {
  cost_center = "development"
  owner       = "dev-team"
}
```

### environments/prod.tfvars

```hcl
subscription_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
environment       = "prod"
location          = "North Europe"
vm_size           = "Standard_D4s_v3"
vm_count          = 3
sql_admin_password = "ProdP@ssw0rd123!"  # Utiliser Key Vault !

additional_tags = {
  cost_center = "production"
  owner       = "ops-team"
  criticality = "high"
}
```

## 🚀 Étape 7 : Déploiement

```bash
# 1. Initialiser
terraform init

# 2. Développement
terraform workspace new dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# 3. Staging
terraform workspace new staging
terraform apply -var-file="environments/staging.tfvars"

# 4. Production
terraform workspace new prod
terraform plan -var-file="environments/prod.tfvars" -out=tfplan
# ⚠️ Review attentif du plan
terraform apply tfplan
```

## 📊 Étape 8 : Tests

```bash
# Valider
terraform validate

# Formater
terraform fmt -recursive

# TFLint
tflint --init
tflint

# Checkov
checkov -d .

# Smoke tests
./scripts/smoke-tests.sh
```

## 🎯 Challenges bonus

### Challenge 1 : Monitoring
Ajoutez Log Analytics et Application Insights

### Challenge 2 : High Availability
Configurez un Load Balancer et des Availability Zones

### Challenge 3 : Disaster Recovery
Implémentez une stratégie de backup automatique

### Challenge 4 : Infrastructure as Code complète
Créez un module Terraform réutilisable et publiez-le

## 📝 Checklist finale

- [ ] Architecture multi-tier déployée
- [ ] Backend distant configuré
- [ ] 3 environnements (dev, staging, prod)
- [ ] Modules réutilisables créés
- [ ] Secrets sécurisés (Key Vault)
- [ ] Tags cohérents sur toutes les ressources
- [ ] Réseau sécurisé (NSG, Private Endpoints)
- [ ] Documentation complète (README)
- [ ] CI/CD configuré
- [ ] Tests passants

## 🎓 Félicitations ! 🎉

Vous avez terminé la formation Terraform avec Azure !

Vous maîtrisez maintenant :
- ✅ Infrastructure as Code
- ✅ Terraform de A à Z
- ✅ Architecture cloud Azure
- ✅ Bonnes pratiques DevOps
- ✅ CI/CD et automatisation

### Prochaines étapes

1. **Certification HashiCorp Terraform Associate**
   - https://www.hashicorp.com/certification/terraform-associate

2. **Certification Azure** (AZ-104, AZ-400)
   - https://learn.microsoft.com/certifications/

3. **Contribuer à l'open source**
   - Créez et partagez vos modules Terraform

4. **Continuer à apprendre**
   - Kubernetes + Terraform
   - Multi-cloud (AWS, GCP)
   - GitOps avec ArgoCD/Flux

---

🎉 **Bravo pour avoir terminé cette formation ! Vous êtes maintenant un expert Terraform !** 🚀
