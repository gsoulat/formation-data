# 🏴‍☠️ Brief Pratique Bash/Zsh - La Chasse au Trésor du Terminal

**Durée estimée :** 4-6 heures
**Niveau :** Débutant à Intermédiaire
**Modalité :** Pratique individuelle

---

## 🎯 Objectifs du Brief

À l'issue de cette chasse au trésor, vous serez capable de :
- Naviguer efficacement dans le système de fichiers
- Manipuler des fichiers et dossiers (copier, déplacer, créer)
- Afficher et lire des fichiers cachés
- Utiliser les variables d'environnement
- Créer et utiliser des alias
- Rendre des scripts exécutables et les ajouter au PATH
- Modifier et sourcer votre fichier de configuration shell (.bashrc/.zshrc)

---

## 📋 Contexte

Bienvenue, jeune aventurier ! 🗺️

Vous venez de découvrir une carte ancienne menant au légendaire **Rouleau du Dragon**, écrit par le grand maître Oogway lui-même. Ce rouleau contient le secret du pouvoir sans limites !

Mais attention, le chemin est semé d'embûches et de mystères. Vous devrez utiliser vos compétences en ligne de commande pour progresser d'étape en étape, déchiffrer des indices et finalement découvrir le trésor.

**Êtes-vous prêt pour l'aventure ? ⚔️**

---

## 📦 Préparation

### Téléchargement du dossier treasure_hunt

Avant de commencer, vous devez obtenir le dossier `treasure_hunt` qui contient tous les éléments de la chasse au trésor.

> **Note :** Votre formateur vous fournira le fichier `treasure_hunt.zip`. Téléchargez-le et dézippez-le.

```bash
# Si vous avez reçu un fichier ZIP
unzip treasure_hunt.zip

# Vérifier que le dossier est bien créé
ls -la
```

**Critères de validation :**
- ✅ Le dossier `treasure_hunt` existe
- ✅ Vous pouvez entrer dedans avec `cd treasure_hunt`

---

## 🗺️ Partie 1 : La Première Exploration (1h)

### 🎯 Objectif
Apprendre à naviguer dans les dossiers, afficher les fichiers cachés et lire des fichiers.

---

### Étape 1 : Entrez dans l'aventure

**Instructions :**

1. Déplacez-vous dans le dossier `treasure_hunt` (dézippé) :
   ```bash
   cd treasure_hunt
   ```

2. Listez tous les dossiers et fichiers :
   ```bash
   ls -la
   ```

**💡 Astuce :** L'option `-a` permet d'afficher les fichiers et dossiers cachés (ceux qui commencent par un point `.`)

**Questions :**
- Combien de dossiers voyez-vous ?
- Y a-t-il des fichiers cachés ?

---

### Étape 2 : Le point de départ

3. Un dossier s'appelle `start`. Déplacez-vous dedans :
   ```bash
   cd start
   ```

4. Regardez ce qu'il y a dedans :
   ```bash
   ls -la
   ```

**💡 Observation :** Vous devriez voir des dossiers et peut-être des fichiers cachés !

---

### Étape 3 : Le premier dossier caché

5. Il y a un dossier caché qui commence par `./10feet_...`. Trouvez-le et entrez dedans :
   ```bash
   # Pour voir les dossiers cachés
   ls -la

   # Pour entrer dans le dossier (remplacez XXX par le nom complet)
   cd ./10feet_XXX
   ```

**💡 Astuce :** Utilisez la touche **TAB** pour l'autocomplétion ! Tapez `cd ./10` puis appuyez sur TAB.

---

### Étape 4 : Le premier indice

6. Il y a un fichier qui s'appelle `indice.txt`. Ouvrez-le :
   ```bash
   cat indice.txt
   # ou
   less indice.txt
   ```

**💡 Note :** Avec `less`, appuyez sur `q` pour quitter.

7. Lisez l'indice et suivez les instructions pour trouver le prochain emplacement.

---

### Étape 5 : Suivez la piste ! 🔍

À partir de maintenant, **suivez les indices que vous trouverez dans chaque fichier `indice.txt`**.

