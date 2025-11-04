# 14 - Workspaces

## 📖 Introduction

Les **workspaces** permettent de gérer plusieurs environnements (dev, staging, prod) avec le même code Terraform, mais avec des états séparés.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les workspaces Terraform
- ✅ Créer et gérer plusieurs workspaces
- ✅ Utiliser `terraform.workspace` dans le code
- ✅ Déployer sur plusieurs environnements
- ✅ Connaître les limites des workspaces

## 🏢 Qu'est-ce qu'un workspace ?

Un **workspace** est un environnement isolé avec son propre fichier d'état (tfstate).

### Workspace par défaut

Terraform crée automatiquement le workspace `default`.

```bash
# Voir le workspace actuel
terraform workspace show

# Résultat : default
```

### États séparés

```
.terraform/
└── terraform.tfstate.d/
    ├── dev/
    │   └── terraform.tfstate
    ├── staging/
    │   └── terraform.tfstate
    └── prod/
        └── terraform.tfstate
```

Chaque workspace a son propre état, donc ses propres ressources.

## 🛠️ Commandes workspace

### Lister les workspaces

```bash
# Lister tous les workspaces
terraform workspace list

# Résultat :
#   default
# * dev        ← Workspace actuel (*)
#   staging
#   prod
```

### Créer un workspace

```bash
# Créer et basculer vers un nouveau workspace
terraform workspace new dev

# Créer sans basculer
terraform workspace new staging
```

### Basculer entre workspaces

```bash
# Basculer vers un workspace existant
terraform workspace select dev

# Vérifier
terraform workspace show
# Résultat : dev
```

### Supprimer un workspace

```bash
# Supprimer un workspace (ne supprime PAS les ressources)
terraform workspace delete staging

# ⚠️ Impossible de supprimer le workspace actuel
# Il faut d'abord basculer vers un autre
```

## 💻 Utiliser les workspaces dans le code

### Variable terraform.workspace

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-${terraform.workspace}"  # rg-dev, rg-staging, rg-prod
  location = "West Europe"

  tags = {
    environment = terraform.workspace
  }
}
```

### Configurations conditionnelles

```hcl
locals {
  # Configuration par workspace
  vm_size = {
    dev     = "Standard_B2s"
    staging = "Standard_D2s_v3"
    prod    = "Standard_D4s_v3"
  }

  # Nombre d'instances par workspace
  instance_count = {
    dev     = 1
    staging = 2
    prod    = 3
  }

  # Tags par workspace
  tags = {
    environment = terraform.workspace
    managed_by  = "terraform"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  count = local.instance_count[terraform.workspace]

  name                = "vm-web-${terraform.workspace}-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = local.vm_size[terraform.workspace]
  # ...

  tags = local.tags
}
```

### Variables par workspace

```hcl
# variables.tf
variable "environment_config" {
  type = map(object({
    location            = string
    vm_size             = string
    instance_count      = number
    enable_monitoring   = bool
  }))
  default = {
    dev = {
      location          = "West Europe"
      vm_size           = "Standard_B2s"
      instance_count    = 1
      enable_monitoring = false
    }
    staging = {
      location          = "North Europe"
      vm_size           = "Standard_D2s_v3"
      instance_count    = 2
      enable_monitoring = true
    }
    prod = {
      location          = "West Europe"
      vm_size           = "Standard_D4s_v3"
      instance_count    = 3
      enable_monitoring = true
    }
  }
}

# main.tf
locals {
  config = var.environment_config[terraform.workspace]
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${terraform.workspace}"
  location = local.config.location
}
```

**➡️ Voir l'exemple complet** : `../azure/16-workspace/`

## 🚀 Workflow avec workspaces

### Déploiement multi-environnements

```bash
# 1. Créer les workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 2. Déployer sur dev
terraform workspace select dev
terraform plan
terraform apply

# 3. Déployer sur staging
terraform workspace select staging
terraform plan
terraform apply

# 4. Déployer sur prod
terraform workspace select prod
terraform plan
terraform apply
```

### Script d'automatisation

```bash
#!/bin/bash
# deploy-all.sh

for env in dev staging prod; do
  echo "=== Deploying to $env ==="
  terraform workspace select $env
  terraform apply -auto-approve
  echo ""
done
```

**➡️ Voir les scripts complets** : `../azure/16-workspace/apply-all-workspaces.sh`

## ⚠️ Limites des workspaces

### 1. Même backend pour tous les workspaces

```hcl
# Tous les workspaces utilisent le même backend
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    # key change par workspace : dev.tfstate, staging.tfstate, prod.tfstate
  }
}
```

### 2. Pas de séparation de permissions

Tous les workspaces utilisent les mêmes credentials Azure. Impossible d'avoir des permissions différentes par environnement.

### 3. État dans le même storage

Si le storage backend est compromis, tous les environnements sont affectés.

### 4. Risque d'erreur humaine

```bash
# Risque : Déployer sur prod en croyant être sur dev
terraform workspace show  # Toujours vérifier !
terraform apply
```

## 🎯 Workspaces vs Autres approches

| Approche | Avantages | Inconvénients |
|----------|-----------|---------------|
| **Workspaces** | Simple, même code | Même backend, permissions |
| **Dossiers séparés** | Isolation totale | Duplication de code |
| **Fichiers tfvars** | Simple, flexible | Pas d'isolation d'état |
| **Modules** | Réutilisable | Plus complexe |

### Alternative : Dossiers séparés

```
environments/
├── dev/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── staging/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── backend.tf
└── prod/
    ├── main.tf
    ├── terraform.tfvars
    └── backend.tf
