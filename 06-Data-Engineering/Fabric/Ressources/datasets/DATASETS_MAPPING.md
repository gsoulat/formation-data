# Mapping Datasets - Projets Pratiques

**Guide complet pour utiliser les datasets dans chaque projet**

## Vue d'Ensemble

```
Ressources/datasets/
├── retail_sales.csv     (15 MB)  → Projets 1, 3, 5, 6
├── customers.csv        (1.6 MB) → Projets 1, 3, 5, 6
├── products.csv         (63 KB)  → Projets 1, 3, 6
├── iot_telemetry.json   (2.0 MB) → Projet 2
├── customer_churn.csv   (762 KB) → Projet 4
└── web_logs.json        (17 MB)  → Projet 2 (optionnel)
```

---

## Projet 1 : Lakehouse ETL Pipeline

**Datasets requis :**
- `retail_sales.csv` → Bronze web_sales + store_sales
- `customers.csv` → Bronze customers
- `products.csv` → Bronze products

**Chargement :**
```python
df_sales = spark.read.csv("Files/raw/retail_sales.csv", header=True, inferSchema=True)
df_customers = spark.read.csv("Files/raw/customers.csv", header=True, inferSchema=True)
df_products = spark.read.csv("Files/raw/products.csv", header=True, inferSchema=True)
```

---

## Projet 2 : Real-Time Dashboard

**Datasets requis :**
- `iot_telemetry.json` → Données de capteurs IoT

**Chargement :**
```python
import json
with open("Files/raw/iot_telemetry.json", "r") as f:
    data = json.load(f)
df_telemetry = spark.createDataFrame(data)
```

**Alternative :** Utiliser le simulateur Python fourni dans le README du projet pour générer des données en temps réel.

---

## Projet 3 : Data Warehouse Analytics

**Datasets requis :**
- `retail_sales.csv` → Fact_Sales
- `customers.csv` → Dim_Customer
- `products.csv` → Dim_Product

**Chargement :**
```python
# Créer tables Bronze
df_sales.write.mode("overwrite").saveAsTable("bronze_sales")
df_customers.write.mode("overwrite").saveAsTable("bronze_customers")
df_products.write.mode("overwrite").saveAsTable("bronze_products")

# Transformer en Star Schema (scripts fournis dans README)
```

---

## Projet 4 : ML Pipeline End-to-End

**Datasets requis :**
- `customer_churn.csv` → Données d'entraînement ML

**Caractéristiques :**
- 5000 clients
- ~35% taux de churn
- Features numériques et catégorielles
- Prêt pour feature engineering

**Chargement :**
```python
df_churn = spark.read.csv("Files/raw/customer_churn.csv", header=True, inferSchema=True)
df_churn.write.mode("overwrite").saveAsTable("raw_churn")
```

---

## Projet 5 : Gouvernance et Sécurité

**Datasets requis :**
- `customers.csv` → Tests RLS/GDPR (données personnelles)
- `retail_sales.csv` → Tests RLS par région

**Cas d'usage :**
- Row-Level Security par région
- Dynamic Data Masking sur emails
- GDPR compliance (suppression, anonymisation)

---

## Projet 6 : Migration Synapse vers Fabric

**Datasets requis :**
- `retail_sales.csv` → Simule table Synapse SQL Pool
- `customers.csv` → Simule dimension Synapse
- `products.csv` → Simule dimension Synapse

**Simulation :**
Les CSV simulent un export de Synapse Analytics. Vous les migrez vers Fabric Lakehouse/Warehouse.

---

## Instructions Globales

### 1. Télécharger les Datasets
Depuis ce dossier `Ressources/datasets/`, téléchargez les fichiers nécessaires pour votre projet.

### 2. Uploader dans Fabric
```
1. Ouvrir votre Fabric Workspace
2. Créer/ouvrir un Lakehouse
3. Cliquer sur "Get data" → "Upload files"
4. Uploader dans Files/raw/
```

### 3. Structure Recommandée
```
Votre_Lakehouse/
├── Files/
│   ├── raw/
│   │   ├── retail_sales.csv
│   │   ├── customers.csv
│   │   └── ...
│   └── checkpoints/
└── Tables/
    ├── bronze_xxx
    ├── silver_xxx
    └── gold_xxx
```

### 4. Vérification
```python
# Dans un notebook Fabric
import os
files = os.listdir("/lakehouse/default/Files/raw/")
print(f"Fichiers uploadés: {files}")
```

---

## Génération de Nouvelles Données

Si vous souhaitez générer des datasets personnalisés :

```bash
cd Ressources/datasets/
python generate_all_datasets.py
```

Options du script :
- Modifier `num_records` pour ajuster la taille
- Personnaliser les patterns de données
- Ajouter des colonnes custom

---

## FAQ

**Q: Les datasets sont trop gros pour mon environnement ?**
R: Utilisez un sous-ensemble :
```python
df = df.limit(10000)  # Prendre seulement 10K lignes
```

**Q: Comment simuler des données incrémentales ?**
R: Filtrez par date :
```python
df_batch1 = df.filter(col("date") < "2024-06-01")
df_batch2 = df.filter(col("date") >= "2024-06-01")
```

**Q: Les données ne correspondent pas exactement au projet ?**
R: C'est normal ! Les projets sont des scénarios fictifs. Adaptez les transformations pour correspondre aux colonnes réelles des CSV.
