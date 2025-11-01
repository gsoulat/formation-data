#!/bin/bash

# Script pour nettoyer les secrets AWS avec BFG Repo-Cleaner
# ⚠️  ATTENTION: Ce script réécrit l'historique Git!

set -e  # Arrêter en cas d'erreur

REPO_DIR="/Users/guillaume/workplace/Simplon/Formation"
BACKUP_DIR="/Users/guillaume/workplace/Simplon/formation-backup-$(date +%Y%m%d-%H%M%S)"

echo "🚨 NETTOYAGE DES SECRETS AVEC BFG REPO-CLEANER"
echo "=============================================="
echo ""

# Vérifier qu'on est dans le bon répertoire
cd "$REPO_DIR"

# Vérifier l'état Git
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  Il y a des modifications non commitées!"
    echo "Voulez-vous continuer? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo "❌ Annulé"
        exit 1
    fi
fi

echo "📦 Étape 1: Installation de BFG..."
echo "-----------------------------------"

# Vérifier si BFG est installé
if ! command -v bfg &> /dev/null; then
    echo "BFG n'est pas installé. Installation..."

    # Méthode 1: Avec brew
    if command -v brew &> /dev/null; then
        echo "Installation via Homebrew..."
        brew install bfg
    else
        # Méthode 2: Téléchargement direct du JAR
        echo "Téléchargement du JAR BFG..."
        BFG_VERSION="1.14.0"
        BFG_JAR="$HOME/.bfg/bfg-${BFG_VERSION}.jar"
        mkdir -p "$HOME/.bfg"

        if [[ ! -f "$BFG_JAR" ]]; then
            curl -L "https://repo1.maven.org/maven2/com/madgag/bfg/${BFG_VERSION}/bfg-${BFG_VERSION}.jar" -o "$BFG_JAR"
        fi

        # Créer un alias
        alias bfg="java -jar $BFG_JAR"
        echo "✅ BFG téléchargé dans $BFG_JAR"
        echo "💡 Utilisation: java -jar $BFG_JAR"
    fi
else
    echo "✅ BFG est déjà installé"
fi

echo ""
echo "💾 Étape 2: Création d'une sauvegarde..."
echo "----------------------------------------"

# Créer une sauvegarde complète
echo "Sauvegarde dans: $BACKUP_DIR"
cp -R "$REPO_DIR" "$BACKUP_DIR"
echo "✅ Sauvegarde créée"

echo ""
echo "🔍 Étape 3: Identification des secrets..."
echo "-----------------------------------------"

# Créer un fichier avec les patterns de secrets à remplacer
cat > /tmp/secrets-to-replace.txt <<'EOF'
AKIA****===>***REMOVED_AWS_KEY***
regex:secret_key\s*=\s*"[^"]*"===>secret_key = "***REMOVED***"
regex:access_key\s*=\s*"[^"]*"===>access_key = "***REMOVED***"
EOF

echo "✅ Fichier de remplacement créé: /tmp/secrets-to-replace.txt"
cat /tmp/secrets-to-replace.txt

echo ""
echo "🧹 Étape 4: Nettoyage avec BFG..."
echo "---------------------------------"

# Exécuter BFG pour remplacer les secrets
if command -v bfg &> /dev/null; then
    bfg --replace-text /tmp/secrets-to-replace.txt "$REPO_DIR/.git"
else
    # Utiliser le JAR directement
    BFG_JAR="$HOME/.bfg/bfg-1.14.0.jar"
    if [[ -f "$BFG_JAR" ]]; then
        java -jar "$BFG_JAR" --replace-text /tmp/secrets-to-replace.txt "$REPO_DIR/.git"
    else
        echo "❌ BFG non trouvé. Impossible de continuer."
        exit 1
    fi
fi

echo ""
echo "🗑️  Étape 5: Nettoyage des refs Git..."
echo "---------------------------------------"

cd "$REPO_DIR"

# Nettoyer les références
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ Nettoyage des refs terminé"

echo ""
echo "🔍 Étape 6: Vérification..."
echo "---------------------------"

# Vérifier qu'il n'y a plus de secrets
echo "Recherche de secrets restants..."
if git log --all -p | grep -i "AKIA" | head -5; then
    echo "⚠️  Des secrets AKIA ont été trouvés!"
else
    echo "✅ Aucun secret AKIA trouvé"
fi

echo ""
echo "📊 Étape 7: Statistiques..."
echo "---------------------------"

# Voir la taille du repo avant/après
du -sh .git
git count-objects -vH

echo ""
echo "✅ NETTOYAGE TERMINÉ!"
echo "===================="
echo ""
echo "📝 Prochaines étapes:"
echo ""
echo "1. Vérifier les changements:"
echo "   git log --oneline -10"
echo ""
echo "2. Tester localement:"
echo "   cd $REPO_DIR"
echo "   git status"
echo ""
echo "3. Force push vers GitHub (⚠️  ATTENTION):"
echo "   git push --force origin main"
echo ""
echo "💾 Sauvegarde disponible dans:"
echo "   $BACKUP_DIR"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - RÉVOQUEZ les anciennes clés AWS avant de push!"
echo "   - Le force push va réécrire l'historique"
echo "   - Si d'autres personnes travaillent sur le repo, coordonnez-vous!"
echo ""
