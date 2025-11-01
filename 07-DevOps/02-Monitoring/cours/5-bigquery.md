# Formation 5 : Introduction à Google BigQuery

Bienvenue dans cette formation dédiée à Google BigQuery. Nous allons explorer ce qu'est BigQuery, pourquoi il est si puissant, et comment l'utiliser pour analyser de grands volumes de données rapidement.

**Ce que nous allons apprendre :**
1.  **Qu'est-ce que BigQuery ?** Comprendre ses caractéristiques et cas d'usage.
2.  **Architecture et Concepts Clés :** Projets, datasets, tables, et jobs.
3.  **Charger des Données :** Importer des données depuis Cloud Storage et d'autres sources.
4.  **Analyser avec SQL :** Écrire des requêtes pour explorer et extraire des informations.
5.  **Bonnes Pratiques :** Optimiser les coûts et les performances.
6.  **Exercice Pratique :** Utiliser un jeu de données public pour mettre en pratique nos connaissances.

---

## 1. Qu'est-ce que Google BigQuery ?

**BigQuery** est un entrepôt de données d'entreprise (**Data Warehouse**) entièrement géré et sans serveur (**serverless**). Il est conçu pour stocker et analyser des pétaoctets de données à une vitesse fulgurante en utilisant la puissance de l'infrastructure de Google.

### Caractéristiques Principales

*   **Serverless :** Pas de serveurs à gérer, pas d'infrastructure à provisionner. Vous vous concentrez sur l'analyse, pas sur l'administration.
*   **Scalabilité Extrême :** BigQuery ajuste automatiquement les ressources de calcul nécessaires pour exécuter vos requêtes, qu'elles portent sur quelques mégaoctets ou plusieurs pétaoctets.
*   **Haute Vitesse :** Grâce à son architecture massivement parallèle (Dremel), BigQuery peut exécuter des requêtes complexes sur de grands ensembles de données en quelques secondes.
*   **Requêtes SQL Standard :** Utilise le dialecte SQL standard (ANSI:2011), ce qui le rend facile à prendre en main pour les analystes et les développeurs.
*   **Analyse en Temps Réel :** Permet d'ingérer des données en streaming et de les requêter immédiatement.
*   **Machine Learning Intégré (BigQuery ML) :** Permet de créer et d'exécuter des modèles de machine learning directement dans BigQuery avec de simples commandes SQL.

### Cas d'Usage Courants

*   **Business Intelligence :** Alimenter des tableaux de bord (comme Grafana ou Looker Studio) pour visualiser les tendances.
*   **Analyse de Logs :** Centraliser et analyser les logs d'applications, de serveurs ou de sécurité.
*   **Analyse de Données de Sites Web et Mobiles :** Comprendre le comportement des utilisateurs en analysant les données de Google Analytics.
*   **Génomique :** Analyser de grands ensembles de données génomiques.

---

## 2. Architecture et Concepts Clés

BigQuery organise les données de manière hiérarchique.

