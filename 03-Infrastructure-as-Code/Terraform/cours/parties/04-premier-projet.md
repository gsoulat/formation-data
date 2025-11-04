# 04 - Premier projet Terraform

## 📖 Introduction

Le moment est venu ! Vous allez créer votre première infrastructure Azure avec Terraform. Dans ce module, nous allons créer un Resource Group et un Storage Account pas à pas.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Créer votre premier fichier Terraform
- ✅ Comprendre la structure d'un projet Terraform
- ✅ Initialiser un projet avec `terraform init`
- ✅ Prévisualiser les changements avec `terraform plan`
- ✅ Déployer l'infrastructure avec `terraform apply`
- ✅ Détruire l'infrastructure avec `terraform destroy`

## 📁 Structure du projet

Créons notre premier projet Terraform :

```bash
# Créer le dossier du projet
mkdir ~/terraform-projects/mon-premier-projet
cd ~/terraform-projects/mon-premier-projet

# Nous allons créer ces fichiers :
# ├── main.tf              # Fichier principal
# ├── variables.tf         # Déclaration des variables
# ├── outputs.tf           # Sorties du projet
# └── terraform.tfvars     # Valeurs des variables
```

## 📝 Créer le fichier main.tf

Le fichier `main.tf` contient la configuration principale de notre infrastructure.

### Étape 1 : Configuration du provider

Créez le fichier `main.tf` :

```hcl
# main.tf

# Configuration de Terraform
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configuration du provider Azure
provider "azurerm" {
  features {}

  # Si vous avez configuré les variables d'environnement ARM_*,
  # pas besoin de spécifier subscription_id, client_id, etc.
}
```

### Étape 2 : Créer un Resource Group

Ajoutons notre première ressource Azure :

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-mon-premier-projet"
  location = "West Europe"

  tags = {
    environment = "dev"
    project     = "formation-terraform"
    created_by  = "terraform"
  }
}
```

**Décortiquons ce code** :

- `resource` : Mot-clé pour déclarer une ressource
- `"azurerm_resource_group"` : Type de ressource (Resource Group Azure)
- `"main"` : Nom local de la ressource (utilisé dans Terraform uniquement)
- `name` : Nom de la ressource dans Azure
- `location` : Région Azure où créer la ressource
- `tags` : Métadonnées pour organiser et filtrer les ressources

### Étape 3 : Créer un Storage Account

Ajoutons un compte de stockage :

```hcl
# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "stmypremierprojet001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "dev"
    project     = "formation-terraform"
    created_by  = "terraform"
  }
}
```

**Points importants** :

- Le nom du Storage Account doit être **unique globalement** sur Azure
- Il ne peut contenir que des lettres minuscules et des chiffres
- `azurerm_resource_group.main.name` : Référence au Resource Group créé au-dessus
- `LRS` : Locally Redundant Storage (le moins cher)

## 📤 Créer le fichier outputs.tf

Les outputs permettent d'afficher des informations après le déploiement.

Créez `outputs.tf` :

```hcl
# outputs.tf

