# Module 3 : Premier Projet Terraform

> **Durée : 1 heure**
>
> Créez votre première infrastructure avec Terraform

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre la structure d'un projet Terraform
- ✅ Créer vos premiers fichiers de configuration (.tf)
- ✅ Utiliser les commandes essentielles : `init`, `plan`, `apply`, `destroy`
- ✅ Comprendre le workflow complet de Terraform
- ✅ Déployer votre première ressource sur Azure

---

## 📁 Structure d'un Projet Terraform

Un projet Terraform bien structuré ressemble à ceci :

```
mon-projet/
├── main.tf              # Ressources principales
├── variables.tf         # Déclaration des variables
├── outputs.tf           # Déclaration des outputs
├── terraform.tfvars     # Valeurs des variables (non versionné si sensible)
├── provider.tf          # Configuration du/des provider(s)
├── .gitignore           # Fichiers à ignorer par Git
├── .terraform/          # Dossier des plugins (créé par terraform init)
└── terraform.tfstate    # Fichier d'état (créé par terraform apply)
```

### Convention de Nommage des Fichiers

| Fichier | Rôle | Obligatoire |
|---------|------|-------------|
| `main.tf` | Définit les ressources principales | ✅ Oui |
| `variables.tf` | Déclare les variables d'entrée | ⚪ Recommandé |
| `outputs.tf` | Déclare les outputs | ⚪ Recommandé |
| `provider.tf` | Configure les providers | ⚪ Recommandé |
| `terraform.tfvars` | Valeurs des variables | ⚪ Optionnel |
| `versions.tf` | Contraintes de versions | ⚪ Recommandé |

**Note :** Terraform charge automatiquement tous les fichiers `.tf` dans le répertoire.

---

## 🚀 Premier Projet : Resource Group Azure

Créons notre premier projet Terraform qui déploie un Resource Group sur Azure.

### Étape 1 : Créer le Répertoire du Projet

```bash
# Créer le dossier du projet
mkdir ~/terraform-projects/first-project
cd ~/terraform-projects/first-project

# Créer le fichier .gitignore
cat > .gitignore << 'EOF'
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files with secrets
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI configuration files
.terraformrc
terraform.rc
EOF
```

### Étape 2 : Créer le Fichier de Configuration du Provider

```bash
# Créer provider.tf
cat > provider.tf << 'EOF'
# Configure the Terraform settings
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}
EOF
```

**Explications :**

- `terraform { }` : Bloc de configuration Terraform
- `required_version` : Version minimale de Terraform requise
- `required_providers` : Providers nécessaires au projet
- `source` : Source du provider (registre Terraform)
- `version` : Contrainte de version (`~> 3.0` = 3.x.x)
- `provider "azurerm"` : Configuration du provider Azure
- `features {}` : Bloc requis par le provider Azure (peut contenir des flags)

### Étape 3 : Créer le Fichier Principal

```bash
# Créer main.tf
cat > main.tf << 'EOF'
# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-demo"
  location = "West Europe"

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "FirstProject"
  }
}
EOF
```

**Explications :**

```hcl
resource "TYPE" "NAME" {
  argument1 = value1
  argument2 = value2
}
```

- `resource` : Mot-clé pour déclarer une ressource
- `"azurerm_resource_group"` : Type de ressource (défini par le provider)
- `"main"` : Nom local de la ressource (utilisé dans Terraform uniquement)
- `name` : Nom du Resource Group dans Azure
- `location` : Région Azure
- `tags` : Métadonnées sous forme de map (clé-valeur)

### Étape 4 : Créer le Fichier d'Outputs

```bash
# Créer outputs.tf
cat > outputs.tf << 'EOF'
# Output the resource group ID
output "resource_group_id" {
  description = "ID du Resource Group créé"
  value       = azurerm_resource_group.main.id
}

# Output the resource group name
output "resource_group_name" {
  description = "Nom du Resource Group"
  value       = azurerm_resource_group.main.name
}

# Output the resource group location
output "resource_group_location" {
  description = "Région du Resource Group"
  value       = azurerm_resource_group.main.location
}
EOF
```

**Explications :**

