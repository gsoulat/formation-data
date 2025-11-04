# Exemple 16 : Workspaces

## Objectif
Apprendre à utiliser les **workspaces Terraform** pour gérer plusieurs environnements (dev, staging, prod) avec le même code.

## Concepts clés

### Qu'est-ce qu'un Workspace ?
- Les workspaces permettent de **gérer plusieurs états** avec la même configuration
- Chaque workspace a son propre fichier `terraform.tfstate`
- Le workspace par défaut s'appelle `default`
- Idéal pour gérer plusieurs environnements (dev, staging, prod)

### Avantages
✅ Un seul code pour plusieurs environnements
✅ Isolation complète des états entre environnements
✅ Facile de switcher entre environnements
✅ Réduction de la duplication de code

### Inconvénients
⚠️ Tous les workspaces partagent le même backend
⚠️ Risque d'erreur humaine (mauvais workspace)
⚠️ Difficile de donner des permissions différentes par environnement

## Structure des fichiers

```
16-workspace/
├── main.tf                      # Configuration principale
├── variables.tf                 # Variables
├── outputs.tf                   # Outputs
└── README.md                   # Ce fichier
```

## Commandes essentielles

### Gestion des workspaces

```bash
# Lister tous les workspaces (l'actuel est marqué par *)
terraform workspace list

# Créer un nouveau workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Sélectionner un workspace
terraform workspace select dev
terraform workspace select staging
terraform workspace select prod

# Afficher le workspace actuel
terraform workspace show

# Supprimer un workspace (doit être vide)
terraform workspace delete dev
```

### Workflow complet

#### Méthode 1 : Avec les scripts (Recommandé)

```bash
# 1. Créer votre configuration
cp dev.tfvars.example dev.tfvars

```

#### Méthode 2 : Manuellement

```bash
# 1. Initialiser Terraform
terraform init

# 2. Créer les workspaces pour chaque environnement
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# 3. Déployer en dev
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# 4. Voir les ressources créées
terraform output

# 5. Déployer en staging
terraform workspace select staging
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# 6. Déployer en prod
terraform workspace select prod
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# 7. Comparer les outputs
terraform workspace select dev && terraform output
terraform workspace select staging && terraform output
terraform workspace select prod && terraform output

# 8. Détruire un environnement
terraform workspace select dev
terraform destroy -var-file="dev.tfvars"
```

## Ressources créées par workspace

Cet exemple crée les ressources suivantes pour chaque workspace :

### Resources
- **Resource Group** : Nom basé sur le workspace via `var.rg_names`
  - dev → `rg1dev`
  - staging → `rg1staging`
  - prod → `rg1prod`
  - default → `rg1`

- **Storage Account** : Nom unique par workspace
  - Préfixe : `st` + nom du workspace + suffixe aléatoire
  - Exemple : `stdevabcd`, `stprodxyz`

### Nommage des ressources

```hcl
# Resource Group
name = lookup(var.rg_names, terraform.workspace, var.rg_names.default)

# Storage Account
name = "st${terraform.workspace}${random_string.suffix.result}"
```

### Exemple de résultats

| Workspace | Resource Group | Storage Account | Localisation |
|-----------|----------------|-----------------|--------------|
| dev | rg1dev | stdevabcd | francecentral |
| staging | rg1staging | ststagingabcd | francecentral |
| prod | rg1prod | stprodabcd | francecentral |
| default | rg1 | stdefaultabcd | francecentral |

## Accès au workspace dans le code

```hcl
# Variable Terraform intégrée
terraform.workspace

# Dans cet exemple, on utilise :
locals {
  environment = terraform.workspace
}
```

## Fichiers d'état

Les états sont stockés séparément :
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

## Bonnes pratiques

### ✅ À FAIRE
- Utiliser `terraform.workspace` pour adapter la configuration
- Définir des configurations claires par environnement
- Documenter les différences entre environnements
- Utiliser des noms cohérents (dev, staging, prod)
- Toujours vérifier le workspace actuel avant d'appliquer

### ❌ À ÉVITER
- Ne pas hardcoder le nom du workspace
- Ne pas partager les credentials entre environnements
- Éviter d'avoir trop de différences entre environnements
- Ne pas oublier de sélectionner le bon workspace !

## Vérification du workspace

Toujours vérifier le workspace avant d'appliquer :

```bash
# Afficher le workspace actuel
terraform workspace show

# Ou utiliser un alias
alias tfws='terraform workspace show'

# Ou afficher dans le prompt
# Ajoutez à votre .bashrc ou .zshrc :
export PS1='[\$(terraform workspace show 2>/dev/null)] \$ '
```

## Alternative : Répertoires séparés

Pour des environnements très différents, considérez :
```
environments/
├── dev/
│   └── main.tf
├── staging/
│   └── main.tf
└── prod/
    └── main.tf
```

## Prérequis

1. Créer votre fichier de configuration :
   ```bash
   cp dev.tfvars.example dev.tfvars
   ```

2. Éditer `dev.tfvars` avec votre subscription ID :
   ```hcl
   subscription_id = "votre-subscription-id"
   location        = "francecentral"
   ```

## Ressources

- [Documentation Terraform - Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)
- [When to use workspaces](https://www.terraform.io/docs/cloud/workspaces/index.html)
