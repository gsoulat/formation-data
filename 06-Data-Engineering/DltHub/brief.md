# ⚡ Brief Pratique DltHub - Data Engineering

**Durée estimée :** 6 heures
**Niveau :** Intermédiaire
**Modalité :** Pratique individuelle

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :
- Créer des pipelines DLT de A à Z
- Extraire des données de diverses sources (API, fichiers, bases de données)
- Charger vers différentes destinations (DuckDB, PostgreSQL, BigQuery)
- Implémenter le loading incrémental
- Gérer le schema evolution et la validation
- Déployer un pipeline en production avec monitoring

---

## 📋 Contexte

Vous êtes Data Engineer chez **StreamData Solutions**. L'entreprise a besoin de mettre en place des pipelines de données modernes pour ingérer des données depuis plusieurs sources (APIs, bases de données) vers un data warehouse. Vous avez choisi **DltHub** pour sa simplicité et sa flexibilité.

---

## 🚀 Partie 1 : Installation et premier pipeline (1h)

### Tâche 1.1 : Setup de l'environnement

**Instructions :**

1. **Créer un projet DLT :**

```bash
# Créer un dossier pour le projet
mkdir dlthub-data-pipeline
cd dlthub-data-pipeline

# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate  # macOS/Linux
# ou venv\Scripts\activate  # Windows
```

2. **Installer les dépendances :**

Créer un fichier `requirements.txt` :

```
dlt[duckdb]==0.4.0
dlt[postgres]
pandas==2.1.0
requests==2.31.0
python-dotenv==1.0.0
faker==20.0.0
```

```bash
pip install -r requirements.txt
```

3. **Initialiser la structure DLT :**

```bash
# Créer la structure des dossiers
mkdir -p .dlt pipelines data

# Créer les fichiers de configuration
touch .dlt/config.toml .dlt/secrets.toml .gitignore
```

4. **Fichier `.gitignore` :**

```
venv/
.dlt/secrets.toml
*.duckdb
*.duckdb.wal
__pycache__/
*.pyc
.env
data/
```

5. **Configuration `.dlt/config.toml` :**

```toml
[runtime]
log_level = "INFO"

[sources.jsonplaceholder]
base_url = "https://jsonplaceholder.typicode.com"
```

**Critères de validation :**
- ✅ Environnement virtuel créé et activé
- ✅ DLT installé (`dlt --version`)
- ✅ Structure des dossiers créée
- ✅ Fichiers de configuration initialisés

---

### Tâche 1.2 : Premier pipeline API → DuckDB

**Scénario :** Extraire des utilisateurs depuis l'API JSONPlaceholder et les charger dans DuckDB.

**Instructions :**

Créer `pipelines/first_pipeline.py` :

```python
"""
Premier pipeline DLT : API → DuckDB
"""
import dlt
import requests


@dlt.resource(name="users", write_disposition="replace")
def get_users():
    """Récupérer les utilisateurs depuis JSONPlaceholder"""
    print("📥 Fetching users from API...")

    response = requests.get("https://jsonplaceholder.typicode.com/users")
    users = response.json()

    print(f"✅ Fetched {len(users)} users")
    yield users


@dlt.resource(name="posts", write_disposition="replace")
def get_posts():
    """Récupérer les posts"""
    print("📥 Fetching posts from API...")

    response = requests.get("https://jsonplaceholder.typicode.com/posts")
    posts = response.json()

    print(f"✅ Fetched {len(posts)} posts")
    yield posts


def run():
    """Exécuter le pipeline"""
    print("🚀 Starting first DLT pipeline...\n")

    # Créer le pipeline
    pipeline = dlt.pipeline(
        pipeline_name="jsonplaceholder_api",
        destination="duckdb",
        dataset_name="jsonplaceholder_data"
    )

    # Charger les données
    load_info = pipeline.run([get_users(), get_posts()])

    print(f"\n✅ Pipeline completed successfully!")
    print(f"📊 Load info: {load_info}")


if __name__ == "__main__":
    run()
```

**Exécuter le pipeline :**

```bash
python pipelines/first_pipeline.py
```

**Vérifier les données :**

```bash
# Ouvrir DuckDB
duckdb jsonplaceholder_data.duckdb

# Dans DuckDB:
SHOW TABLES;
SELECT * FROM users LIMIT 5;
SELECT * FROM posts LIMIT 5;
.exit
```

**Critères de validation :**
- ✅ Pipeline s'exécute sans erreur
- ✅ Fichier `jsonplaceholder_data.duckdb` créé
- ✅ Tables `users` et `posts` présentes
- ✅ Données correctement chargées

---

### Tâche 1.3 : Enrichir les données

**Instructions :**

