# Exemple 10 : Backend distant (Remote State)

## Objectif
Apprendre à configurer un **backend distant** pour stocker le fichier d'état Terraform (`terraform.tfstate`) sur Azure Storage au lieu du disque local.

## Concepts clés

### Qu'est-ce que le State (état) ?
- Le **state** est un fichier JSON qui contient l'état actuel de votre infrastructure
- Terraform l'utilise pour savoir quelles ressources existent déjà
- Par défaut, stocké localement dans `terraform.tfstate`

### Problèmes du state local
❌ **Collaboration difficile** : Chaque développeur a son propre state
❌ **Pas de locking** : Risque de corruption si plusieurs personnes exécutent Terraform en même temps
❌ **Perte de données** : Si le fichier est supprimé, Terraform perd la trace des ressources
❌ **Secrets exposés** : Le state contient des valeurs sensibles en clair

### Backend distant : la solution
✅ **State partagé** : Toute l'équipe utilise le même state
✅ **Locking** : Empêche les exécutions simultanées
✅ **Backup automatique** : Versioning du state
✅ **Sécurisé** : Contrôle d'accès via Azure RBAC

## Types de backends

### 1. Local (par défaut)
```hcl
# Pas besoin de configuration
# State stocké dans ./terraform.tfstate
```

### 2. Azure Storage (recommandé pour Azure)
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "RG-STATES"
    storage_account_name = "remotestates"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### 3. Terraform Cloud
```hcl
terraform {
  backend "remote" {
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}
```

### 4. Autres backends
- **S3** (AWS)
- **GCS** (Google Cloud)
- **Consul**
- **etcd**

## Configuration Azure Backend

### Prérequis

Vous devez créer le Storage Account **avant** de configurer le backend :

```bash
# 1. Créer le Resource Group pour le state
az group create --name RG-STATES --location westeurope

# 2. Créer le Storage Account
az storage account create \
  --name remotestates \
  --resource-group RG-STATES \
  --location westeurope \
  --sku Standard_LRS

# 3. Créer le conteneur
az storage container create \
  --name tfstate \
  --account-name remotestates
```

### Configuration dans Terraform

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.50.0"
    }
  }

  # Backend Azure Storage
  backend "azurerm" {
    resource_group_name  = "RG-STATES"
    storage_account_name = "remotestates"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
  subscription_id = var.subscription_id
}
```

## Migrations de backend

### Migrer de local vers Azure

1. **Ajoutez** la configuration backend dans `main.tf`
2. **Réinitialisez** Terraform :
   ```bash
   terraform init -migrate-state
   ```
3. **Confirmez** la migration
4. **Vérifiez** que le state est dans Azure :
   ```bash
   az storage blob list \
     --container-name tfstate \
     --account-name remotestates
   ```

### Migrer d'Azure vers local

1. **Commentez** le bloc backend
2. **Réinitialisez** :
   ```bash
   terraform init -migrate-state
   ```
3. Le state sera rapatrié localement

## Backend avec différents projets

Utilisez des **clés différentes** pour chaque projet :

```hcl
# Projet 1
backend "azurerm" {
  resource_group_name  = "RG-STATES"
  storage_account_name = "remotestates"
  container_name       = "tfstate"
  key                  = "projet1/terraform.tfstate"  # 👈 Clé spécifique
}

# Projet 2
backend "azurerm" {
  resource_group_name  = "RG-STATES"
  storage_account_name = "remotestates"
  container_name       = "tfstate"
  key                  = "projet2/terraform.tfstate"  # 👈 Clé différente
}
```

Structure dans le storage :
```
tfstate/
├── projet1/
│   └── terraform.tfstate
├── projet2/
│   └── terraform.tfstate
└── dev/
    └── terraform.tfstate
```

## State Locking

Azure Storage supporte le **locking** automatiquement :
- Empêche les exécutions simultanées
- Évite la corruption du state
- Gère les locks automatiquement

```bash
# Terminal 1
$ terraform apply
Acquiring state lock. This may take a few moments...

# Terminal 2 (en même temps)
$ terraform apply
Error: Error acquiring the state lock
...
Lock Info:
  ID:        abc123...
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2024-01-15 10:30:00
```

### Débloquer manuellement

Si un lock reste bloqué (ex: crash) :

```bash
# Voir l'ID du lock
terraform force-unlock <LOCK_ID>

# ⚠️ Attention : Utilisez seulement si vous êtes sûr qu'aucun autre terraform ne tourne !
```

## Authentification pour le backend

### Option 1 : Azure CLI (développement)
```bash
az login
```

### Option 2 : Access Key (CI/CD)
```hcl
backend "azurerm" {
  resource_group_name  = "RG-STATES"
  storage_account_name = "remotestates"
  container_name       = "tfstate"
  key                  = "terraform.tfstate"
  access_key           = var.backend_access_key  # ⚠️ Sensible !
}
```

### Option 3 : Service Principal (CI/CD)
```bash
# Variables d'environnement
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

