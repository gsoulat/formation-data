# Module 6 : Gestion du State

> **Durée : 45 minutes**
>
> Maîtrisez la gestion du state Terraform pour la production

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre le rôle du state file en profondeur
- ✅ Configurer un backend distant (Azure Storage, AWS S3, Terraform Cloud)
- ✅ Activer le state locking pour éviter les conflits
- ✅ Utiliser les commandes `terraform state` avancées
- ✅ Migrer d'un backend local vers un backend distant
- ✅ Sécuriser le state file
- ✅ Gérer le state en équipe

---

## 📊 Comprendre le State File

### Qu'est-ce que le State ?

Le **state file** (`terraform.tfstate`) est un fichier JSON qui contient :

- **Mapping** entre votre code Terraform et les ressources réelles
- **Attributs** de chaque ressource (IDs, IPs, configurations)
- **Métadonnées** (version Terraform, dépendances, etc.)
- **Outputs** calculés

### Exemple de State File

```json
{
  "version": 4,
  "terraform_version": "1.6.6",
  "serial": 5,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "resource_group_name": {
      "value": "rg-prod",
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
            "id": "/subscriptions/xxx/resourceGroups/rg-prod",
            "location": "westeurope",
            "name": "rg-prod",
            "tags": {
              "Environment": "Production"
            }
          },
          "dependencies": []
        }
      ]
    }
  ]
}
```

### Rôles du State File

1. **Mapping Code ↔ Infrastructure**
   ```
   Code Terraform         State File           Infrastructure Réelle
   ─────────────         ───────────          ──────────────────────
   resource "..." {  ←→  "id": "/sub/.."  ←→  Resource Group Azure
   ```

2. **Performance** : Cache des attributs pour éviter des appels API à chaque `plan`

3. **Dépendances** : Track les relations entre ressources

4. **Collaboration** : Permet à plusieurs personnes de travailler ensemble

---

## 🏠 State Local vs Remote

### State Local (Par Défaut)

**Avantages :**
- ✅ Simple à mettre en place
- ✅ Pas de configuration supplémentaire
- ✅ Idéal pour apprendre et tester

**Inconvénients :**
- ❌ Pas de collaboration possible
- ❌ Pas de sauvegarde automatique
- ❌ Risque de perte de données
- ❌ Pas de verrouillage (state locking)
- ❌ Secrets en clair dans le state

**Utilisation :**
```bash
# Par défaut, le state est stocké localement
terraform init
terraform apply
# Crée : terraform.tfstate
```

### State Remote (Production)

**Avantages :**
- ✅ Collaboration en équipe
- ✅ Sauvegarde automatique
- ✅ State locking (évite les conflits)
- ✅ Chiffrement des données
- ✅ Versioning du state
- ✅ Accès contrôlé

**Backends Populaires :**
- **Azure Storage** (azurerm)
- **AWS S3** (s3)
- **Terraform Cloud** (cloud)
- **Google Cloud Storage** (gcs)
- **HashiCorp Consul** (consul)

---

## ☁️ Configuration d'un Backend Distant

### Backend Azure Storage

#### Étape 1 : Créer les Ressources Azure pour le Backend

```bash
# Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="sttfstate$(date +%s)"
CONTAINER_NAME="tfstate"
LOCATION="West Europe"

# Créer le Resource Group
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location "$LOCATION"

# Créer le Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false

# Créer le Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

# Récupérer la clé d'accès
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Account Key: $ACCOUNT_KEY"
```

#### Étape 2 : Configurer le Backend dans Terraform

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"  # Nom du fichier state
  }
}
```

**Ou avec variables d'environnement (Recommandé pour CI/CD) :**

```bash
export ARM_ACCESS_KEY="xxxxx"
```

```hcl
# backend.tf (sans les credentials)
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

#### Étape 3 : Initialiser avec le Backend

```bash
terraform init
```

**Sortie attendue :**

