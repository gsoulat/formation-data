# Semantic Release - Guide d'utilisation

Ce projet utilise **Semantic Release** pour automatiser la gestion des versions et des releases.

## Comment ça marche ?

Semantic Release analyse vos messages de commit pour déterminer automatiquement :
- Le type de version (major, minor, patch)
- La génération du CHANGELOG
- La création de la release GitHub
- L'envoi de notification Discord

## Format des commits (Conventional Commits)

### Structure

```
<type>(<scope>): <description courte>

[corps optionnel]

[footer optionnel]
```

### Types de commits

| Type | Description | Bump de version |
|------|-------------|----------------|
| `feat` | Nouvelle fonctionnalité | Minor (1.x.0) |
| `fix` | Correction de bug | Patch (1.0.x) |
| `docs` | Documentation uniquement | Pas de release |
| `style` | Formatage, ponctuation | Pas de release |
| `refactor` | Refactoring de code | Pas de release |
| `perf` | Amélioration de performance | Patch (1.0.x) |
| `test` | Ajout/modification de tests | Pas de release |
| `chore` | Tâches de maintenance | Pas de release |
| `ci` | Changements CI/CD | Pas de release |

### Breaking Changes (Major version)

Pour indiquer un changement non rétrocompatible (major version bump: x.0.0) :

```
feat(terraform)!: refonte complète de la structure

BREAKING CHANGE: L'ancienne structure n'est plus compatible
```

## Exemples de commits

### Nouvelle fonctionnalité (Minor)
```bash
git commit -m "feat(kubernetes): ajout du cours sur les StatefulSets"
```

### Correction de bug (Patch)
```bash
git commit -m "fix(terraform): correction de la configuration Azure provider"
```

### Documentation (Pas de release)
```bash
git commit -m "docs(readme): mise à jour des instructions d'installation"
```

### Breaking Change (Major)
```bash
git commit -m "feat(structure)!: réorganisation complète de l'arborescence

BREAKING CHANGE: Tous les chemins ont été modifiés selon la nouvelle architecture"
```

### Avec scope détaillé
```bash
git commit -m "feat(azure/databricks): ajout de notebooks d'exercices

- Ajout de 3 nouveaux notebooks
- Exemples avec PySpark
- Documentation associée"
```

## Configuration du webhook Discord

### 1. Créer un webhook Discord

1. Ouvrez Discord et allez sur le serveur cible
2. Cliquez sur le nom du serveur → **Paramètres du serveur**
3. Allez dans **Intégrations** → **Webhooks**
4. Cliquez sur **Nouveau Webhook**
5. Configurez le webhook :
   - Nom : `Release Bot`
   - Channel : choisissez le canal de destination
   - Copiez l'URL du webhook

### 2. Ajouter le secret GitHub

1. Allez sur votre repository GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Cliquez sur **New repository secret**
4. Créez le secret :
   - Name : `DISCORD_WEBHOOK`
   - Secret : collez l'URL du webhook Discord
5. Cliquez sur **Add secret**

## Workflow de release

1. **Développement** : Travaillez sur une branche de feature
   ```bash
   git checkout -b feature/nouveau-cours
   # Faites vos modifications
   git commit -m "feat(docker): ajout cours sur les multi-stage builds"
   ```

2. **Pull Request** : Créez une PR vers `main`
   ```bash
   git push origin feature/nouveau-cours
   # Créez la PR sur GitHub
   ```

3. **Merge** : Une fois la PR approuvée et mergée dans `main`
   - Le workflow `release.yml` se déclenche automatiquement
   - Semantic Release analyse les commits depuis la dernière release
   - Si des commits déclenchent une release :
     - Création automatique du tag et de la release
     - Mise à jour du CHANGELOG.md
     - Notification envoyée sur Discord

4. **Résultat** : Vous recevez une notification Discord avec :
   - Numéro de version
   - Lien vers la release
   - Lien vers le changelog
   - Informations sur le commit

## Exemples de notification Discord

### Release réussie
```
🚀 Nouvelle Release - v1.2.0

Une nouvelle version de Formation vient d'être publiée !

Version: v1.2.0
Branche: main
Auteur: guillaume
Commit: a1b2c3d

Liens: 📦 Release Notes | 📝 Changelog
```

### Erreur de release
```
❌ Erreur lors de la release

La création de la release a échoué pour Formation

Workflow: Voir les logs
```

## Vérifier les releases

- **Releases GitHub** : https://github.com/VOTRE_USERNAME/Formation/releases
- **Changelog** : `/CHANGELOG.md` (généré automatiquement)
- **Tags** : `git tag -l`

## Forcer une release

Si vous voulez forcer une release sans commit feat/fix :

```bash
# Créer un commit vide avec un type de release
git commit --allow-empty -m "feat: déclenchement de release"
git push origin main
```

## Désactiver une release

Pour un commit qui ne doit PAS déclencher de release :

```bash
git commit -m "chore: maintenance du code [skip ci]"
```

Le `[skip ci]` empêche le workflow de se déclencher.

## Dépannage

### La release ne se déclenche pas

1. Vérifiez que vous êtes sur `main` ou `master`
2. Vérifiez le format de vos commits
3. Consultez les logs : **Actions** → **Semantic Release**

### Notification Discord non reçue

1. Vérifiez que le secret `DISCORD_WEBHOOK` est bien configuré
2. Vérifiez que le webhook Discord est actif
3. Consultez les logs du workflow

### Conflit sur CHANGELOG.md

Si semantic-release échoue à cause d'un conflit sur CHANGELOG.md :

```bash
# Pull les derniers changements
git pull origin main

# Résolvez les conflits si nécessaire
git add CHANGELOG.md
git commit -m "chore: résolution conflit changelog"
git push origin main
```

## Ressources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Release](https://semantic-release.gitbook.io/)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)

---

**Simplon Formation** - Système de release automatisé
