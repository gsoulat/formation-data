# Chapitre 7 : Modèles incrémentaux

## 🎯 Objectifs
- Comprendre les modèles incrémentaux et leurs avantages
- Implémenter un modèle incrémental pour les hôtes
- Gérer les mises à jour et les doublons
- Optimiser les performances pour de gros volumes
- Tester les stratégies incrémentales

## 📈 Introduction aux modèles incrémentaux

Les modèles incrémentaux permettent de traiter efficacement de gros volumes de données en ne transformant que les nouveaux enregistrements ou ceux modifiés.

### Avantages
- ⚡ **Performance** : Traitement des deltas uniquement
- 💰 **Coût** : Réduction de la consommation de ressources
- 🕐 **Temps** : Builds plus rapides
- 📊 **Fraîcheur** : Mises à jour fréquentes possibles

### Cas d'usage typiques
- Tables de faits volumineuses
- Logs d'événements
- Données historiques
- Tables de dimensions qui évoluent

## 🏗️ Préparation : Ajout de timestamps

### 1. Modification de la table source

Dans Snowflake, ajoutons un timestamp de chargement à la table hosts :

```sql
-- Ajouter une colonne de timestamp
ALTER TABLE AIRBNB.RAW.HOSTS ADD COLUMN LOAD_TIMESTAMP TIMESTAMP;

-- Mettre à jour tous les enregistrements existants avec le timestamp actuel
UPDATE AIRBNB.RAW.HOSTS SET LOAD_TIMESTAMP = CURRENT_TIMESTAMP;

-- Vérifier le résultat
SELECT host_id, host_name, load_timestamp FROM AIRBNB.RAW.HOSTS LIMIT 10;
```

### 2. Configuration des variables

Dans `dbt_project.yml`, ajoutez les variables pour l'environnement incrémental :

```yaml
vars:
  # Variables pour les modèles incrémentaux
  inc_database: 'airbnb'
  inc_schema: 'curation_inc'

  # Nombre de jours pour le lookback (réexécution partielle)
  incremental_lookback_days: 2
```

## 📊 Création du modèle incrémental

### 1. Créer le modèle `models/curation_inc/curation_hosts_inc.sql`

```sql
{{
    config(
        database=var('inc_database'),
        schema=var('inc_schema'),
        materialized='incremental',
        unique_key='host_id',
    )
}}

-- Modèle incrémental pour les données des hôtes
-- Traite uniquement les nouveaux enregistrements ou ceux modifiés

WITH raw_hosts AS (
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
        load_timestamp,

        -- Metadata pour le tracking
        CURRENT_TIMESTAMP AS dbt_updated_at

    FROM {{ source('raw_airbnb_data', 'hosts') }}
)
SELECT * FROM raw_hosts
{% if is_incremental() %}
    -- En mode incrémental : seulement les nouveaux enregistrements
    WHERE load_timestamp > (SELECT MAX(load_timestamp) FROM {{ this }})
{% else %}
    -- Première exécution : éliminer les doublons en gardant le plus récent
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY host_id
        ORDER BY load_timestamp DESC
    ) = 1
{% endif %}

```

### 2. Première exécution du modèle

```bash
# Première exécution (full refresh automatique)
dbt run --select curation_hosts_inc

# Vérifier dans Snowflake
```

Dans Snowflake, vérifiez la création :

```sql
-- Compter les enregistrements
SELECT COUNT(*) FROM AIRBNB.CURATION_INC.CURATION_HOSTS_INC;

-- Vérifier les timestamps
SELECT
    MIN(load_timestamp) AS premier_timestamp,
    MAX(load_timestamp) AS dernier_timestamp,
    COUNT(DISTINCT load_timestamp) AS nb_timestamps_differents
FROM AIRBNB.CURATION_INC.CURATION_HOSTS_INC;
```

## 🔄 Test des mises à jour incrémentales

### 1. Simuler l'arrivée de nouvelles données

Dans Snowflake, insérons un nouvel enregistrement :

```sql
-- Insérer un nouveau hôte avec un timestamp récent
INSERT INTO AIRBNB.RAW.HOSTS VALUES (
    '999999',                    -- host_id unique
    'Alice Martin',              -- host_name
    '2024-01-15'::DATE,         -- host_since
    'Rotterdam, Netherlands',    -- host_location
    'within an hour',           -- host_response_time
    '98%',                      -- host_response_rate
    't',                        -- host_is_superhost
    'Centrum',                  -- host_neighbourhood
    't',                        -- host_identity_verified
    CURRENT_TIMESTAMP           -- load_timestamp
);

-- Vérifier l'insertion
SELECT * FROM AIRBNB.RAW.HOSTS WHERE host_id = '999999';
```

### 2. Exécution incrémentale

```bash
# Exécution incrémentale (traite seulement le nouveau record)
dbt run --select curation_hosts_inc

# Vérifier que le nouveau record a été ajouté
```

Dans Snowflake :

```sql
-- Vérifier le nouveau record
SELECT * FROM AIRBNB.CURATION_INC.CURATION_HOSTS_INC WHERE host_id = '999999';

-- Compter le total (devrait avoir +1)
SELECT COUNT(*) FROM AIRBNB.CURATION_INC.CURATION_HOSTS_INC;
```

## 🔧 Gestion des mises à jour existantes

### 1. Simuler une mise à jour

```sql
-- Modifier un enregistrement existant
UPDATE AIRBNB.RAW.HOSTS
SET
    host_response_time = 'within a few hours',
    host_response_rate = '95%',
    load_timestamp = CURRENT_TIMESTAMP
WHERE host_id = '1376607';
```


## ⚠️ Bonnes pratiques et pièges à éviter

### ✅ Bonnes pratiques

1. **Tests fréquents** : Comparer périodiquement avec full refresh
2. **Monitoring** : Surveiller la fraîcheur et la qualité
3. **Documentation** : Documenter la logique incrémentale
4. **Backfill** : Prévoir une stratégie de rattrapage

### ❌ Pièges à éviter

1. **Pas de unique_key** : Risque de doublons
2. **Logique complexe** : Difficile à déboguer
3. **Pas de tests** : Dérive silencieuse
4. **Oubli du full refresh** : Accumulation d'erreurs

## ✅ Validation finale

Vérifiez que vous avez :

- [ ] Modèle incrémental fonctionnel avec timestamps
- [ ] Tests d'insertion et de mise à jour
- [ ] Stratégie de merge configurée
- [ ] Tests de cohérence temporelle
- [ ] Dashboard de monitoring

```bash
# Test complet
dbt test --select tag:incremental
dbt run --select tag:incremental
```

## 🎯 Points clés à retenir

1. **Performance** : Les modèles incrémentaux sont essentiels pour de gros volumes
2. **Timestamps** : Indispensables pour identifier les nouveaux/modifiés
3. **Tests** : Plus critiques que pour les modèles standard
4. **Maintenance** : Full refresh périodique nécessaire
5. **Monitoring** : Surveillance de la fraîcheur et de la qualité

---

🎉 **Félicitations !** Vous avez terminé le cours DBT Cloud. Vous maîtrisez maintenant :
- Configuration complète d'un projet DBT Cloud
- Transformation de données avec les bonnes pratiques
- Gestion des matérialisations et optimisations
- Tests de qualité et unitaires
- Modèles incrémentaux pour la performance

## 📚 Ressources pour aller plus loin

- [Documentation officielle DBT](https://docs.getdbt.com/)
- [DBT Cloud Features](https://www.getdbt.com/product/dbt-cloud/)
- [Communauté DBT](https://discourse.getdbt.com/)
- [Packages DBT](https://hub.getdbt.com/)