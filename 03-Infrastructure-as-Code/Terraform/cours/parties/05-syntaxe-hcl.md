# 05 - Syntaxe HCL (HashiCorp Configuration Language)

## 📖 Introduction

HCL (HashiCorp Configuration Language) est le langage utilisé par Terraform pour définir l'infrastructure. Il est conçu pour être lisible par l'humain tout en restant facile à analyser par la machine.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre la syntaxe de base de HCL
- ✅ Utiliser les différents types de données
- ✅ Écrire des expressions et des fonctions
- ✅ Utiliser les commentaires efficacement
- ✅ Structurer proprement votre code Terraform

## 📚 Structure de base

### Blocks (Blocs)

Les blocs sont la structure fondamentale de HCL :

```hcl
<BLOCK_TYPE> "<BLOCK_LABEL>" "<BLOCK_LABEL>" {
  # Arguments du bloc
  argument_name = argument_value
}
```

**Exemples** :

```hcl
# Bloc resource avec 2 labels
resource "azurerm_resource_group" "example" {
  name     = "my-rg"
  location = "West Europe"
}

# Bloc terraform sans label
terraform {
  required_version = ">= 1.0"
}

# Bloc provider avec 1 label
provider "azurerm" {
  features {}
}

# Bloc variable avec 1 label
variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}
```

### Arguments

Les arguments assignent une valeur à un nom :

```hcl
resource "azurerm_storage_account" "example" {
  # Argument simple
  name     = "mystorageaccount"

  # Argument avec référence
  location = azurerm_resource_group.example.location

  # Argument avec expression
  account_tier = var.environment == "prod" ? "Premium" : "Standard"
}
```

## 🔤 Types de données

### String (Chaîne de caractères)

```hcl
# String simple
name = "my-resource"

# String multiligne
description = <<-EOT
  Ceci est une description
  sur plusieurs lignes
EOT

# String avec interpolation
greeting = "Hello ${var.name}!"

# Template avec conditions
message = "Environment is ${var.env == "prod" ? "production" : "development"}"
```

### Number (Nombre)

```hcl
# Entier
count = 3

# Décimal
cpu_cores = 2.5

# Opérations mathématiques
total = var.quantity * var.price
```

### Bool (Booléen)

```hcl
# Valeurs booléennes
enabled          = true
public_access    = false
https_only       = true
```

### List (Liste)

```hcl
# Liste de strings
availability_zones = ["1", "2", "3"]

# Liste de nombres
ports = [80, 443, 8080]

# Liste mixte (éviter en pratique)
mixed = ["string", 123, true]

# Accès aux éléments
first_zone = var.availability_zones[0]  # "1"
last_zone  = var.availability_zones[2]  # "3"
```

### Map (Dictionnaire)

```hcl
# Map de strings
tags = {
  environment = "dev"
  project     = "terraform-training"
  owner       = "john.doe"
}

# Map de nombres
sizes = {
  small  = 1
  medium = 2
  large  = 4
}

# Accès aux valeurs
env_tag = var.tags["environment"]  # "dev"
# ou
env_tag = var.tags.environment     # "dev"
```

### Object (Objet)

```hcl
# Objet avec types mixtes
server_config = {
  name     = "web-server"
  count    = 3
  enabled  = true
  tags     = ["web", "frontend"]
}

# Accès aux propriétés
server_name = var.server_config.name
```

### Set (Ensemble)

```hcl
# Set de valeurs uniques
unique_regions = toset(["eu-west", "eu-west", "us-east"])
# Résultat : ["eu-west", "us-east"]
```

## 💬 Commentaires

```hcl
# Commentaire sur une ligne

// Commentaire alternatif (style C++)

/*
  Commentaire
  sur plusieurs
  lignes
*/

resource "azurerm_resource_group" "example" {
  name     = "my-rg"     # Commentaire inline
  location = "West Europe"

  # TODO: Ajouter plus de tags
  tags = {
    environment = "dev"
  }
}
```

## 🔗 Références

### Référencer des ressources

```hcl
resource "azurerm_resource_group" "main" {
  name     = "my-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  # Référence au nom du RG
  resource_group_name = azurerm_resource_group.main.name

  # Référence à la location du RG
  location = azurerm_resource_group.main.location

  # Référence à l'ID complet
  # id = azurerm_resource_group.main.id
}
```

**Syntaxe** : `<TYPE>.<NAME>.<ATTRIBUTE>`

### Référencer des variables

```hcl
variable "environment" {
  default = "dev"
}

resource "azurerm_resource_group" "example" {
  name = "rg-${var.environment}"
  # Résultat : "rg-dev"
}
```