Modifier `pipelines/first_pipeline.py` pour enrichir les données :

```python
from datetime import datetime

@dlt.resource(name="users_enriched", write_disposition="replace")
def get_users_enriched():
    """Récupérer et enrichir les utilisateurs"""
    print("📥 Fetching users from API...")

    response = requests.get("https://jsonplaceholder.typicode.com/users")
    users = response.json()

    # Enrichir chaque utilisateur
    enriched_users = []
    for user in users:
        enriched = {
            "user_id": user["id"],
            "name": user["name"],
            "username": user["username"],
            "email": user["email"].lower(),
            "city": user["address"]["city"],
            "latitude": float(user["address"]["geo"]["lat"]),
            "longitude": float(user["address"]["geo"]["lng"]),
            "company_name": user["company"]["name"],
            "company_bs": user["company"]["bs"],
            # Métadonnées
            "loaded_at": datetime.now(),
            "source": "jsonplaceholder_api"
        }
        enriched_users.append(enriched)

    print(f"✅ Enriched {len(enriched_users)} users")
    yield enriched_users
```

**Critères de validation :**
- ✅ Données aplaties (nested → flat)
- ✅ Champs calculés ajoutés (loaded_at, source)
- ✅ Emails en minuscules
- ✅ Géolocalisation extraite

---

## 📊 Partie 2 : Sources et destinations multiples (1h30)

### Tâche 2.1 : Créer une source complète

**Instructions :**

Créer `pipelines/ecommerce_source.py` :

```python
"""
Source e-commerce complète avec plusieurs resources
"""
import dlt
import requests
from datetime import datetime
from typing import Iterator, Dict, Any


@dlt.source
def ecommerce_api(base_url: str = "https://fakestoreapi.com"):
    """
    Source e-commerce avec plusieurs resources
    """

    @dlt.resource(
        name="products",
        write_disposition="replace",
        primary_key="id"
    )
    def get_products() -> Iterator[Dict[str, Any]]:
        """Récupérer les produits"""
        print("📥 Fetching products...")

        response = requests.get(f"{base_url}/products")
        products = response.json()

        for product in products:
            yield {
                "product_id": product["id"],
                "title": product["title"],
                "price": product["price"],
                "category": product["category"],
                "description": product["description"][:100],  # Tronquer
                "rating_rate": product["rating"]["rate"],
                "rating_count": product["rating"]["count"],
                "loaded_at": datetime.now()
            }

    @dlt.resource(
        name="categories",
        write_disposition="replace"
    )
    def get_categories() -> Iterator[Dict[str, Any]]:
        """Récupérer les catégories"""
        print("📥 Fetching categories...")

        response = requests.get(f"{base_url}/products/categories")
        categories = response.json()

        for i, category in enumerate(categories, 1):
            yield {
                "category_id": i,
                "category_name": category,
                "loaded_at": datetime.now()
            }

    @dlt.resource(
        name="users",
        write_disposition="replace",
        primary_key="user_id"
    )
    def get_users() -> Iterator[Dict[str, Any]]:
        """Récupérer les utilisateurs"""
        print("📥 Fetching users...")

        response = requests.get(f"{base_url}/users")
        users = response.json()

        for user in users:
            yield {
                "user_id": user["id"],
                "email": user["email"].lower(),
                "username": user["username"],
                "name_firstname": user["name"]["firstname"],
                "name_lastname": user["name"]["lastname"],
                "phone": user["phone"],
                "city": user["address"]["city"],
                "loaded_at": datetime.now()
            }

    return get_products(), get_categories(), get_users()


def run_ecommerce_pipeline():
    """Exécuter le pipeline e-commerce"""
    print("🚀 Starting e-commerce pipeline...\n")

    pipeline = dlt.pipeline(
        pipeline_name="ecommerce",
        destination="duckdb",
        dataset_name="ecommerce_data"
    )

    # Charger toutes les resources de la source
    source = ecommerce_api()
    load_info = pipeline.run(source)

    print(f"\n✅ Pipeline completed!")
    print(f"📊 {load_info}")


if __name__ == "__main__":
    run_ecommerce_pipeline()
```

**Exécuter :**

```bash
python pipelines/ecommerce_source.py
```

**Critères de validation :**
- ✅ 3 tables créées : products, categories, users
- ✅ Données enrichies et aplaties
- ✅ Primary keys définis

---

### Tâche 2.2 : Charger vers PostgreSQL

**Scénario :** Maintenant charger les mêmes données vers PostgreSQL au lieu de DuckDB.

**Instructions :**

1. **Démarrer PostgreSQL avec Docker :**

```bash
docker run -d \
  --name postgres_dlt \
  -p 5432:5432 \
  -e POSTGRES_USER=dlt_user \
  -e POSTGRES_PASSWORD=dlt_password \
  -e POSTGRES_DB=dlt_data \
  postgres:15
```

