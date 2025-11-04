# 16 - Organisation du code

## 📖 Introduction

Une bonne organisation du code Terraform est essentielle pour la maintenabilité, la lisibilité et la collaboration en équipe.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Organiser les fichiers Terraform efficacement
- ✅ Structurer un projet multi-environnements
- ✅ Utiliser une convention de nommage cohérente
- ✅ Organiser le code par couches (réseau, compute, data)

## 📁 Structure basique

### Projet simple

```
projet/
├── main.tf           # Ressources principales
├── variables.tf      # Toutes les variables
├── outputs.tf        # Tous les outputs
├── providers.tf      # Configuration providers
├── versions.tf       # Contraintes de versions
├── locals.tf         # Variables locales (optionnel)
├── backend.tf        # Configuration backend
├── terraform.tfvars  # Valeurs (ne pas commiter)
├── *.tfvars.example  # Templates de variables
├── .gitignore        # Fichiers à ignorer
└── README.md         # Documentation
```

### Contenu type

#### providers.tf

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "random" {}
```

#### versions.tf

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

#### main.tf

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                = "st${var.project}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ...
}
```

## 🏗️ Structure par couches (grandes infrastructures)

### Organisation recommandée

```
projet/
├── main.tf
├── providers.tf
├── versions.tf
├── backend.tf
├── variables.tf
├── outputs.tf
├── locals.tf
│
├── network.tf        # VNet, Subnets, NSG, etc.
├── compute.tf        # VMs, Scale Sets, etc.
├── storage.tf        # Storage Accounts, File Shares
├── database.tf       # SQL, CosmosDB, etc.
├── security.tf       # Key Vault, Identities, Roles
├── monitoring.tf     # Log Analytics, Application Insights
│
├── dev.tfvars
├── staging.tfvars
├── prod.tfvars
│
└── README.md
```

### Exemple : network.tf

```hcl
# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.vnet_address_space

  tags = local.common_tags
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_web_prefixes
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_app_prefixes
}

# Network Security Groups
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}
```

## 🎯 Structure multi-environnements

### Option 1 : Workspaces (simple)

```
projet/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
└── backend.tf

# Déploiement
terraform workspace select dev
terraform apply

terraform workspace select prod
terraform apply
```

### Option 2 : Dossiers séparés (isolation)

```
projet/
├── modules/
│   └── infrastructure/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── terraform.tfvars
│   │   └── README.md
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       ├── terraform.tfvars
│       └── README.md
└── README.md
```

#### environments/dev/main.tf

```hcl
terraform {
  required_version = ">= 1.0"
}

module "infrastructure" {
  source = "../../modules/infrastructure"

  environment         = "dev"
  location            = "West Europe"
  instance_count      = 1
  vm_size             = "Standard_B2s"
  enable_monitoring   = false
}

output "resource_group_name" {
  value = module.infrastructure.resource_group_name
}
```

### Option 3 : Fichiers tfvars (flexible)

```
projet/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── backend.tf
│
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
└── README.md
```

```bash
# Déploiement
terraform apply -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## 📛 Convention de nommage

### Ressources Terraform

```hcl
# Format : <resource_type> "<name>"
# Nom descriptif, en snake_case

# ✅ Bon
resource "azurerm_resource_group" "main" {}
resource "azurerm_storage_account" "application_logs" {}
resource "azurerm_virtual_network" "primary_vnet" {}

# ❌ Mauvais
resource "azurerm_resource_group" "rg1" {}
resource "azurerm_storage_account" "sa" {}
resource "azurerm_virtual_network" "net" {}
```

### Ressources Azure

```hcl
# Format recommandé : <type>-<name>-<environment>-<region>
# En minuscules, avec tirets

resource "azurerm_resource_group" "main" {
  name = "rg-myapp-dev-westeurope"
}

resource "azurerm_storage_account" "logs" {
  name = "stmyappdevlogs"  # Pas de tirets (limitation Azure)
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-myapp-dev-westeurope"
}
```

### Préfixes recommandés

| Ressource Azure | Préfixe |
|----------------|---------|
| Resource Group | `rg-` |
| Virtual Network | `vnet-` |
| Subnet | `subnet-` |
| Network Security Group | `nsg-` |
| Virtual Machine | `vm-` |
| Storage Account | `st` (pas de tiret) |
| App Service | `app-` |
| SQL Database | `sql-` |
| Key Vault | `kv-` |
| Container Registry | `cr` (pas de tiret) |

## 📝 Documentation

### README.md

```markdown
# Infrastructure MyApp

Infrastructure Azure pour l'application MyApp.

## Prérequis

- Terraform >= 1.0
- Azure CLI
- Compte Azure avec permissions Contributor

## Structure

- `network.tf` : Réseau (VNet, Subnets, NSG)
- `compute.tf` : Machines virtuelles
- `storage.tf` : Comptes de stockage
- `database.tf` : Bases de données

## Utilisation

### Développement

\`\`\`bash
terraform init
terraform workspace select dev
terraform plan
terraform apply
\`\`\`

### Production

\`\`\`bash
terraform init
terraform workspace select prod
terraform plan -out=tfplan
terraform apply tfplan
\`\`\`

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name | - |
| `location` | Azure region | `West Europe` |
| `vm_size` | VM size | `Standard_B2s` |

## Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Resource group name |
| `vnet_id` | Virtual network ID |
```

### Commentaires dans le code

```hcl
# ==============================================================================
# NETWORK INFRASTRUCTURE
# ==============================================================================

# Primary virtual network for the application
# Deployed across 3 subnets: web, app, data
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

# Web tier subnet - Hosts web servers
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

## 🔒 .gitignore

```bash
# .gitignore

# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Except example files
!*.tfvars.example
!example.tfvars

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore plan files
*.tfplan

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

## 💡 Bonnes pratiques

### 1. Un fichier par fonction

```
# ✅ Bon : Fichiers séparés par fonction
network.tf
compute.tf
storage.tf

# ⚠️ Moins bon : Tout dans main.tf
main.tf  # 1000 lignes
```

### 2. Variables groupées logiquement

```hcl
# variables.tf

# ==============================================================================
# GENERAL
# ==============================================================================
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# ==============================================================================
# NETWORK
# ==============================================================================
variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "subnet_web_prefixes" {
  description = "Web subnet prefixes"
  type        = list(string)
}
```

### 3. Locals pour valeurs calculées

```hcl
# locals.tf

locals {
  # Nom de ressources
  resource_prefix = "${var.project}-${var.environment}"

  # Tags communs
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }

  # Configuration par environnement
  vm_size = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B2s"
}
```

### 4. Outputs organisés

```hcl
# outputs.tf

# ==============================================================================
# GENERAL
# ==============================================================================
output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

# ==============================================================================
# NETWORK
# ==============================================================================
output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    web  = azurerm_subnet.web.id
    app  = azurerm_subnet.app.id
    data = azurerm_subnet.data.id
  }
}
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Organiser les fichiers Terraform par fonction
- ✅ Structure pour petits et grands projets
- ✅ Approches multi-environnements (workspaces, dossiers, tfvars)
- ✅ Conventions de nommage cohérentes
- ✅ Documentation et commentaires
- ✅ .gitignore pour Terraform

## ➡️ Prochaine étape

Maintenant que votre code est bien organisé, découvrons les **bonnes pratiques** pour écrire du Terraform de qualité professionnelle !

**Prochain module** : [17 - Bonnes pratiques](./17-bonnes-pratiques.md)

---

📂 Parfait ! Votre code est organisé. Découvrons les bonnes pratiques !
