# 07 - Variables et Outputs

## 📖 Introduction

Les **variables** permettent de paramétrer votre code Terraform, le rendant réutilisable et flexible. Les **outputs** permettent d'extraire et d'afficher des informations sur l'infrastructure créée.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Déclarer et utiliser des variables
- ✅ Définir des valeurs par défaut et des contraintes
- ✅ Utiliser différentes méthodes pour passer des valeurs
- ✅ Valider les entrées utilisateur
- ✅ Créer des outputs pour exposer des informations
- ✅ Utiliser des outputs entre modules

## 📥 Input Variables (Variables d'entrée)

### Déclaration basique

```hcl
# variables.tf

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  # Pas de default = variable obligatoire
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}
```

### Utilisation

```hcl
# main.tf

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
  }
}
```

## 🎨 Types de variables

### String

```hcl
variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "myproject"
}

# Utilisation
name = "rg-${var.project_name}"
```

### Number

```hcl
variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
  default     = 3
}

# Utilisation
count = var.vm_count
```

### Bool

```hcl
variable "enable_monitoring" {
  type        = bool
  description = "Enable Azure Monitor"
  default     = true
}

# Utilisation
enabled = var.enable_monitoring
```

### List

```hcl
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["1", "2", "3"]
}

# Utilisation
availability_zones = var.availability_zones

# Accès aux éléments
first_zone = var.availability_zones[0]
```

### Map

```hcl
variable "tags" {
  type = map(string)
  description = "Tags to apply to resources"
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Utilisation
tags = var.tags

# Accès aux valeurs
env_tag = var.tags["environment"]
# ou
env_tag = var.tags.environment
```

### Object (Structure complexe)

```hcl
variable "vm_config" {
  type = object({
    name     = string
    size     = string
    count    = number
    enabled  = bool
  })
  description = "VM configuration"
  default = {
    name    = "myvm"
    size    = "Standard_B2s"
    count   = 2
    enabled = true
  }
}

# Utilisation
size = var.vm_config.size
```

### List d'objects (Structures complexes)

```hcl
variable "storage_accounts" {
  type = list(object({
    name                     = string
    account_tier             = string
    account_replication_type = string
  }))
  description = "List of storage accounts to create"
  default = [
    {
      name                     = "stlogs"
      account_tier             = "Standard"
      account_replication_type = "LRS"
    },
    {
      name                     = "stdata"
      account_tier             = "Premium"
      account_replication_type = "GRS"
    }
  ]
}

# Utilisation avec for_each
resource "azurerm_storage_account" "example" {
  for_each = { for idx, sa in var.storage_accounts : idx => sa }

  name                     = each.value.name
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  # ...
}
```

## ✅ Validation des variables

### Contraintes simples

```hcl
variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Contraintes multiples

```hcl
variable "vm_size" {
  type        = string
  description = "Azure VM size"

  validation {
    condition = can(regex("^Standard_[BDS][0-9]+(m?s?)(_v[0-9]+)?$", var.vm_size))
    error_message = "VM size must follow Azure naming convention (e.g., Standard_B2s, Standard_D4s_v3)."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances"

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"

  validation {
    condition = (
      can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    )
    error_message = "Storage account name must be 3-24 lowercase letters or numbers."
  }
}
```

## 🎯 Définir des valeurs de variables

### Méthode 1 : Valeur par défaut

```hcl
variable "location" {
  type    = string
  default = "West Europe"
}
```

### Méthode 2 : Fichier terraform.tfvars

```hcl
# terraform.tfvars
environment   = "production"
location      = "North Europe"
instance_count = 5

tags = {
  project    = "myapp"
  cost_center = "engineering"
}
```

Terraform charge automatiquement `terraform.tfvars`.

### Méthode 3 : Fichiers .tfvars personnalisés

```hcl
# dev.tfvars
environment    = "dev"
location       = "West Europe"
instance_count = 1

# prod.tfvars
environment    = "prod"
location       = "North Europe"
instance_count = 3
```

Utilisation :

```bash
# Appliquer avec dev
terraform apply -var-file="dev.tfvars"

# Appliquer avec prod
terraform apply -var-file="prod.tfvars"
```

**➡️ Voir l'exemple complet** : `../azure/08-tfvars/`

### Méthode 4 : Ligne de commande

```bash
# Passer une variable
terraform apply -var="environment=dev"

# Passer plusieurs variables
terraform apply \
  -var="environment=dev" \
  -var="location=West Europe" \
  -var="instance_count=2"
```

### Méthode 5 : Variables d'environnement

```bash
# Linux/macOS
export TF_VAR_environment="dev"
export TF_VAR_location="West Europe"
terraform apply

# Windows PowerShell
$env:TF_VAR_environment="dev"
$env:TF_VAR_location="West Europe"
terraform apply
```

### Ordre de priorité

Terraform applique les valeurs dans cet ordre (du moins au plus prioritaire) :

1. Valeur `default` dans la déclaration
2. Variable d'environnement `TF_VAR_*`
3. Fichier `terraform.tfvars`
4. Fichier `*.auto.tfvars` (ordre alphabétique)
5. `-var-file` (dans l'ordre spécifié)
6. `-var` en ligne de commande

## 🔒 Variables sensibles

```hcl
variable "database_password" {
  type        = string
  description = "Database admin password"
  sensitive   = true  # Ne sera pas affiché dans les logs
}

# Utilisation
resource "azurerm_sql_server" "example" {
  administrator_login_password = var.database_password
  # ...
}
```

**Attention** : `sensitive = true` masque la valeur dans les logs, mais ne chiffre pas le fichier tfstate !

## 📤 Outputs (Sorties)

### Déclaration basique

```hcl
# outputs.tf

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}
```

### Afficher les outputs

```bash
# Appliquer et voir les outputs
terraform apply

