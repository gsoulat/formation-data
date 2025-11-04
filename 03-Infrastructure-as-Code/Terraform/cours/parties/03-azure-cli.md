# 03 - Installation et configuration d'Azure CLI

## 📖 Introduction

Pour que Terraform puisse créer des ressources sur Azure, il faut d'abord installer Azure CLI et se connecter à votre compte Azure. Ce module vous guide à travers l'installation et la configuration complète.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Installer Azure CLI sur votre système d'exploitation
- ✅ Se connecter à Azure avec `az login`
- ✅ Gérer plusieurs abonnements Azure
- ✅ Créer un Service Principal pour l'authentification
- ✅ Configurer les variables d'environnement pour Terraform

## 🌐 Qu'est-ce qu'Azure CLI ?

**Azure CLI** est un outil en ligne de commande pour gérer les ressources Azure. Il permet de :

- 🔐 S'authentifier auprès d'Azure
- 📋 Lister et gérer les ressources
- 🚀 Automatiser les tâches Azure
- 🔗 Fournir l'authentification à Terraform

## 📦 Installation d'Azure CLI

### 🐧 Installation sur Ubuntu / Linux

```bash
# Méthode 1 : Installation rapide via curl (Recommandée)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Vérifier l'installation
az version
```

#### Méthode 2 : Installation manuelle (Ubuntu/Debian)

```bash
# 1. Installer les dépendances
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

# 2. Télécharger et installer la clé de signature Microsoft
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
  gpg --dearmor |
  sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

# 3. Ajouter le repository Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
  sudo tee /etc/apt/sources.list.d/azure-cli.list

# 4. Installer Azure CLI
sudo apt-get update
sudo apt-get install azure-cli

# 5. Vérifier
az version
```

### 🪟 Installation sur Windows

#### Méthode 1 : Avec Chocolatey (Recommandée)

```powershell
# Installer Azure CLI avec Chocolatey
choco install azure-cli

# Vérifier l'installation
az version
```

#### Méthode 2 : Avec winget (Windows 11/10)

```powershell
# Installer avec winget
winget install -e --id Microsoft.AzureCLI

# Vérifier
az version
```

#### Méthode 3 : Installateur MSI

1. Télécharger depuis : https://aka.ms/installazurecliwindows
2. Exécuter le fichier MSI téléchargé
3. Suivre l'assistant d'installation
4. Redémarrer le terminal
5. Vérifier : `az version`

### 🍎 Installation sur macOS

#### Méthode 1 : Avec Homebrew (Recommandée)

```bash
# Installer Azure CLI
brew update && brew install azure-cli

# Vérifier l'installation
az version

# Pour mettre à jour plus tard
brew upgrade azure-cli
```

#### Méthode 2 : Installation manuelle

```bash
# Télécharger et installer
curl -L https://aka.ms/InstallAzureCli | bash

# Recharger le shell
exec -l $SHELL

# Vérifier
az version
```

## 🔐 Configuration et authentification

### Première connexion à Azure

```bash
# Se connecter à Azure (ouvre le navigateur)
az login

# La commande ouvrira votre navigateur web
# Connectez-vous avec vos identifiants Azure
# Une fois connecté, vous verrez vos abonnements dans le terminal
```

**Résultat attendu** :
```json
[
  {
    "cloudName": "AzureCloud",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "isDefault": true,
    "name": "Mon Abonnement Azure",
    "state": "Enabled",
    "tenantId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
    "user": {
      "name": "votre.email@domain.com",
      "type": "user"
    }
  }
]
```

### Gérer plusieurs abonnements

Si vous avez plusieurs abonnements Azure :

```bash
# Lister tous vos abonnements
az account list --output table

# Afficher l'abonnement actuel
az account show

# Définir un abonnement par défaut
az account set --subscription "Nom-de-votre-abonnement"
# ou
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Vérifier le changement
az account show --query "{Name:name, ID:id}" --output table
```

### Obtenir les informations de votre abonnement

```bash
# Afficher l'ID de votre abonnement
az account show --query id --output tsv

# Afficher votre Tenant ID
az account show --query tenantId --output tsv

# Afficher toutes les infos importantes
az account show --output json
```

## 🔑 Créer un Service Principal (pour CI/CD)

