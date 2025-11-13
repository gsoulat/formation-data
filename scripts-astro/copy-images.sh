#!/bin/bash

# Script pour copier les images vers Astro
# Usage: ./copy-images.sh

set -e

echo "📸 Copie des images vers Astro"
echo "==============================="

DOCS_DIR="docs/src/content/docs"
PUBLIC_DIR="docs/public"

if [ ! -d "docs" ]; then
    echo "❌ Le dossier 'docs' n'existe pas"
    echo "   Lancez d'abord: ./setup-astro.sh"
    exit 1
fi

# Créer le dossier public/images si nécessaire
mkdir -p "$PUBLIC_DIR/images"

echo "📁 Copie des images..."

# Fonction pour copier avec rapport
copy_images() {
    local src="$1"
    local label="$2"

    if [ -d "$src" ]; then
        echo "📂 Copie des images de $label..."

        # Trouver et copier tous les fichiers images
        COUNT=0
        while IFS= read -r -d '' img; do
            # Copier dans public/images en préservant la structure relative
            REL_PATH=$(dirname "${img#$src/}")
            mkdir -p "$PUBLIC_DIR/images/$REL_PATH"
            cp "$img" "$PUBLIC_DIR/images/$REL_PATH/" 2>/dev/null || true
            ((COUNT++)) || true
        done < <(find "$src" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" -o -name "*.webp" \) -print0 2>/dev/null)

        echo "   ✅ $COUNT images copiées"
    else
        echo "   ⏭️  $src n'existe pas, ignoré"
    fi
}

# Copier les images de chaque section
copy_images "04-Cloud-Platforms/snowflake/images" "Snowflake"
copy_images "07-DevOps/02-Monitoring/images" "Monitoring"
copy_images "01-Fondamentaux" "Fondamentaux"
copy_images "02-Containerisation" "Containerisation"
copy_images "03-Infrastructure-as-Code" "Infrastructure"
copy_images "04-Cloud-Platforms" "Cloud"
copy_images "05-Databases" "Databases"
copy_images "06-Data-Engineering" "Data Engineering"
copy_images "99-Brief" "Briefs"

echo ""
echo "🎉 Copie terminée !"
echo ""
echo "📝 Les images sont maintenant dans: docs/public/images/"
echo "   Redémarrez le serveur: cd docs && npm run dev"
echo ""