Chaque indice vous donnera :
- Le nom du prochain dossier ou fichier à trouver
- Parfois des commandes à exécuter
- Des informations importantes pour la suite

**Commandes utiles pour vous déplacer :**
```bash
# Voir où vous êtes
pwd

# Remonter d'un niveau
cd ..

# Revenir au dossier de départ
cd ~/treasure_hunt/start

# Lister avec détails
ls -lah

# Chercher un fichier
find . -name "indice.txt"

# Lire un fichier
cat nom_du_fichier.txt
less nom_du_fichier.txt
head nom_du_fichier.txt
tail nom_du_fichier.txt
```

---

### 🏆 Objectif de la Partie 1

Continuez à explorer et à suivre les indices jusqu'à ce que vous trouviez **le mot de passe secret** !

**Critères de validation :**
- ✅ Vous avez trouvé et lu au moins 5 indices
- ✅ Vous savez naviguer entre les dossiers avec `cd`
- ✅ Vous savez afficher les fichiers cachés avec `ls -la`
- ✅ Vous avez trouvé le mot de passe secret

**💡 Note importante :** Les dernières étapes pour trouver le trésor sont les plus difficiles, ne vous découragez pas ! 💪

---

## 🚀 Partie 2 : Le Rituel Magique (2h)

### 🎯 Objectif
Apprendre à copier des dossiers, utiliser les variables d'environnement, créer des alias et rendre des scripts exécutables.

---

### Étape 1 : Préparer le terrain

**Instructions :**

1. **Copiez le dossier `treasure_hunt` dans votre répertoire personnel** :

   ```bash
   # Si vous êtes sur Linux/WSL
   cp -r treasure_hunt ~/

   # Si vous êtes sur macOS
   cp -r treasure_hunt ~/

   # Vérifier que la copie a réussi
   ls -la ~/ | grep treasure_hunt
   ```

   **💡 Pour les utilisateurs WSL (Windows) :**
   Si votre dossier `treasure_hunt` est dans Windows, vous devez d'abord le copier vers Linux :
   ```bash
   # Trouver le chemin Windows (commence par /mnt/)
   # Par exemple : /mnt/c/Users/VotreNom/Downloads/treasure_hunt

   # Copier vers votre home Linux
   cp -r /mnt/c/Users/VotreNom/Downloads/treasure_hunt ~/
   ```

2. **Déplacez-vous dans le dossier copié** :
   ```bash
   cd ~/treasure_hunt
   pwd
   ```

**Critères de validation :**
- ✅ Le dossier `treasure_hunt` est dans votre répertoire personnel (`~/`)
- ✅ Vous êtes positionné dans `~/treasure_hunt`

---

### Étape 2 : La variable magique

3. **Créez une variable d'environnement avec le code secret** trouvé lors de la première chasse au trésor :

   ```bash
   # Remplacez VOTRE_CODE par le mot de passe que vous avez trouvé
   export CODE="VOTRE_CODE"

   # Vérifier que la variable est bien définie
   echo $CODE
   ```

**💡 Important :** Cette variable n'existera que pendant votre session actuelle. Si vous fermez le terminal, vous devrez la recréer.

**Critères de validation :**
- ✅ La commande `echo $CODE` affiche votre mot de passe

---

### Étape 3 : Trouver le script magique

4. **Un fichier `formule.sh` se trouve quelque part sous l'arbre 14** (tree 14 ou arbre 14).

   Cherchez-le :
   ```bash
   # Depuis la racine de treasure_hunt
   find . -name "formule.sh"
   ```

**💡 Note :** Notez bien le chemin complet du fichier, vous en aurez besoin !

---

### Étape 4 : Rendre le script exécutable depuis n'importe où

5. **Rendez le script exécutable** :
   ```bash
   # Remplacez le chemin par celui que vous avez trouvé
   chmod +x chemin/vers/formule.sh
   ```

