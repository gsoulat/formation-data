#!/bin/bash

# Script d'installation automatique d'Astro Starlight
# Usage: ./setup-astro.sh

set -e

echo "🚀 Installation d'Astro Starlight pour Formation Data Engineer"
echo "=============================================================="

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé"
    echo "📥 Installez Node.js depuis: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version $NODE_VERSION détectée"
    echo "📥 Version 18+ requise. Mettez à jour Node.js"
    exit 1
fi

echo "✅ Node.js $(node -v) détecté"

# Créer le dossier docs si nécessaire
if [ -d "docs" ]; then
    echo "⚠️  Le dossier 'docs' existe déjà"
    read -p "Voulez-vous le supprimer et recommencer? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf docs
        echo "🗑️  Dossier docs supprimé"
    else
        echo "❌ Installation annulée"
        exit 1
    fi
fi

# Installer Astro
echo "📦 Installation d'Astro..."
npm create astro@latest docs -- --template minimal --no-install --no-git --typescript false

# Installer les dépendances
cd docs
echo "📦 Installation des dépendances..."
npm install

# Installer Starlight
echo "⭐ Installation de Starlight..."
npx astro add starlight --yes

echo ""
echo "✅ Installation terminée !"
echo ""
echo "📝 Prochaines étapes :"
echo "   1. Suivez le guide GUIDE_ASTRO.md"
echo "   2. Configurez astro.config.mjs"
echo "   3. Copiez vos fichiers Markdown"
echo "   4. Lancez: cd docs && npm run dev"
echo ""