output "resource_group_name" {
  description = "Nom du resource group créé"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID du resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_name" {
  description = "Nom du storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Endpoint principal du storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}
```

## 🚀 Déployer l'infrastructure

### Étape 1 : Initialiser Terraform

```bash
# Initialiser le projet
terraform init
```

**Que fait `terraform init` ?**

1. 📥 Télécharge le provider Azure (azurerm)
2. 📁 Crée le dossier `.terraform/`
3. 🔒 Crée le fichier `.terraform.lock.hcl` (verrou de versions)
4. ✅ Vérifie la syntaxe de base

**Résultat attendu** :
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 4.0"...
- Installing hashicorp/azurerm v4.x.x...
- Installed hashicorp/azurerm v4.x.x

Terraform has been successfully initialized!
```

### Étape 2 : Formater le code (optionnel)

```bash
# Formater automatiquement le code
terraform fmt

# Vérifier si le code est bien formaté
terraform fmt -check
```

### Étape 3 : Valider la configuration

```bash
# Valider la syntaxe
terraform validate
```

**Résultat attendu** :
```
Success! The configuration is valid.
```

### Étape 4 : Planifier les changements

```bash
# Prévisualiser ce qui va être créé
terraform plan
```

**Résultat attendu** :
```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "rg-mon-premier-projet"
      + tags     = {
          + "created_by"  = "terraform"
          + "environment" = "dev"
          + "project"     = "formation-terraform"
        }
    }

  # azurerm_storage_account.main will be created
  + resource "azurerm_storage_account" "main" {
      + id                      = (known after apply)
      + location                = "westeurope"
      + name                    = "stmypremierprojet001"
      + resource_group_name     = "rg-mon-premier-projet"
      + account_tier            = "Standard"
      + account_replication_type = "LRS"
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**Analysez attentivement** :
- ✅ `+ resource` = Création d'une nouvelle ressource
- ✅ `Plan: 2 to add` = 2 ressources vont être créées
- ✅ `(known after apply)` = Valeur connue après le déploiement

### Étape 5 : Appliquer les changements

```bash
# Déployer l'infrastructure
terraform apply

# Ou avec auto-approbation (attention en production !)
terraform apply -auto-approve
```

Terraform va vous demander confirmation :

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Tapez `yes` et appuyez sur Entrée.

**Résultat attendu** :
```
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s [id=/subscriptions/...]
azurerm_storage_account.main: Creating...
azurerm_storage_account.main: Still creating... [10s elapsed]
azurerm_storage_account.main: Still creating... [20s elapsed]
azurerm_storage_account.main: Creation complete after 23s [id=/subscriptions/...]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

resource_group_id = "/subscriptions/.../resourceGroups/rg-mon-premier-projet"
resource_group_name = "rg-mon-premier-projet"
storage_account_name = "stmypremierprojet001"
storage_account_primary_endpoint = "https://stmypremierprojet001.blob.core.windows.net/"
```

🎉 **Félicitations ! Vous venez de créer votre première infrastructure avec Terraform !**

## 🔍 Vérifier l'infrastructure

### Vérifier dans Azure Portal

1. Ouvrez le portail Azure : https://portal.azure.com
2. Allez dans "Resource Groups"
3. Vous devriez voir `rg-mon-premier-projet`
4. Cliquez dessus et vérifiez que le Storage Account existe

### Vérifier avec Azure CLI

```bash
# Lister les resource groups
az group list --query "[?name=='rg-mon-premier-projet']" --output table

# Voir le contenu du resource group
az resource list --resource-group rg-mon-premier-projet --output table
```

### Vérifier avec Terraform

```bash
# Afficher l'état actuel
terraform show

# Afficher uniquement les outputs
terraform output

# Afficher un output spécifique
terraform output storage_account_name
```

## 📊 Comprendre l'état Terraform

Après l'apply, Terraform a créé un fichier `terraform.tfstate` :

```bash
# Lister les fichiers
ls -la

# Devrait afficher :
# terraform.tfstate         ← État actuel
# terraform.tfstate.backup  ← Sauvegarde de l'état précédent
# .terraform/               ← Plugins et dépendances
# .terraform.lock.hcl       ← Verrou des versions
```

**⚠️ Le fichier `terraform.tfstate` est CRUCIAL** :
- 📊 Il contient l'état actuel de votre infrastructure
- 🔗 Il fait le lien entre votre code et Azure
- 🚫 Ne le supprimez JAMAIS
- 🚫 Ne le modifiez JAMAIS manuellement
- 🔒 Ne le commitez JAMAIS dans Git (contient des secrets)

## 🔄 Modifier l'infrastructure

Modifions quelque chose pour voir comment Terraform gère les changements.

### Ajouter un tag

Modifiez `main.tf` et ajoutez un tag au Resource Group :

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-mon-premier-projet"
  location = "West Europe"

  tags = {
    environment = "dev"
    project     = "formation-terraform"
    created_by  = "terraform"
    modified    = "2024-01-15"  # ← Nouveau tag
  }
}
```

Appliquez le changement :

```bash
# Planifier
terraform plan

# Résultat attendu :
# ~ update in-place
#   ~ tags = {
#       + "modified"    = "2024-01-15"
#     }

# Appliquer
terraform apply
```

Terraform va **modifier** la ressource existante sans la détruire !

## 🗑️ Détruire l'infrastructure

Quand vous avez terminé, détruisez tout pour éviter les coûts :

```bash
# Voir ce qui va être détruit
terraform plan -destroy

# Détruire l'infrastructure
terraform destroy

# Ou avec auto-approbation
terraform destroy -auto-approve
```

**Résultat attendu** :
```
azurerm_storage_account.main: Destroying...
azurerm_storage_account.main: Destruction complete after 15s
azurerm_resource_group.main: Destroying...
azurerm_resource_group.main: Destruction complete after 45s

Destroy complete! Resources: 2 destroyed.
```

**⚠️ Attention** : `terraform destroy` supprime TOUT ce qui est géré par Terraform !

## 🎓 Les commandes Terraform essentielles

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `terraform init` | Initialise le projet | Au début, ou après ajout d'un provider |
| `terraform fmt` | Formate le code | Avant chaque commit |
| `terraform validate` | Valide la syntaxe | Avant plan/apply |
| `terraform plan` | Prévisualise les changements | Avant chaque apply |
| `terraform apply` | Applique les changements | Pour déployer |
| `terraform show` | Affiche l'état actuel | Pour inspecter |
| `terraform output` | Affiche les outputs | Pour récupérer des valeurs |
| `terraform destroy` | Détruit tout | En fin de test |
| `terraform state list` | Liste les ressources gérées | Pour diagnostiquer |

## 🛠️ Créer un .gitignore

Si vous utilisez Git, créez un fichier `.gitignore` :

```bash
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl

# Crash log files
crash.log
crash.*.log

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
EOF
```

## 💡 Bonnes pratiques

### ✅ À FAIRE

1. **Toujours exécuter `terraform plan` avant `apply`**
2. **Versionner votre code** avec Git
3. **Utiliser des noms explicites** pour les ressources
4. **Ajouter des tags** à toutes les ressources
5. **Documenter votre code** avec des commentaires
6. **Utiliser `terraform fmt`** régulièrement

### ❌ À ÉVITER

1. **Ne jamais éditer le fichier tfstate** manuellement
2. **Ne jamais commiter terraform.tfstate** dans Git
3. **Ne jamais mettre de secrets** en clair dans le code
4. **Ne pas utiliser `-auto-approve`** en production
5. **Ne pas oublier** de faire `terraform destroy` après les tests

## 🧪 Exercice pratique

Créez une infrastructure similaire mais avec :

1. Un Resource Group nommé `rg-exercice-01`
2. Deux Storage Accounts (utilisez des noms uniques)
3. Ajoutez un tag `owner` avec votre nom
4. Ajoutez des outputs pour afficher tous les noms

<details>
<summary>💡 Solution</summary>

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "exercice" {
  name     = "rg-exercice-01"
  location = "West Europe"

  tags = {
    owner = "VotreNom"
  }
}

resource "azurerm_storage_account" "storage1" {
  name                     = "stexercice001"
  resource_group_name      = azurerm_resource_group.exercice.name
  location                 = azurerm_resource_group.exercice.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    owner = "VotreNom"
  }
}

