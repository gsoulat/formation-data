# Exemple 04 : For Expressions

## Objectif
Maîtriser les **expressions for** pour transformer des listes et des maps dans Terraform.

## Concept : For Expressions

Les expressions `for` permettent de **transformer** des collections (listes, maps, sets) :

```hcl
# Liste → Liste
[for item in list : upper(item)]

# Map → Map
{for key, value in map : key => upper(value)}

# Map → Liste
[for key, value in map : value]

# Avec condition (filtrage)
[for item in list : item if item != ""]
```

## Syntaxes

### 1. Transformation liste → liste

```hcl
variable "names" {
  default = ["alice", "bob", "charlie"]
}

locals {
  upper_names = [for name in var.names : upper(name)]
  # Résultat : ["ALICE", "BOB", "CHARLIE"]
}
```

### 2. Transformation liste → map

```hcl
locals {
  name_map = {
    for name in var.names :
    name => upper(name)
  }
  # Résultat : {
  #   alice = "ALICE"
  #   bob = "BOB"
  #   charlie = "CHARLIE"
  # }
}
```

### 3. Transformation map → map

```hcl
variable "storage_configs" {
  default = {
    dev  = { tier = "Standard" }
    prod = { tier = "Premium" }
  }
}

locals {
  storage_tiers = {
    for key, config in var.storage_configs :
    key => config.tier
  }
  # Résultat : {
  #   dev = "Standard"
  #   prod = "Premium"
  # }
}
```

### 4. Transformation map → liste

```hcl
locals {
  storage_names = [
    for key, config in var.storage_configs : key
  ]
  # Résultat : ["dev", "prod"]
}
```

## Filtrage avec if

### Liste filtrée

```hcl
variable "numbers" {
  default = [1, 2, 3, 4, 5, 6]
}

locals {
  even_numbers = [
    for num in var.numbers : num
    if num % 2 == 0
  ]
  # Résultat : [2, 4, 6]
}
```

### Map filtrée

```hcl
locals {
  premium_storage = {
    for key, config in var.storage_configs :
    key => config
    if config.tier == "Premium"
  }
  # Résultat : { prod = { tier = "Premium" } }
}
```

## For imbriqué avec flatten

Pour créer toutes les combinaisons possibles :

```hcl
variable "environments" {
  default = ["dev", "prod"]
}

variable "regions" {
  default = ["westeurope", "northeurope"]
}

locals {
  all_combinations = flatten([
    for env in var.environments : [
      for region in var.regions : {
        environment = env
        region      = region
        name        = "${env}-${region}"
      }
    ]
  ])
  # Résultat : [
  #   { environment = "dev", region = "westeurope", name = "dev-westeurope" },
  #   { environment = "dev", region = "northeurope", name = "dev-northeurope" },
  #   { environment = "prod", region = "westeurope", name = "prod-westeurope" },
  #   { environment = "prod", region = "northeurope", name = "prod-northeurope" }
  # ]
}
```

## Exemples pratiques dans cet exemple

### 1. Extraire les noms de storage

```hcl
local.storage_names = [
  for key, config in var.storage_configs :
  "${key}${random_string.suffix.result}"
]
```

### 2. Créer une map d'endpoints

```hcl
local.storage_endpoints = {
  for key, storage in azurerm_storage_account.storage :
  key => storage.primary_blob_endpoint
}
```

### 3. Filtrer les storage Premium

```hcl
local.premium_storage = {
  for key, config in var.storage_configs :
  key => config
  if config.tier == "Premium"
}
```

### 4. Créer des tags à partir d'une liste

```hcl
local.resource_tags = {
  for idx, env in var.environments :
  "environment_${idx}" => env
}
```

### 5. Multiple conditions

```hcl
local.prod_standard_storage = [
  for key, config in var.storage_configs :
  key
  if config.tier == "Standard" && config.environment == "prod"
]
```

## Utilisation dans les ressources

### Avec for_each

```hcl
resource "azurerm_storage_account" "storage" {
  for_each = var.storage_configs

  name     = "${each.key}${random_string.suffix.result}"
  # ...
}
```

### Dans les outputs

```hcl
output "storage_summary" {
  value = {
    for key, storage in azurerm_storage_account.storage :
    key => {
      name     = storage.name
      tier     = storage.account_tier
      endpoint = storage.primary_blob_endpoint
    }
  }
}
```

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars

# 2. Initialiser
terraform init

# 3. Plan - Observer les transformations dans les outputs
terraform plan -var-file="dev.tfvars"

# 4. Appliquer
terraform apply -var-file="dev.tfvars"

# 5. Voir les outputs transformés
terraform output
terraform output storage_names
terraform output premium_storage
terraform output all_container_combinations

# 6. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Fonctions utiles avec for

### flatten

Aplatit une liste de listes :
```hcl
flatten([[1, 2], [3, 4]]) # [1, 2, 3, 4]
```

### keys / values

```hcl
keys(var.storage_configs)   # ["dev", "prod"]
values(var.storage_configs) # [{ tier = "Standard" }, { tier = "Premium" }]
```

### merge

```hcl
merge(map1, map2) # Fusionne deux maps
```

## Cas d'usage

1. **Transformation de données** : Adapter le format des variables
2. **Filtrage** : Sélectionner des éléments selon des critères
3. **Agrégation** : Combiner plusieurs sources de données
4. **Outputs structurés** : Créer des outputs formatés
5. **Combinaisons** : Générer toutes les permutations

## Avantages des for expressions

✅ Très flexible pour transformer les données
✅ Syntaxe concise et lisible
✅ Support du filtrage avec `if`
✅ Peut être imbriqué
✅ Fonctionne avec listes, maps et sets

## Limitations

❌ Syntaxe peut être complexe pour les débutants
❌ For imbriqués difficiles à lire
❌ Pas de break ou continue
❌ Évalué à chaque plan (performance)

## Comparaison avec d'autres langages

### Python
```python
# Python
[name.upper() for name in names if len(name) > 3]

# Terraform
[for name in var.names : upper(name) if length(name) > 3]
```

### JavaScript
```javascript
// JavaScript
names.filter(n => n.length > 3).map(n => n.toUpperCase())

// Terraform
[for name in var.names : upper(name) if length(name) > 3]
```

## Bonnes pratiques

1. **Utiliser locals** pour les transformations complexes
2. **Commenter** les expressions for imbriquées
3. **Tester** avec terraform console :
   ```bash
   terraform console
   > [for i in [1,2,3] : i * 2]
   [2, 4, 6]
   ```
4. **Éviter** trop d'imbrication (max 2 niveaux)

## Exercices

1. Créez une liste des noms de storage en majuscules
2. Filtrez uniquement les storage de l'environnement "dev"
3. Créez une map `{name => tier}` pour tous les storage
4. Générez toutes les combinaisons de 3 listes
5. Créez un output qui transforme les ressources en JSON structuré

## Ressources

- [Documentation Terraform - For Expressions](https://www.terraform.io/docs/language/expressions/for.html)
- [Terraform Console](https://www.terraform.io/docs/cli/commands/console.html)
- [Built-in Functions](https://www.terraform.io/docs/language/functions/index.html)
