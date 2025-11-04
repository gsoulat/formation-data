# Exemple 13 : Modules

## Objectif
Apprendre à créer et utiliser des **modules Terraform** pour rendre le code réutilisable et maintenable.

## Concepts clés

### Qu'est-ce qu'un Module ?
- Un **module** est un ensemble de fichiers Terraform regroupés dans un répertoire
- Permet de **réutiliser** du code entre plusieurs projets
- Facilite la **maintenance** et la **standardisation**
- Équivalent à une "fonction" ou "bibliothèque" en programmation

### Types de modules
1. **Root module** : Le répertoire principal où vous exécutez Terraform
2. **Child modules** : Modules appelés par le root module
3. **Published modules** : Modules publiés sur le Terraform Registry

### Avantages
✅ **Réutilisabilité** : Écrire une fois, utiliser partout
✅ **Abstraction** : Cacher la complexité
✅ **Standardisation** : Mêmes patterns dans toute l'organisation
✅ **Maintenabilité** : Modifications centralisées
✅ **Testabilité** : Tester des composants isolés

## Structure d'un module

Un module Terraform contient typiquement :

```
module/
├── main.tf ou <nom>.tf    # Ressources principales
├── variables.tf           # Variables d'entrée
├── outputs.tf            # Valeurs de sortie
└── README.md             # Documentation
```

### Exemple de module minimal

```
module/storage/
├── storage.tf      # Ressource Storage Account
├── variables.tf    # Inputs du module
└── outputs.tf      # Outputs du module
```

## Structure de l'exemple 13

```
13-modules/
├── main.tf                    # Root module
├── variables.tf               # Variables du root
├── dev.tfvars                 # Valeurs de dev
└── module/                    # Dossier des modules
    ├── storage/               # Module Storage
    │   ├── storage.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── app_service/           # Module App Service
        ├── app_service.tf
        ├── variables.tf
        └── outputs.tf
```

## Création d'un module

### 1. Module Storage (module/storage/storage.tf)

```hcl
# Ressources du module
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
```

### 2. Variables du module (module/storage/variables.tf)

```hcl
variable "storage_account_name" {
  type        = string
  description = "Nom du storage account"
}

variable "resource_group_name" {
  type        = string
  description = "Nom du resource group"
}

variable "location" {
  type        = string
  description = "Location Azure"
}

variable "container_name" {
  type        = string
  description = "Nom du conteneur"
}
```

### 3. Outputs du module (module/storage/outputs.tf)

```hcl
output "storage_account_id" {
  value       = azurerm_storage_account.sa.id
  description = "ID du storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.sa.name
  description = "Nom du storage account"
}

output "primary_blob_endpoint" {
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  description = "Endpoint du blob storage"
}
```

## Utilisation d'un module

### Dans le root module (main.tf)

```hcl
# Appel du module storage
module "storage" {
  source = "./module/storage"                    # Chemin vers le module

  # Inputs du module
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = "${var.storage_account_name}${random_string.suffix.result}"
  location             = var.location
  container_name       = "${var.container_name}${random_string.suffix.result}"
}

# Appel du module app_service
module "app_service" {
  source = "./module/app_service"                # Chemin vers le module

  # Inputs du module
  app_service_name    = "${var.app_service_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}
```

## Accéder aux outputs d'un module

```hcl
# Dans le root module
output "storage_endpoint" {
  value = module.storage.primary_blob_endpoint
}

output "app_url" {
  value = module.app_service.app_service_url
}
```

Syntaxe : `module.<nom_module>.<nom_output>`

## Sources de modules

### 1. Local (relatif)
```hcl
module "storage" {
  source = "./module/storage"
}
```

### 2. Local (absolu)
```hcl
module "storage" {
  source = "/absolute/path/to/module"
}
```

### 3. Git
```hcl
module "storage" {
  source = "git::https://github.com/org/repo.git//modules/storage?ref=v1.0.0"
}
```

### 4. Terraform Registry
```hcl
module "storage" {
  source  = "Azure/storage/azurerm"
  version = "~> 2.0"
}
```

### 5. HTTP
```hcl
module "storage" {
  source = "https://example.com/modules/storage.zip"
}
```

## Versioning des modules

### Avec Git tags
```hcl
module "storage" {
  source = "git::https://github.com/org/modules.git//storage?ref=v1.2.0"
}
```

### Avec Terraform Registry
```hcl
module "storage" {
  source  = "Azure/storage/azurerm"
  version = "~> 2.0"  # >= 2.0.0 et < 3.0.0
}
```

Opérateurs de version :
- `= 1.0.0` : Version exacte
- `>= 1.0.0` : Supérieur ou égal
- `~> 1.0` : >= 1.0 et < 2.0
- `~> 1.0.0` : >= 1.0.0 et < 1.1.0

## Prérequis

1. Comprendre les bases de Terraform (exemples 01-10)
2. Provider Azure configuré
3. Fichier dev.tfvars avec vos valeurs

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars
# Éditer avec vos valeurs

# 2. Initialiser (télécharge les modules)
terraform init

# 3. Voir le plan
terraform plan -var-file="dev.tfvars"

