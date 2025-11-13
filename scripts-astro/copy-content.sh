#!/bin/bash

# Script pour copier le contenu existant vers Astro
# Usage: ./copy-content.sh

set -e

echo "📋 Copie du contenu vers Astro"
echo "==============================="

DOCS_DIR="docs/src/content/docs"

if [ ! -d "docs" ]; then
    echo "❌ Le dossier 'docs' n'existe pas"
    echo "   Lancez d'abord: ./setup-astro.sh"
    exit 1
fi

# Créer la structure de dossiers
mkdir -p "$DOCS_DIR"/{fondamentaux,containerisation,infrastructure,cloud,databases,data-engineering,devops,briefs}

echo "📁 Création de la structure..."

# Fonction pour copier avec rapport
copy_with_report() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ -d "$src" ]; then
        echo "📂 Copie de $label..."
        cp -r "$src"/* "$dest/" 2>/dev/null || echo "   ⚠️  Aucun fichier trouvé"
        COUNT=$(find "$dest" -name "*.md" -type f | wc -l)
        echo "   ✅ $COUNT fichiers Markdown copiés"
    else
        echo "   ⏭️  $src n'existe pas, ignoré"
    fi
}

# Copier les contenus
copy_with_report "01-Fondamentaux" "$DOCS_DIR/fondamentaux" "Fondamentaux"
copy_with_report "02-Containerisation" "$DOCS_DIR/containerisation" "Containerisation"
copy_with_report "03-Infrastructure-as-Code/Terraform" "$DOCS_DIR/infrastructure/terraform" "Terraform"
copy_with_report "03-Infrastructure-as-Code/Ansible" "$DOCS_DIR/infrastructure/ansible" "Ansible"
copy_with_report "04-Cloud-Platforms" "$DOCS_DIR/cloud" "Cloud Platforms"
copy_with_report "05-Databases" "$DOCS_DIR/databases" "Databases"
copy_with_report "06-Data-Engineering" "$DOCS_DIR/data-engineering" "Data Engineering"
copy_with_report "07-DevOps" "$DOCS_DIR/devops" "DevOps"
copy_with_report "99-Brief" "$DOCS_DIR/briefs" "Briefs & Projets"

echo ""
echo "🎉 Copie terminée !"
echo ""
echo "📝 Prochaines étapes :"
echo "   1. Ajoutez le frontmatter: ./add-frontmatter.sh"
echo "   2. Configurez astro.config.mjs"
echo "   3. Lancez: cd docs && npm run dev"
echo ""
