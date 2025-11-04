# 12 - Les modules

## 📖 Introduction

Les **modules** sont des conteneurs réutilisables de code Terraform. Ils permettent d'organiser, d'encapsuler et de réutiliser des configurations d'infrastructure.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Créer et utiliser des modules
- ✅ Passer des variables et récupérer des outputs
- ✅ Organiser votre code avec des modules
- ✅ Utiliser des modules du Terraform Registry
- ✅ Versionner et publier des modules

## 📦 Qu'est-ce qu'un module ?

### Définition

Un **module** est un dossier contenant des fichiers Terraform (`.tf`). Tout projet Terraform est techniquement un module (le **root module**).

### Structure d'un module

```
modules/
└── network/
    ├── main.tf       # Ressources principales
    ├── variables.tf  # Variables d'entrée
    ├── outputs.tf    # Outputs (valeurs exportées)
    └── README.md     # Documentation
```

## 🏗️ Créer un module simple

### Exemple : Module réseau

#### modules/network/variables.tf

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets"
  type = map(object({
    address_prefixes = list(string)
  }))
}
```

#### modules/network/main.tf

```hcl
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
}
```

#### modules/network/outputs.tf

```hcl
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}
```

## 📲 Utiliser un module

### main.tf (root module)

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
}

resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

# Utiliser le module network
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "vnet-example"
  address_space       = ["10.0.0.0/16"]

  subnets = {
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

# Utiliser les outputs du module
output "vnet_id" {
  value = module.network.vnet_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}
```

### Commandes

```bash
# Initialiser (télécharge le module)
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply
```

**➡️ Voir l'exemple complet** : `../azure/13-modules/`

## 🔗 Sources de modules

### Module local

```hcl
module "network" {
  source = "./modules/network"  # Chemin relatif
  # ...
}
```

### Module depuis Git

```hcl
module "network" {
  source = "git::https://github.com/user/repo.git//modules/network"
  # ...
}

# Avec une version spécifique
module "network" {
  source = "git::https://github.com/user/repo.git//modules/network?ref=v1.2.0"
  # ...
}
```

### Module depuis Terraform Registry

```hcl
module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"
  # ...
}
```

## 🎨 Modules avancés

### Module avec count

```hcl
module "storage" {
  source = "./modules/storage"
  count  = 3

  name                = "st${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Accès :
# module.storage[0]
# module.storage[1]
# module.storage[2]
```

### Module avec for_each

```hcl
variable "environments" {
  default = {
    dev  = "West Europe"
    prod = "North Europe"
  }
}

module "network" {
  source   = "./modules/network"
  for_each = var.environments

  vnet_name           = "vnet-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = each.value
  # ...
}

# Accès :
# module.network["dev"]
# module.network["prod"]
```

### Module avec dépendances

```hcl
module "network" {
  source = "./modules/network"
  # ...
}

module "compute" {
  source = "./modules/compute"

  subnet_id = module.network.subnet_ids["web"]  # Dépendance implicite
  # ...
}

# Dépendance explicite
module "monitoring" {
  source = "./modules/monitoring"
  # ...

  depends_on = [
    module.network,
    module.compute
  ]
}
```

## 📚 Terraform Registry

### Découvrir des modules

Explorez https://registry.terraform.io/browse/modules

**Modules Azure populaires** :
- `Azure/network/azurerm` : Réseau Azure
- `Azure/compute/azurerm` : Machines virtuelles
- `Azure/aks/azurerm` : Kubernetes Azure
- `Azure/database/azurerm` : Bases de données

### Utiliser un module du Registry

```hcl
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "7.5.0"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = "aks-example"
  # Voir la documentation pour tous les paramètres
}
```

## 📝 Bonnes pratiques

### 1. Structure de module standard

```
module/
├── main.tf          # Ressources principales
├── variables.tf     # Variables d'entrée (tout en un fichier)
├── outputs.tf       # Outputs (tout en un fichier)
├── versions.tf      # Contraintes de versions
├── README.md        # Documentation
└── examples/        # Exemples d'utilisation
    └── basic/
        └── main.tf
```

### 2. Documentation claire

```markdown
# Network Module

## Usage

\`\`\`hcl
module "network" {
  source = "./modules/network"

  resource_group_name = "rg-example"
  location            = "West Europe"
  vnet_name           = "vnet-example"
}
\`\`\`

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | `string` | - | Resource group name |
| `location` | `string` | - | Azure region |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Virtual network ID |
```

### 3. Versions sémantiques

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
  }
}
```

### 4. Variables avec validation

```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 5. Outputs documentés

```hcl
output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}
```

## 🔄 Cycle de vie des modules

### 1. Développement

```bash
# Créer le module
mkdir -p modules/my-module
cd modules/my-module

# Créer les fichiers
touch main.tf variables.tf outputs.tf README.md
```

### 2. Test local

```bash
# Utiliser le module localement
module "test" {
  source = "./modules/my-module"
  # ...
}

terraform init
terraform plan
terraform apply
```

### 3. Versionnement

```bash
# Git tag
git tag -a v1.0.0 -m "First release"
git push origin v1.0.0
```

### 4. Publication

Si vous souhaitez partager :
1. Publier sur GitHub
2. Connecter à Terraform Registry
3. Créer des releases avec tags sémantiques

## 🎯 Exemple complet : Infrastructure multi-tier

```
projet/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── database/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### main.tf

```hcl
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_name           = "vnet-${var.environment}"
  # ...
}

module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["web"]
  # ...
}

module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["data"]
  # ...

  depends_on = [module.network]
}
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Créer des modules réutilisables
- ✅ Passer des variables et récupérer des outputs
- ✅ Utiliser des modules locaux, Git, et Registry
- ✅ Organiser le code en modules
- ✅ Les bonnes pratiques de modules

## ➡️ Prochaine étape

Maintenant que vous savez créer des modules, découvrons les **Data Sources** pour lire des informations existantes dans Azure !

**Prochain module** : [13 - Data Sources](./13-data-sources.md)

---

📦 Parfait ! Vous maîtrisez les modules. Découvrons les data sources !
