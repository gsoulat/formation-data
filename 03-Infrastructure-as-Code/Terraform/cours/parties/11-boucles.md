# 11 - Les boucles (count, for_each, for)

## 📖 Introduction

Les boucles permettent de créer plusieurs ressources similaires sans dupliquer le code. Terraform offre plusieurs mécanismes : `count`, `for_each`, et les expressions `for`.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Utiliser `count` pour créer N ressources identiques
- ✅ Utiliser `for_each` pour créer des ressources avec des clés
- ✅ Utiliser les expressions `for` pour transformer des données
- ✅ Utiliser les blocs `dynamic` pour générer des sous-blocs
- ✅ Choisir la bonne méthode selon le besoin

## 🔢 count - Créer N ressources

### Principe

`count` crée un nombre défini de ressources identiques ou similaires.

### Exemple basique

```hcl
resource "azurerm_storage_account" "example" {
  count = 3  # Créer 3 storage accounts

  name                = "stexample${count.index}"  # stexample0, stexample1, stexample2
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  account_tier        = "Standard"
  account_replication_type = "LRS"
}

# Accès aux instances :
# azurerm_storage_account.example[0]
# azurerm_storage_account.example[1]
# azurerm_storage_account.example[2]
```

### count.index

```hcl
resource "azurerm_storage_account" "example" {
  count = 3

  name = "stexample${count.index}"  # 0, 1, 2
  # ...

  tags = {
    index = count.index
    name  = "Storage ${count.index + 1}"  # Storage 1, Storage 2, Storage 3
  }
}
```

### count avec variable

```hcl
variable "instance_count" {
  type    = number
  default = 3
}

resource "azurerm_storage_account" "example" {
  count = var.instance_count

  name = "stexample${count.index}"
  # ...
}
```

### count conditionnel (feature flag)

```hcl
variable "enable_backup_storage" {
  type    = bool
  default = false
}

resource "azurerm_storage_account" "backup" {
  count = var.enable_backup_storage ? 1 : 0  # Créer uniquement si true

  name = "stbackup"
  # ...
}

# Accès :
# azurerm_storage_account.backup[0]  (si enabled)
```

### Référencer avec count

```hcl
# Toutes les instances
output "all_storage_ids" {
  value = azurerm_storage_account.example[*].id
}

# Une instance spécifique
output "first_storage_id" {
  value = azurerm_storage_account.example[0].id
}

# Nombre d'instances
output "storage_count" {
  value = length(azurerm_storage_account.example)
}
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/01-count/`

## 🔑 for_each - Créer avec des clés

### Principe

`for_each` crée des ressources basées sur un **map** ou un **set**, avec des clés nommées.

### for_each avec map

```hcl
variable "storage_accounts" {
  type = map(string)
  default = {
    logs    = "stlogs"
    data    = "stdata"
    backups = "stbackups"
  }
}

resource "azurerm_storage_account" "example" {
  for_each = var.storage_accounts

  name                = each.value  # stlogs, stdata, stbackups
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ...

  tags = {
    purpose = each.key  # logs, data, backups
  }
}

# Accès aux instances :
# azurerm_storage_account.example["logs"]
# azurerm_storage_account.example["data"]
# azurerm_storage_account.example["backups"]
```

### each.key et each.value

```hcl
for_each = {
  dev  = "environment-dev"
  prod = "environment-prod"
}

# each.key   = "dev" ou "prod"
# each.value = "environment-dev" ou "environment-prod"
```

### for_each avec set

```hcl
variable "regions" {
  type = set(string)
  default = ["westeurope", "northeurope", "francecentral"]
}

resource "azurerm_resource_group" "regional" {
  for_each = var.regions

  name     = "rg-${each.key}"
  location = each.key  # westeurope, northeurope, francecentral
}
```

### for_each avec objets complexes

```hcl
variable "storage_configs" {
  type = map(object({
    tier        = string
    replication = string
  }))
  default = {
    logs = {
      tier        = "Standard"
      replication = "LRS"
    }
    data = {
      tier        = "Premium"
      replication = "GRS"
    }
  }
}

resource "azurerm_storage_account" "example" {
  for_each = var.storage_configs

  name                     = "st${each.key}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = each.value.tier
  account_replication_type = each.value.replication
}
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/03-for-each/`

## 🔄 Expressions for

### Liste vers liste

```hcl
variable "names" {
  default = ["alice", "bob", "charlie"]
}

locals {
  # Transformer en majuscules
  upper_names = [for name in var.names : upper(name)]
  # Résultat : ["ALICE", "BOB", "CHARLIE"]

  # Ajouter un préfixe
  prefixed_names = [for name in var.names : "user-${name}"]
  # Résultat : ["user-alice", "user-bob", "user-charlie"]
}
```

