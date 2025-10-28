# Chapitre 3 : Premiers modèles

## 🎯 Objectifs
- Comprendre la philosophie des modèles DBT
- Créer nos premiers modèles de curation
- Transformer les données raw en données exploitables
- Appliquer les bonnes pratiques SQL

## 🏗️ Architecture des données

Notre architecture suivra le pattern classique :

```
RAW → CURATION → ANALYTICS
```

- **RAW** : Données brutes importées de Snowflake
- **CURATION** : Données nettoyées et standardisées
- **ANALYTICS** : Données agrégées pour l'analyse

## 📋 Création du modèle `curation_hosts`

### 1. Créer le fichier du modèle

Dans DBT Cloud, créez le fichier `models/curation/curation_hosts.sql` :

```sql
-- Modèle de curation pour les données des hôtes Airbnb
-- Nettoie et standardise les données raw des hôtes

WITH hosts_raw AS (
    SELECT
        host_id,
        -- Gestion des noms anonymes (1 caractère = anonyme)
        CASE
            WHEN LEN(host_name) = 1 THEN 'Anonyme'
            ELSE host_name
        END AS host_name,

        host_since,
        host_location,

        -- Extraction de la ville (première partie avant la virgule)
        SPLIT_PART(host_location, ',', 1) AS host_city,

        -- Extraction du pays (deuxième partie après la virgule)
        SPLIT_PART(host_location, ',', 2) AS host_country,

        -- Conversion du taux de réponse en entier
        TRY_CAST(REPLACE(host_response_rate, '%', '') AS INTEGER) AS response_rate,

        -- Conversion en booléen pour superhost
        host_is_superhost = 't' AS is_superhost,

        host_neighbourhood,

        -- Conversion en booléen pour identité vérifiée
        host_identity_verified = 't' AS is_identity_verified

    FROM airbnb.raw.hosts
)

SELECT * FROM hosts_raw;
```

### 2. Explication des transformations

| Transformation | Logique | Pourquoi |
|----------------|---------|----------|
| **host_name** | Remplace les noms d'1 caractère par "Anonyme" | Protection de la vie privée |
| **host_city/country** | Split sur la virgule | Séparation géographique |
| **response_rate** | Supprime '%' et convertit en INT | Calculs numériques |
| **is_superhost** | Convertit 't'/'f' en TRUE/FALSE | Type boolean plus clair |
| **is_identity_verified** | Convertit 't'/'f' en TRUE/FALSE | Type boolean plus clair |

## 📋 Création du modèle `curation_listings`

### 1. Créer le fichier du modèle

Créez le fichier `models/curation/curation_listings.sql` :

```sql
-- Modèle de curation pour les données des listings Airbnb
-- Nettoie et standardise les données raw des listings

WITH listings_raw AS 
	(SELECT 
		id AS listing_id,
		listing_url,
		name,
		description,
		description IS NOT NULL has_description,
		neighbourhood_overview,
		neighbourhood_overview IS NOT NULL AS has_neighrbourhood_description,
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
        try_cast(split_part(price, '$', 1) as float) as price,
		minimum_nights,
		maximum_nights
	FROM airbnb.raw.listings )
SELECT *
FROM listings_raw
```

## 📋 Création du modèle `curation_reviews`

### 1. Créer le fichier du modèle

Créez le fichier `models/curation/curation_reviews.sql` :

```sql
-- Modèle de curation pour les données des reviews Airbnb
-- Nettoie et standardise les données raw des reviews

WITH curation_raw AS
( SELECT listing_id, date AS review_date FROM airbnb.raw.reviews)

SELECT listing_id,  review_date , count(*) AS nb_reviews FROM curation_raw
GROUP BY ALL
```


### 2. Explication des transformations

| Transformation | Logique | Pourquoi |
|----------------|---------|----------|
| **listing_id** | Renomme `id` | Nom plus explicite |
| **has_description** | Booléen si description existe | Indicateur de qualité |
| **has_neighbourhood_description** | Booléen si overview existe | Indicateur de qualité |
| **price** | Extrait le nombre après '$' | Calculs numériques |

## 🚀 Exécution des modèles

### 1. Compiler les modèles

Dans le terminal DBT Cloud :

```bash
# Compiler pour vérifier la syntaxe
dbt build
```

## 🔍 Exploration des données transformées

### 1. Dans Snowflake

Connectez-vous à Snowflake et explorez vos nouvelles tables :

**Note** : Les tables `AIRBNB.RAW.CURATION_HOSTS`, `AIRBNB.RAW.CURATION_LISTINGS` et `AIRBNB.RAW.CURATION_REVIEWS` sont des vues matérialisées.

```sql
-- Vérifier la table des hôtes curée
SELECT count(*) FROM AIRBNB.RAW.CURATION_HOSTS;
SELECT count(*) FROM AIRBNB.RAW.HOSTS;
```

## 🎨 Bonnes pratiques appliquées

### 1. Structure SQL
- **CTE** : Utilisation de Common Table Expressions pour la lisibilité
- **Nommage** : Noms de colonnes explicites et cohérents
- **Commentaires** : Documentation du code SQL

### 2. Transformations
- **Type safety** : Utilisation de TRY_CAST pour éviter les erreurs
- **Null handling** : Gestion explicite des valeurs nulles
- **Business logic** : Application de règles métier claires

### 3. Performance
- **Sélection** : Sélection explicite des colonnes nécessaires
- **Filtres** : Application de filtres en amont quand possible

## ❗ Résolution des erreurs courantes

### Erreur de compilation
```
Compilation Error in model 'curation_hosts'
```
**Solution** : Vérifiez la syntaxe SQL et l'existence des sources

### Erreur de référence de source
```
Source 'raw_airbnb_data.hosts' not found
```
**Solution** : Nous configurerons les sources dans le Chapitre 5

### Erreur de type
```
Cannot cast 'N/A' to INTEGER
```
**Solution** : Utilisez TRY_CAST au lieu de CAST

## 🎯 Points clés à retenir

1. **Transformation progressive** : Raw → Curation → Analytics
2. **Documentation** : Commentaires SQL explicites
3. **Robustesse** : Gestion des erreurs avec TRY_CAST
4. **Lisibilité** : Structure CTE claire
5. **Validation** : Toujours vérifier les résultats

## ✅ Checklist de validation

- [ ] Les deux modèles se compilent sans erreur
- [ ] Les deux modèles s'exécutent avec succès
- [ ] Les données transformées sont cohérentes
- [ ] Les types de données sont corrects
- [ ] Les valeurs nulles sont gérées appropriément

---

**Prochaine étape** : [Chapitre 4 - Matérialisations](chapitre-4-materialisations.md)