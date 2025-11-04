# Exemple 07 : Variables

## Objectif
Apprendre à utiliser les **variables** et les **locals** dans Terraform pour rendre le code réutilisable et configurable.

## Concepts clés

### Variables vs Locals

| Caractéristique | Variables | Locals |
|----------------|-----------|---------|
| Définition | Valeurs d'entrée | Valeurs calculées |
| Modification | Peut être passée à l'exécution | Fixe dans le code |
| Usage | Configuration externe | Calculs internes |
| Fichier | `variable.tf` ou `variables.tf` | `locals.tf` |

### Variables
- Permettent de **paramétrer** votre code
- Peuvent avoir des valeurs par défaut
- Peuvent être définies de plusieurs façons (CLI, fichier, environnement)
- Déclarées avec le bloc `variable`

### Locals
- Valeurs **calculées** ou **constantes** locales
- Ne peuvent pas être modifiées de l'extérieur
- Utiles pour éviter la répétition dans le code
- Déclarées avec le bloc `locals`

## Types de variables

Terraform supporte de nombreux types de variables :

### 1. Types simples

```hcl
# String (chaîne de caractères)
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "rg-default"
}

# Number (nombre)
variable "number" {
  type        = number
  description = "A numeric value"
  default     = 1
}

# Bool (booléen)
variable "bool" {
  type        = bool
  description = "A boolean value"
  default     = true
}
```

### 2. Types complexes

```hcl
# List (liste ordonnée)
variable "list" {
  type        = list(string)
  description = "List of strings"
  default     = ["folder1", "folder2", "folder3"]
}

# Map (dictionnaire clé-valeur)
variable "map" {
  type        = map(string)
  description = "Map of strings"
  default     = {
    folder1 = "value1"
    folder2 = "value2"
  }
}

# Set (ensemble non ordonné, valeurs uniques)
variable "set" {
  type        = set(string)
  description = "Set of unique strings"
  default     = ["folder1", "folder2", "folder3"]
}

# Object (structure avec types définis)
variable "triangle" {
  type = object({
    s_one       = number
    s_two       = number
    s_three     = number
    description = string
  })
  default = {
    s_one       = 1
    s_two       = 2
    s_three     = 3
    description = "Triangle"
  }
}

# Tuple (liste avec types spécifiques par position)
variable "tuple" {
  type        = tuple([string, number, bool])
  description = "Tuple with mixed types"
  default     = ["folder1", 1, true]
}

# Any (n'importe quel type)
variable "any" {
  type        = any
  description = "Can be any type"
  default     = "folder1"
}
```

## Utilisation des variables

```hcl
# Dans main.tf
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    firstName = local.first_name
    lastName  = local.last_name
  }
}
```

Syntaxe :
- Variables : `var.<nom_variable>`
- Locals : `local.<nom_local>`

## Locals (valeurs locales)

```hcl
# Dans locals.tf
locals {
  first_name = "Guillaume"
  last_name  = "Soulat"

  # Valeurs calculées
  full_name = "${local.first_name} ${local.last_name}"

  # Références à des variables
  environment_prefix = "${var.environment}-${var.project_name}"
}
```

## Méthodes pour définir des variables

### 1. Valeur par défaut (dans le code)
```hcl
variable "location" {
  default = "francecentral"
}
```

### 2. Via la ligne de commande
```bash
terraform apply -var="resource_group_name=mon-rg"
terraform apply -var="location=westeurope" -var="number=5"
```

### 3. Via fichier .tfvars
```bash
terraform apply -var-file="prod.tfvars"
```

### 4. Via variables d'environnement
```bash
export TF_VAR_resource_group_name="mon-rg"
export TF_VAR_location="westeurope"
terraform apply
```

### 5. Interactivement (si pas de default)
```bash
terraform apply
# Terraform demandera les valeurs manquantes
```

## Ordre de priorité

Terraform applique les variables dans cet ordre (du moins au plus prioritaire) :
1. Valeurs par défaut dans le code
2. Variables d'environnement (`TF_VAR_*`)
3. Fichier `terraform.tfvars`
4. Fichier `*.auto.tfvars`
5. Fichier `-var-file`
6. Arguments `-var` en ligne de commande

