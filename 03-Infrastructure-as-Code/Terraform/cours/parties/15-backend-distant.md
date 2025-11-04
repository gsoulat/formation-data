# 15 - Backend distant

## 📖 Introduction

Le **backend** est l'endroit où Terraform stocke son état (tfstate). Par défaut, l'état est stocké localement, mais pour la collaboration et la production, il faut un backend distant.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les backends Terraform
- ✅ Configurer un backend Azure (Azure Storage)
- ✅ Migrer l'état local vers un backend distant
- ✅ Collaborer en équipe avec un état partagé
- ✅ Gérer le verrouillage d'état

## 🎯 Pourquoi un backend distant ?

### Problèmes du backend local

| Problème | Impact |
|----------|--------|
| 📁 Fichier local | Pas de partage entre membres de l'équipe |
| 🔒 Pas de verrouillage | Risque de conflits simultanés |
| 🚫 Pas de chiffrement | Secrets en clair sur le disque |
| 💾 Pas de sauvegarde | Perte de données si fichier supprimé |
| 👥 Collaboration impossible | Chacun a son propre état |

### Avantages du backend distant

| Avantage | Bénéfice |
|----------|----------|
| ☁️ Stockage centralisé | Équipe entière synchronisée |
| 🔐 Chiffrement | Secrets protégés |
| 🔒 Verrouillage (locking) | Empêche les modifications simultanées |
| 💾 Sauvegarde automatique | Résilience |
| 📜 Historique des versions | Possibilité de rollback |

## 🗄️ Types de backends

### Backends populaires

| Backend | Provider | Usage |
|---------|----------|-------|
| **azurerm** | Azure Storage | ✅ Recommandé pour Azure |
| **s3** | AWS S3 | Pour AWS |
| **gcs** | Google Cloud Storage | Pour GCP |
| **remote** | Terraform Cloud | SaaS HashiCorp |
| **http** | API HTTP custom | Solutions custom |

## ☁️ Backend Azure Storage

### Architecture

```
┌─────────────┐
│   Équipe    │
│ Terraform   │
└──────┬──────┘
       │
       ↓
┌─────────────────────┐
│ Azure Storage       │
│ ┌─────────────────┐ │
│ │ Container       │ │
│ │ - dev.tfstate   │ │
│ │ - prod.tfstate  │ │
│ └─────────────────┘ │
│                     │
│ + Chiffrement       │
│ + Verrouillage      │
│ + Versioning        │
└─────────────────────┘
```

### Étape 1 : Créer le Storage Account

```bash
# Variables
RESOURCE_GROUP="rg-terraform-state"
LOCATION="westeurope"
STORAGE_ACCOUNT="sttfstate$(openssl rand -hex 4)"  # Nom unique
CONTAINER_NAME="tfstate"

# Créer le Resource Group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Créer le Storage Account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false

# Créer le Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Activer le versioning (recommandé)
az storage account blob-service-properties update \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true

# Afficher les informations
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
```

### Étape 2 : Configurer le backend Terraform

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstateXXXXXXXX"  # Remplacer par votre nom
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"  # Nom du fichier d'état
  }
}
```

### Étape 3 : Initialiser avec le backend

```bash
# Initialiser (migrer l'état local vers le backend)
terraform init

# Terraform demandera : "Do you want to copy existing state to the new backend?"
# Répondre : yes
```

**Résultat** :
```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. Would you like to copy this state to the new
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "azurerm"!
```

### Étape 4 : Vérifier

```bash
# Vérifier que l'état est dans Azure
az storage blob list \
  --account-name sttfstateXXXXXXXX \
  --container-name tfstate \
  --output table \
  --auth-mode login
```

**➡️ Voir l'exemple complet** : `../azure/10-States-backend/`

## 🔒 Verrouillage d'état (State Locking)

### Principe

Le **locking** empêche plusieurs personnes d'exécuter `terraform apply` en même temps.

### Comment ça marche ?

```
Utilisateur A: terraform apply
  ↓
  1. Verrouiller l'état ✅
  2. Lire l'état
  3. Calculer les changements
  4. Appliquer
  5. Déverrouiller l'état ✅

Utilisateur B: terraform apply (en même temps)
  ↓
  1. Tentative de verrouillage ❌
  Erreur: "State is locked by Utilisateur A"
