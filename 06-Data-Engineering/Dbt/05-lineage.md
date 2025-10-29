# Chapitre 5 : Lignée et dépendances

## 🎯 Objectifs
- Définir les sources de données
- Créer et utiliser des seeds
- Implémenter des snapshots pour l'historisation
- Comprendre la lignée des données
- Utiliser le graphique de dépendances

## 🗂️ Définition des sources

Les sources permettent de documenter et tester les données brutes avant transformation.

### 1. Créer le fichier des sources

Créez le fichier `models/sources/sources.yml` :

```yaml
version: 2

sources:
  - name: raw_airbnb_data
    description: "Données brutes Airbnb chargées depuis le repository Git"
    database: airbnb
    schema: raw
    tables:
      - name: hosts
        description: "Informations sur les hôtes Airbnb"
        columns:
          - name: host_id
            description: "Identifiant unique de l'hôte"
            tests:
              - unique
              - not_null
          - name: host_name
            description: "Nom d'affichage de l'hôte"
          - name: host_since
            description: "Date d'inscription de l'hôte sur Airbnb"
          - name: host_location
            description: "Localisation de l'hôte (ville, pays)"
          - name: host_response_time
            description: "Temps de réponse moyen de l'hôte"
          - name: host_response_rate
            description: "Taux de réponse de l'hôte (en %)"
          - name: host_is_superhost
            description: "Indicateur superhost (t/f)"
          - name: host_neighbourhood
            description: "Quartier de l'hôte"
          - name: host_identity_verified
            description: "Identité vérifiée (t/f)"

      - name: listings
        description: "Informations sur les logements Airbnb"
        columns:
          - name: id
            description: "Identifiant unique du listing"
            tests:
              - unique
              - not_null
          - name: listing_url
            description: "URL du listing sur Airbnb"
          - name: name
            description: "Nom du listing"
          - name: description
            description: "Description du listing"
          - name: host_id
            description: "Identifiant de l'hôte propriétaire"
            tests:
              - not_null
              - relationships:
                  to: source('raw_airbnb_data', 'hosts')
                  field: host_id
          - name: property_type
            description: "Type de propriété"
          - name: room_type
            description: "Type de chambre/espace"
          - name: accommodates
            description: "Nombre de personnes accueillies"
          - name: price
            description: "Prix par nuit (avec devise)"
          - name: minimum_nights
            description: "Nombre minimum de nuits"

      - name: reviews
        description: "Dates des commentaires par listing"
        columns:
          - name: listing_id
            description: "Identifiant du listing commenté"
            tests:
              - not_null
              - relationships:
                  to: source('raw_airbnb_data', 'listings')
                  field: id
          - name: date
            description: "Date du commentaire"
            tests:
              - not_null

```

### 2. Mettre à jour les modèles pour utiliser les sources

Modifiez vos modèles existants pour utiliser la fonction `source()` :

#### Dans `curation_hosts.sql` :
```sql
FROM {{ source('raw_airbnb_data', 'hosts') }}
```

#### Dans `curation_listings.sql` :
```sql
FROM {{ source('raw_airbnb_data', 'listings') }}
```

### 3. Tester les sources

```bash
# Tester toutes les sources
dbt test --select source:*

# Tester une source spécifique
dbt test --select source:raw_airbnb_data.hosts
```

## 🌱 Création et utilisation des seeds

Les seeds permettent d'importer des fichiers CSV statiques dans votre projet.

### 1. Créer le fichier seed

Créez le fichier `seeds/tourists_per_year.csv` :

```csv
year,tourists
2015,17600000
2016,18600000
2017,19200000
2018,19800000
2019,20400000
2020,9200000
2021,9800000
2022,15600000
2023,18200000
2024,19100000
```

### 2. Configurer le seed

Dans `dbt_project.yml`, ajoutez :

```yaml
seeds:
  analyse_airbnb:
    tourists_per_year:
      +enabled: true
      +database: airbnb
      +schema: raw
      +column_types:
        year: integer
        tourists: integer
```

### 3. Charger le seed

```bash
# Charger tous les seeds
dbt seed

# Charger un seed spécifique
dbt seed --select tourists_per_year

# Recharger en forçant l'écrasement
dbt seed --full-refresh
```

### 4. Créer un modèle utilisant le seed

Créez `models/curation/curation_tourists.sql` :

