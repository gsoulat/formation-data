# 06 - Providers et Resources

## 📖 Introduction

Les **Providers** et les **Resources** sont les deux concepts fondamentaux de Terraform. Les providers permettent à Terraform de communiquer avec les APIs des cloud providers, tandis que les resources représentent les composants d'infrastructure que vous souhaitez créer.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre le rôle des providers
- ✅ Configurer différents providers
- ✅ Utiliser plusieurs providers simultanément
- ✅ Créer et gérer des resources
- ✅ Comprendre le cycle de vie des resources
- ✅ Utiliser les meta-arguments

## 🔌 Qu'est-ce qu'un Provider ?

Un **provider** est un plugin qui permet à Terraform d'interagir avec une API externe (cloud provider, SaaS, etc.).

### Providers populaires

| Provider | Description | Nombre de resources |
|----------|-------------|---------------------|
| **azurerm** | Microsoft Azure | 1000+ |
| **aws** | Amazon Web Services | 900+ |
| **google** | Google Cloud Platform | 400+ |
| **kubernetes** | Kubernetes | 100+ |
| **github** | GitHub | 50+ |
| **random** | Génération aléatoire | 10 |
| **null** | Provider utilitaire | 2 |

Découvrez tous les providers sur : https://registry.terraform.io/browse/providers

## ⚙️ Configuration d'un Provider

### Provider Azure (azurerm)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  # Source du provider
      version = "~> 4.0"              # Version contrainte
    }
  }
}

provider "azurerm" {
  features {}

  # Configuration optionnelle
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # skip_provider_registration peut accélérer les déploiements
  skip_provider_registration = true
}
```

### Versions des providers

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"     # >= 4.0, < 5.0
      # version = ">= 4.0"   # 4.0 ou supérieur
      # version = "= 4.0.0"  # Exactement 4.0.0
      # version = ">= 4.0, < 4.10"  # Entre 4.0 et 4.10
    }
  }

  # Version minimale de Terraform
  required_version = ">= 1.0"
}
```

**Opérateurs de version** :
- `~>` : Permet les mises à jour de patch uniquement
- `>=` : Version minimale
- `<=` : Version maximale
- `=` : Version exacte
- `!=` : Exclure une version

## 🔀 Utiliser plusieurs Providers

### Providers multiples (même type)

```hcl
# Provider par défaut pour West Europe
provider "azurerm" {
  features {}
  alias = "westeurope"
}

# Provider alternatif pour North Europe
provider "azurerm" {
  features {}
  alias       = "northeurope"
  # Configuration différente si nécessaire
}

# Utiliser le provider par défaut
resource "azurerm_resource_group" "west" {
  name     = "rg-west"
  location = "West Europe"
  # Utilise le provider "westeurope"
}

# Utiliser le provider alternatif
resource "azurerm_resource_group" "north" {
  provider = azurerm.northeurope
  name     = "rg-north"
  location = "North Europe"
}
```