## Prérequis

1. Provider Azure configuré
2. Authentification Azure

## Commandes

```bash
# 1. Initialiser
terraform init

# 2. Voir le plan avec les valeurs par défaut
terraform plan

# 3. Appliquer avec valeurs par défaut
terraform apply

# 4. Appliquer avec variables personnalisées
terraform apply -var="resource_group_name=mon-nouveau-rg"

# 5. Utiliser un fichier de variables
terraform apply -var-file="dev.tfvars"

# 6. Détruire
terraform destroy
```

## Validation des variables

Vous pouvez ajouter des validations :

```hcl
variable "location" {
  type        = string
  description = "Azure region"

  validation {
    condition     = contains(["westeurope", "francecentral", "northeurope"], var.location)
    error_message = "Location must be westeurope, francecentral, or northeurope."
  }
}

variable "environment" {
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## Points d'attention

### ⚠️ Mauvaises pratiques (dans cet exemple)

Le code contient volontairement des **mauvaises pratiques** à des fins pédagogiques :

```hcl
# ❌ Mauvais : Hardcoder subscription_id avec default
variable "subscription_id" {
  default = "029b3537-0f24-400b-b624-6058a145efe1"
}

# ❌ Mauvais : Noms trop génériques dans les defaults
variable "storage_account_name" {
  default = "gsobucket"
}
```

### ✅ Bonnes pratiques

```hcl
# ✅ Bon : Pas de default pour les valeurs sensibles
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  sensitive   = true
  # Pas de default !
}

# ✅ Bon : Default générique ou pas de default
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  # Pas de default ou default très générique
}

# ✅ Bon : Default raisonnable pour la location
variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}
```

### 📝 Bonnes pratiques générales

1. **Ne jamais** commiter de valeurs sensibles (subscription_id, passwords, etc.)
2. Utiliser `sensitive = true` pour les variables sensibles
3. Ajouter des descriptions claires
4. Utiliser des validations quand possible
5. Préférer les fichiers `.tfvars` pour les configurations spécifiques
6. Ajouter `.tfvars` dans `.gitignore` (sauf `.tfvars.example`)

## Structure des fichiers

```
07-variables/
├── main.tf          # Configuration principale
├── variables.tf     # Déclaration des variables
├── locals.tf        # Valeurs locales
└── README.md        # Ce fichier

# Fichiers optionnels (non versionnés)
├── terraform.tfvars # Valeurs spécifiques (à ajouter au .gitignore)
└── dev.tfvars       # Valeurs pour l'environnement dev
```

## Exemple de fichier .tfvars

Créez un fichier `terraform.tfvars` :

```hcl
subscription_id      = "votre-subscription-id"
resource_group_name  = "rg-myapp-dev"
storage_account_name = "mystoragedev"
container_name       = "mycontainer"
location             = "westeurope"
```

Puis utilisez-le :
```bash
terraform apply  # Utilise automatiquement terraform.tfvars
```

## Exercices

1. **Créer un fichier tfvars** : Créez `dev.tfvars` avec vos propres valeurs
2. **Ajouter une validation** : Ajoutez une validation sur `location`
3. **Variable sensible** : Marquez `subscription_id` comme `sensitive = true`
4. **Local calculé** : Créez un local qui combine plusieurs variables
5. **Variable conditionnelle** : Utilisez une variable bool pour activer/désactiver une ressource

## Variables sensibles

```hcl
variable "admin_password" {
  type        = string
  description = "Admin password"
  sensitive   = true
  # Pas de default !
}

# Dans les outputs
output "password" {
  value     = var.admin_password
  sensitive = true  # Masqué dans les logs
}
```

## Prochaines étapes

- Utiliser des fichiers tfvars pour différents environnements (voir exemple 08)
- Organiser les variables par modules (voir exemple 13)
- Utiliser des secrets externes (Azure Key Vault)

## Ressources

- [Documentation Terraform - Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Documentation Terraform - Locals](https://www.terraform.io/docs/language/values/locals.html)
- [Variable Validation](https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules)
- [Type Constraints](https://www.terraform.io/docs/language/expressions/type-constraints.html)
