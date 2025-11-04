# Exemple 08 : Fichiers tfvars

## Objectif
Apprendre à utiliser les **fichiers .tfvars** pour séparer la configuration des valeurs et gérer plusieurs environnements.

## Concepts clés

### Fichiers .tfvars
- Permettent de **séparer** la déclaration des variables de leurs valeurs
- Format : paires clé-valeur simples
- Extension : `.tfvars` ou `.tfvars.json`
- Utilisation : configurations par environnement (dev, staging, prod)

### Avantages
✅ Code réutilisable (variables.tf)
✅ Valeurs spécifiques par environnement (dev.tfvars, prod.tfvars)
✅ Sécurité (fichiers .tfvars non versionnés)
✅ Collaboration facilitée (fichiers .example)

## Différence avec l'exemple 07

| Exemple 07 | Exemple 08 |
|------------|------------|
| Variables **avec** default | Variables **sans** default |
| Valeurs dans le code | Valeurs dans fichiers .tfvars |
| Moins flexible | Plus flexible |
| OK pour démo | ✅ Meilleur pour production |

## Structure du code

### 1. Variables sans default (variables.tf)
```hcl
variable "resource_group_name" {
  type = string
  # Pas de default !
}

variable "subscription_id" {
  type = string
  # Obligatoire via .tfvars
}

variable "location" {
  type    = string
  default = "westeurope"  # Seulement pour valeurs "sûres"
}
```

### 2. Valeurs dans dev.tfvars
```hcl
resource_group_name  = "rg-myapp-dev"
storage_account_name = "storagedev"
container_name       = "container-dev"
subscription_id      = "votre-subscription-id"
location             = "francecentral"
```

### 3. Template dev.tfvars.example
```hcl
resource_group_name  = ""
storage_account_name = ""
container_name       = ""
subscription_id      = ""
location             = ""
```

## Fichiers .tfvars vs .tfvars.example

### .tfvars (NON versionné)
- Contient les **vraies valeurs**
- Spécifique à chaque développeur/environnement
- **À ajouter dans .gitignore**
- Utilisé pour l'exécution

### .tfvars.example (versionné)
- Contient la **structure** avec des valeurs vides
- Template pour les autres développeurs
- **À versionner** dans Git
- Documentation des variables nécessaires

## Workflow d'utilisation

```bash
# 1. Nouveau développeur clone le projet
git clone <repo>
cd 08-tfvars

# 2. Copie le fichier example
cp dev.tfvars.example dev.tfvars

# 3. Remplit ses propres valeurs
vim dev.tfvars  # ou nano, code, etc.

# 4. Utilise son fichier
terraform init
terraform apply -var-file="dev.tfvars"
```

## Gestion multi-environnements

```
08-tfvars/
├── main.tf
├── variables.tf
├── dev.tfvars           # ❌ Non versionné
├── dev.tfvars.example   # ✅ Versionné
├── staging.tfvars       # ❌ Non versionné
├── staging.tfvars.example  # ✅ Versionné
├── prod.tfvars          # ❌ Non versionné
└── prod.tfvars.example  # ✅ Versionné
```

### Exemple dev.tfvars
```hcl
resource_group_name  = "rg-myapp-dev"
storage_account_name = "storagedev123"
container_name       = "data-dev"
subscription_id      = "xxx-dev-subscription-xxx"
location             = "francecentral"
```

### Exemple prod.tfvars
```hcl
resource_group_name  = "rg-myapp-prod"
storage_account_name = "storageprod456"
container_name       = "data-prod"
subscription_id      = "xxx-prod-subscription-xxx"
location             = "westeurope"
```

## Prérequis

1. Avoir complété l'exemple 07 (comprendre les variables)
2. Provider Azure configuré
3. Authentification Azure

## Commandes

```bash
# 1. Créer votre fichier de config
cp dev.tfvars.example dev.tfvars
# Puis éditer dev.tfvars avec vos valeurs

# 2. Initialiser
terraform init

# 3. Voir le plan avec le fichier dev
terraform plan -var-file="dev.tfvars"

# 4. Appliquer avec dev
terraform apply -var-file="dev.tfvars"

# 5. Appliquer avec prod (si vous avez prod.tfvars)
terraform apply -var-file="prod.tfvars"

# 6. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Fichier .gitignore

Ajoutez ceci à votre `.gitignore` :

```gitignore
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Variable files with values
*.tfvars
!*.tfvars.example

# Crash log files
crash.log

