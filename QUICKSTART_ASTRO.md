# 🚀 Quick Start Astro - 5 Minutes

Guide ultra-rapide pour créer votre site en **5 minutes chrono** !

## ⚡ Installation Express

### Option 1 : Tout automatique (Recommandé)

```bash
# 1. Installer Astro (2 min)
./scripts-astro/setup-astro.sh

# 2. Copier vos cours (30 sec)
./scripts-astro/copy-content.sh

# 3. Ajouter le frontmatter (1 min)
./scripts-astro/add-frontmatter.sh

# 4. Configurer (30 sec)
cp scripts-astro/astro.config.example.mjs docs/astro.config.mjs
mkdir -p docs/src/styles
cp scripts-astro/custom.example.css docs/src/styles/custom.css

# 5. Lancer ! (30 sec)
cd docs
npm run dev
```

**🎉 C'est tout ! Ouvrez http://localhost:4321**

---

### Option 2 : Manuel (si vous préférez le contrôle)

```bash
# 1. Créer le projet Astro
npm create astro@latest docs -- --template minimal --no-install --no-git --typescript false
cd docs
npm install

# 2. Installer Starlight
npx astro add starlight --yes

# 3. Retour à la racine et copie
cd ..
./scripts-astro/copy-content.sh
./scripts-astro/add-frontmatter.sh

# 4. Configuration
cp scripts-astro/astro.config.example.mjs docs/astro.config.mjs
mkdir -p docs/src/styles
cp scripts-astro/custom.example.css docs/src/styles/custom.css

# 5. Lancer
cd docs
npm run dev
```

---

## ✏️ Personnalisation Rapide

### Changer le titre et les couleurs (1 min)

Éditez `docs/astro.config.mjs` :

```javascript
starlight({
  title: 'Mon Titre Perso',  // ← Changez ici

  // Dans customCss (voir custom.css)
})
```

Éditez `docs/src/styles/custom.css` :

```css
:root {
  --sl-color-accent: #4f46e5;  /* ← Votre couleur */
}
```

---

## 🌐 Déploiement Express (GitHub Pages)

### Configuration rapide (2 min)

1. **Éditer `docs/astro.config.mjs` :**

```javascript
export default defineConfig({
  site: 'https://VOTRE-USERNAME.github.io',
  base: '/formation-data-engineer',
  // ...
});
```

2. **Créer le workflow :**

```bash
mkdir -p .github/workflows
cat > .github/workflows/deploy-docs.yml << 'EOF'
name: Deploy Docs

on:
  push:
    branches: [main]
    paths: ['docs/**']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: cd docs && npm ci && npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: docs/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
EOF
```

3. **Activer GitHub Pages :**
   - Repo → Settings → Pages
   - Source : **GitHub Actions**
   - Save

4. **Push !**

```bash
git add .
git commit -m "feat(docs): add Astro documentation site"
git push
```

**✅ Site en ligne en 5 minutes ! → https://votre-username.github.io/formation-data-engineer**

---

## 🎨 Créer la page d'accueil (Optionnel - 3 min)

```bash
cat > docs/src/content/docs/index.mdx << 'EOF'
---
title: Formation Data Engineer
template: splash
hero:
  title: Formation Data Engineer
  tagline: DevOps, Cloud & Data Engineering - Apprenez par la pratique
  actions:
    - text: Commencer
      link: /fondamentaux/
      icon: right-arrow
      variant: primary
---

import { Card, CardGrid } from '@astrojs/starlight/components';

## 🎯 Parcours

<CardGrid>
  <Card title="Fondamentaux" icon="star">
    Bash, Git, Docker
  </Card>
  <Card title="Infrastructure" icon="setting">
    Terraform, Ansible
  </Card>
  <Card title="Cloud" icon="rocket">
    Azure, AWS, GCP
  </Card>
  <Card title="Data" icon="bars">
    dbt, Snowflake, Airflow
  </Card>
</CardGrid>

## 🚀 Commencer maintenant

Choisissez votre parcours dans le menu de gauche !
EOF
```

---

## 📋 Checklist Ultra-Rapide

- [ ] Node.js 18+ installé → `node --version`
- [ ] Scripts exécutés → `./scripts-astro/setup-astro.sh`
- [ ] Contenu copié → `./scripts-astro/copy-content.sh`
- [ ] Frontmatter ajouté → `./scripts-astro/add-frontmatter.sh`
- [ ] Config copiée → `cp scripts-astro/*.example.* docs/`
- [ ] Test local → `cd docs && npm run dev`
- [ ] ✅ Ça marche ! → http://localhost:4321

---

## ⚡ Commandes essentielles

```bash
# Développement
cd docs
npm run dev          # Serveur local

# Build
npm run build        # Créer le site statique
npm run preview      # Prévisualiser le build

# Aide
npm run astro --help
```

---

## 🆘 Problèmes ?

### "Node.js not found"
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### "Module not found"
```bash
cd docs
rm -rf node_modules package-lock.json
npm install
```

### Site vide ou erreurs
```bash
# Vérifier que le frontmatter est partout
./scripts-astro/add-frontmatter.sh

# Rebuild
cd docs
npm run build
```

---

## 📚 Documentation complète

Pour plus de détails → **GUIDE_ASTRO.md** (guide complet pas à pas)

---

## 🎉 Prêt en 5 minutes !

**Temps estimé :**
- Installation : 2 min
- Copie contenu : 1 min
- Configuration : 1 min
- Premier démarrage : 1 min
- **TOTAL : 5 minutes** ⚡

**Bon courage ! 🚀**
