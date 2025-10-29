# Chapitre 8 : Variables DBT

## 🎯 Objectifs
- Comprendre les variables DBT et leur utilisation
- Configurer des variables dans différents contextes
- Utiliser les variables pour la flexibilité et la réutilisabilité
- Optimiser les modèles avec des variables conditionnelles

## 📊 Introduction aux variables

Les variables DBT permettent de :
- **Paramétrer** les modèles et macros
- **Configurer** des comportements selon l'environnement
- **Réutiliser** du code avec différentes valeurs
- **Optimiser** les performances avec des filtres dynamiques

## ⚙️ Types de variables

### 1. Variables de projet (`dbt_project.yml`)

```yaml
# dbt_project.yml
vars:
  # Variables globales
  start_date: '2023-01-01'
  end_date: '2024-12-31'

  # Variables par environnement
  table_prefix: 'dev_'
  max_records: 1000

  # Variables de filtrage
  countries: ['FR', 'ES', 'IT']
  price_threshold: 100
```

### 2. Variables de ligne de commande

```bash
# Exécution avec variables
dbt run --vars '{"start_date": "2024-01-01", "country": "FR"}'

# Variables multiples
dbt run --vars '{"debug_mode": true, "limit_rows": 500}'

# Surcharger les variables du projet
dbt run --vars '{"price_threshold": 200}'
```

### 3. Variables de profil (`profiles.yml`)

```yaml
# profiles.yml
analyse_airbnb:
  target: dev
  outputs:
    dev:
      type: snowflake
      # ... autres configs
      vars:
        environment: 'development'
        debug_mode: true

    prod:
      type: snowflake
      # ... autres configs
      vars:
        environment: 'production'
        debug_mode: false
```

## 🔧 Utilisation des variables

### 1. Fonction `var()`

```sql
-- Utilisation simple
SELECT *
FROM {{ source('raw_airbnb_data', 'listings') }}
WHERE created_date >= '{{ var("start_date") }}'

-- Avec valeur par défaut
SELECT *
FROM {{ source('raw_airbnb_data', 'listings') }}
WHERE price <= {{ var("price_threshold", 150) }}

-- Variables conditionnelles
{% if var("debug_mode", false) %}
    LIMIT {{ var("max_records", 100) }}
{% endif %}
```

### 2. Variables dans les configurations

```sql
{{
    config(
        materialized='table',
        schema=var('target_schema', 'analytics'),
        tags=[var('environment', 'dev')]
    )
}}

SELECT * FROM my_data
```

## 📝 Exemples pratiques

### 1. Modèle avec filtres variables

Créons `models/analytics/analytics_listings_filtered.sql` :

```sql
{{
    config(
        materialized='view',
        schema='analytics'
    )
}}

-- Modèle de listings avec filtres variables
WITH filtered_listings AS (
    SELECT
        listing_id,
        name,
        host_id,
        latitude,
        longitude,
        property_type,
        room_type,
        accommodates,
        bathrooms,
        bedrooms,
        price,
        minimum_nights,
        maximum_nights
    FROM {{ ref('curation_listings') }}
    WHERE 1=1

    -- Filtre par prix
    {% if var("min_price", none) is not none %}
        AND price >= {{ var("min_price") }}
    {% endif %}

    {% if var("max_price", none) is not none %}
        AND price <= {{ var("max_price") }}
    {% endif %}

    -- Filtre par nombre de chambres
    {% if var("min_bedrooms", none) is not none %}
        AND bedrooms >= {{ var("min_bedrooms") }}
    {% endif %}

    -- Filtre par type de propriété
    {% if var("property_types", none) is not none %}
        AND property_type IN (
            {%- for property_type in var("property_types") -%}
                '{{ property_type }}'
                {%- if not loop.last -%},{%- endif -%}
            {%- endfor -%}
        )
    {% endif %}

    -- Filtre par type de chambre
    {% if var("room_types", none) is not none %}
        AND room_type IN (
            {%- for room_type in var("room_types") -%}
                '{{ room_type }}'
                {%- if not loop.last -%},{%- endif -%}
            {%- endfor -%}
        )
    {% endif %}
)

SELECT
    *,
    -- Ajout de métadonnées sur les filtres appliqués
    '{{ var("min_price", "non défini") }}' AS filtre_prix_min,
    '{{ var("max_price", "non défini") }}' AS filtre_prix_max,
    '{{ var("environment", "dev") }}' AS environnement
FROM filtered_listings

{% if var("debug_mode", false) %}
    -- Mode debug : limiter le nombre de résultats
    LIMIT {{ var("debug_limit", 100) }}
{% endif %}
```

### 2. Modèle avec dates variables

