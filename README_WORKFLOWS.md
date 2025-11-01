# 🤖 GitHub Actions - Workflows automatiques

Ce repository utilise GitHub Actions pour automatiser le versioning et les vérifications de qualité.

## 📋 Workflows configurés

### 1. Release (Semantic Release)

**Fichier:** `.github/workflows/release.yml`

**Quand:** À chaque push sur la branche `main`

**Actions:**
1. ✅ Analyse les commits depuis la dernière release
2. ✅ Détermine la nouvelle version (MAJOR.MINOR.PATCH)
3. ✅ Génère le CHANGELOG.md
4. ✅ Crée un tag Git (ex: `v1.2.0`)
5. ✅ Crée une release GitHub avec les notes

**Exemple:**
```bash
# Vous faites:
git commit -m "feat: add new terraform examples"
git push origin main

# GitHub Actions fait automatiquement:
# - Détecte le commit "feat:" → version MINOR
# - Crée le tag v1.1.0
# - Publie la release sur GitHub
```

---

### 2. Pre-commit checks

**Fichier:** `.github/workflows/pre-commit.yml`

**Quand:**
- À chaque Pull Request
- À chaque push sur `main`

**Actions:**
1. ✅ Vérifie les secrets (gitleaks, detect-secrets)
2. ✅ Valide la syntaxe Terraform
3. ✅ Vérifie le formatage du code
4. ✅ Valide les fichiers YAML/JSON

---

## 🚀 Comment ça fonctionne?

### Workflow de développement complet

```
1. Développeur crée une branche
   git checkout -b feature/new-examples

2. Développeur fait des commits (format conventionnel)
   git commit -m "feat(terraform): add hetzner examples"
   git commit -m "fix(azure): correct variable type"

3. Développeur push et crée une PR
   git push origin feature/new-examples

   → GitHub Actions exécute pre-commit checks ✅

4. PR est approuvée et mergée dans main

   → GitHub Actions exécute semantic-release
   → Création automatique:
      - Tag v1.2.0
      - CHANGELOG.md mis à jour
      - Release GitHub publiée
```

---

## 📊 Versions automatiques

Selon vos commits, semantic-release crée automatiquement les versions:

| Type de commit | Exemple | Impact version |
|---------------|---------|----------------|
| `feat:` | `feat: add oracle examples` | MINOR (1.0.0 → 1.1.0) |
| `fix:` | `fix: correct azure bug` | PATCH (1.0.0 → 1.0.1) |
| `feat!:` ou `BREAKING CHANGE:` | `feat!: upgrade terraform` | MAJOR (1.0.0 → 2.0.0) |
| `docs:`, `style:`, `chore:` | `docs: update README` | Aucune nouvelle version |

---

## 🔍 Vérifier les workflows

### Dans GitHub

1. Allez sur https://github.com/gsoulat/formation-data-engineer/actions
2. Vous verrez l'historique de toutes les exécutions
3. Cliquez sur une exécution pour voir les détails

### Localement

Testez les pre-commit hooks:
```bash
# Installer pre-commit
pip install pre-commit
pre-commit install

# Tester
pre-commit run --all-files
```

Testez semantic-release en dry-run:
```bash
npm install
npm run release:dry
```

---

## 🎯 Première release

Pour créer votre première release automatiquement:

```bash
# 1. Assurez-vous que les workflows sont pushés
git add .github/workflows/
git commit -m "ci: add GitHub Actions workflows for release and pre-commit"
git push origin main

# 2. GitHub Actions va détecter le commit "ci:" mais ne créera pas de release
# (car "ci:" ne déclenche pas de version)

# 3. Faites un commit qui déclenche une release
git commit --allow-empty -m "feat: initialize semantic-release

First release with automated versioning.

- GitHub Actions configured
- Pre-commit hooks configured
- Documentation added"

git push origin main

# 4. Vérifiez sur GitHub:
# https://github.com/gsoulat/formation-data-engineer/releases
# → Vous devriez voir v1.0.0 !
```

---

## 🛠️ Configuration

### Permissions GitHub Token

Le workflow utilise `GITHUB_TOKEN` (fourni automatiquement par GitHub).

**Permissions nécessaires** (déjà configurées dans le workflow):
- `contents: write` → Créer tags et releases
- `issues: write` → Commenter les issues
- `pull-requests: write` → Commenter les PRs

### Personnalisation

Pour modifier le comportement de semantic-release:
1. Éditez `.releaserc.json`
2. Consultez la doc: https://semantic-release.gitbook.io/

Pour modifier les pre-commit hooks:
1. Éditez `.pre-commit-config.yaml`
2. Consultez la doc: https://pre-commit.com/

---

## 📝 CHANGELOG automatique

Semantic-release génère automatiquement `CHANGELOG.md`:

```markdown
# Changelog

## [1.2.0] - 2024-11-01

### 🚀 Nouvelles fonctionnalités
- **terraform**: add hetzner cloud examples ([abc1234](link))
- **terraform**: add oracle support ([def5678](link))

### 🐛 Corrections de bugs
- **azure**: correct variable type ([ghi9012](link))
```

---

## 🔗 Ressources

- [Semantic Release](https://semantic-release.gitbook.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Pre-commit](https://pre-commit.com/)

---

## ✅ Checklist

Après avoir pushé les workflows:

- [ ] Vérifier que `.github/workflows/release.yml` existe sur GitHub
- [ ] Vérifier que `.github/workflows/pre-commit.yml` existe sur GitHub
- [ ] Aller sur https://github.com/gsoulat/formation-data-engineer/actions
- [ ] Faire un commit `feat:` pour déclencher la première release
- [ ] Vérifier la release sur https://github.com/gsoulat/formation-data-engineer/releases

**Une fois tout coché, semantic-release est opérationnel! 🎉**
