# 17 - Bonnes pratiques

## 📖 Introduction

Ce module regroupe les bonnes pratiques essentielles pour écrire du code Terraform de qualité professionnelle, maintenable et sécurisé.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Écrire du code Terraform sécurisé
- ✅ Optimiser les performances
- ✅ Gérer les secrets correctement
- ✅ Appliquer les principes DRY (Don't Repeat Yourself)
- ✅ Suivre les standards de l'industrie

## 🔒 Sécurité

### 1. Ne jamais commiter de secrets

```hcl
# ❌ JAMAIS FAIRE ÇA !
resource "azurerm_sql_server" "example" {
  administrator_login_password = "P@ssw0rd123!"  # Secret en clair !
}

# ✅ Bon : Utiliser des variables
resource "azurerm_sql_server" "example" {
  administrator_login_password = var.sql_admin_password
}

# ✅ Encore mieux : Key Vault
data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_sql_server" "example" {
  administrator_login_password = data.azurerm_key_vault_secret.sql_password.value
}
```

### 2. Marquer les variables sensibles

```hcl
variable "database_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true  # Ne sera pas affiché dans les logs
}
```

### 3. Utiliser HTTPS uniquement

```hcl
resource "azurerm_storage_account" "example" {
  name                      = "stexample"
  enable_https_traffic_only = true  # ✅ Obligatoire
  min_tls_version           = "TLS1_2"  # ✅ TLS 1.2 minimum
  # ...
}
```

### 4. Activer le chiffrement

```hcl
resource "azurerm_storage_account" "example" {
  name = "stexample"

  # Chiffrement des données au repos
  encryption {
    services {
      blob {
        enabled = true
      }
      file {
        enabled = true
      }
    }
  }
}

resource "azurerm_sql_database" "example" {
  name      = "sqldb-example"
  # Chiffrement transparent (TDE) activé par défaut sur Azure SQL
  transparent_data_encryption_enabled = true
}
```

### 5. Limiter les accès réseau

```hcl
resource "azurerm_storage_account" "example" {
  name = "stexample"

  # Bloquer l'accès public
  allow_blob_public_access = false

  # Firewall réseau
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["203.0.113.0/24"]  # Seulement IPs autorisées
    virtual_network_subnet_ids = [azurerm_subnet.trusted.id]
    bypass                     = ["AzureServices"]
  }
}
```

## 📝 Code propre

### 1. Toujours formater le code

```bash
# Formater tous les fichiers
terraform fmt -recursive

# Vérifier le formatage (CI/CD)
terraform fmt -check -recursive
```

### 2. Valider la syntaxe

```bash
# Valider la configuration
terraform validate

# Dans CI/CD
terraform fmt -check && terraform validate
```

### 3. Nommer clairement

```hcl
# ✅ Bon : Noms descriptifs
resource "azurerm_resource_group" "application_main" {
  name = "rg-myapp-prod-westeurope"
}

resource "azurerm_storage_account" "application_logs" {
  name = "stmyappprodlogs"
}

# ❌ Mauvais : Noms génériques
resource "azurerm_resource_group" "rg1" {
  name = "my-rg"
}

resource "azurerm_storage_account" "st1" {
  name = "storage1"
}
```

### 4. Commenter le code complexe

```hcl
# Subnet delegation for Azure Container Instances
# Required to allow ACI to create network interfaces in this subnet
# See: https://docs.microsoft.com/azure/virtual-network/subnet-delegation-overview
resource "azurerm_subnet" "aci" {
  name                 = "subnet-aci"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.10.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}
```

## 🎯 DRY (Don't Repeat Yourself)

### 1. Utiliser des locals

```hcl
# ❌ Mauvais : Répétition
resource "azurerm_resource_group" "web" {
  name     = "rg-myapp-prod-westeurope"
  location = "West Europe"
  tags = {
    environment = "prod"
    project     = "myapp"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "logs" {
  name     = "stmyappprodlogs"
  location = "West Europe"
  tags = {
    environment = "prod"
    project     = "myapp"
    managed_by  = "terraform"
  }
}

# ✅ Bon : Locals
locals {
  name_prefix = "rg-myapp-${var.environment}"
  common_tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "web" {
  name     = "${local.name_prefix}-web"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "logs" {
  name     = "st${var.project}${var.environment}logs"
  location = var.location
  tags     = local.common_tags
}
```

### 2. Utiliser des modules

```hcl
# ❌ Mauvais : Code dupliqué pour chaque environnement

# ✅ Bon : Module réutilisable
module "network_dev" {
  source = "./modules/network"

  environment = "dev"
  # ...
}

module "network_prod" {
  source = "./modules/network"

  environment = "prod"
  # ...
}
```

### 3. Utiliser des boucles

```hcl
# ❌ Mauvais : Duplication
resource "azurerm_storage_account" "logs" {
  name = "stlogs"
  # ...
}

resource "azurerm_storage_account" "data" {
  name = "stdata"
  # ...
}

resource "azurerm_storage_account" "backups" {
  name = "stbackups"
  # ...
}

# ✅ Bon : for_each
variable "storage_accounts" {
  default = {
    logs    = { tier = "Standard", replication = "LRS" }
    data    = { tier = "Premium",  replication = "GRS" }
    backups = { tier = "Standard", replication = "GRS" }
  }
}

resource "azurerm_storage_account" "storage" {
  for_each = var.storage_accounts

  name                     = "st${each.key}"
  account_tier             = each.value.tier
  account_replication_type = each.value.replication
  # ...
}
```

## ⚡ Performance

### 1. Utiliser des data sources au lieu de ressources

```hcl
# ❌ Moins performant : Créer une resource
resource "azurerm_resource_group" "existing" {
  name     = "existing-rg"
  location = "West Europe"
}

# ✅ Plus performant : Data source (lecture seule)
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}
```

### 2. Limiter le parallélisme si nécessaire

```bash
# Par défaut, Terraform crée 10 ressources en parallèle

# Limiter si API rate limiting
terraform apply -parallelism=2
```

### 3. Utiliser depends_on avec parcimonie

```hcl
# ❌ Mauvais : depends_on inutile (dépendance implicite existe)
resource "azurerm_storage_account" "example" {
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [
    azurerm_resource_group.main  # Inutile !
  ]
}

# ✅ Bon : Seulement quand nécessaire
resource "azurerm_role_assignment" "example" {
  scope = azurerm_storage_account.example.id
  # ...

  depends_on = [
    azurerm_storage_account.example  # Nécessaire !
  ]
}
```

## 🛡️ Résilience

### 1. Utiliser create_before_destroy

```hcl
resource "azurerm_virtual_machine" "web" {
  name = "vm-web"
  # ...

  lifecycle {
    create_before_destroy = true  # Zéro downtime
  }
}
```

### 2. Protéger les ressources critiques

```hcl
resource "azurerm_sql_database" "production" {
  name = "sql-prod"
  # ...

  lifecycle {
    prevent_destroy = true  # Empêche la suppression accidentelle
  }
}
```

### 3. Ignorer les changements externes

```hcl
resource "azurerm_virtual_machine" "example" {
  name = "vm-example"
  # ...

  lifecycle {
    ignore_changes = [
      tags["last_patched"],  # Modifié par un processus externe
      tags["backup_status"]
    ]
  }
}
```

## 📊 Validation

### 1. Valider les entrées

```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string

  validation {
    condition = can(regex("^Standard_[A-Z][0-9]+(m?s?)(_v[0-9]+)?$", var.vm_size))
    error_message = "Invalid VM size format."
  }
}
```

### 2. Utiliser des types stricts

```hcl
# ✅ Bon : Type défini
variable "instance_count" {
  type    = number
  default = 3
}

# ❌ Mauvais : Type non défini
variable "instance_count" {
  default = 3
}
```

## 📋 Checklist bonnes pratiques

### Avant chaque commit

- [ ] `terraform fmt -recursive`
- [ ] `terraform validate`
- [ ] Pas de secrets en clair
- [ ] Variables sensibles marquées `sensitive = true`
- [ ] .gitignore à jour
- [ ] README.md documenté

### Avant chaque apply

- [ ] `terraform plan`
- [ ] Vérifier les ressources créées/modifiées/détruites
- [ ] Vérifier le workspace/environnement
- [ ] Sauvegarder l'état si critique
- [ ] Vérifier les coûts

### Production

- [ ] Backend distant configuré
- [ ] Verrouillage d'état activé
- [ ] Chiffrement activé
- [ ] Accès réseau restreint
- [ ] HTTPS uniquement
- [ ] TLS 1.2+ minimum
- [ ] Logs et monitoring
- [ ] Tags sur toutes les ressources

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Sécurité : secrets, chiffrement, accès réseau
- ✅ Code propre : formatage, validation, nommage
- ✅ DRY : locals, modules, boucles
- ✅ Performance : data sources, parallélisme
- ✅ Résilience : lifecycle, protection
- ✅ Validation : contraintes, types stricts

## ➡️ Prochaine étape

Maintenant que vous connaissez les bonnes pratiques, découvrons comment **tester et valider** votre code Terraform !

**Prochain module** : [18 - Tests et validation](./18-tests-validation.md)

---

✅ Excellent ! Vous écrivez du code de qualité. Testons-le !
