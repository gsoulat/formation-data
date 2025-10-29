# Chapitre 1 : Configuration de l'environnement

## 🎯 Objectifs
- Configurer Snowflake pour DBT Cloud
- Charger les données Airbnb
- Préparer l'environnement de développement

## ❄️ Configuration de Snowflake

Avant de commencer avec DBT Cloud, nous devons préparer notre environnement Snowflake. Cette configuration créera un utilisateur dédié, des rôles appropriés et la base de données pour notre projet.

### 1. Création de l'utilisateur et des permissions

Connectez-vous à Snowflake et exécutez le script suivant :

```sql
-- Utiliser le rôle admin
USE ROLE ACCOUNTADMIN;

-- Créer le rôle `transform`
CREATE ROLE IF NOT EXISTS transform;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Créer la warehouse par défaut
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Créer l'utilisateur DBT et lui assigner le rôle
CREATE USER IF NOT EXISTS dbt
  PASSWORD='MotDePasseDBT123@'
  LOGIN_NAME='dbt'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE='transform'
  DEFAULT_NAMESPACE='AIRBNB.RAW'
  COMMENT='Utilisateur DBT pour la transformation des données';

GRANT ROLE transform to USER dbt;

-- Création de la BDD et du schéma
CREATE DATABASE IF NOT EXISTS AIRBNB;
CREATE SCHEMA IF NOT EXISTS AIRBNB.RAW;

-- Mise en place des permissions pour le rôle `transform`
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE transform;
GRANT ALL ON DATABASE AIRBNB to ROLE transform;
GRANT ALL ON ALL SCHEMAS IN DATABASE AIRBNB to ROLE transform;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE AIRBNB to ROLE transform;
GRANT ALL ON ALL TABLES IN SCHEMA AIRBNB.RAW to ROLE transform;
GRANT ALL ON FUTURE TABLES IN SCHEMA AIRBNB.RAW to ROLE transform;
```

> 💡 **Conseil sécurité** : En production, utilisez un mot de passe plus complexe et activez l'authentification multi-facteurs.

### 2. Vérification de la configuration

Testez la connexion avec le nouvel utilisateur :

```sql
-- Se connecter avec l'utilisateur dbt
USE ROLE transform;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE AIRBNB;
USE SCHEMA RAW;

-- Vérifier les permissions
SHOW GRANTS TO ROLE transform;
```

## 📊 Chargement des données Airbnb

Nous allons maintenant charger les données Airbnb dans Snowflake en utilisant un repository Git public.

### 1. Configuration de l'intégration Git

```sql
USE WAREHOUSE COMPUTE_WH;
USE DATABASE AIRBNB;
USE SCHEMA RAW;

-- Créer l'intégration API pour accéder à GitHub
CREATE OR REPLACE API INTEGRATION integration_jeu_de_donnees_github
API_PROVIDER = git_https_api
API_ALLOWED_PREFIXES = ('https://github.com/gsoulat')
ENABLED = true;

-- Créer le repository Git
CREATE OR REPLACE GIT REPOSITORY jeu_de_donnees_airbnb
API_INTEGRATION = integration_jeu_de_donnees_github
ORIGIN = 'https://github.com/gsoulat/dbt.git';

-- Définir le format de fichier CSV
CREATE OR REPLACE FILE FORMAT format_jeu_de_donnees
TYPE = csv
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

### 2. Création et chargement de la table HOSTS

```sql
-- Créer la table HOSTS
CREATE TABLE AIRBNB.RAW.HOSTS
(
    host_id                STRING,
    host_name              STRING,
    host_since             DATE,
    host_location          STRING,
    host_response_time     STRING,
    host_response_rate     STRING,
    host_is_superhost      STRING,
    host_neighbourhood     STRING,
    host_identity_verified STRING
);