```
Initializing the backend...

Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

### Backend AWS S3

#### Étape 1 : Créer les Ressources AWS

```bash
# Variables
BUCKET_NAME="my-terraform-state-$(date +%s)"
REGION="eu-west-1"

# Créer le bucket S3
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

# Activer le versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Activer le chiffrement
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Bloquer l'accès public
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=true,\
    IgnorePublicAcls=true,\
    BlockPublicPolicy=true,\
    RestrictPublicBuckets=true

# Créer une table DynamoDB pour le state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
```

#### Étape 2 : Configurer le Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-1234567890"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Pour le state locking
  }
}
```

#### Étape 3 : Initialiser

```bash
terraform init
```

### Backend Terraform Cloud

#### Étape 1 : Créer un Compte

1. Aller sur https://app.terraform.io/
2. Créer un compte
3. Créer une organisation
4. Créer un workspace

#### Étape 2 : Configurer le Backend

```hcl
# backend.tf
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      name = "my-app-prod"
    }
  }
}
```

#### Étape 3 : S'Authentifier

```bash
# Générer un token
terraform login

# Ou définir manuellement
export TF_TOKEN_app_terraform_io="xxxxxxxx"
```

#### Étape 4 : Initialiser

```bash
terraform init
```

---

## 🔒 State Locking

Le **state locking** empêche plusieurs personnes de modifier le state simultanément.

### Azure Storage (Automatic Locking)

Azure Storage inclut automatiquement le state locking via des leases :

```hcl
terraform {
  backend "azurerm" {
    # Le locking est automatique
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### AWS S3 + DynamoDB (Manual Configuration)

Pour S3, utilisez DynamoDB pour le locking :

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"  # Table DynamoDB pour locking
    encrypt        = true
  }
}
```

### Comportement du Locking

```bash
# Terminal 1
terraform apply
# Acquiert le lock...

# Terminal 2 (pendant l'apply du Terminal 1)
terraform apply
# Error: Error acquiring the state lock
# Lock Info:
#   ID:        abc123-def456-ghi789
#   Path:      prod/terraform.tfstate
#   Operation: OperationTypeApply
#   Who:       user@hostname
#   Version:   1.6.6
#   Created:   2025-11-01 10:30:15
```

### Forcer le Déverrouillage (DANGER)

```bash
# Si un apply a crashé et le lock n'a pas été libéré
terraform force-unlock LOCK_ID

# ⚠️ À utiliser UNIQUEMENT si vous êtes sûr que personne d'autre n'utilise le state
```

---

## 🛠️ Commandes State Avancées

### `terraform state list` - Lister les Ressources

```bash
# Lister toutes les ressources dans le state
terraform state list

# Sortie :
# azurerm_resource_group.main
# azurerm_virtual_network.main
# azurerm_subnet.web
# azurerm_subnet.app
```

### `terraform state show` - Afficher une Ressource

```bash
# Afficher les détails d'une ressource
terraform state show azurerm_resource_group.main

# Sortie :
# resource "azurerm_resource_group" "main" {
#     id       = "/subscriptions/.../resourceGroups/rg-prod"
#     location = "westeurope"
#     name     = "rg-prod"
#     tags     = {
#         "Environment" = "Production"
#     }
# }
```

### `terraform state mv` - Renommer une Ressource

```bash
# Renommer une ressource dans le state
terraform state mv azurerm_resource_group.main azurerm_resource_group.prod

# Ensuite, mettre à jour le code :
# resource "azurerm_resource_group" "prod" {  # ← Changé de "main" à "prod"
#   name = "rg-prod"
#   ...
# }
```

### `terraform state rm` - Retirer une Ressource du State

```bash
# Retirer une ressource du state (sans la supprimer dans le cloud)
terraform state rm azurerm_resource_group.main

# ⚠️ La ressource existe toujours dans Azure, mais Terraform ne la gère plus
```