```

### Avec Azure Backend

Le verrouillage est **automatique** avec Azure Storage ! Terraform utilise des blobs pour gérer le lock.

### Forcer le déverrouillage

Si un lock reste bloqué (crash, interruption) :

```bash
# Obtenir l'ID du lock
terraform force-unlock <LOCK_ID>

# Exemple
terraform force-unlock 1234567890abcdef
```

⚠️ **Attention** : Utilisez uniquement si vous êtes SÛR que personne d'autre n'exécute Terraform !

## 🔐 Sécurité du backend

### 1. Authentification

#### Option A : Azure CLI (développement)

```bash
# Se connecter
az login

# Terraform utilise automatiquement ces credentials
terraform init
terraform plan
terraform apply
```

#### Option B : Service Principal (CI/CD)

```bash
# Variables d'environnement
export ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_CLIENT_SECRET="votre-secret"
export ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Terraform utilise ces variables automatiquement
terraform init
```

### 2. Permissions minimales

```bash
# Créer un Service Principal avec permissions limitées
az ad sp create-for-rbac \
  --name "terraform-backend-sp" \
  --role "Storage Blob Data Contributor" \
  --scopes "/subscriptions/xxxx/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/sttfstate"
```

### 3. Chiffrement

```bash
# Activer le chiffrement (activé par défaut sur Azure)
az storage account update \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --encryption-services blob
```

### 4. Accès réseau

```bash
# Limiter l'accès aux IPs autorisées
az storage account network-rule add \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --ip-address "203.0.113.10"

# Bloquer l'accès public
az storage account update \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --default-action Deny
```

## 🏗️ Backends multiples

### Par environnement

```hcl
# backend-dev.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

```hcl
# backend-prod.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod"
    storage_account_name = "sttfstateprod"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Configuration partielle

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    # Configuration partielle
    # Les valeurs seront fournies à l'init
  }
}
```

```bash
# Initialiser avec les valeurs
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=sttfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.tfstate"
```

## 🔄 Migrer entre backends

### Du local vers Azure

```bash
# 1. Ajouter la configuration backend
vim backend.tf

# 2. Initialiser (Terraform propose la migration)
terraform init

# 3. Confirmer la copie
# Enter a value: yes
```

### D'Azure vers un autre Storage

```bash
# 1. Modifier la configuration backend
vim backend.tf

# 2. Reconfigurer
terraform init -reconfigure

# 3. Migrer l'état
terraform init -migrate-state
```

## 💡 Bonnes pratiques

### 1. Un backend par environnement

```
dev.tfstate    → storage account dev
staging.tfstate → storage account staging
prod.tfstate    → storage account prod (différent!)
```

### 2. Activer le versioning

```bash
az storage account blob-service-properties update \
  --enable-versioning true
```

### 3. Sauvegardes régulières

```bash
# Script de sauvegarde
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
terraform state pull > backups/terraform.tfstate.$DATE
```

### 4. Ne jamais commiter backend.tf avec des secrets

```hcl
# ❌ Mauvais
terraform {
  backend "azurerm" {
    storage_account_name = "sttfstate"
    access_key           = "xxxxxx"  # Secret en clair !
  }
}

# ✅ Bon : Utiliser l'authentification Azure CLI ou variables d'env
```

### 5. Documenter le backend

```markdown
# Configuration Backend

## Storage Account
- **Resource Group** : `rg-terraform-state`
- **Storage Account** : `sttfstate12345678`
- **Container** : `tfstate`

## Accès
- Développement : Azure CLI (`az login`)
- CI/CD : Service Principal (variables ARM_*)
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Les backends stockent l'état Terraform
- ✅ Azure Storage est le backend recommandé pour Azure
- ✅ Configuration avec `backend "azurerm"`
- ✅ Verrouillage automatique pour éviter les conflits
- ✅ Sécurité : chiffrement, permissions, authentification
- ✅ Migration d'état entre backends

## ➡️ Prochaine étape

Maintenant que vous avez un backend distant, découvrons comment **organiser votre code** Terraform de manière professionnelle !

**Prochain module** : [16 - Organisation du code](./16-organisation-code.md)

---

🗄️ Parfait ! Votre état est sécurisé et partagé. Organisons le code !
