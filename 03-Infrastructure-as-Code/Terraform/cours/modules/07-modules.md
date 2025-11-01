# Module 7 : Modules Terraform

> **Durée : 1 heure**
>
> Créez des composants d'infrastructure réutilisables

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre ce qu'est un module Terraform
- ✅ Créer votre premier module custom
- ✅ Définir des variables d'entrée et outputs de module
- ✅ Utiliser des modules du Terraform Registry
- ✅ Versionner et publier vos modules
- ✅ Structurer un projet avec des modules
- ✅ Appliquer les best practices des modules

---

## 📦 Qu'est-ce qu'un Module ?

Un **module** est un ensemble de fichiers Terraform (`.tf`) regroupés dans un répertoire, conçu pour être réutilisé.

### Analogie

```
Module Terraform = Fonction en programmation

Fonction Python                   Module Terraform
────────────────                  ─────────────────
def create_user(name, role):      module "user" {
    user = User(name)                 source = "./modules/user"
    user.assign_role(role)            name   = "john"
    return user                       role   = "admin"
                                  }

# Réutilisable                    # Réutilisable
user1 = create_user("john", "admin")    module "user1" { ... }
user2 = create_user("jane", "dev")      module "user2" { ... }
```

### Types de Modules

1. **Root Module** : Le répertoire principal où vous exécutez `terraform apply`
2. **Child Module** : Un module appelé par un autre module
3. **Published Module** : Un module publié sur le Terraform Registry

---

## 🏗️ Structure d'un Module

### Structure Minimale

```
modules/
└── network/
    ├── main.tf        # Ressources principales
    ├── variables.tf   # Variables d'entrée
    ├── outputs.tf     # Outputs
    └── README.md      # Documentation (recommandé)
```

### Structure Complète (Recommandée)

```
modules/
└── network/
    ├── main.tf          # Ressources principales
    ├── variables.tf     # Variables d'entrée
    ├── outputs.tf       # Outputs
    ├── versions.tf      # Contraintes de version
    ├── README.md        # Documentation
    ├── examples/        # Exemples d'utilisation
    │   └── complete/
    │       ├── main.tf
    │       └── variables.tf
    └── tests/           # Tests (optionnel)
        └── network_test.go
```

---

## 🎨 Créer Votre Premier Module

### Exemple : Module Réseau Azure

Créons un module pour déployer un réseau Azure avec des subnets.

#### Étape 1 : Créer la Structure

```bash
mkdir -p modules/azure-network
cd modules/azure-network
touch main.tf variables.tf outputs.tf versions.tf README.md
```

#### Étape 2 : `versions.tf`

```hcl
# modules/azure-network/versions.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}
```

#### Étape 3 : `variables.tf`

```hcl
# modules/azure-network/variables.tf

variable "resource_group_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "vnet_name" {
  description = "Nom du Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Espace d'adressage du VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map des subnets à créer"
  type = map(object({
    address_prefix = string
    delegation     = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
```

#### Étape 4 : `main.tf`

```hcl
# modules/azure-network/main.tf

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.address_prefix]

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name = each.value.delegation
      }
    }
  }
}

# Network Security Groups (un par subnet)
resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.subnets
  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Association NSG-Subnet
resource "azurerm_subnet_network_security_group_association" "associations" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}
```

#### Étape 5 : `outputs.tf`

```hcl
# modules/azure-network/outputs.tf

output "vnet_id" {
  description = "ID du Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nom du Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map des IDs de subnets"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}

output "nsg_ids" {
  description = "Map des IDs de NSG"
  value = {
    for k, v in azurerm_network_security_group.nsgs : k => v.id
  }
}
```

#### Étape 6 : `README.md`

```markdown
# Module Azure Network

Ce module crée un Virtual Network Azure avec des subnets et leurs Network Security Groups.

## Usage

```hcl
module "network" {
  source = "./modules/azure-network"

  resource_group_name = "rg-prod"
  location            = "West Europe"
  vnet_name           = "vnet-prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefix = "10.0.1.0/24"
      delegation     = null
    }
    app = {
      address_prefix = "10.0.2.0/24"
      delegation     = null
    }
    db = {
      address_prefix = "10.0.3.0/24"
      delegation     = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Nom du Resource Group | string | n/a | yes |
| location | Région Azure | string | n/a | yes |
| vnet_name | Nom du VNet | string | n/a | yes |
| address_space | Espace d'adressage | list(string) | ["10.0.0.0/16"] | no |
| subnets | Map des subnets | map(object) | {} | no |
| tags | Tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | ID du VNet |
| vnet_name | Nom du VNet |
| subnet_ids | Map des IDs de subnets |
| nsg_ids | Map des IDs de NSG |
```

---

## 🚀 Utiliser un Module

### Dans le Root Module

```hcl
# main.tf (root module)

# Provider configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-prod"
  location = "West Europe"
}

