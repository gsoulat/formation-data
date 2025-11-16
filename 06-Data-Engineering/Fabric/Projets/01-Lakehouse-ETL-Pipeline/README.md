# Projet 1 : Lakehouse ETL Pipeline

## Vue d'ensemble

Dans ce projet, vous allez construire un **pipeline ETL complet** pour une entreprise e-commerce fictive "TechRetail". Vous implémenterez l'architecture **Medallion** (Bronze/Silver/Gold) pour traiter des données de ventes provenant de multiples sources.

**Durée estimée :** 8-10 heures
**Niveau :** Intermédiaire
**Modules prérequis :** 02, 04, 05, 06

## Contexte Business

### L'entreprise : TechRetail

TechRetail est un retailer en ligne vendant des produits électroniques. Ils ont :
- Un site web e-commerce
- 3 magasins physiques
- Une application mobile
- Un système CRM (Salesforce)

### Problématique

Les données sont actuellement **silotées** :
- Ventes web : fichiers CSV quotidiens dans Azure Blob Storage
- Ventes magasins : base SQL Server on-premises
- Données produits : API REST
- Données clients : Salesforce

**Objectif :** Créer une plateforme analytics unifiée dans Fabric avec architecture Medallion.

## Objectifs d'Apprentissage

À la fin de ce projet, vous serez capable de :

- ✅ Créer une architecture Lakehouse Medallion complète
- ✅ Ingérer des données de sources multiples
- ✅ Transformer des données avec Spark
- ✅ Implémenter un chargement incrémental
- ✅ Optimiser les tables Delta (V-Order, partitionnement)
- ✅ Créer des pipelines orchestrés
- ✅ Documenter une solution data engineering

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`retail_sales.csv`** (15 MB, 100K lignes) | Ventes e-commerce avec dates, montants, régions | → bronze_web_sales, bronze_store_sales |
| **`customers.csv`** (1.6 MB, 10K clients) | Clients avec pays, ville, date inscription | → bronze_customers |
| **`products.csv`** (63 KB, 500 produits) | Catalogue produits avec catégories et prix | → bronze_products |

### Chargement des Données dans Fabric

1. **Téléchargez les fichiers** depuis `Ressources/datasets/`
2. **Dans votre Workspace Fabric** :
   - Ouvrez votre Lakehouse
   - Cliquez sur **"Get data" → "Upload files"**
   - Uploadez les 3 fichiers CSV dans le dossier `Files/raw/`
3. **Structure recommandée** :
   ```
   Files/
   ├── raw/
   │   ├── retail_sales.csv
   │   ├── customers.csv
   │   └── products.csv
   ```

### Exemple de Chargement Spark

```python
# Dans un notebook Fabric
df_sales = spark.read.csv("Files/raw/retail_sales.csv", header=True, inferSchema=True)
df_customers = spark.read.csv("Files/raw/customers.csv", header=True, inferSchema=True)
df_products = spark.read.csv("Files/raw/products.csv", header=True, inferSchema=True)

# Vérification
print(f"Ventes: {df_sales.count()} lignes")
print(f"Clients: {df_customers.count()} lignes")
print(f"Produits: {df_products.count()} lignes")
```

## Architecture Cible

```
┌─────────────────────────────────────────────────────────────┐
│                        SOURCES                               │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Azure Blob   │ SQL Server   │ REST API     │ Salesforce     │
│ (CSV files)  │ (on-prem)    │ (Products)   │ (Customers)    │
└──────┬───────┴──────┬───────┴──────┬───────┴────────┬───────┘
       │              │              │                │
       └──────────────┴──────────────┴────────────────┘
                      │
              ┌───────▼────────┐
              │  Data Pipelines│
              └───────┬────────┘
                      │
       ┌──────────────┼──────────────┐
       │              │              │
       ▼              ▼              ▼
┌─────────────┬─────────────┬─────────────┐
│   BRONZE    │   SILVER    │    GOLD     │
│             │             │             │
│  Raw Data   │  Cleaned    │ Aggregated  │
│  As-is      │  Validated  │ Business    │
│  Schema-on- │  Dedup      │ Metrics     │
│  read       │  Enriched   │ Ready for   │
│             │             │ reporting   │
└─────────────┴─────────────┴─────────────┘
              │
              ▼
       ┌──────────────┐
       │  Power BI    │
       │  Dashboards  │
       └──────────────┘
```

