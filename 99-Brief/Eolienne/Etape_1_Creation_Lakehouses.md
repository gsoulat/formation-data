# Étape 1 : Création des Lakehouses

**Durée estimée :** 20-30 minutes  
**Difficulté :** ⭐ Facile

---

## 🎯 Objectifs de cette étape

À la fin de cette étape, vous aurez :

- ✅ Compris le concept de Lakehouse dans Microsoft Fabric
- ✅ Créé le Lakehouse Bronze pour les données brutes
- ✅ Créé le Lakehouse Silver pour les données nettoyées
- ✅ Créé le Lakehouse Gold pour le modèle dimensionnel
- ✅ Vérifié que les 3 Lakehouses sont bien présents dans votre Workspace

---

## 📋 Prérequis

Avant de commencer cette étape, vous devez avoir complété :

- ✅ [Étape 0 : Préparation de l'environnement](01_Etape_0_Preparation_Environnement.md)
  - Trial Fabric activé
  - Workspace `WindPowerAnalytics` créé

---

## 📚 Comprendre le concept de Lakehouse

### Qu'est-ce qu'un Lakehouse ?

Un **Lakehouse** dans Microsoft Fabric est une architecture de données moderne qui combine :

- 📁 **Data Lake** : Stockage flexible de fichiers (CSV, JSON, Parquet, etc.)
- 🗄️ **Data Warehouse** : Capacités de requêtes SQL et analytiques

### Avantages du Lakehouse

- 🔄 **Transactions ACID** : Garantit la cohérence des données
- 📸 **Versioning** : Possibilité de revenir à des versions antérieures des données
- ⚡ **Performances optimisées** : Format Delta Lake hautement performant
- 🔍 **Requêtes SQL directes** : Interrogez vos données comme une base de données
- 🌊 **Streaming et Batch** : Supporte les deux modes de traitement

### Structure d'un Lakehouse

Chaque Lakehouse contient deux sections principales :

1. **Files (Fichiers)** :
   - Pour stocker des fichiers bruts (CSV, JSON, images, etc.)
   - Organisés en dossiers comme un système de fichiers classique

2. **Tables** :
   - Pour stocker des tables Delta Lake
   - Interrogeables avec SQL
   - Optimisées pour les performances analytiques

### Le modèle Medallion

Dans ce projet, nous implémentons l'architecture **Medallion** avec trois couches :

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     BRONZE      │       │     SILVER      │       │      GOLD       │
│  (Raw Data)     │   →   │  (Cleaned Data) │   →   │  (Business Data)│
│                 │       │                 │       │                 │
│ • Données brutes│       │ • Nettoyées     │       │ • Modèle        │
│ • Format origine│       │ • Validées      │       │   dimensionnel  │
│ • Pas de transfo│       │ • Enrichies     │       │ • Optimisé BI   │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

- **Bronze** 🥉 : Données telles qu'ingérées (exactement comme dans la source)
- **Silver** 🥈 : Données nettoyées, standardisées, enrichies
- **Gold** 🥇 : Données organisées pour l'analyse métier (modèle dimensionnel)

> 💡 **Analogie** : Imaginez une usine de raffinage :
> - Bronze = Matière première brute
> - Silver = Matière purifiée et standardisée
> - Gold = Produit fini prêt à être consommé

---

## 🥉 Tâche 1 : Créer le Lakehouse Bronze

Le Lakehouse Bronze va stocker les données brutes telles qu'elles sont ingérées depuis la source GitHub.

### 1.1 - Accéder à votre Workspace

1. **Ouvrez Microsoft Fabric** : [app.fabric.microsoft.com](https://app.fabric.microsoft.com)

2. **Dans le menu latéral gauche**, cliquez sur **"Workspaces"**

3. **Sélectionnez votre Workspace** : `WindPowerAnalytics`

### 1.2 - Créer le Lakehouse

1. **Cliquez sur le bouton "+ New item"** (ou "+ New")
   - Il se trouve en haut de la page du Workspace

2. **Dans la liste des types d'items**, recherchez et cliquez sur **"Lakehouse"**
   - Vous pouvez utiliser la barre de recherche pour taper "Lakehouse"

3. **Une fenêtre de création s'ouvre**

4. **Entrez le nom** : `LH_Wind_Power_Bronze`
   - Le préfixe `LH_` signifie "Lakehouse" - c'est une bonne pratique de nommage
   - Cela vous aidera à identifier rapidement le type de ressource

5. **Cliquez sur "Create"**

### 1.3 - Explorer la structure du Lakehouse

Après quelques secondes, le Lakehouse est créé et vous êtes automatiquement redirigé vers son interface.

Vous devriez voir :

- **À gauche** : Un explorateur avec deux sections
  - 📁 **Files** : Vide pour l'instant
  - 📊 **Tables** : Vide pour l'instant

- **Au centre** : La zone principale (vide actuellement)

- **En haut** : Des options pour créer des notebooks, charger des données, etc.

> 💡 **Note** : Pour l'instant, le Lakehouse est vide. Nous le remplirons à l'étape suivante avec des données.

### 1.4 - Retourner au Workspace

1. **Cliquez sur le nom de votre Workspace** dans le fil d'Ariane en haut
   - `WindPowerAnalytics > LH_Wind_Power_Bronze`
   - Cliquez sur `WindPowerAnalytics`

2. **Vous devriez maintenant voir** votre premier Lakehouse dans la liste des items du Workspace

**📸 Capture d'écran à prendre :** `01_lakehouse_bronze_created.png`

---

## 🥈 Tâche 2 : Créer le Lakehouse Silver

Le Lakehouse Silver stockera les données après nettoyage et enrichissement.

### 2.1 - Créer le second Lakehouse

Répétez les mêmes étapes que pour Bronze :

1. **Cliquez sur "+ New item"**

2. **Sélectionnez "Lakehouse"**

3. **Nom** : `LH_Wind_Power_Silver`

4. **Cliquez sur "Create"**

### 2.2 - Vérification

- Le Lakehouse Silver est créé avec la même structure (Files et Tables vides)
- Retournez au Workspace
- Vous devriez maintenant voir **2 Lakehouses** dans votre Workspace

**📸 Capture d'écran à prendre :** `01_workspace_with_two_lakehouses.png`

---

## 🥇 Tâche 3 : Créer le Lakehouse Gold

Le Lakehouse Gold contiendra le modèle dimensionnel final, optimisé pour Power BI.

### 3.1 - Créer le troisième Lakehouse

Dernière fois ! Même procédure :

1. **Cliquez sur "+ New item"**

2. **Sélectionnez "Lakehouse"**

3. **Nom** : `LH_Wind_Power_Gold`

4. **Cliquez sur "Create"**

### 3.2 - Vérification finale

Retournez au Workspace. Vous devriez maintenant voir **3 Lakehouses** :

```
WindPowerAnalytics
├── 🗄️ LH_Wind_Power_Bronze
├── 🗄️ LH_Wind_Power_Silver
└── 🗄️ LH_Wind_Power_Gold
```

**📸 Capture d'écran à prendre :** `01_workspace_with_three_lakehouses.png`

> 🎉 **Félicitations !** Vous avez créé l'infrastructure de base de votre architecture Medallion !

---

## 📊 Tâche 4 : Comprendre l'organisation

### 4.1 - Vue d'ensemble du Workspace

Prenez un moment pour observer votre Workspace :

- Les 3 Lakehouses sont listés avec leur icône distinctive
- Chaque Lakehouse affiche sa date de création
- Vous pouvez cliquer sur chacun pour l'explorer

### 4.2 - Conventions de nommage

Notez les bonnes pratiques de nommage utilisées :

| Type de ressource | Préfixe | Exemple |
|-------------------|---------|---------|
| Lakehouse | LH_ | LH_Wind_Power_Bronze |
| Notebook | NB_ | NB_Get_Daily_Data (à venir) |
| Pipeline | PL_ | PL_Orchestration (à venir) |
| Semantic Model | SM_ | SM_Wind_Turbine_Power (à venir) |
| Report | RPT_ | RPT_Wind_Turbine_Power_Analysis (à venir) |

> 💡 **Conseil** : Respecter ces conventions tout au long du projet facilitera grandement la navigation et la maintenance.

### 4.3 - Flux de données anticipé

Visualisez mentalement comment les données vont circuler :

```
Source (GitHub CSV)
        ↓
[Ingestion]
        ↓
LH_Wind_Power_Bronze (données brutes)
        ↓
[Transformation & Enrichissement]
        ↓
LH_Wind_Power_Silver (données nettoyées)
        ↓
[Modélisation dimensionnelle]
        ↓
LH_Wind_Power_Gold (star schema)
        ↓
Semantic Model
        ↓
Power BI Reports
```

---

## ✅ Vérification de l'étape

Avant de passer à l'étape suivante, vérifiez que vous avez bien :

- [ ] ✅ Créé le Lakehouse `LH_Wind_Power_Bronze`
- [ ] ✅ Créé le Lakehouse `LH_Wind_Power_Silver`
- [ ] ✅ Créé le Lakehouse `LH_Wind_Power_Gold`
- [ ] ✅ Les 3 Lakehouses sont visibles dans votre Workspace `WindPowerAnalytics`
- [ ] ✅ Vous comprenez la structure Files/Tables d'un Lakehouse
- [ ] ✅ Vous comprenez le concept de l'architecture Medallion
- [ ] ✅ 3 captures d'écran prises :
  - Lakehouse Bronze créé
  - Workspace avec 2 Lakehouses
  - Workspace avec 3 Lakehouses

---

## 📸 Captures d'écran de cette étape

**À sauvegarder sur votre ordinateur :**

1. `01_lakehouse_bronze_created.png` - Vue du Lakehouse Bronze vide
2. `01_workspace_with_two_lakehouses.png` - Workspace avec Bronze et Silver
3. `01_workspace_with_three_lakehouses.png` - Workspace avec les 3 Lakehouses

---

## 🎓 Ce que vous avez appris

Dans cette étape, vous avez :

- ✅ Compris le concept de Lakehouse et ses avantages
- ✅ Découvert l'architecture Medallion (Bronze/Silver/Gold)
- ✅ Créé 3 Lakehouses pour implémenter cette architecture
- ✅ Appris les conventions de nommage pour organiser vos ressources
- ✅ Visualisé le flux de données de votre future pipeline

---

## ⚠️ Problèmes courants et solutions

### Problème 1 : "Je ne vois pas l'option Lakehouse"

**Cause possible :** Vous êtes dans la mauvaise expérience Fabric.

**Solution :**
1. Vérifiez que vous êtes dans l'expérience "Data Engineering"
2. En bas à gauche, cliquez sur l'icône de changement d'expérience
3. Sélectionnez "Data Engineering" ou "Data Warehouse"

### Problème 2 : "Erreur lors de la création du Lakehouse"

**Cause possible :** Nom invalide ou conflit de noms.

**Solutions :**
- Vérifiez que le nom ne contient pas de caractères spéciaux
- Assurez-vous que le nom est unique dans votre Workspace
- Rafraîchissez la page et réessayez

### Problème 3 : "Le Lakehouse met du temps à se créer"

**C'est normal !**
- La création d'un Lakehouse peut prendre 10-30 secondes
- Soyez patient et attendez la fin du processus
- Ne fermez pas la fenêtre pendant la création

---

## 💡 Informations complémentaires

### Différence entre Lakehouse et Warehouse

Si vous vous demandez pourquoi nous utilisons des Lakehouses et pas des Warehouses :

| Aspect | Lakehouse | Warehouse |
|--------|-----------|-----------|
| Stockage | Fichiers + Tables Delta | Tables uniquement |
| Flexibilité | Très haute (tout type de fichier) | Structuré (tables SQL) |
| Cas d'usage | Data engineering, ML, BI | BI et analytics SQL |
| Format | Delta Lake (open source) | Propriétaire optimisé |

Pour ce projet, le Lakehouse est idéal car nous avons besoin de :
- Stocker des fichiers CSV bruts
- Transformer les données avec PySpark
- Créer des tables optimisées pour BI

### À propos du format Delta Lake

Delta Lake est un format de stockage open-source qui apporte :
- ✅ Transactions ACID (Atomicité, Cohérence, Isolation, Durabilité)
- ✅ Time travel (possibilité de lire l'état des données à un moment donné)
- ✅ Schema evolution (évolution du schéma des données)
- ✅ Upserts et deletes efficaces
- ✅ Lecture optimisée pour l'analytique

---

## 🎯 Prochaine étape

Excellent ! Vos Lakehouses sont prêts à recevoir des données.

➡️ **Passez à l'étape suivante :** [Étape 2 : Ingestion des données (Bronze)](03_Etape_2_Ingestion_Bronze.md)

Dans la prochaine étape, vous allez :
- Créer votre premier Notebook
- Écrire du code Python pour télécharger des données depuis GitHub
- Charger ces données dans le Lakehouse Bronze
- Comprendre la logique d'ingestion incrémentale

---

*Étape 1 complétée ✅*  
*Temps estimé passé : 20-30 minutes*  
*Total cumulé : 50-75 minutes*
