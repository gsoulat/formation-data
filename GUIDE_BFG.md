# 🧹 Guide BFG - Nettoyer les secrets AWS

Ce guide vous explique comment utiliser BFG Repo-Cleaner pour supprimer les secrets de l'historique Git.

## 🚨 AVANT DE COMMENCER

**1. RÉVOQUER LES CLÉS AWS (CRITIQUE!)**

Les clés suivantes ont été exposées:
- Fichier: `aws/4_training/provider.tf` ligne 13-14
- Fichier: `aws/TP_2/providers.tf` ligne 13-14

**Action immédiate:**
1. Allez sur AWS Console: https://console.aws.amazon.com/iam/
2. IAM → Users → Votre utilisateur → Security credentials
3. **Désactivez** ou **Supprimez** les Access Keys exposées
4. Créez de nouvelles clés **après** avoir nettoyé le repo

---

## 🎯 SOLUTION AUTOMATIQUE (RECOMMANDÉ)

J'ai créé un script qui fait tout automatiquement.

### Exécution du script

```bash
# 1. Aller dans le répertoire
cd /Users/guillaume/workplace/Simplon/Formation

# 2. Rendre le script exécutable
chmod +x clean_secrets_with_bfg.sh

# 3. Exécuter le script
./clean_secrets_with_bfg.sh
```

Le script va:
- ✅ Installer BFG automatiquement
- ✅ Créer une sauvegarde complète
- ✅ Remplacer tous les secrets dans l'historique
- ✅ Nettoyer les références Git
- ✅ Vérifier que tout est OK

**Après l'exécution:**

```bash
# Force push (⚠️  réécrit l'historique)
git push --force origin main
```

---

## 🔧 SOLUTION MANUELLE (Étape par étape)

Si vous préférez faire manuellement:

### Étape 1: Installer BFG

**Option A: Avec Homebrew**
```bash
brew install bfg
```

**Option B: Téléchargement direct (si brew échoue)**
```bash
# Créer le dossier
mkdir -p ~/.bfg

# Télécharger BFG JAR
curl -L "https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar" \
  -o ~/.bfg/bfg.jar

# Vérifier
java -jar ~/.bfg/bfg.jar --version
```

### Étape 2: Créer une sauvegarde

```bash
# Sauvegarde complète du repository
cp -R /Users/guillaume/workplace/Simplon/Formation \
     /Users/guillaume/workplace/Simplon/formation-backup-$(date +%Y%m%d)

echo "✅ Sauvegarde créée"
```

### Étape 3: Créer le fichier de remplacement

```bash
cd /Users/guillaume/workplace/Simplon/Formation

# Créer le fichier avec les patterns à remplacer
cat > secrets-replace.txt <<'EOF'
AKIA****===>***AWS_KEY_REMOVED***
regex:access_key\s*=\s*"[^"]*"===>access_key = ""
regex:secret_key\s*=\s*"[^"]*"===>secret_key = ""
EOF
```

### Étape 4: Exécuter BFG

**Si installé avec brew:**
```bash
bfg --replace-text secrets-replace.txt
```

**Si vous utilisez le JAR:**
```bash
java -jar ~/.bfg/bfg.jar --replace-text secrets-replace.txt
```

### Étape 5: Nettoyer les refs Git

```bash
cd /Users/guillaume/workplace/Simplon/Formation

# Expirer le reflog
git reflog expire --expire=now --all

# Garbage collection agressive
git gc --prune=now --aggressive
```

### Étape 6: Vérifier

```bash
# Chercher des secrets restants
git log --all -p | grep -i "AKIA" || echo "✅ Aucun secret trouvé"

# Voir l'historique récent
git log --oneline -10
```

### Étape 7: Force Push

```bash
# ⚠️  ATTENTION: Ceci réécrit l'historique distant!
git push --force origin main
```

---

## 🎯 SOLUTION EXPRESS (Une seule commande)

Si vous êtes pressé:

```bash
cd /Users/guillaume/workplace/Simplon/Formation && \
  brew install bfg && \
  cp -R . ../formation-backup-$(date +%Y%m%d) && \
  cat > /tmp/secrets.txt <<'EOF'
AKIA****===>***REMOVED***
regex:access_key\s*=\s*".*"===>access_key = ""
regex:secret_key\s*=\s*".*"===>secret_key = ""
EOF
  bfg --replace-text /tmp/secrets.txt && \
  git reflog expire --expire=now --all && \
  git gc --prune=now --aggressive && \
  echo "✅ Nettoyage terminé! Maintenant: git push --force origin main"
```

---

## 📊 Que fait BFG exactement?

BFG parcourt **tout l'historique Git** et:

1. **Trouve** tous les commits contenant les patterns définis
2. **Remplace** les secrets par les chaînes de remplacement
3. **Réécrit** les commits avec les nouvelles valeurs
4. **Préserve** le commit le plus récent (HEAD) intact

**Avant BFG:**
```terraform
# Commit 6a291e6
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"  # ❌ Secret visible
  secret_key = "wJalrXUt..."
}
```

**Après BFG:**
```terraform
# Commit 6a291e6 (réécrits)
provider "aws" {
  access_key = ""  # ✅ Secret supprimé
  secret_key = ""
}
```

---

## ⚠️ Points importants

### Avant le force push

- [ ] J'ai **révoqué** les clés AWS exposées
- [ ] J'ai créé une **sauvegarde** du repo
- [ ] J'ai vérifié qu'**aucun secret** n'est trouvé: `git log -p | grep AKIA`
- [ ] Je suis prêt à **réécrire l'historique**

### Après le force push

- [ ] Vérifier que GitHub accepte le push
- [ ] Créer de **nouvelles clés AWS**
- [ ] Les configurer localement: `aws configure`
- [ ] Installer pre-commit: `pre-commit install`

---

## 🆘 En cas de problème

### "BFG ne s'installe pas"

Utilisez le JAR directement:
```bash
curl -L "https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar" \
  -o ~/bfg.jar
java -jar ~/bfg.jar --version
```

### "Force push rejeté"

Vérifiez les protections de branche:
```bash
# GitHub → Settings → Branches → main → Edit
# Décochez temporairement "Require linear history"
```

### "Des secrets sont toujours détectés"

Vérifiez manuellement:
```bash
# Chercher dans l'historique complet
git log --all --full-history -p -- \
  "03-Infrastructure-as-Code/Terraform/aws/*/provider*.tf" | \
  grep -A2 -B2 "AKIA"
```

### "Je veux restaurer la sauvegarde"

```bash
# Copier la sauvegarde
cp -R /Users/guillaume/workplace/Simplon/formation-backup-* \
     /Users/guillaume/workplace/Simplon/Formation-restored

cd /Users/guillaume/workplace/Simplon/Formation-restored
git log  # Vérifier l'état
```

---

## 📚 Ressources

- [BFG Documentation](https://rtyley.github.io/bfg-repo-cleaner/)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [AWS Key Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

---

## ✅ Checklist finale

Avant de considérer le problème résolu:

1. [ ] Clés AWS révoquées
2. [ ] BFG exécuté avec succès
3. [ ] Aucun secret dans: `git log -p | grep AKIA`
4. [ ] Force push réussi vers GitHub
5. [ ] Nouvelles clés AWS créées
6. [ ] Pre-commit installé: `pre-commit install`
7. [ ] Test d'un commit: `git commit -m "test"`

**Une fois tout coché, le problème est RÉSOLU! 🎉**