**Cas d'usage :**
- Migrer une ressource vers un autre projet Terraform
- Passer d'une gestion Terraform à une gestion manuelle

### `terraform state pull` - Télécharger le State

```bash
# Télécharger le state distant
terraform state pull > local_state.json

# Utile pour inspecter le state
```

### `terraform state push` - Uploader le State (DANGER)

```bash
# ⚠️ ATTENTION : Peut écraser le state distant
terraform state push local_state.json

# À utiliser UNIQUEMENT pour récupérer d'un désastre
```

### `terraform import` - Importer une Ressource Existante

```bash
# Importer un Resource Group existant
terraform import azurerm_resource_group.main /subscriptions/SUBSCRIPTION_ID/resourceGroups/existing-rg

# Étapes :
# 1. Créer le bloc resource vide dans le code
# 2. Exécuter terraform import
# 3. Exécuter terraform plan pour voir les différences
# 4. Ajuster le code pour correspondre à la ressource
```

**Exemple complet :**

```hcl
# 1. Créer le bloc vide
resource "azurerm_resource_group" "main" {
  # Ne pas remplir encore
}
```

```bash
# 2. Importer
terraform import azurerm_resource_group.main /subscriptions/xxx/resourceGroups/existing-rg

# 3. Voir ce qui manque
terraform plan

# 4. Compléter le code
# resource "azurerm_resource_group" "main" {
#   name     = "existing-rg"
#   location = "West Europe"
#   tags = {
#     Environment = "Production"
#   }
# }

# 5. Vérifier
terraform plan
# No changes. Your infrastructure matches the configuration.
```

---

## 🔄 Migration de Backend

### De Local vers Remote

#### Étape 1 : État Initial (Local)

```hcl
# Pas de configuration backend
terraform init
terraform apply
# Crée : terraform.tfstate (local)
```

#### Étape 2 : Ajouter la Configuration Backend

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

#### Étape 3 : Réinitialiser avec Migration

```bash
terraform init -migrate-state
```

**Sortie :**

```
Initializing the backend...
Terraform detected that the backend type changed from "local" to "azurerm".

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. No existing state was found in the newly
  configured "azurerm" backend. Do you want to copy this state to the new "azurerm"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

Le state local est maintenant migré vers Azure Storage !

#### Étape 4 : Vérification

```bash
# Vérifier que le state est bien distant
terraform state list

# Supprimer le state local (optionnel)
rm terraform.tfstate
rm terraform.tfstate.backup
```

### D'un Backend Remote à un Autre

```bash
# 1. Modifier backend.tf avec le nouveau backend
# 2. Réinitialiser avec migration
terraform init -migrate-state -reconfigure
```

---

## 🔐 Sécurité du State

### Problèmes de Sécurité

Le state file peut contenir :
- ❌ Mots de passe en clair
- ❌ Clés API
- ❌ Tokens d'authentification
- ❌ Informations sensibles

**Exemple :**

```json
{
  "resources": [
    {
      "type": "azurerm_postgresql_flexible_server",
      "instances": [
        {
          "attributes": {
            "administrator_password": "SuperSecretPassword123!",  # ← EN CLAIR !
            "connection_string": "postgresql://admin:SuperSecretPassword123!@..."
          }
        }
      ]
    }
  ]
}
```

### Best Practices de Sécurité

#### 1. Ne JAMAIS Versionner le State

```gitignore
# .gitignore
*.tfstate
*.tfstate.*
*.tfstate.backup
```

#### 2. Utiliser un Backend Chiffré

**Azure Storage :**
```bash
# Le Storage Account doit avoir le chiffrement activé
az storage account create \
  --encryption-services blob \
  --https-only true
```

**AWS S3 :**
```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "prod/terraform.tfstate"
    encrypt = true  # ← Chiffrement activé
  }
}
```

#### 3. Contrôler les Accès

**Azure - RBAC :**
```bash
# Donner accès uniquement aux utilisateurs nécessaires
az role assignment create \
  --assignee user@example.com \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/.../resourceGroups/rg-terraform-state
