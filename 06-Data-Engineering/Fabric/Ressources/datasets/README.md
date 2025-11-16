# Datasets pour Exercices Fabric

Ce guide explique comment obtenir et préparer les jeux de données pour les exercices pratiques.

---

## ⭐ DATASETS PRÉ-GÉNÉRÉS (Prêts à l'Emploi)

**Ces fichiers sont déjà générés et disponibles dans ce dossier !**

| Fichier | Taille | Lignes | Projets |
|---------|--------|--------|---------|
| **`retail_sales.csv`** | 15 MB | 100,000 | 1, 3, 5, 6 |
| **`customers.csv`** | 1.6 MB | 10,000 | 1, 3, 5, 6 |
| **`products.csv`** | 63 KB | 500 | 1, 3, 6 |
| **`iot_telemetry.json`** | 2.0 MB | 10,000 | 2 |
| **`customer_churn.csv`** | 762 KB | 5,000 | 4 |
| **`web_logs.json`** | 17 MB | 50,000 | 2 |

### 📋 Guide de Mapping Complet

**Voir [`DATASETS_MAPPING.md`](./DATASETS_MAPPING.md)** pour :
- Quel dataset utiliser pour quel projet
- Code de chargement copier-coller
- Instructions pas-à-pas
- FAQ

### 🚀 Utilisation Rapide

```python
# Dans un notebook Fabric
# 1. Uploadez les fichiers dans Files/raw/ de votre Lakehouse
# 2. Chargez avec Spark :

df_sales = spark.read.csv("Files/raw/retail_sales.csv", header=True, inferSchema=True)
df_customers = spark.read.csv("Files/raw/customers.csv", header=True, inferSchema=True)
df_products = spark.read.csv("Files/raw/products.csv", header=True, inferSchema=True)

print(f"Ventes: {df_sales.count()} lignes")
print(f"Clients: {df_customers.count()} lignes")
print(f"Produits: {df_products.count()} lignes")
```

### 🔄 Régénérer les Datasets

```bash
python generate_all_datasets.py
```

---

## Datasets Recommandés (Sources Externes)

### 1. Contoso Sales (Officiel Microsoft)