**Syntaxe** : `var.<NAME>`

### Référencer des outputs locaux

```hcl
locals {
  common_tags = {
    managed_by = "terraform"
    project    = "demo"
  }
}

resource "azurerm_resource_group" "example" {
  name     = "my-rg"
  location = "West Europe"
  tags     = local.common_tags
}
```

**Syntaxe** : `local.<NAME>`

### Référencer des data sources

```hcl
data "azurerm_subscription" "current" {}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
```

**Syntaxe** : `data.<TYPE>.<NAME>.<ATTRIBUTE>`

## 🔧 Expressions

### Opérateurs arithmétiques

```hcl
# Addition
total = var.base_price + var.tax

# Soustraction
remaining = var.total - var.used

# Multiplication
total_cost = var.quantity * var.unit_price

# Division
average = var.total / var.count

# Modulo
is_even = var.number % 2 == 0
```

### Opérateurs de comparaison

```hcl
# Égalité
is_prod = var.environment == "production"

# Inégalité
is_not_dev = var.environment != "dev"

# Comparaisons numériques
is_large = var.size > 100
is_small = var.size < 10
is_valid = var.age >= 18 && var.age <= 65
```

### Opérateurs logiques

```hcl
# ET logique
is_valid = var.enabled && var.configured

# OU logique
needs_action = var.is_critical || var.is_urgent

# NON logique
is_disabled = !var.enabled
```

### Opérateur ternaire (condition)

```hcl
# Syntaxe : condition ? valeur_si_vrai : valeur_si_faux

account_tier = var.environment == "production" ? "Premium" : "Standard"

instance_count = var.high_availability ? 3 : 1

location = var.region != "" ? var.region : "West Europe"
```

## 📋 Fonctions intégrées

Terraform fournit de nombreuses fonctions. Voici les plus utilisées :

### Fonctions de strings

```hcl
# lower() - Convertir en minuscules
name_lower = lower("MYNAME")  # "myname"

# upper() - Convertir en majuscules
name_upper = upper("myname")  # "MYNAME"

# title() - Capitaliser
name_title = title("hello world")  # "Hello World"

# format() - Formater une string
message = format("Hello %s, you are %d years old", var.name, var.age)

# join() - Joindre une liste
joined = join(", ", ["a", "b", "c"])  # "a, b, c"

# split() - Diviser une string
parts = split(",", "a,b,c")  # ["a", "b", "c"]

# substr() - Extraire une sous-chaîne
sub = substr("hello", 0, 4)  # "hell"

# replace() - Remplacer
clean = replace("hello-world", "-", "_")  # "hello_world"
```

### Fonctions de collections

```hcl
# length() - Longueur d'une liste/map
count = length(var.availability_zones)

# concat() - Concaténer des listes
all = concat(["a", "b"], ["c", "d"])  # ["a", "b", "c", "d"]

# merge() - Fusionner des maps
all_tags = merge(
  { environment = "dev" },
  { project = "demo" }
)

# keys() - Extraire les clés d'une map
tag_keys = keys({ env = "dev", owner = "john" })  # ["env", "owner"]

# values() - Extraire les valeurs d'une map
tag_values = values({ env = "dev", owner = "john" })  # ["dev", "john"]

# contains() - Vérifier si une liste contient une valeur
has_prod = contains(["dev", "staging", "prod"], "prod")  # true

# element() - Obtenir un élément (avec rotation)
zone = element(var.zones, 5)  # Rotation si index > length
```

### Fonctions numériques

```hcl
# min() - Minimum
smallest = min(5, 12, 9)  # 5

# max() - Maximum
largest = max(5, 12, 9)  # 12

# ceil() - Arrondir au supérieur
rounded_up = ceil(4.3)  # 5

# floor() - Arrondir à l'inférieur
rounded_down = floor(4.7)  # 4
```

### Fonctions de date/heure

```hcl
# timestamp() - Timestamp actuel
current_time = timestamp()  # "2024-01-15T10:30:00Z"

# formatdate() - Formater une date
formatted = formatdate("YYYY-MM-DD", timestamp())  # "2024-01-15"
```

### Fonctions d'encodage

```hcl
# base64encode() - Encoder en base64
encoded = base64encode("hello")

# base64decode() - Décoder du base64
decoded = base64decode("aGVsbG8=")  # "hello"

# jsonencode() - Convertir en JSON
json_string = jsonencode({ name = "test", value = 123 })

# jsondecode() - Parser du JSON
data = jsondecode("{\"name\":\"test\"}")
```

### Fonctions de fichiers

