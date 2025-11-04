# 13 - Data Sources

## 📖 Introduction

Les **Data Sources** permettent de lire des informations sur l'infrastructure existante sans la gérer. C'est un moyen de référencer des ressources créées en dehors de Terraform ou dans d'autres projets.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre la différence entre resources et data sources
- ✅ Lire des ressources Azure existantes
- ✅ Utiliser des data sources pour référencer des infras externes
- ✅ Combiner data sources et resources

## 📊 Resource vs Data Source

| Resource | Data Source |
|----------|-------------|
| Crée/modifie/détruit | Lit uniquement |
| `resource` block | `data` block |
| Gère le cycle de vie | Pas de gestion |
| `azurerm_resource_group` | `data.azurerm_resource_group` |

## 📖 Syntaxe basique

```hcl
data "<TYPE>" "<NAME>" {
  # Arguments de recherche
  name = "existing-resource"
}

# Utilisation
output "resource_info" {
  value = data.<TYPE>.<NAME>.attribute
}
```

## 🔍 Data Sources Azure courantes

### Subscription actuelle

```hcl
data "azurerm_subscription" "current" {
  # Pas d'arguments nécessaires
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}
```

### Client config (utilisateur connecté)

```hcl
data "azurerm_client_config" "current" {}

output "current_user_id" {
  value = data.azurerm_client_config.current.object_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
```

### Resource Group existant

```hcl
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

# Utiliser dans une resource
resource "azurerm_storage_account" "example" {
  name                = "stexample"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  # ...
}
```

### Virtual Network existant

```hcl
data "azurerm_virtual_network" "existing" {
  name                = "existing-vnet"
  resource_group_name = "existing-rg"
}

# Utiliser les informations
output "vnet_address_space" {
  value = data.azurerm_virtual_network.existing.address_space
}
```

### Subnet existant

```hcl
data "azurerm_subnet" "existing" {
  name                 = "existing-subnet"
  virtual_network_name = "existing-vnet"
  resource_group_name  = "existing-rg"
}

# Créer une VM dans ce subnet
resource "azurerm_network_interface" "example" {
  name                = "nic-example"
  location            = "West Europe"
  resource_group_name = "my-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

### Key Vault existant

```hcl
data "azurerm_key_vault" "existing" {
  name                = "my-keyvault"
  resource_group_name = "security-rg"
}

# Lire un secret
data "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  key_vault_id = data.azurerm_key_vault.existing.id
}

# Utiliser le secret
resource "azurerm_sql_server" "example" {
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
  # ...
}
```

**➡️ Voir l'exemple complet** : `../azure/14-data-source/`

## 🎯 Cas d'usage pratiques

### Cas 1 : Infrastructure partagée

```hcl
# Réseau géré par l'équipe Infra
data "azurerm_virtual_network" "shared" {
  name                = "vnet-shared"
  resource_group_name = "rg-network"
}

data "azurerm_subnet" "app" {
  name                 = "subnet-app"
  virtual_network_name = data.azurerm_virtual_network.shared.name
  resource_group_name  = "rg-network"
}

# Votre application
resource "azurerm_network_interface" "app" {
  # ...
  ip_configuration {
    subnet_id = data.azurerm_subnet.app.id
  }
}
```

### Cas 2 : Secrets centralisés

```hcl
# Key Vault géré par l'équipe Sécurité
data "azurerm_key_vault" "central" {
  name                = "kv-central-secrets"
  resource_group_name = "rg-security"
}

data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.central.id
}

data "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-access-key"
  key_vault_id = data.azurerm_key_vault.central.id
}

# Utiliser les secrets
resource "azurerm_sql_server" "app" {
  administrator_login_password = data.azurerm_key_vault_secret.sql_password.value
  # ...
}
```

### Cas 3 : Multi-projets Terraform

```hcl
# Projet 1 : Infrastructure réseau (managed)
resource "azurerm_virtual_network" "main" {
  name = "vnet-main"
  # ...
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}
```

```hcl
# Projet 2 : Application (utilise le réseau)
data "azurerm_virtual_network" "main" {
  name                = "vnet-main"  # Créé par Projet 1
  resource_group_name = "rg-network"
}

resource "azurerm_subnet" "app" {
  virtual_network_name = data.azurerm_virtual_network.main.name
  # ...
}
```

## 🔄 Data Sources dynamiques

### Filtrer avec for_each

```hcl
variable "subnet_names" {
  default = ["subnet-web", "subnet-app", "subnet-data"]
}

data "azurerm_subnet" "subnets" {
  for_each = toset(var.subnet_names)

  name                 = each.key
  virtual_network_name = "vnet-main"
  resource_group_name  = "rg-network"
}

# Utiliser
output "subnet_ids" {
  value = {
    for k, v in data.azurerm_subnet.subnets : k => v.id
  }
}
```

## ⚠️ Attention aux dérives

### Problème

```hcl
# Terraform gère le RG
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

# ❌ ÉVITER : Data source sur une resource gérée
data "azurerm_resource_group" "main" {
  name = "rg-example"
}
```

**Solution** : Utilisez directement la resource, pas la data source.

```hcl
# ✅ Bon
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  resource_group_name = azurerm_resource_group.main.name  # Référence directe
  # ...
}
```

## 💡 Bonnes pratiques

### 1. Nommer clairement

```hcl
# ✅ Bon : Nom explicite
data "azurerm_resource_group" "existing_shared_rg" {
  name = "rg-shared"
}

# ❌ Moins bon : Nom vague
data "azurerm_resource_group" "rg" {
  name = "rg-shared"
}
```

### 2. Documenter les dépendances externes

```hcl
# Data source for the shared network infrastructure
# Managed by: Network team
# Contact: network-team@company.com
data "azurerm_virtual_network" "shared" {
  name                = "vnet-shared"
  resource_group_name = "rg-network"
}
```

### 3. Valider l'existence

```hcl
data "azurerm_resource_group" "existing" {
  name = "rg-that-may-not-exist"
}

# Terraform échouera si la ressource n'existe pas
# C'est une bonne chose : fail fast!
```

### 4. Utiliser des data sources pour les metadata

```hcl
# Informations sur la région
data "azurerm_subscription" "current" {}

locals {
  location = "West Europe"
  tags = {
    subscription_id = data.azurerm_subscription.current.subscription_id
    tenant_id       = data.azurerm_subscription.current.tenant_id
  }
}
```

## 📚 Data Sources utiles

| Data Source | Usage |
|-------------|-------|
| `azurerm_subscription` | Info subscription |
| `azurerm_client_config` | Info utilisateur connecté |
| `azurerm_resource_group` | RG existant |
| `azurerm_virtual_network` | VNet existant |
| `azurerm_subnet` | Subnet existant |
| `azurerm_key_vault` | Key Vault existant |
| `azurerm_key_vault_secret` | Secret KV |
| `azurerm_storage_account` | Storage existant |
| `azurerm_public_ip` | IP publique existante |

**Documentation complète** : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Les data sources lisent l'infrastructure existante
- ✅ Différence entre resource (gère) et data (lit)
- ✅ Data sources courantes : subscription, client_config, resource_group, vnet
- ✅ Cas d'usage : infra partagée, secrets centralisés, multi-projets
- ✅ Bonnes pratiques : noms explicites, documentation

## ➡️ Prochaine étape

Maintenant que vous savez lire des données externes, découvrons les **Workspaces** pour gérer plusieurs environnements !

**Prochain module** : [14 - Workspaces](./14-workspaces.md)

---

📖 Excellent ! Vous savez lire l'infrastructure existante. Découvrons les workspaces !
