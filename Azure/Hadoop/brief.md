# 🐘 Brief Pratique Hadoop - Pipeline Big Data E-commerce

**Durée estimée :** 8-10 heures
**Niveau :** Intermédiaire
**Modalité :** Pratique individuelle ou binôme
**Prérequis :** Avoir suivi la formation Hadoop (Parties 1-6)

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :

- Mettre en place un environnement Hadoop complet
- Ingérer et stocker des données dans HDFS
- Effectuer des traitements avec MapReduce
- Analyser des données avec Hive
- Créer un pipeline Big Data de bout en bout

---

## 📋 Contexte

Vous êtes Data Engineer chez **DataMart**, une plateforme e-commerce en pleine croissance. L'entreprise génère des millions de transactions par jour et souhaite analyser ses données pour :

- Comprendre le comportement d'achat des clients
- Identifier les produits les plus vendus
- Analyser les tendances de ventes par catégorie et par région
- Détecter les périodes de forte activité

Votre mission : Créer un **pipeline Big Data** complet avec Hadoop pour ingérer, traiter et analyser ces données.

---

## 📊 Données Fournies

Vous disposerez de 3 datasets :

### 1. **transactions.csv**
Format : `transaction_id,user_id,product_id,quantity,amount,timestamp,region`

Exemple :
```
TXN001,U1001,P5001,2,49.99,2025-01-15 10:23:45,EU
TXN002,U1002,P5002,1,129.99,2025-01-15 11:34:12,NA
TXN003,U1001,P5003,3,24.99,2025-01-15 12:45:33,EU
```

### 2. **products.csv**
Format : `product_id,product_name,category,price,stock`

Exemple :
```
P5001,Wireless Mouse,Electronics,24.99,150
P5002,Gaming Keyboard,Electronics,129.99,80
P5003,USB Cable,Accessories,7.99,500
```

### 3. **users.csv**
Format : `user_id,username,email,registration_date,country`

Exemple :
```
U1001,alice_smith,alice@email.com,2024-03-12,France
U1002,bob_jones,bob@email.com,2024-05-20,USA
U1003,charlie_brown,charlie@email.com,2024-07-08,Germany
```

---

## 🚀 Partie 1 : Préparation de l'Environnement (1h30)

### Tâche 1.1 : Installation et Configuration de Hadoop

**Objectif :** Mettre en place un cluster Hadoop fonctionnel en mode pseudo-distribué.

**Étapes à réaliser :**

1. Installer Java (OpenJDK 8 ou 11)
2. Télécharger et installer Hadoop 3.3.6
3. Configurer les fichiers suivants :
   - `hadoop-env.sh`
   - `core-site.xml`
   - `hdfs-site.xml`
   - `mapred-site.xml`
   - `yarn-site.xml`
4. Formater le NameNode
5. Démarrer les services HDFS et YARN

**Critères de validation :**
- ✅ La commande `jps` affiche : NameNode, DataNode, SecondaryNameNode, ResourceManager, NodeManager
- ✅ L'interface web du NameNode est accessible sur http://localhost:9870
- ✅ L'interface web YARN est accessible sur http://localhost:8088
- ✅ La commande `hdfs dfsadmin -report` affiche le statut du cluster

### Tâche 1.2 : Génération des Données de Test

**Objectif :** Créer des jeux de données réalistes pour tester le pipeline.

**À faire :**

1. Créer un script Python ou Shell pour générer :
   - 10 000 transactions
   - 100 produits
   - 500 utilisateurs
2. Les données doivent respecter les formats indiqués ci-dessus
3. Générer des données cohérentes (les IDs doivent correspondre entre les fichiers)

**Indications :**
- Utilisez des librairies comme `faker` (Python) pour générer des données réalistes
- Répartissez les transactions sur 30 jours
- Variez les régions : EU, NA, AS, SA
- Créez au moins 5 catégories de produits différentes

**Critères de validation :**
- ✅ 3 fichiers CSV créés : `transactions.csv`, `products.csv`, `users.csv`
- ✅ Les données sont cohérentes (pas de product_id ou user_id inexistant dans transactions)
- ✅ Les timestamps sont répartis sur une période d'un mois
- ✅ Les fichiers ont au moins les quantités mentionnées

---

## 📂 Partie 2 : Ingestion des Données dans HDFS (1h)

### Tâche 2.1 : Création de l'Architecture de Répertoires

**Objectif :** Organiser les données dans HDFS de manière structurée.

**À faire :**

Créer l'arborescence suivante dans HDFS :

```
/user/datamart/
├── raw/
│   ├── transactions/
│   ├── products/
│   └── users/
├── processed/
│   └── (sera utilisé plus tard)
└── analytics/
    └── (sera utilisé plus tard)
```

**Commandes à utiliser :** `hdfs dfs -mkdir`

