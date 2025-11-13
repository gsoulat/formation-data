# Guide Complet : Créer votre Site Web avec Astro Starlight

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation d'Astro Starlight](#installation-dastro-starlight)
3. [Structure du projet](#structure-du-projet)
4. [Configuration de base](#configuration-de-base)
5. [Intégration de vos fichiers Markdown](#intégration-de-vos-fichiers-markdown)
6. [Personnalisation](#personnalisation)
7. [Tests en local](#tests-en-local)
8. [Déploiement](#déploiement)
9. [Troubleshooting](#troubleshooting)

---

## 🔧 Prérequis

### Vérifier Node.js et npm

```bash
# Vérifier Node.js (version 18+ requise)
node --version

# Vérifier npm
npm --version
```

**Si Node.js n'est pas installé :**
- **Linux/Mac** : `curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs`
- **Windows** : Télécharger depuis https://nodejs.org/

---

## 🚀 Installation d'Astro Starlight

### Étape 1 : Créer le projet Astro

```bash
# À la racine de votre repository
cd /chemin/vers/formation-data-engineer

# Créer un nouveau projet Astro dans un dossier 'docs'
npm create astro@latest docs
```

**Répondre aux questions :**
- `How would you like to start?` → **Use blog template** ou **Empty** (recommandé: Empty)
- `Install dependencies?` → **Yes**
- `Initialize git?` → **No** (vous avez déjà git)
- `TypeScript?` → **No** (plus simple pour débuter)

### Étape 2 : Installer Starlight

```bash
cd docs
npx astro add starlight
```

**Répondre :**
- `Continue?` → **Yes**
- `Install dependencies?` → **Yes**

---

## 📁 Structure du projet

Après installation, vous aurez :

```
formation-data-engineer/
├── docs/                          # ⭐ Nouveau dossier Astro
│   ├── node_modules/
│   ├── src/
│   │   ├── content/
│   │   │   ├── docs/             # Vos docs iront ici
│   │   │   └── config.ts
│   │   └── env.d.ts
│   ├── public/                    # Images, favicon, etc.
│   ├── astro.config.mjs          # Configuration principale
│   ├── package.json
│   └── tsconfig.json
├── 01-Fondamentaux/              # Vos cours existants (restent intacts)
├── 02-Containerisation/
├── 03-Infrastructure-as-Code/
└── ... (autres dossiers)
```

---

## ⚙️ Configuration de base

### Étape 1 : Éditer `astro.config.mjs`

Ouvrir `docs/astro.config.mjs` et configurer :

```javascript
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [
    starlight({
      title: 'Formation Data Engineer',
      description: 'Cours DevOps, Cloud & Data Engineering',

      // Localisation en français
      defaultLocale: 'root',
      locales: {
        root: {
          label: 'Français',
          lang: 'fr',
        },
      },

      // Logo (optionnel)
      logo: {
        src: './src/assets/logo.svg',
      },

      // Sidebar (navigation à gauche)
      sidebar: [
        {
          label: 'Accueil',
          link: '/',
        },
        {
          label: 'Fondamentaux',
          autogenerate: { directory: 'fondamentaux' },
        },
        {
          label: 'Containerisation',
          autogenerate: { directory: 'containerisation' },
        },
        {
          label: 'Infrastructure as Code',
          items: [
            {
              label: 'Terraform',
              autogenerate: { directory: 'infrastructure/terraform' },
            },
            {
              label: 'Ansible',
              autogenerate: { directory: 'infrastructure/ansible' },
            },
          ],
        },
        {
          label: 'Cloud Platforms',
          autogenerate: { directory: 'cloud' },
        },
        {
          label: 'Databases',
          autogenerate: { directory: 'databases' },
        },
        {
          label: 'Data Engineering',
          autogenerate: { directory: 'data-engineering' },
        },
        {
          label: 'DevOps',
          autogenerate: { directory: 'devops' },
        },
        {
          label: 'Briefs & Projets',
          autogenerate: { directory: 'briefs' },
        },
      ],

      // Configuration sociale (optionnel)
      social: {
        github: 'https://github.com/votre-username/formation-data-engineer',
      },

      // Recherche
      search: {
        provider: 'pagefind',
      },

      // Thème
      customCss: [
        './src/styles/custom.css',
      ],
    }),
  ],
});
```

---

## 📝 Intégration de vos fichiers Markdown

Vous avez **2 options** :

### Option A : Copier les fichiers (Recommandé)

**Avantages :** Indépendance, personnalisation facile
**Inconvénient :** Duplication des fichiers

```bash
cd docs/src/content/docs

# Créer la structure
mkdir -p fondamentaux containerisation infrastructure/{terraform,ansible} cloud databases data-engineering devops briefs

# Copier vos cours
cp -r ../../../01-Fondamentaux/* fondamentaux/
cp -r ../../../02-Containerisation/* containerisation/
cp -r ../../../03-Infrastructure-as-Code/Terraform/* infrastructure/terraform/
cp -r ../../../03-Infrastructure-as-Code/Ansible/* infrastructure/ansible/
cp -r ../../../04-Cloud-Platforms/* cloud/
cp -r ../../../05-Databases/* databases/
cp -r ../../../06-Data-Engineering/* data-engineering/
cp -r ../../../07-DevOps/* devops/
cp -r ../../../99-Brief/* briefs/
```

### Option B : Liens symboliques

**Avantages :** Pas de duplication, modifications automatiques
**Inconvénient :** Peut causer des problèmes selon l'OS

```bash
cd docs/src/content/docs

# Créer des liens symboliques
ln -s ../../../../01-Fondamentaux fondamentaux
ln -s ../../../../02-Containerisation containerisation
ln -s ../../../../03-Infrastructure-as-Code/Terraform infrastructure-terraform
ln -s ../../../../03-Infrastructure-as-Code/Ansible infrastructure-ansible
ln -s ../../../../04-Cloud-Platforms cloud
ln -s ../../../../05-Databases databases
ln -s ../../../../06-Data-Engineering data-engineering
ln -s ../../../../07-DevOps devops
ln -s ../../../../99-Brief briefs
```

### Étape importante : Ajouter le frontmatter

Astro Starlight nécessite un **frontmatter** en haut de chaque fichier Markdown :

```markdown
---
title: Nom de votre page
description: Description de la page
---

# Votre contenu existant commence ici
```

**Script pour ajouter automatiquement le frontmatter :**

Créer un script `docs/add-frontmatter.sh` :

```bash
#!/bin/bash

# Parcourir tous les fichiers .md
find src/content/docs -name "*.md" -type f | while read file; do
  # Vérifier si le frontmatter existe déjà
  if ! head -n 1 "$file" | grep -q "^---$"; then
    # Extraire le titre du premier H1 ou du nom de fichier
    title=$(grep -m 1 "^# " "$file" | sed 's/^# //' | sed 's/[*`]//g')

    if [ -z "$title" ]; then
      # Si pas de H1, utiliser le nom du fichier
      title=$(basename "$file" .md | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
    fi

    # Créer un fichier temporaire avec le frontmatter
    echo "---" > temp.md
    echo "title: $title" >> temp.md
    echo "description: $title" >> temp.md
    echo "---" >> temp.md
    echo "" >> temp.md
    cat "$file" >> temp.md

    # Remplacer le fichier original
    mv temp.md "$file"

    echo "✅ Frontmatter ajouté à: $file"
  fi
done

echo "🎉 Terminé !"
```

**Exécuter le script :**
```bash
chmod +x docs/add-frontmatter.sh
./docs/add-frontmatter.sh
```

---

## 🎨 Personnalisation

### Étape 1 : Page d'accueil

Créer `docs/src/content/docs/index.mdx` :

```mdx
---
title: Formation Data Engineer
description: Bienvenue sur le site de formation DevOps, Cloud & Data Engineering
template: splash
hero:
  title: Formation Data Engineer
  tagline: Apprenez le DevOps, le Cloud et le Data Engineering par la pratique
  image:
    file: ../../assets/hero-image.png
  actions:
    - text: Commencer la formation
      link: /fondamentaux/
      icon: right-arrow
      variant: primary
    - text: Voir les briefs
      link: /briefs/
      icon: external
---

import { Card, CardGrid } from '@astrojs/starlight/components';

## 🎯 Parcours d'apprentissage

<CardGrid>
  <Card title="Fondamentaux" icon="star">
    Bash, Git, Docker - Les bases essentielles
  </Card>
  <Card title="Infrastructure as Code" icon="setting">
    Terraform, Ansible - Automatisez tout
  </Card>
  <Card title="Cloud Platforms" icon="rocket">
    Azure, AWS - Déployez dans le cloud
  </Card>
  <Card title="Data Engineering" icon="bars">
    dbt, Snowflake - Transformez vos données
  </Card>
</CardGrid>

## 📊 Statistiques

- **13 technologies** couvertes
- **140+ fichiers** de cours
- **10+ projets** pratiques
- **Mises à jour** régulières

## 🚀 Commencer maintenant

Choisissez votre parcours dans le menu de gauche et commencez votre apprentissage !
```

### Étape 2 : CSS personnalisé

Créer `docs/src/styles/custom.css` :

```css
/* Variables de couleur */
:root {
  --sl-color-accent: #4f46e5;
  --sl-color-accent-high: #6366f1;
}

/* Style des cartes */
.card-grid {
  gap: 1rem;
}

/* Style du code */
code {
  background-color: var(--sl-color-gray-6);
  padding: 0.2em 0.4em;
  border-radius: 0.25rem;
  font-size: 0.9em;
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
}

th, td {
  border: 1px solid var(--sl-color-gray-5);
  padding: 0.75rem;
  text-align: left;
}

th {
  background-color: var(--sl-color-gray-6);
  font-weight: 600;
}
```

### Étape 3 : Favicon et logo

```bash
# Placer votre logo/favicon dans public/
cp votre-logo.svg docs/public/favicon.svg
```

---

## 🧪 Tests en local

### Démarrer le serveur de développement

```bash
cd docs
npm run dev
```

**Ouvrir dans le navigateur :**
- URL : http://localhost:4321

**Commandes utiles :**
- `npm run dev` → Serveur de développement
- `npm run build` → Build de production
- `npm run preview` → Prévisualiser le build

---

## 🌐 Déploiement

### Option 1 : GitHub Pages (Gratuit)

**Étape 1 : Configuration**

Éditer `docs/astro.config.mjs` :

```javascript
export default defineConfig({
  site: 'https://votre-username.github.io',
  base: '/formation-data-engineer',
  // ... reste de la config
});
```

**Étape 2 : Créer le workflow GitHub Actions**

Créer `.github/workflows/deploy-docs.yml` :

```yaml
name: Deploy Docs to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: |
          cd docs
          npm ci

      - name: Build
        run: |
          cd docs
          npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: docs/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Étape 3 : Activer GitHub Pages**

1. Aller sur GitHub → Votre repo → Settings → Pages
2. Source : **GitHub Actions**
3. Sauvegarder

**Étape 4 : Pusher le code**

```bash
git add .
git commit -m "feat(docs): add Astro documentation site"
git push origin main
```

Le site sera disponible sur : `https://votre-username.github.io/formation-data-engineer`

### Option 2 : Netlify (Gratuit)

1. Aller sur https://netlify.com
2. Connecter votre repo GitHub
3. Configuration :
   - **Build command :** `cd docs && npm run build`
   - **Publish directory :** `docs/dist`
4. Deploy !

### Option 3 : Vercel (Gratuit)

```bash
cd docs
npm install -g vercel
vercel
```

Suivre les instructions.

---

## 🔧 Troubleshooting

### Problème : "Cannot find module"

```bash
cd docs
rm -rf node_modules package-lock.json
npm install
```

### Problème : Les liens ne fonctionnent pas

- Vérifier que tous les fichiers `.md` ont un frontmatter
- Vérifier les chemins dans `sidebar` de `astro.config.mjs`

### Problème : Images ne s'affichent pas

- Les images doivent être dans `docs/public/` ou `docs/src/assets/`
- Chemins relatifs : `/image.png` → cherche dans `public/`

### Problème : Le build échoue

```bash
cd docs
npm run build -- --verbose
```

Analyser les erreurs détaillées.

### Problème : Lenteur en dev

- Réduire le nombre de fichiers dans `src/content/docs/`
- Utiliser des liens symboliques sélectifs

---

## 📚 Ressources

- **Documentation Astro :** https://docs.astro.build
- **Documentation Starlight :** https://starlight.astro.build
- **Exemples :** https://starlight.astro.build/showcase/
- **Discord Astro :** https://astro.build/chat

---

## 🎯 Checklist complète

- [ ] Node.js installé (v18+)
- [ ] Projet Astro créé dans `docs/`
- [ ] Starlight installé
- [ ] `astro.config.mjs` configuré
- [ ] Fichiers Markdown copiés ou liés
- [ ] Frontmatter ajouté à tous les `.md`
- [ ] Page d'accueil créée
- [ ] CSS personnalisé (optionnel)
- [ ] Test en local (`npm run dev`)
- [ ] Configuration déploiement
- [ ] Premier déploiement réussi ✅

---

## 💡 Conseils finaux

1. **Commencez simple** : Ne personnalisez pas tout de suite, testez d'abord
2. **Testez souvent** : `npm run dev` après chaque modification
3. **Git commit régulier** : Ne perdez pas votre travail
4. **Documentation** : Starlight a une excellente doc, consultez-la
5. **Communauté** : Le Discord Astro est très actif et réactif

---

**Bon courage ! 🚀**

Si vous bloquez, n'hésitez pas à consulter la documentation ou à demander de l'aide.
