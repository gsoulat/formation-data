# Scripts Utilitaires Astro

Scripts pour automatiser l'installation et la configuration d'Astro Starlight.

## 📋 Scripts disponibles

### 1. `setup-astro.sh` - Installation automatique

Installe Astro et Starlight automatiquement.

```bash
chmod +x scripts-astro/setup-astro.sh
./scripts-astro/setup-astro.sh
```

**Ce que fait le script :**
- ✅ Vérifie Node.js (version 18+)
- ✅ Crée le projet Astro dans `docs/`
- ✅ Installe Starlight
- ✅ Configure l'environnement de base

---

### 2. `copy-content.sh` - Copie des fichiers Markdown

Copie tous vos cours existants vers le dossier Astro.

```bash
chmod +x scripts-astro/copy-content.sh
./scripts-astro/copy-content.sh
```

**Ce que fait le script :**
- 📁 Crée la structure de dossiers
- 📋 Copie tous les fichiers Markdown
- 📊 Affiche un rapport détaillé

---

### 3. `add-frontmatter.sh` - Ajout automatique du frontmatter

Ajoute le frontmatter requis à tous vos fichiers Markdown.

```bash
chmod +x scripts-astro/add-frontmatter.sh
./scripts-astro/add-frontmatter.sh
```

**Ce que fait le script :**
- 🔍 Détecte les fichiers sans frontmatter
- 📝 Extrait le titre du premier H1 ou du nom de fichier
- ✨ Ajoute le frontmatter YAML
- ⏭️ Ignore les fichiers déjà traités

**Format du frontmatter ajouté :**
```yaml
---
title: "Titre du cours"
description: "Description extraite du contenu"
---
```

---

## 🚀 Workflow complet

Exécutez les scripts dans cet ordre :

```bash
# 1. Installer Astro
./scripts-astro/setup-astro.sh

# 2. Copier le contenu
./scripts-astro/copy-content.sh

# 3. Ajouter le frontmatter
./scripts-astro/add-frontmatter.sh

# 4. Tester
cd docs
npm run dev
```

---

## 🔧 Personnalisation

### Modifier le chemin de destination

```bash
# Copier vers un autre dossier
./scripts-astro/copy-content.sh /chemin/personnalise

# Ajouter le frontmatter ailleurs
./scripts-astro/add-frontmatter.sh /chemin/personnalise
```

---

## ⚠️ Important

- Ces scripts préservent vos fichiers originaux
- Les scripts peuvent être exécutés plusieurs fois sans danger
- Toujours tester avec `npm run dev` après modifications

---

## 🆘 Résolution de problèmes

### Erreur : "Permission denied"

```bash
chmod +x scripts-astro/*.sh
```

### Erreur : "Node.js not found"

Installez Node.js v18+ depuis https://nodejs.org/

### Le script ne trouve pas les fichiers

Vérifiez que vous êtes à la racine du projet :
```bash
pwd  # Doit afficher: .../formation-data-engineer
```

---

## 📚 Documentation complète

Consultez `GUIDE_ASTRO.md` pour le guide complet pas à pas.