**Source:** [Microsoft Fabric Samples GitHub](https://github.com/microsoft/fabric-samples)

```bash
# Clone the official samples
git clone https://github.com/microsoft/fabric-samples.git
cd fabric-samples
```

Contient:
- Sales transactions
- Customer data
- Product catalog
- Date dimension

### 2. NYC Taxi Data

**Source:** [NYC Open Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

Parfait pour:
- Traitement de gros volumes
- Time series analysis
- Géospatial analytics

```python
# Download via PySpark
url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet"
df = spark.read.parquet(url)
df.write.saveAsTable("lakehouse.taxi_trips")
```

### 3. AdventureWorks (Classic DW Sample)

**Source:** [Microsoft SQL Server Samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works)

Idéal pour:
- Star schema modeling
- DAX measures
- Power BI reports

### 4. Sample IoT Telemetry Generator

**Script Python pour générer des données IoT:**

```python
import json
import random
from datetime import datetime, timedelta

def generate_iot_data(num_devices=10, num_records=1000):
    """Generate sample IoT telemetry data"""
    data = []
    base_time = datetime.now()

    for i in range(num_records):
        record = {
            "device_id": f"sensor_{random.randint(1, num_devices):03d}",
            "temperature": round(20 + random.gauss(0, 5), 2),
            "humidity": round(50 + random.gauss(0, 15), 2),
            "pressure": round(1013 + random.gauss(0, 10), 2),
            "timestamp": (base_time - timedelta(minutes=i)).isoformat() + "Z"
        }
        data.append(record)

    return data

# Generate and save
iot_data = generate_iot_data(num_devices=20, num_records=10000)
with open("iot_telemetry.json", "w") as f:
    json.dump(iot_data, f, indent=2)
```

### 5. Sample Retail Data Generator

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def generate_retail_data(num_transactions=100000):
    """Generate realistic retail sales data"""

    np.random.seed(42)

    # Generate dates
    start_date = datetime(2023, 1, 1)
    dates = [start_date + timedelta(days=int(x)) for x in np.random.randint(0, 730, num_transactions)]

    # Products and categories
    products = {
        "Electronics": ["Laptop", "Phone", "Tablet", "Headphones", "Camera"],
        "Clothing": ["T-Shirt", "Jeans", "Jacket", "Shoes", "Hat"],
        "Home": ["Chair", "Table", "Lamp", "Rug", "Curtains"],
        "Sports": ["Basketball", "Tennis Racket", "Yoga Mat", "Dumbbells", "Bike"]
    }

    data = []
    for i in range(num_transactions):
        category = np.random.choice(list(products.keys()))
        product = np.random.choice(products[category])

        # Price based on category
        base_prices = {"Electronics": 500, "Clothing": 50, "Home": 150, "Sports": 100}
        price = base_prices[category] * (0.5 + np.random.random())

        data.append({
            "transaction_id": f"TXN{i:08d}",
            "date": dates[i].strftime("%Y-%m-%d"),
            "customer_id": f"CUST{np.random.randint(1, 5001):05d}",
            "product": product,
            "category": category,
            "quantity": np.random.randint(1, 5),
            "unit_price": round(price, 2),
            "discount": round(np.random.choice([0, 0, 0, 0.1, 0.2, 0.3]), 2),
            "region": np.random.choice(["North", "South", "East", "West"])
        })

    df = pd.DataFrame(data)
    df["total_amount"] = df["quantity"] * df["unit_price"] * (1 - df["discount"])

    return df

# Generate and save
retail_df = generate_retail_data(100000)
retail_df.to_csv("retail_sales.csv", index=False)
retail_df.to_parquet("retail_sales.parquet", index=False)
```

## Chargement dans Fabric

### Via Upload UI
1. Ouvrir Lakehouse dans Fabric
2. Files → Upload → Upload folder/files
3. Sélectionner les fichiers CSV/Parquet

### Via Notebook
```python
# Read local files uploaded to Lakehouse Files
df = spark.read.csv("Files/retail_sales.csv", header=True, inferSchema=True)

# Save as Delta table
df.write.format("delta").saveAsTable("lakehouse.retail_sales")
```

### Via Data Pipeline
1. Créer Data Pipeline
2. Copy activity: Source = Local file, Sink = Lakehouse table
3. Exécuter le pipeline

## Datasets Publics Additionnels

| Dataset | Source | Use Case |
|---------|--------|----------|
| **Kaggle Datasets** | [kaggle.com/datasets](https://www.kaggle.com/datasets) | Variété de scénarios |
| **UCI ML Repository** | [archive.ics.uci.edu](https://archive.ics.uci.edu/ml/datasets.php) | ML et analytics |
| **AWS Open Data** | [registry.opendata.aws](https://registry.opendata.aws/) | Big data |
| **Google BigQuery Public** | [cloud.google.com/bigquery/public-data](https://cloud.google.com/bigquery/public-data) | Datasets massifs |
| **data.gov** | [data.gov](https://data.gov/) | Données gouvernementales US |

## Structure Recommandée

```
lakehouse/
├── Files/
│   ├── raw/
│   │   ├── retail_sales.csv
│   │   ├── iot_telemetry.json
│   │   └── customers.json
│   └── staging/
│       └── processed_data/
└── Tables/
    ├── bronze_sales
    ├── silver_sales_cleaned
    └── gold_sales_aggregated
```

## Tailles de Données par Exercice

| Exercice | Taille Recommandée | Lignes |
|----------|-------------------|--------|
| Tests rapides | Small | 1K - 10K |
| Exercices modules | Medium | 100K - 1M |
| Projets | Large | 1M - 10M |
| Tests performance | XLarge | 10M+ |

## Notes Importantes

- **Performance**: Pour les exercices, 100K-1M lignes suffisent
- **Coûts**: Utiliser des capacités trial pour les tests
- **Stockage**: OneLake optimise automatiquement le stockage
- **Format**: Préférer Parquet/Delta pour les performances

---

[⬅️ Retour aux ressources](../README.md)
