# Chapitre 4 : Matérialisations

## 🎯 Objectifs
- Comprendre les différents types de matérialisations
- Configurer les matérialisations par modèle
- Optimiser les performances avec les bonnes matérialisations
- Gérer les schémas de destination

## 📊 Types de matérialisations

DBT propose plusieurs types de matérialisations :

| Type | Description | Cas d'usage | Performance |
|------|-------------|-------------|-------------|
| **view** | Vue SQL (défaut) | Transformations légères, données toujours à jour | ⚡ Rapide à créer |
| **table** | Table physique | Données volumineuses, calculs complexes | 🚀 Rapide à lire |
| **incremental** | Table mise à jour incrémentalement | Très gros volumes, historique | ⚡🚀 Optimal |
| **ephemeral** | CTE réutilisable | Logique intermédiaire | 🔄 Pas de stockage |

## ⚙️ Configuration des matérialisations

### 1. Configuration au niveau du modèle

Ajoutez la configuration en haut de vos fichiers SQL avec la macro `config` :

#### Exemple pour `curation_hosts.sql`

```sql
{{
    config(
        materialized='table'
    )
}}

-- Modèle de curation pour les données des hôtes Airbnb
WITH hosts_raw AS (
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
        host_identity_verified = 't' AS is_identity_verified
    FROM {{ source('raw_airbnb_data', 'hosts') }}
)

SELECT * FROM hosts_raw
```

#### Exemple pour `curation_listings.sql`

```sql
{{
    config(
        materialized='view'
    )
}}

-- Modèle de curation pour les données des listings Airbnb
WITH listings_raw AS (
    SELECT
        id AS listing_id,
        listing_url,
        name,
        description,
        description IS NOT NULL AS has_description,
        neighbourhood_overview,
        neighbourhood_overview IS NOT NULL AS has_neighbourhood_description,
        host_id,
        latitude,
        longitude,
        property_type,
        room_type,
        accommodates,
        bathrooms,
        bedrooms,
        beds,
        amenities,
        TRY_CAST(SPLIT_PART(price, '$', 2) AS FLOAT) AS price,
        minimum_nights,
        maximum_nights
    FROM {{ source('raw_airbnb_data', 'listings') }}
)

SELECT * FROM listings_raw
```

### 2. Configuration au niveau du projet

Dans `dbt_project.yml`, vous pouvez définir des matérialisations par défaut :

```yaml
models:
  analyse_airbnb:
    # Modèles de curation en tables pour de meilleures performances
    curation:
      +materialized: table
      +schema: curation

    # Modèles analytics en tables pour les dashboards
    analytics:
      +materialized: table
      +schema: analytics

    # Modèles intermédiaires en views
    intermediate:
      +materialized: view
      +schema: intermediate
```

## 🏗️ Gestion des schémas personnalisés

### 1. Problème par défaut

Par défaut, DBT crée les schémas comme : `[target_schema]_[custom_schema]`

Par exemple : `dbt_guillaume_curation` au lieu de simplement `curation`

### 2. Solution : Macro personnalisée

Créez le fichier `macros/generate_schema_name.sql` :

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
```

#### Explication détaillée de la macro

Cette macro **surcharge le comportement par défaut de DBT** pour la génération des noms de schémas.

**Fonctionnement :**

1. **Paramètres d'entrée :**
   - `custom_schema_name` : le nom du schéma personnalisé défini dans la configuration (`+schema: curation`)
   - `node` : objet contenant les métadonnées du modèle (non utilisé ici)

2. **Logique conditionnelle :**
   - **Ligne 130** : Récupère le schéma par défaut (`target.schema`) depuis le profil de connexion
   - **Ligne 131-133** : Si aucun schéma personnalisé n'est spécifié (`custom_schema_name is none`), utilise le schéma par défaut
   - **Ligne 135-137** : Si un schéma personnalisé est défini, l'utilise tel quel après suppression des espaces (`trim`)

3. **Comportement par défaut vs. personnalisé :**

| Configuration | Sans macro (défaut) | Avec macro personnalisée |
|---------------|---------------------|-------------------------|
| `+schema: curation` | `dbt_guillaume_curation` | `curation` |
| `+schema: analytics` | `dbt_guillaume_analytics` | `analytics` |
| Pas de schema | `dbt_guillaume` | `dbt_guillaume` |

**Avantages :**
- **Simplicité** : Les schémas ont des noms clairs et courts
- **Consistance** : Même structure entre développement et production
- **Lisibilité** : Plus facile à comprendre dans les requêtes SQL

Cette macro permet d'utiliser directement le nom du schéma personnalisé sans préfixe.

### 3. Résultat

Avec cette macro, vos modèles seront créés dans :
- `AIRBNB.CURATION.CURATION_HOSTS`
- `AIRBNB.CURATION.CURATION_LISTINGS`
- `AIRBNB.CURATION.CURATION_REVIEWS`

## 🚀 Test des matérialisations

### 1. Nettoyer et reconstruire

```bash
# Nettoyer les anciens builds
dbt clean

# Reconstruire tous les modèles
dbt run
```

### 3. Observer les performances

Comparez les temps d'exécution :

```sql
-- Query sur une table (plus rapide)
SELECT COUNT(*) FROM AIRBNB.CURATION.CURATION_HOSTS;

-- Query sur une view (recalcul à chaque fois)
SELECT COUNT(*) FROM AIRBNB.CURATION.CURATION_LISTINGS;
```

## 📈 Création d'un modèle analytics


### 1. Créer `models/analytics/analytics_host_performance.sql`

```sql
{{
    config(
        materialized='view',
        schema='analytics'
    )
}}