**Critères de validation :**
- ✅ L'arborescence est créée correctement
- ✅ La commande `hdfs dfs -ls -R /user/datamart/` affiche tous les répertoires

### Tâche 2.2 : Chargement des Données dans HDFS

**Objectif :** Copier les fichiers CSV depuis le système local vers HDFS.

**À faire :**

1. Copier `transactions.csv` dans `/user/datamart/raw/transactions/`
2. Copier `products.csv` dans `/user/datamart/raw/products/`
3. Copier `users.csv` dans `/user/datamart/raw/users/`

**Commandes à utiliser :** `hdfs dfs -put`

**Critères de validation :**
- ✅ Les 3 fichiers sont présents dans HDFS
- ✅ La commande `hdfs dfs -ls /user/datamart/raw/transactions/` affiche le fichier
- ✅ La commande `hdfs dfs -cat /user/datamart/raw/transactions/transactions.csv | head -5` affiche les 5 premières lignes

### Tâche 2.3 : Vérification et Statistiques

**Objectif :** S'assurer que les données sont bien chargées.

**À faire :**

1. Afficher le nombre de lignes de chaque fichier
2. Vérifier la taille totale des données dans HDFS
3. Afficher le facteur de réplication

**Commandes utiles :**
```bash
hdfs dfs -cat <fichier> | wc -l
hdfs dfs -du -h <répertoire>
hdfs dfs -stat %r <fichier>
```

**Critères de validation :**
- ✅ Le nombre de lignes correspond aux données générées
- ✅ La taille des fichiers est cohérente
- ✅ Le facteur de réplication est 1 (mode pseudo-distribué)

---

## ⚙️ Partie 3 : Traitement MapReduce (2h30)

### Tâche 3.1 : Job MapReduce - Chiffre d'Affaires par Région

**Objectif :** Calculer le chiffre d'affaires total par région.

**À réaliser :**

Écrire un job MapReduce en Java qui :
- Lit le fichier `transactions.csv`
- Calcule le chiffre d'affaires total (somme des montants) par région
- Stocke le résultat dans `/user/datamart/processed/revenue_by_region/`

**Structure du Mapper :**
- Input : `transaction_id,user_id,product_id,quantity,amount,timestamp,region`
- Output : `<region, amount>`

**Structure du Reducer :**
- Input : `<region, [amount1, amount2, ...]>`
- Output : `<region, total_revenue>`

**Indications :**
- Utilisez `LongWritable` pour les clés d'entrée
- Utilisez `Text` pour les régions
- Utilisez `DoubleWritable` pour les montants
- N'oubliez pas le Combiner pour optimiser

**Critères de validation :**
- ✅ Le code Java compile sans erreur
- ✅ Le JAR est créé avec succès
- ✅ Le job s'exécute sans erreur via `hadoop jar`
- ✅ Le résultat est stocké dans le répertoire HDFS spécifié
- ✅ Les revenus par région sont corrects

### Tâche 3.2 : Job MapReduce - Top 10 Produits les Plus Vendus

**Objectif :** Identifier les 10 produits ayant généré le plus de ventes (en quantité).

**À réaliser :**

Écrire un job MapReduce qui :
- Lit `transactions.csv`
- Calcule la quantité totale vendue par `product_id`
- Trie les résultats et garde uniquement le top 10
- Stocke dans `/user/datamart/processed/top_products/`

**Indications :**
- Utilisez un second job MapReduce pour trier (ou utilisez un seul reducer)
- Pour le top N, vous pouvez utiliser un TreeMap dans le Reducer

**Critères de validation :**
- ✅ Le job s'exécute avec succès
- ✅ Le résultat contient exactement 10 produits
- ✅ Les produits sont triés par quantité décroissante
- ✅ Les quantités sont correctes

### Tâche 3.3 : Job MapReduce - Analyse Temporelle

**Objectif :** Analyser le nombre de transactions par jour.

**À réaliser :**

Créer un job MapReduce qui :
- Lit `transactions.csv`
- Extrait la date du timestamp (format : YYYY-MM-DD)
- Compte le nombre de transactions par jour
- Stocke dans `/user/datamart/processed/daily_transactions/`

**Indications :**
- Utilisez `SimpleDateFormat` pour parser les timestamps
- Map output : `<date, 1>`
- Reduce output : `<date, count>`

**Critères de validation :**
- ✅ Le job fonctionne correctement
- ✅ Les dates sont au bon format
- ✅ Le comptage est exact
- ✅ Les résultats sont triés par date

---

## 🐝 Partie 4 : Analyse avec Apache Hive (2h)

### Tâche 4.1 : Installation et Configuration de Hive

**Objectif :** Installer Apache Hive sur votre environnement Hadoop.

**À faire :**

