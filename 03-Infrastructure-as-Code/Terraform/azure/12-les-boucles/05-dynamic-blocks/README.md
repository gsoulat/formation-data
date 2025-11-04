# Exemple 05 : Dynamic Blocks

## Objectif
Utiliser les **dynamic blocks** pour créer des blocs répétitifs à l'intérieur d'une ressource.

## Concept : Dynamic Blocks

Les dynamic blocks permettent de générer plusieurs blocs imbriqués dynamiquement dans une ressource :

```hcl
resource "azurerm_network_security_group" "nsg" {
  # ...

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name     = security_rule.value.name
      priority = security_rule.value.priority
      # ...
    }
  }
}
```

## Syntaxe

```hcl
dynamic "<BLOCK_TYPE>" {
  for_each = <COLLECTION>
  iterator = <ITERATOR_NAME>  # Optionnel, défaut = BLOCK_TYPE
  content {
    # Configuration du bloc
    # Accès via <ITERATOR_NAME>.key et <ITERATOR_NAME>.value
  }
}
```

## Différence avec count/for_each

| Aspect | count/for_each | dynamic |
|--------|----------------|---------|
| Scope | Ressources entières | Blocs dans une ressource |
| Usage | Créer plusieurs ressources | Créer plusieurs blocs |
| Niveau | Racine | Imbriqué |

## Exemple 1 : NSG avec règles dynamiques

### Sans dynamic (répétitif)

```hcl
resource "azurerm_network_security_group" "nsg" {
  # ...

  security_rule {
    name     = "allow-ssh"
    priority = 100
    # ...
  }

  security_rule {
    name     = "allow-https"
    priority = 110
    # ...
  }

  security_rule {
    name     = "allow-http"
    priority = 120
    # ...
  }
}
```

### Avec dynamic (DRY - Don't Repeat Yourself)

```hcl
variable "security_rules" {
  type = list(object({
    name          = string
    priority      = number
    direction     = string
    access        = string
    protocol      = string
    source_port_range = string
    destination_port_range = string
    # ...
  }))
}

resource "azurerm_network_security_group" "nsg" {
  # ...

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

## Exemple 2 : Dynamic conditionnel

```hcl
resource "azurerm_storage_account" "storage" {
  # ...

  # Créer le bloc network_rules seulement si enabled
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action = "Deny"
      bypass         = ["AzureServices"]
      ip_rules       = var.allowed_ips
    }
  }
}
```

**Astuce** : `for_each = var.enabled ? [1] : []`
- Si `true` → liste avec 1 élément → bloc créé
- Si `false` → liste vide → bloc non créé

## Exemple 3 : Dynamic imbriqué

```hcl
resource "azurerm_linux_web_app" "app" {
  # ...

  site_config {
    # Dynamic pour application_stack
    dynamic "application_stack" {
      for_each = var.app_runtime != null ? [var.app_runtime] : []
      content {
        node_version = application_stack.value.node_version
      }
    }

    # Dynamic pour CORS
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
  }
}
```

## Exemple 4 : Key Vault avec access policies

```hcl
resource "azurerm_key_vault" "kv" {
  # ...

  dynamic "access_policy" {
    for_each = var.key_vault_access_policies
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }
}
```

## Iterator personnalisé

Par défaut, l'iterator a le même nom que le bloc. Vous pouvez le changer :

```hcl
dynamic "security_rule" {
  for_each = var.security_rules
  iterator = rule  # Nom personnalisé

  content {
    name     = rule.value.name      # Utilisez 'rule' au lieu de 'security_rule'
    priority = rule.value.priority
  }
}
```

## Cas d'usage

1. **NSG Rules** : Règles de sécurité réseau
2. **Firewall Rules** : Règles de firewall
3. **CORS Configuration** : Configuration CORS conditionnelle
4. **Access Policies** : Policies Key Vault, Storage, etc.
5. **Blocs optionnels** : Feature flags au niveau des blocs

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars
# Personnaliser les règles NSG, CORS, etc.

# 2. Initialiser
terraform init

# 3. Plan - Observer les dynamic blocks générés
terraform plan -var-file="dev.tfvars"

# 4. Appliquer
terraform apply -var-file="dev.tfvars"

# 5. Voir le résumé
terraform output summary

# 6. Modifier les variables et voir le plan
# Exemple : Activer network_rules
terraform plan -var="enable_network_rules=true" -var-file="dev.tfvars"

# 7. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Avantages des dynamic blocks

✅ Évite la répétition (DRY)
✅ Configuration pilotée par des variables
✅ Facile d'ajouter/supprimer des blocs
✅ Blocs conditionnels simples
✅ Meilleure maintenabilité

## Limitations

❌ Syntaxe plus complexe que du code statique
❌ Peut rendre le code moins lisible
❌ Difficile à déboguer
❌ Ne fonctionne que pour les blocs répétitifs

## Quand utiliser dynamic

✅ **Utilisez** quand :
- Vous avez des blocs répétitifs
- Le nombre de blocs dépend de variables
- Vous voulez des blocs conditionnels
- Configuration externe (variables, tfvars)

❌ **N'utilisez PAS** quand :
- Vous avez seulement 1-2 blocs statiques
- La configuration ne change jamais
- Cela rend le code moins lisible

## Bonnes pratiques

1. **Ne pas abuser** : Utilisez seulement si vraiment nécessaire
2. **Documenter** : Expliquez pourquoi le dynamic est utilisé
3. **Nommer clairement** les variables de configuration
4. **Tester** avec différentes configurations
5. **Préférer la simplicité** : Code statique > dynamic si possible

## Pattern : Dynamic conditionnel

Pour créer un bloc optionnel :

```hcl
# Pattern 1 : Variable booléenne
dynamic "block" {
  for_each = var.enabled ? [1] : []
  content { ... }
}

# Pattern 2 : Vérifier null
dynamic "block" {
  for_each = var.config != null ? [var.config] : []
  content { ... }
}

# Pattern 3 : Vérifier longueur liste
dynamic "block" {
  for_each = length(var.items) > 0 ? [1] : []
  content { ... }
}
```

## Exemples de cet exemple

1. **NSG** : 3 règles de sécurité dynamiques
2. **Storage** : Network rules conditionnelles + blob versioning
3. **App Service** : Application stack + CORS conditionnels
4. **Key Vault** : Access policies dynamiques

## Exercices

1. Ajoutez une nouvelle règle NSG dans la variable
2. Activez `enable_network_rules` et testez
3. Ajoutez des CORS allowed origins et observez le plan
4. Créez votre propre dynamic block pour une autre ressource
5. Combinez dynamic avec for expression

## Ressources

- [Documentation Terraform - Dynamic Blocks](https://www.terraform.io/docs/language/expressions/dynamic-blocks.html)
- [When to Use Dynamic Blocks](https://www.terraform.io/docs/language/expressions/dynamic-blocks.html#best-practices-for-dynamic-blocks)
