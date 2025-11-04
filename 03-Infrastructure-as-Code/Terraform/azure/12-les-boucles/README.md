# Exemple 12 : Les Boucles dans Terraform

## Objectif
Maîtriser tous les types de **boucles** et d'**itérations** disponibles dans Terraform pour créer des infrastructures dynamiques et maintenables.

## Vue d'ensemble

Terraform propose plusieurs mécanismes pour répéter et transformer des ressources :

1. **count** - Créer N ressources identiques
2. **for_each** - Créer des ressources basées sur une collection
3. **for expressions** - Transformer des listes et maps
4. **dynamic blocks** - Générer des blocs répétitifs dans une ressource

## Structure des exemples

```
12-les-boucles/
├── 01-count/             # Count basique (N ressources)
├── 02-feature_flag/      # Count conditionnel (feature flags)
├── 03-for-each/          # For_each avec sets et maps
├── 04-for-expressions/   # Expressions for (transformations)
├── 05-dynamic-blocks/    # Dynamic blocks (blocs répétitifs)
└── README.md            # Ce fichier
```

## Comparaison rapide

| Mécanisme | Niveau | Usage principal | Clé d'accès |
|-----------|--------|-----------------|-------------|
| **count** | Ressource | N copies identiques | Index numérique (0,1,2...) |
| **for_each** | Ressource | Ressources par collection | Clé de la map/set |
| **for expression** | Expression | Transformation de données | N/A (retourne une valeur) |
| **dynamic** | Bloc | Blocs répétitifs | Élément de la collection |

## 01 - Count

**Objectif** : Créer plusieurs ressources identiques

```hcl
resource "azurerm_resource_group" "rg" {
  count    = 3
  name     = "rg-${count.index}"
  location = var.location
}
```

**Résultat** :
- `azurerm_resource_group.rg[0]`
- `azurerm_resource_group.rg[1]`
- `azurerm_resource_group.rg[2]`

**Quand l'utiliser** :
✅ Nombre fixe de ressources identiques
✅ Configuration simple
✅ Index numérique suffisant

**Limitations** :
❌ Réindexation lors de suppressions
❌ Accès par index peu lisible
❌ Difficile de gérer des variations