```sql
{{
    config(
        materialized='table',
        schema='curation'
    )
}}

-- Transformation des données de tourisme à Amsterdam
WITH tourists_raw AS (
    SELECT
        year,
        tourists
    FROM {{ ref('tourists_per_year') }}
),

tourists_formatted AS (
    SELECT
        -- Conversion en date de fin d'année
        DATE(year || '-12-31') AS year_end_date,
        year,
        tourists,

        -- Calcul des variations annuelles
        LAG(tourists) OVER (ORDER BY year) AS tourists_previous_year,
        tourists - LAG(tourists) OVER (ORDER BY year) AS tourists_change,

        -- Pourcentage de variation
        ROUND(
            (tourists - LAG(tourists) OVER (ORDER BY year)) * 100.0
            / LAG(tourists) OVER (ORDER BY year), 2
        ) AS tourists_change_pct,

        -- Catégorisation
        CASE
            WHEN year <= 2019 THEN 'Pre-COVID'
            WHEN year IN (2020, 2021) THEN 'COVID'
            ELSE 'Post-COVID'
        END AS period_category

    FROM tourists_raw
)

SELECT * FROM tourists_formatted
ORDER BY year
```

## 📸 Snapshots : Historisation des données

Les snapshots permettent de capturer l'évolution des données dans le temps.

### 1. Créer un snapshot des hôtes

Créez le fichier `snapshots/hosts_snapshot.sql` :

```sql
{% snapshot hosts_snapshot %}

    {{
        config(
          target_database='airbnb',
          target_schema='snapshots',
          strategy='check',
          check_cols='all',
          unique_key='host_id'
        )
    }}

    SELECT * FROM {{ source('raw_airbnb_data', 'hosts') }}

{% endsnapshot %}
```

### 2. Exécuter le snapshot

```bash
# Première exécution : capture l'état initial
dbt snapshot

# Vérifier le résultat
dbt run-operation list_snapshots
```

### 3. Simuler un changement de données

Dans Snowflake, modifiez quelques enregistrements :

```sql
-- Modifier les données d'un hôte pour tester le snapshot
UPDATE AIRBNB.RAW.HOSTS
SET
    host_response_time = 'within an hour',
    host_response_rate = '100%'
WHERE host_id = '1376607';

-- Modifier un autre hôte
UPDATE AIRBNB.RAW.HOSTS
SET
    host_is_superhost = 't',
    host_response_rate = '95%'
WHERE host_id = '25613';
```

### 4. Capturer les changements

```bash
# Exécuter le snapshot à nouveau
dbt snapshot
```

### 5. Analyser l'historique

```sql
-- Voir l'évolution d'un hôte spécifique
SELECT
    host_id,
    host_name,
    host_response_time,
    host_response_rate,
    host_is_superhost,
    dbt_valid_from,
    dbt_valid_to,
    dbt_updated_at
FROM AIRBNB.SNAPSHOTS.HOSTS_SNAPSHOT
WHERE host_id = '1376607'
ORDER BY dbt_valid_from;

-- Voir tous les changements récents
SELECT
    host_id,
    host_name,
    dbt_valid_from,
    dbt_valid_to,
    dbt_updated_at
FROM AIRBNB.SNAPSHOTS.HOSTS_SNAPSHOT
WHERE dbt_updated_at > CURRENT_DATE - 1
ORDER BY dbt_updated_at DESC;
```

### 6. Créer un modèle utilisant les snapshots

Créez `models/curation/curation_hosts_with_history.sql` :

```sql
{{
    config(
        materialized='view',
        schema='curation'
    )
}}

-- Modèle des hôtes avec gestion de l'historique
WITH hosts_current AS (
    SELECT
        host_id,
        CASE WHEN LEN(host_name) = 1 THEN 'Anonyme' ELSE host_name END AS host_name,
        host_since,
        host_location,
        SPLIT_PART(host_location, ',', 1) AS host_city,
        SPLIT_PART(host_location, ',', 2) AS host_country,
        TRY_CAST(REPLACE(host_response_rate, '%', '') AS INTEGER) AS response_rate,
        host_is_superhost = 't' AS is_superhost,
        host_neighbourhood,
        host_identity_verified = 't' AS is_identity_verified,
        dbt_valid_from,
        dbt_valid_to,
        dbt_updated_at
    FROM {{ ref('hosts_snapshot') }}

    -- Filtrer pour ne garder que les enregistrements actuels
    WHERE dbt_valid_to IS NULL
      AND host_is_superhost IS NOT NULL
      AND host_neighbourhood IS NOT NULL
)

SELECT * FROM hosts_current
```

## 📊 Visualisation de la lignée

### 1. Génération de la documentation

```bash
# Générer la documentation
dbt docs generate

# Servir la documentation localement
dbt docs serve
```

### 2. Explorer le graphique de lignée