### Providers de types différents

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Les providers random et null ne nécessitent pas de configuration
# ils sont utilisés automatiquement

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "example" {
  name                = "st${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}
```

## 📦 Qu'est-ce qu'une Resource ?

Une **resource** représente un élément d'infrastructure (VM, réseau, base de données, etc.).

### Syntaxe d'une resource

```hcl
resource "<TYPE>" "<NAME>" {
  # Arguments
  argument_name = argument_value

  # Bloc imbriqué
  block_name {
    nested_argument = value
  }

  # Meta-arguments (spéciaux)
  depends_on = [other_resource]
  count      = 3
}
```

### Exemple : Resource Group

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

**Décortiquons** :
- `azurerm_resource_group` : Type de resource
- `main` : Nom local (utilisé uniquement dans Terraform)
- `name` : Argument requis (nom dans Azure)
- `location` : Argument requis (région Azure)
- `tags` : Argument optionnel

## 🔗 Référencer des Resources

### Références basiques

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  name                = "stexample"

  # Référencer le nom du RG
  resource_group_name = azurerm_resource_group.main.name

  # Référencer la location du RG
  location            = azurerm_resource_group.main.location

  # ...
}
```

### Références avec dépendances

Terraform crée automatiquement des **dépendances implicites** quand vous référencez une resource :

```hcl
# Terraform sait qu'il doit créer le RG AVANT le Storage Account
resource "azurerm_storage_account" "example" {
  resource_group_name = azurerm_resource_group.main.name  # ← Dépendance implicite
}
```

## 🎯 Meta-Arguments

Les meta-arguments sont des arguments spéciaux disponibles pour toutes les resources.

### 1. depends_on (dépendances explicites)

Utilisez `depends_on` quand Terraform ne peut pas détecter automatiquement les dépendances.

```hcl
resource "azurerm_storage_account" "example" {
  name                = "stexample"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  # Dépendance explicite : attendre que le Storage Account soit prêt
  depends_on = [
    azurerm_storage_account.example
  ]
}
```

**➡️ Voir l'exemple complet** : `../azure/02-depend_on/`

### 2. count (créer plusieurs instances)

```hcl
variable "storage_accounts" {
  default = 3
}

resource "azurerm_storage_account" "example" {
  count = var.storage_accounts

  name                = "stexample${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ...
}

# Accès aux instances
# azurerm_storage_account.example[0]
# azurerm_storage_account.example[1]
# azurerm_storage_account.example[2]
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/01-count/`

### 3. for_each (créer plusieurs instances avec clés)

```hcl
variable "storage_accounts" {
  default = {
    logs    = "stlogs"
    data    = "stdata"
    backups = "stbackups"
  }
}

resource "azurerm_storage_account" "example" {
  for_each = var.storage_accounts

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ...

  tags = {
    purpose = each.key  # logs, data, ou backups
  }
}

# Accès aux instances
# azurerm_storage_account.example["logs"]
# azurerm_storage_account.example["data"]
# azurerm_storage_account.example["backups"]
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/03-for-each/`

### 4. provider (spécifier un provider alternatif)

```hcl
provider "azurerm" {
  features {}
  alias = "westeurope"
}

resource "azurerm_resource_group" "example" {
  provider = azurerm.westeurope  # Utiliser ce provider spécifique
  name     = "rg-example"
  location = "West Europe"
}
```

### 5. lifecycle (contrôler le cycle de vie)

```hcl
resource "azurerm_storage_account" "example" {
  name                = "stexample"
  resource_group_name = azurerm_resource_group.main.name
  # ...

  lifecycle {
    # Empêcher la destruction de cette resource
    prevent_destroy = true

    # Créer la nouvelle resource AVANT de détruire l'ancienne
    create_before_destroy = true

    # Ignorer les changements sur certains attributs
    ignore_changes = [
      tags,
      # Azure peut modifier automatiquement certains champs
    ]

    # Remplacer la resource si cet attribut change
    replace_triggered_by = [
      azurerm_resource_group.main.location
    ]
  }
}
```

## 🎨 Exemples de Resources Azure

### Virtual Network

```hcl
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}
```

### Subnet

```hcl
resource "azurerm_subnet" "example" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  # Délégation pour certains services
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}
```

### Virtual Machine (simple)

```hcl
resource "azurerm_linux_virtual_machine" "example" {
  name                = "vm-example"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

## 🔍 Inspecter les Resources

### Lister les resources gérées

```bash
# Lister toutes les resources
terraform state list

# Afficher les détails d'une resource
terraform state show azurerm_resource_group.main
```

### Documentation des resources

Chaque resource a une documentation détaillée sur le Registry :

**Azure Provider** : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

**Structure de la doc** :
- Arguments requis et optionnels
- Attributs exportés (utilisables en référence)
- Exemples d'utilisation
- Notes importantes

## 🎯 Import de resources existantes

Vous pouvez importer des resources Azure existantes dans Terraform.

### Étape 1 : Créer le bloc resource

```hcl
resource "azurerm_resource_group" "imported" {
  # Laisser vide pour l'instant
  name     = "existing-rg"
  location = "West Europe"
}
```

### Étape 2 : Importer

```bash
# Syntaxe : terraform import <TYPE>.<NAME> <AZURE_RESOURCE_ID>
terraform import azurerm_resource_group.imported \
  /subscriptions/xxxx/resourceGroups/existing-rg
```

### Étape 3 : Récupérer la configuration

```bash
# Afficher la configuration actuelle
terraform show
```

**➡️ Voir l'exemple complet** : `../azure/11-import/`

## 💡 Bonnes pratiques

### 1. Nommage cohérent

```hcl
# ✅ Bon : Nommage logique et cohérent
resource "azurerm_resource_group" "application_main" {
  name = "rg-myapp-prod-westeurope"
}

resource "azurerm_storage_account" "application_logs" {
  name = "stmyappprodlogs"
}

# ❌ Mauvais : Noms génériques
resource "azurerm_resource_group" "rg1" {
  name = "my-rg"
}
```

### 2. Utiliser des variables pour les configs répétitives

```hcl
# ✅ Bon
locals {
  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  }
}

resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = var.location
  tags     = local.common_tags
}
```

### 3. Organiser les resources par fonction

```
# Fichiers séparés par fonction
main.tf          # Provider configuration
network.tf       # VNet, Subnets, NSG
compute.tf       # VMs, Scale Sets
storage.tf       # Storage Accounts, Containers
database.tf      # SQL, CosmosDB
```

### 4. Versionner les providers

```hcl
# ✅ Bon : Version contrainte
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"  # Permet les updates de patch
    }
  }
}

# ❌ Mauvais : Pas de contrainte de version
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Pas de version = peut casser à tout moment
    }
  }
}
```

## 📋 Résumé des Meta-Arguments

| Meta-Argument | Usage | Exemple |
|---------------|-------|---------|
| `depends_on` | Dépendances explicites | Ordre de création |
| `count` | Créer N instances (index) | 3 VMs identiques |
| `for_each` | Créer N instances (clés) | VMs par environnement |
| `provider` | Provider alternatif | Multi-région |
| `lifecycle` | Contrôler le cycle de vie | Empêcher destruction |

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Les providers permettent à Terraform d'interagir avec les APIs
- ✅ Les resources représentent les composants d'infrastructure
- ✅ Les dépendances implicites vs explicites (depends_on)
- ✅ Les meta-arguments : count, for_each, lifecycle, provider
- ✅ Comment référencer les resources entre elles
- ✅ Comment importer des resources existantes

## ➡️ Prochaine étape

Maintenant que vous maîtrisez les providers et resources, découvrons comment rendre notre code **paramétrable et réutilisable** avec les Variables et Outputs !

**Prochain module** : [07 - Variables et Outputs](./07-variables-outputs.md)

---

🚀 Super ! Vous savez maintenant créer et gérer des resources. Rendons le code paramétrable !
