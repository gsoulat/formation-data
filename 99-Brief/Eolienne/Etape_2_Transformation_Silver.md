# Étape 3 : Transformation Bronze → Silver

**Durée estimée :** 60-75 minutes  
**Difficulté :** ⭐⭐ Moyen

---

## 🎯 Objectifs de cette étape

À la fin de cette étape, vous aurez :

- ✅ Compris les transformations de la couche Silver
- ✅ Créé un notebook de transformation PySpark
- ✅ Créé un notebook de transformation SQL (optionnel)
- ✅ Nettoyé et standardisé les données
- ✅ Enrichi les données avec des colonnes calculées
- ✅ Chargé les données transformées dans le Lakehouse Silver
- ✅ Versionné vos notebooks sur GitHub

---

## 📋 Prérequis

- ✅ [Étape 2 : Ingestion Bronze](03_Etape_2_Ingestion_Bronze.md) complétée
- ✅ Données présentes dans le Lakehouse Bronze (≥2 jours)

---

## 📚 Comprendre les transformations Silver

### Objectif de la couche Silver

La couche Silver transforme les données brutes en données **nettoyées, validées et enrichies** :

**Transformations appliquées :**

1. **🔢 Nettoyage numérique**
   - Arrondir `wind_speed` à 2 décimales
   - Arrondir `energy_produced` à 2 décimales

2. **📅 Enrichissement temporel**
   - Extraire : `day`, `month`, `quarter`, `year`
   - Calculer la période de la journée (`time_period`)

3. **🕐 Décomposition du temps**
   - Extraire : `hour_of_day`, `minute_of_hour`, `second_of_minute`
   - Corriger le format de `time` (remplacer "-" par ":")

4. **✨ Calculs métier**
   - `time_period` : Morning (5-11h), Afternoon (12-16h), Evening (17-20h), Night (autres)

---

## 💻 Tâche 1 : Créer le notebook de transformation (PySpark)

### 1.1 - Créer un nouveau Notebook

1. **Dans votre Workspace** `WindPowerAnalytics`
2. **Cliquez sur "+ New item" → "Notebook"**
3. **Nom** : `NB_Bronze_To_Silver_Transformations_Python`
4. **Cliquez sur "Create"**

### 1.2 - Attacher les Lakehouses

Vous devez attacher **2 Lakehouses** :

1. **Cliquez sur "Add lakehouse"**
2. **Ajoutez** `LH_Wind_Power_Bronze` (lecture)
3. **Ajoutez** `LH_Wind_Power_Silver` (écriture)

> 💡 Vous pouvez attacher plusieurs Lakehouses à un même notebook.

---

## 📝 Tâche 2 : Écrire le code de transformation

### 2.1 - Cellule Markdown : Documentation

```markdown
# Transformation Bronze → Silver

## 📋 Objectif
Nettoyer, standardiser et enrichir les données brutes du Lakehouse Bronze.

## 🔄 Transformations appliquées
1. **Nettoyage numérique** : Arrondi à 2 décimales
2. **Enrichissement temporel** : Extraction jour/mois/année/trimestre
3. **Standardisation** : Correction du format de time
4. **Calcul métier** : Période de la journée basée sur l'heure

## 📦 Dépendances
- **Input** : `LH_Wind_Power_Bronze.dbo.wind_power`
- **Output** : `LH_Wind_Power_Silver.dbo.wind_power`

## ⚙️ Mode de sauvegarde
- **Mode** : Overwrite (écrasement complet)
- **Raison** : Simplicité pour ce projet pédagogique
```

### 2.2 - Cellule 1 : Imports

```python
from pyspark.sql.functions import (
    round, col, dayofmonth, month, year, quarter, 
    substring, when, regexp_replace
)
```

### 2.3 - Cellule 2 : Charger les données depuis Bronze