```hcl
# file() - Lire un fichier
content = file("${path.module}/config.txt")

# fileexists() - Vérifier si un fichier existe
exists = fileexists("${path.module}/config.txt")

# templatefile() - Template avec variables
rendered = templatefile("${path.module}/template.tpl", {
  name = "John"
  age  = 30
})
```

## 🎨 Expressions complexes

### For expressions (boucles)

```hcl
# Transformer une liste
upper_names = [for name in var.names : upper(name)]

# Filtrer une liste
large_sizes = [for s in var.sizes : s if s > 100]

# Transformer un map
upper_tags = { for k, v in var.tags : k => upper(v) }

# Créer un map depuis une liste
name_map = { for idx, name in var.names : idx => name }
```

### Splat expressions

```hcl
# Extraire un attribut de toutes les instances
all_ids = azurerm_storage_account.example[*].id

# Équivalent à :
all_ids = [
  for s in azurerm_storage_account.example : s.id
]
```

## 📦 Locals (variables locales)

```hcl
locals {
  # Valeurs calculées
  resource_prefix = "${var.environment}-${var.project}"

  # Tags communs
  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    created_at  = timestamp()
  }

  # Logique conditionnelle
  instance_type = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B2s"

  # Compositions complexes
  storage_name = lower(replace("${local.resource_prefix}-storage", "/[^a-z0-9]/", ""))
}

# Utilisation
resource "azurerm_resource_group" "example" {
  name     = "${local.resource_prefix}-rg"
  location = "West Europe"
  tags     = local.common_tags
}
```

## 🎯 Exemples pratiques

### Exemple 1 : Nommage cohérent

```hcl
locals {
  name_prefix = "${var.environment}-${var.project}-${var.region}"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.region
}

resource "azurerm_storage_account" "data" {
  name                = lower(replace("${local.name_prefix}st", "/[^a-z0-9]/", ""))
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}
```

### Exemple 2 : Tags dynamiques

```hcl
locals {
  base_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project
  }

  resource_tags = merge(
    local.base_tags,
    {
      resource_type = "storage"
      backup        = var.environment == "prod" ? "enabled" : "disabled"
    }
  )
}

resource "azurerm_storage_account" "example" {
  # ... autres arguments ...
  tags = local.resource_tags
}
```

### Exemple 3 : Configuration conditionnelle

```hcl
locals {
  is_production = var.environment == "production"

  storage_config = {
    account_tier             = local.is_production ? "Premium" : "Standard"
    account_replication_type = local.is_production ? "GRS" : "LRS"
    enable_https_only        = true
    min_tls_version          = local.is_production ? "TLS1_2" : "TLS1_1"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = local.storage_config.account_tier
  account_replication_type = local.storage_config.account_replication_type
  enable_https_traffic_only = local.storage_config.enable_https_only
  min_tls_version          = local.storage_config.min_tls_version
}
```

## ✅ Bonnes pratiques

### 1. Utilisez des noms explicites

```hcl
# ❌ Mauvais
resource "azurerm_resource_group" "rg1" {
  name = "rg"
}

# ✅ Bon
resource "azurerm_resource_group" "application_main" {
  name = "rg-myapp-prod-westeurope"
}
```

### 2. Commentez votre code

```hcl
# ✅ Bon
# This storage account is used for application logs
# Retention: 30 days
# Backup: Enabled in production only
resource "azurerm_storage_account" "logs" {
  # ...
}
```

### 3. Utilisez locals pour la logique complexe

```hcl
# ✅ Bon - Logique dans locals
locals {
  should_enable_backup = var.environment == "prod" && var.backup_enabled
}

resource "azurerm_backup_policy" "example" {
  count = local.should_enable_backup ? 1 : 0
  # ...
}
```

### 4. Formatez toujours votre code

```bash
# Formatter automatiquement
terraform fmt

# Vérifier le formatage
terraform fmt -check
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ La structure des blocs HCL
- ✅ Les types de données (string, number, bool, list, map, object)
- ✅ Les références entre ressources
- ✅ Les expressions et opérateurs
- ✅ Les fonctions intégrées de Terraform
- ✅ Les locals pour la logique complexe
- ✅ Les bonnes pratiques de syntaxe

## ➡️ Prochaine étape

Maintenant que vous maîtrisez la syntaxe HCL, approfondissons les **Providers et Resources** pour créer des infrastructures plus complexes.

**Prochain module** : [06 - Providers et Resources](./06-providers-resources.md)

---

🎓 Excellent ! Vous maîtrisez maintenant la syntaxe HCL. Passons aux providers et resources !
