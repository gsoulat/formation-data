# Module 4 : Variables et Outputs

> **Durée : 1 heure**
>
> Rendez votre code Terraform flexible et réutilisable

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Déclarer et utiliser des variables dans Terraform
- ✅ Maîtriser les différents types de variables (string, number, bool, list, map, object)
- ✅ Définir des valeurs par défaut et des validations
- ✅ Utiliser des fichiers `.tfvars` pour fournir des valeurs
- ✅ Créer des outputs pour exposer des informations
- ✅ Gérer des données sensibles
- ✅ Créer des configurations multi-environnements (dev/staging/prod)

---

## 📦 Pourquoi Utiliser des Variables ?

Sans variables, votre code est **rigide** :

```hcl
# ❌ Code en dur - pas flexible
resource "azurerm_resource_group" "main" {
  name     = "rg-prod-westeurope"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-prod"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "rg-prod-westeurope"
}
```

**Problèmes :**
- ❌ Duplication de valeurs
- ❌ Difficile à adapter pour d'autres environnements
- ❌ Modifications manuelles error-prone
- ❌ Impossible de réutiliser le code

Avec variables, votre code devient **flexible** :

```hcl
# ✅ Code paramétrable - réutilisable
variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "West Europe"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}-${replace(lower(var.location), " ", "")}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}
```

**Avantages :**
- ✅ DRY (Don't Repeat Yourself)
- ✅ Réutilisable pour dev, staging, prod
- ✅ Centralisé et maintenable
- ✅ Validation des valeurs

---

## 🔤 Déclaration de Variables

### Syntaxe de Base

```hcl
variable "NOM_VARIABLE" {
  type        = TYPE
  description = "Description de la variable"
  default     = VALEUR_PAR_DEFAUT
  sensitive   = true/false
  validation {
    # Règles de validation
  }
}
```

### Exemple Simple

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Nom de l'environnement (dev, staging, prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Région Azure pour les ressources"
  default     = "West Europe"
}

variable "instance_count" {
  type        = number
  description = "Nombre d'instances à créer"
  default     = 1
}
```

### Utilisation des Variables

```hcl
# main.tf
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  count               = var.instance_count
  name                = "vnet-${var.environment}-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}
```

**Syntaxe de référence :** `var.NOM_VARIABLE`

---

## 🎨 Types de Variables

Terraform supporte plusieurs types de données :

### 1. Types Primitifs

#### `string` - Chaîne de Caractères

```hcl
variable "project_name" {
  type        = string
  description = "Nom du projet"
  default     = "my-app"
}

# Utilisation
resource "azurerm_resource_group" "main" {
  name = "${var.project_name}-rg"
}
```

#### `number` - Nombre

```hcl
variable "vm_count" {
  type        = number
  description = "Nombre de VMs à créer"
  default     = 2
}

# Utilisation
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name  = "vm-${count.index}"
  # ...
}
```

#### `bool` - Booléen

```hcl
variable "enable_backup" {
  type        = bool
  description = "Activer les backups automatiques"
  default     = true
}

# Utilisation
resource "azurerm_backup_policy_vm" "policy" {
  count = var.enable_backup ? 1 : 0
  # ...
}
```

### 2. Types Complexes

#### `list` - Liste

```hcl
# Liste de strings
variable "allowed_locations" {
  type        = list(string)
  description = "Régions Azure autorisées"
  default     = ["West Europe", "North Europe", "France Central"]
}

# Utilisation
resource "azurerm_resource_group" "rg" {
  count    = length(var.allowed_locations)
  name     = "rg-${var.allowed_locations[count.index]}"
  location = var.allowed_locations[count.index]
}
```

```hcl
# Liste de nombres
variable "vm_sizes" {
  type        = list(string)
  description = "Tailles de VMs disponibles"
  default     = ["Standard_B1s", "Standard_B2s", "Standard_D2s_v3"]
}
```

#### `map` - Map (Dictionnaire)

```hcl
variable "tags" {
  type        = map(string)
  description = "Tags à appliquer aux ressources"
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "IT"
  }
}

