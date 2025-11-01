# 🗃️ Chapitre 4 : Gestion de Version avec Git

## Introduction

Git est l'outil de versioning incontournable pour tout développeur moderne. Au-delà des commandes de base, ce chapitre explore les workflows professionnels, les conventions de commits, et les stratégies de collaboration efficaces.

## 🌳 Comprendre Git en Profondeur

### Les Trois États de Git

```bash
# Working Directory : Fichiers modifiés non suivis
# Staging Area (Index) : Modifications prêtes au commit  
# Repository : Historique des commits

# Visualiser l'état actuel
git status

# Voir les différences
git diff              # Working directory vs Staging
git diff --staged     # Staging vs dernier commit
git diff HEAD        # Working directory vs dernier commit
```

### Configuration Initiale

```bash
# Configuration globale
git config --global user.name "Votre Nom"
git config --global user.email "email@example.com"

# Éditeur par défaut
git config --global core.editor "code --wait"  # VS Code

# Alias utiles
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Améliorer l'affichage
git config --global color.ui auto
git config --global core.pager 'less -FRX'

# Configuration du comportement
git config --global pull.rebase true  # Rebase par défaut lors du pull
git config --global fetch.prune true   # Nettoyer les branches supprimées
```

## 📝 Conventional Commits

### Format Standard

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types de Commits

| Type | Description | Exemple |
|------|-------------|---------|
| `feat` | Nouvelle fonctionnalité | `feat(auth): add OAuth2 login` |
| `fix` | Correction de bug | `fix(api): handle null user data` |
| `docs` | Documentation | `docs(readme): update installation guide` |
| `style` | Formatage (sans changement de logique) | `style: fix indentation` |
| `refactor` | Refactoring du code | `refactor(user): extract validation logic` |
| `perf` | Amélioration des performances | `perf(db): add index on user email` |
| `test` | Ajout ou modification de tests | `test(auth): add login tests` |
| `build` | Changements de build/dépendances | `build: upgrade to React 18` |
| `ci` | Changements CI/CD | `ci: add deployment workflow` |
| `chore` | Tâches de maintenance | `chore: update dependencies` |
| `revert` | Annulation d'un commit | `revert: feat(auth): add OAuth2 login` |

### Exemples Détaillés

```bash
# Feature simple
git commit -m "feat(user): add profile picture upload"

# Bug fix avec description
git commit -m "fix(cart): prevent duplicate items

Items were being added twice when clicking rapidly.
Now using debounce to prevent multiple submissions.

Fixes #234"

# Breaking change
git commit -m "feat(api)!: change user endpoint response format

BREAKING CHANGE: The /api/users endpoint now returns
data in a different format. Update your API clients.

Old format: { users: [...] }
New format: { data: [...], meta: {...} }"

# Commit avec plusieurs footers
git commit -m "fix(security): patch XSS vulnerability in comments

Update sanitization library to latest version.

Reviewed-by: Alice <alice@example.com>
Refs: #123, #456
CVE-2024-1234"
```

### Configuration avec Commitizen

```bash
# Installation
npm install -g commitizen
npm install -g cz-conventional-changelog

# Configuration dans le projet
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc

# Utilisation
git add .
git cz  # Lance l'assistant interactif
```

## 🌿 Stratégies de Branches

### Git Flow

```bash
# Branches principales
main        # Production, toujours stable
develop     # Développement, intègre les features

# Branches temporaires
feature/*   # Nouvelles fonctionnalités
release/*   # Préparation des releases
hotfix/*    # Corrections urgentes en production

# Workflow Feature
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication
# ... développement ...
git add .
git commit -m "feat(auth): implement JWT authentication"
git push origin feature/user-authentication
# Créer une Pull Request vers develop

# Workflow Hotfix
git checkout main
git checkout -b hotfix/security-patch
# ... correction ...
git commit -m "fix(security): patch SQL injection vulnerability"
git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v1.2.1 -m "Security patch"
git checkout develop
git merge --no-ff hotfix/security-patch
```

### GitHub Flow (Simplifié)

```bash
# Une seule branche principale : main
# Tout le reste en feature branches

git checkout main
git pull origin main
git checkout -b feature/new-feature
# ... développement ...
git push origin feature/new-feature
# Pull Request vers main
# Review + Tests
# Merge
```

### Trunk Based Development

```bash
# Développement directement sur main
# Branches très courtes (< 1 jour)
# Feature flags pour le code incomplet

git checkout main
git pull --rebase origin main
# ... petit changement ...
git add .
git commit -m "feat: add user avatar to navbar"
git push origin main
```

