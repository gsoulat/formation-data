# 08 - Le cycle de vie Terraform

## 📖 Introduction

Comprendre le cycle de vie Terraform est essentiel pour utiliser l'outil efficacement. Ce module explique comment Terraform gère la création, la modification et la destruction de l'infrastructure.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les phases du cycle de vie Terraform
- ✅ Maîtriser les commandes terraform init, plan, apply, destroy
- ✅ Interpréter les plans d'exécution
- ✅ Gérer les changements d'infrastructure
- ✅ Utiliser les hooks du lifecycle

## 🔄 Le workflow Terraform

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│   Write  │ --> │   Init   │ --> │   Plan   │ --> │  Apply   │
│   Code   │     │ Providers│     │ Preview  │     │  Deploy  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                                                          │
                                                          ↓
                                                    ┌──────────┐
                                                    │ Destroy  │
                                                    │   Clean  │
                                                    └──────────┘
```

## 1️⃣ terraform init

**Objectif** : Initialiser le répertoire de travail Terraform.

### Que fait terraform init ?

```bash
terraform init
```

1. **Télécharge les providers** spécifiés dans le bloc `terraform`
2. **Initialise le backend** (local ou distant)
3. **Crée le dossier `.terraform/`**
4. **Crée `.terraform.lock.hcl`** (verrou de versions)
5. **Installe les modules** référencés

### Options utiles

```bash
# Initialisation standard
terraform init

# Réinstaller les providers
terraform init -upgrade

# Mode non-interactif
terraform init -input=false

# Reconfigurer le backend
terraform init -reconfigure

# Migrer l'état
terraform init -migrate-state
```

### Quand lancer init ?

- ✅ Première fois dans un nouveau projet
- ✅ Après avoir ajouté un nouveau provider
- ✅ Après avoir modifié la configuration du backend
- ✅ Après avoir cloné un repository

## 2️⃣ terraform plan

**Objectif** : Prévisualiser les changements avant de les appliquer.

### Commande basique

```bash
terraform plan
```

### Lecture du plan

```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "westeurope"
      + name     = "rg-example"
    }

  # azurerm_storage_account.example will be updated in-place
  ~ resource "azurerm_storage_account" "example" {
      ~ account_tier = "Standard" -> "Premium"
        id           = "/subscriptions/..."
        name         = "stexample"
    }

  # azurerm_virtual_network.old will be destroyed
  - resource "azurerm_virtual_network" "old" {
      - id       = "..." -> null
      - name     = "vnet-old" -> null
    }

Plan: 1 to add, 1 to change, 1 to destroy.
```

### Symboles du plan

| Symbole | Signification | Action |
|---------|---------------|--------|
| `+` | Création | Nouvelle ressource |
| `-` | Destruction | Suppression de ressource |
| `~` | Modification | Modification in-place |
| `-/+` | Recréation | Destruction puis création |
| `<=` | Lecture | Data source |

### Options utiles

```bash
# Sauvegarder le plan
terraform plan -out=tfplan

# Plan avec des variables spécifiques
terraform plan -var-file="prod.tfvars"

# Plan de destruction
terraform plan -destroy

# Format JSON
terraform plan -json

# Plan détaillé
terraform plan -verbose
```

### Comprendre (known after apply)

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "West Europe"
}

output "rg_id" {
  value = azurerm_resource_group.main.id  # (known after apply)
}
```

Certaines valeurs (comme les IDs) ne sont connues qu'après la création de la ressource.

## 3️⃣ terraform apply

**Objectif** : Appliquer les changements pour créer/modifier l'infrastructure.

### Commande basique

```bash
# Apply avec confirmation
terraform apply

# Apply sans confirmation
terraform apply -auto-approve
```

### Apply depuis un plan sauvegardé

```bash
# 1. Créer le plan
terraform plan -out=tfplan

# 2. Appliquer le plan exact
terraform apply tfplan
```

**Avantage** : Le plan ne peut pas changer entre plan et apply.

### Options utiles

```bash
# Apply avec variables
terraform apply -var-file="prod.tfvars"

# Apply ciblé (une ressource spécifique)
terraform apply -target=azurerm_resource_group.main

# Apply avec parallélisme contrôlé
terraform apply -parallelism=2

# Apply sans couleur (pour les logs)
terraform apply -no-color
```

### Processus d'apply

```
1. Refresh : Terraform vérifie l'état actuel
   ↓
2. Plan : Calcule les changements nécessaires
   ↓
3. Confirmation : Demande "yes"
   ↓
4. Apply : Exécute les changements
   ↓
5. Update State : Met à jour terraform.tfstate
```

## 4️⃣ terraform destroy

**Objectif** : Détruire toute l'infrastructure gérée par Terraform.

### Commande basique

```bash
# Destroy avec confirmation
terraform destroy

# Destroy sans confirmation
terraform destroy -auto-approve
```

### Destroy ciblé

```bash
# Détruire une ressource spécifique
terraform destroy -target=azurerm_storage_account.example

# Détruire plusieurs ressources
terraform destroy \
  -target=azurerm_storage_account.example \
  -target=azurerm_virtual_network.old
```

### ⚠️ Attention avec destroy

```hcl
resource "azurerm_storage_account" "critical" {
  name     = "stcriticaldata"
  # ...

  lifecycle {
    prevent_destroy = true  # Empêche la destruction accidentelle
  }
}
```

## 🔧 Autres commandes utiles

### terraform validate

```bash
# Valider la syntaxe
terraform validate

# Valider et afficher les erreurs JSON
terraform validate -json
```

### terraform fmt