```python
# Chemin vers la table Bronze
bronze_table_path = "abfss://WindPowerAnalytics@onelake.dfs.fabric.microsoft.com/LH_Wind_Power_Bronze.Lakehouse/Tables/dbo/wind_power"

# Charger les données
df = spark.read.format("delta").load(bronze_table_path)

# Afficher le schéma et un aperçu
print("📊 Schéma des données Bronze :")
df.printSchema()

print(f"\n📈 Nombre de lignes : {df.count()}")

print("\n🔍 Aperçu des 5 premières lignes :")
df.show(5, truncate=False)
```

**Exécutez** cette cellule pour vérifier que les données se chargent correctement.

### 2.4 - Cellule 3 : Appliquer les transformations

```python
# Appliquer toutes les transformations en une seule opération chaînée
df_transformed = (df
    # 🔢 Arrondir les valeurs numériques à 2 décimales
    .withColumn("wind_speed", round(col("wind_speed"), 2))
    .withColumn("energy_produced", round(col("energy_produced"), 2))
    
    # 📅 Extraire les composants de date
    .withColumn("day", dayofmonth(col("date")))
    .withColumn("month", month(col("date")))
    .withColumn("quarter", quarter(col("date")))
    .withColumn("year", year(col("date")))
    
    # 🕐 Corriger le format de time (remplacer - par :)
    .withColumn("time", regexp_replace(col("time"), "-", ":"))
    
    # ⏰ Extraire les composants de temps
    .withColumn("hour_of_day", substring(col("time"), 1, 2).cast("int"))
    .withColumn("minute_of_hour", substring(col("time"), 4, 2).cast("int"))
    .withColumn("second_of_minute", substring(col("time"), 7, 2).cast("int"))
    
    # 🌅 Calculer la période de la journée
    .withColumn("time_period", 
        when((col("hour_of_day") >= 5) & (col("hour_of_day") < 12), "Morning")
        .when((col("hour_of_day") >= 12) & (col("hour_of_day") < 17), "Afternoon")
        .when((col("hour_of_day") >= 17) & (col("hour_of_day") < 21), "Evening")
        .otherwise("Night")
    )
)

print("✅ Transformations appliquées avec succès !")
```

### 2.5 - Cellule 4 : Afficher un échantillon transformé

```python
# Afficher un échantillon des données transformées
print("📊 Aperçu des données transformées :")
df_transformed.select(
    "date", "time", "turbine_name", 
    "wind_speed", "energy_produced", 
    "day", "month", "year", "quarter",
    "hour_of_day", "time_period"
).show(10)

print(f"\n📈 Nombre de colonnes : {len(df_transformed.columns)}")
print(f"📋 Nouvelles colonnes ajoutées : day, month, quarter, year, hour_of_day, minute_of_hour, second_of_minute, time_period")
```

### 2.6 - Cellule 5 : Vérifications de qualité

```python
from pyspark.sql.functions import count, when, isnan, col, min as spark_min, max as spark_max

# Vérifier qu'il n'y a pas de valeurs nulles dans les colonnes critiques
print("=== 🔍 Vérification des valeurs nulles ===")
null_counts = df_transformed.select([
    count(when(col(c).isNull(), c)).alias(c) 
    for c in ["wind_speed", "energy_produced", "day", "month", "year", "time_period"]
])
null_counts.show()

# Vérifier les valeurs uniques de time_period
print("\n=== 📊 Distribution des périodes de la journée ===")
df_transformed.groupBy("time_period").count().orderBy("count", ascending=False).show()

# Vérifier les plages de dates
print("\n=== 📅 Plage de dates ===")
df_transformed.select(
    spark_min("date").alias("Date minimale"),
    spark_max("date").alias("Date maximale")
).show()

# Statistiques descriptives
print("\n=== 📈 Statistiques sur les mesures ===")
df_transformed.select("wind_speed", "energy_produced").describe().show()
```

### 2.7 - Cellule 6 : Sauvegarder dans Silver

```python
# Chemin vers la table Silver
silver_table_path = "abfss://WindPowerAnalytics@onelake.dfs.fabric.microsoft.com/LH_Wind_Power_Silver.Lakehouse/Tables/dbo/wind_power"

# Sauvegarder en mode overwrite (écrasement complet)
df_transformed.write.format("delta").mode("overwrite").save(silver_table_path)

print("✅ Données transformées et sauvegardées dans Silver")
print(f"📊 Nombre de lignes sauvegardées : {df_transformed.count()}")
```