**[➡️ Voir l'exemple détaillé](./01-count/README.md)**

## 02 - Feature Flag (Count conditionnel)

**Objectif** : Activer/désactiver des ressources avec count

```hcl
locals {
  deployContainer = true  # Feature flag
}

resource "azurerm_storage_container" "container" {
  count = local.deployContainer ? 1 : 0
  # ...
}
```

**Pattern** : `count = condition ? 1 : 0`

**Cas d'usage** :
- Ressources optionnelles par environnement
- Feature toggles
- Migrations progressives
- Contrôle des coûts (désactiver en dev)

**[➡️ Voir l'exemple détaillé](./02-feature_flag/README.md)**

## 03 - For_each

**Objectif** : Créer des ressources basées sur une map ou un set

```hcl
variable "resource_group_names" {
  default = ["app", "data", "network"]
}

resource "azurerm_resource_group" "rg" {
  for_each = toset(var.resource_group_names)

  name     = "rg-${each.key}"
  location = var.location
}
```

**Résultat** :
- `azurerm_resource_group.rg["app"]`
- `azurerm_resource_group.rg["data"]`
- `azurerm_resource_group.rg["network"]`

**Avantage principal** : Pas de réindexation !
- Supprimer "data" ne recrée pas "network"
- Clés explicites et lisibles
- Parfait pour les maps d'objets

**Quand l'utiliser** :
✅ Collections avec clés significatives
✅ Besoin de supprimer des éléments
✅ Ressources avec configurations différentes
✅ Meilleure maintenabilité

**[➡️ Voir l'exemple détaillé](./03-for-each/README.md)**

## 04 - For Expressions

**Objectif** : Transformer des listes et maps

```hcl
# Liste → Liste transformée
locals {
  storage_names = [
    for key, config in var.storage_configs :
    "${key}${random_string.suffix.result}"
  ]
}

# Map → Map transformée
locals {
  storage_endpoints = {
    for key, storage in azurerm_storage_account.storage :
    key => storage.primary_blob_endpoint
  }
}

# Avec filtrage (if)
locals {
  premium_storage = {
    for key, config in var.storage_configs :
    key => config
    if config.tier == "Premium"
  }
}
```

**Syntaxes** :
- `[for item in list : transformation]` → Liste
- `{for key, val in map : key => transformation}` → Map
- `[for item in list : item if condition]` → Filtrage

**Cas d'usage** :
- Transformer le format des données
- Filtrer des collections
- Créer des outputs structurés
- Générer des combinaisons

**[➡️ Voir l'exemple détaillé](./04-for-expressions/README.md)**

## 05 - Dynamic Blocks

**Objectif** : Créer des blocs répétitifs dans une ressource

```hcl
resource "azurerm_network_security_group" "nsg" {
  name                = "my-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Génère plusieurs blocs security_rule
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

**Pattern conditionnel** :
```hcl
dynamic "block_name" {
  for_each = var.enabled ? [1] : []
  content { ... }
}
```

**Cas d'usage** :
- NSG rules, firewall rules
- Access policies (Key Vault, Storage)
- Configuration CORS
- Blocs optionnels (feature flags)

**Quand l'utiliser** :
✅ Blocs répétitifs dans une ressource
✅ Configuration pilotée par variables
✅ Blocs conditionnels

**Quand NE PAS l'utiliser** :
❌ 1-2 blocs statiques simples
❌ Rend le code moins lisible
❌ Pas vraiment nécessaire

**[➡️ Voir l'exemple détaillé](./05-dynamic-blocks/README.md)**

## Arbre de décision

```
Besoin de créer plusieurs éléments ?
│
├─ Ressources entières ?
│  │
│  ├─ Ressources identiques avec nombre fixe ?
│  │  → Utilisez COUNT
│  │
│  ├─ Ressources avec clés significatives ?
│  │  → Utilisez FOR_EACH
│  │
│  └─ Ressources conditionnelles (feature flag) ?
│     → Utilisez COUNT avec condition
│
├─ Blocs dans une ressource ?
│  → Utilisez DYNAMIC BLOCKS
│
└─ Transformer des données ?
   → Utilisez FOR EXPRESSIONS
```

## Exemples combinés

### Exemple complet : Multi-environnement

```hcl
# 1. Variable avec map d'objets
variable "environments" {
  type = map(object({
    location    = string
    sku         = string
    enable_logs = bool
  }))
  default = {
    dev = {
      location    = "westeurope"
      sku         = "Standard"
      enable_logs = false
    }
    prod = {
      location    = "northeurope"
      sku         = "Premium"
      enable_logs = true
    }
  }
}

# 2. For_each pour créer les storage accounts
resource "azurerm_storage_account" "storage" {
  for_each = var.environments

  name                     = "st${each.key}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = each.value.location
  account_tier             = each.value.sku
  account_replication_type = "LRS"

  # 3. Dynamic block conditionnel pour les logs
  dynamic "blob_properties" {
    for_each = each.value.enable_logs ? [1] : []
    content {
      versioning_enabled = true
    }
  }
}

# 4. For expression pour transformer les outputs
output "storage_endpoints" {
  value = {
    for env, storage in azurerm_storage_account.storage :
    env => storage.primary_blob_endpoint
  }
}

# 5. For expression avec filtrage
output "premium_storages" {
  value = [
    for env, config in var.environments :
    env if config.sku == "Premium"
  ]
}
```

## Bonnes pratiques générales

### ✅ À FAIRE

1. **Préférer for_each à count** pour la plupart des cas
2. **Utiliser des clés significatives** (pas juste des nombres)
3. **Documenter** les boucles complexes
4. **Tester** les suppressions d'éléments
5. **Combiner** les mécanismes quand nécessaire
6. **Utiliser locals** pour les transformations complexes
7. **Valider** avec `terraform console`

### ❌ À ÉVITER

1. **Trop de complexité** : Gardez le code lisible
2. **Count pour des maps** : Utilisez for_each
3. **Dynamic partout** : Utilisez seulement si nécessaire
4. **For imbriqués** profonds : Max 2-3 niveaux
5. **Logique dans les ressources** : Mettez-la dans locals

## Tableau récapitulatif

| Besoin | Solution | Exemple |
|--------|----------|---------|
| 3 RG identiques | `count = 3` | 01-count |
| RG seulement en prod | `count = var.env == "prod" ? 1 : 0` | 02-feature_flag |
| RG par nom de liste | `for_each = toset(var.names)` | 03-for-each |
| RG par map de configs | `for_each = var.configs` | 03-for-each |
| Liste des noms de RG | `[for rg in ... : rg.name]` | 04-for-expressions |
| Filtrer RG Premium | `[for k, v in ... : k if v.tier == "Premium"]` | 04-for-expressions |
| Plusieurs NSG rules | `dynamic "security_rule" { for_each = ... }` | 05-dynamic-blocks |
| Bloc CORS optionnel | `dynamic "cors" { for_each = var.enabled ? [1] : [] }` | 05-dynamic-blocks |

## Commandes communes

```bash
# Pour chaque exemple
cd 0X-<nom>/

# Créer la config
cp dev.tfvars.example dev.tfvars
# Éditer dev.tfvars

# Workflow standard
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Tester les transformations
terraform console
> [for i in [1,2,3] : i * 2]
> {for k, v in var.map : k => upper(v)}

# Voir les ressources créées
terraform state list

# Nettoyer
terraform destroy -var-file="dev.tfvars"
```

## Progression suggérée

1. **Commencez par** 01-count (le plus simple)
2. **Comprenez** 02-feature_flag (count conditionnel)
3. **Passez à** 03-for-each (plus flexible)
4. **Maîtrisez** 04-for-expressions (transformations)
5. **Terminez par** 05-dynamic-blocks (le plus avancé)

## Exercices globaux

1. **Migration count → for_each** : Convertissez l'exemple 01 pour utiliser for_each
2. **Combinaison** : Utilisez for_each + dynamic blocks ensemble
3. **Transformation complète** : Créez une infrastructure avec :
   - for_each pour les ressources
   - for expressions pour les outputs
   - dynamic blocks pour les configurations
   - count pour les feature flags
4. **Multi-cloud** : Adaptez ces patterns pour AWS ou GCP
5. **Module** : Créez un module réutilisable avec for_each

## Ressources complémentaires

- [Terraform - Meta-Arguments](https://www.terraform.io/docs/language/meta-arguments/index.html)
- [Terraform - Expressions](https://www.terraform.io/docs/language/expressions/index.html)
- [Terraform - Functions](https://www.terraform.io/docs/language/functions/index.html)
- [Dynamic Blocks Best Practices](https://www.terraform.io/docs/language/expressions/dynamic-blocks.html#best-practices-for-dynamic-blocks)

## Prochaines étapes

Après avoir maîtrisé les boucles, vous pouvez :
- Créer des modules réutilisables (exemple 13)
- Utiliser des workspaces pour multi-environnements (exemple 16)
- Combiner avec des data sources (exemple 14)
- Intégrer dans CI/CD

---

**Note** : Chaque sous-dossier contient son propre README détaillé avec des exemples, exercices et explications approfondies.
