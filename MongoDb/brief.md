# 🍃 Brief Pratique MongoDB - Data Engineering

**Durée estimée :** 6 heures
**Niveau :** Débutant à Intermédiaire
**Modalité :** Pratique individuelle

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :
- Installer et configurer MongoDB (local et cloud)
- Maîtriser les opérations CRUD
- Créer des pipelines d'agrégation complexes
- Optimiser les performances avec les index
- Modéliser des données pour MongoDB
- Intégrer MongoDB dans des pipelines Data Engineering Python

---

## 📋 Contexte

Vous êtes Data Engineer chez **DataStream Analytics**. L'entreprise a décidé d'adopter MongoDB pour stocker et analyser des données semi-structurées provenant de diverses sources (APIs, logs, IoT). Votre mission est de mettre en place une solution MongoDB complète pour supporter les besoins data de l'entreprise.

---

## 🚀 Partie 1 : Installation et configuration (1h)

### Tâche 1.1 : Installer MongoDB avec Docker

**Instructions :**

1. **Créer un fichier `docker-compose.yml` :**

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb_dev
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: SecurePass123
      MONGO_INITDB_DATABASE: dataeng
    volumes:
      - mongodb_data:/data/db
      - ./mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js
    restart: unless-stopped

  mongo-express:
    image: mongo-express:latest
    container_name: mongo_express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: SecurePass123
      ME_CONFIG_MONGODB_URL: mongodb://admin:SecurePass123@mongodb:27017/
      ME_CONFIG_BASICAUTH: false
    depends_on:
      - mongodb
    restart: unless-stopped

volumes:
  mongodb_data:
```

2. **Créer un fichier `mongo-init.js` pour initialiser les données :**

```javascript
// Créer un utilisateur pour la base de données dataeng
db = db.getSiblingDB('dataeng');

db.createUser({
  user: 'dataeng_user',
  pwd: 'DataPass123',
  roles: [
    {
      role: 'readWrite',
      db: 'dataeng'
    }
  ]
});

// Créer une collection et insérer des données de test
db.createCollection('users');

db.users.insertMany([
  {
    name: "Alice Dupont",
    email: "alice.dupont@example.com",
    age: 28,
    department: "Data Engineering",
    skills: ["Python", "SQL", "MongoDB"],
    salary: 55000,
    hire_date: new Date("2022-01-15")
  },
  {
    name: "Bob Martin",
    email: "bob.martin@example.com",
    age: 32,
    department: "Data Science",
    skills: ["Python", "R", "Machine Learning"],
    salary: 65000,
    hire_date: new Date("2020-06-20")
  },
  {
    name: "Charlie Brown",
    email: "charlie.brown@example.com",
    age: 25,
    department: "Data Engineering",
    skills: ["Java", "Spark", "Kafka"],
    salary: 50000,
    hire_date: new Date("2023-03-10")
  }
]);

print("✅ Base de données initialisée avec succès");
```

3. **Lancer les conteneurs :**

```bash
# Démarrer MongoDB et Mongo Express
docker-compose up -d

# Vérifier que les conteneurs sont lancés
docker-compose ps

# Voir les logs
docker-compose logs mongodb
```

4. **Tester la connexion :**

```bash
# Se connecter au shell MongoDB
docker exec -it mongodb_dev mongosh -u admin -p SecurePass123

# Dans le shell MongoDB
show dbs
use dataeng
db.users.find()
exit
```

5. **Accéder à Mongo Express :**
   - Ouvrir http://localhost:8081 dans le navigateur
   - Explorer la base de données graphiquement

**Critères de validation :**
- ✅ Conteneurs MongoDB et Mongo Express lancés
- ✅ Connexion réussie au shell MongoDB
- ✅ Données initiales visibles dans la collection users
- ✅ Mongo Express accessible sur http://localhost:8081

---

### Tâche 1.2 : Configurer l'environnement Python

**Instructions :**

1. **Créer un environnement virtuel :**

```bash
# Créer un dossier pour le projet
mkdir mongodb-data-engineering
cd mongodb-data-engineering

# Créer un environnement virtuel
python -m venv venv

# Activer l'environnement
# macOS/Linux:
source venv/bin/activate
# Windows:
venv\Scripts\activate
```

2. **Créer un fichier `requirements.txt` :**

```
pymongo==4.6.0
pandas==2.1.0
python-dotenv==1.0.0
faker==20.0.0
```

3. **Installer les dépendances :**

```bash
pip install -r requirements.txt
```

4. **Créer un fichier `.env` pour les credentials :**

```
MONGODB_URI=mongodb://admin:SecurePass123@localhost:27017/
DATABASE_NAME=dataeng
COLLECTION_NAME=users
```

5. **Créer un script `test_connection.py` :**

```python
from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Charger les variables d'environnement
load_dotenv()

# Connexion à MongoDB
uri = os.getenv('MONGODB_URI')
client = MongoClient(uri)

try:
    # Tester la connexion
    client.admin.command('ping')
    print("✅ Connexion à MongoDB réussie!")

    # Lister les bases de données
    dbs = client.list_database_names()
    print(f"📚 Bases de données disponibles: {dbs}")

    # Accéder à la base de données
    db = client[os.getenv('DATABASE_NAME')]

    # Lister les collections
    collections = db.list_collection_names()
    print(f"📁 Collections: {collections}")

    # Compter les documents dans users
    count = db.users.count_documents({})
    print(f"👥 Nombre d'utilisateurs: {count}")

    # Afficher un utilisateur
    user = db.users.find_one()
    print(f"👤 Premier utilisateur: {user['name']} - {user['email']}")

except Exception as e:
    print(f"❌ Erreur: {e}")

finally:
    client.close()
    print("🔒 Connexion fermée")