# Utiliser le module network
module "network" {
  source = "./modules/azure-network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "vnet-prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefix = "10.0.1.0/24"
      delegation     = null
    }
    app = {
      address_prefix = "10.0.2.0/24"
      delegation     = null
    }
    db = {
      address_prefix = "10.0.3.0/24"
      delegation     = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
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

### Initialiser et Appliquer

```bash
terraform init   # Télécharge les modules
terraform plan
terraform apply
```

---

## 🌐 Utiliser des Modules du Terraform Registry

Le [Terraform Registry](https://registry.terraform.io/) contient plus de 10 000 modules publics.

### Exemple : Module VPC AWS

```hcl
# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # Toujours spécifier une version !

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### Exemple : Module AKS Azure

```hcl
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "7.5.0"

  resource_group_name = azurerm_resource_group.main.name
  kubernetes_version  = "1.28.0"
  orchestrator_version = "1.28.0"

  prefix = "myaks"

  network_plugin     = "azure"
  vnet_subnet_id     = module.network.subnet_ids["aks"]

  agents_size  = "Standard_D2s_v3"
  agents_count = 3
}
```

---

## 🔄 Sources de Modules

Terraform supporte plusieurs sources de modules :

### 1. Chemin Local

```hcl
module "network" {
  source = "./modules/azure-network"
}

module "network_parent" {
  source = "../modules/azure-network"
}
```

### 2. Terraform Registry

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}
```

### 3. GitHub

```hcl
# Branche main
module "network" {
  source = "github.com/myorg/terraform-modules//azure-network"
}

# Tag spécifique
module "network" {
  source = "github.com/myorg/terraform-modules//azure-network?ref=v1.2.0"
}

# Branche spécifique
module "network" {
  source = "github.com/myorg/terraform-modules//azure-network?ref=develop"
}

# Commit spécifique
module "network" {
  source = "github.com/myorg/terraform-modules//azure-network?ref=abc123"
}
```

### 4. Git (Generic)

```hcl
module "network" {
  source = "git::https://github.com/myorg/terraform-modules.git//azure-network?ref=v1.2.0"
}

# SSH
module "network" {
  source = "git::ssh://git@github.com/myorg/terraform-modules.git//azure-network"
}
```

### 5. HTTP URL

```hcl
module "network" {
  source = "https://example.com/terraform-modules/azure-network.zip"
}
```

### 6. Azure DevOps Repos

```hcl
module "network" {
  source = "git::https://dev.azure.com/myorg/myproject/_git/terraform-modules//azure-network?ref=v1.0.0"
}
```

---

## 📌 Versioning des Modules

### Pourquoi Versionner ?

- ✅ Stabilité : Empêche les changements inattendus
- ✅ Reproductibilité : Même code = même infra
- ✅ Sécurité : Contrôle des mises à jour
- ✅ Rollback : Retour en arrière possible

### Contraintes de Version

```hcl
# Version exacte (dangereux)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}

# Version minimale
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.1.2"
}

# Compatible avec version (recommandé)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"  # Accepte 5.1.x mais pas 5.2.0
}

# Plage de versions
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.1.0, < 6.0.0"
}
```

### Semantic Versioning

```
Version: MAJOR.MINOR.PATCH (ex: 2.3.5)

MAJOR : Changements incompatibles (breaking changes)
MINOR : Nouvelles fonctionnalités (rétrocompatibles)
PATCH : Corrections de bugs

Exemples :
~> 2.3   →  >= 2.3.0, < 2.4.0
~> 2     →  >= 2.0.0, < 3.0.0
>= 2.3.0 →  Toute version >= 2.3.0
```

---

## 🎯 Modules Imbriqués

Les modules peuvent appeler d'autres modules :

```
root/
├── main.tf
└── modules/
    ├── application/
    │   ├── main.tf
    │   └── modules/
    │       └── compute/
    └── network/
```

```hcl
# modules/application/main.tf
module "compute" {
  source = "./modules/compute"

  subnet_id = var.subnet_id
  vm_size   = var.vm_size
}
```

```hcl
# root/main.tf
module "application" {
  source = "./modules/application"

  subnet_id = module.network.subnet_ids["app"]
  vm_size   = "Standard_B2s"
}
```

---

## 🧪 Projet Pratique : Créer un Module Complet

Créons un module pour déployer une application web complète.

### Structure

```
modules/web-app/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

### variables.tf

```hcl
variable "resource_group_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "app_name" {
  description = "Nom de l'application"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_count" {
  description = "Nombre de VMs"
  type        = number
  default     = 2

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "vm_count doit être entre 1 et 10."
  }
}

variable "subnet_id" {
  description = "ID du subnet où déployer les VMs"
  type        = string
}

