# 02 - Installation de Terraform

## 📖 Introduction

Maintenant que vous comprenez ce qu'est Terraform, il est temps de l'installer sur votre machine ! Ce module vous guidera à travers l'installation sur les trois systèmes d'exploitation principaux : Ubuntu (Linux), Windows et macOS.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Installer Terraform sur Ubuntu/Linux
- ✅ Installer Terraform sur Windows avec Chocolatey
- ✅ Installer Terraform sur macOS avec Homebrew
- ✅ Vérifier l'installation de Terraform
- ✅ Configurer votre premier environnement de travail

## 💻 Prérequis système

Terraform fonctionne sur pratiquement tous les systèmes :

| OS | Versions supportées |
|----|---------------------|
| **Windows** | Windows 10/11, Server 2016+ |
| **macOS** | macOS 10.15 (Catalina) ou plus récent |
| **Linux** | Ubuntu 18.04+, Debian, RHEL, CentOS, etc. |

**Ressources minimales** :
- 💾 RAM : 512 MB minimum (2 GB recommandé)
- 💿 Espace disque : 100 MB pour Terraform
- 🌐 Connexion internet (pour télécharger les providers)

## 🐧 Installation sur Ubuntu / Linux

### Méthode 1 : Installation via le repository HashiCorp (Recommandée)

Cette méthode garantit que vous obtenez toujours la dernière version via `apt update`.

```bash
# 1. Installer les dépendances
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# 2. Installer la clé GPG HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# 3. Vérifier l'empreinte de la clé
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# 4. Ajouter le repository HashiCorp
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# 5. Mettre à jour et installer Terraform
sudo apt update
sudo apt-get install terraform

# 6. Vérifier l'installation
terraform version
```

### Méthode 2 : Installation manuelle

Si vous préférez installer manuellement :

```bash
# 1. Télécharger la dernière version
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip

# 2. Installer unzip si nécessaire
sudo apt-get install unzip

# 3. Décompresser
unzip terraform_1.9.0_linux_amd64.zip

# 4. Déplacer dans le PATH
sudo mv terraform /usr/local/bin/

# 5. Vérifier
terraform version

# 6. Nettoyer
rm terraform_1.9.0_linux_amd64.zip
```

### Configuration de l'autocomplétion (Ubuntu)

```bash
# Activer l'autocomplétion pour Bash
terraform -install-autocomplete

# Recharger le shell
source ~/.bashrc
```

## 🪟 Installation sur Windows

### Méthode 1 : Avec Chocolatey (Recommandée)