```

6. **Exécuter le script :**

```bash
python test_connection.py
```

**Critères de validation :**
- ✅ Environnement virtuel créé et activé
- ✅ Dépendances installées
- ✅ Script test_connection.py exécuté avec succès
- ✅ Connexion MongoDB fonctionnelle depuis Python

---

## 📝 Partie 2 : Opérations CRUD et requêtes (1h30)

### Tâche 2.1 : Insérer des données (Create)

**Scénario :** Vous devez importer des données de ventes dans MongoDB.

**Instructions :**

1. **Créer un fichier `insert_data.py` :**

```python
from pymongo import MongoClient
from faker import Faker
from datetime import datetime, timedelta
import random

fake = Faker('fr_FR')

# Connexion
client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']

# Collection sales
sales_collection = db['sales']

# Générer 100 ventes fictives
sales = []

for i in range(100):
    sale = {
        "transaction_id": f"TRX{str(i+1).zfill(5)}",
        "customer": {
            "name": fake.name(),
            "email": fake.email(),
            "city": fake.city()
        },
        "products": [
            {
                "name": random.choice(["Laptop", "Mouse", "Keyboard", "Monitor", "Headset"]),
                "quantity": random.randint(1, 5),
                "unit_price": round(random.uniform(20, 1500), 2)
            }
            for _ in range(random.randint(1, 3))
        ],
        "total_amount": 0,  # Sera calculé
        "payment_method": random.choice(["Credit Card", "PayPal", "Bank Transfer"]),
        "status": random.choice(["completed", "pending", "cancelled"]),
        "created_at": datetime.now() - timedelta(days=random.randint(0, 365)),
        "metadata": {
            "source": "web",
            "campaign": random.choice(["email", "social", "direct", "ads"])
        }
    }

    # Calculer le montant total
    sale['total_amount'] = sum(
        p['quantity'] * p['unit_price'] for p in sale['products']
    )

    sales.append(sale)

# Insérer en bulk
result = sales_collection.insert_many(sales)
print(f"✅ {len(result.inserted_ids)} ventes insérées")

# Statistiques
total_sales = sum(s['total_amount'] for s in sales)
print(f"💰 Montant total des ventes: {total_sales:,.2f}€")

client.close()
```

2. **Exécuter le script :**

```bash
python insert_data.py
```

3. **Vérifier dans MongoDB Shell :**

```javascript
db.sales.countDocuments()
db.sales.findOne()
```

**Critères de validation :**
- ✅ 100 documents insérés dans la collection sales
- ✅ Structure de données correcte avec sous-documents
- ✅ Montant total calculé

---

### Tâche 2.2 : Requêtes de lecture (Read)

**Instructions :**

Créez un fichier `queries.py` avec les requêtes suivantes :

```python
from pymongo import MongoClient

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== REQUÊTES MONGODB ===\n")

# 1. Toutes les ventes complétées
print("1️⃣ Ventes complétées:")
completed = sales.find({"status": "completed"})
print(f"   Nombre: {sales.count_documents({'status': 'completed'})}")

# 2. Ventes > 500€
print("\n2️⃣ Ventes > 500€:")
high_value = sales.find(
    {"total_amount": {"$gt": 500}},
    {"transaction_id": 1, "total_amount": 1, "_id": 0}
)
for sale in high_value.limit(5):
    print(f"   {sale['transaction_id']}: {sale['total_amount']:.2f}€")

# 3. Ventes à Paris
print("\n3️⃣ Ventes à Paris:")
paris_sales = sales.find({"customer.city": {"$regex": "Paris", "$options": "i"}})
print(f"   Nombre: {sales.count_documents({'customer.city': {'$regex': 'Paris', '$options': 'i'}})}")

# 4. Ventes par carte de crédit en 2024
print("\n4️⃣ Ventes par carte de crédit en 2024:")
from datetime import datetime
start_2024 = datetime(2024, 1, 1)
end_2024 = datetime(2024, 12, 31)

cc_sales = sales.find({
    "payment_method": "Credit Card",
    "created_at": {"$gte": start_2024, "$lte": end_2024}
})
count = sales.count_documents({
    "payment_method": "Credit Card",
    "created_at": {"$gte": start_2024, "$lte": end_2024}
})
print(f"   Nombre: {count}")

# 5. Ventes avec laptop dans les produits
print("\n5️⃣ Ventes contenant un Laptop:")
laptop_sales = sales.find({"products.name": "Laptop"})
print(f"   Nombre: {sales.count_documents({'products.name': 'Laptop'})}")

# 6. Top 5 ventes par montant
print("\n6️⃣ Top 5 ventes:")
top_sales = sales.find(
    {},
    {"transaction_id": 1, "customer.name": 1, "total_amount": 1, "_id": 0}
).sort("total_amount", -1).limit(5)

for i, sale in enumerate(top_sales, 1):
    print(f"   #{i} {sale['transaction_id']}: {sale['customer']['name']} - {sale['total_amount']:.2f}€")

# 7. Ventes entre 100€ et 300€
print("\n7️⃣ Ventes entre 100€ et 300€:")
mid_range = sales.count_documents({
    "total_amount": {"$gte": 100, "$lte": 300}
})
print(f"   Nombre: {mid_range}")

# 8. Ventes avec statut pending ou cancelled
print("\n8️⃣ Ventes pending ou cancelled:")
not_completed = sales.find({
    "status": {"$in": ["pending", "cancelled"]}
})
print(f"   Nombre: {sales.count_documents({'status': {'$in': ['pending', 'cancelled']}})}")