- `output` : Déclare une valeur à afficher après `terraform apply`
- `description` : Description de l'output (optionnel mais recommandé)
- `value` : Valeur à afficher (peut référencer des ressources)
- Syntaxe de référence : `TYPE.NAME.ATTRIBUTE`

---

## 🔧 Workflow Terraform : Les Commandes Essentielles

Le workflow Terraform suit généralement ces étapes :

```
WRITE → INIT → PLAN → APPLY → DESTROY
```

### 1. `terraform init` - Initialisation

La commande `init` initialise le projet Terraform :

```bash
terraform init
```

**Cette commande :**
- ✅ Télécharge les plugins des providers (azurerm, aws, etc.)
- ✅ Initialise le backend (local par défaut)
- ✅ Crée le dossier `.terraform/`
- ✅ Génère le fichier `.terraform.lock.hcl` (lockfile des versions)

**Sortie attendue :**

```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.84.0...
- Installed hashicorp/azurerm v3.84.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

**Quand exécuter `terraform init` ?**
- À la première création du projet
- Après avoir ajouté un nouveau provider
- Après avoir cloné un projet depuis Git
- Après avoir modifié la configuration du backend

### 2. `terraform fmt` - Formatage (Optionnel mais Recommandé)

Formate automatiquement le code selon les conventions Terraform :

```bash
terraform fmt
```

**Cette commande :**
- ✅ Indente correctement le code
- ✅ Aligne les arguments
- ✅ Trie les blocs de manière cohérente

**Exemple :**

```hcl
# Avant terraform fmt
resource "azurerm_resource_group" "main" {
name="rg-demo"
location   =    "West Europe"
}