# Utilisation
resource "azurerm_resource_group" "main" {
  name     = "rg-prod"
  location = "West Europe"
  tags     = var.tags
}
```

```hcl
# Map avec des nombres
variable "vm_sizes_by_env" {
  type = map(string)
  default = {
    dev     = "Standard_B1s"
    staging = "Standard_B2s"
    prod    = "Standard_D4s_v3"
  }
}

# Utilisation
resource "azurerm_linux_virtual_machine" "vm" {
  size = var.vm_sizes_by_env[var.environment]
  # ...
}
```

#### `set` - Ensemble (Valeurs Uniques)

```hcl
variable "allowed_ip_addresses" {
  type        = set(string)
  description = "Adresses IP autorisées (valeurs uniques)"
  default     = ["203.0.113.1", "198.51.100.1"]
}
```

#### `object` - Objet (Structure Complexe)

```hcl
variable "vm_config" {
  type = object({
    name          = string
    size          = string
    admin_username = string
    disk_size_gb  = number
  })
  description = "Configuration de la VM"
  default = {
    name          = "my-vm"
    size          = "Standard_B2s"
    admin_username = "azureuser"
    disk_size_gb  = 30
  }
}

# Utilisation
resource "azurerm_linux_virtual_machine" "vm" {
  name               = var.vm_config.name
  size               = var.vm_config.size
  admin_username     = var.vm_config.admin_username

  os_disk {
    disk_size_gb = var.vm_config.disk_size_gb
  }
}
```

#### `tuple` - Tuple (Liste avec Types Mixtes)

```hcl
variable "subnet_config" {
  type        = tuple([string, string, number])
  description = "Configuration subnet : [name, CIDR, subnet_id]"
  default     = ["subnet-web", "10.0.1.0/24", 1]
}
```

### 3. Type `any` (À Éviter)

```hcl
variable "flexible_var" {
  type        = any
  description = "Variable de type flexible (déconseillé)"
}
```

**⚠️ Note :** Évitez `any`, préférez des types explicites pour la clarté et la validation.

---

## 🎯 Fournir des Valeurs aux Variables

Il existe plusieurs façons de définir les valeurs des variables, par ordre de priorité :

### 1. Valeurs par Défaut (Priorité la Plus Faible)

```hcl
# variables.tf
variable "environment" {
  type    = string
  default = "dev"  # Valeur par défaut
}
```

### 2. Fichiers `.tfvars`

**Créer un fichier `terraform.tfvars` :**

```hcl
# terraform.tfvars
environment = "production"
location    = "West Europe"
vm_count    = 3

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
}
```

Terraform charge automatiquement :
- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

**Créer des fichiers pour différents environnements :**

```bash
# dev.tfvars
environment = "dev"
location    = "North Europe"
vm_count    = 1

# prod.tfvars
environment = "prod"
location    = "West Europe"
vm_count    = 5
```

**Utiliser un fichier spécifique :**

```bash
terraform apply -var-file="prod.tfvars"
```

### 3. Variables d'Environnement

```bash
# Les variables d'environnement doivent commencer par TF_VAR_
export TF_VAR_environment="staging"
export TF_VAR_location="France Central"
export TF_VAR_vm_count=2

terraform apply
```

### 4. Option `-var` en Ligne de Commande (Priorité la Plus Haute)

```bash
terraform apply -var="environment=prod" -var="vm_count=10"
```

### Ordre de Priorité (du Plus Faible au Plus Fort)

```
1. Valeur par défaut dans variable {}
2. Variables d'environnement (TF_VAR_*)
3. terraform.tfvars
4. *.auto.tfvars (ordre alphabétique)
5. -var-file (ordre de définition)
6. -var (ordre de définition)
```

---

## ✅ Validation des Variables

Ajoutez des règles de validation pour garantir des valeurs correctes :

### Validation Simple

```hcl
variable "environment" {
  type        = string
  description = "Environnement de déploiement"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}