terraform init
```

### Option 4 : Managed Identity (Azure VM/Pipeline)
```hcl
backend "azurerm" {
  resource_group_name  = "RG-STATES"
  storage_account_name = "remotestates"
  container_name       = "tfstate"
  key                  = "terraform.tfstate"
  use_msi              = true
  subscription_id      = "xxx"
  tenant_id            = "xxx"
}
```

## Commandes

```bash
# 1. Créer l'infrastructure pour le backend (une seule fois)
./setup-backend.sh  # Ou créer manuellement avec az cli

# 2. Initialiser avec le backend distant
terraform init

# 3. Vérifier que le backend est configuré
terraform show

# 4. Voir le state distant
terraform state list

# 5. Migrer vers un nouveau backend
terraform init -migrate-state

# 6. Récupérer le state localement (backup)
terraform state pull > backup.tfstate

# 7. Envoyer un state local vers le backend
terraform state push backup.tfstate
```

## Versioning du state

Azure Storage supporte le **versioning** :

```bash
# Activer le versioning sur le storage account
az storage account blob-service-properties update \
  --account-name remotestates \
  --enable-versioning true

# Lister les versions d'un blob
az storage blob list \
  --container-name tfstate \
  --account-name remotestates \
  --include v
```

## Points d'attention

### ⚠️ Sécurité

1. **Ne jamais** commiter le state local
2. **Restreindre l'accès** au Storage Account (RBAC)
3. **Activer le chiffrement** (activé par défaut sur Azure)
4. **Activer le soft delete** pour récupération
5. **Activer le versioning** pour historique

### 📝 Bonnes pratiques

1. **Un Storage Account dédié** pour les states (séparation)
2. **Activer le versioning** du state
3. **Activer le soft delete** (30 jours minimum)
4. **Utiliser des clés différentes** par projet/environnement
5. **Documenter** la configuration du backend
6. **Backup régulier** du state (script automatisé)
7. **Limiter les accès** au strict nécessaire

### ✅ Configuration production

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-states"
    storage_account_name = "stterraformstates"
    container_name       = "tfstate"
    key                  = "prod/myapp/terraform.tfstate"

    # Sécurité
    use_azuread_auth = true  # Utiliser Azure AD au lieu des access keys
  }
}
```

## Structure des fichiers

```
10-States-backend/
├── main.tf              # Configuration avec backend azurerm
├── app_service.tf       # Ressources
├── variable.tf          # Variables
├── output.tf            # Outputs
├── dev.tfvars.example   # Template
└── README.md            # Ce fichier
```

## Script de setup du backend

Créez un script `setup-backend.sh` :

```bash
#!/bin/bash

# Configuration
RESOURCE_GROUP="rg-terraform-states"
LOCATION="westeurope"
STORAGE_ACCOUNT="stterraformstates"
CONTAINER_NAME="tfstate"

# Créer le Resource Group
echo "Création du Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Créer le Storage Account
echo "Création du Storage Account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Activer le versioning
echo "Activation du versioning..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true

# Activer le soft delete
echo "Activation du soft delete..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-delete-retention true \
  --delete-retention-days 30

# Créer le conteneur
echo "Création du conteneur..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

echo "Backend configuré avec succès !"
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
```

## Exercices

1. **Créer le backend** : Suivez les étapes pour créer le Storage Account
2. **Migrer** : Passez d'un state local à un state distant
3. **Multi-projet** : Configurez plusieurs projets avec des clés différentes
4. **Versioning** : Activez et testez le versioning du state
5. **Backup** : Créez un script de backup automatique du state

## Comparaison des backends

| Backend | Locking | Versioning | Coût | Complexité |
|---------|---------|------------|------|------------|
| Local | ❌ | ❌ | Gratuit | Simple |
| Azure Storage | ✅ | ✅ | ~0.50€/mois | Moyen |
| Terraform Cloud | ✅ | ✅ | Gratuit (limité) | Simple |
| S3 | ✅ | ✅ | ~1$/mois | Moyen |

## Dépannage

### Erreur : Failed to get existing workspaces
```
Error: Failed to get existing workspaces: storage account does not exist
```
**Solution** : Créez le Storage Account avant d'initialiser

### Erreur : Error acquiring the state lock
```
Error: Error acquiring the state lock
```
**Solution** : Attendez que l'autre processus se termine ou utilisez `force-unlock`

### Erreur : Failed to save state
```
Error: Failed to save state
```
**Solution** : Vérifiez les permissions sur le Storage Account

## Prochaines étapes

- Intégrer avec CI/CD (Azure DevOps, GitHub Actions)
- Utiliser des modules avec state partagé (voir exemple 13)
- Mettre en place une stratégie de backup/restore du state

## Ressources

- [Documentation Terraform - Backend Configuration](https://www.terraform.io/docs/language/settings/backends/index.html)
- [Azure Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)