![BigQuery Hierarchy](https://cloud.google.com/bigquery/images/bigquery-explorer-resources.png)

*   **Projet (Project) :** Le conteneur de plus haut niveau. Chaque projet GCP est un conteneur pour les ressources BigQuery. Il gère la facturation, les accès et les permissions.
*   **Dataset :** Un conteneur pour les tables et les vues. C'est l'équivalent d'un schéma ou d'une base de données dans les systèmes traditionnels. Il permet de regrouper des tables logiquement et de contrôler les accès au niveau du dataset.
*   **Table :** Là où vos données sont stockées. Une table a un schéma défini avec des colonnes et des types de données.
*   **Vue (View) :** Une requête SQL enregistrée qui peut être interrogée comme une table. C'est une table virtuelle.
*   **Job :** Une action que vous demandez à BigQuery d'effectuer, comme charger des données, les exporter, les copier ou exécuter une requête.

---

## 3. Charger des Données dans BigQuery

Il existe plusieurs façons de charger des données dans BigQuery.

### Méthode 1 : Depuis Google Cloud Storage (Recommandé pour les gros volumes)

C'est la méthode la plus courante pour les chargements en masse (batch loading).

1.  **Uploadez votre fichier** (CSV, JSON, Avro, Parquet) dans un bucket Cloud Storage.
2.  **Accédez à l'interface BigQuery** dans la console GCP.
3.  **Sélectionnez votre dataset** (ou créez-en un).
4.  Cliquez sur **CRÉER UNE TABLE**.
5.  Configurez la source :
    *   **Créer une table à partir de :** Google Cloud Storage.
    *   **Sélectionnez le fichier** depuis votre bucket.
    *   **Format du fichier :** Choisissez le format correspondant (ex: CSV).
6.  Configurez la destination :
    *   **Nom de la table :** Donnez un nom à votre table.
7.  **Définissez le schéma :**
    *   **Détection automatique :** Laissez BigQuery deviner le schéma.
    *   **Manuellement :** Définissez chaque colonne et son type (ex: `STRING`, `INTEGER`, `FLOAT`, `TIMESTAMP`, `BOOLEAN`).
8.  Cliquez sur **CRÉER LA TABLE**.

### Méthode 2 : Depuis un Fichier Local

Idéal pour les petits fichiers (< 10 Mo).

1.  Dans l'interface BigQuery, sélectionnez votre dataset.
2.  Cliquez sur **CRÉER UNE TABLE**.
3.  **Créer une table à partir de :** Importer.
4.  **Sélectionnez le fichier** depuis votre ordinateur.
5.  Suivez les mêmes étapes pour la configuration de la table et du schéma.

---

## 4. Analyser avec SQL

L'analyse dans BigQuery se fait principalement via des requêtes SQL. BigQuery utilise le dialecte **SQL standard**.

### L'Éditeur de Requêtes

L'interface BigQuery fournit un éditeur de requêtes puissant avec auto-complétion, validation de la syntaxe en temps réel et une estimation du volume de données qui sera traité par la requête (ce qui est crucial pour la gestion des coûts).

### Exemple de Requêtes

Nous allons utiliser un jeu de données public pour nos exemples : `bigquery-public-data.samples.shakespeare`.

**Requête 1 : Compter le nombre total de mots dans toutes les pièces de Shakespeare.**

```sql
SELECT
  SUM(word_count) AS total_words
FROM
  `bigquery-public-data.samples.shakespeare`;
```

**Requête 2 : Trouver les 10 mots les plus utilisés par "king henry IV".**

```sql
SELECT
  word,
  SUM(word_count) AS count
FROM
  `bigquery-public-data.samples.shakespeare`
WHERE
  corpus = 'kinghenryiv'
GROUP BY
  word
ORDER BY
  count DESC
LIMIT 10;
```

**Requête 3 : Compter le nombre de pièces uniques.**

```sql
SELECT
  COUNT(DISTINCT corpus) AS unique_plays
FROM
  `bigquery-public-data.samples.shakespeare`;
```

---

## 5. Bonnes Pratiques et Optimisation des Coûts

Le modèle de tarification de BigQuery est basé sur deux axes principaux : le **stockage** et l'**analyse** (volume de données traité par les requêtes).

1.  **Ne sélectionnez que les colonnes dont vous avez besoin.**
    *   Évitez `SELECT *`. C'est la règle la plus importante. Plus vous scannez de colonnes, plus vous payez.
    *   **Mauvais :** `SELECT * FROM my_table;`
    *   **Bon :** `SELECT user_id, event_name FROM my_table;`

2.  **Utilisez `LIMIT` pour explorer les données.**
    *   Lorsque vous découvrez une table, utilisez `LIMIT` pour ne renvoyer qu'un échantillon. Attention, cela ne réduit pas le coût de la requête (qui scanne toujours toutes les données), mais réduit la quantité de données affichées.

3.  **Pré-visualisez les données gratuitement.**
    *   Utilisez l'onglet **Aperçu** sur une table pour voir des échantillons de données sans exécuter de requête payante.

4.  **Estimez les coûts avant d'exécuter.**
    *   L'éditeur de requêtes affiche une estimation des données qui seront traitées (ex: "Cette requête traitera 1,2 Go une fois exécutée."). Utilisez cette information pour éviter les mauvaises surprises.

5.  **Utilisez les tables partitionnées et clusterisées.**
    *   **Partitionnement :** Divise une table en segments (partitions) basés sur une colonne de date/heure ou un entier. Requêter une partition spécifique réduit considérablement le volume de données scanné.
    *   **Clustering :** Trie physiquement les données dans une table en fonction des valeurs d'une ou plusieurs colonnes. Cela améliore les performances des requêtes qui filtrent sur ces colonnes.

---

## 6. Exercice Pratique

Mettons en pratique ce que nous avons appris.

### Étape 1 : Créer un Dataset

1.  Dans l'explorateur BigQuery, cliquez sur les trois points à côté de votre ID de projet.
2.  Cliquez sur **Créer un ensemble de données**.
3.  **ID de l'ensemble de données :** `my_first_dataset`.
4.  **Emplacement des données :** Choisissez une région (ex: `europe-west9 (Paris)`).
5.  Cliquez sur **CRÉER L'ENSEMBLE DE DONNÉES**.

### Étape 2 : Explorer un Jeu de Données Public

Nous allons utiliser le jeu de données sur les naissances aux États-Unis.

1.  Copiez et collez la requête suivante dans l'éditeur :

    ```sql
    -- Quel est le jour de la semaine le plus populaire pour les naissances ?
    SELECT
      wday AS day_of_week,
      SUM(plurality) AS total_births
    FROM
      `bigquery-public-data.samples.natality`
    GROUP BY
      day_of_week
    ORDER BY
      total_births DESC;
    ```

2.  Observez l'estimation du coût (ex: "Cette requête traitera 1,5 Go").
3.  Exécutez la requête.

    *Note : Les jours de la semaine sont numérotés, où 1 = Dimanche et 7 = Samedi.*

### Étape 3 : Sauvegarder les Résultats dans une Nouvelle Table

1.  Au-dessus des résultats de la requête, cliquez sur **ENREGISTRER LES RÉSULTATS**.
2.  Choisissez **Table BigQuery**.
3.  **Projet :** Votre projet.
4.  **Dataset :** `my_first_dataset`.
5.  **Table :** `births_by_day_of_week`.
6.  Cliquez sur **ENREGISTRER**.

Vous venez de créer votre première table à partir des résultats d'une requête ! Vous pouvez maintenant la trouver dans votre dataset `my_first_dataset`.

Félicitations ! Vous avez terminé cette introduction à BigQuery. Vous avez maintenant les bases pour commencer à explorer et analyser vos propres données.
