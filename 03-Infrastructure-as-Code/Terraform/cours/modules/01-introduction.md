# Module 1 : Introduction à Terraform

> **Durée : 45 minutes**
>
> Découvrez les concepts fondamentaux de l'Infrastructure as Code et de Terraform

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Expliquer ce qu'est Terraform et l'Infrastructure as Code (IaC)
- ✅ Identifier les avantages de Terraform par rapport aux approches traditionnelles
- ✅ Comparer Terraform avec d'autres outils IaC
- ✅ Comprendre l'architecture et le workflow de Terraform
- ✅ Maîtriser les concepts clés : Providers, Resources, State, etc.

---

## 📚 Qu'est-ce que Terraform ?

**Terraform** est un outil open-source d'**Infrastructure as Code (IaC)** développé par HashiCorp en 2014. Il permet de définir, provisionner et gérer l'infrastructure cloud de manière **déclarative** et **automatisée**.

### Caractéristiques Principales

- **Open-source** : Code source disponible sur GitHub
- **Déclaratif** : Vous décrivez l'état désiré, Terraform s'occupe du reste
- **Multi-cloud** : Supporte Azure, AWS, GCP et 3000+ providers
- **État partagé** : Tracking de l'infrastructure dans un fichier d'état
- **Langage HCL** : HashiCorp Configuration Language, simple et lisible

### En Pratique

Plutôt que de cliquer dans un portail web ou d'écrire des scripts impératifs, vous écrivez du code déclaratif :

```hcl
# Ce code déclare une machine virtuelle Azure
resource "azurerm_virtual_machine" "example" {
  name                = "my-vm"
  location            = "West Europe"
  resource_group_name = "my-rg"
  vm_size            = "Standard_B2s"

  # ... autres configurations
}
```

Terraform se charge de créer cette VM exactement comme spécifié.

---

## 🏗️ Infrastructure as Code (IaC)

L'**Infrastructure as Code** est une pratique DevOps qui consiste à gérer et provisionner l'infrastructure via du code plutôt que par des processus manuels.

### Avant l'IaC : Approche Manuelle

```
1. Se connecter au portail Azure/AWS
2. Cliquer sur "Créer une ressource"
3. Remplir un formulaire
4. Attendre la création
5. Documenter dans un wiki (souvent oublié)
6. Répéter pour chaque environnement (dev, staging, prod)
```

**Problèmes :**
- ❌ Erreurs humaines
- ❌ Pas de reproductibilité
- ❌ Pas de versioning
- ❌ Lent et répétitif
- ❌ Difficile à auditer
- ❌ Documentation obsolète

### Avec l'IaC : Approche Automatisée

```hcl
# Tout est défini dans du code versionné
resource "azurerm_resource_group" "example" {
  name     = "my-infrastructure"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
```

**Avantages :**
- ✅ Reproductible à l'infini
- ✅ Versionné avec Git
- ✅ Automatisable (CI/CD)
- ✅ Auto-documenté
- ✅ Testable
- ✅ Collaboration facilitée

---

## 🔄 Pourquoi Terraform ?

### 1. Multi-Cloud et Multi-Provider

Terraform fonctionne avec **3000+ providers** :

- **Cloud Providers** : Azure, AWS, GCP, Oracle Cloud, Alibaba Cloud
- **SaaS** : GitHub, Datadog, PagerDuty, Cloudflare
- **Infrastructure** : VMware, Docker, Kubernetes
- **Databases** : MySQL, PostgreSQL, MongoDB Atlas

**Exemple :** Gérer Azure + AWS + GitHub dans le même projet

```hcl
# Azure VM
resource "azurerm_virtual_machine" "app_server" {
  # ...
}

# AWS S3 Bucket
resource "aws_s3_bucket" "backup" {
  # ...
}

# GitHub Repository
resource "github_repository" "project" {
  # ...
}
```

### 2. Déclaratif vs Impératif

**Approche Impérative** (scripts shell, Azure CLI) :
```bash
# Vous devez gérer l'ordre et les conditions
if ! az group exists --name my-rg; then
  az group create --name my-rg --location westeurope
fi

if ! az vm show --name my-vm --resource-group my-rg; then
  az vm create --name my-vm --resource-group my-rg --image UbuntuLTS
fi
```

**Approche Déclarative** (Terraform) :
```hcl
# Vous déclarez l'état désiré
resource "azurerm_resource_group" "example" {
  name     = "my-rg"
  location = "West Europe"
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "my-vm"
  resource_group_name = azurerm_resource_group.example.name
  # ...
}
```

Terraform détermine automatiquement :
- Si la ressource existe déjà
- Si elle doit être créée, modifiée ou supprimée
- L'ordre des opérations

### 3. Plan Avant Exécution

Terraform vous montre **exactement** ce qui va changer **avant** de l'appliquer :