## 🔧 Commandes Git Avancées

### Réécriture d'Historique

```bash
# Modifier le dernier commit
git commit --amend -m "New commit message"

# Ajouter des fichiers oubliés au dernier commit
git add forgotten_file.py
git commit --amend --no-edit

# Squash : Fusionner plusieurs commits
git rebase -i HEAD~3  # Interactif sur les 3 derniers commits
# Remplacer 'pick' par 'squash' pour les commits à fusionner

# Exemple de rebase interactif
pick a1b2c3d feat: add user model
squash e4f5g6h fix: typo in user model
squash i7j8k9l docs: add user model documentation
# Résultat : un seul commit avec tous les changements

# Diviser un commit
git rebase -i HEAD~1
# Marquer le commit avec 'edit'
git reset HEAD^
git add -p  # Ajouter partiellement
git commit -m "feat: add user model"
git add .
git commit -m "feat: add user validation"
git rebase --continue
```

### Stash : Sauvegarder Temporairement

```bash
# Sauvegarder les modifications en cours
git stash
git stash save "WIP: working on user feature"

# Lister les stashes
git stash list

# Appliquer un stash
git stash pop                # Applique et supprime
git stash apply              # Applique sans supprimer
git stash apply stash@{2}    # Applique un stash spécifique

# Créer une branche depuis un stash
git stash branch feature/new-feature

# Stash partiel
git stash push -p  # Interactif
git stash push -m "message" -- path/to/file.js
```

### Cherry-pick : Copier des Commits

```bash
# Appliquer un commit spécifique d'une autre branche
git cherry-pick abc123def

# Cherry-pick multiple
git cherry-pick abc123..def456

# Cherry-pick sans commit automatique
git cherry-pick -n abc123
# Permet de modifier avant de commiter
```

### Bisect : Trouver le Commit Problématique

```bash
# Démarrer la recherche binaire
git bisect start
git bisect bad                    # Le bug est présent
git bisect good v1.0             # Le bug n'était pas là en v1.0

# Git checkout automatiquement des commits
# Tester et marquer
git bisect good  # ou git bisect bad

# Git trouve le commit problématique
# Terminer
git bisect reset

# Automatiser avec un script
git bisect start HEAD v1.0
git bisect run npm test
```

## 🔀 Résolution de Conflits

### Comprendre les Conflits

```bash
# Structure d'un conflit
<<<<<<< HEAD
Code de votre branche
=======
Code de l'autre branche
>>>>>>> feature/other-feature

# Outils pour résoudre
git status                    # Voir les fichiers en conflit
git diff                      # Voir les différences
git log --merge               # Voir les commits en conflit
git show :1:filename          # Version de base
git show :2:filename          # Version HEAD
git show :3:filename          # Version de l'autre branche
```

### Stratégies de Résolution

```bash
# Résolution manuelle
# 1. Éditer les fichiers
# 2. Supprimer les marqueurs de conflit
# 3. Choisir ou combiner le code
git add resolved_file.py
git commit

# Prendre une version spécifique
git checkout --ours file.py    # Garder notre version
git checkout --theirs file.py  # Prendre leur version

# Utiliser un outil de merge
git mergetool                  # Lance l'outil configuré
git mergetool --tool=vimdiff   # Outil spécifique

# Abandonner le merge
git merge --abort
git rebase --abort
```

## 📊 Workflows d'Équipe

### Pull Requests / Merge Requests

```markdown
## Description
Décrivez brièvement les changements apportés.

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Comment tester
1. Étape 1
2. Étape 2
3. Vérifier que...

## Checklist
- [ ] Mon code suit les conventions du projet
- [ ] J'ai ajouté des tests
- [ ] J'ai mis à jour la documentation
- [ ] Tous les tests passent

## Screenshots (si applicable)

## Issues liées
Fixes #123
```

### Protection de Branches

```bash
# Configuration GitHub/GitLab (via interface web ou API)
# Branch protection rules pour 'main':
# - Require pull request reviews (2 approvals)
# - Require status checks to pass
# - Require branches to be up to date
# - Include administrators
# - Restrict who can push

# Pre-push hook local (.git/hooks/pre-push)
#!/bin/bash
protected_branch='main'
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [ $protected_branch = $current_branch ]; then
    echo "Direct push to $protected_branch branch is not allowed"
    exit 1
fi
```

### Code Review Best Practices

```bash
# Préparer une PR propre
# 1. Rebase sur la branche cible
git checkout feature/my-feature
git rebase origin/main

# 2. Nettoyer l'historique
git rebase -i origin/main
# Squash les commits de WIP

# 3. Vérifier les changements
git diff origin/main

# 4. Lancer les tests
npm test

# 5. Push
git push origin feature/my-feature --force-with-lease
```