# Après terraform fmt
resource "azurerm_resource_group" "main" {
  name     = "rg-demo"
  location = "West Europe"
}
```

### 3. `terraform validate` - Validation

Vérifie que la syntaxe est correcte :

```bash
terraform validate
```

**Sortie si OK :**

```
Success! The configuration is valid.
```

**Sortie si erreur :**

```
Error: Missing required argument

  on main.tf line 2, in resource "azurerm_resource_group" "main":
   2: resource "azurerm_resource_group" "main" {

The argument "location" is required, but no definition was found.
```

### 4. `terraform plan` - Planification

Génère un plan d'exécution montrant ce qui sera créé/modifié/supprimé :

```bash
terraform plan
```

**Sortie attendue :**

```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "rg-terraform-demo"
      + tags     = {
          + "Environment" = "Development"
          + "ManagedBy"   = "Terraform"
          + "Project"     = "FirstProject"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + resource_group_id       = (known after apply)
  + resource_group_location = "westeurope"
  + resource_group_name     = "rg-terraform-demo"
```

**Symboles importants :**
- `+` : Ressource qui sera **créée**
- `-` : Ressource qui sera **supprimée**
- `~` : Ressource qui sera **modifiée**
- `-/+` : Ressource qui sera **remplacée** (destroy puis create)

**Options utiles :**

```bash
# Sauvegarder le plan dans un fichier
terraform plan -out=tfplan

# Voir seulement les changements (sans les détails)
terraform plan -compact-warnings

# Afficher le plan en JSON
terraform plan -json
```

### 5. `terraform apply` - Application

Applique les changements pour créer/modifier l'infrastructure :

```bash
terraform apply
```

**Sortie interactive :**

```
Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s [id=/subscriptions/.../resourceGroups/rg-terraform-demo]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

resource_group_id = "/subscriptions/xxxxx/resourceGroups/rg-terraform-demo"
resource_group_location = "westeurope"
resource_group_name = "rg-terraform-demo"
```

**Options utiles :**

```bash
# Auto-approve (sans confirmation interactive)
terraform apply -auto-approve

# Appliquer un plan sauvegardé
terraform apply tfplan

# Créer uniquement une ressource spécifique
terraform apply -target=azurerm_resource_group.main
```

**⚠️ IMPORTANT :** `terraform apply` crée réellement les ressources et peut engendrer des coûts !

### 6. `terraform show` - Afficher l'État

Affiche l'état actuel de l'infrastructure :

```bash
terraform show
```

**Sortie :**

```
# azurerm_resource_group.main:
resource "azurerm_resource_group" "main" {
    id       = "/subscriptions/.../resourceGroups/rg-terraform-demo"
    location = "westeurope"
    name     = "rg-terraform-demo"
    tags     = {
        "Environment" = "Development"
        "ManagedBy"   = "Terraform"
        "Project"     = "FirstProject"
    }
}
```

### 7. `terraform output` - Afficher les Outputs

Affiche uniquement les outputs :

```bash
# Afficher tous les outputs
terraform output

# Afficher un output spécifique
terraform output resource_group_name

# Afficher en JSON
terraform output -json
```

### 8. `terraform destroy` - Destruction

Détruit toutes les ressources gérées par Terraform :

```bash
terraform destroy
```

**Sortie interactive :**

```
Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

azurerm_resource_group.main: Destroying... [id=/subscriptions/.../resourceGroups/rg-terraform-demo]
azurerm_resource_group.main: Still destroying... [id=/subscriptions/.../resourceGroups/rg-terraform-demo, 10s elapsed]
azurerm_resource_group.main: Destruction complete after 15s

Destroy complete! Resources: 1 destroyed.
```

**Options utiles :**

```bash
# Auto-approve (ATTENTION : dangereux !)
terraform destroy -auto-approve

# Détruire uniquement une ressource spécifique
terraform destroy -target=azurerm_resource_group.main
```

---

## 🔄 Workflow Complet en Pratique

Voici le workflow complet pour notre premier projet :

```bash
# 1. Créer et se positionner dans le projet
cd ~/terraform-projects/first-project

# 2. Vérifier les fichiers créés
ls -la

# 3. Initialiser Terraform
terraform init

# 4. Formater le code (optionnel)
terraform fmt

# 5. Valider la syntaxe
terraform validate

# 6. Voir le plan d'exécution
terraform plan

# 7. Vérifier l'authentification Azure
az account show

# 8. Appliquer les changements
terraform apply
# Tapez 'yes' pour confirmer

# 9. Vérifier dans le portail Azure
# Aller sur portal.azure.com → Resource Groups

# 10. Afficher les outputs
terraform output

# 11. Voir l'état actuel
terraform show

# 12. Détruire les ressources (pour éviter les coûts)
terraform destroy
# Tapez 'yes' pour confirmer
```

---

## 📊 Comprendre le State File

Après `terraform apply`, un fichier `terraform.tfstate` est créé :

```json
{
  "version": 4,
  "terraform_version": "1.6.6",
  "serial": 1,
  "lineage": "xxxxx-xxxx-xxxx-xxxx-xxxxx",
  "outputs": {
    "resource_group_name": {
      "value": "rg-terraform-demo",
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
            "id": "/subscriptions/.../resourceGroups/rg-terraform-demo",
            "location": "westeurope",
            "name": "rg-terraform-demo",
            "tags": {
              "Environment": "Development",
              "ManagedBy": "Terraform"
            }
          }
        }
      ]
    }
  ]
}
```

**Rôles du state file :**

1. **Mapping** : Lie le code Terraform aux ressources réelles
2. **Performance** : Cache les attributs des ressources
3. **Dépendances** : Track les relations entre ressources
4. **Collaboration** : Permet le travail en équipe (avec remote backend)

**⚠️ IMPORTANT :**

- Ne **JAMAIS** éditer manuellement le state file
- Ne **JAMAIS** versionner le state file (il peut contenir des secrets)
- Utiliser un **remote backend** pour le travail en équipe (Module 6)

---

## 🛠️ Commandes Avancées

### Afficher les Ressources Gérées

```bash
# Lister toutes les ressources dans le state
terraform state list

# Afficher une ressource spécifique
terraform state show azurerm_resource_group.main
```

### Rafraîchir l'État

```bash
# Synchroniser le state avec la réalité (sans modifier les ressources)
terraform refresh
```

### Importer des Ressources Existantes

Si vous avez créé une ressource manuellement et voulez la gérer avec Terraform :

```bash
# Importer un Resource Group existant
terraform import azurerm_resource_group.main /subscriptions/SUBSCRIPTION_ID/resourceGroups/existing-rg
```

### Générer un Graphe de Dépendances

```bash
# Générer un graphe au format DOT
terraform graph > graph.dot