Un **Service Principal** est comme un compte de service qui permet à Terraform de s'authentifier automatiquement sans intervention humaine.

### Pourquoi créer un Service Principal ?

- ✅ Authentification automatisée
- ✅ Idéal pour CI/CD (GitHub Actions, Azure DevOps)
- ✅ Permissions limitées (principe du moindre privilège)
- ✅ Pas de MFA (authentification multifacteur) requis

### Créer le Service Principal

```bash
# Créer un Service Principal avec le rôle "Contributor"
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/VOTRE-SUBSCRIPTION-ID"

# Remplacez VOTRE-SUBSCRIPTION-ID par votre vrai ID
# Vous pouvez l'obtenir avec : az account show --query id --output tsv
```

**Résultat** (IMPORTANT : Sauvegardez ces informations !) :
```json
{
  "appId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "displayName": "terraform-sp",
  "password": "votre-secret-tres-long",
  "tenant": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}
```

**⚠️ ATTENTION** : Sauvegardez le `password` immédiatement ! Vous ne pourrez plus le récupérer.

### Correspondance pour Terraform

| Azure CLI | Variable Terraform | Description |
|-----------|-------------------|-------------|
| `appId` | `client_id` | ID de l'application |
| `password` | `client_secret` | Secret de l'application |
| `tenant` | `tenant_id` | ID du tenant Azure AD |
| Votre subscription ID | `subscription_id` | ID de votre abonnement |

## 🌍 Configuration des variables d'environnement

### Linux / macOS

Ajoutez ces lignes à votre `~/.bashrc` ou `~/.zshrc` :

```bash
# Variables d'environnement Azure pour Terraform
export ARM_CLIENT_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
export ARM_CLIENT_SECRET="votre-secret"
export ARM_SUBSCRIPTION_ID="votre-subscription-id"
export ARM_TENANT_ID="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

# Recharger le fichier
source ~/.bashrc  # ou source ~/.zshrc
```

### Windows PowerShell

```powershell
# Définir les variables d'environnement (session courante)
$env:ARM_CLIENT_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
$env:ARM_CLIENT_SECRET="votre-secret"
$env:ARM_SUBSCRIPTION_ID="votre-subscription-id"
$env:ARM_TENANT_ID="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

# Pour rendre les variables permanentes
[System.Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "User")
[System.Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", "votre-secret", "User")
[System.Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "votre-subscription-id", "User")
[System.Environment]::SetEnvironmentVariable("ARM_TENANT_ID", "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "User")
```

### Windows CMD

```cmd
# Session courante
set ARM_CLIENT_ID=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
set ARM_CLIENT_SECRET=votre-secret
set ARM_SUBSCRIPTION_ID=votre-subscription-id
set ARM_TENANT_ID=bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb

# Pour rendre permanent : Variables système via le Panneau de configuration
```

## ✅ Tester l'authentification

### Test avec Azure CLI

```bash
# Lister les resource groups (devrait fonctionner)
az group list --output table

# Vérifier les permissions
az role assignment list --assignee "terraform-sp" --output table
```

### Test avec Terraform

Créez un fichier `test-auth.tf` :

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Si variables d'environnement définies, pas besoin de ces lignes
  # subscription_id = "votre-id"
  # client_id       = "votre-client-id"
  # client_secret   = "votre-secret"
  # tenant_id       = "votre-tenant-id"
}

# Test : récupérer l'abonnement actuel
data "azurerm_subscription" "current" {}

