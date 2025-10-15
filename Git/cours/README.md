# Formation Git - Version Modulaire

Formation complète Git pour Data Engineering, découpée en modules pour une meilleure progression pédagogique.

## 🎯 Améliorations par rapport à la version originale

### ✅ Corrections importantes

1. **`.gitignore` pour Jupyter Notebooks corrigé**
   - ❌ Avant : Exclusion de tous les `*.ipynb`
   - ✅ Maintenant : Utilisation de `nbstripout` pour nettoyer uniquement les outputs
   - Configuration détaillée dans la Partie 7

2. **Durée réaliste**
   - ❌ Avant : 1 heure (irréaliste)
   - ✅ Maintenant : 3-4 heures (réaliste avec exercices)

3. **Ajout de sections manquantes**
   - ✅ `git switch` vs `git checkout` expliqué
   - ✅ `git worktree` documenté
   - ✅ Gestion des secrets et credentials
   - ✅ Configuration pre-commit hooks complète

### ✅ Nouvelles fonctionnalités

1. **Exercices pratiques interactifs** (`exercices.html`)
   - Exercices guidés après chaque partie
   - Quiz JavaScript interactifs avec scoring
   - Défis avancés (cherry-pick, reflog, rebase interactif)
   - Solutions dépliables

2. **Projet fil rouge complet** (`projet-fil-rouge.html`)
   - Pipeline ETL Sales Data de bout en bout
   - Application de Git Flow (main, develop, feature, hotfix)
   - Gestion de conflits réalistes
   - Création de releases avec tags
   - 1 heure de pratique immersive

3. **Structure modulaire**
   - 7 parties indépendantes
   - Navigation fluide entre les modules
   - Permet de suivre à son rythme
   - Checkpoints de progression

## 📂 Structure des fichiers

```
cours-modulaire/
├── index.html              # Page d'accueil avec navigation
├── exercices.html          # Exercices pratiques + quiz
├── projet-fil-rouge.html   # Projet ETL complet
├── generate_parts.py       # Script pour générer parties 1-6
├── README.md              # Ce fichier
│
├── assets/
│   └── styles.css         # CSS commun à toutes les pages
│
└── parties/
    ├── partie1.html       # Introduction à Git
    ├── partie2.html       # Installation et configuration
    ├── partie3.html       # Premiers pas
    ├── partie4.html       # Branches
    ├── partie5.html       # Collaboration
    ├── partie6.html       # Commandes avancées
    └── partie7.html       # Meilleures pratiques (✨ AMÉLIORÉE)
```

## 🚀 Utilisation

### Option 1 : Utiliser directement

1. Ouvrez `index.html` dans votre navigateur
2. Suivez les modules dans l'ordre recommandé
3. Faites les exercices après chaque partie
4. Terminez par le projet fil rouge

### Option 2 : Générer les parties 1-6 depuis l'original

Si vous voulez régénérer les parties 1-6 à partir du fichier `formation.html` original :

```bash
# Installer BeautifulSoup (si nécessaire)
pip install beautifulsoup4

# Générer les parties
python3 generate_parts.py
```

### Option 3 : Serveur local (recommandé pour les quiz JavaScript)

```bash
# Avec Python
cd cours-modulaire
python3 -m http.server 8000

# Puis ouvrez http://localhost:8000

# Ou avec Node.js
npx http-server
```

## 📚 Parcours d'apprentissage recommandé

### Jour 1 (2h)
1. **Partie 1** : Introduction (20 min)
2. **Partie 2** : Installation (20 min)
3. **Partie 3** : Premiers pas (30 min)
4. **Exercices** : Parties 1-3 (30 min)

### Jour 2 (2h)
1. **Partie 4** : Branches (40 min)
2. **Partie 5** : Collaboration (35 min)
3. **Exercices** : Parties 4-5 (30 min)
4. Pause révision (15 min)

### Jour 3 (2h)
1. **Partie 6** : Avancé (40 min)
2. **Partie 7** : Meilleures pratiques (30 min)
3. **Projet fil rouge** : Pipeline ETL (1h)

### Révision (30 min)
- Quiz final
- Ressources complémentaires