client.close()
```

**Exécuter :**

```bash
python queries.py
```

**Critères de validation :**
- ✅ Toutes les requêtes s'exécutent sans erreur
- ✅ Résultats cohérents avec les données insérées
- ✅ Utilisation correcte des opérateurs ($gt, $in, $regex, etc.)

---

### Tâche 2.3 : Mises à jour (Update)

**Instructions :**

Créez un fichier `updates.py` :

```python
from pymongo import MongoClient
from datetime import datetime

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== MISES À JOUR ===\n")

# 1. Ajouter un champ updated_at à toutes les ventes
result = sales.update_many(
    {},
    {"$set": {"updated_at": datetime.now()}}
)
print(f"1️⃣ Champ updated_at ajouté à {result.modified_count} documents")

# 2. Ajouter une remise de 10% aux ventes > 1000€
result = sales.update_many(
    {"total_amount": {"$gt": 1000}},
    {
        "$set": {"discount_applied": True, "discount_percent": 10},
        "$mul": {"total_amount": 0.9}
    }
)
print(f"2️⃣ Remise appliquée à {result.modified_count} ventes")

# 3. Changer le statut pending en processing
result = sales.update_many(
    {"status": "pending"},
    {"$set": {"status": "processing"}}
)
print(f"3️⃣ {result.modified_count} ventes passées en processing")

# 4. Ajouter un tag "premium" aux ventes > 500€
result = sales.update_many(
    {"total_amount": {"$gt": 500}},
    {"$addToSet": {"tags": "premium"}}
)
print(f"4️⃣ Tag premium ajouté à {result.modified_count} ventes")

# 5. Mettre à jour une vente spécifique
result = sales.update_one(
    {"transaction_id": "TRX00001"},
    {
        "$set": {
            "status": "completed",
            "shipping_date": datetime.now(),
            "tracking_number": "TRACK123456"
        }
    }
)
print(f"5️⃣ Vente TRX00001 mise à jour: {result.modified_count} document")

# 6. Incrémenter la quantité d'un produit
result = sales.update_one(
    {"transaction_id": "TRX00002", "products.name": "Laptop"},
    {"$inc": {"products.$.quantity": 1}}
)
print(f"6️⃣ Quantité incrémentée: {result.modified_count} document")

# Vérifier une mise à jour
updated_sale = sales.find_one({"transaction_id": "TRX00001"})
print(f"\n✅ Vérification TRX00001:")
print(f"   Statut: {updated_sale.get('status')}")
print(f"   Tracking: {updated_sale.get('tracking_number')}")

client.close()
```

**Exécuter :**

```bash
python updates.py
```

**Critères de validation :**
- ✅ Mises à jour en masse réussies
- ✅ Utilisation correcte des opérateurs ($set, $mul, $inc, $addToSet)
- ✅ Mise à jour d'éléments dans des tableaux ($)

---

### Tâche 2.4 : Suppressions (Delete)

**Instructions :**

Créez un fichier `deletes.py` :

```python
from pymongo import MongoClient
from datetime import datetime, timedelta

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== SUPPRESSIONS ===\n")

# Compter avant suppressions
total_before = sales.count_documents({})
print(f"📊 Total avant: {total_before} documents\n")

# 1. Supprimer les ventes cancelled
result = sales.delete_many({"status": "cancelled"})
print(f"1️⃣ Ventes cancelled supprimées: {result.deleted_count}")

# 2. Supprimer les ventes < 50€
result = sales.delete_many({"total_amount": {"$lt": 50}})
print(f"2️⃣ Ventes < 50€ supprimées: {result.deleted_count}")

# 3. Supprimer les ventes de plus d'un an
one_year_ago = datetime.now() - timedelta(days=365)
result = sales.delete_many({"created_at": {"$lt": one_year_ago}})
print(f"3️⃣ Ventes > 1 an supprimées: {result.deleted_count}")

# Compter après suppressions
total_after = sales.count_documents({})
print(f"\n📊 Total après: {total_after} documents")
print(f"🗑️ Total supprimé: {total_before - total_after} documents")

client.close()
```

**Exécuter :**

```bash
python deletes.py
```

**Critères de validation :**
- ✅ Suppressions ciblées réussies
- ✅ Nombre de documents supprimés correct

---

## 📊 Partie 3 : Agrégation et analytics (2h)

### Tâche 3.1 : Agrégations simples

**Instructions :**

Créez un fichier `aggregations.py` :

```python
from pymongo import MongoClient

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== AGRÉGATIONS ===\n")

# 1. Ventes par statut
print("1️⃣ Ventes par statut:")
pipeline1 = [
    {
        "$group": {
            "_id": "$status",
            "count": {"$sum": 1},
            "total_amount": {"$sum": "$total_amount"},
            "avg_amount": {"$avg": "$total_amount"}
        }
    },
    {"$sort": {"count": -1}}
]

for result in sales.aggregate(pipeline1):
    print(f"   {result['_id']}: {result['count']} ventes, "
          f"total: {result['total_amount']:.2f}€, "
          f"moyenne: {result['avg_amount']:.2f}€")

# 2. Top 5 villes par nombre de ventes
print("\n2️⃣ Top 5 villes:")
pipeline2 = [
    {
        "$group": {
            "_id": "$customer.city",
            "sales_count": {"$sum": 1},
            "total_revenue": {"$sum": "$total_amount"}
        }
    },
    {"$sort": {"sales_count": -1}},
    {"$limit": 5}
]

for result in sales.aggregate(pipeline2):
    print(f"   {result['_id']}: {result['sales_count']} ventes, "
          f"{result['total_revenue']:.2f}€")

# 3. Ventes par méthode de paiement
print("\n3️⃣ Ventes par méthode de paiement:")
pipeline3 = [
    {
        "$group": {
            "_id": "$payment_method",
            "count": {"$sum": 1},
            "percentage": {"$sum": 1}  # Sera calculé après
        }
    },
    {"$sort": {"count": -1}}
]