```

**AWS - IAM Policy :**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::my-terraform-state/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

#### 4. Utiliser `sensitive = true` pour les Variables

```hcl
variable "db_password" {
  type      = string
  sensitive = true  # ← Masqué dans les logs
}

output "db_endpoint" {
  value     = azurerm_postgresql_flexible_server.main.fqdn
  sensitive = true  # ← Masqué dans les outputs
}
```

#### 5. Activer le Versioning

**Azure Storage :**
```bash
az storage blob service-properties update \
  --account-name sttfstate1234567890 \
  --enable-versioning true
```

**AWS S3 :**
```bash
aws s3api put-bucket-versioning \
  --bucket my-terraform-state \
  --versioning-configuration Status=Enabled
```

---

## 👥 Collaboration en Équipe

### Workflow avec Backend Distant

```
Développeur 1                Backend (Azure Storage)              Développeur 2
─────────────               ─────────────────────────            ─────────────

terraform plan          ─→  Acquiert le lock                ←─  terraform plan (bloqué)
                            Lit le state
                            Calcule le plan
                                   │
terraform apply         ─→  Modifie les ressources
                            Met à jour le state
                            Libère le lock
                                   │                          ─→  terraform plan (OK)
                                   │                              Lit le nouveau state
                                   │                              Calcule le plan
                            ✅ State à jour
```

### Bonnes Pratiques en Équipe

1. **Utiliser des Workspaces ou des Projets Séparés**

```bash
# Créer un workspace par environnement
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Lister les workspaces
terraform workspace list

# Changer de workspace
terraform workspace select prod
```

2. **Utiliser des Fichiers .tfvars par Environnement**

```
project/
├── backend.tf              # Backend partagé
├── main.tf
├── variables.tf
├── dev.tfvars             # Valeurs dev
├── staging.tfvars         # Valeurs staging
└── prod.tfvars            # Valeurs prod
```

3. **Communication dans l'Équipe**

- Annoncer avant de faire un `terraform apply`
- Utiliser des branches Git séparées
- Faire des code reviews avant de merger
- Automatiser avec CI/CD (Module 8)

---

## 📝 Points Clés à Retenir

1. **State** : Contient le mapping entre le code et l'infrastructure réelle
2. **Backend Remote** : Obligatoire pour le travail en équipe
3. **State Locking** : Évite les conflits lors d'exécutions simultanées
4. **Sécurité** : Ne jamais versionner le state, utiliser le chiffrement
5. **Commandes State** : `list`, `show`, `mv`, `rm`, `import`
6. **Migration** : `terraform init -migrate-state`
7. **Collaboration** : Backend distant + locking + workspaces

---

## ✅ Quiz de Compréhension

1. Pourquoi ne doit-on JAMAIS versionner le state file dans Git ?
2. Qu'est-ce que le state locking et pourquoi est-il important ?
3. Comment migrer un state local vers Azure Storage ?
4. Quelle commande permet d'importer une ressource existante ?
5. Quelles sont les 3 meilleures pratiques de sécurité pour le state ?

---

## 🚀 Prochaine Étape

Vous maîtrisez maintenant la gestion du state ! Il est temps de rendre votre code réutilisable avec les modules.

**➡️ [Module 7 : Modules Terraform](07-modules.md)**

Dans le prochain module, vous allez :
- Comprendre les modules Terraform
- Créer votre premier module custom
- Utiliser des modules du Terraform Registry
- Versionner vos modules
- Structurer un projet avec des modules

---

## 📚 Ressources Complémentaires

- [State File](https://www.terraform.io/docs/language/state/index.html)
- [Backend Configuration](https://www.terraform.io/docs/language/settings/backends/index.html)
- [State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [Azure Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)

---

[⬅️ Module précédent](05-ressources-cloud.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](07-modules.md)