```bash
$ terraform plan

Terraform will perform the following actions:

  # azurerm_resource_group.example will be created
  + resource "azurerm_resource_group" "example" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "my-rg"
    }

  # azurerm_virtual_network.example will be created
  + resource "azurerm_virtual_network" "example" {
      + id                = (known after apply)
      + name              = "my-vnet"
      + resource_group_name = "my-rg"
      + address_space     = [
          + "10.0.0.0/16",
        ]
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**Aucune surprise** : vous savez exactement ce qui va se passer.

### 4. Gestion d'État (State)

Terraform maintient un fichier d'**état** (`terraform.tfstate`) qui track :
- Les ressources créées
- Leurs attributs actuels
- Les dépendances entre ressources

Cela permet à Terraform de :
- Détecter les changements (drift detection)
- Mettre à jour uniquement ce qui a changé
- Supprimer proprement les ressources

### 5. Modules Réutilisables

Créez des composants d'infrastructure réutilisables :

```hcl
# Utiliser un module réseau
module "network" {
  source = "./modules/azure-network"

  vnet_name     = "prod-vnet"
  address_space = "10.0.0.0/16"
  subnets = {
    web = "10.0.1.0/24"
    app = "10.0.2.0/24"
    db  = "10.0.3.0/24"
  }
}
```

**Terraform Registry** : Plus de 10 000 modules publics disponibles.

---

## ⚖️ Terraform vs Autres Outils IaC

| Outil | Type | Approche | Cloud | Langage | État |
|-------|------|----------|-------|---------|------|
| **Terraform** | IaC | Déclaratif | Multi-cloud | HCL | Fichier state |
| **ARM Templates** | IaC | Déclaratif | Azure only | JSON | Intégré Azure |
| **Bicep** | IaC | Déclaratif | Azure only | DSL | Intégré Azure |
| **CloudFormation** | IaC | Déclaratif | AWS only | YAML/JSON | Intégré AWS |
| **Pulumi** | IaC | Déclaratif | Multi-cloud | Python/TS/Go | Fichier state |
| **Ansible** | Config Mgmt | Procédural | Agnostic | YAML | Sans état |
| **Azure CLI** | CLI | Impératif | Azure only | Bash/PS | Aucun |

### Quand Utiliser Terraform ?

**Terraform est idéal pour :**
- ✅ Provisionner de l'infrastructure cloud
- ✅ Projets multi-cloud
- ✅ Infrastructure complexe et évolutive
- ✅ Équipes DevOps cherchant la standardisation
- ✅ CI/CD automation

**Terraform n'est PAS idéal pour :**
- ❌ Configuration d'applications (utilisez Ansible, Chef, Puppet)
- ❌ Déploiement d'applications (utilisez Kubernetes, Docker)
- ❌ Scripts one-shot simples (utilisez CLI)

### Terraform + Autres Outils

En pratique, on combine souvent :

```
Terraform (infrastructure)
    ↓
Ansible (configuration)
    ↓
Kubernetes (déploiement apps)
    ↓
GitHub Actions (CI/CD)
```

---

## 🏛️ Architecture de Terraform

### Composants Principaux

```
┌─────────────────────────────────────────────────────────┐
│                 TERRAFORM WORKFLOW                       │
│                                                          │
│  ┌──────────────────────────────────────────┐           │
│  │   1. CODE (.tf files)                     │           │
│  │   ├── main.tf        (ressources)         │           │
│  │   ├── variables.tf   (inputs)             │           │
│  │   ├── outputs.tf     (outputs)            │           │
│  │   └── terraform.tfvars (valeurs)          │           │
│  └────────────┬─────────────────────────────┘           │
│               │                                          │
│               ▼                                          │
│  ┌──────────────────────────────────────────┐           │
│  │   2. TERRAFORM CORE                       │           │
│  │   ┌─────────┐  ┌────────┐  ┌─────────┐  │           │
│  │   │ INIT    │→ │ PLAN   │→ │ APPLY   │  │           │
│  │   └─────────┘  └────────┘  └─────────┘  │           │
│  │   - Graph dependencies                    │           │
│  │   - Calculate diff                        │           │
│  │   - Execute changes                       │           │
│  └────────────┬─────────────────────────────┘           │
│               │                                          │
│               ▼                                          │
│  ┌──────────────────────────────────────────┐           │
│  │   3. STATE FILE (terraform.tfstate)       │           │
│  │   - Current infrastructure state          │           │
│  │   - Resource attributes                   │           │
│  │   - Dependencies mapping                  │           │
│  └────────────┬─────────────────────────────┘           │
│               │                                          │
│               ▼                                          │
│  ┌──────────────────────────────────────────┐           │
│  │   4. PROVIDERS (plugins)                  │           │
│  │   ┌────────┐ ┌────────┐ ┌────────┐       │           │
│  │   │ Azure  │ │  AWS   │ │  GCP   │ ...   │           │
│  │   └────────┘ └────────┘ └────────┘       │           │
│  │   - API interactions                      │           │
│  │   - Authentication                        │           │
│  └────────────┬─────────────────────────────┘           │
│               │                                          │
│               ▼                                          │
│  ┌──────────────────────────────────────────┐           │
│  │   5. CLOUD INFRASTRUCTURE                 │           │
│  │   VMs | Networks | Databases | Storage    │           │
│  └──────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

### Le Workflow Terraform