6. **Ajoutez le dossier contenant `formule.sh` à votre PATH** :

   Pour rendre le script accessible depuis n'importe où, vous devez ajouter son dossier au PATH.

   **Option 1 : Temporaire (pour cette session uniquement)**
   ```bash
   # Remplacez par le chemin du DOSSIER contenant formule.sh
   export PATH="$PATH:/chemin/vers/le/dossier"

   # Vérifier
   echo $PATH
   ```

   **Option 2 : Permanent (recommandé)**

   Ajoutez la ligne dans votre fichier de configuration :
   ```bash
   # Si vous utilisez Bash
   nano ~/.bashrc

   # Si vous utilisez Zsh (macOS par défaut)
   nano ~/.zshrc
   ```

   Ajoutez cette ligne à la fin du fichier :
   ```bash
   export PATH="$PATH:~/treasure_hunt/chemin/vers/le/dossier"
   ```

   Sauvegardez et rechargez :
   ```bash
   source ~/.bashrc   # ou source ~/.zshrc
   ```

**Critères de validation :**
- ✅ `chmod +x` a été exécuté sur `formule.sh`
- ✅ Le script est accessible depuis n'importe quel dossier

---

### Étape 5 : Créer l'alias magique

7. **Créez un alias pour `formule.sh` qui s'appelle `abracadabash`** :

   Ouvrez votre fichier de configuration :
   ```bash
   # Bash
   nano ~/.bashrc

   # Zsh
   nano ~/.zshrc
   ```

   Ajoutez cette ligne :
   ```bash
   alias abracadabash='~/treasure_hunt/chemin/vers/formule.sh'
   ```

   **💡 Remplacez le chemin par le chemin complet vers votre script !**

8. **Rechargez votre configuration** :
   ```bash
   source ~/.bashrc   # ou source ~/.zshrc
   ```

9. **Testez votre alias** :
   ```bash
   abracadabash
   ```

**Critères de validation :**
- ✅ L'alias `abracadabash` est défini
- ✅ La commande `abracadabash` exécute le script

---

### Étape 6 : L'incantation sous le rocher

10. **Rendez-vous sous le rocher 1** (rock 1 ou rocher 1) et exécutez `formule.sh` avec l'alias :

    ```bash
    # Trouvez le dossier "rock_1" ou similaire
    cd ~/treasure_hunt
    find . -name "*rock*1*" -type d

    # Allez-y
    cd chemin/vers/rock_1

    # Exécutez le script avec l'alias
    abracadabash
    ```

**💡 ATTENTION :** Assurez-vous que vous n'avez pas dézippé le dossier `treasure_hunt` dans un autre dossier `treasure_hunt`, sinon les chemins ne fonctionneront pas !

Si le script vous demande le mot de passe, il utilisera la variable `$CODE` que vous avez définie.

---

### Étape 7 : La trappe secrète

11. **Si vous entrez les bons mots de passe, une trappe devrait apparaître** à l'endroit où vous êtes.

    Cherchez un nouveau fichier ou dossier qui vient d'apparaître :
    ```bash
    ls -la
    ```

12. **Trouvez le moyen d'ouvrir la trappe** :
    - Il peut s'agir d'un fichier à lire
    - Ou d'un script à exécuter
    - Ou d'un dossier caché à explorer

**💡 Indice :** Cherchez quelque chose qui contient "trappe", "door", "hatch" dans son nom.

---

### Étape 8 : Le Rouleau du Dragon

13. **Après avoir ouvert la trappe, une nouvelle incantation est disponible.**

    Cherchez un nouveau script ou fichier :
    ```bash
    ls -la
    find . -name "*.sh"
    ```

14. **Lancez la nouvelle incantation** pour accéder au **Rouleau du Dragon** :
    ```bash
    # Rendez le script exécutable si nécessaire
    chmod +x nom_du_script.sh

    # Exécutez-le
    ./nom_du_script.sh
    ```

---

### 🐉 Félicitations !

**Si vous avez réussi, vous devriez maintenant voir le Rouleau du Dragon, qui contient le secret du pouvoir sans limites !**

**Critères de validation :**
- ✅ Vous avez copié `treasure_hunt` dans votre home
- ✅ La variable `CODE` est définie
- ✅ Le script `formule.sh` est exécutable
- ✅ L'alias `abracadabash` fonctionne
- ✅ Vous avez trouvé et ouvert la trappe
- ✅ Vous avez découvert le Rouleau du Dragon

---