---

## 🗃️ Tâche 3 : Créer la version SQL (Optionnel mais recommandé)

### 3.1 - Créer un nouveau Notebook SQL

1. **Créez un nouveau Notebook** : `NB_Bronze_To_Silver_Transformations_SQL`
2. **Attachez les 2 Lakehouses** (Bronze et Silver)

### 3.2 - Cellule 1 : Créer une vue temporaire

```sql
%%sql
-- Créer une vue temporaire de la table Bronze
CREATE OR REPLACE TEMPORARY VIEW bronze_wind_power AS
SELECT *
FROM WindPowerAnalytics.LH_Wind_Power_Bronze.dbo.wind_power;
```

### 3.3 - Cellule 2 : Appliquer les transformations SQL

```sql
%%sql
-- Nettoyer et enrichir les données
CREATE OR REPLACE TEMPORARY VIEW transformed_wind_power AS
SELECT
    production_id,
    date,
    turbine_name,
    capacity,
    location_name,
    latitude,
    longitude,
    region,
    status,
    responsible_department,
    wind_direction,
    
    -- 🔢 Arrondi des valeurs numériques
    ROUND(wind_speed, 2) AS wind_speed,
    ROUND(energy_produced, 2) AS energy_produced,
    
    -- 📅 Extraction des composants de date
    DAY(date) AS day,
    MONTH(date) AS month,
    QUARTER(date) AS quarter,
    YEAR(date) AS year,
    
    -- 🕐 Correction du format de time
    REGEXP_REPLACE(time, '-', ':') AS time,
    
    -- ⏰ Extraction des composants de temps
    CAST(SUBSTRING(time, 1, 2) AS INT) AS hour_of_day,
    CAST(SUBSTRING(time, 4, 2) AS INT) AS minute_of_hour,
    CAST(SUBSTRING(time, 7, 2) AS INT) AS second_of_minute,
    
    -- 🌅 Calcul de la période de la journée
    CASE
        WHEN CAST(SUBSTRING(time, 1, 2) AS INT) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN CAST(SUBSTRING(time, 1, 2) AS INT) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN CAST(SUBSTRING(time, 1, 2) AS INT) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS time_period
    
FROM bronze_wind_power;
```

### 3.4 - Cellule 3 : Supprimer l'ancienne table Silver

```sql
%%sql
-- Supprimer l'ancienne table Silver si elle existe
DROP TABLE IF EXISTS WindPowerAnalytics.LH_Wind_Power_Silver.dbo.wind_power;
```

### 3.5 - Cellule 4 : Créer la nouvelle table Silver

```sql
%%sql
-- Créer la nouvelle table Silver avec les données transformées
CREATE TABLE WindPowerAnalytics.LH_Wind_Power_Silver.dbo.wind_power
USING delta
AS
SELECT * FROM transformed_wind_power;
```

### 3.6 - Cellule 5 : Vérification

```sql
%%sql
-- Vérifier que la table a été créée avec succès
SELECT 
    COUNT(*) as total_rows,
    MIN(date) as min_date,
    MAX(date) as max_date,
    COUNT(DISTINCT turbine_name) as turbine_count
FROM WindPowerAnalytics.LH_Wind_Power_Silver.dbo.wind_power;
```

---

## ✅ Tâche 4 : Vérifier les données dans Silver

### 4.1 - Explorer le Lakehouse Silver

1. **Ouvrez le Lakehouse** `LH_Wind_Power_Silver`
2. **Naviguez vers** Tables → dbo → wind_power
3. **Cliquez sur la table** pour voir son contenu

### 4.2 - Vérifier les nouvelles colonnes

Vous devriez voir les colonnes suivantes ajoutées :
- `day`, `month`, `quarter`, `year`
- `hour_of_day`, `minute_of_hour`, `second_of_minute`
- `time_period`