```bash
# Formater le code
terraform fmt

# Formater récursivement
terraform fmt -recursive

# Vérifier le formatage sans modifier
terraform fmt -check

# Afficher les différences
terraform fmt -diff
```

### terraform show

```bash
# Afficher l'état actuel
terraform show

# Afficher un plan sauvegardé
terraform show tfplan

# Format JSON
terraform show -json
```

### terraform output

```bash
# Afficher tous les outputs
terraform output

# Afficher un output spécifique
terraform output resource_group_name

# Format JSON
terraform output -json

# Format brut (sans guillemets)
terraform output -raw storage_connection_string
```

### terraform refresh

```bash
# Mettre à jour l'état avec l'infrastructure réelle
terraform refresh

# Refresh avec variables
terraform refresh -var-file="prod.tfvars"
```

**Note** : Depuis Terraform 0.15+, `refresh` est intégré dans `plan` et `apply`.

## 📊 Le bloc lifecycle

Le bloc `lifecycle` contrôle le comportement de Terraform pour une ressource.

### prevent_destroy

```hcl
resource "azurerm_sql_database" "production" {
  name     = "prod-database"
  # ...

  lifecycle {
    prevent_destroy = true  # Terraform refusera de détruire cette ressource
  }
}
```

**Cas d'usage** : Protéger les ressources critiques en production.

### create_before_destroy

```hcl
resource "azurerm_virtual_machine" "web" {
  name = "vm-web"
  # ...

  lifecycle {
    create_before_destroy = true  # Créer la nouvelle VM avant de détruire l'ancienne
  }
}
```

**Cas d'usage** : Zéro downtime lors du remplacement.

### ignore_changes

```hcl
resource "azurerm_virtual_machine" "example" {
  name = "vm-example"
  # ...

  lifecycle {
    ignore_changes = [
      tags,          # Ignorer les changements de tags
      # Azure peut modifier automatiquement certains attributs
    ]
  }
}
```

**Cas d'usage** : Quand Azure ou d'autres processus modifient des attributs.

### replace_triggered_by

```hcl
resource "azurerm_storage_account" "example" {
  name     = "stexample"
  location = azurerm_resource_group.main.location
  # ...

  lifecycle {
    replace_triggered_by = [
      azurerm_resource_group.main.location  # Recréer si la location du RG change
    ]
  }
}
```

### Exemple complet

```hcl
resource "azurerm_storage_account" "logs" {
  name                = "stlogs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ...

  lifecycle {
    # Ne pas détruire accidentellement
    prevent_destroy = true

    # Ignorer les changements de tags (modifiés manuellement)
    ignore_changes = [
      tags["last_modified"],
      tags["modified_by"]
    ]

    # Créer avant de détruire (zéro downtime)
    create_before_destroy = false  # Pas applicable pour Storage Account
  }
}
```

## 🎯 Scénarios courants

### Scénario 1 : Premier déploiement

```bash
# 1. Écrire le code
vim main.tf

# 2. Initialiser
terraform init

# 3. Valider
terraform validate

# 4. Formater
terraform fmt

# 5. Planifier
terraform plan

# 6. Appliquer
terraform apply
```

### Scénario 2 : Modification d'infrastructure

```bash
# 1. Modifier le code
vim main.tf

# 2. Planifier les changements
terraform plan

# 3. Vérifier le plan
# Lire attentivement : +, -, ~, -/+

# 4. Appliquer
terraform apply
```

### Scénario 3 : Rollback

```bash
# Option 1 : Revenir au code précédent (Git)
git revert HEAD
terraform plan
terraform apply

# Option 2 : Utiliser un plan sauvegardé
# (nécessite d'avoir sauvegardé le plan avant)
```

### Scénario 4 : Environnements multiples

```bash
# Développement
terraform plan -var-file="dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan

# Production
terraform plan -var-file="prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

## 💡 Bonnes pratiques

### 1. Toujours exécuter plan avant apply

```bash
# ✅ Bon
terraform plan
# Vérifier le plan
terraform apply

# ❌ Mauvais (appliquer directement)
terraform apply -auto-approve
```

### 2. Sauvegarder les plans en production

```bash
# ✅ Bon (production)
terraform plan -out=tfplan
# Review du plan
terraform apply tfplan

# ⚠️ Acceptable (dev uniquement)
terraform apply
```

### 3. Utiliser des fichiers tfvars séparés

```bash
# ✅ Bon
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"

# ❌ Mauvais (variables en dur)
terraform apply -var="environment=prod"
```

### 4. Protéger les ressources critiques

```hcl
# ✅ Bon
resource "azurerm_sql_database" "prod" {
  lifecycle {
    prevent_destroy = true
  }
}
```

### 5. Versionner le lock file

```bash
# .gitignore
terraform.tfstate
terraform.tfstate.*
*.tfvars

# .gitattributes (versionner le lock file)
.terraform.lock.hcl
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Le workflow Terraform : Write → Init → Plan → Apply
- ✅ `terraform init` : Initialiser le projet
- ✅ `terraform plan` : Prévisualiser les changements
- ✅ `terraform apply` : Appliquer les changements
- ✅ `terraform destroy` : Détruire l'infrastructure
- ✅ Le bloc `lifecycle` pour contrôler le comportement
- ✅ Les bonnes pratiques du cycle de vie

## ➡️ Prochaine étape

Maintenant que vous comprenez le cycle de vie, découvrons **l'état Terraform (State)** qui est le cœur du fonctionnement de Terraform.

**Prochain module** : [09 - L'état Terraform (State)](./09-etat-terraform.md)

---

🔄 Parfait ! Vous maîtrisez le cycle de vie Terraform. Découvrons maintenant l'état !