## Exigences Fonctionnelles

### Bronze Layer (Raw Data)

**Tables à créer :**

1. **bronze_web_sales**
   - Source : CSV files (Azure Blob)
   - Schéma : order_id, customer_id, product_id, quantity, amount, order_date, source
   - Fréquence : Quotidienne
   - Format : Delta (non-partitionné initialement)

2. **bronze_store_sales**
   - Source : SQL Server
   - Schéma : sale_id, store_id, product_id, quantity, price, sale_datetime
   - Fréquence : Temps réel (simulation: toutes les heures)
   - Chargement : Incrémental (watermark)

3. **bronze_products**
   - Source : REST API
   - Schéma : product_id, name, category, price, stock_level
   - Fréquence : Quotidienne

4. **bronze_customers**
   - Source : Salesforce (simulé avec CSV)
   - Schéma : customer_id, name, email, country, city, signup_date
   - Fréquence : Quotidienne

### Silver Layer (Cleaned & Validated)

**Transformations requises :**

1. **silver_sales_unified**
   - Union de web_sales + store_sales
   - Nettoyage : remove nulls, deduplicate
   - Standardisation des colonnes
   - Validation : amount > 0, valid dates
   - Enrichissement avec données produits et clients

2. **silver_products_clean**
   - Remove duplicates
   - Validation de prix (> 0)
   - Standardisation category (uppercase, trim)

3. **silver_customers_clean**
   - Validation email
   - Deduplicate by email
   - Standardisation country codes

### Gold Layer (Business-Level Aggregates)

**Tables analytiques :**

1. **gold_daily_sales_by_category**
   - Ventes quotidiennes par catégorie de produit
   - Métriques : total_sales, total_orders, avg_order_value

2. **gold_monthly_sales_by_country**
   - Ventes mensuelles par pays
   - Métriques : total_sales, unique_customers, items_sold

3. **gold_product_performance**
   - Performance des produits
   - Métriques : total_revenue, units_sold, avg_price, stock_turnover

4. **gold_customer_rfm**
   - Analyse RFM (Recency, Frequency, Monetary)
   - Pour segmentation clients

## Exigences Techniques

### 1. Data Pipelines

Créer **3 pipelines** :

**Pipeline 1 : `pl_ingest_bronze`**
- Ingestion de toutes les sources vers Bronze
- Parallélisation des Copy activities
- Error handling et logging

**Pipeline 2 : `pl_transform_silver`**
- Appel de notebooks Spark pour transformations
- Bronze → Silver
- Dependencies entre notebooks

**Pipeline 3 : `pl_aggregate_gold`**
- Agrégations pour Gold layer
- Peut utiliser SQL ou Spark

### 2. Notebooks Spark

Créer **4 notebooks** :

**Notebook 1 : `nb_bronze_validation.ipynb`**
- Valider les données brutes
- Data quality checks
- Logging des anomalies

**Notebook 2 : `nb_transform_sales.ipynb`**
- Union et transformation des ventes
- Enrichissement

**Notebook 3 : `nb_transform_dimensions.ipynb`**
- Nettoyage produits et clients

**Notebook 4 : `nb_gold_aggregations.ipynb`**
- Calcul des métriques Gold

### 3. Optimisations

**Requis :**
- Partitionner `silver_sales_unified` par `order_date` (année/mois)
- Activer V-Order sur toutes les tables Silver et Gold
- Utiliser Z-ordering sur `silver_sales_unified` (customer_id, product_id)
- OPTIMIZE régulier
- VACUUM avec retention 7 jours

### 4. Scheduling

**Triggers :**
- Pipeline Bronze : tous les jours à 2h00 (schedule trigger)
- Pipeline Silver : après succès Bronze (tumbling window)
- Pipeline Gold : après succès Silver

### 5. Monitoring

- Logging dans table `metadata.pipeline_runs`
- Suivi des row counts (source vs destination)
- Durée d'exécution
- Alertes en cas d'échec

## Jeux de Données Fournis