1. **WRITE** : Écrire la configuration en HCL
2. **INIT** : Initialiser le projet et télécharger les providers
3. **PLAN** : Prévisualiser les changements
4. **APPLY** : Appliquer les changements
5. **DESTROY** : (Optionnel) Détruire l'infrastructure

---

## 🔑 Concepts Clés

### 1. Provider

Un **provider** est un plugin qui permet à Terraform d'interagir avec une API (cloud, SaaS, etc.).

```hcl
# Configuration du provider Azure
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
  subscription_id = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
}
```

**Providers populaires :**
- `azurerm` - Azure
- `aws` - Amazon Web Services
- `google` - Google Cloud Platform
- `kubernetes` - Kubernetes
- `github` - GitHub

### 2. Resource

Une **resource** représente un composant d'infrastructure (VM, réseau, base de données, etc.).

```hcl
# Syntaxe générale
resource "TYPE" "NAME" {
  argument1 = value1
  argument2 = value2
}

# Exemple concret
resource "azurerm_resource_group" "main" {
  name     = "production-rg"
  location = "West Europe"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

- **TYPE** : Type de ressource (défini par le provider)
- **NAME** : Nom local dans Terraform (pas le nom dans le cloud)
- **Arguments** : Configuration de la ressource

### 3. State

Le **state** est un fichier JSON (`terraform.tfstate`) qui stocke :

```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "type": "azurerm_resource_group",
      "name": "main",
      "instances": [
        {
          "attributes": {
            "id": "/subscriptions/.../resourceGroups/production-rg",
            "name": "production-rg",
            "location": "westeurope"
          }
        }
      ]
    }
  ]
}
```

**Rôles du state :**
- Mapping entre le code et la réalité
- Performance (cache des attributs)
- Gestion des dépendances
- Collaboration (state partagé)

### 4. Variables

Les **variables** rendent le code paramétrable :

```hcl
# Déclaration
variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

# Utilisation
resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-rg"
  location = "West Europe"
}
```

### 5. Outputs

Les **outputs** exposent des valeurs après le déploiement :

```hcl
output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "ID du Resource Group créé"
}

output "resource_group_location" {
  value = azurerm_resource_group.main.location
}
```

```bash
$ terraform apply
# ...
Outputs:

resource_group_id = "/subscriptions/.../resourceGroups/production-rg"
resource_group_location = "westeurope"
```

### 6. Modules

Un **module** est un ensemble de fichiers `.tf` réutilisables :

```hcl
# modules/network/main.tf
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.address_space]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Utilisation du module
module "production_network" {
  source              = "./modules/network"
  vnet_name           = "prod-vnet"
  address_space       = "10.0.0.0/16"
  location            = "West Europe"
  resource_group_name = "prod-rg"
}
```

### 7. Data Sources

Les **data sources** permettent de référencer des ressources existantes :

```hcl
# Récupérer un Resource Group existant
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

# Utiliser ses propriétés
resource "azurerm_virtual_network" "new" {
  name                = "new-vnet"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
}
```

---

## 🎨 Exemple Complet

Voici un exemple complet montrant tous les concepts :

```hcl
# Configure the Azure Provider
terraform {
  required_version = ">= 1.0"

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

# Variables
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "West Europe"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

# Outputs
output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = "ID of the virtual network"
}
```

---

## 📝 Points Clés à Retenir

1. **Terraform = IaC** : Gérer l'infrastructure avec du code
2. **Déclaratif** : Vous décrivez l'état désiré, pas les étapes
3. **Multi-cloud** : Un seul outil pour tous les providers
4. **State** : Terraform track l'état actuel de l'infrastructure
5. **Plan before apply** : Toujours prévisualiser avant d'exécuter
6. **Modules** : Réutilisabilité et organisation du code
7. **Providers** : Plugins pour interagir avec les APIs

---

## ✅ Quiz de Compréhension

Avant de passer au module suivant, testez vos connaissances :

1. Quelle est la différence entre une approche déclarative et impérative ?
2. Qu'est-ce qu'un provider dans Terraform ?
3. À quoi sert le fichier `terraform.tfstate` ?
4. Pourquoi utiliser `terraform plan` avant `terraform apply` ?
5. Citez 3 avantages de l'Infrastructure as Code

---

## 🚀 Prochaine Étape

Maintenant que vous comprenez les concepts fondamentaux, passons à la pratique !

**➡️ [Module 2 : Installation et Configuration](02-installation.md)**

Dans le prochain module, vous allez :
- Installer Terraform sur votre machine
- Configurer Azure CLI ou AWS CLI
- Créer votre premier fichier Terraform
- Exécuter votre première commande `terraform init`

---

## 📚 Ressources Complémentaires

- [Terraform Documentation](https://www.terraform.io/docs)
- [What is Infrastructure as Code?](https://www.hashicorp.com/resources/what-is-infrastructure-as-code)
- [Terraform vs. Other IaC Tools](https://www.terraform.io/intro/vs)
- [How Terraform Works](https://www.terraform.io/docs/internals/index.html)

---

[⬅️ Retour à l'accueil](../README.md) | [➡️ Module suivant](02-installation.md)