## 🏷️ Tags et Releases

### Versioning Sémantique

```bash
# Format : MAJOR.MINOR.PATCH
# MAJOR : Breaking changes
# MINOR : Nouvelles fonctionnalités
# PATCH : Bug fixes

# Créer un tag annoté
git tag -a v1.2.0 -m "Release version 1.2.0

Features:
- Add user authentication
- Add profile management

Fixes:
- Fix memory leak in image upload
- Fix timezone issues"

# Lister les tags
git tag
git tag -l "v1.2.*"

# Voir les détails d'un tag
git show v1.2.0

# Pousser les tags
git push origin v1.2.0
git push origin --tags

# Supprimer un tag
git tag -d v1.2.0                    # Local
git push origin :refs/tags/v1.2.0   # Remote
```

### Générer un Changelog

```bash
# Avec conventional-changelog
npm install -g conventional-changelog-cli

# Générer le changelog
conventional-changelog -p angular -i CHANGELOG.md -s

# Script npm
{
  "scripts": {
    "version": "conventional-changelog -p angular -i CHANGELOG.md -s && git add CHANGELOG.md"
  }
}

# Workflow complet de release
npm version minor  # Incrémente la version
git push origin main --follow-tags
```

## 🛠️ Git Hooks

### Hooks Côté Client

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Lancer les tests avant chaque commit

echo "Running tests..."
npm test
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

echo "Checking code style..."
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Commit aborted."
    exit 1
fi

# .git/hooks/commit-msg
#!/bin/bash
# Vérifier le format du message de commit

commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: <type>(<scope>): <subject>"
    exit 1
fi
```

### Partager les Hooks avec Husky

```json
// package.json
{
  "devDependencies": {
    "husky": "^8.0.0",
    "lint-staged": "^13.0.0"
  },
  "scripts": {
    "prepare": "husky install"
  },
  "lint-staged": {
    "*.js": ["eslint --fix", "git add"],
    "*.{js,css,md}": "prettier --write"
  }
}
```

```bash
# Installation
npm install husky lint-staged --save-dev
npx husky install

# Ajouter des hooks
npx husky add .husky/pre-commit "npx lint-staged"
npx husky add .husky/commit-msg 'npx commitlint --edit $1'
```

## 📈 Git Avancé

### Submodules

```bash
# Ajouter un submodule
git submodule add https://github.com/user/repo.git libs/external

# Cloner un projet avec submodules
git clone --recursive https://github.com/user/project.git

# Mettre à jour les submodules
git submodule update --init --recursive
git submodule update --remote

# Travailler dans un submodule
cd libs/external
git checkout main
git pull origin main
cd ../..
git add libs/external
git commit -m "chore: update external library"
```

### Git Attributes

```bash
# .gitattributes
# Définir des attributs par fichier

# Normalisation des fins de ligne
* text=auto
*.sh text eol=lf
*.bat text eol=crlf

# Fichiers binaires
*.png binary
*.jpg binary
*.pdf binary

# Diff personnalisé
*.docx diff=word
*.xlsx diff=excel

# Merge drivers
package-lock.json merge=ours
yarn.lock merge=ours

# Export excludes (pour les archives)
.gitattributes export-ignore
.gitignore export-ignore
/tests export-ignore
```

## 🎯 Exercices Pratiques

### Exercice 1 : Workflow Feature
1. Créer une branche feature
2. Faire 3 commits
3. Squash en un seul commit propre
4. Rebase sur main
5. Créer une PR

### Exercice 2 : Résolution de Conflits
1. Créer deux branches avec des modifications conflictuelles
2. Merger la première
3. Résoudre les conflits lors du merge de la seconde
4. Utiliser différentes stratégies de résolution

### Exercice 3 : Réécriture d'Historique
1. Créer 5 commits avec des messages non conventionnels
2. Utiliser rebase interactif pour :
   - Corriger les messages
   - Réorganiser les commits
   - Squash certains commits

## 📚 Points Clés à Retenir

1. **Commits atomiques** : Un commit = un changement logique
2. **Messages clairs** : Le futur vous remerciera
3. **Branches courtes** : Merger fréquemment
4. **Historique propre** : Rebase avant de merger
5. **Collaboration** : Communication claire dans les PRs

## 🔗 Ressources Complémentaires

- [Pro Git Book](https://git-scm.com/book/en/v2)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)

---

**Prochain chapitre** : [Tests et Qualité →](05-tests-qualite.md)