total = sales.count_documents({})
for result in sales.aggregate(pipeline3):
    percentage = (result['count'] / total) * 100
    print(f"   {result['_id']}: {result['count']} ({percentage:.1f}%)")

# 4. Statistiques globales
print("\n4️⃣ Statistiques globales:")
pipeline4 = [
    {
        "$group": {
            "_id": None,
            "total_sales": {"$sum": 1},
            "total_revenue": {"$sum": "$total_amount"},
            "avg_order_value": {"$avg": "$total_amount"},
            "min_order": {"$min": "$total_amount"},
            "max_order": {"$max": "$total_amount"}
        }
    }
]

stats = list(sales.aggregate(pipeline4))[0]
print(f"   Total ventes: {stats['total_sales']}")
print(f"   Chiffre d'affaires: {stats['total_revenue']:.2f}€")
print(f"   Panier moyen: {stats['avg_order_value']:.2f}€")
print(f"   Commande min: {stats['min_order']:.2f}€")
print(f"   Commande max: {stats['max_order']:.2f}€")

client.close()
```

**Exécuter :**

```bash
python aggregations.py
```

**Critères de validation :**
- ✅ Agrégations simples fonctionnelles
- ✅ Utilisation de $group, $sum, $avg, $min, $max
- ✅ Tri et limite des résultats

---

### Tâche 3.2 : Agrégations complexes avec $unwind

**Instructions :**

Créez un fichier `advanced_aggregations.py` :

```python
from pymongo import MongoClient

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== AGRÉGATIONS AVANCÉES ===\n")

# 1. Top 5 produits les plus vendus (nécessite $unwind)
print("1️⃣ Top 5 produits:")
pipeline1 = [
    {"$unwind": "$products"},
    {
        "$group": {
            "_id": "$products.name",
            "total_quantity": {"$sum": "$products.quantity"},
            "total_revenue": {"$sum": {"$multiply": ["$products.quantity", "$products.unit_price"]}},
            "avg_price": {"$avg": "$products.unit_price"}
        }
    },
    {"$sort": {"total_quantity": -1}},
    {"$limit": 5}
]

for result in sales.aggregate(pipeline1):
    print(f"   {result['_id']}: {result['total_quantity']} unités vendues, "
          f"{result['total_revenue']:.2f}€, prix moyen: {result['avg_price']:.2f}€")

# 2. Ventes par mois (time-series)
print("\n2️⃣ Ventes par mois:")
pipeline2 = [
    {
        "$project": {
            "year_month": {
                "$dateToString": {
                    "format": "%Y-%m",
                    "date": "$created_at"
                }
            },
            "total_amount": 1
        }
    },
    {
        "$group": {
            "_id": "$year_month",
            "sales_count": {"$sum": 1},
            "revenue": {"$sum": "$total_amount"}
        }
    },
    {"$sort": {"_id": 1}}
]

for result in sales.aggregate(pipeline2):
    print(f"   {result['_id']}: {result['sales_count']} ventes, {result['revenue']:.2f}€")

# 3. Performance par campagne marketing
print("\n3️⃣ Performance des campagnes:")
pipeline3 = [
    {
        "$group": {
            "_id": "$metadata.campaign",
            "sales": {"$sum": 1},
            "revenue": {"$sum": "$total_amount"},
            "avg_order_value": {"$avg": "$total_amount"}
        }
    },
    {"$sort": {"revenue": -1}}
]

for result in sales.aggregate(pipeline3):
    print(f"   {result['_id']}: {result['sales']} ventes, "
          f"{result['revenue']:.2f}€, AOV: {result['avg_order_value']:.2f}€")

# 4. Analyse par tranche de prix
print("\n4️⃣ Ventes par tranche de prix:")
pipeline4 = [
    {
        "$bucket": {
            "groupBy": "$total_amount",
            "boundaries": [0, 100, 300, 500, 1000, 10000],
            "default": "Other",
            "output": {
                "count": {"$sum": 1},
                "total_revenue": {"$sum": "$total_amount"}
            }
        }
    }
]

ranges = ["0-100€", "100-300€", "300-500€", "500-1000€", "1000€+"]
for i, result in enumerate(sales.aggregate(pipeline4)):
    if i < len(ranges):
        print(f"   {ranges[i]}: {result['count']} ventes, {result['total_revenue']:.2f}€")

# 5. Clients avec le plus de commandes (top 5)
print("\n5️⃣ Top 5 clients:")
pipeline5 = [
    {
        "$group": {
            "_id": "$customer.email",
            "name": {"$first": "$customer.name"},
            "orders_count": {"$sum": 1},
            "total_spent": {"$sum": "$total_amount"}
        }
    },
    {"$sort": {"orders_count": -1}},
    {"$limit": 5}
]

for result in sales.aggregate(pipeline5):
    print(f"   {result['name']} ({result['_id']}): "
          f"{result['orders_count']} commandes, {result['total_spent']:.2f}€")

client.close()
```

**Exécuter :**

```bash
python advanced_aggregations.py
```

**Critères de validation :**
- ✅ $unwind utilisé pour dérouler les produits
- ✅ Agrégations temporelles avec $dateToString
- ✅ $bucket pour créer des tranches
- ✅ Pipelines multi-stages fonctionnels

---

### Tâche 3.3 : Export des résultats vers CSV

**Instructions :**

Créez un fichier `export_analytics.py` :

```python
from pymongo import MongoClient
import pandas as pd
from datetime import datetime

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== EXPORT ANALYTICS ===\n")

# 1. Export des ventes en DataFrame
sales_data = list(sales.find({}, {
    "transaction_id": 1,
    "customer.name": 1,
    "customer.city": 1,
    "total_amount": 1,
    "status": 1,
    "created_at": 1,
    "_id": 0
}))

