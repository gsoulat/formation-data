#!/bin/bash

# Script pour ajouter automatiquement le frontmatter aux fichiers Markdown
# Usage: ./add-frontmatter.sh [chemin-vers-docs]

set -e

DOCS_PATH="${1:-docs/src/content/docs}"

if [ ! -d "$DOCS_PATH" ]; then
    echo "❌ Le dossier $DOCS_PATH n'existe pas"
    exit 1
fi

echo "🔍 Recherche de fichiers Markdown dans $DOCS_PATH..."

COUNT=0
SKIPPED=0

# Fonction pour nettoyer le titre
clean_title() {
    local title="$1"
    # Supprimer les #, *, `, etc.
    title=$(echo "$title" | sed 's/^#* *//' | sed 's/[*`]//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    echo "$title"
}

# Fonction pour créer un titre à partir du nom de fichier
filename_to_title() {
    local filename="$1"
    # Supprimer l'extension
    filename=$(basename "$filename" .md)
    # Remplacer - et _ par des espaces
    filename=$(echo "$filename" | sed 's/[-_]/ /g')
    # Capitaliser chaque mot (première lettre en majuscule)
    filename=$(echo "$filename" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
    echo "$filename"
}

# Parcourir tous les fichiers .md
find "$DOCS_PATH" -name "*.md" -type f | while read file; do
    # Vérifier si le frontmatter existe déjà
    if head -n 1 "$file" | grep -q "^---$"; then
        echo "⏭️  Ignoré (frontmatter existant): $file"
        ((SKIPPED++)) || true
        continue
    fi

    # Extraire le titre du premier H1
    title=$(grep -m 1 "^# " "$file" 2>/dev/null | sed 's/^# //' || echo "")
    title=$(clean_title "$title")

    # Si pas de H1, utiliser le nom du fichier
    if [ -z "$title" ]; then
        title=$(filename_to_title "$file")
    fi

    # Créer une description (première phrase du contenu ou titre)
    description=$(grep -v "^#" "$file" | grep -v "^$" | head -n 1 | sed 's/[*`]//g' | cut -c1-150 || echo "$title")
    if [ -z "$description" ]; then
        description="$title"
    fi

    # Créer un fichier temporaire avec le frontmatter
    {
        echo "---"
        echo "title: \"$title\""
        echo "description: \"$description\""
        echo "sidebar:"
        echo "  hidden: false"
        echo "---"
        echo ""
        cat "$file"
    } > "${file}.tmp"

    # Remplacer le fichier original
    mv "${file}.tmp" "$file"

    echo "✅ Frontmatter ajouté: $file"
    ((COUNT++)) || true
done

echo ""
echo "🎉 Terminé !"
echo "   - $COUNT fichiers traités"
echo "   - $SKIPPED fichiers ignorés (déjà traités)"
echo ""
