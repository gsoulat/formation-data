# 10 - Gestion des dépendances

## 📖 Introduction

Dans une infrastructure, les ressources dépendent souvent les unes des autres. Terraform gère automatiquement ces dépendances dans la plupart des cas, mais il faut parfois les définir explicitement.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les dépendances implicites et explicites
- ✅ Utiliser `depends_on` correctement
- ✅ Visualiser le graphe de dépendances
- ✅ Éviter les cycles de dépendances
- ✅ Optimiser l'ordre de création des ressources

## 🔗 Dépendances implicites

### Principe

Terraform détecte automatiquement les dépendances quand vous **référencez** un attribut d'une autre ressource.

### Exemple

```hcl
# 1. Resource Group (créé en premier)
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

# 2. Storage Account (créé après le RG)
resource "azurerm_storage_account" "example" {
  name                = "stexample"
  resource_group_name = azurerm_resource_group.main.name  # ← Dépendance implicite
  location            = azurerm_resource_group.main.location
  # ...
}

# 3. Storage Container (créé après le Storage Account)
resource "azurerm_storage_container" "data" {
  name               = "data"
  storage_account_id = azurerm_storage_account.example.id  # ← Dépendance implicite
}
```

**Ordre de création automatique** :
```
1. azurerm_resource_group.main
   ↓
2. azurerm_storage_account.example
   ↓
3. azurerm_storage_container.data
```

### Comment Terraform détecte les dépendances ?

```hcl
# Cette référence crée une dépendance
resource_group_name = azurerm_resource_group.main.name
                      ↑                        ↑      ↑
                    Type                    Nom   Attribut
```

Dès que vous utilisez `resource_type.name.attribute`, Terraform sait qu'il doit créer la ressource référencée en premier.

## ⚙️ Dépendances explicites (depends_on)

### Quand utiliser depends_on ?

Utilisez `depends_on` quand la dépendance n'est **pas visible** dans les références d'attributs.

#### Cas 1 : Permissions et rôles

```hcl
resource "azurerm_storage_account" "example" {
  name                = "stexample"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}

# Assigner un rôle
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  # ⚠️ Sans depends_on, cette ressource pourrait être créée
  # avant que le Storage Account soit complètement prêt
  depends_on = [
    azurerm_storage_account.example
  ]
}
```

#### Cas 2 : Provisioners

```hcl
resource "azurerm_virtual_machine" "web" {
  # ...
}

resource "null_resource" "configure_vm" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx"
    ]
  }

  # Attendre que la VM soit créée ET démarrée
  depends_on = [
    azurerm_virtual_machine.web
  ]
}
```

#### Cas 3 : Ordre métier

```hcl
resource "azurerm_storage_account" "logs" {
  name = "stlogs"
  # ...
}

resource "azurerm_storage_account" "data" {
  name = "stdata"
  # ...
}

# Script de migration qui nécessite les deux storage accounts
resource "null_resource" "migrate_data" {
  provisioner "local-exec" {
    command = "python migrate.py"
  }

  # Attendre que TOUT soit créé
  depends_on = [
    azurerm_storage_account.logs,
    azurerm_storage_account.data
  ]
}
```

### Syntaxe de depends_on

```hcl
resource "azurerm_resource" "example" {
  # Configuration...

  depends_on = [
    azurerm_resource_group.main,           # Ressource simple
    azurerm_storage_account.example,       # Autre ressource
    module.network,                        # Module entier
    module.database.azurerm_sql_server.main # Ressource dans un module
  ]
}
```

**➡️ Voir l'exemple complet** : `../azure/02-depend_on/`

## 📊 Visualiser le graphe de dépendances

### Générer le graphe

```bash
# Générer le graphe au format DOT
terraform graph

# Sauvegarder dans un fichier
terraform graph > graph.dot
```

### Visualiser avec Graphviz

```bash
# Installer Graphviz
# Ubuntu
sudo apt install graphviz

# macOS
brew install graphviz

# Windows
choco install graphviz

# Générer une image
terraform graph | dot -Tsvg > graph.svg

# Ouvrir l'image
open graph.svg  # macOS
xdg-open graph.svg  # Linux
```

### Exemple de graphe

```
┌─────────────────┐
│ Resource Group  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ Storage Account │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│     Container   │
└─────────────────┘
```

## 🚫 Cycles de dépendances

### Qu'est-ce qu'un cycle ?

Un **cycle de dépendances** se produit quand deux ressources dépendent l'une de l'autre.

### Exemple de cycle (❌ Erreur)

```hcl
resource "azurerm_network_security_group" "nsg_a" {
  name                = "nsg-a"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Référence nsg_b
  security_rule {
    source_address_prefix = azurerm_network_security_group.nsg_b.id
  }
}

resource "azurerm_network_security_group" "nsg_b" {
  name                = "nsg-b"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Référence nsg_a ← CYCLE !
  security_rule {
    source_address_prefix = azurerm_network_security_group.nsg_a.id
  }
}
```