```

### Validation avec Regex

```hcl
variable "storage_account_name" {
  type        = string
  description = "Nom du Storage Account"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Le nom doit contenir entre 3 et 24 caractères minuscules et chiffres uniquement."
  }
}
```

### Validation de Plage

```hcl
variable "vm_count" {
  type        = number
  description = "Nombre de VMs (1-10)"

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "vm_count doit être entre 1 et 10."
  }
}
```

### Validations Multiples

```hcl
variable "location" {
  type        = string
  description = "Région Azure"

  validation {
    condition = contains([
      "West Europe",
      "North Europe",
      "France Central",
      "UK South"
    ], var.location)
    error_message = "location doit être une région européenne supportée."
  }

  validation {
    condition     = length(var.location) > 0
    error_message = "location ne peut pas être vide."
  }
}
```

---

## 📤 Outputs

Les **outputs** exposent des valeurs après le déploiement.

### Syntaxe de Base

```hcl
output "NOM_OUTPUT" {
  description = "Description de l'output"
  value       = VALEUR
  sensitive   = true/false
}
```

### Exemples d'Outputs

```hcl
# outputs.tf

# Output simple
output "resource_group_name" {
  description = "Nom du Resource Group créé"
  value       = azurerm_resource_group.main.name
}

# Output avec ID de ressource
output "vnet_id" {
  description = "ID du Virtual Network"
  value       = azurerm_virtual_network.main.id
}

# Output avec objet complet
output "vm_details" {
  description = "Détails de la VM"
  value = {
    name       = azurerm_linux_virtual_machine.vm.name
    private_ip = azurerm_linux_virtual_machine.vm.private_ip_address
    public_ip  = azurerm_public_ip.vm_pip.ip_address
  }
}

# Output sensible (ne s'affiche pas dans les logs)
output "admin_password" {
  description = "Mot de passe administrateur"
  value       = random_password.admin.result
  sensitive   = true
}

# Output avec liste
output "subnet_ids" {
  description = "IDs de tous les subnets"
  value       = azurerm_subnet.subnets[*].id
}
```

### Afficher les Outputs

```bash
# Afficher tous les outputs
terraform output

# Afficher un output spécifique
terraform output resource_group_name

# Afficher en JSON
terraform output -json

# Afficher un output sensible
terraform output -raw admin_password
```

### Utiliser les Outputs dans d'Autres Projets

Les outputs peuvent être référencés via **remote state** :

```hcl
# Projet A - outputs.tf
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

# Projet B - main.tf
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    # Configuration du remote state
  }
}

resource "azurerm_subnet" "app" {
  virtual_network_name = data.terraform_remote_state.network.outputs.vnet_id
}
```

---

## 🔒 Variables Sensibles

### Marquer une Variable comme Sensible

```hcl
variable "admin_password" {
  type        = string
  description = "Mot de passe administrateur"
  sensitive   = true  # Ne sera pas affiché dans les logs
}

variable "db_connection_string" {
  type      = string
  sensitive = true
}
```

### Utilisation

```hcl
resource "azurerm_linux_virtual_machine" "vm" {
  # ...
  admin_password = var.admin_password
}
```

**Résultat dans `terraform plan` :**

```
# azurerm_linux_virtual_machine.vm will be created
+ resource "azurerm_linux_virtual_machine" "vm" {
    + admin_password = (sensitive value)
    + admin_username = "azureuser"
    # ...
  }
```

---

## 🏗️ Projet Pratique : Infrastructure Multi-Environnements

Créons une infrastructure flexible pour dev, staging et prod.

### Structure du Projet

```
multi-env/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── dev.tfvars
├── staging.tfvars
├── prod.tfvars
└── .gitignore
```

### provider.tf

```hcl
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
```

### variables.tf

```hcl
variable "environment" {
  type        = string
  description = "Nom de l'environnement"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "location" {
  type        = string
  description = "Région Azure"
  default     = "West Europe"
}

variable "vm_size" {
  type        = string
  description = "Taille de la VM"
  default     = "Standard_B1s"
}

variable "vm_count" {
  type        = number
  description = "Nombre de VMs"
  default     = 1

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "vm_count doit être entre 1 et 10."
  }
}

variable "address_space" {
  type        = string
  description = "CIDR du VNet"
  default     = "10.0.0.0/16"
}

variable "tags" {
  type        = map(string)
  description = "Tags communs"
  default = {
    ManagedBy = "Terraform"
  }
}
```

### main.tf

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}"
  location = var.location

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = azurerm_resource_group.main.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}
```

