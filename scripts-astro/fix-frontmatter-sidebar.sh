#!/bin/bash

# Script pour ajouter la propriété sidebar aux frontmatters existants
# Usage: ./fix-frontmatter-sidebar.sh

set -e

DOCS_PATH="docs/src/content/docs"

if [ ! -d "$DOCS_PATH" ]; then
    echo "❌ Le dossier $DOCS_PATH n'existe pas"
    exit 1
fi

echo "🔧 Ajout de la propriété sidebar aux frontmatters..."

COUNT=0

find "$DOCS_PATH" -name "*.md" -type f | while read file; do
    # Vérifier si le fichier a un frontmatter
    if ! head -n 1 "$file" | grep -q "^---$"; then
        echo "⏭️  Ignoré (pas de frontmatter): $file"
        continue
    fi

    # Vérifier si sidebar existe déjà
    if grep -q "^sidebar:" "$file"; then
        echo "⏭️  Ignoré (sidebar existe): $file"
        continue
    fi

    # Trouver la ligne de fin du frontmatter
    closing_line=$(awk '/^---$/{if (NR>1) {print NR; exit}}' "$file")

    if [ -z "$closing_line" ]; then
        echo "⚠️  Frontmatter invalide: $file"
        continue
    fi

    # Insérer sidebar avant la ligne de fermeture
    {
        head -n $((closing_line - 1)) "$file"
        echo "sidebar:"
        echo "  hidden: false"
        tail -n +$closing_line "$file"
    } > "${file}.tmp"

    mv "${file}.tmp" "$file"

    echo "✅ Corrigé: $file"
    ((COUNT++)) || true
done

echo ""
echo "🎉 Terminé !"
echo "   - $COUNT fichiers corrigés"
echo ""