## ✨ Points forts de cette version

### Partie 7 - Meilleures pratiques (Améliorée)

**Nouvelles sections :**
- Configuration nbstripout pour Jupyter Notebooks
- Gestion des secrets avec .env.example
- Pre-commit hooks complets pour Data Engineering
- Git LFS expliqué avec cas d'usage
- Convention Conventional Commits détaillée

**Code corrigé :**
```bash
# ❌ AVANT dans .gitignore
*.ipynb  # Exclut TOUS les notebooks !

# ✅ MAINTENANT
.ipynb_checkpoints/
# Utiliser nbstripout pour nettoyer les outputs
```

### Page Exercices (Nouvelle)

**Exercices guidés :**
- Configuration initiale
- Premier dépôt et commits
- Branches et merges
- Résolution de conflits
- Pull Requests
- Défis avancés (reflog, cherry-pick)

**Quiz interactifs :**
- 12 questions avec correction automatique
- Feedback immédiat
- Scoring final
- Sélection des bonnes réponses

### Projet Fil Rouge (Nouveau)

**Pipeline ETL complet :**
- Architecture Extract-Transform-Load
- Modules Python réalistes
- Git Flow appliqué (main, develop, feature, hotfix)
- Gestion de hotfix en production
- Création de releases avec tags (v1.0.0)
- Documentation complète

**Compétences appliquées :**
- Initialisation de projet
- Stratégies de branches
- Résolution de conflits
- Pre-commit hooks
- Collaboration simulée

## 🔧 Configuration requise

- **Navigateur moderne** : Chrome, Firefox, Safari, Edge
- **Git installé** : version 2.0+
- **Éditeur de code** : VS Code recommandé
- **Terminal** : bash, zsh, ou PowerShell

## 📖 Contenu des parties

### Partie 1 : Introduction (20 min)
- Qu'est-ce que Git ?
- Concepts fondamentaux
- Architecture distribuée
- Les trois états de Git

### Partie 2 : Installation (20 min)
- Installation sur tous les OS
- Configuration initiale
- Création d'alias

### Partie 3 : Premiers pas (30 min)
- Initialiser un dépôt
- Workflow de base
- Premiers commits
- Consulter l'historique

### Partie 4 : Branches (40 min)
- Créer et gérer des branches
- Git Flow vs GitHub Flow
- Merge et rebase
- Résoudre les conflits

### Partie 5 : Collaboration (35 min)
- Remotes et GitHub
- Fetch, Pull, Push
- Pull Requests
- Workflow collaboratif

### Partie 6 : Avancé (40 min)
- Annuler des modifications
- Stash
- Tags et versioning
- Cherry-pick et reflog
- Git worktree

### Partie 7 : Meilleures pratiques (30 min) ✨
- .gitignore pour Data Engineering
- Jupyter Notebooks avec nbstripout
- Stratégies de branches
- Pre-commit hooks
- Git LFS
- Gestion des secrets

## 🎯 Objectifs pédagogiques

À la fin de cette formation, vous saurez :

✅ Initialiser et gérer un dépôt Git
✅ Créer des commits atomiques et clairs
✅ Travailler avec des branches
✅ Résoudre les conflits de merge
✅ Collaborer avec GitHub/GitLab
✅ Versionner des projets Data Engineering
✅ Mettre en place des workflows CI/CD
✅ Récupérer des erreurs avec reflog
✅ Appliquer les meilleures pratiques

## 🆘 Support

Pour toute question :
- 📧 Email : formation@example.com
- 📚 Documentation Git : https://git-scm.com/doc
- 🎓 Learn Git Branching : https://learngitbranching.js.org

## 📝 Licence

Formation Git pour Data Engineering - 2024
Contenu éducatif libre d'utilisation

## 🙏 Crédits

- Design inspiré par les meilleures pratiques UI/UX
- Exemples de code testés en conditions réelles
- Quiz JavaScript vanilla (pas de dépendances)
- Structure modulaire pour apprentissage progressif

---

**Bonne formation ! 🚀**

*N'oubliez pas : la meilleure façon d'apprendre Git, c'est de pratiquer !*