-- Charger les données depuis Git
INSERT INTO AIRBNB.RAW.HOSTS (
    SELECT
        $1 as host_id,
        $2 as host_name,
        $3 as host_since,
        $4 as host_location,
        $5 as host_response_time,
        $6 as host_response_rate,
        $7 as host_is_superhost,
        $8 as host_neighbourhood,
        $9 as host_identity_verified
    FROM @jeu_de_donnees_airbnb/branches/main/dataset/hosts.csv
    (FILE_FORMAT => 'format_jeu_de_donnees')
);
```

### 3. Création et chargement de la table LISTINGS

```sql
-- Créer la table LISTINGS
CREATE TABLE AIRBNB.RAW.LISTINGS
(
    id                     STRING,
    listing_url            STRING,
    name                   STRING,
    description            STRING,
    neighbourhood_overview STRING,
    host_id                STRING,
    latitude               STRING,
    longitude              STRING,
    property_type          STRING,
    room_type              STRING,
    accommodates           INTEGER,
    bathrooms              FLOAT,
    bedrooms               FLOAT,
    beds                   FLOAT,
    amenities              STRING,
    price                  STRING,
    minimum_nights         INTEGER,
    maximum_nights         INTEGER
);

-- Charger les données depuis Git
INSERT INTO AIRBNB.RAW.LISTINGS (
    SELECT
        $1  AS id,
        $2  AS listing_url,
        $3  AS name,
        $4  AS description,
        $5  AS neighbourhood_overview,
        $6  AS host_id,
        $7  AS latitude,
        $8  AS longitude,
        $9  AS property_type,
        $10 AS room_type,
        $11 AS accommodates,
        $12 AS bathrooms,
        $13 AS bedrooms,
        $14 AS beds,
        $15 AS amenities,
        $16 AS price,
        $17 AS minimum_nights,
        $18 AS maximum_nights
    FROM @jeu_de_donnees_airbnb/branches/main/dataset/listings.csv
    (FILE_FORMAT => 'format_jeu_de_donnees')
);
```

### 4. Création et chargement de la table REVIEWS

```sql
-- Créer la table REVIEWS
CREATE TABLE AIRBNB.RAW.REVIEWS
(
    listing_id  STRING,
    date        DATE
);

-- Charger les données depuis Git
INSERT INTO AIRBNB.RAW.REVIEWS (
    SELECT
        $1 as listing_id,
        $2 as date
    FROM @jeu_de_donnees_airbnb/branches/main/dataset/reviews.csv
    (FILE_FORMAT => 'format_jeu_de_donnees')
);
```

## ✅ Vérification du chargement

Vérifiez que toutes les données ont été chargées correctement :

```sql
-- Compter les enregistrements dans chaque table
SELECT 'HOSTS' as table_name, COUNT(*) as row_count FROM AIRBNB.RAW.HOSTS
UNION ALL
SELECT 'LISTINGS' as table_name, COUNT(*) as row_count FROM AIRBNB.RAW.LISTINGS
UNION ALL
SELECT 'REVIEWS' as table_name, COUNT(*) as row_count FROM AIRBNB.RAW.REVIEWS;

-- Aperçu des données
SELECT * FROM AIRBNB.RAW.HOSTS LIMIT 5;
SELECT * FROM AIRBNB.RAW.LISTINGS LIMIT 5;
SELECT * FROM AIRBNB.RAW.REVIEWS LIMIT 5;
```

## 📝 Informations de connexion pour DBT Cloud

Conservez ces informations pour la configuration de DBT Cloud dans le chapitre suivant :

- **Account** : Votre nom de compte Snowflake
- **User** : `dbt`
- **Password** : `MotDePasseDBT123@`
- **Role** : `transform`
- **Database** : `AIRBNB`
- **Warehouse** : `COMPUTE_WH`
- **Schema** : `RAW`

## 🎯 Points clés à retenir

1. **Sécurité** : Nous avons créé un utilisateur dédié avec des permissions limitées
2. **Organisation** : La structure database → schema → table suit les bonnes pratiques
3. **Automation** : L'intégration Git permet de charger les données automatiquement
4. **Vérification** : Toujours vérifier que les données sont correctement chargées

---

**Étape précédente** : [Chapitre 0 - Guide des commandes DBT](chapitre-0-commandes-dbt.md)
**Prochaine étape** : [Chapitre 2 - Initialisation du projet DBT Cloud](chapitre-2-initialisation.md)