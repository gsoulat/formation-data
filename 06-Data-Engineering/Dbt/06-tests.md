# Chapitre 6 : Tests de qualité et unitaires

## 🎯 Objectifs
- Implémenter des tests de qualité sur les sources
- Créer des tests personnalisés pour les modèles
- Développer des tests unitaires pour la logique SQL
- Utiliser le package dbt-utils pour des tests avancés
- Créer des macros testables

## 🔍 Tests de qualité des sources

Nous avons déjà défini des tests de base dans le chapitre précédent. Enrichissons-les.

### 1. Compléter les tests dans `sources.yml`

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
            tests:
              - not_null
          - name: host_since
            description: "Date d'inscription de l'hôte"
            tests:
              - not_null
          - name: host_response_rate
            description: "Taux de réponse (format: XX%)"
            tests:
              - not_null

      - name: listings
        description: "Informations sur les logements Airbnb"
        columns:
          - name: id
            description: "Identifiant unique du listing"
            tests:
              - unique
              - not_null
          - name: host_id
            description: "Référence vers l'hôte"
            tests:
              - not_null
              - relationships:
                  to: source('raw_airbnb_data', 'hosts')
                  field: host_id
          - name: minimum_nights
            description: "Nombre minimum de nuits"
            tests:
              - not_null
              # Test personnalisé : valeur positive
              - dbt_utils.accepted_range:
                  min_value: 1
                  inclusive: true

      - name: reviews
        description: "Dates des commentaires"
        columns:
          - name: listing_id
            description: "Référence vers le listing"
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

## 📊 Tests de qualité des modèles

### 1. Créer le fichier `models/curation/schema.yml`

```yaml
version: 2

models:
  - name: curation_hosts
    description: "Table hôtes nettoyée et formatée"
    columns:
      - name: host_id
        description: "Identifiant unique de l'hôte"
        tests:
          - unique
          - not_null

      - name: host_name
        description: "Nom de l'hôte (anonymisé si nécessaire)"
        tests:
          - not_null

      - name: host_since
        description: "Date d'inscription de l'hôte"
        tests:
          - not_null

      - name: host_location
        description: "Localisation complète"
        tests:
          - not_null

      - name: host_city
        description: "Ville extraite de host_location"
        tests:
          - not_null

      - name: host_country
        description: "Pays extrait de host_location"
        tests:
          - not_null

      - name: response_rate
        description: "Taux de réponse converti en entier"
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 100
              inclusive: true

      - name: is_superhost
        description: "Statut superhost (boolean)"
        tests:
          - not_null
          - accepted_values:
              values: [true, false]

      - name: host_neighbourhood
        description: "Quartier de l'hôte"
        tests:
          - not_null

      - name: is_identity_verified
        description: "Identité vérifiée (boolean)"
        tests:
          - not_null
          - accepted_values:
              values: [true, false]

  - name: curation_listings
    description: "Table listings nettoyée et formatée"
    columns:
      - name: listing_id
        description: "Identifiant unique du listing"
        tests:
          - unique
          - not_null

      - name: host_id
        description: "Référence vers l'hôte"
        tests:
          - not_null
          - relationships:
              to: ref('curation_hosts')
              field: host_id

      - name: price
        description: "Prix par nuit en format numérique"
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              inclusive: false

      - name: accommodates
        description: "Nombre de personnes accueillies"
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 1
              max_value: 20
              inclusive: true

      - name: property_type
        description: "Type de propriété"
        tests:
          - not_null

      - name: room_type
        description: "Type de chambre"
        tests:
          - not_null
          - accepted_values:
              values:
                - 'Entire home/apt'
                - 'Private room'
                - 'Shared room'
                - 'Hotel room'

  - name: curation_tourists
    description: "Données de tourisme à Amsterdam formatées"
    columns:
      - name: year
        description: "Année"
        tests:
          - unique
          - not_null
          - dbt_utils.accepted_range:
              min_value: 2015
              max_value: 2030

      - name: tourists
        description: "Nombre de touristes"
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 1000000
              inclusive: true
```

## 🧪 Tests unitaires pour la logique SQL

Les tests unitaires permettent de tester la logique de transformation sans dépendre des vraies données.

### 1. Ajouter des tests unitaires dans `schema.yml`