2. **Configurer les credentials dans `.dlt/secrets.toml` :**

```toml
[destination.postgres.credentials]
database = "dlt_data"
username = "dlt_user"
password = "dlt_password"
host = "localhost"
port = 5432
```

3. **Créer `pipelines/ecommerce_to_postgres.py` :**

```python
"""
Pipeline e-commerce vers PostgreSQL
"""
import dlt
from ecommerce_source import ecommerce_api


def run():
    """Exécuter le pipeline vers PostgreSQL"""
    print("🚀 Starting pipeline to PostgreSQL...\n")

    pipeline = dlt.pipeline(
        pipeline_name="ecommerce_postgres",
        destination="postgres",
        dataset_name="ecommerce"
    )

    source = ecommerce_api()
    load_info = pipeline.run(source)

    print(f"\n✅ Data loaded to PostgreSQL!")
    print(f"📊 {load_info}")


if __name__ == "__main__":
    run()
```

4. **Exécuter :**

```bash
python pipelines/ecommerce_to_postgres.py
```

5. **Vérifier dans PostgreSQL :**

```bash
docker exec -it postgres_dlt psql -U dlt_user -d dlt_data

# Dans psql:
\dt ecommerce.*
SELECT * FROM ecommerce.products LIMIT 5;
\q
```

**Critères de validation :**
- ✅ PostgreSQL running
- ✅ Données chargées dans PostgreSQL
- ✅ Schema `ecommerce` créé
- ✅ 3 tables présentes

---

### Tâche 2.3 : Générer des données fictives avec Faker

**Instructions :**

Créer `pipelines/sales_generator.py` :

```python
"""
Générer des ventes fictives avec Faker
"""
import dlt
from faker import Faker
from datetime import datetime, timedelta
import random

fake = Faker()


@dlt.resource(
    name="sales",
    write_disposition="append",
    primary_key="sale_id"
)
def generate_sales(num_sales: int = 1000):
    """Générer des ventes fictives"""
    print(f"📊 Generating {num_sales} fake sales...")

    for i in range(1, num_sales + 1):
        sale_date = fake.date_time_between(
            start_date="-30d",
            end_date="now"
        )

        yield {
            "sale_id": i,
            "customer_name": fake.name(),
            "customer_email": fake.email(),
            "product": random.choice([
                "Laptop", "Mouse", "Keyboard",
                "Monitor", "Headset", "Webcam"
            ]),
            "quantity": random.randint(1, 5),
            "unit_price": round(random.uniform(20, 1500), 2),
            "total_amount": 0,  # Calculé après
            "sale_date": sale_date,
            "status": random.choice(["completed", "pending", "cancelled"]),
            "payment_method": random.choice([
                "Credit Card", "PayPal", "Bank Transfer"
            ]),
            "country": fake.country(),
            "city": fake.city(),
            "loaded_at": datetime.now()
        }


@dlt.transformer(
    name="sales_with_total",
    write_disposition="replace",
    primary_key="sale_id"
)
def calculate_total(sales):
    """Transformer : calculer le total"""
    for sale in sales:
        sale["total_amount"] = round(
            sale["quantity"] * sale["unit_price"],
            2
        )
        yield sale


def run():
    """Exécuter le générateur"""
    print("🚀 Generating and loading sales data...\n")

    pipeline = dlt.pipeline(
        pipeline_name="sales_generator",
        destination="duckdb",
        dataset_name="sales_data"
    )

    # Générer et transformer
    sales = generate_sales(num_sales=1000)
    sales_transformed = calculate_total(sales)

    load_info = pipeline.run(sales_transformed)

    print(f"\n✅ Sales data generated and loaded!")
    print(f"📊 {load_info}")


if __name__ == "__main__":
    run()
```

**Exécuter :**

```bash
python pipelines/sales_generator.py
```

**Critères de validation :**
- ✅ 1000 ventes générées
- ✅ Total calculé automatiquement
- ✅ Données réalistes avec Faker
- ✅ Table `sales_with_total` créée

---

## 🔄 Partie 3 : Loading incrémental et state (1h30)

### Tâche 3.1 : Implémenter le loading incrémental

**Scénario :** Charger seulement les nouvelles commandes depuis une API.

**Instructions :**

Créer `pipelines/incremental_orders.py` :