output "subscription_name" {
  value = data.azurerm_subscription.current.display_name
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
```

Testez :

```bash
# Initialiser
terraform init

# Planifier (devrait fonctionner sans erreur)
terraform plan

# Voir les outputs
terraform apply
```

## 🔒 Sécurité des credentials

### ❌ Mauvaises pratiques

```hcl
# NE JAMAIS FAIRE ÇA !
provider "azurerm" {
  subscription_id = "xxx-xxx-xxx"  # En dur dans le code
  client_secret   = "mon-secret"   # Secret en clair !
}
```

### ✅ Bonnes pratiques

1. **Utiliser les variables d'environnement** (déjà configurées)
2. **Utiliser un fichier .env** (à ne jamais commiter)
3. **Utiliser Azure Key Vault** (pour la production)
4. **Utiliser Managed Identity** (sur Azure VM)

### Fichier .env (optionnel)

```bash
# Créer un fichier .env
cat > .env << 'EOF'
export ARM_CLIENT_ID="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
export ARM_CLIENT_SECRET="votre-secret"
export ARM_SUBSCRIPTION_ID="votre-subscription-id"
export ARM_TENANT_ID="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
EOF

# Charger les variables
source .env

# IMPORTANT : Ajouter .env au .gitignore !
echo ".env" >> .gitignore
```

## 📋 Commandes Azure CLI utiles

```bash
# Lister les locations Azure disponibles
az account list-locations --output table

# Lister les types de ressources disponibles
az provider list --output table

# Obtenir les détails d'un resource group
az group show --name "mon-rg" --output json

# Créer un resource group (test)
az group create --name "test-rg" --location "westeurope"

# Supprimer un resource group
az group delete --name "test-rg" --yes --no-wait

# Vérifier les quotas
az vm list-usage --location "westeurope" --output table

# Afficher les coûts
az consumption usage list --output table
```

## 🐛 Problèmes courants

### Problème 1 : "az: command not found"

**Solution** : Le PATH n'est pas configuré
```bash
# Fermer et rouvrir le terminal
# ou
source ~/.bashrc  # Linux/macOS
```

### Problème 2 : "No subscriptions found"

**Solution** : Vous n'avez pas d'abonnement Azure actif
```bash
# Créer un compte gratuit sur https://azure.microsoft.com/free/
```

### Problème 3 : Échec de connexion avec az login

**Solution** : Problème de navigateur
```bash
# Utiliser le mode device code
az login --use-device-code

# Suivre les instructions affichées
```

### Problème 4 : Service Principal sans permissions

**Solution** : Assigner les bonnes permissions
```bash
# Vérifier les permissions actuelles
az role assignment list --assignee "APP-ID" --output table

# Assigner le rôle Contributor
az role assignment create \
  --assignee "APP-ID" \
  --role "Contributor" \
  --scope "/subscriptions/SUBSCRIPTION-ID"
```

## 💰 Créer un compte Azure gratuit

Si vous n'avez pas encore de compte Azure :

1. Allez sur : https://azure.microsoft.com/free/
2. Cliquez sur "Commencer gratuitement"
3. Connectez-vous avec un compte Microsoft
4. Remplissez les informations demandées
5. **Vous obtenez** :
   - 200$ de crédit valable 30 jours
   - Services gratuits pendant 12 mois
   - Services toujours gratuits

**⚠️ Conseil** : Configurez des alertes de budget pour ne pas avoir de surprises !

## ✅ Checklist de fin de module

Avant de passer au module suivant, assurez-vous que :

- [ ] Azure CLI est installé (`az version` fonctionne)
- [ ] Vous êtes connecté à Azure (`az login` effectué)
- [ ] Vous connaissez votre subscription ID
- [ ] Vous avez créé un Service Principal (optionnel mais recommandé)
- [ ] Les variables d'environnement ARM_* sont configurées
- [ ] Le test d'authentification Terraform fonctionne
- [ ] Vous avez ajouté les secrets au .gitignore

## 📊 Récapitulatif des méthodes d'authentification

| Méthode | Cas d'usage | Sécurité | Difficulté |
|---------|-------------|----------|------------|
| `az login` | Développement local | ⭐⭐⭐ | Facile |
| Service Principal | CI/CD, Automatisation | ⭐⭐ | Moyenne |
| Managed Identity | VM Azure, Container | ⭐⭐⭐⭐ | Facile |
| Variables d'env | Développement | ⭐⭐ | Facile |

## 🎓 Résumé

Dans ce module, vous avez appris à :

- ✅ Installer Azure CLI sur tous les OS
- ✅ Se connecter à Azure avec `az login`
- ✅ Gérer plusieurs abonnements
- ✅ Créer un Service Principal
- ✅ Configurer l'authentification pour Terraform
- ✅ Sécuriser vos credentials

## ➡️ Prochaine étape

Vous avez maintenant Terraform ET Azure CLI configurés ! Il est temps de créer votre **premier projet Terraform** !

**Prochain module** : [04 - Premier projet Terraform](./04-premier-projet.md)

---

🎉 Parfait ! Vous êtes maintenant authentifié sur Azure. Créons notre première infrastructure !