# Ignore override files
override.tf
override.tf.json
```

Le `!*.tfvars.example` permet d'inclure les fichiers `.example` tout en excluant les autres `.tfvars`.

## terraform.tfvars (spécial)

Si vous créez un fichier nommé exactement `terraform.tfvars`, il est **chargé automatiquement** :

```bash
# Avec terraform.tfvars présent
terraform apply  # ✅ Charge automatiquement terraform.tfvars

# Avec dev.tfvars
terraform apply -var-file="dev.tfvars"  # ⚠️ Doit être explicite
```

Fichiers chargés automatiquement :
- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

## Points d'attention

### ⚠️ Sécurité
- **JAMAIS** commiter de fichiers `.tfvars` avec des vraies valeurs
- Toujours vérifier le `.gitignore` avant de commit
- Utiliser des secrets managers pour les valeurs très sensibles (passwords, API keys)

### 📝 Bonnes pratiques

1. **Toujours** créer un fichier `.example` pour documentation
2. **Nommer** les fichiers selon l'environnement : `dev.tfvars`, `prod.tfvars`
3. **Valider** que les .tfvars ne sont pas dans Git : `git status`
4. **Documenter** dans le README quelles variables sont nécessaires
5. **Grouper** les variables par catégorie dans le fichier

### ✅ Structure recommandée d'un .tfvars

```hcl
# ============================================
# INFRASTRUCTURE
# ============================================
resource_group_name = "rg-myapp-dev"
location            = "francecentral"

# ============================================
# STORAGE
# ============================================
storage_account_name = "storagedev"
container_name       = "data"

# ============================================
# AUTHENTICATION
# ============================================
subscription_id = "xxx-xxx-xxx"

# ============================================
# CONFIGURATION
# ============================================
environment = "dev"
enable_backup = false
```

## Structure des fichiers

```
08-tfvars/
├── main.tf               # Configuration Terraform
├── variable.tf           # Déclaration des variables (sans default)
├── dev.tfvars.example    # ✅ Template versionné
└── README.md             # Ce fichier

# Fichiers à créer localement (non versionnés)
└── dev.tfvars           # ❌ Vos valeurs réelles
```

## Exemple complet

### variables.tf
```hcl
variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable monitoring"
  default     = false
}
```

### dev.tfvars
```hcl
project_name      = "myapp"
environment       = "dev"
subscription_id   = "your-dev-subscription-id"
location          = "francecentral"
enable_monitoring = false
```

### prod.tfvars
```hcl
project_name      = "myapp"
environment       = "prod"
subscription_id   = "your-prod-subscription-id"
location          = "westeurope"
enable_monitoring = true
```

## Vérification

Pour vérifier que vous n'allez pas commiter de secrets :

```bash
# Voir les fichiers qui vont être commités
git status

# Voir les fichiers ignorés
git status --ignored

# Vérifier qu'un fichier est bien ignoré
git check-ignore dev.tfvars
# Doit retourner : dev.tfvars

# Voir tous les fichiers .tfvars ignorés
git check-ignore *.tfvars
```

## Erreurs courantes

### Erreur : No value for required variable
```
Error: No value for required variable
on variables.tf line 1:
  1: variable "subscription_id" {
```
**Solution** : Créez votre fichier `.tfvars` ou passez `-var="subscription_id=xxx"`

### Erreur : Tfvars file not found
```
Error: Failed to read variables file
```
**Solution** : Vérifiez le chemin du fichier `.tfvars`

### Erreur : Values committed to Git
```
# ⚠️ Vous voyez dev.tfvars dans git status
```
**Solution** :
```bash
git rm --cached dev.tfvars
echo "*.tfvars" >> .gitignore
git add .gitignore
git commit -m "Remove tfvars from git"
```

## Exercices

1. **Multi-environnement** : Créez `staging.tfvars` et `prod.tfvars` avec des valeurs différentes
2. **Validation** : Ajoutez une validation sur la variable `environment`
3. **Secrets** : Marquez les variables sensibles avec `sensitive = true`
4. **Auto-load** : Renommez `dev.tfvars` en `terraform.tfvars` et testez le chargement automatique

## Prochaines étapes

- Ajouter des outputs pour visualiser les valeurs (voir exemple 09)
- Utiliser un backend distant pour l'état (voir exemple 10)
- Intégrer avec CI/CD pour déployer automatiquement

## Ressources

- [Documentation Terraform - Input Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Variable Files (.tfvars)](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files)
- [.gitignore for Terraform](https://github.com/github/gitignore/blob/main/Terraform.gitignore)