# Afficher uniquement les outputs
terraform output

# Afficher un output spécifique
terraform output resource_group_name

# Format JSON
terraform output -json

# Format brut (sans guillemets)
terraform output -raw resource_group_name
```

### Outputs complexes

```hcl
output "storage_accounts" {
  description = "Map of storage account details"
  value = {
    for sa in azurerm_storage_account.example :
    sa.name => {
      id                = sa.id
      primary_endpoint  = sa.primary_blob_endpoint
      connection_string = sa.primary_connection_string
    }
  }
  sensitive = true  # Masquer dans les logs
}

output "vm_public_ips" {
  description = "List of VM public IP addresses"
  value       = [for nic in azurerm_network_interface.example : nic.private_ip_address]
}
```

### Outputs conditionnels

```hcl
output "public_ip" {
  description = "Public IP address if enabled"
  value       = var.enable_public_ip ? azurerm_public_ip.example[0].ip_address : null
}
```

**➡️ Voir l'exemple complet** : `../azure/09-output/`

## 🔗 Utiliser les outputs entre modules

### Module enfant

```hcl
# modules/network/outputs.tf

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = azurerm_subnet.main[*].id
}
```

### Module parent

```hcl
# main.tf

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
}

# Utiliser les outputs du module
resource "azurerm_network_interface" "example" {
  # ...
  subnet_id = module.network.subnet_ids[0]
}

# Exposer les outputs du module
output "vnet_id" {
  description = "Virtual network ID"
  value       = module.network.vnet_id
}
```

**➡️ Voir l'exemple complet** : `../azure/13-modules/`

## 💡 Locals (Variables locales)

Les `locals` sont des valeurs calculées utilisées uniquement dans le module actuel.

### Différence entre variables et locals

| Variable | Local |
|----------|-------|
| Passée de l'extérieur | Calculée en interne |
| Peut avoir une valeur par défaut | Toujours une valeur |
| Peut être validée | Pas de validation |
| Usage : `var.nom` | Usage : `local.nom` |

### Utilisation des locals

```hcl
locals {
  # Composition de noms
  resource_prefix = "${var.environment}-${var.project}"

  # Tags communs
  common_tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
    created_at  = timestamp()
  }

  # Logique conditionnelle
  storage_tier = var.environment == "prod" ? "Premium" : "Standard"

  # Calculs
  total_cost = var.instance_count * var.instance_price

  # Manipulation de strings
  storage_name = lower(replace("${local.resource_prefix}-storage", "/[^a-z0-9]/", ""))
}

# Utilisation
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "example" {
  name         = local.storage_name
  account_tier = local.storage_tier
  # ...
}
```

**➡️ Voir l'exemple complet** : `../azure/03-locals/`

## 🎯 Exemple complet

### variables.tf

```hcl
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "West Europe"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "storage_account_tier" {
  type        = string
  description = "Storage account tier"
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Tier must be Standard or Premium."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
```

### dev.tfvars

```hcl
subscription_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
environment           = "dev"
location              = "West Europe"
project               = "myapp"
storage_account_tier  = "Standard"

tags = {
  cost_center = "engineering"
  owner       = "john.doe"
}
```

### main.tf

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  resource_prefix = "${var.environment}-${var.project}"
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      managed_by  = "terraform"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "main" {
  name                     = lower(replace("${local.resource_prefix}st", "/[^a-z0-9]/", ""))
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = "LRS"
  tags                     = local.common_tags
}
```

### outputs.tf

```hcl
output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "all_tags" {
  description = "All tags applied"
  value       = local.common_tags
}
```

### Utilisation

```bash
# Développement
terraform apply -var-file="dev.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

## 💡 Bonnes pratiques

### 1. Toujours définir le type

```hcl
# ✅ Bon
variable "location" {
  type = string
}

# ❌ Mauvais (type implicite)
variable "location" {}
```

### 2. Ajouter des descriptions

```hcl
# ✅ Bon
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}
```

### 3. Valider les entrées

```hcl
# ✅ Bon
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Invalid environment."
  }
}
```

### 4. Ne pas commiter terraform.tfvars

```bash
# .gitignore
*.tfvars
!*.tfvars.example
```

### 5. Créer des fichiers .tfvars.example

```hcl
# dev.tfvars.example
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
environment     = "dev"
location        = "West Europe"
```

### 6. Organiser les fichiers

```
projet/
├── main.tf
├── variables.tf        # Toutes les déclarations
├── outputs.tf          # Tous les outputs
├── locals.tf           # Toutes les locals (optionnel)
├── dev.tfvars          # Valeurs dev (ne pas commiter)
├── prod.tfvars         # Valeurs prod (ne pas commiter)
├── dev.tfvars.example  # Template dev
└── prod.tfvars.example # Template prod
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Déclarer des variables avec types et validation
- ✅ Passer des valeurs via tfvars, ligne de commande, ou variables d'env
- ✅ Utiliser des locals pour la logique interne
- ✅ Créer des outputs pour exposer des informations
- ✅ Organiser votre code avec variables, locals et outputs
- ✅ Les bonnes pratiques de gestion des variables

## ➡️ Prochaine étape

Vous savez maintenant rendre votre code paramétrable ! Découvrons le **cycle de vie Terraform** pour comprendre comment Terraform gère les changements.

**Prochain module** : [08 - Le cycle de vie Terraform](./08-cycle-de-vie.md)

---

🎉 Excellent ! Votre code est maintenant flexible et réutilisable. Découvrons le cycle de vie !
