# Comment ça fonctionne : Pre-commit et Semantic Release

Ce document explique en détail le fonctionnement des outils de sécurité et de versioning mis en place.

## Table des matières

1. [Workflow global](#workflow-global)
2. [Pre-commit Hooks](#pre-commit-hooks)
3. [Détection de secrets](#détection-de-secrets)
4. [Semantic Release](#semantic-release)
5. [Exemples pratiques](#exemples-pratiques)

---

## Workflow global

```
┌─────────────────────────────────────────────────────────────┐
│                    Développeur                               │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 1. git add fichiers.tf
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Stage (Zone de staging)                     │
│   fichiers prêts à être committés                           │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ 2. git commit -m "feat: ..."
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              PRE-COMMIT HOOKS S'EXÉCUTENT                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │ ✓ Détection de secrets (gitleaks, detect-secrets) │    │
│  │ ✓ Validation Terraform (fmt, validate)            │    │
│  │ ✓ Sécurité Terraform (tfsec)                       │    │
│  │ ✓ Vérification YAML/JSON                           │    │
│  │ ✓ Formatage code (black, isort pour Python)       │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
                ❌ Échec      ✅ Succès
                    │             │
                    ▼             ▼
        ┌──────────────┐   ┌──────────────────┐
        │   BLOQUÉ     │   │ COMMIT-MSG HOOK  │
        │ Corriger les │   │ Validation du    │
        │   erreurs    │   │ format du commit │
        └──────────────┘   └──────────────────┘
                                    │
                             ┌──────┴──────┐
                             │             │
                         ❌ Échec      ✅ Succès
                             │             │
                             ▼             ▼
                  ┌──────────────┐   ┌──────────┐
                  │ Format invalid│   │  COMMIT  │
                  │ feat: xxx     │   │  CRÉÉ    │
                  └──────────────┘   └──────────┘
                                           │
                                           │ 3. git push
                                           ▼
                               ┌────────────────────┐
                               │   Repository Git   │
                               │    (GitHub/...)    │
                               └────────────────────┘
                                           │
                                           │ 4. CI/CD détecte push sur main
                                           ▼
                               ┌────────────────────┐
                               │ SEMANTIC RELEASE   │
                               │ Analyse commits    │
                               │ Génère version     │
                               │ Crée CHANGELOG     │
                               │ Publie release     │
                               └────────────────────┘
```

---

## Pre-commit Hooks

### Qu'est-ce que c'est ?

Pre-commit est un framework qui **s'exécute automatiquement avant chaque commit** pour valider votre code.

### Installation et activation

```bash
# 1. Installer pre-commit
pip install pre-commit

# 2. Activer dans le repo (crée .git/hooks/pre-commit)
pre-commit install

# 3. Activer pour les messages de commit
pre-commit install --hook-type commit-msg
```

### Ce qui se passe en coulisses

Quand vous faites `git commit`:

1. **Git intercepte** la commande avant de créer le commit
2. **Pre-commit lit** le fichier `.pre-commit-config.yaml`
3. **Exécute chaque hook** dans l'ordre défini
4. **Si un hook échoue** → commit BLOQUÉ
5. **Si tous réussissent** → commit créé

### Exemple de ce que vous voyez

```bash
$ git commit -m "feat: add new example"

detect-secrets................................................Passed
gitleaks.....................................................Passed
check-yaml...................................................Passed
check-json...................................................Passed
terraform_fmt................................................Passed
terraform_validate...........................................Passed
conventional-pre-commit......................................Passed

[main abc1234] feat: add new example
 1 file changed, 10 insertions(+)
```

Si un hook échoue:

```bash
$ git commit -m "add example"

detect-secrets................................................Passed
gitleaks.....................................................Passed
conventional-pre-commit......................................Failed
- hook id: conventional-pre-commit
- exit code: 1

Message de commit invalide!
Format attendu: <type>(<scope>): <description>
Exemples: feat: ..., fix: ..., docs: ...
```

### Fichier de configuration

Le fichier `.pre-commit-config.yaml` contient:

```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

Cela signifie:
- **repo**: Où télécharger le hook
- **rev**: Version du hook
- **id**: Quel hook utiliser
- **args**: Arguments à passer au hook

---

## Détection de secrets

Nous utilisons **3 outils complémentaires** pour détecter les secrets:

### 1. detect-secrets (Yelp)

**Fonctionnement**: Utilise des heuristiques pour détecter les secrets

```python
# Détecte les patterns suspects:
- Entropie élevée (chaînes aléatoires)
- Mots-clés (password, secret, api_key)
- Format de clés (AWS, Azure, etc.)
```

**Exemple de détection**:

```terraform
# ❌ DÉTECTÉ
variable "api_key" {
  default = "sk-1234567890abcdef"  # Entropie élevée + pattern
}

# ✅ OK (variable sans valeur)
variable "api_key" {
  description = "API Key"
  type        = string
  sensitive   = true
}
```

**Baseline**: Le fichier `.secrets.baseline` contient les secrets déjà connus (faux positifs acceptés)

```json
{
  "results": {
    "README.md": [
      {
        "type": "Base64 High Entropy String",
        "line": 42,
        "is_verified": false,
        "is_secret": false
      }
    ]
  }
}
```

### 2. gitleaks

**Fonctionnement**: Utilise des regex pour détecter des patterns de secrets connus

```yaml
# Exemples de règles gitleaks:
- AWS Access Key: AKIA[0-9A-Z]{16}
- GitHub Token: ghp_[0-9a-zA-Z]{36}
- Private Key: -----BEGIN.*PRIVATE KEY-----
- Generic API Key: api[_-]?key.*=.*['"][0-9a-zA-Z]{32,}['"]
```

**Exemple de détection**:

```bash
# ❌ DÉTECTÉ par gitleaks
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"

# ❌ DÉTECTÉ
github_token = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"

# ✅ OK (variable d'environnement sans valeur)
export AWS_ACCESS_KEY_ID="${AWS_KEY}"
```

### 3. detect-private-key

**Fonctionnement**: Cherche spécifiquement les clés privées

```bash
# Détecte:
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN OPENSSH PRIVATE KEY-----
-----BEGIN PGP PRIVATE KEY BLOCK-----
-----BEGIN EC PRIVATE KEY-----
```

### Que se passe-t-il quand un secret est détecté?

```bash
$ git commit -m "feat: add config"

detect-secrets................................................Failed
- hook id: detect-secrets
- exit code: 1

Potential secrets found in:
  - terraform/main.tf:12

[IMPORTANT] Please audit the baseline file to verify these are not real secrets.
Run: detect-secrets audit .secrets.baseline
```

**Actions à faire**:

1. **Si c'est un vrai secret**:
   ```bash
   # ❌ NE PAS commiter
   # Retirer le secret du fichier
   # Utiliser une variable ou un service de gestion de secrets
   ```

2. **Si c'est un faux positif** (exemple dans un README):
   ```bash
   # Auditer et marquer comme faux positif
   detect-secrets audit .secrets.baseline
   # Puis commiter à nouveau
   git commit -m "feat: add config"
   ```

### Exemple complet de correction

**Avant (❌ Bloqué)**:

```terraform
# main.tf
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"  # ❌ SECRET DÉTECTÉ
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  region     = "eu-west-1"
}
```

**Après (✅ OK)**:

```terraform
# main.tf
provider "aws" {
  # Les credentials sont lus depuis ~/.aws/credentials
  # ou depuis les variables d'environnement
  region = "eu-west-1"
}

# variables.tf
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true  # Masqué dans les logs
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}
```

```bash
# Utilisation
export TF_VAR_aws_access_key="votre_clé"
export TF_VAR_aws_secret_key="votre_secret"
terraform apply
```

---

## Semantic Release

### Principe

Semantic Release **automatise la gestion des versions** basée sur vos commits.

### Format des commits → Impact sur la version

```
Version actuelle: 1.2.3 (MAJOR.MINOR.PATCH)
```

| Commit | Type de changement | Nouvelle version | Explication |
|--------|-------------------|------------------|-------------|
| `feat: nouvelle fonctionnalité` | MINOR | 1.3.0 | Fonctionnalité compatible |
| `fix: correction de bug` | PATCH | 1.2.4 | Correction mineure |
| `feat!: breaking change` | MAJOR | 2.0.0 | Changement incompatible |
| `docs: mise à jour doc` | Aucun | 1.2.3 | Pas de code changé |
| `chore: nettoyage` | Aucun | 1.2.3 | Maintenance |

### Déroulement complet

```
1. Développeur commit:
   git commit -m "feat: add hetzner examples"
   git commit -m "fix: correct azure variable"
   git commit -m "feat: add oracle cloud"

2. Push sur main:
   git push origin main

3. CI/CD s'exécute (GitHub Actions):

   ┌─────────────────────────────────────┐
   │   Semantic Release démarre          │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 1: Analyser les commits       │
   │ Depuis la dernière release:         │
   │  - feat: add hetzner examples       │
   │  - fix: correct azure variable      │
   │  - feat: add oracle cloud           │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 2: Calculer la version        │
   │ feat = MINOR version                │
   │ Ancienne: 1.2.3                     │
   │ Nouvelle: 1.3.0                     │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 3: Générer CHANGELOG.md       │
   │ ## [1.3.0] - 2024-11-01             │
   │ ### Features                        │
   │ - add hetzner examples              │
   │ - add oracle cloud                  │
   │ ### Bug Fixes                       │
   │ - correct azure variable            │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 4: Mettre à jour package.json │
   │ "version": "1.3.0"                  │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 5: Créer commit de release    │
   │ chore(release): 1.3.0 [skip ci]     │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 6: Créer tag Git              │
   │ git tag v1.3.0                      │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 7: Pusher tag et commit       │
   │ git push --tags                     │
   └─────────────────────────────────────┘
              │
              ▼
   ┌─────────────────────────────────────┐
   │ Étape 8: Créer GitHub Release       │
   │ Titre: v1.3.0                       │
   │ Corps: Contenu du CHANGELOG         │
   └─────────────────────────────────────┘
```

### Configuration dans .releaserc.json

```json
{
  "branches": ["main"],  // Sur quelle branche release
  "plugins": [
    // 1. Analyser les commits
    ["@semantic-release/commit-analyzer", {
      "preset": "conventionalcommits"
    }],

    // 2. Générer les notes de release
    ["@semantic-release/release-notes-generator", {
      "preset": "conventionalcommits"
    }],

    // 3. Mettre à jour CHANGELOG.md
    ["@semantic-release/changelog", {
      "changelogFile": "CHANGELOG.md"
    }],

    // 4. Mettre à jour package.json
    ["@semantic-release/npm", {
      "npmPublish": false  // On ne publie pas sur npm
    }],

    // 5. Commiter les changements
    ["@semantic-release/git", {
      "assets": ["CHANGELOG.md", "package.json"],
      "message": "chore(release): ${nextRelease.version}"
    }],

    // 6. Créer GitHub release
    ["@semantic-release/github"]
  ]
}
```

### Exemple de CHANGELOG généré

```markdown
# Changelog

## [1.3.0] - 2024-11-01

### 🚀 Nouvelles fonctionnalités

- **terraform**: add hetzner cloud examples ([abc1234](link))
- **terraform**: add oracle cloud support ([def5678](link))

### 🐛 Corrections de bugs

- **azure**: correct variable type in main.tf ([ghi9012](link))

### 📝 Documentation

- update README with new examples ([jkl3456](link))
```

---

## Exemples pratiques

### Scénario 1: Commit avec secret (❌ Bloqué)

```bash
# 1. Créer un fichier avec un secret
$ echo 'api_key = "sk-1234567890abcdef"' > config.tf

# 2. Tenter de commiter
$ git add config.tf
$ git commit -m "feat: add config"

detect-secrets................................................Failed

❌ BLOQUÉ - Secret détecté!
```

**Solution**:

```bash
# Corriger en utilisant une variable
$ cat > config.tf <<EOF
variable "api_key" {
  type      = string
  sensitive = true
}
EOF

$ git add config.tf
$ git commit -m "feat: add config with variable"

detect-secrets................................................Passed
✅ COMMIT CRÉÉ
```

### Scénario 2: Format de commit invalide (❌ Bloqué)

```bash
$ git commit -m "added new feature"

conventional-pre-commit......................................Failed

Format invalide!
Attendu: <type>(<scope>): <description>
Types: feat, fix, docs, style, refactor, test, chore, ci, build
```

**Solution**:

```bash
$ git commit -m "feat: add new feature"

conventional-pre-commit......................................Passed
✅ COMMIT CRÉÉ
```

### Scénario 3: Terraform non formaté (✅ Auto-corrigé)

```bash
# Fichier mal formaté
$ cat main.tf
resource "aws_instance" "example" {
ami="ami-123456"
instance_type="t2.micro"
}

$ git add main.tf
$ git commit -m "feat: add instance"

terraform_fmt................................................Modified
- Fichier reformaté automatiquement

$ cat main.tf
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}

✅ COMMIT CRÉÉ (avec fichier formaté)
```

### Scénario 4: Créer une release

```bash
# 1. Plusieurs commits sur une feature branch
$ git checkout -b feature/new-provider
$ git commit -m "feat(linode): add basic examples"
$ git commit -m "feat(linode): add VPC example"
$ git commit -m "docs(linode): add README"

# 2. Merge dans main
$ git checkout main
$ git merge feature/new-provider
$ git push origin main

# 3. CI/CD s'exécute automatiquement
# Semantic Release:
# - Analyse: 2 feat + 1 docs
# - Décision: MINOR version (1.2.0 → 1.3.0)
# - Génère CHANGELOG
# - Crée release GitHub v1.3.0
```

### Scénario 5: Breaking Change (Version MAJOR)

```bash
$ git commit -m "feat(terraform)!: upgrade to terraform 1.7

BREAKING CHANGE: Terraform 1.6 is no longer supported"

# Semantic Release:
# - Détecte "!" et "BREAKING CHANGE"
# - Version MAJOR: 1.3.0 → 2.0.0

# CHANGELOG généré:
## [2.0.0] - 2024-11-01

### ⚠ BREAKING CHANGES

- **terraform**: Terraform 1.6 is no longer supported

### Features

- **terraform**: upgrade to terraform 1.7
```

---

## Commandes utiles

### Pre-commit

```bash
# Exécuter tous les hooks sur tous les fichiers
pre-commit run --all-files

# Exécuter un hook spécifique
pre-commit run detect-secrets
pre-commit run terraform_fmt
pre-commit run gitleaks

# Mettre à jour les versions des hooks
pre-commit autoupdate

# Désactiver temporairement (déconseillé)
git commit --no-verify -m "message"

# Désinstaller pre-commit
pre-commit uninstall
```

### Semantic Release

```bash
# Test sans publier (dry-run)
npm run release:dry

# Publier une release
npm run release

# Voir la prochaine version sans publier
npx semantic-release --dry-run --no-ci
```

### Détection de secrets

```bash
# Scanner tout le repo
gitleaks detect --source . --verbose

# Scanner l'historique complet
gitleaks detect --source . --log-opts "--all"

# Auditer les secrets détectés
detect-secrets audit .secrets.baseline

# Créer une nouvelle baseline
detect-secrets scan > .secrets.baseline
```

---

## Questions fréquentes

### Q: Pre-commit ralentit mes commits

**R**: Vous pouvez skip certains hooks pour des commits rapides:

```bash
# Skip juste un hook
SKIP=terraform_validate git commit -m "wip: work in progress"

# Skip tous les hooks (déconseillé)
git commit --no-verify -m "message"
```

### Q: Comment corriger un secret déjà commité?

**R**: Voir le fichier `SECURITY.md` section "Que faire si un secret est commité".

### Q: Semantic release ne crée pas de version

**R**: Vérifiez:
- Êtes-vous sur la branche `main` ou `master`?
- Avez-vous des commits de type `feat` ou `fix` depuis la dernière release?
- Les commits suivent-ils le format conventionnel?

```bash
# Debug
npm run release:dry
```

### Q: Comment tester sans pusher?

**R**:
```bash
# Pre-commit: tester avant de commiter
pre-commit run --all-files

# Semantic release: dry-run
npm run release:dry
```

---

## Ressources

- [Pre-commit Documentation](https://pre-commit.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Release](https://semantic-release.gitbook.io/)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [detect-secrets](https://github.com/Yelp/detect-secrets)
