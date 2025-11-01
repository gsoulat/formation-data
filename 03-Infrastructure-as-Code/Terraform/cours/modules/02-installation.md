# Module 2 : Installation et Configuration

> **Durée : 30 minutes**
>
> Installez Terraform et configurez votre environnement de développement

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Installer Terraform sur macOS, Windows et Linux
- ✅ Installer et configurer Azure CLI et/ou AWS CLI
- ✅ S'authentifier avec votre cloud provider
- ✅ Configurer VS Code avec les extensions Terraform
- ✅ Vérifier que votre environnement est prêt

---

## 🔧 Installation de Terraform

Terraform est distribué sous forme de binaire unique. Plusieurs méthodes d'installation existent selon votre système d'exploitation.

### macOS

**Méthode 1 : Homebrew (Recommandée)**

```bash
# Installer Terraform via Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Vérifier l'installation
terraform version
```

**Méthode 2 : Téléchargement Manuel**

```bash
# Télécharger le binaire
curl -LO https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_darwin_amd64.zip

# Extraire l'archive
unzip terraform_1.6.6_darwin_amd64.zip

# Déplacer le binaire dans /usr/local/bin
sudo mv terraform /usr/local/bin/

# Vérifier l'installation
terraform version
```

### Windows

**Méthode 1 : Chocolatey (Recommandée)**

```powershell
# Installer Terraform via Chocolatey
choco install terraform

# Vérifier l'installation
terraform version
```

**Méthode 2 : Scoop**

```powershell
# Installer Terraform via Scoop
scoop install terraform

# Vérifier l'installation
terraform version
```

**Méthode 3 : Téléchargement Manuel**