1. Télécharger Apache Hive 3.1.3
2. Configurer les variables d'environnement
3. Configurer `hive-site.xml` avec un metastore Derby
4. Initialiser le schéma du metastore
5. Démarrer Hive CLI ou Beeline

**Commandes clés :**
```bash
schematool -dbType derby -initSchema
hive
```

**Critères de validation :**
- ✅ Hive est installé et configuré
- ✅ `hive --version` affiche la version
- ✅ Le shell Hive démarre sans erreur

### Tâche 4.2 : Création des Tables Hive

**Objectif :** Créer des tables Hive externes pointant vers les données HDFS.

**À faire :**

Créer 3 tables externes :

1. **transactions** : pointant vers `/user/datamart/raw/transactions/`
2. **products** : pointant vers `/user/datamart/raw/products/`
3. **users** : pointant vers `/user/datamart/raw/users/`

**Indications :**
- Utilisez `CREATE EXTERNAL TABLE`
- Spécifiez `ROW FORMAT DELIMITED FIELDS TERMINATED BY ','`
- Ignorez les en-têtes avec `tblproperties ("skip.header.line.count"="1")`

**Exemple de structure pour transactions :**
```sql
CREATE EXTERNAL TABLE transactions (
    transaction_id STRING,
    user_id STRING,
    product_id STRING,
    quantity INT,
    amount DOUBLE,
    transaction_timestamp STRING,
    region STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/datamart/raw/transactions/'
TBLPROPERTIES ("skip.header.line.count"="1");
```

**Critères de validation :**
- ✅ Les 3 tables sont créées
- ✅ `SHOW TABLES;` affiche les 3 tables
- ✅ `SELECT * FROM transactions LIMIT 5;` retourne des données
- ✅ `SELECT COUNT(*) FROM transactions;` retourne le bon nombre

### Tâche 4.3 : Requêtes Analytiques avec HiveQL

**Objectif :** Effectuer des analyses business avec SQL.

**Requêtes à écrire :**

#### Requête 1 : Chiffre d'Affaires Total
Calculer le chiffre d'affaires total de l'entreprise.

```sql
-- Votre requête ici
```

#### Requête 2 : Chiffre d'Affaires par Catégorie
Calculer le CA par catégorie de produit (nécessite une jointure).

```sql
-- Votre requête ici
```

#### Requête 3 : Top 5 Clients (par montant dépensé)
Identifier les 5 clients ayant dépensé le plus.

```sql
-- Votre requête ici
```

#### Requête 4 : Panier Moyen par Région
Calculer le montant moyen des transactions par région.

```sql
-- Votre requête ici
```

#### Requête 5 : Analyse Temporelle
Compter le nombre de transactions par jour et trier par date.

```sql
-- Votre requête ici
-- Indice : utilisez substr() ou to_date() pour extraire la date
```

#### Requête 6 : Produits Jamais Vendus
Lister les produits qui n'ont jamais été vendus (LEFT JOIN).

```sql
-- Votre requête ici
```

**Critères de validation :**
- ✅ Toutes les requêtes s'exécutent sans erreur
- ✅ Les résultats sont cohérents avec les données
- ✅ Les jointures produisent les bons résultats
- ✅ Les agrégations sont correctes

### Tâche 4.4 : Optimisation avec Partitionnement

**Objectif :** Améliorer les performances en partitionnant les données.

**À faire :**

1. Créer une table `transactions_partitioned` partitionnée par `region`
2. Utiliser le format de stockage **Parquet** (plus performant que CSV)
3. Charger les données depuis la table `transactions` vers `transactions_partitioned`

**Structure attendue :**
```sql
CREATE TABLE transactions_partitioned (
    transaction_id STRING,
    user_id STRING,
    product_id STRING,
    quantity INT,
    amount DOUBLE,
    transaction_timestamp STRING
)
PARTITIONED BY (region STRING)
STORED AS PARQUET;
```

**Chargement des données :**
```sql
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT INTO TABLE transactions_partitioned PARTITION(region)
SELECT transaction_id, user_id, product_id, quantity, amount, transaction_timestamp, region
FROM transactions;
```

**Requête à tester :**
Comparer les performances d'une requête sur la table normale vs partitionnée.

```sql
-- Table normale
SELECT SUM(amount) FROM transactions WHERE region = 'EU';

-- Table partitionnée
SELECT SUM(amount) FROM transactions_partitioned WHERE region = 'EU';
```

**Critères de validation :**
- ✅ La table partitionnée est créée
- ✅ Les données sont chargées dans les partitions
- ✅ `SHOW PARTITIONS transactions_partitioned;` affiche les partitions
- ✅ La requête sur la table partitionnée est plus rapide (visible dans les logs Hive)

---

## 🔄 Partie 5 : Pipeline Complet avec Sqoop (Bonus - 1h)

**Objectif :** Importer des données depuis une base MySQL vers Hadoop.