**Erreur** :
```
Error: Cycle: azurerm_network_security_group.nsg_a, azurerm_network_security_group.nsg_b
```

### Solution : Briser le cycle

#### Option 1 : Utiliser des ressources séparées

```hcl
resource "azurerm_network_security_group" "nsg_a" {
  name     = "nsg-a"
  # ...
}

resource "azurerm_network_security_group" "nsg_b" {
  name     = "nsg-b"
  # ...
}

# Règles séparées (pas de cycle)
resource "azurerm_network_security_rule" "rule_a_to_b" {
  network_security_group_name = azurerm_network_security_group.nsg_a.name
  source_address_prefix       = azurerm_network_security_group.nsg_b.id
  # ...
}

resource "azurerm_network_security_rule" "rule_b_to_a" {
  network_security_group_name = azurerm_network_security_group.nsg_b.name
  source_address_prefix       = azurerm_network_security_group.nsg_a.id
  # ...
}
```

#### Option 2 : Utiliser create_before_destroy

```hcl
resource "azurerm_resource" "example" {
  # ...

  lifecycle {
    create_before_destroy = true
  }
}
```

## ⚡ Parallélisation

Terraform crée les ressources en **parallèle** quand elles n'ont pas de dépendances entre elles.

### Exemple

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-main"
  location = "West Europe"
}

# Ces 3 ressources seront créées EN PARALLÈLE
# car elles dépendent uniquement du RG, pas entre elles

resource "azurerm_storage_account" "logs" {
  name                = "stlogs"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}

resource "azurerm_storage_account" "data" {
  name                = "stdata"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}

resource "azurerm_storage_account" "backups" {
  name                = "stbackups"
  resource_group_name = azurerm_resource_group.main.name
  # ...
}
```

**Timeline** :
```
0s: Créer RG
    ↓
2s: Créer logs + data + backups EN PARALLÈLE
    ↓
25s: Terminé
```

### Contrôler le parallélisme

```bash
# Limiter à 2 ressources en parallèle
terraform apply -parallelism=2

# Désactiver le parallélisme (1 à la fois)
terraform apply -parallelism=1

# Par défaut : parallelism=10
```

## 🎯 Bonnes pratiques

### 1. Privilégier les dépendances implicites

```hcl
# ✅ Bon (dépendance implicite)
resource "azurerm_storage_account" "example" {
  resource_group_name = azurerm_resource_group.main.name
}

# ⚠️ Moins bon (depends_on inutile)
resource "azurerm_storage_account" "example" {
  resource_group_name = "rg-example"

  depends_on = [
    azurerm_resource_group.main  # Inutile si on référence le nom !
  ]
}
```

### 2. Documenter les depends_on

```hcl
# ✅ Bon
resource "azurerm_role_assignment" "example" {
  # ...

  # Wait for the storage account to be fully ready
  # before assigning permissions
  depends_on = [
    azurerm_storage_account.example
  ]
}
```

### 3. Éviter les dépendances circulaires

```hcl
# ❌ Éviter
resource "a" {
  depends_on = [b]
}
resource "b" {
  depends_on = [a]
}
```

### 4. Utiliser le graphe pour déboguer

```bash
# Visualiser les dépendances
terraform graph | dot -Tsvg > graph.svg

# Identifier les problèmes visuellement
```

### 5. Tester les dépendances

```bash
# Vérifier l'ordre de création
terraform plan

# Observer l'ordre dans les logs
terraform apply

# Exemple :
# azurerm_resource_group.main: Creating...
# azurerm_resource_group.main: Creation complete after 2s
# azurerm_storage_account.example: Creating...
# azurerm_storage_account.example: Still creating... [10s elapsed]
```

## 📋 Tableau récapitulatif

| Type | Quand utiliser | Syntaxe | Exemple |
|------|----------------|---------|---------|
| **Implicite** | Référence d'attribut | `resource.name.attribute` | `azurerm_rg.main.name` |
| **Explicite** | Pas de référence directe | `depends_on = [...]` | Permissions, provisioners |

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Les dépendances implicites (via références)
- ✅ Les dépendances explicites (depends_on)
- ✅ Quand utiliser depends_on
- ✅ Visualiser le graphe de dépendances
- ✅ Éviter les cycles de dépendances
- ✅ La parallélisation des ressources

## ➡️ Prochaine étape

Maintenant que vous maîtrisez les dépendances, découvrons comment **créer plusieurs ressources similaires** avec les boucles !

**Prochain module** : [11 - Les boucles (count, for_each, for)](./11-boucles.md)

---

🔗 Parfait ! Vous comprenez les dépendances. Découvrons les boucles !