df = pd.DataFrame(sales_data)

# Aplatir les données nested
df['customer_name'] = df['customer'].apply(lambda x: x['name'])
df['customer_city'] = df['customer'].apply(lambda x: x['city'])
df = df.drop('customer', axis=1)

print(f"📊 DataFrame créé: {len(df)} lignes\n")
print(df.head())

# Export vers CSV
df.to_csv('sales_export.csv', index=False)
print(f"\n✅ Export CSV: sales_export.csv")

# 2. Analytics dashboard data
pipeline = [
    {
        "$group": {
            "_id": {
                "status": "$status",
                "payment_method": "$payment_method"
            },
            "count": {"$sum": 1},
            "revenue": {"$sum": "$total_amount"}
        }
    }
]

analytics_data = list(sales.aggregate(pipeline))
analytics_df = pd.DataFrame(analytics_data)

# Restructurer les données
analytics_df['status'] = analytics_df['_id'].apply(lambda x: x['status'])
analytics_df['payment_method'] = analytics_df['_id'].apply(lambda x: x['payment_method'])
analytics_df = analytics_df.drop('_id', axis=1)

analytics_df.to_csv('sales_analytics.csv', index=False)
print(f"✅ Export analytics: sales_analytics.csv")

# 3. Statistiques produits
products_pipeline = [
    {"$unwind": "$products"},
    {
        "$group": {
            "_id": "$products.name",
            "total_quantity": {"$sum": "$products.quantity"},
            "total_revenue": {
                "$sum": {
                    "$multiply": ["$products.quantity", "$products.unit_price"]
                }
            },
            "avg_price": {"$avg": "$products.unit_price"}
        }
    },
    {"$sort": {"total_revenue": -1}}
]

products_data = list(sales.aggregate(products_pipeline))
products_df = pd.DataFrame(products_data)
products_df = products_df.rename(columns={'_id': 'product_name'})

products_df.to_csv('products_analytics.csv', index=False)
print(f"✅ Export produits: products_analytics.csv")

print(f"\n📁 Fichiers créés:")
print(f"   - sales_export.csv ({len(df)} lignes)")
print(f"   - sales_analytics.csv ({len(analytics_df)} lignes)")
print(f"   - products_analytics.csv ({len(products_df)} lignes)")

client.close()
```

**Exécuter :**

```bash
python export_analytics.py
```

**Critères de validation :**
- ✅ DataFrames Pandas créés depuis MongoDB
- ✅ 3 fichiers CSV exportés
- ✅ Données correctement aplaties (nested → flat)

---

## ⚡ Partie 4 : Performances et index (1h)

### Tâche 4.1 : Analyser les performances

**Instructions :**

Créez un fichier `performance_analysis.py` :

```python
from pymongo import MongoClient
import time

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== ANALYSE DES PERFORMANCES ===\n")

# 1. Mesurer une requête sans index
print("1️⃣ Requête SANS index:")
start = time.time()
result = sales.find({"customer.email": "alice.dupont@example.com"})
list(result)  # Force l'exécution
duration = time.time() - start
print(f"   Temps d'exécution: {duration*1000:.2f}ms")

# Explain de la requête
explain = sales.find({"customer.email": "alice.dupont@example.com"}).explain()
print(f"   Documents examinés: {explain['executionStats']['totalDocsExamined']}")
print(f"   Temps (serveur): {explain['executionStats']['executionTimeMillis']}ms")
print(f"   Type de scan: {explain['executionStats']['executionStages']['stage']}")

# 2. Créer des index
print("\n2️⃣ Création des index:")

# Index sur email
sales.create_index([("customer.email", 1)])
print("   ✅ Index créé sur customer.email")

# Index sur total_amount
sales.create_index([("total_amount", -1)])
print("   ✅ Index créé sur total_amount")

# Index composé
sales.create_index([("status", 1), ("created_at", -1)])
print("   ✅ Index composé créé sur status + created_at")

# Index sur transaction_id (unique)
sales.create_index([("transaction_id", 1)], unique=True)
print("   ✅ Index unique créé sur transaction_id")

# 3. Mesurer la même requête AVEC index
print("\n3️⃣ Requête AVEC index:")
start = time.time()
result = sales.find({"customer.email": "alice.dupont@example.com"})
list(result)
duration = time.time() - start
print(f"   Temps d'exécution: {duration*1000:.2f}ms")

explain = sales.find({"customer.email": "alice.dupont@example.com"}).explain()
print(f"   Documents examinés: {explain['executionStats']['totalDocsExamined']}")
print(f"   Temps (serveur): {explain['executionStats']['executionTimeMillis']}ms")
print(f"   Index utilisé: {explain['executionStats']['executionStages'].get('indexName', 'N/A')}")

# 4. Lister tous les index
print("\n4️⃣ Index de la collection:")
for index in sales.list_indexes():
    print(f"   - {index['name']}: {index['key']}")

# 5. Tester une requête complexe
print("\n5️⃣ Requête complexe optimisée:")
pipeline = [
    {
        "$match": {
            "status": "completed",
            "total_amount": {"$gt": 200}
        }
    },
    {
        "$group": {
            "_id": "$customer.city",
            "count": {"$sum": 1}
        }
    },
    {"$sort": {"count": -1}},
    {"$limit": 5}
]

start = time.time()
result = list(sales.aggregate(pipeline))
duration = time.time() - start

print(f"   Temps d'exécution: {duration*1000:.2f}ms")
print(f"   Résultats: {len(result)} villes")