# Convertir en PNG (nécessite graphviz)
dot -Tpng graph.dot -o graph.png
```

---

## 💻 Exercice Pratique 1 : Créer un Storage Account

Maintenant que vous maîtrisez les bases, créez un Storage Account Azure.

**Objectif :** Créer un Storage Account dans un Resource Group

### Solution

```hcl
# main.tf
resource "azurerm_resource_group" "example" {
  name     = "rg-storage-demo"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  name                     = "stterraformdemo12345"  # Doit être unique globalement
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

```hcl
# outputs.tf
output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "storage_account_primary_blob_endpoint" {
  value = azurerm_storage_account.example.primary_blob_endpoint
}
```

**Tester :**

```bash
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

---

## 💻 Exercice Pratique 2 : Projet Multi-Ressources

Créez un projet avec :
- 1 Resource Group
- 1 Virtual Network
- 2 Subnets

### Solution

```hcl
# main.tf
resource "azurerm_resource_group" "network" {
  name     = "rg-network-demo"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "subnet-frontend"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "subnet-backend"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}
```

**Notice :** Les dépendances sont automatiquement gérées par Terraform grâce aux références entre ressources.

---

## 🐛 Dépannage

### Erreur : "provider configuration not found"

```
Error: Provider configuration not present

To work with azurerm_resource_group.main its original provider configuration
at provider["registry.terraform.io/hashicorp/azurerm"] is required, but it
has been removed. This occurs when a provider configuration is removed while
objects created by that provider still exist in the state.
```

**Solution :** Vérifiez que `provider.tf` existe et exécutez `terraform init`

### Erreur : "authentication failed"

```
Error: Error building account: Error getting authenticated object ID: Error listing Service Principals
```

**Solution :** Authentifiez-vous avec Azure :

```bash
az login
az account show
```

### Erreur : "resource already exists"

```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-terraform-demo" already exists
```

**Solution :**

1. Supprimer manuellement la ressource dans Azure
2. **OU** importer la ressource existante :

```bash
terraform import azurerm_resource_group.main /subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-terraform-demo
```

### Erreur : "state lock"

```
Error: Error acquiring the state lock
```

**Solution :** Quelqu'un d'autre utilise le state, ou un apply précédent a crashé :

```bash
# Forcer le déverrouillage (ATTENTION : seulement si vous êtes sûr)
terraform force-unlock LOCK_ID
```

---

## 📝 Points Clés à Retenir

1. **Structure de projet** : `main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`
2. **Workflow** : `init` → `plan` → `apply` → `destroy`
3. **Plan avant apply** : Toujours vérifier avec `terraform plan`
4. **State file** : Ne jamais modifier manuellement, ne pas versionner
5. **Auto-approve** : Attention avec `-auto-approve`, surtout sur `destroy`
6. **Formatage** : Utiliser `terraform fmt` pour un code propre
7. **Validation** : Utiliser `terraform validate` avant `plan`

---

## ✅ Quiz de Compréhension

1. Quelle commande doit-on exécuter en premier dans un nouveau projet Terraform ?
2. Quelle est la différence entre `terraform plan` et `terraform apply` ?
3. À quoi sert le fichier `terraform.tfstate` ?
4. Comment référencer un attribut d'une ressource dans une autre ressource ?
5. Pourquoi ne doit-on pas versionner le state file ?

---

## 🚀 Prochaine Étape

Vous savez maintenant créer des ressources avec Terraform ! Mais votre code est encore rigide. Il est temps de le rendre flexible et réutilisable.

**➡️ [Module 4 : Variables et Outputs](04-variables-outputs.md)**

Dans le prochain module, vous allez :
- Utiliser des variables pour paramétrer votre code
- Découvrir les différents types de variables
- Créer des fichiers `.tfvars`
- Utiliser des outputs pour extraire des informations
- Créer des configurations réutilisables pour dev/staging/prod

---

## 📚 Ressources Complémentaires

- [Terraform CLI Documentation](https://www.terraform.io/docs/cli/index.html)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Workflow](https://www.terraform.io/guides/core-workflow.html)
- [State File](https://www.terraform.io/docs/language/state/index.html)

---

[⬅️ Module précédent](02-installation.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](04-variables-outputs.md)