```

**Avantages** :
- Isolation complète (différents backends)
- Permissions différentes par environnement
- Moins de risque d'erreur

**Inconvénients** :
- Duplication de code
- Maintenance plus complexe

### Alternative : Modules + tfvars

```
├── modules/
│   └── infrastructure/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── main.tf
```

## 💡 Bonnes pratiques

### 1. Toujours vérifier le workspace

```bash
# Avant chaque opération
terraform workspace show

# Ou intégrer dans le prompt shell
export PS1='[$(terraform workspace show)] \w $ '
```

### 2. Utiliser des noms explicites

```hcl
# ✅ Bon
resource "azurerm_resource_group" "main" {
  name = "rg-myapp-${terraform.workspace}-westeurope"
}

# ⚠️ Risqué : noms trop courts
resource "azurerm_resource_group" "main" {
  name = "rg-${terraform.workspace}"
}
```

### 3. Valider le workspace

```hcl
locals {
  # Valider que le workspace est connu
  valid_workspaces = ["dev", "staging", "prod"]
  is_valid = contains(local.valid_workspaces, terraform.workspace)
}

# Échouer si workspace invalide
resource "null_resource" "validate_workspace" {
  count = local.is_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'Invalid workspace: ${terraform.workspace}' && exit 1"
  }
}
```

### 4. Documenter les workspaces

```markdown
# Workspaces disponibles

- `dev` : Environnement de développement
- `staging` : Environnement de pré-production
- `prod` : Environnement de production

## Usage

\`\`\`bash
terraform workspace select dev
terraform apply -var-file="dev.tfvars"
\`\`\`
```

### 5. Ne pas utiliser pour des clients différents

```
# ❌ Mauvais usage
terraform workspace new client-a
terraform workspace new client-b

# ✅ Bon : Utiliser des dossiers séparés
clients/
├── client-a/
└── client-b/
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Les workspaces permettent plusieurs environnements avec un seul code
- ✅ Chaque workspace a son propre état (tfstate)
- ✅ Utiliser `terraform.workspace` dans le code
- ✅ Commandes : new, select, list, delete, show
- ✅ Limites : même backend, même permissions
- ✅ Alternatives : dossiers séparés, modules + tfvars

## ➡️ Prochaine étape

Maintenant que vous comprenez les workspaces, découvrons comment utiliser un **backend distant** pour collaborer en équipe !

**Prochain module** : [15 - Backend distant](./15-backend-distant.md)

---

🏢 Excellent ! Vous gérez plusieurs environnements. Découvrons le backend distant !