Dans le dossier `data/` :

- `web_sales/2024-01-*.csv` (30 jours de ventes web)
- `store_sales_dump.csv` (snapshot SQL Server)
- `products.json` (catalogue produits)
- `customers.csv` (base clients)

**Volumétries :**
- Web sales : ~500 MB (1M lignes)
- Store sales : ~200 MB (400K lignes)
- Products : 10K produits
- Customers : 50K clients

## Livrables Attendus

### 1. Architecture Fabric

- [ ] 3 Lakehouses créés (Bronze, Silver, Gold)
- [ ] Toutes les tables créées avec bon schéma
- [ ] Partitionnement et optimisations appliqués

### 2. Pipelines

- [ ] 3 pipelines fonctionnels
- [ ] Paramétrage et réutilisabilité
- [ ] Error handling implémenté

### 3. Notebooks

- [ ] 4 notebooks documentés
- [ ] Code propre et commenté
- [ ] Logs et validations

### 4. Documentation

- [ ] Schéma d'architecture (draw.io, Visio)
- [ ] Data dictionary (description des tables/colonnes)
- [ ] Décisions techniques (pourquoi Bronze/Silver/Gold, choix de partitionnement, etc.)
- [ ] Guide de déploiement

### 5. Tests

- [ ] Tests de validation des données
- [ ] Tests de performance (temps d'exécution)
- [ ] Tests d'intégrité (referential integrity)

## Guide de Démarrage

### Étape 1 : Setup environnement (1h)
1. Créer un workspace Fabric "TechRetail-Analytics"
2. Créer 3 Lakehouses (Bronze, Silver, Gold)
3. Uploader les datasets dans Bronze/Files/

### Étape 2 : Bronze Layer (2h)
1. Créer les pipelines d'ingestion
2. Copier les données vers tables Bronze
3. Valider les schémas

### Étape 3 : Silver Layer (3h)
1. Créer les notebooks de transformation
2. Implémenter la logique de nettoyage
3. Enrichissement des données
4. Tests de qualité

### Étape 4 : Gold Layer (2h)
1. Créer les agrégations
2. Calculer les métriques business
3. Optimiser les tables

### Étape 5 : Orchestration (1h)
1. Chaîner les pipelines
2. Configurer les triggers
3. Tester end-to-end

### Étape 6 : Optimisation & Documentation (1h)
1. Appliquer V-Order, partitionnement
2. Mesurer les gains
3. Documenter la solution

## Critères de Réussite

| Critère | Points | Détails |
|---------|--------|---------|
| **Architecture** | 20 | Medallion correctement implémenté |
| **Ingestion** | 15 | Toutes sources intégrées |
| **Transformations** | 20 | Silver layer propre et validé |
| **Agrégations** | 15 | Gold layer pertinent |
| **Optimisation** | 15 | V-Order, partitionnement |
| **Orchestration** | 10 | Pipelines qui fonctionnent |
| **Documentation** | 5 | Clair et complet |
| **TOTAL** | 100 | |

**Passage :** 70/100

## Bonus (Optionnel)

Pour aller plus loin :

- [ ] Implémenter un véritable CDC depuis SQL Server
- [ ] Créer un dashboard Power BI sur Gold layer
- [ ] Ajouter des tests unitaires pour les transformations
- [ ] Implémenter Data Activator pour alertes
- [ ] Git integration et CI/CD

## Ressources

### Documentation
- [Module 02 : Lakehouse](../../02-Lakehouse/)
- [Module 04 : Data Pipelines](../../04-Data-Pipelines/)
- [Module 06 : Notebooks Spark](../../06-Notebooks-Spark/)

### Liens externes
- [Medallion Architecture](https://learn.microsoft.com/azure/databricks/lakehouse/medallion)
- [Delta Lake best practices](https://docs.delta.io/latest/best-practices.html)

## Solution de Référence

Une solution complète est disponible dans le dossier `solution/`.

**Attention :** Essayez de résoudre le projet par vous-même avant de consulter la solution !

---

**Prêt à commencer ?** Consultez le fichier [instructions.md](./instructions.md) pour le guide pas-à-pas !

[⬅️ Retour aux Projets](../README.md)