resource "azurerm_storage_account" "storage2" {
  name                     = "stexercice002"
  resource_group_name      = azurerm_resource_group.exercice.name
  location                 = azurerm_resource_group.exercice.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    owner = "VotreNom"
  }
}
```

```hcl
# outputs.tf
output "rg_name" {
  value = azurerm_resource_group.exercice.name
}

output "storage1_name" {
  value = azurerm_storage_account.storage1.name
}

output "storage2_name" {
  value = azurerm_storage_account.storage2.name
}
```

N'oubliez pas de faire `terraform destroy` après !
</details>

## ✅ Quiz de compréhension

1. **Quelle commande initialise un projet Terraform ?**
   - a) terraform start
   - b) terraform init
   - c) terraform begin

2. **Que fait `terraform plan` ?**
   - a) Crée l'infrastructure
   - b) Prévisualise les changements
   - c) Détruit l'infrastructure

3. **Le fichier terraform.tfstate contient :**
   - a) Le code Terraform
   - b) L'état de l'infrastructure
   - c) Les logs d'exécution

4. **Pour détruire l'infrastructure, on utilise :**
   - a) terraform delete
   - b) terraform remove
   - c) terraform destroy

5. **Que signifie LRS pour un Storage Account ?**
   - a) Large Resource Storage
   - b) Locally Redundant Storage
   - c) Limited Resource Service

<details>
<summary>📊 Réponses</summary>

1. **b)** terraform init
2. **b)** Prévisualise les changements
3. **b)** L'état de l'infrastructure
4. **c)** terraform destroy
5. **b)** Locally Redundant Storage

Score : __/5
</details>

## 🎓 Résumé

Dans ce module, vous avez appris à :

- ✅ Créer un fichier main.tf avec des ressources Azure
- ✅ Utiliser terraform init, plan, apply et destroy
- ✅ Comprendre le rôle du fichier terraform.tfstate
- ✅ Créer des outputs pour afficher des informations
- ✅ Modifier et mettre à jour l'infrastructure

## ➡️ Prochaine étape

Vous savez maintenant créer une infrastructure simple ! Il est temps d'approfondir la **syntaxe HCL** pour écrire du code Terraform plus propre et plus puissant.

**Prochain module** : [05 - Syntaxe HCL](./05-syntaxe-hcl.md)

---

🎉 Bravo ! Vous avez créé, modifié et détruit votre première infrastructure ! Passons au niveau supérieur.