### outputs.tf

```hcl
output "resource_group_name" {
  description = "Nom du Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID du Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID du Subnet"
  value       = azurerm_subnet.main.id
}

output "environment_info" {
  description = "Informations sur l'environnement"
  value = {
    environment = var.environment
    location    = var.location
    vm_count    = var.vm_count
    vm_size     = var.vm_size
  }
}
```

### dev.tfvars

```hcl
environment   = "dev"
location      = "North Europe"
vm_size       = "Standard_B1s"
vm_count      = 1
address_space = "10.0.0.0/16"

tags = {
  ManagedBy   = "Terraform"
  CostCenter  = "Development"
}
```

### staging.tfvars

```hcl
environment   = "staging"
location      = "West Europe"
vm_size       = "Standard_B2s"
vm_count      = 2
address_space = "10.1.0.0/16"

tags = {
  ManagedBy   = "Terraform"
  CostCenter  = "QA"
}
```

### prod.tfvars

```hcl
environment   = "prod"
location      = "West Europe"
vm_size       = "Standard_D4s_v3"
vm_count      = 5
address_space = "10.2.0.0/16"

tags = {
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
  Compliance  = "Required"
}
```

### Déploiement

```bash
# Déployer en Dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Déployer en Staging
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"

# Déployer en Prod
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

---

## 💡 Fonctions Utiles avec Variables

### Interpolation

```hcl
resource "azurerm_resource_group" "main" {
  name = "${var.project}-${var.environment}-rg"
}
```

### Fonctions de String

```hcl
# Lowercase
name = lower(var.environment)  # "PROD" → "prod"

# Uppercase
name = upper(var.environment)  # "dev" → "DEV"

# Replace
name = replace(var.location, " ", "-")  # "West Europe" → "West-Europe"

# Trim
name = trim(var.input, " ")
```

### Fonctions de Collection

```hcl
# Length
count = length(var.subnet_names)  # Nombre d'éléments

# Contains
condition = contains(var.allowed_regions, var.location)

# Merge (pour maps)
tags = merge(var.common_tags, var.env_tags)

# Concat (pour lists)
all_ips = concat(var.public_ips, var.private_ips)
```

### Fonctions de Réseau

```hcl
# Calculer un sous-réseau
address_prefix = cidrsubnet("10.0.0.0/16", 8, 1)  # "10.0.1.0/24"
```

---

## 📝 Points Clés à Retenir

1. **Variables** : Paramétrez votre code pour le rendre réutilisable
2. **Types** : Utilisez des types explicites (string, number, bool, list, map, object)
3. **Validation** : Validez les valeurs pour éviter les erreurs
4. **tfvars** : Utilisez des fichiers .tfvars pour différents environnements
5. **Outputs** : Exposez les informations importantes après le déploiement
6. **Sensible** : Marquez les données sensibles avec `sensitive = true`
7. **Priorité** : `-var` > `-var-file` > terraform.tfvars > default

---

## ✅ Quiz de Compréhension

1. Quelle est la différence entre une variable de type `list` et `set` ?
2. Comment valider qu'une variable ne peut prendre que certaines valeurs ?
3. Quel est l'ordre de priorité pour définir les valeurs des variables ?
4. Comment afficher un output sensible ?
5. Pourquoi utiliser des fichiers .tfvars séparés pour chaque environnement ?

---

## 🚀 Prochaine Étape

Vous maîtrisez maintenant les variables et outputs ! Il est temps de créer des ressources cloud complètes.

**➡️ [Module 5 : Créer des Ressources Cloud](05-ressources-cloud.md)**

Dans le prochain module, vous allez :
- Déployer des VMs, réseaux, bases de données sur Azure
- Déployer des EC2, VPC, RDS sur AWS
- Gérer les dépendances entre ressources
- Utiliser des data sources
- Créer une application 3-tier complète

---

## 📚 Ressources Complémentaires

- [Input Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Output Values](https://www.terraform.io/docs/language/values/outputs.html)
- [Variable Validation](https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules)
- [Built-in Functions](https://www.terraform.io/docs/language/functions/index.html)

---

[⬅️ Module précédent](03-premier-projet.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](05-ressources-cloud.md)