### Tâche 5.1 : Configuration de MySQL

**À faire :**

1. Installer MySQL ou MariaDB
2. Créer une base de données `ecommerce_source`
3. Créer une table `customers` avec des données fictives :
   ```sql
   CREATE TABLE customers (
       customer_id INT PRIMARY KEY,
       first_name VARCHAR(50),
       last_name VARCHAR(50),
       email VARCHAR(100),
       city VARCHAR(50),
       country VARCHAR(50)
   );
   ```
4. Insérer 100 enregistrements de test

### Tâche 5.2 : Import avec Sqoop

**À faire :**

Utiliser Sqoop pour importer la table `customers` vers HDFS :
- Destination : `/user/datamart/raw/customers/`
- Format de sortie : Parquet
- Import incrémental si possible

**Commande de base :**
```bash
sqoop import \
  --connect jdbc:mysql://localhost/ecommerce_source \
  --username <user> \
  --password <password> \
  --table customers \
  --target-dir /user/datamart/raw/customers \
  --as-parquetfile \
  -m 1
```

**Critères de validation :**
- ✅ Les données sont importées dans HDFS
- ✅ Le format est bien Parquet
- ✅ Toutes les lignes sont présentes

### Tâche 5.3 : Création d'une Table Hive sur les Données Importées

Créer une table externe Hive pointant vers les données Parquet importées.

**Critères de validation :**
- ✅ La table Hive fonctionne
- ✅ Les requêtes SELECT retournent les bonnes données

---

## 📤 Livrables

À la fin du brief, vous devez fournir :

### 1. **Code Source**
- Tous les jobs MapReduce (fichiers .java)
- Scripts de génération de données
- Fichiers SQL Hive (toutes vos requêtes)

### 2. **Fichiers de Configuration**
- `core-site.xml`
- `hdfs-site.xml`
- `mapred-site.xml`
- `yarn-site.xml`
- `hive-site.xml`

### 3. **Documentation**
Un fichier README.md contenant :
- Instructions de déploiement du pipeline
- Architecture du pipeline (schéma)
- Description de chaque job MapReduce
- Résultats des analyses Hive
- Problèmes rencontrés et solutions
- Pistes d'amélioration

### 4. **Captures d'Écran**
- Interface web NameNode (montrant HDFS)
- Interface web YARN (montrant les jobs exécutés)
- Résultats de vos requêtes Hive
- Arborescence HDFS complète

---

## ✅ Critères d'Évaluation

| Critère | Points | Description |
|---------|--------|-------------|
| **Installation Hadoop** | 10 | Cluster fonctionnel avec HDFS et YARN |
| **Ingestion HDFS** | 10 | Données correctement organisées dans HDFS |
| **Jobs MapReduce** | 30 | 3 jobs fonctionnels et optimisés |
| **Analyse Hive** | 25 | Toutes les requêtes SQL fonctionnent |
| **Optimisation** | 10 | Partitionnement et format Parquet |
| **Documentation** | 10 | README clair et complet |
| **Bonus Sqoop** | 5 | Import MySQL → HDFS fonctionnel |
| **Total** | **100** | |

---

## 💡 Conseils

### Débogage
- Consultez TOUJOURS les logs en cas d'erreur :
  - Logs Hadoop : `$HADOOP_HOME/logs/`
  - Logs YARN : Interface web port 8088
  - Logs Hive : `/tmp/<user>/hive.log`

### Performance
- Utilisez des Combiners dans MapReduce pour réduire le shuffle
- Préférez le format Parquet à CSV pour les grandes données
- Partitionnez vos tables Hive sur les colonnes fréquemment filtrées

### Organisation
- Créez un repository Git pour versionner votre code
- Testez chaque étape avant de passer à la suivante
- Documentez au fur et à mesure

### Ressources
- Documentation officielle Hadoop : https://hadoop.apache.org/docs/
- Documentation Hive : https://cwiki.apache.org/confluence/display/Hive/
- Stack Overflow pour les erreurs courantes

---

## 🎓 Compétences Développées

À l'issue de ce brief, vous aurez pratiqué :

✅ Installation et configuration d'un cluster Hadoop
✅ Manipulation de HDFS (commandes CLI)
✅ Développement de jobs MapReduce en Java
✅ Analyse de données avec Hive (HiveQL)
✅ Optimisation de requêtes Big Data (partitionnement, formats de fichiers)
✅ Intégration de données avec Sqoop
✅ Documentation technique

---

## 📞 Support

En cas de blocage :
1. Consultez la documentation du cours (Parties 1-6)
2. Vérifiez les logs d'erreur
3. Recherchez l'erreur sur Stack Overflow
4. Contactez le formateur si le problème persiste

---

**Bon courage et bon développement ! 🚀**

---

*Brief créé pour la formation Data Engineering - Simplon - 2025*