Créons `models/analytics/analytics_bookings_period.sql` :

```sql
{{
    config(
        materialized='table',
        schema='analytics'
    )
}}

-- Analyse des réservations pour une période donnée
WITH bookings_period AS (
    SELECT
        listing_id,
        host_id,
        date,
        available,
        price,
        adjusted_price,
        minimum_nights,
        maximum_nights
    FROM {{ source('raw_airbnb_data', 'calendar') }}
    WHERE 1=1

    -- Filtre par période
    {% if var("start_date", none) is not none %}
        AND date >= '{{ var("start_date") }}'
    {% endif %}

    {% if var("end_date", none) is not none %}
        AND date <= '{{ var("end_date") }}'
    {% endif %}

    -- Filtre par disponibilité
    {% if var("available_only", false) %}
        AND available = 't'
    {% endif %}
),

aggregated_stats AS (
    SELECT
        listing_id,
        COUNT(*) AS jours_total,
        SUM(CASE WHEN available = 't' THEN 1 ELSE 0 END) AS jours_disponibles,
        SUM(CASE WHEN available = 'f' THEN 1 ELSE 0 END) AS jours_reserves,

        AVG(CASE WHEN available = 't' AND price IS NOT NULL
            THEN TRY_CAST(REPLACE(price, '$', '') AS FLOAT) END) AS prix_moyen_disponible,

        MIN(date) AS premiere_date,
        MAX(date) AS derniere_date

    FROM bookings_period
    WHERE price IS NOT NULL
    GROUP BY listing_id
)

SELECT
    a.*,
    l.name AS listing_name,
    l.property_type,
    l.room_type,

    -- Calculs de performance
    ROUND(jours_reserves::FLOAT / jours_total * 100, 2) AS taux_occupation_pct,
    ROUND(jours_disponibles::FLOAT / jours_total * 100, 2) AS taux_disponibilite_pct,

    -- Métadonnées sur la période analysée
    '{{ var("start_date", "début des données") }}' AS periode_debut,
    '{{ var("end_date", "fin des données") }}' AS periode_fin,
    '{{ var("environment", "dev") }}' AS environnement

FROM aggregated_stats a
LEFT JOIN {{ ref('curation_listings') }} l
    ON a.listing_id = l.listing_id

-- Filtre par taux d'occupation minimum
{% if var("min_occupancy_rate", none) is not none %}
WHERE (jours_reserves::FLOAT / jours_total * 100) >= {{ var("min_occupancy_rate") }}
{% endif %}

ORDER BY taux_occupation_pct DESC
```

## 🏗️ Configuration par environnement

### 1. Variables dans `dbt_project.yml`

```yaml
# dbt_project.yml
vars:
  # Variables de développement (par défaut)
  environment: 'dev'
  debug_mode: true
  max_records: 1000
  table_prefix: 'dev_'

  # Filtres par défaut
  start_date: '2024-01-01'
  end_date: '2024-12-31'
  min_price: 10
  max_price: 1000

  # Types de propriétés autorisés
  property_types: ['Entire home/apt', 'Private room', 'Shared room']
  room_types: ['Entire home/apt', 'Private room']

  # Seuils d'analyse
  min_occupancy_rate: 50
  price_threshold: 150

models:
  analyse_airbnb:
    curation:
      +materialized: table
      +schema: curation

    analytics:
      +materialized: view
      +schema: analytics
      +tags: ["{{ var('environment') }}"]
```

### 2. Surcharge pour la production

Créez `vars/production.yml` :

```yaml
# Variables spécifiques à la production
environment: 'prod'
debug_mode: false
max_records: null  # Pas de limite en production
table_prefix: ''

# Période étendue pour la production
start_date: '2020-01-01'
end_date: '2025-12-31'

# Filtres plus larges
min_price: 1
max_price: 5000
min_occupancy_rate: 0
```

## 🚀 Exécution avec variables

### 1. Exécution de développement

```bash
# Exécution normale (utilise les variables du projet)
dbt run --select analytics_listings_filtered

# Debug avec filtres spécifiques
dbt run --select analytics_listings_filtered --vars '{
    "debug_mode": true,
    "min_price": 50,
    "max_price": 200,
    "property_types": ["Entire home/apt"],
    "debug_limit": 50
}'
```

### 2. Analyse pour période spécifique

```bash
# Analyse pour l'été 2024
dbt run --select analytics_bookings_period --vars '{
    "start_date": "2024-06-01",
    "end_date": "2024-08-31",
    "available_only": false,
    "min_occupancy_rate": 60
}'

# Analyse pour listings premium
dbt run --select analytics_listings_filtered --vars '{
    "min_price": 300,
    "property_types": ["Entire home/apt"],
    "min_bedrooms": 2
}'
```

