# Exemple 01 : Provider

## Objectif
Comprendre ce qu'est un **provider** dans Terraform et comment le configurer pour Azure.

## Concepts clés

### Qu'est-ce qu'un Provider ?
- Un provider est un **plugin** qui permet à Terraform de communiquer avec une API externe
- Chaque cloud provider (Azure, AWS, GCP) a son propre provider
- Le provider traduit les commandes Terraform en appels API vers le cloud

### Le provider AzureRM
- **azurerm** est le provider officiel pour Microsoft Azure
- Il gère toutes les ressources Azure (VMs, Storage, Networking, etc.)
- Maintenu par HashiCorp en collaboration avec Microsoft

## Structure du fichier

```hcl
provider "azurerm" {
  features {}
}
```

### Paramètres importants
- `features {}` : Bloc obligatoire pour configurer les comportements du provider
- `subscription_id` : (Optionnel) ID de la subscription Azure à utiliser
- `skip_provider_registration` : (Optionnel) Évite l'enregistrement automatique des resource providers

## Prérequis

### Authentification Azure
Avant d'utiliser le provider, vous devez vous authentifier à Azure. Plusieurs méthodes :

#### 1. Azure CLI (Recommandé pour le développement)
```bash
az login
az account show
```

#### 2. Service Principal (Recommandé pour la production/CI-CD)
```bash
export ARM_CLIENT_ID="xxxxx"
export ARM_CLIENT_SECRET="xxxxx"
export ARM_SUBSCRIPTION_ID="xxxxx"
export ARM_TENANT_ID="xxxxx"
```

#### 3. Managed Identity (Pour les VMs Azure)
Automatique si exécuté depuis une VM avec une Managed Identity

## Commandes

```bash
# 1. Initialiser Terraform (télécharge le provider)
terraform init

# 2. Vérifier la version du provider installé
terraform version

# 3. Afficher les providers utilisés
terraform providers
```

## Points d'attention

### ⚠️ Attention
- Le bloc `features {}` est **obligatoire** même s'il est vide
- Sans authentification Azure, `terraform init` fonctionnera mais `terraform plan` échouera
- La première initialisation peut prendre quelques secondes (téléchargement du provider)

### 📝 Bonnes pratiques
- Ne pas hardcoder le `subscription_id` dans le code (utiliser des variables)
- Utiliser Azure CLI pour le développement local
- Utiliser Service Principal pour les environnements de production

## Ce que fait cet exemple

Ce premier exemple configure simplement le provider Azure sans créer de ressource. C'est la **base minimale** pour tout projet Terraform sur Azure.

## Structure des fichiers

```
01-provider/
├── main.tf          # Configuration du provider
└── README.md        # Ce fichier
```

## Erreurs courantes

### Erreur : "features block is required"
```
Error: Insufficient features blocks
```
**Solution** : Ajoutez un bloc `features {}` dans votre provider

### Erreur : "Error building account"
```
Error: building account: could not acquire access token
```
**Solution** : Authentifiez-vous avec `az login`

### Erreur : "Provider version constraint"
```
Error: Failed to query available provider packages
```
**Solution** : Vérifiez votre connexion internet et réessayez `terraform init`

## Prochaines étapes

Une fois le provider configuré, vous pouvez :
- Créer des ressources Azure (voir exemple 03)
- Configurer des variables (voir exemple 07)
- Gérer l'état distant (voir exemple 10)

## Ressources

- [Documentation Terraform - Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Service Principal Configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
