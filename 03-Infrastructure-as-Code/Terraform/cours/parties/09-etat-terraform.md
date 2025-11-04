# 09 - L'état Terraform (State)

## 📖 Introduction

Le fichier **terraform.tfstate** est le cœur du fonctionnement de Terraform. Il contient l'état actuel de votre infrastructure et permet à Terraform de savoir ce qui existe déjà et ce qui doit être modifié.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre le rôle du fichier tfstate
- ✅ Manipuler l'état avec les commandes terraform state
- ✅ Gérer les dérives de configuration
- ✅ Sauvegarder et restaurer l'état
- ✅ Préparer le passage à un backend distant

## 📊 Qu'est-ce que l'état Terraform ?

### Définition

L'**état** (state) est un fichier JSON qui contient :

- 🗃️ Le mapping entre votre code et l'infrastructure réelle
- 🔗 Les IDs des ressources créées
- 📋 Les attributs de chaque ressource
- 🔄 Les dépendances entre ressources
- 📝 Les métadonnées

### Fichiers d'état

```
projet/
├── terraform.tfstate           # État actuel
├── terraform.tfstate.backup    # Sauvegarde de l'état précédent
└── .terraform/
    └── terraform.tfstate        # État temporaire lors des opérations
```

### Exemple de contenu

```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 3,
  "lineage": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "outputs": {
    "resource_group_name": {
      "value": "rg-example",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "azurerm_resource_group",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "/subscriptions/.../resourceGroups/rg-example",
            "location": "westeurope",
            "name": "rg-example",
            "tags": {
              "environment": "dev"
            }
          }
        }
      ]
    }
  ]
}
```

## 🔍 Pourquoi l'état est-il important ?

### 1. Mapping Code ↔ Infrastructure

```hcl
# Code Terraform
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}
```

```
terraform.tfstate contient :
- Nom Terraform : azurerm_resource_group.main
- ID Azure : /subscriptions/.../resourceGroups/rg-example
```

### 2. Performance

Au lieu de scanner toute votre infrastructure Azure à chaque fois, Terraform lit le fichier local (très rapide).

### 3. Collaboration

L'état permet à plusieurs personnes de travailler sur la même infrastructure (avec un backend distant).

### 4. Métadonnées

L'état stocke des informations non visibles dans Azure, comme les dépendances entre ressources.

## 🛠️ Commandes terraform state

### terraform state list

Liste toutes les ressources gérées par Terraform.

```bash
# Lister toutes les ressources
terraform state list

# Exemple de sortie :
# azurerm_resource_group.main
# azurerm_storage_account.example
# azurerm_storage_container.data
```

### terraform state show

Affiche les détails d'une ressource spécifique.

```bash
# Afficher une ressource
terraform state show azurerm_resource_group.main

# Exemple de sortie :
# resource "azurerm_resource_group" "main" {
#     id       = "/subscriptions/.../resourceGroups/rg-example"
#     location = "westeurope"
#     name     = "rg-example"
#     tags     = {
#         "environment" = "dev"
#     }
# }
```

### terraform state mv

Déplace une ressource dans l'état (renommage).

```bash
# Renommer une ressource
terraform state mv \
  azurerm_storage_account.old \
  azurerm_storage_account.new

# Déplacer vers un module
terraform state mv \
  azurerm_storage_account.example \
  module.storage.azurerm_storage_account.example
```

**Cas d'usage** : Refactoring du code sans détruire/recréer les ressources.

### terraform state rm

Retire une ressource de l'état (ne la détruit pas dans Azure).

```bash
# Retirer une ressource de l'état
terraform state rm azurerm_storage_account.example

# La ressource existe toujours dans Azure,
# mais Terraform ne la gère plus
```

**Cas d'usage** :
- Passer la gestion d'une ressource à un autre projet Terraform
- Exclure une ressource créée manuellement

### terraform state pull

Télécharge et affiche l'état actuel (utile avec backend distant).

```bash
# Afficher l'état
terraform state pull

# Sauvegarder l'état localement
terraform state pull > terraform.tfstate.backup
```

### terraform state push

Envoie un état local vers le backend (⚠️ Dangereux).

```bash
# Envoyer un état
terraform state push terraform.tfstate

# ⚠️ À utiliser avec précaution !
```

### terraform state replace-provider

Change le provider d'une ressource.

```bash
# Remplacer le provider
terraform state replace-provider \
  registry.terraform.io/hashicorp/azurerm \
  registry.terraform.io/custom/azurerm
```

**Cas d'usage** : Migration vers un provider forké.

## 🔄 Gérer les dérives de configuration

### Qu'est-ce qu'une dérive ?

Une **dérive** (drift) se produit quand l'infrastructure réelle ne correspond plus au code Terraform.

**Causes** :
- 🖱️ Modifications manuelles dans le portail Azure
- 🤖 Scripts automatiques modifiant les ressources
- 👥 Autre processus modifiant l'infrastructure

### Détecter les dérives

```bash
# Rafraîchir et voir les différences
terraform plan

# Exemple de sortie si dérive détectée :
# ~ resource "azurerm_storage_account" "example" {
#     ~ account_tier = "Standard" -> "Premium"
#   }
#
# Note: Objects have changed outside of Terraform
```

### Résoudre les dérives

#### Option 1 : Accepter le changement (mise à jour du code)

```bash
# Modifier le code pour correspondre à la réalité
vim main.tf

# Appliquer
terraform apply
```

#### Option 2 : Forcer le retour au code

```bash
# Appliquer pour revenir à l'état défini dans le code
terraform apply

# Terraform va "corriger" la dérive
```

#### Option 3 : Ignorer les changements

