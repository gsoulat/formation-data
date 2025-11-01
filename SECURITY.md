# Politique de Sécurité

## Détection de Secrets

Ce projet utilise plusieurs outils pour détecter automatiquement les secrets et credentials:

### Outils configurés

1. **detect-secrets** - Détection heuristique de secrets
2. **gitleaks** - Scanner de secrets dans le code et l'historique Git
3. **pre-commit hooks** - Validation automatique avant chaque commit

## Que faire si un secret est commité par erreur?

### 1. NE PAS simplement supprimer le secret

Supprimer un secret d'un commit ne le retire pas de l'historique Git. Le secret reste accessible.

### 2. Révoquer immédiatement le secret

- **Clés API**: Révoquer la clé dans la console du provider (AWS, Azure, GCP, etc.)
- **Tokens**: Régénérer le token
- **Mots de passe**: Changer le mot de passe immédiatement

### 3. Nettoyer l'historique Git

```bash
# Installer BFG Repo-Cleaner
brew install bfg

# Ou git-filter-repo (recommandé)
pip install git-filter-repo

# Supprimer un fichier de tout l'historique
git filter-repo --path-glob '**/*credentials*.json' --invert-paths

# Ou avec BFG
bfg --delete-files credentials.json

# Force push (ATTENTION: coordination avec l'équipe requise)
git push --force --all
```

### 4. Signaler l'incident

Si un secret a été exposé publiquement:
1. Notifier l'équipe de sécurité
2. Vérifier les logs d'accès
3. Documenter l'incident
4. Mettre à jour les procédures si nécessaire

## Bonnes pratiques

### ✅ À FAIRE

- Utiliser des variables d'environnement pour les secrets
- Utiliser des services de gestion de secrets (AWS Secrets Manager, Azure Key Vault, etc.)
- Utiliser des fichiers `.tfvars` (exclus du Git)
- Utiliser `terraform.tfvars.example` pour documenter les variables requises
- Activer les pre-commit hooks
- Vérifier régulièrement le scan de secrets

### ❌ À NE PAS FAIRE

- Commiter des fichiers `.tfvars` contenant des secrets
- Commiter des clés privées (`.pem`, `.key`, `.p12`)
- Coder en dur des secrets dans le code
- Utiliser des secrets en clair dans les scripts
- Partager des secrets par email ou chat
- Commiter des fichiers de credentials cloud (`credentials.json`, etc.)

## Fichiers à ne jamais commiter

Ces patterns sont dans le `.gitignore`:

```
*.tfvars           # Variables Terraform (peuvent contenir des secrets)
*.pem              # Clés privées
*.key              # Clés privées
*.p12              # Certificats
credentials*.json  # Credentials cloud
secrets*.json      # Fichiers de secrets
*token*.txt        # Tokens
*password*.txt     # Mots de passe
.env               # Variables d'environnement
```

## Configuration des secrets dans Terraform

### Utiliser des variables sensibles

```hcl
variable "api_key" {
  description = "API Key"
  type        = string
  sensitive   = true  # Masque la valeur dans les logs
}
```

### Utiliser des data sources pour les secrets

```hcl
# AWS Secrets Manager
data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "my-api-key"
}

# Azure Key Vault
data "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  key_vault_id = azurerm_key_vault.main.id
}

# GCP Secret Manager
data "google_secret_manager_secret_version" "api_key" {
  secret = "api-key"
}
```

### Utiliser des fichiers tfvars locaux

```bash
# Créer terraform.tfvars (ignoré par Git)
cat > terraform.tfvars <<EOF
api_key = "secret_value"
EOF

# Appliquer
terraform apply
```

## Scan de sécurité régulier

### Scanner tout le repository

```bash
# Avec gitleaks
gitleaks detect --source . --verbose

# Avec detect-secrets
detect-secrets scan --all-files

# Avec trufflehog (scan de l'historique complet)
trufflehog git file://. --since-commit HEAD~100
```

### Scanner l'historique Git complet

```bash
# Gitleaks sur tout l'historique
gitleaks detect --source . --log-opts "--all"

# Trufflehog sur tout l'historique
trufflehog git file://. --only-verified
```

## Configuration des providers cloud

### AWS

```bash
# Utiliser AWS CLI pour les credentials
aws configure

# Ou variables d'environnement
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Azure

```bash
# Utiliser Azure CLI
az login

# Ou Service Principal
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

### GCP

```bash
# Utiliser Application Default Credentials
gcloud auth application-default login

# Ou variable d'environnement
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

## Audit de sécurité

### Vérification mensuelle

- [ ] Scanner le repository avec gitleaks
- [ ] Vérifier les permissions des secrets
- [ ] Rotation des clés API anciennes
- [ ] Audit des accès aux secrets
- [ ] Review des fichiers .gitignore

### Checklist avant chaque commit

- [ ] Aucun secret en dur dans le code
- [ ] Fichiers sensibles dans .gitignore
- [ ] Variables marquées comme `sensitive = true`
- [ ] Pre-commit hooks activés

## Signaler une vulnérabilité

Si vous découvrez une vulnérabilité de sécurité:

1. **NE PAS** créer une issue publique
2. Contacter l'équipe de sécurité en privé
3. Fournir les détails:
   - Description de la vulnérabilité
   - Étapes pour la reproduire
   - Impact potentiel
   - Suggestions de correction

## Ressources

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_CheatSheet.html)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Terraform Sensitive Data](https://developer.hashicorp.com/terraform/language/values/variables#sensitive)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
