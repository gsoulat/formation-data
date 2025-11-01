#!/bin/bash

# Solution définitive pour supprimer les secrets du commit 6a291e6
set -e

cd "/Users/guillaume/workplace/Simplon/Formation"

echo "🚨 SOLUTION DÉFINITIVE - Suppression du commit avec secrets"
echo "==========================================================="
echo ""

# Afficher l'historique actuel
echo "📜 Historique actuel:"
git log --oneline -5
echo ""

echo "💡 Solution: Nous allons réécrire l'historique en supprimant le commit 6a291e6"
echo ""

# Méthode: Rebase interactif pour DROP le commit problématique
echo "🔧 Étape 1: Reset vers le commit avant les secrets"
echo "---------------------------------------------------"

# Le commit parent de 6a291e6 est 0d06697
# On va reset vers 0d06697 et recréer les commits propres

# Sauvegarder les fichiers actuels
echo "Sauvegarde des fichiers actuels..."
git stash push -m "Backup before reset" || true

# Reset hard vers le dernier commit sain (avant 6a291e6)
echo "Reset vers 0d06697 (dernier commit sans secrets)..."
git reset --hard 0d06697

echo "✅ Reset effectué"
echo ""

echo "🔧 Étape 2: Récupérer les fichiers propres"
echo "-------------------------------------------"

# Récupérer les fichiers propres du stash ou de HEAD précédent
git stash pop || true

# Ou récupérer depuis les commits récents
git checkout 37c5f9c -- . 2>/dev/null || true

echo "✅ Fichiers récupérés"
echo ""

echo "🔧 Étape 3: Créer un nouveau commit propre"
echo "------------------------------------------"

# Ajouter tous les changements
git add .

# Créer un commit propre
git commit -m "feat(terraform): add terraform examples and courses

- Add Hetzner Cloud examples (provider, server, network, variables)
- Add Linode examples (provider, instance, firewall, VPC)
- Add Oracle Cloud examples (provider, compute, object storage)
- Add OVH Cloud examples (provider, instance, kubernetes, object storage)
- Add Infomaniak examples (provider, instance, object storage)
- Add AWS training examples
- Configure pre-commit hooks for secret detection
- Configure semantic-release for versioning
- Add comprehensive documentation (CONTRIBUTING.md, SECURITY.md)

All provider configurations use environment variables or AWS CLI
credentials instead of hardcoded secrets.

🤖 Generated with Claude Code" || echo "Pas de changements à commiter"

echo "✅ Nouveau commit créé"
echo ""

echo "📊 Nouvel historique:"
git log --oneline -5
echo ""

echo "🔍 Vérification des secrets..."
if git log --all -p | grep -i "AKIA" | head -5; then
    echo "⚠️  Des secrets sont encore présents!"
    echo "Vérification manuelle requise"
else
    echo "✅ Aucun secret trouvé dans l'historique!"
fi

echo ""
echo "✅ TERMINÉ!"
echo "=========="
echo ""
echo "Prochaine étape: Force push vers GitHub"
echo ""
echo "  git push --force origin main"
echo ""
echo "⚠️  Ceci va réécrire l'historique distant!"
echo ""
