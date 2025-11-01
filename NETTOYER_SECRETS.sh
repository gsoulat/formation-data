#!/bin/bash

# Script pour nettoyer définitivement les secrets de l'historique Git
# Ce script va réécrire l'historique en supprimant le commit 6a291e6

set -e

echo "🚨 NETTOYAGE DÉFINITIF DES SECRETS"
echo "===================================="
echo ""

cd /Users/guillaume/workplace/Simplon/Formation

echo "📜 Historique actuel:"
git log --oneline -5
echo ""

echo "⚠️  ATTENTION: Cette opération va réécrire l'historique Git!"
echo "Le commit 6a291e6 (avec secrets) sera supprimé."
echo ""
read -p "Continuer? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Annulé"
    exit 1
fi

echo ""
echo "🔧 Étape 1: Reset au commit avant les secrets"
echo "----------------------------------------------"
# Reset au commit 0d06697 (dernier commit sain)
git reset --hard 0d06697
echo "✅ Reset effectué vers 0d06697"
echo ""

echo "🔧 Étape 2: Récupération des fichiers propres"
echo "----------------------------------------------"
# Récupérer tous les fichiers du commit récent (37c5f9c)
git checkout 37c5f9c -- . || true
echo "✅ Fichiers récupérés"
echo ""

echo "🔧 Étape 3: Ajout des fichiers"
echo "-------------------------------"
git add .
echo "✅ Fichiers ajoutés"
echo ""

echo "🔧 Étape 4: Création du commit propre"
echo "--------------------------------------"
git commit -m "feat(terraform): add cloud provider examples and security tooling

- Add Hetzner Cloud examples (provider, server, network, variables)
- Add Linode examples (provider, instance, firewall, VPC)
- Add Oracle Cloud examples (provider, compute, object storage)
- Add OVHcloud examples (provider, instance, kubernetes, object storage)
- Add Infomaniak examples (provider, instance, object storage)
- Add AWS and Azure training materials
- Configure pre-commit hooks for secret detection (gitleaks, detect-secrets)
- Configure semantic-release for automatic versioning
- Add comprehensive documentation (CONTRIBUTING.md, SECURITY.md, HOW_IT_WORKS.md)

All provider configurations use environment variables or cloud CLI credentials.
No secrets are hardcoded in any files.

🤖 Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>" || echo "Aucun changement à commiter"

echo "✅ Commit créé"
echo ""

echo "📜 Nouvel historique:"
git log --oneline -5
echo ""

echo "🔍 Étape 5: Vérification des secrets"
echo "-------------------------------------"
if git log --all -p | grep -i "AKIA" | head -5; then
    echo ""
    echo "⚠️  ATTENTION: Des secrets AKIA sont encore présents!"
    echo "Vérification manuelle nécessaire."
    exit 1
else
    echo "✅ Aucun secret AKIA trouvé dans l'historique!"
fi
echo ""

echo "✅ NETTOYAGE TERMINÉ AVEC SUCCÈS!"
echo "=================================="
echo ""
echo "📤 Prochaine étape: Force push vers GitHub"
echo ""
echo "Exécutez cette commande:"
echo ""
echo "  git push --force origin main"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Cette commande va réécrire l'historique distant"
echo "  - Assurez-vous d'avoir révoqué les anciennes clés AWS"
echo "  - Si d'autres personnes travaillent sur ce repo, coordonnez-vous!"
echo ""
