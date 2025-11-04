# Exemple 03 : For_each

## Objectif
Utiliser **for_each** pour créer plusieurs ressources basées sur une map ou un set.

## Concept : For_each

`for_each` permet de créer des ressources basées sur une collection (map ou set) :

```hcl
resource "azurerm_resource_group" "rg" {
  for_each = toset(var.resource_group_names)

  name     = "rg-${each.key}"
  location = var.location
}
```

### each.key et each.value

- **each.key** : La clé dans la map ou l'élément dans le set
- **each.value** : La valeur (identique à each.key pour un set)

## Différence avec count

| Aspect | count | for_each |
|--------|-------|----------|
| Index | Numérique (0, 1, 2...) | String (clé de la collection) |
| Suppression | Réindexe les ressources | Pas de réindexation |
| Flexibilité | Faible | Élevée |
| Collections | Liste de nombres | Map ou Set |

## Exemple avec Set

```hcl
variable "resource_group_names" {
  type    = list(string)
  default = ["app", "data", "network"]
}

resource "azurerm_resource_group" "rg" {
  for_each = toset(var.resource_group_names)

  name     = "rg-${each.key}"
  location = var.location
}
```

Résultat :
- `azurerm_resource_group.rg["app"]` → rg-app
- `azurerm_resource_group.rg["data"]` → rg-data
- `azurerm_resource_group.rg["network"]` → rg-network

## Exemple avec Map

```hcl
variable "storage_accounts" {
  type = map(object({
    tier        = string
    replication = string
  }))
  default = {
    dev = {
      tier        = "Standard"
      replication = "LRS"
    }
    prod = {
      tier        = "Premium"
      replication = "GRS"
    }
  }
}

resource "azurerm_storage_account" "storage" {
  for_each = var.storage_accounts

  name                     = "st${each.key}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = each.value.tier
  account_replication_type = each.value.replication
}
```

## Accès aux ressources

```hcl
# Accéder à une ressource spécifique
azurerm_resource_group.rg["app"]
azurerm_resource_group.rg["data"]

# Itérer sur toutes les ressources
values(azurerm_resource_group.rg)[*].id

# Dans un output
output "rg_ids" {
  value = {
    for k, rg in azurerm_resource_group.rg :
    k => rg.id
  }
}
```

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars

# 2. Initialiser
terraform init

# 3. Plan
terraform plan -var-file="dev.tfvars"

# 4. Appliquer
terraform apply -var-file="dev.tfvars"

# 5. Voir les ressources avec leurs clés
terraform state list

# 6. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Avantage principal : Pas de réindexation

### Problème avec count

```hcl
# Liste initiale
var.names = ["a", "b", "c"]

# Si on supprime "b"
var.names = ["a", "c"]

# Terraform va :
# - Détruire resource[1] et resource[2]
# - Recréer resource[1] avec "c"
```

### Solution avec for_each

```hcl
# Set initial
var.names = ["a", "b", "c"]

# Si on supprime "b"
var.names = ["a", "c"]

# Terraform va :
# - Détruire seulement resource["b"]
# - Garder resource["a"] et resource["c"] intacts
```

## Conversion de types

### Liste → Set
```hcl
resource "..." "example" {
  for_each = toset(var.my_list)
}
```

### Map → Set (clés uniquement)
```hcl
resource "..." "example" {
  for_each = toset(keys(var.my_map))
}
```

### Liste d'objets → Map
```hcl
locals {
  servers_map = {
    for server in var.servers :
    server.name => server
  }
}

resource "..." "example" {
  for_each = local.servers_map
}
```

## Exemples pratiques

### 1. Multiple Storage Containers

```hcl
variable "containers" {
  type    = set(string)
  default = ["data", "logs", "backups"]
}

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                 = each.key
  storage_account_name = azurerm_storage_account.storage.name
}
```

### 2. Network Security Rules

```hcl
variable "allowed_ports" {
  type = map(object({
    port     = number
    protocol = string
  }))
  default = {
    ssh = {
      port     = 22
      protocol = "Tcp"
    }
    https = {
      port     = 443
      protocol = "Tcp"
    }
  }
}

resource "azurerm_network_security_rule" "rules" {
  for_each = var.allowed_ports

  name                        = "allow-${each.key}"
  priority                    = 100 + index(keys(var.allowed_ports), each.key)
  destination_port_range      = each.value.port
  protocol                    = each.value.protocol
  # ...
}
```

## Avantages de for_each

✅ Pas de réindexation lors de suppressions
✅ Clés explicites (plus lisible)
✅ Parfait pour les maps d'objets
✅ Meilleur pour la maintenance

## Limitations de for_each

❌ Nécessite un map ou set (pas de liste directement)
❌ Les clés doivent être connues avant apply
❌ Syntaxe légèrement plus complexe

## Quand utiliser for_each

- Collections avec des clés significatives
- Besoin de supprimer des éléments du milieu
- Configuration par map d'objets
- Ressources avec des propriétés différentes

## Exercices

1. Créez des storage accounts avec for_each et une map de configurations
2. Supprimez un élément du set et observez le plan (pas de réindexation)
3. Créez des outputs pour chaque ressource créée
4. Convertissez une liste en map avec une expression `for`

## Ressources

- [Documentation Terraform - for_each](https://www.terraform.io/docs/language/meta-arguments/for_each.html)
- [toset function](https://www.terraform.io/docs/language/functions/toset.html)