```python
"""
Pipeline incrémental : charger seulement les nouvelles données
"""
import dlt
import requests
from datetime import datetime, timedelta
from typing import Iterator, Dict, Any


@dlt.resource(
    name="orders",
    write_disposition="append",
    primary_key="order_id"
)
def get_orders_incremental(
    last_date=dlt.sources.incremental("order_date")
):
    """
    Récupérer les commandes de manière incrémentale
    DLT sauvegarde automatiquement le dernier order_date
    """
    print(f"📥 Fetching orders...")

    # Si première exécution, commencer à 30 jours en arrière
    if last_date.start_value is None:
        start_date = datetime.now() - timedelta(days=30)
        print(f"⚠️ First run, fetching from {start_date.date()}")
    else:
        start_date = last_date.start_value
        print(f"📅 Fetching orders since {start_date}")

    # Simuler des commandes (normalement vous appelleriez une vraie API)
    # Pour la démo, on génère des données
    from faker import Faker
    import random

    fake = Faker()
    current_date = start_date

    orders = []
    while current_date <= datetime.now():
        # Générer 5-10 commandes par jour
        for _ in range(random.randint(5, 10)):
            order = {
                "order_id": fake.uuid4(),
                "customer_name": fake.name(),
                "customer_email": fake.email(),
                "product": random.choice(["Product A", "Product B", "Product C"]),
                "amount": round(random.uniform(10, 500), 2),
                "order_date": current_date,
                "status": random.choice(["completed", "pending"]),
                "loaded_at": datetime.now()
            }
            orders.append(order)

        current_date += timedelta(days=1)

    print(f"✅ Fetched {len(orders)} orders")
    yield orders


def run():
    """Exécuter le pipeline incrémental"""
    print("🚀 Starting incremental pipeline...\n")

    pipeline = dlt.pipeline(
        pipeline_name="orders_incremental",
        destination="duckdb",
        dataset_name="orders_data"
    )

    load_info = pipeline.run(get_orders_incremental())

    print(f"\n✅ Pipeline completed!")
    print(f"📊 Loaded {load_info}")


if __name__ == "__main__":
    # Première exécution : charge 30 jours
    print("=" * 50)
    print("PREMIÈRE EXÉCUTION")
    print("=" * 50)
    run()

    # Attendre un peu
    import time
    time.sleep(2)

    # Deuxième exécution : charge seulement les nouveaux
    print("\n" + "=" * 50)
    print("DEUXIÈME EXÉCUTION (Incrémental)")
    print("=" * 50)
    run()
```

**Exécuter :**

```bash
python pipelines/incremental_orders.py
```

**Vérifier le state :**

```bash
# Le state est sauvegardé dans DuckDB
duckdb orders_data.duckdb

SELECT * FROM _dlt_pipeline_state;
.exit
```

**Critères de validation :**
- ✅ Première exécution charge 30 jours de données
- ✅ Deuxième exécution charge seulement les nouvelles
- ✅ State sauvegardé automatiquement
- ✅ Pas de doublons

---

### Tâche 3.2 : Loading incrémental avec plusieurs cursors

**Instructions :**

Créer `pipelines/multi_cursor_incremental.py` :

```python
"""
Loading incrémental avec plusieurs cursors
"""
import dlt
from datetime import datetime, timedelta
from faker import Faker
import random

fake = Faker()


@dlt.resource(
    name="user_activities",
    write_disposition="append",
    primary_key=["user_id", "activity_date"]
)
def get_user_activities(
    last_date=dlt.sources.incremental("activity_date"),
    last_user_id=dlt.sources.incremental("user_id")
):
    """
    Loading incrémental avec deux cursors :
    - activity_date : date de l'activité
    - user_id : ID utilisateur
    """
    print(f"📥 Fetching user activities...")

    # Valeurs de départ
    if last_date.start_value is None:
        start_date = datetime.now() - timedelta(days=7)
    else:
        start_date = last_date.start_value

    if last_user_id.start_value is None:
        start_user_id = 1
    else:
        start_user_id = last_user_id.start_value

    print(f"📅 From date: {start_date.date()}")
    print(f"👤 From user_id: {start_user_id}")

    # Générer des activités
    activities = []
    for day in range(7):
        activity_date = start_date + timedelta(days=day)

        for user_id in range(start_user_id, start_user_id + 10):
            activity = {
                "user_id": user_id,
                "activity_date": activity_date,
                "activity_type": random.choice(["login", "purchase", "view", "click"]),
                "duration_seconds": random.randint(10, 3600),
                "loaded_at": datetime.now()
            }
            activities.append(activity)

    print(f"✅ Generated {len(activities)} activities")
    yield activities


def run():
    """Exécuter le pipeline"""
    pipeline = dlt.pipeline(
        pipeline_name="user_activities",
        destination="duckdb",
        dataset_name="activities_data"
    )

    load_info = pipeline.run(get_user_activities())
    print(f"📊 {load_info}")


if __name__ == "__main__":
    run()
```

