# Exemple 02 : Feature Flag (Count conditionnel)

## Objectif
Utiliser **count** avec une condition pour activer/désactiver des ressources (feature flag).

## Concept : Count conditionnel

`count` peut être utilisé avec une expression ternaire pour créer ou non une ressource :

```hcl
resource "azurerm_resource" "example" {
  count = var.enabled ? 1 : 0
  # ...
}
```

- Si `var.enabled == true` → count = 1 → ressource créée
- Si `var.enabled == false` → count = 0 → ressource non créée

## Pattern Feature Flag

```hcl
locals {
  deployContainer = true  # Feature flag
}

resource "azurerm_storage_container" "container" {
  count = local.deployContainer ? 1 : 0
  # ...
}
```

## Cas d'usage

1. **Environnement** : Créer certaines ressources seulement en prod
2. **Feature toggle** : Activer/désactiver des fonctionnalités
3. **Migration** : Basculer progressivement vers de nouvelles ressources
4. **Développement** : Désactiver des ressources coûteuses en dev

## Exemples pratiques

### 1. Backup selon l'environnement

```hcl
variable "environment" {
  type = string
}

resource "azurerm_backup_vault" "backup" {
  count = var.environment == "prod" ? 1 : 0
  # ...
}
```

### 2. Monitoring optionnel

```hcl
variable "enable_monitoring" {
  type    = bool
  default = false
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  count = var.enable_monitoring ? 1 : 0
  # ...
}
```

### 3. Multi-région pour la prod

```hcl
resource "azurerm_resource_group" "rg_backup" {
  count    = var.environment == "prod" ? 1 : 0
  name     = "rg-backup"
  location = "northeurope"
}
```

## Accès aux ressources conditionnelles

Avec count conditionnel, la ressource est soit une liste vide `[]`, soit `[ressource]` :

```hcl
# ❌ Incorrect - peut échouer si count = 0
output "container_name" {
  value = azurerm_storage_container.container.name
}

# ✅ Correct - utilise l'index
output "container_name" {
  value = length(azurerm_storage_container.container) > 0 ? azurerm_storage_container.container[0].name : null
}

# ✅ Alternative avec try
output "container_name" {
  value = try(azurerm_storage_container.container[0].name, null)
}
```

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars

# 2. Initialiser
terraform init

# 3. Appliquer avec feature activé
terraform apply -var-file="dev.tfvars"

# 4. Modifier le local deployContainer à false
# et voir le plan
terraform plan -var-file="dev.tfvars"

# 5. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Multiple conditions

```hcl
locals {
  # Créer seulement si prod ET backup activé
  create_backup = var.environment == "prod" && var.enable_backup

  # Créer si dev OU staging
  create_dev_resources = contains(["dev", "staging"], var.environment)
}

resource "azurerm_backup_policy" "policy" {
  count = local.create_backup ? 1 : 0
  # ...
}
```

## Avantages du Feature Flag

✅ Contrôle fin des ressources créées
✅ Facile à activer/désactiver
✅ Utile pour les migrations progressives
✅ Réduit les coûts en dev/test

## Limitations

❌ Syntaxe un peu lourde pour accéder aux ressources
❌ Peut compliquer le code avec trop de conditions
❌ Difficile de déboguer les conditions complexes

## Bonnes pratiques

1. **Nommer clairement** les variables de feature flag
2. **Documenter** pourquoi une ressource est conditionnelle
3. **Utiliser locals** pour les conditions complexes
4. **Tester** avec le flag activé ET désactivé

## Exercices

1. Ajoutez une variable `enable_container` pour contrôler la création
2. Créez une ressource seulement si `var.environment` est "prod" ou "staging"
3. Combinez plusieurs conditions avec `&&` et `||`
4. Créez un output qui gère correctement le cas où count = 0

## Ressources

- [Documentation Terraform - Conditional Expressions](https://www.terraform.io/docs/language/expressions/conditionals.html)
- [Feature Toggles (Feature Flags)](https://martinfowler.com/articles/feature-toggles.html)
