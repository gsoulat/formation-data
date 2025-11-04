# 18 - Tests et validation

## 📖 Introduction

Tester l'infrastructure est aussi important que tester le code applicatif. Ce module présente différentes approches pour valider votre code Terraform.

## 🎯 Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Valider la syntaxe et la configuration
- ✅ Tester localement avant le déploiement
- ✅ Utiliser des outils de linting
- ✅ Effectuer des tests de conformité
- ✅ Mettre en place des tests automatisés

## ✅ Validation basique

### 1. terraform validate

```bash
# Valider la syntaxe et la configuration
terraform validate

# Résultat si OK :
# Success! The configuration is valid.

# Résultat si erreur :
# Error: Missing required argument
#   on main.tf line 5:
#   5: resource "azurerm_resource_group" "main" {
```

### 2. terraform fmt

```bash
# Formater le code
terraform fmt -recursive

# Vérifier le formatage sans modifier
terraform fmt -check -recursive

# Afficher les différences
terraform fmt -diff -recursive
```

### 3. terraform plan

```bash
# Plan standard
terraform plan

# Plan avec sortie détaillée
terraform plan -out=tfplan

# Analyser le plan (format JSON)
terraform show -json tfplan | jq .
```

## 🔍 Linting et analyse statique

### TFLint

[TFLint](https://github.com/terraform-linters/tflint) est un linter Terraform avancé.

#### Installation

```bash
# macOS
brew install tflint

# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Windows
choco install tflint
```

#### Configuration

```hcl
# .tflint.hcl
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}
```

#### Utilisation

```bash
# Initialiser TFLint
tflint --init

# Exécuter TFLint
tflint

# Format compact
tflint --format compact

# Format JSON (pour CI/CD)
tflint --format json
```

### Checkov

[Checkov](https://www.checkov.io/) scanne le code pour détecter les problèmes de sécurité.

#### Installation

```bash
pip install checkov
```

#### Utilisation

```bash
# Scanner le répertoire actuel
checkov -d .

# Scanner un fichier spécifique
checkov -f main.tf

# Ignorer certains checks
checkov -d . --skip-check CKV_AZURE_1,CKV_AZURE_2

# Format JSON
checkov -d . -o json
```

#### Exemple de résultats

```
Check: CKV_AZURE_3: "Ensure storage account enable Secure transfer required"
  FAILED for resource: azurerm_storage_account.example
  File: /main.tf:10-20

  10 | resource "azurerm_storage_account" "example" {
  11 |   name                     = "stexample"
  12 |   resource_group_name      = azurerm_resource_group.main.name
  13 |   location                 = azurerm_resource_group.main.location
  14 |   account_tier             = "Standard"
  15 |   account_replication_type = "LRS"
  16 |   # enable_https_traffic_only = true  # ← Manquant !
  17 | }
```

## 🧪 Tests avec Terratest

[Terratest](https://terratest.gruntwork.io/) permet d'écrire des tests automatisés en Go.

### Installation

```bash
# Prérequis : Go installé
go mod init github.com/your-org/terraform-tests
go get github.com/gruntwork-io/terratest/modules/terraform
```

### Exemple de test

```go
// test/terraform_azure_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraformAzureExample(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        // Chemin vers le code Terraform
        TerraformDir: "../examples/basic",

        // Variables à passer
        Vars: map[string]interface{}{
            "location":    "West Europe",
            "environment": "test",
        },
    }

    // Nettoyer après le test
    defer terraform.Destroy(t, terraformOptions)

    // Exécuter terraform init et apply
    terraform.InitAndApply(t, terraformOptions)

    // Valider les outputs
    resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
    assert.Equal(t, "rg-test-westeurope", resourceGroupName)

    storageAccountName := terraform.Output(t, terraformOptions, "storage_account_name")
    assert.Contains(t, storageAccountName, "sttest")
}
```

### Exécuter les tests

```bash
# Exécuter tous les tests
go test -v ./test/

# Exécuter un test spécifique
go test -v ./test/ -run TestTerraformAzureExample

# Avec timeout
go test -v ./test/ -timeout 30m
```

## 📋 Tests manuels pré-déploiement

### Checklist de validation

```bash
#!/bin/bash
# validate.sh

set -e

echo "=== 1. Format check ==="
terraform fmt -check -recursive

echo "=== 2. Validation ==="
terraform validate

echo "=== 3. TFLint ==="
tflint --init
tflint

echo "=== 4. Checkov (security) ==="
checkov -d . --quiet

echo "=== 5. Plan ==="
terraform plan -out=tfplan

echo "=== All checks passed! ==="
```

### Tests de conformité

```hcl
# tests/compliance.tf

# Vérifier que tous les storage accounts ont HTTPS uniquement
data "azurerm_resources" "storage_accounts" {
  type = "Microsoft.Storage/storageAccounts"
}

locals {
  non_compliant_storage = [
    for sa in data.azurerm_resources.storage_accounts.resources :
    sa.id if sa.properties.supportsHttpsTrafficOnly != true
  ]
}

# Échouer si non conforme
resource "null_resource" "compliance_check" {
  count = length(local.non_compliant_storage) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Non-compliant storage accounts found:"
      echo "${join("\n", local.non_compliant_storage)}"
      exit 1
    EOT
  }
}
```

## 🎯 Stratégies de test

### 1. Test local (dev)

```bash
# Workspace de test
terraform workspace new test

# Variables de test
terraform apply -var-file="test.tfvars"

# Vérifier
terraform output

# Nettoyer
terraform destroy -auto-approve
```

### 2. Environnement éphémère

```bash
# Créer un environnement temporaire
TIMESTAMP=$(date +%Y%m%d%H%M%S)
terraform workspace new test-$TIMESTAMP

# Déployer
terraform apply -auto-approve

# Tests manuels ou automatisés
./run-tests.sh

# Détruire
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete test-$TIMESTAMP
```

### 3. Tests de smoke (validation post-déploiement)

```bash
#!/bin/bash
# smoke-tests.sh

# Récupérer les outputs
RG_NAME=$(terraform output -raw resource_group_name)
STORAGE_NAME=$(terraform output -raw storage_account_name)

# Vérifier que le RG existe
echo "Testing resource group..."
az group show --name $RG_NAME --query "properties.provisioningState" -o tsv | grep -q "Succeeded" || exit 1

# Vérifier que le storage existe
echo "Testing storage account..."
az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --query "provisioningState" -o tsv | grep -q "Succeeded" || exit 1

# Vérifier HTTPS uniquement
echo "Testing HTTPS enforcement..."
az storage account show --name $STORAGE_NAME --resource-group $RG_NAME --query "enableHttpsTrafficOnly" -o tsv | grep -q "true" || exit 1

echo "All smoke tests passed!"
```

## 🔄 Tests dans CI/CD

### GitHub Actions

```yaml
# .github/workflows/terraform.yml
name: Terraform CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Format
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: TFLint
        uses: terraform-linters/setup-tflint@v3
        with:
          tflint_version: latest

      - name: Run TFLint
        run: |
          tflint --init
          tflint -f compact

      - name: Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform

      - name: Terraform Plan
        run: terraform plan
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

## 📊 Métriques de qualité

### Code coverage

```bash
# Vérifier que toutes les variables sont utilisées
terraform graph | grep -c "var."

# Vérifier que tous les outputs sont documentés
grep -c "description" outputs.tf
```

### Complexité

```bash
# Nombre de ressources
grep -c "^resource " *.tf

# Nombre de modules
grep -c "^module " *.tf

# Lignes de code
find . -name "*.tf" -exec wc -l {} + | tail -1
```

## 💡 Bonnes pratiques de test

### 1. Tester en environnement isolé

```
# ✅ Bon
terraform workspace new test-feature-x
terraform apply

# ❌ Mauvais : Tester en prod
terraform workspace select prod
terraform apply  # Risqué !
```

### 2. Nettoyer après les tests

```bash
# Toujours détruire après les tests
terraform destroy -auto-approve

# Ou utiliser un script
trap "terraform destroy -auto-approve" EXIT
```

### 3. Automatiser les tests

```bash
# Intégrer dans pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
terraform fmt -check -recursive || exit 1
terraform validate || exit 1
EOF

chmod +x .git/hooks/pre-commit
```

### 4. Tester les modules séparément

```
modules/
└── network/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── tests/
        └── network_test.go
```

## 🎓 Résumé

Dans ce module, vous avez appris :

- ✅ Validation : fmt, validate, plan
- ✅ Linting : TFLint, Checkov
- ✅ Tests automatisés : Terratest
- ✅ Tests manuels et smoke tests
- ✅ Intégration CI/CD
- ✅ Bonnes pratiques de test

## ➡️ Prochaine étape

Maintenant que vous savez tester votre code, découvrons comment automatiser le déploiement avec **CI/CD** !

**Prochain module** : [19 - CI/CD avec Terraform](./19-cicd.md)

---

🧪 Excellent ! Votre code est testé. Automatisons le déploiement !
