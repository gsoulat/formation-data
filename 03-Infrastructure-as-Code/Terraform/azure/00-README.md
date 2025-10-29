# Formation Terraform - Azure

Ce guide vous aide � installer les outils n�cessaires et � vous authentifier sur Azure pour suivre cette formation.

## Pr�requis

- Un compte Azure actif
- Un terminal (Bash, PowerShell, ou �quivalent)
- Droits d'administration sur votre machine

## Installation

### Azure CLI

#### Linux

```bash
# M�thode recommand�e via script
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Ou via apt (Ubuntu/Debian)
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli
```

#### Windows (Chocolatey)

```powershell
# Installer Chocolatey si ce n'est pas d�j� fait
# Voir https://chocolatey.org/install

# Installer Azure CLI
choco install azure-cli -y
```

#### macOS (Homebrew)

```bash
# Installer Homebrew si ce n'est pas d�j� fait
# Voir https://brew.sh

# Installer Azure CLI
brew update && brew install azure-cli
```

#### V�rification de l'installation

```bash
az --version
```

### Terraform

#### Linux

```bash
# T�l�charger et installer la derni�re version
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### Windows (Chocolatey)

```powershell
choco install terraform -y
```

#### macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

#### V�rification de l'installation

```bash
terraform --version
```

## Authentification sur Azure

### M�thode 1 : Connexion interactive (recommand�e pour le d�veloppement)

```bash
# Se connecter � Azure
az login

# Lister vos souscriptions
az account list --output table

# D�finir la souscription par d�faut
az account set --subscription "VOTRE_SUBSCRIPTION_ID"

# V�rifier la souscription active
az account show
```

### M�thode 2 : Service Principal (recommand�e pour la production/CI-CD)

```bash
# Cr�er un Service Principal
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/VOTRE_SUBSCRIPTION_ID"

# La commande retourne :
# {
#   "appId": "xxxxx",
#   "displayName": "terraform-sp",
#   "password": "xxxxx",
#   "tenant": "xxxxx"
# }
```

Puis d�finissez les variables d'environnement :

**Linux/macOS :**
```bash
export ARM_CLIENT_ID="appId"
export ARM_CLIENT_SECRET="password"
export ARM_SUBSCRIPTION_ID="VOTRE_SUBSCRIPTION_ID"
export ARM_TENANT_ID="tenant"
```

**Windows (PowerShell) :**
```powershell
$env:ARM_CLIENT_ID="appId"
$env:ARM_CLIENT_SECRET="password"
$env:ARM_SUBSCRIPTION_ID="VOTRE_SUBSCRIPTION_ID"
$env:ARM_TENANT_ID="tenant"
```

### M�thode 3 : Managed Identity (pour les ressources Azure)

Si vous ex�cutez Terraform depuis une VM Azure avec une Managed Identity, aucune configuration suppl�mentaire n'est n�cessaire.

## Configuration du provider Azure dans Terraform

Dans vos fichiers Terraform, configurez le provider :

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "VOTRE_SUBSCRIPTION_ID"  # Optionnel si d�j� d�fini via az login
}
```

## R�cup�rer votre Subscription ID

```bash
# Afficher votre subscription ID
az account show --query id --output tsv
```

## Commandes Terraform de base

```bash
# Initialiser le r�pertoire Terraform
terraform init

# Formater le code
terraform fmt

# Valider la configuration
terraform validate

# Pr�visualiser les changements
terraform plan

# Appliquer les changements
terraform apply

# D�truire les ressources
terraform destroy
```

## Ressources utiles

- [Documentation Azure CLI](https://docs.microsoft.com/cli/azure/)
- [Documentation Terraform](https://www.terraform.io/docs)
- [Provider AzureRM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Portal](https://portal.azure.com)

## Support

Pour toute question, consultez la documentation officielle ou contactez votre formateur.