### Liste vers map

```hcl
variable "users" {
  default = ["alice", "bob", "charlie"]
}

locals {
  # Créer un map
  user_map = { for idx, user in var.users : user => idx }
  # Résultat : { alice = 0, bob = 1, charlie = 2 }
}
```

### Map vers map

```hcl
variable "tags" {
  default = {
    environment = "dev"
    project     = "myapp"
  }
}

locals {
  # Transformer les valeurs
  upper_tags = { for k, v in var.tags : k => upper(v) }
  # Résultat : { environment = "DEV", project = "MYAPP" }
}
```

### Filtrage avec if

```hcl
variable "numbers" {
  default = [1, 2, 3, 4, 5, 6]
}

locals {
  # Filtrer les nombres pairs
  even_numbers = [for n in var.numbers : n if n % 2 == 0]
  # Résultat : [2, 4, 6]
}
```

### Exemple complet

```hcl
variable "storage_accounts" {
  default = {
    logs    = { tier = "Standard", important = false }
    data    = { tier = "Premium",  important = true }
    backups = { tier = "Standard", important = true }
  }
}

locals {
  # Filtrer uniquement les storage accounts importants
  important_storage = {
    for key, config in var.storage_accounts :
    key => config
    if config.important
  }
  # Résultat : { data = {...}, backups = {...} }

  # Liste des noms Premium
  premium_names = [
    for key, config in var.storage_accounts :
    key
    if config.tier == "Premium"
  ]
  # Résultat : ["data"]
}
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/04-for-expressions/`

## 🧩 Blocs dynamic

### Principe

Les blocs `dynamic` génèrent des sous-blocs répétitifs à l'intérieur d'une ressource.

### Exemple : NSG rules

```hcl
variable "security_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    {
      name                       = "allow-http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-https"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

resource "azurerm_network_security_group" "example" {
  name                = "nsg-example"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Générer un security_rule pour chaque élément
  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
```

**➡️ Voir l'exemple complet** : `../azure/12-les-boucles/05-dynamic-blocks/`

## 📊 Comparaison count vs for_each

| Critère | count | for_each |
|---------|-------|----------|
| **Index** | Numérique (0, 1, 2...) | Clés nommées |
| **Accès** | `resource[0]` | `resource["key"]` |
| **Ajout/Suppression** | ⚠️ Peut recréer toutes les ressources | ✅ Ne recréer que la ressource modifiée |
| **Cas d'usage** | N ressources identiques | Ressources avec noms/clés spécifiques |
| **Lisibilité** | Moins lisible | Plus lisible |

### Exemple du problème avec count

```hcl
# Avec count
count = 3
# Crée : [0], [1], [2]

# Si on supprime [1] → Terraform recréé [1] et [2] !
```

```hcl
# Avec for_each
for_each = {
  logs = "..."
  data = "..."
  backups = "..."
}

# Si on supprime "data" → Terraform supprime uniquement "data" ✅
```

## 💡 Bonnes pratiques

### 1. Préférer for_each à count

```hcl
# ✅ Bon (for_each)
resource "azurerm_storage_account" "example" {
  for_each = toset(["logs", "data", "backups"])
  name = "st${each.key}"
}

# ⚠️ Moins bon (count)
resource "azurerm_storage_account" "example" {
  count = 3
  name = "stexample${count.index}"
}
```

### 2. Utiliser count pour les feature flags

```hcl
# ✅ Bon usage de count
resource "azurerm_backup_policy" "example" {
  count = var.enable_backup ? 1 : 0
  # ...
}
```

### 3. Utiliser for pour transformer les données

```hcl
# ✅ Bon
locals {
  storage_ids = [for s in azurerm_storage_account.example : s.id]
}
```

### 4. Ne pas mélanger count et for_each

```hcl
# ❌ Ne pas faire
resource "azurerm_resource" "bad" {
  count    = 3
  for_each = var.map  # ERREUR : Impossible !
}
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ `count` : Créer N ressources avec index numérique
- ✅ `for_each` : Créer des ressources avec clés nommées
- ✅ Expressions `for` : Transformer et filtrer des données
- ✅ Blocs `dynamic` : Générer des sous-blocs
- ✅ Préférer `for_each` à `count` pour la maintenabilité

## ➡️ Prochaine étape

Maintenant que vous maîtrisez les boucles, découvrons comment **organiser et réutiliser le code** avec les modules !

**Prochain module** : [12 - Les modules](./12-modules.md)

---

🔁 Excellent ! Vous savez créer des ressources en masse. Découvrons les modules !