client.close()
```

**Exécuter :**

```bash
python performance_analysis.py
```

**Critères de validation :**
- ✅ Différence de performance mesurable avant/après index
- ✅ 4 index créés (simple, composé, unique)
- ✅ explain() utilisé pour analyser les requêtes
- ✅ Amélioration visible des temps d'exécution

---

### Tâche 4.2 : Optimiser les agrégations

**Instructions :**

Créez un fichier `optimize_aggregations.py` :

```python
from pymongo import MongoClient
import time

client = MongoClient('mongodb://admin:SecurePass123@localhost:27017/')
db = client['dataeng']
sales = db['sales']

print("=== OPTIMISATION DES AGRÉGATIONS ===\n")

# Pipeline NON optimisé (match après group)
print("1️⃣ Pipeline NON optimisé:")
pipeline_bad = [
    {
        "$group": {
            "_id": "$status",
            "total": {"$sum": "$total_amount"}
        }
    },
    {
        "$match": {
            "_id": "completed"
        }
    }
]

start = time.time()
result = list(sales.aggregate(pipeline_bad))
duration = time.time() - start
print(f"   Temps: {duration*1000:.2f}ms")

# Pipeline OPTIMISÉ (match avant group)
print("\n2️⃣ Pipeline OPTIMISÉ:")
pipeline_good = [
    {
        "$match": {
            "status": "completed"
        }
    },
    {
        "$group": {
            "_id": "$status",
            "total": {"$sum": "$total_amount"}
        }
    }
]

start = time.time()
result = list(sales.aggregate(pipeline_good))
duration = time.time() - start
print(f"   Temps: {duration*1000:.2f}ms")
print("   💡 $match avant $group réduit les documents à traiter")

# Pipeline avec projection
print("\n3️⃣ Pipeline avec $project:")
pipeline_project = [
    {
        "$match": {
            "status": "completed"
        }
    },
    {
        "$project": {
            "total_amount": 1,
            "customer.city": 1
        }
    },
    {
        "$group": {
            "_id": "$customer.city",
            "revenue": {"$sum": "$total_amount"}
        }
    },
    {"$sort": {"revenue": -1}},
    {"$limit": 10}
]

start = time.time()
result = list(sales.aggregate(pipeline_project))
duration = time.time() - start
print(f"   Temps: {duration*1000:.2f}ms")
print("   💡 $project réduit la taille des documents")

# Utiliser allowDiskUse pour les gros datasets
print("\n4️⃣ Pipeline avec allowDiskUse:")
pipeline_large = [
    {"$unwind": "$products"},
    {
        "$group": {
            "_id": {
                "product": "$products.name",
                "city": "$customer.city"
            },
            "count": {"$sum": 1}
        }
    },
    {"$sort": {"count": -1}}
]

result = sales.aggregate(pipeline_large, allowDiskUse=True)
print("   ✅ allowDiskUse=True pour les agrégations gourmandes en mémoire")

client.close()
```

**Exécuter :**

```bash
python optimize_aggregations.py
```

**Critères de validation :**
- ✅ Comparaison de pipelines optimisés vs non-optimisés
- ✅ $match placé avant $group
- ✅ $project utilisé pour réduire la taille des documents
- ✅ allowDiskUse utilisé

---

## 🏗️ Partie 5 : Projet final - Pipeline ETL complet (1h30)

### Tâche 5.1 : Créer un pipeline ETL production-ready

**Scénario final :** Créez un pipeline ETL complet qui :
1. Extrait des données d'une API
2. Transforme et valide les données
3. Charge dans MongoDB avec gestion d'erreurs
4. Génère des rapports analytics
5. Log toutes les opérations

**Instructions :**

Créez un fichier `etl_pipeline.py` :

```python
"""
Pipeline ETL Production-Ready pour MongoDB
Extract → Transform → Load → Analyze
"""