**Critères de validation :**
- ✅ Deux cursors utilisés (date + user_id)
- ✅ State sauvegardé pour les deux
- ✅ Loading incrémental fonctionne

---

## 📋 Partie 4 : Validation et qualité des données (1h)

### Tâche 4.1 : Validation avec Pydantic

**Instructions :**

Créer `pipelines/validated_pipeline.py` :

```python
"""
Pipeline avec validation Pydantic
"""
import dlt
import requests
from pydantic import BaseModel, EmailStr, validator, Field
from typing import Optional
from datetime import datetime


class UserModel(BaseModel):
    """Modèle de validation pour un utilisateur"""
    user_id: int = Field(..., alias="id")
    name: str
    username: str
    email: EmailStr
    phone: str
    city: str = Field(..., alias="address__city")
    latitude: float = Field(..., alias="address__geo__lat")
    longitude: float = Field(..., alias="address__geo__lng")
    company_name: str = Field(..., alias="company__name")

    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError('Name cannot be empty')
        return v.strip()

    @validator('latitude')
    def latitude_must_be_valid(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v

    @validator('longitude')
    def longitude_must_be_valid(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

    class Config:
        allow_population_by_field_name = True


@dlt.resource(
    name="validated_users",
    write_disposition="replace",
    primary_key="user_id"
)
def get_validated_users():
    """
    Resource avec validation Pydantic
    """
    print("📥 Fetching and validating users...")

    response = requests.get("https://jsonplaceholder.typicode.com/users")
    raw_users = response.json()

    validated_users = []
    errors = []

    for user in raw_users:
        try:
            # Aplatir les données nested pour Pydantic
            flat_user = {
                "id": user["id"],
                "name": user["name"],
                "username": user["username"],
                "email": user["email"],
                "phone": user["phone"],
                "address__city": user["address"]["city"],
                "address__geo__lat": float(user["address"]["geo"]["lat"]),
                "address__geo__lng": float(user["address"]["geo"]["lng"]),
                "company__name": user["company"]["name"]
            }

            # Valider avec Pydantic
            validated = UserModel(**flat_user)

            # Ajouter des métadonnées
            user_dict = validated.dict()
            user_dict["validated_at"] = datetime.now()
            user_dict["validation_passed"] = True

            validated_users.append(user_dict)
            print(f"✅ User {validated.user_id} validated")

        except Exception as e:
            print(f"❌ Validation error for user {user.get('id')}: {e}")
            errors.append({
                "user_id": user.get("id"),
                "error": str(e),
                "timestamp": datetime.now()
            })

    print(f"\n📊 Validation summary:")
    print(f"   ✅ Valid: {len(validated_users)}")
    print(f"   ❌ Invalid: {len(errors)}")

    yield validated_users


@dlt.resource(
    name="validation_errors",
    write_disposition="append"
)
def get_validation_errors():
    """
    Sauvegarder les erreurs de validation
    """
    # Dans un vrai projet, vous stockeriez les erreurs ici
    return []


def run():
    """Exécuter le pipeline avec validation"""
    print("🚀 Starting validated pipeline...\n")

    pipeline = dlt.pipeline(
        pipeline_name="validated",
        destination="duckdb",
        dataset_name="validated_data"
    )

    load_info = pipeline.run([
        get_validated_users(),
        get_validation_errors()
    ])

    print(f"\n✅ Pipeline completed!")
    print(f"📊 {load_info}")


if __name__ == "__main__":
    run()
```

**Exécuter :**

```bash
pip install pydantic[email]
python pipelines/validated_pipeline.py
```

**Critères de validation :**
- ✅ Validation Pydantic implémentée
- ✅ Erreurs de validation capturées
- ✅ Données invalides rejetées
- ✅ Métadonnées de validation ajoutées

---

### Tâche 4.2 : Schema contracts

**Instructions :**

Créer `pipelines/schema_contracts.py` :