```yaml
unit_tests:
  - name: test_host_name_anonymization
    description: "Vérifie que les noms d'1 caractère sont anonymisés"
    model: curation_hosts
    given:
      - input: ref('hosts_snapshot')
        rows:
          - {host_id: '1', host_name: 'Marie', host_location: "Paris,France", host_response_rate: '95%', host_is_superhost: 't', host_neighbourhood: 'Marais', host_identity_verified: 't', dbt_valid_to: null}
          - {host_id: '2', host_name: 'J', host_location: "Lyon,France", host_response_rate: '80%', host_is_superhost: 'f', host_neighbourhood: 'Centre', host_identity_verified: 't', dbt_valid_to: null}
          - {host_id: '3', host_name: 'X', host_location: "Nice,France", host_response_rate: '75%', host_is_superhost: 'f', host_neighbourhood: 'Vieux', host_identity_verified: 'f', dbt_valid_to: null}
    expect:
      rows:
        - {host_name: 'Marie', host_city: 'Paris', host_country: 'France', response_rate: 95}
        - {host_name: 'Anonyme', host_city: 'Lyon', host_country: 'France', response_rate: 80}
        - {host_name: 'Anonyme', host_city: 'Nice', host_country: 'France', response_rate: 75}

  - name: test_location_parsing
    description: "Vérifie l'extraction de ville et pays depuis host_location"
    model: curation_hosts
    given:
      - input: ref('hosts_snapshot')
        rows:
          - {host_id: '1', host_name: 'Test', host_location: "Amsterdam,Netherlands", host_response_rate: '100%', host_is_superhost: 't', host_neighbourhood: 'Centre', host_identity_verified: 't', dbt_valid_to: null}
          - {host_id: '2', host_name: 'Test', host_location: "New York,United States", host_response_rate: '90%', host_is_superhost: 'f', host_neighbourhood: 'Manhattan', host_identity_verified: 't', dbt_valid_to: null}
    expect:
      rows:
        - {host_city: 'Amsterdam', host_country: 'Netherlands'}
        - {host_city: 'New York', host_country: 'United States'}

  - name: test_boolean_conversions
    description: "Vérifie la conversion des valeurs t/f en boolean"
    model: curation_hosts
    given:
      - input: ref('hosts_snapshot')
        rows:
          - {host_id: '1', host_name: 'Test', host_location: "Test,Test", host_response_rate: '100%', host_is_superhost: 't', host_neighbourhood: 'Test', host_identity_verified: 't', dbt_valid_to: null}
          - {host_id: '2', host_name: 'Test', host_location: "Test,Test", host_response_rate: '100%', host_is_superhost: 'f', host_neighbourhood: 'Test', host_identity_verified: 'f', dbt_valid_to: null}
    expect:
      rows:
        - {is_superhost: true, is_identity_verified: true}
        - {is_superhost: false, is_identity_verified: false}
```

### 2. Exécuter les tests unitaires

```bash
# Exécuter tous les tests unitaires
dbt test --select test_type:unit

# Exécuter un test spécifique
dbt test --select test_host_name_anonymization
```

## 🛠️ Macros et tests personnalisés

### 1. Créer une macro pour extraire les prix

Créez le fichier `macros/extract_price.sql` :

```sql
{% macro extraire_prix_a_partir_dun_caractere(price_column, symbol='$') -%}
    TRY_CAST(
        CASE
            WHEN STARTSWITH({{ price_column }}, '{{ symbol }}') THEN
                SPLIT_PART({{ price_column }}, '{{ symbol }}', 2)
            WHEN ENDSWITH({{ price_column }}, '{{ symbol }}') THEN
                SPLIT_PART({{ price_column }}, '{{ symbol }}', 1)
            ELSE NULL
        END
    AS FLOAT)
{%- endmacro %}
```

### 2. Utiliser la macro dans un modèle

Modifiez `curation_listings.sql` pour utiliser la macro :

```sql
{{
    config(
        materialized='view'
    )
}}

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

        -- Utilisation de la macro pour extraire le prix
        {{ extraire_prix_a_partir_dun_caractere('price', '$') }} AS price,

        minimum_nights,
        maximum_nights

    FROM {{ source('raw_airbnb_data', 'listings') }}
)

SELECT * FROM listings_raw
```

### 3. Tester la macro avec des tests unitaires

Ajoutez dans `schema.yml` :

```yaml
unit_tests:
  - name: test_price_extraction_macro
    description: "Teste la macro d'extraction de prix"
    model: curation_listings
    given:
      - input: source('raw_airbnb_data', 'listings')
        rows:
          - {id: '1', price: '$75.00', host_id: '123', property_type: 'Apartment', room_type: 'Entire home/apt', accommodates: 2, minimum_nights: 1, maximum_nights: 30}
          - {id: '2', price: '120.50$', host_id: '124', property_type: 'House', room_type: 'Entire home/apt', accommodates: 4, minimum_nights: 2, maximum_nights: 14}
          - {id: '3', price: 'N/A', host_id: '125', property_type: 'Room', room_type: 'Private room', accommodates: 1, minimum_nights: 1, maximum_nights: 7}
    expect:
      rows:
        - {listing_id: '1', price: 75.0}
        - {listing_id: '2', price: 120.5}
        - {listing_id: '3', price: null}
```

## 📦 Installation et utilisation de dbt-utils