from pymongo import MongoClient
import requests
from datetime import datetime
import logging
import json
import pandas as pd
from typing import Dict, List, Any

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('etl_pipeline.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class MongoDBETLPipeline:
    """Pipeline ETL pour MongoDB"""

    def __init__(self, mongo_uri: str, database: str):
        self.mongo_uri = mongo_uri
        self.database_name = database
        self.client = None
        self.db = None
        self.stats = {
            "extracted": 0,
            "transformed": 0,
            "loaded": 0,
            "errors": 0
        }

    def connect(self):
        """Connexion à MongoDB"""
        try:
            self.client = MongoClient(self.mongo_uri)
            self.db = self.client[self.database_name]
            self.client.admin.command('ping')
            logger.info(f"✅ Connecté à MongoDB: {self.database_name}")
        except Exception as e:
            logger.error(f"❌ Erreur de connexion MongoDB: {e}")
            raise

    def disconnect(self):
        """Déconnexion de MongoDB"""
        if self.client:
            self.client.close()
            logger.info("🔒 Connexion MongoDB fermée")

    def extract_from_api(self, api_url: str) -> List[Dict]:
        """Extract: Récupérer les données depuis une API"""
        logger.info(f"📥 Extraction depuis {api_url}")

        try:
            response = requests.get(api_url, timeout=30)
            response.raise_for_status()

            data = response.json()
            self.stats["extracted"] = len(data)

            logger.info(f"✅ {self.stats['extracted']} enregistrements extraits")
            return data

        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Erreur lors de l'extraction: {e}")
            self.stats["errors"] += 1
            return []

    def validate_record(self, record: Dict) -> bool:
        """Valider un enregistrement"""
        required_fields = ['name', 'email', 'address']

        # Vérifier les champs requis
        for field in required_fields:
            if field not in record or not record[field]:
                logger.warning(f"⚠️ Champ manquant: {field}")
                return False

        # Valider l'email
        if '@' not in record.get('email', ''):
            logger.warning(f"⚠️ Email invalide: {record.get('email')}")
            return False

        return True

    def transform_data(self, raw_data: List[Dict]) -> List[Dict]:
        """Transform: Nettoyer et enrichir les données"""
        logger.info("🔄 Transformation des données")

        transformed = []

        for record in raw_data:
            try:
                # Valider
                if not self.validate_record(record):
                    self.stats["errors"] += 1
                    continue

                # Transformer
                transformed_record = {
                    "user_id": record.get('id'),
                    "name": record.get('name', '').strip(),
                    "email": record.get('email', '').lower(),
                    "phone": record.get('phone', '').strip(),
                    "address": {
                        "street": record.get('address', {}).get('street', ''),
                        "city": record.get('address', {}).get('city', ''),
                        "zipcode": record.get('address', {}).get('zipcode', ''),
                        "geo": {
                            "lat": float(record.get('address', {}).get('geo', {}).get('lat', 0)),
                            "lng": float(record.get('address', {}).get('geo', {}).get('lng', 0))
                        }
                    },
                    "company": {
                        "name": record.get('company', {}).get('name', ''),
                        "catchPhrase": record.get('company', {}).get('catchPhrase', '')
                    },
                    "metadata": {
                        "source": "api",
                        "imported_at": datetime.utcnow(),
                        "version": "1.0"
                    },
                    "status": "active"
                }

                transformed.append(transformed_record)
                self.stats["transformed"] += 1

            except Exception as e:
                logger.error(f"❌ Erreur transformation: {e} - Record: {record.get('id')}")
                self.stats["errors"] += 1

        logger.info(f"✅ {self.stats['transformed']} enregistrements transformés")
        return transformed

    def load_to_mongodb(self, data: List[Dict], collection_name: str):
        """Load: Charger les données dans MongoDB"""
        logger.info(f"💾 Chargement dans {collection_name}")

        if not data:
            logger.warning("⚠️ Aucune donnée à charger")
            return

        collection = self.db[collection_name]

        try:
            # Bulk insert avec gestion d'erreurs
            result = collection.insert_many(data, ordered=False)
            self.stats["loaded"] = len(result.inserted_ids)
            logger.info(f"✅ {self.stats['loaded']} documents insérés")

            # Créer des index
            collection.create_index([("email", 1)], unique=True, background=True)
            collection.create_index([("user_id", 1)], unique=True, background=True)
            collection.create_index([("address.city", 1)], background=True)
            logger.info("✅ Index créés")

        except Exception as e:
            logger.error(f"❌ Erreur lors du chargement: {e}")
            self.stats["errors"] += 1
            raise

    def generate_analytics(self, collection_name: str) -> Dict:
        """Générer des analytics sur les données chargées"""
        logger.info("📊 Génération des analytics")

        collection = self.db[collection_name]

        analytics = {}

        try:
            # 1. Statistiques générales
            analytics['total_users'] = collection.count_documents({})
            analytics['active_users'] = collection.count_documents({"status": "active"})

            # 2. Top 5 villes
            pipeline_cities = [
                {
                    "$group": {
                        "_id": "$address.city",
                        "count": {"$sum": 1}
                    }
                },
                {"$sort": {"count": -1}},
                {"$limit": 5}
            ]
            analytics['top_cities'] = list(collection.aggregate(pipeline_cities))

            # 3. Utilisateurs par domaine email
            pipeline_domains = [
                {
                    "$project": {
                        "domain": {
                            "$arrayElemAt": [
                                {"$split": ["$email", "@"]},
                                1
                            ]
                        }
                    }
                },
                {
                    "$group": {
                        "_id": "$domain",
                        "count": {"$sum": 1}
                    }
                },
                {"$sort": {"count": -1}}
            ]
            analytics['domains'] = list(collection.aggregate(pipeline_domains))

            logger.info("✅ Analytics générés")
            return analytics

        except Exception as e:
            logger.error(f"❌ Erreur analytics: {e}")
            return {}

    def export_report(self, analytics: Dict, filename: str = "etl_report.json"):
        """Exporter un rapport JSON"""
        report = {
            "pipeline_run": {
                "timestamp": datetime.utcnow().isoformat(),
                "status": "success" if self.stats["errors"] == 0 else "completed_with_errors"
            },
            "statistics": self.stats,
            "analytics": analytics
        }

        with open(filename, 'w') as f:
            json.dump(report, f, indent=2, default=str)

        logger.info(f"📄 Rapport exporté: {filename}")

    def run_pipeline(self, api_url: str, collection_name: str):
        """Exécuter le pipeline complet"""
        logger.info("=" * 50)
        logger.info("🚀 DÉMARRAGE DU PIPELINE ETL")
        logger.info("=" * 50)

        try:
            # Connect
            self.connect()

            # Extract
            raw_data = self.extract_from_api(api_url)

            # Transform
            transformed_data = self.transform_data(raw_data)

            # Load
            self.load_to_mongodb(transformed_data, collection_name)

            # Analyze
            analytics = self.generate_analytics(collection_name)

            # Report
            self.export_report(analytics)

            # Summary
            logger.info("=" * 50)
            logger.info("✅ PIPELINE ETL TERMINÉ AVEC SUCCÈS")
            logger.info(f"📊 Extraits: {self.stats['extracted']}")
            logger.info(f"🔄 Transformés: {self.stats['transformed']}")
            logger.info(f"💾 Chargés: {self.stats['loaded']}")
            logger.info(f"❌ Erreurs: {self.stats['errors']}")
            logger.info("=" * 50)

        except Exception as e:
            logger.error(f"❌ ERREUR CRITIQUE DU PIPELINE: {e}")
            raise

        finally:
            self.disconnect()


# Utilisation
if __name__ == "__main__":
    # Configuration
    MONGO_URI = "mongodb://admin:SecurePass123@localhost:27017/"
    DATABASE = "dataeng"
    API_URL = "https://jsonplaceholder.typicode.com/users"
    COLLECTION = "etl_users"

    # Exécuter le pipeline
    pipeline = MongoDBETLPipeline(MONGO_URI, DATABASE)
    pipeline.run_pipeline(API_URL, COLLECTION)
```

**Exécuter :**

```bash
python etl_pipeline.py
```

**Critères de validation :**
- ✅ Pipeline ETL complet fonctionnel
- ✅ Extract, Transform, Load implémentés
- ✅ Validation des données
- ✅ Gestion d'erreurs complète
- ✅ Logging détaillé
- ✅ Index créés automatiquement
- ✅ Analytics générés
- ✅ Rapport JSON exporté

---

### Tâche 5.2 : Vérifier et analyser les résultats

**Instructions :**

```bash
# 1. Vérifier les logs
cat etl_pipeline.log

# 2. Voir le rapport JSON
cat etl_report.json

# 3. Vérifier dans MongoDB
docker exec -it mongodb_dev mongosh -u admin -p SecurePass123

# Dans le shell MongoDB :
use dataeng
db.etl_users.countDocuments()
db.etl_users.findOne()
db.etl_users.getIndexes()
exit
```

**Critères de validation :**
- ✅ Log fichier créé avec toutes les opérations
- ✅ Rapport JSON contenant stats et analytics
- ✅ Données dans MongoDB
- ✅ Index créés

---

## 📤 Livrables

À la fin du brief, vous devez avoir :

### 1. Infrastructure MongoDB :
- ✅ MongoDB running avec Docker
- ✅ Mongo Express accessible
- ✅ Connexion Python fonctionnelle

### 2. Collections créées :
- ✅ `users` (données initiales)
- ✅ `sales` (100+ ventes générées)
- ✅ `etl_users` (données importées via ETL)

### 3. Scripts Python (10+ fichiers) :
- ✅ test_connection.py
- ✅ insert_data.py
- ✅ queries.py
- ✅ updates.py
- ✅ deletes.py
- ✅ aggregations.py
- ✅ advanced_aggregations.py
- ✅ export_analytics.py
- ✅ performance_analysis.py
- ✅ optimize_aggregations.py
- ✅ etl_pipeline.py

### 4. Fichiers de données :
- ✅ sales_export.csv
- ✅ sales_analytics.csv
- ✅ products_analytics.csv
- ✅ etl_report.json
- ✅ etl_pipeline.log

### 5. Documentation :
- ✅ README.md expliquant le projet
- ✅ Commentaires dans le code
- ✅ Logs détaillés

---

## ✅ Critères d'Évaluation

| Critère | Points |
|---------|--------|
| Installation et configuration | 10 |
| Opérations CRUD complètes | 15 |
| Agrégations simples et complexes | 20 |
| Optimisation et index | 15 |
| Pipeline ETL complet | 25 |
| Qualité du code et logs | 10 |
| Documentation | 5 |

**Total : 100 points**

**Bonus (+10 points) :**
- Change Streams implémentés
- Transactions ACID utilisées
- Dashboard de visualisation créé
- Tests unitaires ajoutés

---

## 💡 Conseils

### Performance
- 🔍 **Index stratégiques** : Indexez les champs de vos requêtes fréquentes
- 📊 **$match tôt** : Placez $match au début des pipelines
- 💾 **Projection** : Limitez les champs récupérés
- 🚀 **allowDiskUse** : Activez pour les grandes agrégations

### Modélisation
- 🗂️ **Embed vs Reference** : Embed pour one-to-few, reference pour one-to-many
- 📐 **Schéma flexible** : Profitez de la flexibilité mais documentez
- 🎯 **Design par usage** : Modélisez selon vos patterns d'accès

### Production
- 🔒 **Sécurité** : Utilisez des credentials sécurisés
- 📝 **Logging** : Loggez tout pour le debugging
- ⚠️ **Gestion d'erreurs** : Try-except sur toutes les opérations
- 💾 **Backups** : Mettez en place des sauvegardes régulières

---

## 🆘 Troubleshooting

### MongoDB ne démarre pas
```bash
# Vérifier les logs
docker-compose logs mongodb

# Redémarrer
docker-compose restart mongodb

# Recréer les conteneurs
docker-compose down -v
docker-compose up -d
```

### Erreur de connexion Python
```python
# Vérifier la connexion
from pymongo import MongoClient
client = MongoClient('mongodb://localhost:27017/', serverSelectionTimeoutMS=5000)
try:
    client.admin.command('ping')
    print("✅ Connecté")
except Exception as e:
    print(f"❌ Erreur: {e}")
```

### Performance lente
```javascript
// Analyser une requête
db.collection.find({query}).explain("executionStats")

// Vérifier les index
db.collection.getIndexes()

// Créer un index
db.collection.createIndex({field: 1})
```

---

## 📚 Ressources

### Documentation
- [MongoDB Manual](https://www.mongodb.com/docs/manual/)
- [PyMongo Documentation](https://pymongo.readthedocs.io/)
- [Aggregation Pipeline](https://www.mongodb.com/docs/manual/aggregation/)

### Tutorials
- [MongoDB University](https://university.mongodb.com/) - Cours gratuits
- [MongoDB Developer Hub](https://www.mongodb.com/developer/)

### Tools
- [MongoDB Compass](https://www.mongodb.com/products/compass) - GUI officielle
- [Studio 3T](https://studio3t.com/) - IDE MongoDB avancé
- [NoSQLBooster](https://nosqlbooster.com/) - Client MongoDB

---

**Bon courage ! 🚀**

*MongoDB : La base NoSQL pour vos projets Data Engineering modernes !*