-- Analyse de performance des hôtes
-- Table matérialisée pour des accès rapides aux dashboards

WITH host_stats AS (
    SELECT
        h.host_id,
        h.host_name,
        h.host_city,
        h.host_country,
        h.is_superhost,
        h.response_rate,

        -- Statistiques des listings
        COUNT(l.listing_id) AS nb_listings,
        AVG(l.price) AS prix_moyen,
        MIN(l.price) AS prix_min,
        MAX(l.price) AS prix_max,

        -- Capacité totale
        SUM(l.accommodates) AS capacite_totale,
        AVG(l.accommodates) AS capacite_moyenne,

        -- Diversité des types de propriétés
        COUNT(DISTINCT l.property_type) AS nb_types_proprietes,
        COUNT(DISTINCT l.room_type) AS nb_types_chambres

    FROM airbnb.curation.curation_hosts h
    INNER JOIN airbnb.curation.curation_listings l
        ON h.host_id = l.host_id

    WHERE l.price IS NOT NULL
      AND l.price > 0

    GROUP BY 1, 2, 3, 4, 5, 6
),

performance_categories AS (
    SELECT
        *,
        -- Catégorisation des hôtes
        CASE
            WHEN nb_listings >= 10 THEN 'Professionnel'
            WHEN nb_listings >= 3 THEN 'Multi-propriétaire'
            ELSE 'Particulier'
        END AS categorie_hote,

        -- Segmentation prix
        CASE
            WHEN prix_moyen <= 75 THEN 'Budget'
            WHEN prix_moyen <= 150 THEN 'Standard'
            WHEN prix_moyen <= 300 THEN 'Premium'
            ELSE 'Luxe'
        END AS segment_prix

    FROM host_stats
)

SELECT * FROM performance_categories
ORDER BY nb_listings DESC, prix_moyen DESC
```

### 2. Exécuter le modèle analytics

```bash
dbt run --select analytics_host_performance
```

## 📊 Configuration avancée avec des tags

Ajoutez des tags pour organiser vos modèles :

```sql
{{
    config(
        materialized='table',
        schema='analytics',
        tags=['analytics', 'dashboard', 'performance']
    )
}}
```

Puis exécutez par tags :

```bash
# Exécuter tous les modèles analytics
dbt run --select tag:analytics

# Exécuter tous les modèles dashboard
dbt run --select tag:dashboard
```

## ⚡ Optimisations de performance

### 1. Configuration des clusters (Snowflake)

Pour de grandes tables, ajoutez le clustering :

```sql
{{
    config(
        materialized='table',
        cluster_by=['host_country', 'categorie_hote']
    )
}}
```

### 2. Configuration des index

```sql
{{
    config(
        materialized='table',
        post_hook="CREATE INDEX idx_host_id ON {{ this }} (host_id)"
    )
}}
```

### 3. Partitioning temporel

```sql
{{
    config(
        materialized='table',
        partition_by={
            'field': 'date_created',
            'data_type': 'date'
        }
    )
}}
```

## 🔍 Analyse des matérialisations

### 1. Vérifier les objets créés

```sql
-- Liste tous les objets créés par DBT
SELECT
    table_schema,
    table_name,
    table_type,
    row_count
FROM INFORMATION_SCHEMA.TABLES
WHERE table_schema IN ('CURATION', 'ANALYTICS')
ORDER BY table_schema, table_name;
```

### 2. Comparer les tailles

```sql
-- Taille des tables
SELECT
    table_schema,
    table_name,
    bytes,
    rows
FROM INFORMATION_SCHEMA.TABLE_STORAGE_METRICS
WHERE table_schema IN ('CURATION', 'ANALYTICS')
ORDER BY bytes DESC;
```

## 🎯 Recommandations par cas d'usage

| Cas d'usage | Matérialisation | Justification |
|-------------|-----------------|---------------|
| **ETL quotidien** | table | Calculs complexes, accès fréquents |
| **Dashboards** | table | Performance requise |
| **Données temps réel** | view | Toujours à jour |
| **Gros volumes** | incremental | Optimisation ressources |
| **Logique intermédiaire** | ephemeral | Pas de stockage nécessaire |

## ❗ Erreurs courantes et solutions

### Erreur de permission
```
Permission denied on schema 'CURATION'
```
**Solution** : Vérifiez les permissions dans Snowflake

### Erreur de configuration
```
Invalid materialization type
```
**Solution** : Vérifiez l'orthographe dans la macro config

### Conflit de schéma
```
Schema already exists
```
**Solution** : Utilisez la macro `generate_schema_name`

## ✅ Validation finale

Vérifiez que vous avez :

1. **Tables** dans le schéma `CURATION` pour `curation_hosts`
2. **View** dans le schéma `CURATION` pour `curation_listings`
3. **Table** dans le schéma `ANALYTICS` pour `analytics_host_performance`
4. **Macro** `generate_schema_name` fonctionnelle

```bash
# Test final
dbt run --full-refresh
```

## 🎯 Points clés à retenir

1. **Choix pertinent** : Adaptez la matérialisation au cas d'usage
2. **Performance** : Tables pour les accès fréquents, views pour la fraîcheur
3. **Organisation** : Utilisez des schémas pour structurer
4. **Optimisation** : Clustering et partitioning pour de gros volumes
5. **Tags** : Organisez l'exécution par groupes logiques

---

**Prochaine étape** : [Chapitre 5 - Lignée et dépendances](chapitre-5-lineage.md)