```python
"""
Pipeline avec schema contracts stricts
"""
import dlt


@dlt.resource(
    name="strict_products",
    write_disposition="merge",
    primary_key="product_id",
    columns={
        "product_id": {"data_type": "bigint", "nullable": False},
        "name": {"data_type": "text", "nullable": False},
        "price": {"data_type": "double", "nullable": False},
        "category": {"data_type": "text", "nullable": True}
    },
    schema_contract={
        "tables": "evolve",      # Nouvelles tables OK
        "columns": "freeze",     # Nouvelles colonnes = ERREUR
        "data_type": "freeze"    # Changement de type = ERREUR
    }
)
def get_strict_products():
    """
    Products avec schema contract strict
    """
    products = [
        {
            "product_id": 1,
            "name": "Laptop",
            "price": 999.99,
            "category": "Electronics"
        },
        {
            "product_id": 2,
            "name": "Mouse",
            "price": 29.99,
            "category": "Accessories"
        }
    ]

    yield products


def run():
    """Exécuter avec schema contract"""
    pipeline = dlt.pipeline(
        pipeline_name="strict_schema",
        destination="duckdb",
        dataset_name="strict_data"
    )

    # Première exécution : OK
    print("🚀 First run (should succeed)...")
    load_info = pipeline.run(get_strict_products())
    print(f"✅ {load_info}\n")

    # Deuxième exécution avec nouvelle colonne : ERREUR
    @dlt.resource(
        name="strict_products",
        write_disposition="merge",
        primary_key="product_id",
        schema_contract={
            "columns": "freeze"
        }
    )
    def get_products_with_new_column():
        """Nouvelle colonne = erreur avec freeze"""
        products = [
            {
                "product_id": 3,
                "name": "Keyboard",
                "price": 79.99,
                "category": "Accessories",
                "stock": 50  # ❌ Nouvelle colonne !
            }
        ]
        yield products

    print("🚀 Second run with new column (should fail)...")
    try:
        load_info = pipeline.run(get_products_with_new_column())
        print(f"✅ {load_info}")
    except Exception as e:
        print(f"❌ Expected error: {e}")


if __name__ == "__main__":
    run()
```

**Critères de validation :**
- ✅ Schema contract configuré
- ✅ Première exécution réussit
- ✅ Deuxième exécution échoue (comme attendu)
- ✅ Erreur explicite sur nouvelle colonne

---

## 🚀 Partie 5 : Pipeline production-ready (2h)

### Tâche 5.1 : Pipeline complet avec monitoring

**Scénario final :** Créer un pipeline production-ready complet avec :
- Extraction depuis une API
- Validation des données
- Loading incrémental
- Gestion d'erreurs
- Logging détaillé
- Alertes

**Instructions :**

Créer `pipelines/production_pipeline.py` :

