# Exemple 06 : Gestion de multiples providers (alias)

## Objectif
Apprendre à utiliser plusieurs configurations du **même provider** avec des paramètres différents grâce aux **alias**.

## Concepts clés

### Provider Alias
- Permet d'utiliser plusieurs instances du même provider
- Utile pour gérer plusieurs régions, subscriptions ou configurations
- Un provider peut être "par défaut" et les autres avec alias

### Cas d'usage
1. **Multi-région** : Déployer dans plusieurs régions Azure
2. **Multi-subscription** : Gérer plusieurs subscriptions
3. **Configurations différentes** : Paramètres différents par environnement

## Structure du code

```hcl
# Provider par défaut (sans alias)
provider "hashicorp-azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = "..."
}

# Provider avec alias "sqlserver"
provider "hashicorp-azurerm" {
  alias = "sqlserver"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "..."
}
```

### Utilisation d'un provider avec alias

Pour utiliser un provider avec alias, ajoutez `provider = <nom>.<alias>` :

```hcl
resource "azurerm_resource_group" "rg" {
  provider = hashicorp-azurerm.sqlserver
  name     = "rg-soulat"
  location = "francecentral"
}
```

## Configuration des features

### prevent_deletion_if_contains_resources

Ce paramètre contrôle la suppression des Resource Groups :
- **true** : Empêche la suppression si le RG contient des ressources (sécurité)
- **false** : Permet la suppression même avec des ressources (attention !)

```hcl
features {
  resource_group {
    prevent_deletion_if_contains_resources = true  # Mode sécurisé
  }
}
```

## Exemples d'utilisation

### 1. Multi-région

```hcl
provider "azurerm" {
  alias = "europe"
  features {}
  subscription_id = var.subscription_id
}

provider "azurerm" {
  alias = "usa"
  features {}
  subscription_id = var.subscription_id
}

# Resource Group en Europe
resource "azurerm_resource_group" "rg_eu" {
  provider = azurerm.europe
  name     = "rg-europe"
  location = "westeurope"
}

# Resource Group aux USA
resource "azurerm_resource_group" "rg_us" {
  provider = azurerm.usa
  name     = "rg-usa"
  location = "eastus"
}
```

### 2. Multi-subscription

```hcl
provider "azurerm" {
  alias = "production"
  features {}
  subscription_id = var.prod_subscription_id
}

provider "azurerm" {
  alias = "development"
  features {}
  subscription_id = var.dev_subscription_id
}

# Ressources de production
resource "azurerm_resource_group" "prod_rg" {
  provider = azurerm.production
  name     = "rg-prod"
  location = "westeurope"
}

# Ressources de développement
resource "azurerm_resource_group" "dev_rg" {
  provider = azurerm.development
  name     = "rg-dev"
  location = "northeurope"
}
```

### 3. Configurations différentes

```hcl
# Provider strict pour la production
provider "azurerm" {
  alias = "prod"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Provider permissif pour le dev
provider "azurerm" {
  alias = "dev"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
```

## Prérequis

1. Provider Azure configuré
2. Accès à une ou plusieurs subscriptions Azure
3. Authentification configurée

## Commandes

```bash
# 1. Initialiser Terraform
terraform init

# 2. Voir les providers configurés
terraform providers

# 3. Voir le plan
terraform plan

# 4. Appliquer
terraform apply

# 5. Voir quelle ressource utilise quel provider
terraform state list
terraform state show azurerm_resource_group.rg

# 6. Détruire
terraform destroy
```

## Points d'attention

### ⚠️ Important
- Si vous ne spécifiez pas `provider`, Terraform utilise le provider par défaut
- Toutes les ressources enfants héritent du provider de leur parent
- Les alias sont définis au niveau du provider, pas au niveau de la ressource

### 📝 Bonnes pratiques
- Nommer les alias de manière descriptive (`prod`, `dev`, `europe`, `usa`)
- Documenter quel alias est utilisé pour quoi
- Éviter d'avoir trop de providers (complexifie la maintenance)
- Utiliser des variables pour les subscription IDs

## Structure des fichiers

```
06-gestion-double-provider/
├── main.tf          # Configuration avec multiples providers
└── README.md        # Ce fichier
```

## Features block - Options disponibles

### resource_group
```hcl
resource_group {
  prevent_deletion_if_contains_resources = true/false
}
```

### key_vault
```hcl
key_vault {
  purge_soft_delete_on_destroy    = true/false
  recover_soft_deleted_key_vaults = true/false
}
```

### virtual_machine
```hcl
virtual_machine {
  delete_os_disk_on_deletion     = true/false
  graceful_shutdown              = true/false
  skip_shutdown_and_force_delete = true/false
}
```

### template_deployment
```hcl
template_deployment {
  delete_nested_items_during_deletion = true/false
}
```

## Exercices

1. **Multi-région** : Créez deux RG dans deux régions différentes
2. **Features différentes** : Testez avec `prevent_deletion_if_contains_resources` à true et false
3. **Module avec provider** : Créez un module qui accepte un provider en paramètre

## Erreurs courantes

### Erreur : Provider not configured
```
Error: provider "azurerm.myalias" is not configured
```
**Solution** : Vérifiez que vous avez bien déclaré le provider avec l'alias

### Erreur : Cannot use provider that is not configured
```
Error: Reference to undeclared provider
```
**Solution** : Ajoutez le bloc provider avec l'alias correspondant

### Erreur : Module does not support provider
```
Error: Module does not support count
```
**Solution** : Passez le provider explicitement au module avec `providers = {...}`

## Exemple complet multi-région

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }
}

provider "azurerm" {
  alias           = "west"
  features {}
  subscription_id = var.subscription_id
}

provider "azurerm" {
  alias           = "north"
  features {}
  subscription_id = var.subscription_id
}

# Application en West Europe
resource "azurerm_resource_group" "west_rg" {
  provider = azurerm.west
  name     = "rg-west-app"
  location = "westeurope"
}

resource "azurerm_storage_account" "west_storage" {
  provider                 = azurerm.west
  name                     = "storagewest${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.west_rg.name
  location                 = azurerm_resource_group.west_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Backup/DR en North Europe
resource "azurerm_resource_group" "north_rg" {
  provider = azurerm.north
  name     = "rg-north-backup"
  location = "northeurope"
}

resource "azurerm_storage_account" "north_storage" {
  provider                 = azurerm.north
  name                     = "storagenorth${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.north_rg.name
  location                 = azurerm_resource_group.north_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```

## Prochaines étapes

- Utiliser des variables pour gérer les configurations (voir exemple 07)
- Créer des modules réutilisables multi-régions
- Implémenter une stratégie de disaster recovery multi-région

## Ressources

- [Documentation Terraform - Provider Configuration](https://www.terraform.io/docs/language/providers/configuration.html)
- [Azure Provider - Features](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block)
- [Multiple Provider Instances](https://www.terraform.io/docs/language/providers/configuration.html#alias-multiple-provider-configurations)