### 3. Exécution en production

```bash
# Production avec fichier de variables
dbt run --vars-file vars/production.yml

# Production avec surcharge spécifique
dbt run --vars-file vars/production.yml --vars '{"end_date": "2024-06-30"}'
```

## 🔍 Variables avancées

### 1. Variables calculées dans des macros

Créez `macros/get_date_range.sql` :

```sql
{% macro get_date_range() %}
    {% if var("environment") == "dev" %}
        {% set start_date = "2024-01-01" %}
        {% set end_date = "2024-03-31" %}
    {% else %}
        {% set start_date = var("start_date", "2020-01-01") %}
        {% set end_date = var("end_date", "2024-12-31") %}
    {% endif %}

    {% do return({
        "start_date": start_date,
        "end_date": end_date
    }) %}
{% endmacro %}
```

Utilisation dans un modèle :

```sql
{% set date_range = get_date_range() %}

SELECT *
FROM {{ source('raw_airbnb_data', 'calendar') }}
WHERE date BETWEEN '{{ date_range.start_date }}' AND '{{ date_range.end_date }}'
```

### 2. Variables conditionnelles complexes

```sql
-- Logique de filtrage avancée
{% set filters = [] %}

{% if var("min_price", none) is not none %}
    {% do filters.append("price >= " + var("min_price")|string) %}
{% endif %}

{% if var("property_types", none) is not none %}
    {% set property_filter %}
        property_type IN (
            {%- for pt in var("property_types") -%}
                '{{ pt }}'
                {%- if not loop.last -%},{%- endif -%}
            {%- endfor -%}
        )
    {% endset %}
    {% do filters.append(property_filter) %}
{% endif %}

SELECT *
FROM {{ ref('curation_listings') }}
{% if filters|length > 0 %}
    WHERE {{ filters|join(' AND ') }}
{% endif %}
```

## 📊 Validation des variables

### 1. Macro de validation

Créez `macros/validate_vars.sql` :

```sql
{% macro validate_vars() %}

    -- Validation des dates
    {% if var("start_date", none) is not none and var("end_date", none) is not none %}
        {% if var("start_date") > var("end_date") %}
            {{ log("ERREUR: start_date doit être antérieure à end_date", info=true) }}
            {{ exceptions.raise_compiler_error("Date de début postérieure à la date de fin") }}
        {% endif %}
    {% endif %}

    -- Validation des prix
    {% if var("min_price", none) is not none and var("max_price", none) is not none %}
        {% if var("min_price") >= var("max_price") %}
            {{ log("ERREUR: min_price doit être inférieur à max_price", info=true) }}
            {{ exceptions.raise_compiler_error("Prix minimum supérieur au prix maximum") }}
        {% endif %}
    {% endif %}

    -- Validation de l'environnement
    {% set valid_environments = ["dev", "staging", "prod"] %}
    {% if var("environment", "dev") not in valid_environments %}
        {{ exceptions.raise_compiler_error("Environnement invalide: " + var("environment")) }}
    {% endif %}

    {{ log("✅ Validation des variables réussie", info=true) }}

{% endmacro %}
```

Utilisation dans un modèle :

```sql
-- Validation en début de modèle
{{ validate_vars() }}

SELECT * FROM my_data
```

## 🔄 Variables dynamiques

### 1. Variables basées sur l'heure d'exécution

```sql
{% set current_date = modules.datetime.datetime.now().strftime("%Y-%m-%d") %}
{% set current_month = modules.datetime.datetime.now().strftime("%Y-%m") %}

SELECT
    *,
    '{{ current_date }}' AS date_execution,
    '{{ current_month }}' AS mois_execution
FROM my_data
WHERE date_colonne >= '{{ var("start_date", current_date) }}'
```

### 2. Variables avec logique métier

```sql
{% macro get_price_segment(price_var="price") %}
    CASE
        WHEN {{ price_var }} <= {{ var("budget_threshold", 75) }} THEN 'Budget'
        WHEN {{ price_var }} <= {{ var("standard_threshold", 150) }} THEN 'Standard'
        WHEN {{ price_var }} <= {{ var("premium_threshold", 300) }} THEN 'Premium'
        ELSE 'Luxe'
    END
{% endmacro %}

SELECT
    *,
    {{ get_price_segment() }} AS segment_prix
FROM {{ ref('curation_listings') }}
```

## 📈 Exemple complet : Dashboard configurable

Créons `models/analytics/analytics_dashboard_kpis.sql` :