1. Téléchargez le ZIP depuis [releases.hashicorp.com](https://releases.hashicorp.com/terraform/)
2. Extrayez `terraform.exe` dans un dossier (ex: `C:\terraform`)
3. Ajoutez ce dossier au PATH système :
   ```powershell
   # PowerShell (en tant qu'administrateur)
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\terraform", "Machine")
   ```
4. Redémarrez votre terminal
5. Vérifiez : `terraform version`

### Linux (Ubuntu/Debian)

**Méthode 1 : Repository HashiCorp (Recommandée)**

```bash
# Installer les dépendances
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Ajouter la clé GPG HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Ajouter le repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Installer Terraform
sudo apt update
sudo apt install terraform

# Vérifier l'installation
terraform version
```

**Méthode 2 : Téléchargement Manuel**

```bash
# Télécharger le binaire
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip

# Extraire l'archive
unzip terraform_1.6.6_linux_amd64.zip

# Déplacer le binaire dans /usr/local/bin
sudo mv terraform /usr/local/bin/

# Rendre le binaire exécutable
sudo chmod +x /usr/local/bin/terraform

# Vérifier l'installation
terraform version
```

### Vérification de l'Installation

Quelle que soit votre méthode, vérifiez que Terraform est correctement installé :

```bash
terraform version
```

**Résultat attendu :**

```
Terraform v1.6.6
on darwin_amd64
```

**Commande d'aide :**

```bash
terraform help
```

---

## ☁️ Installation des CLI Cloud

Pour interagir avec votre cloud provider, vous devez installer leur CLI respective.

### Azure CLI

**macOS**

```bash
# Via Homebrew
brew update && brew install azure-cli

# Vérifier l'installation
az version
```

**Windows**

```powershell
# Via Chocolatey
choco install azure-cli

# OU télécharger l'installateur MSI
# https://aka.ms/installazurecliwindows
```

**Linux (Ubuntu/Debian)**

```bash
# Installation via script officiel
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Vérifier l'installation
az version
```

**Documentation complète :**
- https://docs.microsoft.com/cli/azure/install-azure-cli

### AWS CLI

**macOS**

```bash
# Télécharger et installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Vérifier l'installation
aws --version
```

**Windows**

```powershell
# Télécharger l'installateur MSI
# https://awscli.amazonaws.com/AWSCLIV2.msi

# Via Chocolatey
choco install awscli

# Vérifier l'installation
aws --version
```

**Linux**

```bash
# Télécharger et installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Vérifier l'installation
aws --version
```

**Documentation complète :**
- https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Google Cloud CLI (Optionnel)

**macOS**

```bash
brew install --cask google-cloud-sdk
```

**Windows / Linux**

Suivez le guide officiel : https://cloud.google.com/sdk/docs/install

---

## 🔐 Authentification avec les Cloud Providers

### Authentification Azure

**1. Se connecter à Azure**

```bash
# Ouvre une fenêtre de navigateur pour l'authentification
az login
```

**2. Vérifier le compte connecté**

```bash
# Afficher les informations du compte
az account show

# Afficher toutes les subscriptions disponibles
az account list --output table
```

**3. Sélectionner une subscription spécifique**

```bash
# Définir la subscription par défaut
az account set --subscription "VOTRE_SUBSCRIPTION_ID"

# Vérifier la subscription active
az account show --query name
```

**4. Créer un Service Principal (Pour CI/CD)**

```bash
# Créer un Service Principal avec rôle Contributor
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/VOTRE_SUBSCRIPTION_ID

# Résultat :
{
  "appId": "xxxxx-xxxx-xxxx-xxxx-xxxxx",
  "displayName": "terraform-sp",
  "password": "xxxxx-xxxx-xxxx-xxxx-xxxxx",
  "tenant": "xxxxx-xxxx-xxxx-xxxx-xxxxx"
}
```

**⚠️ Important :** Sauvegardez ces credentials de manière sécurisée !

**5. Configurer Terraform avec le Service Principal**

```hcl
# provider.tf
provider "azurerm" {
  features {}

  subscription_id = "xxxxx-xxxx-xxxx-xxxx-xxxxx"
  client_id       = "xxxxx-xxxx-xxxx-xxxx-xxxxx"  # appId
  client_secret   = "xxxxx-xxxx-xxxx-xxxx-xxxxx"  # password
  tenant_id       = "xxxxx-xxxx-xxxx-xxxx-xxxxx"
}
```

**Ou via variables d'environnement (Recommandé) :**

```bash
export ARM_SUBSCRIPTION_ID="xxxxx-xxxx-xxxx-xxxx-xxxxx"
export ARM_CLIENT_ID="xxxxx-xxxx-xxxx-xxxx-xxxxx"
export ARM_CLIENT_SECRET="xxxxx-xxxx-xxxx-xxxx-xxxxx"
export ARM_TENANT_ID="xxxxx-xxxx-xxxx-xxxx-xxxxx"
```

### Authentification AWS

**1. Configurer les credentials**

```bash
# Configuration interactive
aws configure

# Vous devrez fournir :
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (ex: eu-west-1)
# - Default output format (ex: json)
```

**2. Vérifier la configuration**

```bash
# Afficher l'identité du compte
aws sts get-caller-identity

# Lister les régions disponibles
aws ec2 describe-regions --output table
```

**3. Créer un utilisateur IAM pour Terraform**

```bash
# Via la console AWS :
# 1. IAM → Users → Add user
# 2. Access type: Programmatic access
# 3. Attach policies: AdministratorAccess (ou plus restrictif)
# 4. Copier Access Key ID et Secret Access Key
```

**4. Configurer Terraform avec les credentials**

```bash
# ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Ou via variables d'environnement :**

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="eu-west-1"
```

---

## 🖥️ Configuration de l'Éditeur de Code

### VS Code (Recommandé)

**1. Installer VS Code**

Téléchargez depuis : https://code.visualstudio.com/

**2. Installer l'extension HashiCorp Terraform**

**Méthode 1 : Via l'interface VS Code**
1. Ouvrez VS Code
2. Allez dans Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Recherchez "HashiCorp Terraform"
4. Cliquez sur "Install"

**Méthode 2 : Via la ligne de commande**

```bash
code --install-extension hashicorp.terraform
```

**3. Installer l'extension Azure Terraform (Optionnel)**

```bash
code --install-extension ms-azuretools.vscode-azureterraform
```

**4. Configuration recommandée de VS Code**

Ajoutez ces paramètres dans votre `settings.json` :

```json
{
  // Terraform
  "terraform.languageServer.enable": true,
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.codelens.referenceCount": true,

  // Format on save
  "[terraform]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "hashicorp.terraform"
  },

  // Files associations
  "files.associations": {
    "*.tf": "terraform",
    "*.tfvars": "terraform"
  }
}
```

**5. Extensions Complémentaires Utiles**

```bash
# Azure Account (pour gérer vos ressources Azure depuis VS Code)
code --install-extension ms-vscode.azure-account

# AWS Toolkit
code --install-extension amazonwebservices.aws-toolkit-vscode

# YAML (pour les fichiers de configuration)
code --install-extension redhat.vscode-yaml

# GitLens (pour Git)
code --install-extension eamodio.gitlens
```

### IntelliJ IDEA / PyCharm (Alternative)

**1. Installer le plugin Terraform**
1. File → Settings → Plugins
2. Recherchez "Terraform and HCL"
3. Installez le plugin

**2. Configurer le plugin**
1. File → Settings → Languages & Frameworks → Terraform
2. Cochez "Enable Terraform support"

### Vim/Neovim (Pour les puristes)

```bash
# Installer vim-terraform
git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform

# Ajouter dans ~/.vimrc
let g:terraform_fmt_on_save=1
let g:terraform_align=1
```

---

## ✅ Vérification de l'Environnement

Vérifiez que tout est correctement configuré :

### Checklist

```bash
# 1. Terraform installé
terraform version
# ✅ Terraform v1.6.6

# 2. Azure CLI installé (si vous utilisez Azure)
az version
# ✅ azure-cli 2.54.0

# 3. Authentification Azure fonctionnelle
az account show
# ✅ Affiche votre subscription

# 4. AWS CLI installé (si vous utilisez AWS)
aws --version
# ✅ aws-cli/2.13.0

# 5. Authentification AWS fonctionnelle
aws sts get-caller-identity
# ✅ Affiche votre identité

# 6. VS Code avec extension Terraform
code --list-extensions | grep terraform
# ✅ hashicorp.terraform
```

### Test Rapide

Créez un fichier de test pour valider l'installation :

```bash
# Créer un dossier de test
mkdir ~/terraform-test
cd ~/terraform-test

# Créer un fichier main.tf
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
}

# Simple output pour tester
output "hello" {
  value = "Terraform is installed correctly!"
}
EOF

# Initialiser Terraform
terraform init

# Valider la configuration
terraform validate

# Voir l'output
terraform apply -auto-approve
```

**Résultat attendu :**

```
Outputs:

hello = "Terraform is installed correctly!"
```

**Nettoyer le test :**

```bash
cd ~
rm -rf ~/terraform-test
```

---

## 🎨 Auto-complétion dans le Terminal

Activez l'auto-complétion pour faciliter l'utilisation de Terraform.

### Bash

```bash
# Ajouter dans ~/.bashrc
terraform -install-autocomplete

# Recharger le shell
source ~/.bashrc
```

### Zsh

```bash
# Ajouter dans ~/.zshrc
terraform -install-autocomplete

# Recharger le shell
source ~/.zshrc
```

### PowerShell

```powershell
# Installer le module PSReadLine
Install-Module -Name PSReadLine -Force

# Ajouter dans $PROFILE
Set-PSReadLineOption -PredictionSource History
```

---

## 🔒 Bonnes Pratiques de Sécurité

### Gestion des Credentials

**❌ Ne JAMAIS faire :**

```hcl
# NE JAMAIS mettre les credentials en dur dans le code !
provider "azurerm" {
  subscription_id = "xxxxx-xxxx-xxxx-xxxx-xxxxx"  # ❌ BAD
  client_id       = "xxxxx-xxxx-xxxx-xxxx-xxxxx"  # ❌ BAD
  client_secret   = "super-secret-password"        # ❌ BAD
}
```

**✅ À faire :**

**Option 1 : Variables d'environnement**

```bash
# Dans ~/.bashrc ou ~/.zshrc
export ARM_SUBSCRIPTION_ID="xxxxx"
export ARM_CLIENT_ID="xxxxx"
export ARM_CLIENT_SECRET="xxxxx"
export ARM_TENANT_ID="xxxxx"
```

```hcl
# Dans provider.tf
provider "azurerm" {
  features {}
  # Les credentials sont automatiquement lus depuis les variables d'environnement
}
```

**Option 2 : Fichier de credentials externe (non versionné)**

```bash
# credentials.auto.tfvars (ajouté dans .gitignore)
subscription_id = "xxxxx"
client_id       = "xxxxx"
client_secret   = "xxxxx"
tenant_id       = "xxxxx"
```

```hcl
# variables.tf
variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "client_id" {
  type      = string
  sensitive = true
}

# provider.tf
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
}
```

**Option 3 : Utiliser Azure Managed Identity ou AWS IAM Roles**

Le plus sécurisé en production (pas de credentials à gérer).

### .gitignore pour Terraform

Créez toujours un `.gitignore` dans vos projets Terraform :

```gitignore
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

# IDE
.vscode/
.idea/
*.swp
*.swo
```

---

## 📝 Points Clés à Retenir

1. **Terraform** : Binaire unique, facile à installer
2. **CLI Cloud** : Nécessaire pour l'authentification (az, aws, gcloud)
3. **VS Code + Extension** : Meilleur environnement de développement
4. **Authentification** : Utilisez des variables d'environnement ou des Service Principals
5. **Sécurité** : Ne jamais versionner les credentials
6. **Auto-complétion** : Améliore grandement l'expérience
7. **Vérification** : Toujours tester que l'environnement fonctionne

---

## ✅ Quiz de Compréhension

1. Quelle commande permet de vérifier la version de Terraform installée ?
2. Comment s'authentifier avec Azure pour Terraform ?
3. Quelle extension VS Code est recommandée pour Terraform ?
4. Pourquoi ne doit-on JAMAIS mettre les credentials dans le code ?
5. Quel fichier doit contenir les patterns pour ignorer les fichiers sensibles ?

---

## 🚀 Prochaine Étape

Votre environnement est maintenant configuré ! Il est temps de créer votre premier projet Terraform.

**➡️ [Module 3 : Premier Projet Terraform](03-premier-projet.md)**

Dans le prochain module, vous allez :
- Créer votre premier fichier Terraform
- Comprendre la structure d'un projet
- Exécuter les commandes `init`, `plan`, `apply`, `destroy`
- Déployer votre première ressource Azure

---

## 📚 Ressources Complémentaires

- [Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [VS Code Terraform Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Terraform Environment Variables](https://www.terraform.io/cli/config/environment-variables)

---

[⬅️ Module précédent](01-introduction.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](03-premier-projet.md)