```python
"""
Pipeline production-ready avec monitoring complet
"""
import dlt
import requests
from datetime import datetime, timedelta
import logging
from typing import Iterator, Dict, Any
from pydantic import BaseModel, EmailStr, validator
import json

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('pipeline.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class OrderModel(BaseModel):
    """Modèle de validation pour une commande"""
    order_id: str
    customer_email: EmailStr
    amount: float
    order_date: datetime
    status: str

    @validator('amount')
    def amount_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('Amount must be positive')
        return v

    @validator('status')
    def status_must_be_valid(cls, v):
        valid_statuses = ['pending', 'completed', 'cancelled']
        if v not in valid_statuses:
            raise ValueError(f'Status must be one of {valid_statuses}')
        return v


class ProductionPipeline:
    """Classe pour encapsuler le pipeline de production"""

    def __init__(self, pipeline_name: str, destination: str, dataset: str):
        self.pipeline_name = pipeline_name
        self.destination = destination
        self.dataset = dataset
        self.stats = {
            "extracted": 0,
            "validated": 0,
            "loaded": 0,
            "errors": 0
        }

    @dlt.resource(
        name="orders",
        write_disposition="append",
        primary_key="order_id"
    )
    def extract_orders(
        self,
        last_date=dlt.sources.incremental("order_date")
    ) -> Iterator[Dict[str, Any]]:
        """
        Extract : Récupérer les commandes avec loading incrémental
        """
        logger.info("📥 Starting extraction of orders...")

        # Déterminer la date de départ
        if last_date.start_value is None:
            start_date = datetime.now() - timedelta(days=7)
            logger.info(f"⚠️ First run, fetching from {start_date.date()}")
        else:
            start_date = last_date.start_value
            logger.info(f"📅 Incremental load from {start_date}")

        try:
            # Simuler extraction API (remplacer par vraie API)
            orders = self._fetch_from_api(start_date)
            self.stats["extracted"] = len(orders)
            logger.info(f"✅ Extracted {len(orders)} orders")

            # Valider et transformer
            for order in orders:
                validated_order = self._validate_and_transform(order)
                if validated_order:
                    yield validated_order

        except Exception as e:
            logger.error(f"❌ Extraction error: {e}")
            self.stats["errors"] += 1
            raise

    def _fetch_from_api(self, start_date: datetime) -> list:
        """Simuler fetch API (remplacer par vraie API)"""
        from faker import Faker
        import random

        fake = Faker()
        orders = []

        current_date = start_date
        while current_date <= datetime.now():
            for _ in range(random.randint(5, 15)):
                order = {
                    "order_id": fake.uuid4(),
                    "customer_email": fake.email(),
                    "amount": round(random.uniform(10, 1000), 2),
                    "order_date": current_date,
                    "status": random.choice(["pending", "completed", "cancelled"])
                }
                orders.append(order)

            current_date += timedelta(hours=1)

        return orders

    def _validate_and_transform(self, order: Dict) -> Dict[str, Any]:
        """Valider et transformer une commande"""
        try:
            # Valider avec Pydantic
            validated = OrderModel(**order)

            # Enrichir avec métadonnées
            order_dict = validated.dict()
            order_dict["loaded_at"] = datetime.now()
            order_dict["pipeline_version"] = "1.0.0"

            self.stats["validated"] += 1
            return order_dict

        except Exception as e:
            logger.warning(f"⚠️ Validation failed for order: {e}")
            self.stats["errors"] += 1
            # Sauvegarder dans une table d'erreurs
            return None

    def run(self):
        """Exécuter le pipeline complet"""
        logger.info("=" * 60)
        logger.info(f"🚀 STARTING PIPELINE: {self.pipeline_name}")
        logger.info("=" * 60)

        start_time = datetime.now()

        try:
            # Créer le pipeline DLT
            pipeline = dlt.pipeline(
                pipeline_name=self.pipeline_name,
                destination=self.destination,
                dataset_name=self.dataset
            )

            # Exécuter
            load_info = pipeline.run(self.extract_orders())

            # Vérifier les erreurs
            if load_info.has_failed_jobs:
                logger.error("❌ Pipeline had failed jobs!")
                self.stats["errors"] += len(load_info.load_packages[0].jobs.get("failed_jobs", []))
                raise Exception("Some jobs failed")

            self.stats["loaded"] = self.stats["validated"]

            # Durée
            duration = (datetime.now() - start_time).total_seconds()

            # Log du succès
            logger.info("=" * 60)
            logger.info("✅ PIPELINE COMPLETED SUCCESSFULLY")
            logger.info(f"📊 Extracted: {self.stats['extracted']}")
            logger.info(f"✅ Validated: {self.stats['validated']}")
            logger.info(f"💾 Loaded: {self.stats['loaded']}")
            logger.info(f"❌ Errors: {self.stats['errors']}")
            logger.info(f"⏱️ Duration: {duration:.2f}s")
            logger.info("=" * 60)

            # Sauvegarder les métriques
            self._save_metrics(duration, load_info)

            return load_info

        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()

            logger.error("=" * 60)
            logger.error("❌ PIPELINE FAILED")
            logger.error(f"Error: {e}")
            logger.error(f"⏱️ Duration: {duration:.2f}s")
            logger.error("=" * 60)

            # Envoyer alerte
            self._send_alert(f"Pipeline failed: {e}")
            raise

    def _save_metrics(self, duration: float, load_info):
        """Sauvegarder les métriques du pipeline"""
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "pipeline_name": self.pipeline_name,
            "duration_seconds": duration,
            "stats": self.stats,
            "load_info": str(load_info)
        }

        with open("pipeline_metrics.json", "a") as f:
            f.write(json.dumps(metrics) + "\n")

        logger.info("📊 Metrics saved to pipeline_metrics.json")

    def _send_alert(self, message: str):
        """Envoyer une alerte (Slack, email, etc.)"""
        logger.warning(f"🚨 ALERT: {message}")
        # Ici vous ajouteriez l'intégration Slack/email
        # requests.post(slack_webhook, json={"text": message})


def main():
    """Point d'entrée principal"""
    pipeline = ProductionPipeline(
        pipeline_name="production_orders",
        destination="duckdb",
        dataset="production_data"
    )

    pipeline.run()


if __name__ == "__main__":
    main()
```

**Exécuter :**

```bash
python pipelines/production_pipeline.py
```

**Vérifier les logs :**

```bash
cat pipeline.log
cat pipeline_metrics.json
```

**Critères de validation :**
- ✅ Pipeline production-ready complet
- ✅ Logging détaillé dans fichier
- ✅ Validation avec Pydantic
- ✅ Loading incrémental
- ✅ Gestion d'erreurs robuste
- ✅ Métriques sauvegardées
- ✅ Alertes en cas d'échec

---

### Tâche 5.2 : Scheduler avec APScheduler

**Instructions :**

Créer `pipelines/scheduler.py` :