variable "admin_username" {
  description = "Nom d'utilisateur admin"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clé publique SSH"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
```

### main.tf

```hcl
# Load Balancer Public IP
resource "azurerm_public_ip" "lb" {
  name                = "pip-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "lb-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = var.tags
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "BackEndAddressPool"
}

# Health Probe
resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load Balancing Rule
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

# Network Interfaces
resource "azurerm_network_interface" "vm" {
  count               = var.vm_count
  name                = "nic-${var.app_name}-${count.index}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Association NIC-Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "vm" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.vm[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "vm-${var.app_name}-${count.index}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.app_name}-${count.index}-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/init.sh", {
    app_name = var.app_name
  }))

  tags = merge(var.tags, {
    Role = "WebServer"
  })
}
```

### outputs.tf

```hcl
output "load_balancer_public_ip" {
  description = "IP publique du Load Balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "application_url" {
  description = "URL de l'application"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "vm_ids" {
  description = "IDs des VMs"
  value       = azurerm_linux_virtual_machine.vm[*].id
}

output "vm_private_ips" {
  description = "IPs privées des VMs"
  value       = azurerm_network_interface.vm[*].private_ip_address
}
```

### Utilisation

```hcl
# root/main.tf
module "web_app" {
  source = "./modules/web-app"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  app_name            = "myapp"
  environment         = "prod"
  vm_size             = "Standard_D2s_v3"
  vm_count            = 3
  subnet_id           = module.network.subnet_ids["web"]
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")

  tags = {
    Project = "MyApp"
  }
}

output "app_url" {
  value = module.web_app.application_url
}
```

---

## 📝 Best Practices des Modules

### 1. Un Module = Une Responsabilité

```
✅ BON :
- modules/network/    (gère uniquement le réseau)
- modules/compute/    (gère uniquement les VMs)
- modules/database/   (gère uniquement les DB)

❌ MAUVAIS :
- modules/everything/ (fait tout en même temps)
```

### 2. Documenter avec README.md

Incluez toujours :
- Description du module
- Exemple d'utilisation
- Liste des inputs
- Liste des outputs
- Prérequis

### 3. Valider les Inputs

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}
```

### 4. Fournir des Valeurs par Défaut Sensées

```hcl
variable "vm_size" {
  type    = string
  default = "Standard_B2s"  # Valeur économique par défaut
}

variable "enable_monitoring" {
  type    = bool
  default = true  # Activé par défaut pour la sécurité
}
```

### 5. Utiliser des Outputs Clairs

```hcl
output "vnet_id" {
  description = "ID du Virtual Network créé"
  value       = azurerm_virtual_network.main.id
}
```

### 6. Versionner Vos Modules

```bash
# Créer un tag Git
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 7. Tester Vos Modules

Créez un dossier `examples/` avec des cas d'utilisation :

```
modules/network/
├── main.tf
├── variables.tf
├── outputs.tf
└── examples/
    ├── simple/
    │   └── main.tf
    └── complete/
        └── main.tf
```

---

## 📝 Points Clés à Retenir

1. **Modules** : Composants réutilisables d'infrastructure
2. **Structure** : main.tf, variables.tf, outputs.tf minimum
3. **Registry** : Plus de 10 000 modules publics disponibles
4. **Versioning** : Toujours spécifier une version pour la stabilité
5. **Sources** : Local, Registry, GitHub, Git, HTTP
6. **Best Practices** : Un module = une responsabilité, documenter, valider
7. **Outputs** : Permettent de chaîner les modules

---

## ✅ Quiz de Compréhension

1. Quelle est la différence entre un root module et un child module ?
2. Pourquoi est-il important de versionner les modules ?
3. Comment référencer un module depuis GitHub avec un tag spécifique ?
4. Quelle est la structure minimale recommandée d'un module ?
5. Comment utiliser l'output d'un module dans un autre module ?

---

## 🚀 Prochaine Étape

Vous maîtrisez maintenant les modules ! Il est temps d'apprendre les best practices et l'automatisation.

**➡️ [Module 8 : Best Practices et CI/CD](08-best-practices-cicd.md)**

Dans le prochain module, vous allez :
- Structurer des projets Terraform professionnels
- Appliquer les conventions de nommage
- Gérer les secrets de manière sécurisée
- Créer des pipelines CI/CD avec Azure DevOps et GitHub Actions
- Automatiser les tests et déploiements
- Créer un projet final complet

---

## 📚 Ressources Complémentaires

- [Terraform Modules](https://www.terraform.io/docs/language/modules/index.html)
- [Terraform Registry](https://registry.terraform.io/)
- [Module Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part3.html)
- [Publishing Modules](https://www.terraform.io/docs/registry/modules/publish.html)

---

[⬅️ Module précédent](06-gestion-state.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](08-best-practices-cicd.md)