Dans l'interface DBT Docs :
1. Cliquez sur un modèle
2. Sélectionnez l'onglet "Lineage"
3. Explorez les dépendances amont et aval

### 3. Commandes de lignée utiles

```bash
# Voir la lignée d'un modèle
dbt list --select +curation_hosts+

# Exécuter un modèle et toutes ses dépendances
dbt run --select +analytics_host_performance

# Exécuter un modèle et tous ses descendants
dbt run --select curation_hosts+
```

## 📈 Modèle analytics utilisant toutes les sources

Créez `models/analytics/analytics_tourism_impact.sql` :

```sql
{{
    config(
        materialized='table',
        schema='analytics'
    )
}}

-- Analyse de l'impact du tourisme sur l'offre Airbnb
WITH tourism_data AS (
    SELECT
        year,
        tourists,
        tourists_change_pct,
        period_category
    FROM {{ ref('curation_tourists') }}
),

reviews_by_year AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        COUNT(*) AS nb_reviews,
        COUNT(DISTINCT listing_id) AS listings_reviewed
    FROM {{ source('raw_airbnb_data', 'reviews') }}
    WHERE date >= '2015-01-01'
    GROUP BY 1
),

hosts_stats AS (
    SELECT
        COUNT(*) AS total_hosts,
        COUNT(CASE WHEN is_superhost THEN 1 END) AS superhosts,
        AVG(response_rate) AS avg_response_rate
    FROM {{ ref('curation_hosts') }}
    WHERE response_rate IS NOT NULL
),

listings_stats AS (
    SELECT
        COUNT(*) AS total_listings,
        AVG(price) AS avg_price,
        COUNT(DISTINCT property_type) AS property_types,
        COUNT(DISTINCT room_type) AS room_types
    FROM {{ ref('curation_listings') }}
    WHERE price IS NOT NULL AND price > 0
),

combined_analysis AS (
    SELECT
        t.year,
        t.tourists,
        t.tourists_change_pct,
        t.period_category,
        r.nb_reviews,
        r.listings_reviewed,

        -- Ratio reviews par touriste (proxy d'activité)
        ROUND(r.nb_reviews * 1000.0 / t.tourists, 2) AS reviews_per_1000_tourists,

        -- Stats globales (répétées pour jointure)
        h.total_hosts,
        h.superhosts,
        h.avg_response_rate,
        l.total_listings,
        l.avg_price,
        l.property_types,
        l.room_types

    FROM tourism_data t
    LEFT JOIN reviews_by_year r ON t.year = r.year
    CROSS JOIN hosts_stats h
    CROSS JOIN listings_stats l
)

SELECT * FROM combined_analysis
ORDER BY year
```

## 🔍 Tests et validation

### 1. Tester toutes les sources et modèles

```bash
# Test complet du projet
dbt test

# Test par catégorie
dbt test --select source:*
dbt test --select tag:curation
```

### 2. Validation des références

```bash
# Vérifier que toutes les références sont valides
dbt compile

# Voir le graphique de dépendances
dbt list --select +analytics_tourism_impact+ --output json
```

### 3. Vérification de la fraîcheur des sources

Ajoutez dans `sources.yml` :

```yaml
sources:
  - name: raw_airbnb_data
    freshness:
      warn_after: {count: 1, period: day}
      error_after: {count: 2, period: day}
    # ... rest of config
```

Puis testez :

```bash
dbt source freshness
```

## 🎯 Commandes de sélection avancées

```bash
# Exécuter seulement les modèles modifiés
dbt run --select state:modified

# Exécuter par tag
dbt run --select tag:analytics

# Exécuter par path
dbt run --select models/curation

# Combinaisons
dbt run --select curation_hosts+ --exclude tag:slow
```

## 📋 Checklist de validation

- [ ] Sources définies et testées
- [ ] Seeds chargés et configurés
- [ ] Snapshots fonctionnels avec historique
- [ ] Modèles utilisent les bonnes références (`source()`, `ref()`)
- [ ] Documentation générée et accessible
- [ ] Lignée cohérente dans le graphique
- [ ] Tests passent sur toutes les dépendances

## 🎯 Points clés à retenir

1. **Sources** : Documentent et testent les données d'entrée
2. **Seeds** : Permettent d'importer des données statiques
3. **Snapshots** : Capturent l'évolution des données
4. **Lignée** : Traçabilité complète des transformations
5. **Références** : `source()` pour les données brutes, `ref()` pour les modèles
6. **Tests** : Validation automatique de la qualité

---

**Prochaine étape** : [Chapitre 6 - Tests de qualité](chapitre-6-tests.md)