# 4. Appliquer
terraform apply -var-file="dev.tfvars"

# 5. Voir les outputs des modules
terraform output

# 6. Mettre à jour les modules
terraform get -update

# 7. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Bonnes pratiques pour les modules

### 📝 Structure recommandée

```
module/
├── main.tf             # Ressources principales
├── variables.tf        # Tous les inputs
├── outputs.tf          # Tous les outputs
├── versions.tf         # Versions Terraform/providers
├── README.md           # Documentation
└── examples/           # Exemples d'utilisation
    └── basic/
        └── main.tf
```

### ✅ Bonnes pratiques

1. **Un module = une responsabilité** : Module Storage, Module Network, etc.
2. **Variables bien documentées** : Description, type, validation
3. **Outputs utiles** : Exposer ce dont les utilisateurs ont besoin
4. **README complet** : Comment utiliser, exemples, inputs/outputs
5. **Versions sémantiques** : v1.0.0, v1.1.0, v2.0.0
6. **Variables optionnelles** : Fournir des defaults raisonnables
7. **Pas de provider dans les modules** : Laisser le root module le définir
8. **Tester les modules** : Créer des exemples fonctionnels

### ⚠️ À éviter

❌ Modules trop gros et complexes
❌ Hard-coder des valeurs
❌ Dépendances cachées entre modules
❌ Pas de documentation
❌ Pas de versioning

## Variables avec validation

```hcl
variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }
}
```

## Dépendances entre modules

```hcl
# Module network doit être créé en premier
module "network" {
  source = "./modules/network"
  // ...
}

# Module VM dépend du network
module "vm" {
  source = "./modules/vm"

  subnet_id = module.network.subnet_id  # Dépendance implicite
  // ...
}
```

Terraform détecte automatiquement l'ordre grâce aux références.

## Module avec count

```hcl
module "storage" {
  count  = var.environment == "prod" ? 3 : 1
  source = "./modules/storage"

  storage_account_name = "storage${count.index}"
  // ...
}

# Accès aux outputs
output "storage_endpoints" {
  value = module.storage[*].primary_blob_endpoint
}
```

## Module avec for_each

```hcl
variable "environments" {
  type = map(object({
    location = string
    sku      = string
  }))
  default = {
    dev = {
      location = "westeurope"
      sku      = "Standard"
    }
    prod = {
      location = "northeurope"
      sku      = "Premium"
    }
  }
}

module "storage" {
  for_each = var.environments
  source   = "./modules/storage"

  environment = each.key
  location    = each.value.location
  sku         = each.value.sku
}

# Accès aux outputs
output "storage_endpoints" {
  value = {
    for k, m in module.storage : k => m.primary_blob_endpoint
  }
}
```

## Publier un module

### 1. Structure du repository Git
```
terraform-azurerm-storage/
├── main.tf
├── variables.tf
├── outputs.tf
├── README.md
├── LICENSE
└── examples/
    └── basic/
        └── main.tf
```

### 2. Tag de version
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 3. Utilisation
```hcl
module "storage" {
  source = "git::https://github.com/org/terraform-azurerm-storage.git?ref=v1.0.0"
  // ...
}
```

## Exercices

1. **Créer un module Network** : Créez un module pour gérer VNet et Subnet
2. **Module avec validation** : Ajoutez des validations sur les variables
3. **Module complet** : Ajoutez un README avec exemples
4. **Module versionné** : Créez un repo Git avec tags
5. **Module count** : Créez plusieurs instances d'un module avec count

## Registry public

Terraform Registry : https://registry.terraform.io/browse/modules

Exemples de modules Azure populaires :
- [Azure Network](https://registry.terraform.io/modules/Azure/network/azurerm)
- [Azure VM](https://registry.terraform.io/modules/Azure/compute/azurerm)
- [Azure AKS](https://registry.terraform.io/modules/Azure/aks/azurerm)

## Points d'attention

### ⚠️ Important

- Les modules sont **téléchargés** lors du `terraform init`
- Après modification d'un module, faites `terraform get -update`
- Les **providers** doivent être définis dans le root module
- Les modules locaux sont référencés relativement

### 🔍 Debugging de modules

```bash
# Voir les modules installés
terraform providers

# Réinitialiser les modules
rm -rf .terraform/modules
terraform init

# Voir le graph de dépendances
terraform graph | dot -Tpng > graph.png
```

## Différences module vs ressource

| Aspect | Ressource | Module |
|--------|-----------|--------|
| Scope | Une ressource Azure | Groupe de ressources |
| Réutilisabilité | Non | Oui |
| Abstraction | Faible | Élevée |
| Complexité | Simple | Variable |
| Use case | Ressource unique | Pattern réutilisable |

## Prochaines étapes

- Créer vos propres modules réutilisables
- Publier des modules sur un registry privé
- Utiliser des modules dans CI/CD
- Créer des modules multi-cloud

## Ressources

- [Documentation Terraform - Modules](https://www.terraform.io/docs/language/modules/index.html)
- [Module Development](https://www.terraform.io/docs/language/modules/develop/index.html)
- [Terraform Registry](https://registry.terraform.io/)
- [Module Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)