```python
"""
Scheduler pour exécuter le pipeline automatiquement
"""
from apscheduler.schedulers.blocking import BlockingScheduler
from datetime import datetime
import logging
from production_pipeline import ProductionPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run_pipeline_job():
    """Job exécuté par le scheduler"""
    logger.info("⏰ Scheduled job triggered")

    try:
        pipeline = ProductionPipeline(
            pipeline_name="scheduled_orders",
            destination="duckdb",
            dataset="scheduled_data"
        )
        pipeline.run()

    except Exception as e:
        logger.error(f"❌ Scheduled job failed: {e}")


def main():
    """Démarrer le scheduler"""
    scheduler = BlockingScheduler()

    # Exécuter toutes les heures
    scheduler.add_job(
        run_pipeline_job,
        'interval',
        hours=1,
        next_run_time=datetime.now()  # Première exécution immédiate
    )

    logger.info("⏰ Scheduler started. Pipeline will run every hour.")
    logger.info("Press Ctrl+C to stop")

    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        logger.info("Scheduler stopped")


if __name__ == "__main__":
    # Installer APScheduler
    # pip install apscheduler
    main()
```

**Critères de validation :**
- ✅ Scheduler implémenté
- ✅ Pipeline s'exécute automatiquement
- ✅ Gestion du Ctrl+C

---

## 📤 Livrables

À la fin du brief, vous devez avoir :

### 1. Pipelines DLT (10+ fichiers) :
- ✅ `first_pipeline.py` - Premier pipeline simple
- ✅ `ecommerce_source.py` - Source complète multi-resources
- ✅ `ecommerce_to_postgres.py` - Pipeline vers PostgreSQL
- ✅ `sales_generator.py` - Générateur de données
- ✅ `incremental_orders.py` - Loading incrémental
- ✅ `multi_cursor_incremental.py` - Multi-cursors
- ✅ `validated_pipeline.py` - Validation Pydantic
- ✅ `schema_contracts.py` - Schema contracts
- ✅ `production_pipeline.py` - Pipeline production-ready
- ✅ `scheduler.py` - Scheduler automatique

### 2. Bases de données :
- ✅ DuckDB avec plusieurs datasets
- ✅ PostgreSQL avec données chargées

### 3. Fichiers de configuration :
- ✅ `.dlt/config.toml`
- ✅ `.dlt/secrets.toml`
- ✅ `requirements.txt`

### 4. Logs et métriques :
- ✅ `pipeline.log`
- ✅ `pipeline_metrics.json`

### 5. Documentation :
- ✅ README.md expliquant le projet
- ✅ Commentaires dans le code

---

## ✅ Critères d'Évaluation

| Critère | Points |
|---------|--------|
| Installation et premier pipeline | 10 |
| Sources et destinations multiples | 15 |
| Loading incrémental implémenté | 20 |
| Validation des données | 15 |
| Pipeline production-ready complet | 30 |
| Qualité du code et logs | 10 |

**Total : 100 points**

**Bonus (+10 points) :**
- Déploiement avec Airflow
- Tests unitaires complets
- Dashboard de métriques
- Documentation exceptionnelle

---

## 💡 Conseils

### Performance
- 🔄 **Loading incrémental** : Économise API calls et temps
- 📦 **Batch processing** : Utilisez yield pour traiter par lots
- 🗜️ **Compression** : Activez la compression pour les grandes tables

### Production
- 🔐 **Secrets** : Jamais en dur, toujours dans .dlt/secrets.toml
- 📝 **Logging** : Loggez tout pour le debugging
- 🚨 **Alertes** : Configurez des alertes sur échecs
- 📊 **Monitoring** : Trackez les métriques (durée, lignes, erreurs)

### Validation
- ✅ **Pydantic** : Validation robuste et explicite
- 🔒 **Schema contracts** : Utilisez-les pour des pipelines critiques
- 🧪 **Tests** : Testez avec DuckDB avant PostgreSQL/BigQuery

---

## 🆘 Troubleshooting

### Erreur : "Module dlt not found"
```bash
pip install dlt[duckdb]
```

### Erreur : "Database locked"
```bash
# Fermer toutes les connexions DuckDB
# Supprimer le fichier .wal
rm *.duckdb.wal
```

### Erreur : "Cannot connect to PostgreSQL"
```bash
# Vérifier que le conteneur tourne
docker ps | grep postgres

# Vérifier les credentials dans .dlt/secrets.toml
```

### Erreur de validation Pydantic
```python
# Activer les logs détaillés
import logging
logging.basicConfig(level=logging.DEBUG)
```

---

## 📚 Ressources

### Documentation
- [DLT Documentation](https://dlthub.com/docs)
- [DLT API Reference](https://dlthub.com/docs/reference)
- [Pydantic Documentation](https://docs.pydantic.dev/)

### Exemples
- [DLT Examples Repository](https://github.com/dlt-hub/verified-sources)
- [DLT Blog](https://dlthub.com/docs/blog)

### Community
- [DLT Discord](https://discord.gg/dlthub)
- [GitHub Issues](https://github.com/dlt-hub/dlt/issues)

---

**Bon courage ! 🚀**

*DltHub : Le framework Python moderne pour vos pipelines de données !*