```sql
{{
    config(
        materialized='table',
        schema='analytics'
    )
}}

-- KPIs configurables pour dashboard
{{ validate_vars() }}

{% set date_range = get_date_range() %}

WITH listings_filtered AS (
    SELECT *
    FROM {{ ref('curation_listings') }}
    WHERE 1=1

    {% if var("property_types", none) is not none %}
        AND property_type IN (
            {%- for pt in var("property_types") -%}
                '{{ pt }}'
                {%- if not loop.last -%},{%- endif -%}
            {%- endfor -%}
        )
    {% endif %}

    {% if var("price_range", none) is not none %}
        AND price BETWEEN {{ var("price_range")[0] }} AND {{ var("price_range")[1] }}
    {% endif %}
),

kpis AS (
    SELECT
        COUNT(*) AS nb_listings_total,
        COUNT(DISTINCT host_id) AS nb_hosts_uniques,
        AVG(price) AS prix_moyen,
        MEDIAN(price) AS prix_median,
        MIN(price) AS prix_min,
        MAX(price) AS prix_max,

        -- Segments de prix avec seuils variables
        SUM(CASE WHEN price <= {{ var("budget_threshold", 75) }} THEN 1 ELSE 0 END) AS nb_budget,
        SUM(CASE WHEN price > {{ var("budget_threshold", 75) }}
                 AND price <= {{ var("standard_threshold", 150) }} THEN 1 ELSE 0 END) AS nb_standard,
        SUM(CASE WHEN price > {{ var("standard_threshold", 150) }}
                 AND price <= {{ var("premium_threshold", 300) }} THEN 1 ELSE 0 END) AS nb_premium,
        SUM(CASE WHEN price > {{ var("premium_threshold", 300) }} THEN 1 ELSE 0 END) AS nb_luxe,

        -- Métadonnées
        '{{ var("environment", "dev") }}' AS environnement,
        '{{ date_range.start_date }}' AS periode_debut,
        '{{ date_range.end_date }}' AS periode_fin,
        CURRENT_TIMESTAMP() AS genere_le

    FROM listings_filtered
)

SELECT * FROM kpis
```

## ⚡ Optimisations avec variables

### 1. Échantillonnage conditionnel

```sql
SELECT *
FROM {{ ref('large_table') }}
{% if var("debug_mode", false) %}
    SAMPLE ({{ var("sample_rate", 1) }} PERCENT)
{% endif %}
```

### 2. Partitioning dynamique

```sql
{{
    config(
        materialized='table',
        partition_by={
            'field': var('partition_field', 'date_created'),
            'data_type': 'date'
        } if var('use_partitioning', true) else none
    )
}}
```

## ❗ Bonnes pratiques

### 1. Nommage des variables
- Utilisez des noms explicites : `min_price` plutôt que `mp`
- Préfixez par contexte : `debug_mode`, `filter_country`
- Soyez cohérent dans le projet

### 2. Valeurs par défaut
- Toujours fournir des valeurs par défaut sensées
- Utiliser `none` pour les filtres optionnels
- Documenter les valeurs attendues

### 3. Validation
- Valider les types et plages de valeurs
- Fournir des messages d'erreur clairs
- Loguer les valeurs utilisées pour le debug

## 🎯 Cas d'usage recommandés

| Cas d'usage | Variables recommandées | Exemple |
|-------------|----------------------|---------|
| **Filtrage temporel** | `start_date`, `end_date` | Analyses périodiques |
| **Debug/Test** | `debug_mode`, `limit_rows` | Développement rapide |
| **Environnements** | `environment`, `schema_prefix` | Dev/Staging/Prod |
| **Seuils métier** | `price_threshold`, `min_rating` | Règles business |
| **Performance** | `sample_rate`, `use_clustering` | Optimisations |

## ✅ Validation finale

Testez vos variables avec différentes configurations :

```bash
# Test en développement
dbt run --vars '{"debug_mode": true, "environment": "dev"}'

# Test avec filtres
dbt run --vars '{
    "min_price": 100,
    "property_types": ["Entire home/apt"],
    "start_date": "2024-01-01"
}'

# Test de validation d'erreurs
dbt run --vars '{"min_price": 200, "max_price": 100}'  # Doit échouer
```

## 🎯 Points clés à retenir

1. **Flexibilité** : Les variables permettent de paramétrer vos modèles
2. **Réutilisabilité** : Un même modèle pour différents cas d'usage
3. **Environnements** : Configuration différente selon le contexte
4. **Performance** : Optimisation conditionnelle avec variables
5. **Validation** : Toujours valider les valeurs critiques

---

**Prochaine étape** : [Chapitre 9 - Tests et documentation](chapitre-9-tests.md)