[Chocolatey](https://chocolatey.org/) est un gestionnaire de paquets pour Windows, similaire à `apt` sur Linux.

#### Étape 1 : Installer Chocolatey

```powershell
# Ouvrir PowerShell en tant qu'Administrateur

# Vérifier la politique d'exécution
Get-ExecutionPolicy

# Si Restricted, autoriser l'exécution
Set-ExecutionPolicy AllSigned
# ou
Set-ExecutionPolicy Bypass -Scope Process

# Installer Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Vérifier l'installation de Chocolatey
choco --version
```

#### Étape 2 : Installer Terraform avec Chocolatey

```powershell
# Installer Terraform
choco install terraform

# Vérifier l'installation
terraform version

# Pour mettre à jour Terraform plus tard
choco upgrade terraform
```

### Méthode 2 : Installation manuelle (Windows)

```powershell
# 1. Télécharger depuis https://www.terraform.io/downloads
# Choisir : Windows AMD64

# 2. Créer un dossier pour Terraform
New-Item -Path "C:\terraform" -ItemType Directory

# 3. Décompresser le fichier ZIP téléchargé dans C:\terraform

# 4. Ajouter au PATH Windows
# Rechercher "Variables d'environnement" dans le menu Démarrer
# Modifier la variable PATH et ajouter : C:\terraform

# Ou via PowerShell (Administrateur)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\terraform", "Machine")

# 5. Redémarrer PowerShell et vérifier
terraform version
```

### Configuration de l'autocomplétion (Windows)

Pour PowerShell :

```powershell
# Créer le profil si nécessaire
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}

# Ajouter l'autocomplétion
Add-Content $PROFILE 'terraform -install-autocomplete'
```

## 🍎 Installation sur macOS

### Méthode 1 : Avec Homebrew (Recommandée)

[Homebrew](https://brew.sh/) est le gestionnaire de paquets standard pour macOS.

#### Étape 1 : Installer Homebrew (si pas déjà installé)

```bash
# Ouvrir Terminal

# Installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Vérifier l'installation
brew --version
```

#### Étape 2 : Installer Terraform avec Homebrew

```bash
# Installer Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Vérifier l'installation
terraform version

# Pour mettre à jour Terraform plus tard
brew upgrade hashicorp/tap/terraform
```

### Méthode 2 : Installation manuelle (macOS)

```bash
# 1. Télécharger la version macOS
curl -O https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_darwin_amd64.zip

# Pour Apple Silicon (M1/M2)
curl -O https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_darwin_arm64.zip

# 2. Décompresser
unzip terraform_1.9.0_darwin_amd64.zip

# 3. Déplacer dans le PATH
sudo mv terraform /usr/local/bin/

# 4. Vérifier
terraform version

# 5. Nettoyer
rm terraform_1.9.0_darwin_amd64.zip
```

### Configuration de l'autocomplétion (macOS)

```bash
# Pour Bash
terraform -install-autocomplete

# Pour Zsh (shell par défaut sur macOS récent)
terraform -install-autocomplete
source ~/.zshrc
```

## ✅ Vérification de l'installation

Quelle que soit votre plateforme, vérifiez l'installation :

```bash
# Afficher la version de Terraform
terraform version

# Devrait afficher quelque chose comme :
# Terraform v1.9.0
# on linux_amd64 (ou darwin_amd64, windows_amd64)
```

### Commandes de base pour tester

```bash
# Afficher l'aide
terraform -help

# Afficher les commandes disponibles
terraform

# Afficher l'aide d'une commande spécifique
terraform init -help
```

## 🔧 Configuration de l'éditeur de code

### Visual Studio Code (Recommandé)

VS Code est l'éditeur le plus populaire pour Terraform.

#### Installation de VS Code

- **Windows** : Télécharger depuis [code.visualstudio.com](https://code.visualstudio.com/)
- **macOS** : `brew install --cask visual-studio-code`
- **Ubuntu** :
```bash
sudo snap install code --classic
```

#### Extensions VS Code essentielles

```bash
# Dans VS Code, installer ces extensions :
```

1. **HashiCorp Terraform** (obligatoire)
   - Syntaxe highlighting
   - Autocomplétion
   - Validation

2. **Azure Terraform** (recommandé)
   - Snippets Azure
   - Intégration Azure

3. **GitLens** (recommandé)
   - Gestion Git avancée

#### Rechercher et installer dans VS Code :
```
Extensions (Ctrl+Shift+X ou Cmd+Shift+X)
→ Rechercher "HashiCorp Terraform"
→ Cliquer sur "Install"
```

## 📁 Créer votre espace de travail

Créez un répertoire pour vos projets Terraform :

```bash
# Linux / macOS
mkdir -p ~/terraform-projects
cd ~/terraform-projects

# Windows PowerShell
New-Item -Path "$HOME\terraform-projects" -ItemType Directory
cd $HOME\terraform-projects
```

## 🎯 Test de fonctionnement

Créons un fichier de test simple :

```bash
# Créer un dossier de test
mkdir test-terraform
cd test-terraform

# Créer un fichier main.tf
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
}

output "hello_world" {
  value = "Terraform fonctionne parfaitement ! 🎉"
}
EOF

# Initialiser Terraform
terraform init

# Afficher le plan
terraform plan

# Appliquer
terraform apply

# Devrait afficher : Terraform fonctionne parfaitement ! 🎉
```

Si vous voyez le message de succès, bravo ! Terraform est correctement installé.

## 🔥 Désinstallation (si nécessaire)

### Ubuntu

```bash
# Si installé via apt
sudo apt-get remove terraform

# Si installation manuelle
sudo rm /usr/local/bin/terraform
```

### Windows (Chocolatey)

```powershell
choco uninstall terraform
```

### macOS (Homebrew)

```bash
brew uninstall hashicorp/tap/terraform
```

## ❓ Problèmes courants et solutions

### Problème 1 : "terraform: command not found"

**Solution** : Le PATH n'est pas configuré correctement

```bash
# Linux/macOS : Vérifier le PATH
echo $PATH

# Windows : Vérifier le PATH
echo $env:Path
```

Assurez-vous que le dossier contenant terraform est dans le PATH.

### Problème 2 : Permission denied (Linux/macOS)

**Solution** : Rendre terraform exécutable

```bash
sudo chmod +x /usr/local/bin/terraform
```

### Problème 3 : "execution policy" sur Windows

**Solution** : Modifier la politique d'exécution PowerShell

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problème 4 : Version obsolète

**Solution** : Mettre à jour Terraform

```bash
# Ubuntu
sudo apt update && sudo apt upgrade terraform

# macOS
brew upgrade hashicorp/tap/terraform

# Windows
choco upgrade terraform
```

## 📊 Tableau récapitulatif

| OS | Méthode recommandée | Commande d'installation | Temps estimé |
|----|---------------------|------------------------|--------------|
| **Ubuntu** | Repository HashiCorp | `sudo apt install terraform` | 5 min |
| **Windows** | Chocolatey | `choco install terraform` | 10 min |
| **macOS** | Homebrew | `brew install hashicorp/tap/terraform` | 5 min |

## ✅ Checklist de fin de module

Avant de passer au module suivant, assurez-vous que :

- [ ] Terraform est installé sur votre machine
- [ ] La commande `terraform version` fonctionne
- [ ] VS Code est installé avec l'extension HashiCorp Terraform
- [ ] L'autocomplétion est configurée
- [ ] Vous avez créé votre espace de travail terraform-projects
- [ ] Le test "hello_world" fonctionne

## 🎓 Résumé

Dans ce module, vous avez appris à :

- ✅ Installer Terraform sur Ubuntu avec apt
- ✅ Installer Terraform sur Windows avec Chocolatey
- ✅ Installer Terraform sur macOS avec Homebrew
- ✅ Configurer VS Code pour Terraform
- ✅ Vérifier et tester l'installation
- ✅ Résoudre les problèmes courants

## ➡️ Prochaine étape

Maintenant que Terraform est installé, il faut installer et configurer **Azure CLI** pour pouvoir interagir avec Azure !

**Prochain module** : [03 - Installation et configuration Azure CLI](./03-azure-cli.md)

---

💪 Excellent ! Terraform est installé et fonctionnel. Passons à Azure CLI !