```hcl
resource "azurerm_storage_account" "example" {
  name         = "stexample"
  account_tier = "Standard"
  # ...

  lifecycle {
    ignore_changes = [
      account_tier,  # Ignorer les changements sur cet attribut
    ]
  }
}
```

## 💾 Sauvegarder et restaurer l'état

### Sauvegarder l'état

```bash
# Sauvegarder l'état
cp terraform.tfstate terraform.tfstate.$(date +%Y%m%d_%H%M%S)

# Ou avec terraform state pull
terraform state pull > state-backup-$(date +%Y%m%d).json
```

### Restaurer l'état

```bash
# Restaurer depuis une sauvegarde
cp terraform.tfstate.20240115_143000 terraform.tfstate

# Vérifier
terraform plan
```

## 🔒 Sécurité de l'état

### ⚠️ Dangers du fichier tfstate

Le fichier `terraform.tfstate` contient des **informations sensibles** :

- 🔐 Mots de passe
- 🔑 Clés d'API
- 🎫 Tokens d'accès
- 📋 Chaînes de connexion

**Exemple** :

```json
{
  "resources": [{
    "type": "azurerm_sql_server",
    "attributes": {
      "administrator_login": "sqladmin",
      "administrator_login_password": "P@ssw0rd123!"  // ⚠️ En clair !
    }
  }]
}
```

### 🛡️ Protéger l'état

#### 1. Ne JAMAIS commiter l'état

```bash
# .gitignore
terraform.tfstate
terraform.tfstate.*
*.backup
```

#### 2. Utiliser un backend distant chiffré

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    # Chiffrement automatique dans Azure Storage
  }
}
```

**➡️ Voir le module** : [15 - Backend distant](./15-backend-distant.md)

#### 3. Limiter l'accès

```bash
# Permissions sur le fichier
chmod 600 terraform.tfstate

# Supprimer après chaque session (avec backend distant)
rm terraform.tfstate
```

## 🔧 Importer des ressources existantes

Si vous avez des ressources Azure créées manuellement, vous pouvez les importer dans Terraform.

### Étape 1 : Créer le bloc resource

```hcl
resource "azurerm_resource_group" "imported" {
  name     = "existing-rg"
  location = "West Europe"
}
```

### Étape 2 : Obtenir l'ID de la ressource

```bash
# Trouver l'ID avec Azure CLI
az group show --name existing-rg --query id --output tsv

# Résultat :
# /subscriptions/xxxx-xxxx-xxxx/resourceGroups/existing-rg
```

### Étape 3 : Importer

```bash
terraform import azurerm_resource_group.imported \
  /subscriptions/xxxx-xxxx-xxxx/resourceGroups/existing-rg
```

### Étape 4 : Ajuster le code

```bash
# Voir la configuration importée
terraform state show azurerm_resource_group.imported

# Ajuster votre code pour correspondre
vim main.tf

# Vérifier
terraform plan  # Devrait afficher "No changes"
```

**➡️ Voir l'exemple complet** : `../azure/11-import/`

## 🎯 Scénarios pratiques

### Scénario 1 : Renommer une ressource

```bash
# 1. Renommer dans le code
# OLD: resource "azurerm_storage_account" "old_name"
# NEW: resource "azurerm_storage_account" "new_name"

# 2. Mettre à jour l'état
terraform state mv \
  azurerm_storage_account.old_name \
  azurerm_storage_account.new_name

# 3. Vérifier
terraform plan  # Devrait afficher "No changes"
```

### Scénario 2 : Diviser un projet en modules

```bash
# 1. Créer le module
mkdir -p modules/network

# 2. Déplacer le code
mv network.tf modules/network/main.tf

# 3. Mettre à jour l'état
terraform state mv \
  azurerm_virtual_network.main \
  module.network.azurerm_virtual_network.main

# 4. Vérifier
terraform plan
```

### Scénario 3 : Récupérer après un état corrompu

```bash
# 1. Restaurer depuis la sauvegarde
cp terraform.tfstate.backup terraform.tfstate

# 2. Vérifier
terraform plan

# 3. Si nécessaire, rafraîchir
terraform refresh

# 4. Appliquer
terraform apply
```

## 💡 Bonnes pratiques

### 1. Ne jamais éditer l'état manuellement

```bash
# ❌ JAMAIS FAIRE ÇA !
vim terraform.tfstate

# ✅ Utiliser les commandes terraform state
terraform state mv ...
terraform state rm ...
```

### 2. Toujours sauvegarder avant une opération

```bash
# ✅ Bon
cp terraform.tfstate terraform.tfstate.backup
terraform state rm ...
```

### 3. Utiliser un backend distant dès que possible

```hcl
# ✅ Bon (production)
terraform {
  backend "azurerm" {
    # Configuration backend
  }
}
```

### 4. Versionner le lock file, pas l'état

```bash
# .gitignore
terraform.tfstate     # ← Ne pas versionner
terraform.tfstate.*

# Versionner
.terraform.lock.hcl   # ← À versionner
```

### 5. Faire des refresh réguliers

```bash
# En dev, vérifier régulièrement les dérives
terraform plan  # Inclut un refresh automatique
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Le fichier tfstate est le cœur de Terraform
- ✅ Il fait le mapping entre le code et l'infrastructure
- ✅ Les commandes terraform state (list, show, mv, rm)
- ✅ Gérer les dérives de configuration
- ✅ Importer des ressources existantes
- ✅ Protéger l'état (ne pas commiter, backend distant)
- ✅ Sauvegarder et restaurer l'état

## ➡️ Prochaine étape

Maintenant que vous maîtrisez l'état Terraform, découvrons comment **gérer les dépendances** entre ressources de manière explicite.

**Prochain module** : [10 - Gestion des dépendances](./10-dependances.md)

---

📊 Excellent ! Vous comprenez maintenant le rôle de l'état. Gérons les dépendances !