**📸 Capture d'écran à prendre :** `03_silver_table_schema.png`

### 4.3 - Comparer avec Bronze

| Aspect | Bronze | Silver |
|--------|--------|--------|
| Nombre de colonnes | 14 | 22 (+8) |
| Format time | avec "-" | avec ":" |
| Valeurs numériques | Brutes | Arrondies |
| Colonnes temporelles | Basiques | Enrichies |

---

## 🗂️ Tâche 5 : Versionner sur GitHub

### 5.1 - Télécharger les notebooks

1. **Notebook PySpark** : Téléchargez `NB_Bronze_To_Silver_Transformations_Python.ipynb`
2. **Notebook SQL** (si créé) : Téléchargez `NB_Bronze_To_Silver_Transformations_SQL.ipynb`

### 5.2 - Uploader sur GitHub

1. **GitHub** → `notebooks/silver/`
2. **Uploadez les 2 notebooks**
3. **Commit message** : `feat: Add Bronze to Silver transformation notebooks`

**📸 Capture d'écran à prendre :** `03_github_silver_notebooks.png`

---

## ✅ Vérification de l'étape

- [ ] ✅ Notebook PySpark créé et fonctionnel
- [ ] ✅ (Optionnel) Notebook SQL créé et fonctionnel
- [ ] ✅ Table `wind_power` créée dans Silver avec 22 colonnes
- [ ] ✅ Données nettoyées (valeurs arrondies)
- [ ] ✅ Données enrichies (colonnes temporelles)
- [ ] ✅ Format de time corrigé (: au lieu de -)
- [ ] ✅ Vérifications de qualité effectuées
- [ ] ✅ Notebooks versionnés sur GitHub
- [ ] ✅ 2 captures d'écran prises

---

## 🎓 Ce que vous avez appris

- ✅ Utiliser les fonctions PySpark pour transformer des données
- ✅ Créer des colonnes calculées avec `withColumn()`
- ✅ Utiliser les fonctions temporelles (day, month, quarter, year)
- ✅ Appliquer des conditions avec `when().otherwise()`
- ✅ Utiliser les expressions régulières avec `regexp_replace()`
- ✅ Faire la même chose en SQL pour comparer les approches
- ✅ Effectuer des vérifications de qualité de données

---

## 📊 Comparaison PySpark vs SQL

| Aspect | PySpark | SQL |
|--------|---------|-----|
| **Syntaxe** | Méthodes chainées | Déclaratif |
| **Lisibilité** | Peut être verbeux | Très lisible |
| **Performance** | Identique | Identique |
| **Flexibilité** | Très élevée | Bonne |
| **Cas d'usage** | Transformations complexes | Requêtes simples |

> 💡 **Conseil** : Utilisez PySpark pour les transformations complexes et SQL pour les requêtes simples et lisibles.

---

## ⚠️ Problèmes courants et solutions

### Problème 1 : "Colonne not found"

**Cause** : Le schéma de Bronze ne correspond pas au code.

**Solution** :
```python
# Vérifiez les colonnes disponibles
df.printSchema()
df.columns
```

### Problème 2 : "time_period avec des valeurs NULL"

**Cause** : La logique de CASE/when ne couvre pas tous les cas.

**Solution** : Vérifiez que vous avez un `otherwise()` ou `ELSE` pour les cas non couverts.

### Problème 3 : "Performance lente"

**Cause** : Trop de données à traiter.

**Solution** :
```python
# Utilisez le caching pour éviter de recalculer
df_transformed.cache()
df_transformed.count()  # Force l'évaluation
```

---

## 🎯 Prochaine étape

Excellent ! Vos données sont maintenant nettoyées et enrichies dans la couche Silver.

➡️ **[Étape 4 : Transformation Silver → Gold](05_Etape_4_Transformation_Gold.md)**

Dans la prochaine étape, vous allez créer le modèle dimensionnel (star schema) dans la couche Gold.

---

*Étape 3 complétée ✅ | Temps : ~75 min | Total cumulé : ~210 min (~3h30)*
