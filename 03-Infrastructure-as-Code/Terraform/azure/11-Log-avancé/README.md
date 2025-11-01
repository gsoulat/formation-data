# Guide d'utilisation des logs Terraform

Ce guide explique comment activer, configurer et analyser les logs Terraform pour le débogage et le monitoring de vos déploiements d'infrastructure.

## Table des matières

1. [Activation rapide](#activation-rapide)
2. [Niveaux de logging](#niveaux-de-logging)
3. [Redirection vers un fichier](#redirection-vers-un-fichier)
4. [Logs par composant](#logs-par-composant)
5. [Exemples pratiques](#exemples-pratiques)
6. [Analyse des logs](#analyse-des-logs)
7. [Bonnes pratiques](#bonnes-pratiques)
8. [Cas d'usage concrets](#cas-dusage-concrets)

---

## Activation rapide

### Activer le logging

```bash
# Activer le niveau TRACE (le plus verbeux)
export TF_LOG=TRACE
terraform plan
terraform apply

# Désactiver
unset TF_LOG
```

---

## Niveaux de logging

Terraform propose 5 niveaux de verbosité, du moins au plus détaillé :

```bash
# Niveaux disponibles (du moins au plus verbeux)
TF_LOG=ERROR   # Seulement les erreurs
TF_LOG=WARN    # Avertissements et erreurs
TF_LOG=INFO    # Informations générales
TF_LOG=DEBUG   # Informations de débogage
TF_LOG=TRACE   # Tout, y compris les détails internes (le plus verbeux)
```

### Exemples d'utilisation

```bash
# Logging modéré pour usage quotidien
export TF_LOG=INFO
terraform apply

# Logging complet pour déboguer un problème
export TF_LOG=TRACE
terraform apply
```

---

## Redirection vers un fichier

Pour éviter de surcharger la console, redirigez les logs vers un fichier (particulièrement important pour `TRACE`) :

### Linux / macOS

```bash
# Définir le fichier de log
export TF_LOG=TRACE
export TF_LOG_PATH="./terraform-trace.log"
terraform apply

# Ou en une ligne
TF_LOG=TRACE TF_LOG_PATH="./terraform.log" terraform apply
```

### Windows (PowerShell)

```powershell
$env:TF_LOG="TRACE"
$env:TF_LOG_PATH=".\terraform-trace.log"
terraform apply
```

### Windows (CMD)

```cmd
set TF_LOG=TRACE
set TF_LOG_PATH=terraform-trace.log
terraform apply
```

---

## Logs par composant

Vous pouvez activer le logging pour des composants spécifiques :

```bash
# Logger uniquement le core de Terraform
export TF_LOG_CORE=TRACE

# Logger uniquement les providers
export TF_LOG_PROVIDER=TRACE

# Exemple avec Azure provider
export TF_LOG_PROVIDER=TRACE
terraform apply
```

---

## Exemples pratiques

### Scénario : Déboguer un déploiement Azure

```bash
# 1. Créer un dossier pour les logs
mkdir -p logs

# 2. Configurer le logging avec timestamp
export TF_LOG=TRACE
export TF_LOG_PATH="./logs/terraform-$(date +%Y%m%d-%H%M%S).log"

# 3. Exécuter Terraform avec logging
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. Analyser les logs en cas de problème
grep -i "error" ./logs/terraform-*.log
grep -i "azurerm" ./logs/terraform-*.log
```

### Script Bash avec logging automatisé

```bash
#!/bin/bash

# Script de déploiement avec logging activé

# Configuration
LOG_DIR="./terraform-logs"
LOG_FILE="$LOG_DIR/deployment-$(date +%Y%m%d-%H%M%S).log"

# Créer le dossier de logs
mkdir -p "$LOG_DIR"

# Activer le logging TRACE
export TF_LOG=TRACE
export TF_LOG_PATH="$LOG_FILE"

echo "Logging activé : $LOG_FILE"

# Exécuter Terraform
terraform init
terraform plan -out=tfplan

# Demander confirmation
read -p "Voulez-vous appliquer ce plan ? (oui/non) " -n 3 -r
echo
if [[ $REPLY =~ ^[Oo][Uu][Ii]$ ]]
then
    terraform apply tfplan

    # Vérifier le résultat
    if [ $? -eq 0 ]; then
        echo "Déploiement réussi"
    else
        echo "Erreur lors du déploiement"
        echo "Consultez les logs : $LOG_FILE"
    fi
fi

# Désactiver le logging
unset TF_LOG
unset TF_LOG_PATH
```

### Pipeline CI/CD (GitHub Actions)

```yaml
name: Terraform Deploy with Logging

on:
  push:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.6.0

    - name: Terraform Init with logging
      env:
        TF_LOG: TRACE
        TF_LOG_PATH: ./terraform-init.log
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      run: terraform init

    - name: Terraform Plan with logging
      env:
        TF_LOG: DEBUG  # Moins verbeux pour le plan
        TF_LOG_PATH: ./terraform-plan.log
      run: terraform plan -out=tfplan

    - name: Terraform Apply with logging
      if: github.ref == 'refs/heads/main'
      env:
        TF_LOG: TRACE
        TF_LOG_PATH: ./terraform-apply.log
      run: terraform apply -auto-approve tfplan

    - name: Upload logs on failure
      if: failure()
      uses: actions/upload-artifact@v3
      with:
        name: terraform-logs
        path: |
          terraform-*.log
        retention-days: 7
```

---

## Analyse des logs

Les logs `TRACE` contiennent énormément d'informations. Voici comment les analyser efficacement.

### Rechercher des erreurs spécifiques

```bash
# Erreurs générales
grep -i "error" terraform.log

# Erreurs Azure
grep -i "azure\|azurerm" terraform.log | grep -i "error"

# Problèmes d'authentification
grep -i "auth\|credential\|permission" terraform.log

# Timeouts
grep -i "timeout\|timed out" terraform.log

# Problèmes de ressources
grep -i "resource.*not found\|already exists" terraform.log
```

### Extraire les appels API

```bash
# Voir tous les appels HTTP
grep "HTTP Request\|HTTP Response" terraform.log

# Filtrer par code de statut
grep "HTTP Response.*Status: 4[0-9][0-9]" terraform.log  # Erreurs client (4xx)
grep "HTTP Response.*Status: 5[0-9][0-9]" terraform.log  # Erreurs serveur (5xx)
```

### Analyser les temps d'exécution

```bash
# Voir les opérations longues
grep "elapsed time" terraform.log | sort -t: -k2 -n
```

---

## Bonnes pratiques

### À faire

- ✅ Utilisez `TF_LOG=DEBUG` ou `TF_LOG=INFO` pour l'usage quotidien
- ✅ Utilisez `TF_LOG=TRACE` uniquement pour déboguer des problèmes spécifiques
- ✅ Redirigez toujours `TRACE` vers un fichier avec `TF_LOG_PATH`
- ✅ Nettoyez régulièrement les anciens logs
- ✅ N'activez pas `TRACE` en production (trop verbeux)
- ✅ Utilisez `.gitignore` pour exclure les logs

### À éviter

- ❌ Laisser `TF_LOG=TRACE` activé en permanence (ralentit Terraform)
- ❌ Commiter les fichiers de logs dans Git (peuvent contenir des secrets)
- ❌ Afficher les logs `TRACE` directement dans la console (illisible)

### Exemple `.gitignore`

```gitignore
# Terraform logs
*.log
terraform-*.log
terraform-logs/

# Terraform files
.terraform/
*.tfstate
*.tfstate.backup
tfplan
```

---

## Cas d'usage concrets

### 1. Déboguer un problème d'authentification Azure

```bash
export TF_LOG=TRACE
export TF_LOG_PATH="./auth-debug.log"

terraform plan

# Analyser les tentatives d'authentification
grep -A 5 "Azure Provider" auth-debug.log
grep "Authorization" auth-debug.log
```

### 2. Déboguer un déploiement lent

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH="./perf-debug.log"

time terraform apply

# Voir les opérations qui prennent du temps
grep "still creating\|still destroying" perf-debug.log
```

### 3. Déboguer un problème de dépendances

```bash
export TF_LOG=TRACE
export TF_LOG_PATH="./deps-debug.log"

terraform apply

# Analyser l'ordre de création
grep "Creating\|Modifying\|Reading" deps-debug.log
```

---

## Ressources supplémentaires

- [Documentation officielle Terraform - Debugging](https://developer.hashicorp.com/terraform/internals/debugging)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## Aide et support

Si vous rencontrez des problèmes spécifiques avec Terraform et avez besoin d'aide pour analyser vos logs, n'hésitez pas à :
- Vérifier les logs avec les commandes d'analyse ci-dessus
- Consulter la documentation officielle
- Partager les extraits pertinents des logs (en masquant les informations sensibles)
