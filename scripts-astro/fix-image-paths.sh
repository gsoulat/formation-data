#!/bin/bash

# Script pour corriger les chemins d'images dans les fichiers Markdown
# Usage: ./fix-image-paths.sh

set -e

echo "🔧 Correction des chemins d'images"
echo "===================================="

DOCS_DIR="docs/src/content/docs"

if [ ! -d "$DOCS_DIR" ]; then
    echo "❌ Le dossier $DOCS_DIR n'existe pas"
    exit 1
fi

echo "🔍 Recherche des fichiers Markdown avec des images..."

COUNT=0

# Parcourir tous les fichiers .md
find "$DOCS_DIR" -name "*.md" -type f | while read file; do
    # Vérifier si le fichier contient des références à des images
    if grep -q -E '!\[.*\]\(.*\.(png|jpg|jpeg|gif|svg|webp)' "$file" 2>/dev/null; then

        # Créer un backup
        cp "$file" "${file}.bak"

        # Corriger les chemins d'images
        # images/xxx.png -> /images/xxx.png
        sed -i.tmp 's|!\[\([^]]*\)\](images/|\![\1](/images/|g' "$file"

        # ../images/xxx.png -> /images/xxx.png
        sed -i.tmp 's|!\[\([^]]*\)\](\.\./images/|\![\1](/images/|g' "$file"

        # ./images/xxx.png -> /images/xxx.png
        sed -i.tmp 's|!\[\([^]]*\)\](\./images/|\![\1](/images/|g' "$file"

        # Supprimer les fichiers temporaires
        rm -f "${file}.tmp"

        echo "✅ Corrigé: $file"
        ((COUNT++)) || true
    fi
done

echo ""
echo "🎉 Terminé !"
echo "   - $COUNT fichiers corrigés"
echo ""
echo "📝 Les chemins d'images pointent maintenant vers /images/"
echo ""