### 1. Créer le fichier `packages.yml`

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
```

### 2. Installer les packages

```bash
dbt deps
```

### 3. Utiliser dbt-utils dans les tests

Nous avons déjà utilisé `dbt_utils.accepted_range` dans nos tests. Ajoutons d'autres tests utiles :

```yaml
# Dans models/curation/schema.yml
models:
  - name: curation_listings
    tests:
      # Test d'unicité composée
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - listing_id
            - host_id
    columns:
      - name: listing_id
        tests:
          # Test de format (doit être numérique)
          - dbt_utils.not_empty_string

      - name: price
        tests:
          # Test de valeurs non négatives
          - dbt_utils.accepted_range:
              min_value: 0
              inclusive: false
          # Test que 95% des prix sont sous 500€
          - dbt_utils.expression_is_true:
              expression: "price < 500"
              config:
                severity: warn
                where: "price is not null"

      - name: accommodates
        tests:
          # Test de cohérence métier
          - dbt_utils.expression_is_true:
              expression: "accommodates >= bedrooms"
              config:
                where: "bedrooms is not null"
```

## 🔧 Tests personnalisés avancés

### 1. Créer un test personnalisé

Créez le fichier `tests/test_price_consistency.sql` :

```sql
-- Test personnalisé : vérifier que le prix moyen par type de propriété est cohérent
WITH price_stats AS (
    SELECT
        property_type,
        AVG(price) AS avg_price,
        COUNT(*) AS listing_count
    FROM {{ ref('curation_listings') }}
    WHERE price IS NOT NULL AND price > 0
    GROUP BY property_type
),

outliers AS (
    SELECT *
    FROM price_stats
    WHERE avg_price > 1000  -- Prix moyen suspicieusement élevé
       OR avg_price < 10    -- Prix moyen suspicieusement bas
       OR listing_count < 5 -- Trop peu de données
)

-- Le test échoue s'il y a des outliers
SELECT * FROM outliers
```

### 2. Test de cohérence temporelle

Créez `tests/test_review_dates_logical.sql` :

```sql
-- Vérifier que les dates de reviews sont logiques
WITH invalid_dates AS (
    SELECT
        listing_id,
        date
    FROM {{ source('raw_airbnb_data', 'reviews') }}
    WHERE date > CURRENT_DATE  -- Dates futures
       OR date < '2008-01-01'  -- Avant la création d'Airbnb
)

SELECT * FROM invalid_dates
```

## ⚡ Optimisation des tests

### 1. Configuration des tests par environnement

Dans `dbt_project.yml` :

```yaml
tests:
  analyse_airbnb:
    +severity: error  # Par défaut, les tests font échouer le build

    # Tests moins critiques en warning
    sources:
      +severity: warn

    # Tests de performance en warning pour le développement
    +tags: ["performance"]
    +severity: warn
```

### 2. Exécution sélective des tests

```bash
# Tests critiques seulement
dbt test --select tag:critical

# Exclure les tests lents
dbt test --exclude tag:slow

# Tests par sévérité
dbt test --fail-fast  # S'arrêter au premier échec
```

## 📊 Monitoring et alertes

### 1. Tests de fraîcheur des données

Dans `sources.yml` :

```yaml
sources:
  - name: raw_airbnb_data
    freshness:
      warn_after: {count: 1, period: day}
      error_after: {count: 3, period: day}
    loaded_at_field: load_timestamp  # Si vous avez ce champ
```

### 2. Tests de volume

Créez `tests/test_data_volume.sql` :

```sql
-- Vérifier que nous avons un volume minimum de données
WITH volume_check AS (
    SELECT
        COUNT(*) AS total_hosts
    FROM {{ ref('curation_hosts') }}
)

SELECT *
FROM volume_check
WHERE total_hosts < 1000  -- Alerte si moins de 1000 hôtes
```

## 🎯 Stratégie de tests

### 1. Tests par couche

| Couche | Types de tests | Priorité |
|--------|----------------|----------|
| **Sources** | Unicité, non-nullité, relations | Critique |
| **Curation** | Logique métier, formats | Haute |
| **Analytics** | Cohérence, agrégations | Moyenne |

### 2. Fréquence d'exécution

```bash
# Tests rapides à chaque build
dbt test --select tag:fast

# Tests complets quotidiens
dbt test --full-refresh

# Tests de performance hebdomadaires
dbt test --select tag:performance
```

## ✅ Checklist de validation

Votre projet doit avoir :

- [ ] Tests de base sur toutes les sources
- [ ] Tests métier sur les modèles de curation
- [ ] Au moins 3 tests unitaires fonctionnels
- [ ] Package dbt-utils installé et utilisé
- [ ] Tests personnalisés pour la logique spécifique
- [ ] Configuration de sévérité appropriée

```bash
# Test final complet
dbt test --full-refresh
```

## 🎯 Points clés à retenir

1. **Tests en pyramide** : Beaucoup de tests unitaires, quelques tests d'intégration
2. **Tests précoces** : Tester les sources avant les transformations
3. **Sévérité adaptée** : Error pour les critiques, warn pour le monitoring
4. **Maintenance** : Réviser les tests avec l'évolution des données
5. **Documentation** : Chaque test doit avoir une description claire

---

**Prochaine étape** : [Chapitre 7 - Modèles incrémentaux](chapitre-7-incremental.md)