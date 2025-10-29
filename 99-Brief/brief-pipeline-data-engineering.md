# Brief : Pipeline Data Engineering - NYC Taxi Data

## Vue d'ensemble du projet

Ce projet consiste à construire une pipeline data complète pour l'ingestion, le traitement et l'analyse des données de taxis de New York (NYC Taxi Trip Records). Vous allez progressivement développer une infrastructure moderne de data engineering.

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE FINALE                          │
└─────────────────────────────────────────────────────────────────┘

    NYC Open Data (2025)
           │
           │ ① Téléchargement
           ▼
    ┌──────────────┐
    │  Parquet     │
    │   Files      │
    └──────┬───────┘
           │
           │ ② Ingestion
           ▼
    ┌──────────────┐    
    │    Azure     │
    │   PostgreSQL │
    │   (Brut)     │
    └──────┬───────┘
           │
           │ ③ Clean
           │ 
           ▼
    ┌──────────────┐
    │ DLT Pipeline │ ④  DLT Migration
    └──────┬───────┘
           │
           │ ⑤ Déploiement
           ▼
    ┌──────────────┐
    │    Azure     │
    │  MongoDB     │
    │  (Nettoyé)   │
    └──────────────┘
           │
           │ ⑥ Automatisation
           ▼
    ┌──────────────┐
    │  GitHub      │
    │  Actions     │
    │  (Mensuel)   │
    └──────────────┘
```

## Objectifs pédagogiques

- Maîtriser Git/GitHub avec un workflow professionnel (branches, PRs, semantic release)
- Développer des scripts Python robustes pour l'ingestion de données
- Travailler avec plusieurs bases de données (DuckDB, PostgreSQL, MongoDB)
- Conteneuriser une application avec Docker
- Créer une API REST avec FastAPI
- Moderniser une pipeline avec DLT (Data Load Tool)
- Déployer sur Azure avec automatisation

## Prérequis

- Git et GitHub CLI installés
- Python 3.9+ installé
- Docker et Docker Compose installés
- Compte GitHub
- Compte Azure (pour l'étape finale)
- Connaissances de base en Python, SQL et Git

## Source des données

**URL des données** : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

**Format** : Fichiers Parquet (Yellow Taxi Trip Records)

**Exemple de fichier** : https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet

**Données à utiliser** : Uniquement l'année 2025

**Structure des données** :
```
Colonnes principales :
- VendorID : Identifiant du fournisseur
- tpep_pickup_datetime : Date/heure de prise en charge
- tpep_dropoff_datetime : Date/heure de dépose
- passenger_count : Nombre de passagers
- trip_distance : Distance du trajet (miles)
- fare_amount : Montant du tarif
- tip_amount : Montant du pourboire
- total_amount : Montant total
- payment_type : Type de paiement
- ...et d'autres colonnes
```

---

## Jour 1 : Configuration Git/GitHub et Ingestion des données

### Schéma de l'étape

```
┌──────────────────────────────────────────────┐
│  JOUR 1 : Git + Download                    │
└──────────────────────────────────────────────┘

GitHub Repo
    │
    ├── main (protégée)
    │
    └── develop (protégée, ne se supprime pas)
         │
         └── feature/semantic-release
         │        │
         │        └─▶ Workflow release.yml
         │
         └── feature/data-ingestion
                  │
                  └─▶ Script Python download_data.py
                       │
                       ▼
                  data/raw/*.parquet
```

### Étape 1.1 : Initialiser le projet GitHub (1h)

**🎯 Objectifs** :
- Créer un repository public avec la GitHub CLI
- Configurer les branches et la protection
- Mettre en place Semantic Release

**📋 Tâches à réaliser** :

1. **Créer le repository via github-cli**
 

2. **Créer un README.md initial**
   - Titre du projet
   - Description concise
   - Liste des technologies utilisées (Python, Docker, PostgreSQL, MongoDB, FastAPI, DLT, Azure)

3. **Créer et protéger la branch develop**
   ```bash
   git checkout -b develop
   git push -u origin develop
   ```

   Utiliser la commande `gh api` ou via `github` pour protéger la branch develop :


**💡 Indices** :
- La branch `develop` doit être la branch par défaut pour le développement
- La branch `main` sera utilisée pour les releases
- La protection empêche la suppression accidentelle

### Étape 1.2 : Configuration Semantic Release (1h)

**🎯 Objectifs** :
- Automatiser le versioning avec Semantic Release
- Créer un workflow GitHub Actions pour les releases

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/semantic-release
   ```

2. **Créer le fichier `.github/workflows/release.yml`**


4. **Créer un `.gitignore` complet**

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv

# Data files
*.parquet
*.csv
data/

# Databases
*.db
*.duckdb
*.duckdb.wal

# Environment variables
.env
.env.local

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Node
node_modules/
package-lock.json

# Docker
docker-compose.override.yml

# OS
.DS_Store
Thumbs.db

# DLT
.dlt/secrets.toml
.dlt/.sources
```

5. **Commit et merge**
   ```bash
   git add .
   git commit -m "feat: add semantic release workflow and gitignore"
   git push -u origin feature/semantic-release
   git checkout develop
   git merge feature/semantic-release
   git push origin develop
   ```

**💡 Indices** :
- Semantic Release génère automatiquement les versions basées sur les commits
- Les commits doivent suivre la convention : `feat:`, `fix:`, `docs:`, `chore:`
- Le workflow ne se déclenche que sur la branch `main`

### Étape 1.3 : Téléchargement des données Parquet (2-3h)

**🎯 Objectifs** :
- Créer un script Python pour télécharger les fichiers Parquet de 2025
- Éviter les téléchargements en double
- Gérer les erreurs réseau

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/data-ingestion
   ```

2. **Créer la structure du projet**
   ```bash
   mkdir -p src/data
   mkdir -p data/raw
   ```

3. **Créer le fichier `requirements.txt`**
   ```
   requests==2.31.0
   pandas==2.2.0
   pyarrow==15.0.0
   fastparquet==2024.2.0
   ```

4. **Développer `src/download_data.py`**

Votre script doit contenir :

**Classe `NYCTaxiDataDownloader`** avec les méthodes suivantes :

- `__init__()` :
  - Définir les constantes : `BASE_URL`, `YEAR`, `DATA_DIR`
  - Créer le répertoire de destination si nécessaire

- `get_file_path(month: int) -> Path` :
  - Construire le chemin du fichier pour un mois donné
  - Format : `yellow_tripdata_YYYY-MM.parquet`

- `file_exists(month: int) -> bool` :
  - Vérifier si le fichier existe déjà localement
  - Retourner True/False

- `download_month(month: int) -> bool` :
  - Vérifier si le fichier existe déjà (utiliser `file_exists()`)
  - Si oui, afficher un message et retourner True
  - Sinon, télécharger le fichier depuis `BASE_URL`
  - Utiliser `requests.get()` avec `stream=True`
  - Afficher une barre de progression (optionnel)
  - Gérer les erreurs avec try/except
  - En cas d'erreur, supprimer le fichier partiel

- `download_all_available() -> list` :
  - Déterminer le mois actuel
  - Boucler de janvier au mois actuel (si année 2025)
  - Appeler `download_month()` pour chaque mois
  - Retourner la liste des fichiers téléchargés
  - Afficher un résumé

**💡 Indices** :
- Utilisez `pathlib.Path` pour la gestion des chemins
- `requests.get(url, stream=True, timeout=30)` pour le téléchargement
- `response.iter_content(chunk_size=8192)` pour lire par morceaux
- `datetime.now().month` pour obtenir le mois actuel
- N'oubliez pas de gérer les exceptions `requests.exceptions.RequestException`

**Structure attendue** :
```
src/download_data.py
   │
   ├─ class NYCTaxiDataDownloader:
   │     ├─ __init__(self)
   │     ├─ get_file_path(self, month)
   │     ├─ file_exists(self, month)
   │     ├─ download_month(self, month)
   │     └─ download_all_available(self)
   │
   └─ if __name__ == "__main__":
         └─ Créer instance et télécharger
```

5. **Tester le script**
   ```bash
   python -m venv venv
   source venv/bin/activate  # ou venv\Scripts\activate sur Windows
   pip install -r requirements.txt
   python src/download_data.py
   ```

6. **Commit et merge**
   ```bash
   git add .
   git commit -m "feat: add NYC taxi data downloader with duplicate prevention"
   git push -u origin feature/data-ingestion
   git checkout develop
   git merge feature/data-ingestion
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] Les fichiers se téléchargent dans `data/raw/`
- [ ] Les fichiers déjà présents ne sont pas re-téléchargés
- [ ] Les erreurs réseau sont gérées proprement
- [ ] Un message de progression s'affiche
- [ ] Un résumé final est affiché

---

## Jour 2 : Import dans DuckDB et Transition vers Docker

### Schéma de l'étape

```
┌──────────────────────────────────────────────┐
│  JOUR 2 : DuckDB + Docker + PostgreSQL      │
└──────────────────────────────────────────────┘

data/raw/*.parquet
      │
      │ ① Import
      ▼
┌─────────────┐
│   DuckDB    │  (Fichier local)
│   .duckdb   │
└─────────────┘

      │ ② Migration
      ▼

┌─────────────────────────────────────┐
│     Docker Compose                  │
│  ┌──────────┐    ┌──────────┐      │
│  │PostgreSQL│    │   App    │      │
│  │  :5432   │◄───│  :8000   │      │
│  └──────────┘    └──────────┘      │
└─────────────────────────────────────┘
```

### Étape 2.1 : Import des données dans DuckDB (2h)

**🎯 Objectifs** :
- Créer un script pour importer les fichiers Parquet dans DuckDB
- Éviter les imports en double avec une table de log
- Ne pas versionner la base de données

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/duckdb-import
   ```

2. **Ajouter DuckDB aux dépendances**
   Ajouter dans `requirements.txt` :
   ```
   duckdb==0.10.0
   ```

3. **Développer `src/import_to_duckdb.py`**

**Classe `DuckDBImporter`** avec les méthodes suivantes :

- `__init__(db_path: str)` :
  - Se connecter à DuckDB
  - Appeler `_initialize_database()`

- `_initialize_database()` :
  - Créer la table `yellow_taxi_trips` si elle n'existe pas
  - Créer la table `import_log` pour tracker les imports
  - La table `import_log` doit contenir : `file_name`, `import_date`, `rows_imported`

- `is_file_imported(filename: str) -> bool` :
  - Vérifier si le fichier est déjà dans `import_log`
  - Retourner True/False

- `import_parquet(file_path: Path) -> bool` :
  - Vérifier si déjà importé (utiliser `is_file_imported()`)
  - Si oui, afficher un message et retourner True
  - Sinon :
    - Compter les lignes actuelles dans la table
    - Importer avec `INSERT INTO ... SELECT * FROM read_parquet('...')`
    - Compter les nouvelles lignes
    - Enregistrer dans `import_log`
    - Gérer les erreurs

- `import_all_parquet_files(data_dir: Path) -> int` :
  - Lister tous les fichiers `.parquet` dans le répertoire
  - Appeler `import_parquet()` pour chacun
  - Retourner le nombre de fichiers importés

- `get_statistics()` :
  - Afficher le nombre total de trajets
  - Afficher le nombre de fichiers importés
  - Afficher la plage de dates (min/max)
  - Afficher la taille de la base de données

- `close()` :
  - Fermer la connexion DuckDB

**💡 Indices DuckDB** :
- `duckdb.connect(db_path)` pour se connecter
- `conn.execute(sql_query)` pour exécuter du SQL
- `conn.execute(query).fetchone()` pour récupérer un résultat
- DuckDB peut lire directement les Parquet : `read_parquet('file.parquet')`
- Utilisez des transactions pour l'intégrité des données

**Schéma de la base DuckDB** :
```sql
CREATE TABLE yellow_taxi_trips (
    VendorID BIGINT,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count DOUBLE,
    trip_distance DOUBLE,
    RatecodeID DOUBLE,
    store_and_fwd_flag VARCHAR,
    PULocationID BIGINT,
    DOLocationID BIGINT,
    payment_type BIGINT,
    fare_amount DOUBLE,
    extra DOUBLE,
    mta_tax DOUBLE,
    tip_amount DOUBLE,
    tolls_amount DOUBLE,
    improvement_surcharge DOUBLE,
    total_amount DOUBLE,
    congestion_surcharge DOUBLE,
    Airport_fee DOUBLE
);

CREATE TABLE import_log (
    file_name VARCHAR PRIMARY KEY,
    import_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rows_imported BIGINT
);
```

4. **Vérifier le `.gitignore`**
   S'assurer que ces patterns sont présents :
   ```
   *.duckdb
   *.duckdb.wal
   ```

5. **Tester et merger**
   ```bash
   pip install duckdb
   python src/import_to_duckdb.py
   git add .
   git commit -m "feat: add DuckDB importer with duplicate prevention"
   git push -u origin feature/duckdb-import
   git checkout develop
   git merge feature/duckdb-import
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] Les données sont importées dans DuckDB
- [ ] Les fichiers déjà importés ne sont pas ré-importés
- [ ] Les statistiques s'affichent correctement
- [ ] La base de données n'est pas versionnée dans Git

### Étape 2.2 : Dockerisation avec PostgreSQL (3h)

**🎯 Objectifs** :
- Créer un docker-compose avec PostgreSQL
- Migrer de DuckDB vers PostgreSQL
- Créer un workflow pour builder et publier l'image Docker

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/docker-postgres
   ```

2. **Ajouter les dépendances PostgreSQL**
   Ajouter dans `requirements.txt` :
   ```
   psycopg2-binary==2.9.9
   sqlalchemy==2.0.25
   ```

3. **Créer le fichier `.env.example`**

```
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=nyc_taxi
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Application
APP_ENV=development
```

4. **Créer le fichier `docker-compose.yml`**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: nyc-taxi-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-nyc_taxi}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: nyc-taxi-app
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-nyc_taxi}
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
    ports:
      - "8000:8000"
    volumes:
      - ./data:/app/data
      - ./src:/app/src
    depends_on:
      postgres:
        condition: service_healthy
    command: uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  postgres_data:
```

5. **Créer le `Dockerfile`**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copier les requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY src/ ./src/
COPY data/ ./data/

# Exposer le port
EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

6. **Développer `src/database.py`**

Ce fichier doit contenir :
- Configuration de la connexion PostgreSQL depuis les variables d'environnement
- Création du moteur SQLAlchemy
- Fonction `get_db()` pour obtenir une session (dépendance FastAPI)
- Fonction `init_db()` pour initialiser les tables

**💡 Indices SQLAlchemy** :
```python
DATABASE_URL = f"postgresql://{user}:{password}@{host}:{port}/{db}"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
```

7. **Développer `src/import_to_postgres.py`**

Adapter le script DuckDB pour PostgreSQL :

**Classe `PostgresImporter`** :
- Similaire à `DuckDBImporter` mais avec PostgreSQL
- Utiliser SQLAlchemy pour les connexions
- Utiliser `pandas.to_sql()` pour l'import
- Créer les mêmes tables : `yellow_taxi_trips` et `import_log`

**💡 Indices** :
- Renommer les colonnes pour correspondre au schéma PostgreSQL (snake_case)
- Utiliser `df.to_sql('table_name', engine, if_exists='append')`
- Les types PostgreSQL diffèrent légèrement : `DOUBLE PRECISION`, `SERIAL PRIMARY KEY`

8. **Créer le workflow `.github/workflows/docker-build.yml`**
    objectif créer une image docker et la push sur le registry de github

9. **Tester et merger**
   ```bash
   cp .env.example .env
   docker-compose up -d postgres
   pip install psycopg2-binary sqlalchemy pandas
   python src/import_to_postgres.py

   git add .
   git commit -m "feat: add Docker support with PostgreSQL and build workflow"
   git push -u origin feature/docker-postgres
   git checkout develop
   git merge feature/docker-postgres
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] PostgreSQL démarre dans Docker
- [ ] Les données s'importent correctement
- [ ] L'image Docker se build sans erreur
- [ ] Le workflow GitHub Actions est configuré

---

## Jour 3 : API REST avec FastAPI

### Schéma de l'étape

```
┌────────────────────────────────────────────────┐
│  JOUR 3 : API FastAPI (Architecture MVC)      │
└────────────────────────────────────────────────┘

        API REST (FastAPI)
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐
│ Routes │ │Services│ │ Models │
│        │ │        │ │        │
│ GET    │─│ CRUD   │─│SQLAlch.│
│ POST   │ │Logic   │ │Schemas │
│ PUT    │ │        │ │        │
│ DELETE │ │        │ │        │
└────────┘ └────────┘ └────────┘
              │
              ▼
         PostgreSQL
```

### Étape 3.1 : Créer le CRUD avec FastAPI (4h)

**🎯 Objectifs** :
- Créer un CRUD complet sur PostgreSQL
- Organiser le code avec Models, Services et Routes
- Ajouter une route pour exécuter les scripts de téléchargement et import
- Générer une documentation automatique avec Swagger

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/fastapi-crud
   ```

2. **Ajouter FastAPI aux dépendances**
   ```
   fastapi==0.109.0
   uvicorn[standard]==0.27.0
   pydantic==2.5.3
   pydantic-settings==2.1.0
   ```

3. **Développer `src/models.py` (Modèles SQLAlchemy)**

Créer les modèles SQLAlchemy :

**Classe `YellowTaxiTrip(Base)`** :
- Hériter de `Base` (SQLAlchemy)
- Définir `__tablename__ = "yellow_taxi_trips"`
- Définir toutes les colonnes correspondant au schéma PostgreSQL
- Ajouter un `id` en primary key

**Classe `ImportLog(Base)`** :
- Table pour tracker les imports
- Colonnes : `file_name`, `import_date`, `rows_imported`

**💡 Structure attendue** :
```python
from sqlalchemy import Column, Integer, String, Float, DateTime, BigInteger
from src.database import Base

class YellowTaxiTrip(Base):
    __tablename__ = "yellow_taxi_trips"
    # Définir toutes les colonnes ici

class ImportLog(Base):
    __tablename__ = "import_log"
    # Définir les colonnes de log
```

4. **Développer `src/schemas.py` (Schémas Pydantic)**

Créer les schémas de validation Pydantic :

**Schémas à créer** :
- `TaxiTripBase` : Schéma de base avec tous les champs
- `TaxiTripCreate` : Hérite de `TaxiTripBase` (pour création)
- `TaxiTripUpdate` : Hérite de `TaxiTripBase` (pour mise à jour)
- `TaxiTrip` : Hérite de `TaxiTripBase` + `id` (pour réponse)
- `TaxiTripList` : Contient `total` et `trips: list[TaxiTrip]`
- `Statistics` : Pour les statistiques (total, dates, moyennes)
- `PipelineResponse` : Pour les réponses de la pipeline

**💡 Indices Pydantic** :
```python
from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class TaxiTripBase(BaseModel):
    # Tous les champs avec Optional[type] = None

class TaxiTrip(TaxiTripBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
```

5. **Développer `src/services.py` (Logique métier)**

**Classe `TaxiTripService`** avec méthodes statiques :

- `get_trip(db: Session, trip_id: int)` :
  - Récupérer un trajet par ID
  - Retourner None si non trouvé

- `get_trips(db: Session, skip: int, limit: int)` :
  - Récupérer une liste de trajets avec pagination
  - Retourner (trips, total)

- `create_trip(db: Session, trip: TaxiTripCreate)` :
  - Créer un nouveau trajet
  - Sauvegarder en base
  - Retourner le trajet créé

- `update_trip(db: Session, trip_id: int, trip: TaxiTripUpdate)` :
  - Mettre à jour un trajet existant
  - Retourner None si non trouvé

- `delete_trip(db: Session, trip_id: int)` :
  - Supprimer un trajet
  - Retourner True/False

- `get_statistics(db: Session)` :
  - Calculer les statistiques (COUNT, MIN, MAX, AVG)
  - Retourner un objet `Statistics`

**💡 Indices SQLAlchemy** :
```python
from sqlalchemy.orm import Session
from sqlalchemy import func

# Requête
db.query(Model).filter(Model.id == id).first()

# Comptage
db.query(func.count(Model.id)).scalar()

# Statistiques
db.execute(text("SELECT AVG(column) FROM table")).fetchone()
```

6. **Développer `src/routes.py` (Endpoints API)**

**Router FastAPI** avec les endpoints suivants :

**CRUD Trajets** :
- `GET /trips` : Liste avec pagination (skip, limit)
- `GET /trips/{trip_id}` : Un trajet par ID
- `POST /trips` : Créer un trajet
- `PUT /trips/{trip_id}` : Mettre à jour un trajet
- `DELETE /trips/{trip_id}` : Supprimer un trajet

**Statistiques** :
- `GET /statistics` : Obtenir les statistiques

**Pipeline** :
- `POST /pipeline/run` : Exécuter téléchargement + import

**💡 Structure attendue** :
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

router = APIRouter()

@router.get("/trips", response_model=TaxiTripList, tags=["Trips"])
def get_trips(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    # Appeler le service
    # Retourner la réponse
```

7. **Développer `src/main.py` (Application principale)**

Créer l'application FastAPI :
- Initialiser l'app avec titre et description
- Configurer CORS
- Inclure le router avec prefix `/api/v1`
- Créer les routes `/` et `/health`
- Créer les tables au démarrage

**💡 Structure** :
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.database import engine, Base
from src.routes import router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NYC Taxi Data Pipeline API",
    description="...",
    version="1.0.0"
)

app.add_middleware(CORSMiddleware, ...)
app.include_router(router, prefix="/api/v1")
```

8. **Tester l'API**
   ```bash
   pip install fastapi uvicorn pydantic pydantic-settings
   docker-compose up -d
   uvicorn src.main:app --reload
   ```

   Accéder à la documentation : http://localhost:8000/docs

9. **Merger**
   ```bash
   git add .
   git commit -m "feat: add FastAPI CRUD with models, services and routes"
   git push -u origin feature/fastapi-crud
   git checkout develop
   git merge feature/fastapi-crud
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] L'API démarre sans erreur
- [ ] La documentation Swagger est accessible
- [ ] Les endpoints CRUD fonctionnent
- [ ] Les statistiques s'affichent
- [ ] La route pipeline fonctionne

**📊 Endpoints attendus** :
```
GET    /                      → Info API
GET    /health                → Health check
GET    /api/v1/trips          → Liste des trajets
GET    /api/v1/trips/{id}     → Un trajet
POST   /api/v1/trips          → Créer un trajet
PUT    /api/v1/trips/{id}     → Modifier un trajet
DELETE /api/v1/trips/{id}     → Supprimer un trajet
GET    /api/v1/statistics     → Statistiques
POST   /api/v1/pipeline/run   → Exécuter la pipeline
```

---

## Jour 4 : Analyse et nettoyage des données avec MongoDB

### Schéma de l'étape

```
┌────────────────────────────────────────────────┐
│  JOUR 4 : Data Cleaning + MongoDB             │
└────────────────────────────────────────────────┘

PostgreSQL (Données brutes)
      │
      │ ① Extraction
      ▼
┌────────────┐
│ DataFrame  │
│  (Pandas)  │
└─────┬──────┘
      │
      │ ② Analyse
      ▼
┌────────────┐
│  Détection │
│  Anomalies │
│            │
│ • Négatifs │
│ • Nulls    │
│ • Outliers │
└─────┬──────┘
      │
      │ ③ Nettoyage
      ▼
┌────────────┐
│ Filtrage   │
│ Suppression│
└─────┬──────┘
      │
      │ ④ Sauvegarde
      ▼
┌────────────┐
│  MongoDB   │
│  (Clean)   │
└────────────┘
```

### Étape 4.1 : Analyser et nettoyer les données (4h)

**🎯 Objectifs** :
- Analyser les données pour détecter les anomalies
- Créer un script pour nettoyer les données
- Sauvegarder les données nettoyées dans MongoDB

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/data-cleaning-mongodb
   ```

2. **Ajouter MongoDB aux dépendances**
   ```
   pymongo==4.6.1
   motor==3.3.2
   ```

3. **Ajouter MongoDB dans `docker-compose.yml`**

```yaml
  mongodb:
    image: mongo:7
    container_name: nyc-taxi-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER:-admin}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-admin}
      MONGO_INITDB_DATABASE: ${MONGO_DB:-nyc_taxi_clean}
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

volumes:
  postgres_data:
  mongodb_data:
```

4. **Ajouter les variables MongoDB dans `.env.example`**
   ```
   # MongoDB
   MONGO_USER=admin
   MONGO_PASSWORD=admin
   MONGO_DB=nyc_taxi_clean
   MONGO_HOST=mongodb
   MONGO_PORT=27017
   ```

5. **Développer `src/data_cleaner.py`**

**Classe `DataCleaner`** avec les méthodes suivantes :

**a) Initialisation et connexions** :

- `__init__()` :
  - Créer la connexion PostgreSQL (avec SQLAlchemy)
  - Créer la connexion MongoDB (avec pymongo)
  - Initialiser la collection `cleaned_trips`

- `_get_postgres_engine()` :
  - Construire l'URL de connexion depuis les variables d'environnement
  - Retourner le moteur SQLAlchemy

- `_get_mongo_client()` :
  - Construire l'URL de connexion MongoDB
  - Retourner le client MongoDB

**b) Chargement des données** :

- `load_data_from_postgres()` :
  - Charger toutes les données depuis PostgreSQL
  - Utiliser `pd.read_sql()`
  - Retourner un DataFrame

**c) Analyse des données** :

- `analyze_data(df: pd.DataFrame) -> Dict` :
  - Analyser les valeurs négatives pour : `passenger_count`, `trip_distance`, `fare_amount`, `tip_amount`, `tolls_amount`, `total_amount`
  - Analyser les valeurs nulles
  - Analyser les outliers :
    - `passenger_count` : doit être entre 1 et 8
    - `trip_distance` : ne doit pas dépasser 100 miles
    - `fare_amount` : ne doit pas dépasser $500
  - Retourner un dictionnaire avec les statistiques

**d) Nettoyage des données** :

- `clean_data(df: pd.DataFrame) -> pd.DataFrame` :
  - Supprimer les lignes avec valeurs négatives
  - Supprimer les lignes avec `passenger_count` < 1 ou > 8
  - Supprimer les lignes avec `trip_distance` > 100
  - Supprimer les lignes avec `fare_amount` > 500
  - Supprimer les lignes avec dates manquantes
  - Afficher un résumé du nettoyage
  - Retourner le DataFrame nettoyé

**e) Sauvegarde dans MongoDB** :

- `save_to_mongodb(df: pd.DataFrame) -> int` :
  - Convertir le DataFrame en liste de dictionnaires
  - Convertir les Timestamp Pandas en datetime Python
  - Supprimer l'ID PostgreSQL
  - Vérifier si des données existent déjà dans MongoDB
  - Si oui, supprimer les anciennes données
  - Insérer les nouvelles données
  - Retourner le nombre de documents insérés

**f) Fermeture** :

- `close()` :
  - Fermer la connexion MongoDB

**💡 Règles de nettoyage** :
```
Valeurs négatives à supprimer :
- passenger_count < 0
- trip_distance < 0
- fare_amount < 0
- tip_amount < 0
- tolls_amount < 0
- total_amount < 0

Outliers à supprimer :
- passenger_count < 1 ou > 8
- trip_distance > 100 miles
- fare_amount > $500

Valeurs manquantes :
- tpep_pickup_datetime NULL
- tpep_dropoff_datetime NULL
```

**💡 Indices Pandas/MongoDB** :
```python
# Filtrage Pandas
df = df[df['column'] >= 0]
df = df[(df['col'] >= min) & (df['col'] <= max)]
df = df.dropna(subset=['col1', 'col2'])

# MongoDB
client = MongoClient(f"mongodb://{user}:{password}@{host}:{port}/")
collection.count_documents({})
collection.delete_many({})
collection.insert_many(records)

# Conversion Pandas Timestamp
if isinstance(value, pd.Timestamp):
    value = value.to_pydatetime()
```

6. **Structure du script principal**
   ```python
   if __name__ == "__main__":
       cleaner = DataCleaner()
       try:
           # Charger
           df = cleaner.load_data_from_postgres()

           # Analyser
           analysis = cleaner.analyze_data(df)

           # Nettoyer
           cleaned_df = cleaner.clean_data(df)

           # Sauvegarder
           cleaner.save_to_mongodb(cleaned_df)
       finally:
           cleaner.close()
   ```

7. **Tester et merger**
   ```bash
   pip install pymongo
   docker-compose up -d mongodb
   python src/data_cleaner.py

   git add .
   git commit -m "feat: add data cleaning and MongoDB integration"
   git push -u origin feature/data-cleaning-mongodb
   git checkout develop
   git merge feature/data-cleaning-mongodb
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] L'analyse détecte correctement les anomalies
- [ ] Le nettoyage supprime les lignes problématiques
- [ ] Les données sont sauvegardées dans MongoDB
- [ ] Les statistiques avant/après sont affichées

**📊 Exemple de sortie attendue** :
```
📊 Analyse des données brutes :
  ⚠ fare_amount: 1,245 valeurs négatives
  ⚠ passenger_count: 3,567 valeurs aberrantes (< 1 ou > 8)
  ⚠ trip_distance: 892 trajets > 100 miles

🧹 Nettoyage des données...
  ✓ Supprimé 1,245 lignes avec fare_amount négatif
  ✓ Supprimé 3,567 lignes avec passenger_count invalide
  ✓ Supprimé 892 lignes avec trip_distance > 100 miles

  📈 Total supprimé : 5,704 lignes (2.34%)
  ✅ Lignes restantes : 238,296

💾 Sauvegarde dans MongoDB...
  ✅ 238,296 documents insérés dans MongoDB
```

---

## Jour 5 : Migration vers DLT (Data Load Tool)

### Schéma de l'étape

```
┌────────────────────────────────────────────────┐
│  JOUR 5 : Migration DLT                        │
└────────────────────────────────────────────────┘

    Scripts Python (avant)          DLT Pipeline (après)
┌────────────────────────┐     ┌──────────────────────┐
│ download_data.py       │     │                      │
│ import_to_postgres.py  │ ──▶ │  dlt_pipeline.py     │
│ data_cleaner.py        │     │                      │
└────────────────────────┘     │  ┌────────────────┐  │
                               │  │  @dlt.resource │  │
                               │  │  - Download    │  │
                               │  │  - Clean       │  │
                               │  │  - Load        │  │
                               │  └────────────────┘  │
                               └──────────┬───────────┘
                                          │
                                          ▼
                                   PostgreSQL/MongoDB
```

### Étape 5.1 : Remplacer les scripts par DLT (4-5h)

**🎯 Objectifs** :
- Comprendre DLT et ses avantages
- Créer une pipeline DLT unifiée
- Obtenir le même résultat avec moins de code

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/dlt-migration
   ```

2. **Installer DLT**
   ```bash
   pip install dlt[postgres,parquet]
   ```

   Ajouter dans `requirements.txt` :
   ```
   dlt[postgres,parquet]==0.4.3
   ```

3. **Initialiser DLT**
   ```bash
   dlt init nyc_taxi postgres
   ```

4. **Créer la configuration `.dlt/config.toml`**

```toml
[runtime]
log_level = "INFO"

[sources.nyc_taxi]
year = 2025
```

5. **Créer le fichier de secrets `.dlt/secrets.toml`** (NE PAS COMMITTER)

```toml
[destination.postgres.credentials]
database = "nyc_taxi"
username = "postgres"
password = "postgres"
host = "localhost"
port = 5432
```

6. **Ajouter `.dlt/secrets.toml` au `.gitignore`**

7. **Développer `src/dlt_pipeline.py`**

**Comprendre DLT** :

DLT (Data Load Tool) est un framework Python pour créer des pipelines de données. Les concepts clés :

- **Resource** : Source de données (décorateur `@dlt.resource`)
- **Pipeline** : Orchestration des resources
- **Destination** : Où stocker les données (PostgreSQL, BigQuery, etc.)
- **write_disposition** : Comment gérer les doublons
  - `append` : Ajouter (pas de doublons)
  - `replace` : Remplacer tout
  - `merge` : Fusionner sur clé

**Classe `NYCTaxiDLTPipeline`** :

**a) Initialisation** :

- `__init__()` :
  - Définir les constantes (BASE_URL, YEAR, DATA_DIR)
  - Créer le répertoire de données

**b) Resource DLT** :

- `load_taxi_data()` (décorée avec `@dlt.resource`) :
  - Paramètres du décorateur :
    - `name="yellow_taxi_trips"`
    - `write_disposition="append"` (pour éviter les doublons)
  - Logique :
    1. Déterminer les mois à traiter
    2. Pour chaque mois :
       - Télécharger si nécessaire (`_download_if_needed()`)
       - Lire le Parquet avec pandas
       - Nettoyer les données (`_clean_data()`)
       - Normaliser les noms de colonnes
       - Yielder chaque enregistrement (dictionnaire)

**c) Méthodes privées** :

- `_download_if_needed(month: int) -> Path` :
  - Vérifier si le fichier existe
  - Sinon, télécharger depuis l'URL
  - Retourner le chemin du fichier

- `_clean_data(df: pd.DataFrame) -> pd.DataFrame` :
  - Appliquer les mêmes règles de nettoyage que `data_cleaner.py`
  - Retourner le DataFrame nettoyé

**d) Exécution de la pipeline** :

- `run_pipeline(destination: str = "postgres")` :
  - Créer la pipeline DLT :
    ```python
    pipeline = dlt.pipeline(
        pipeline_name="nyc_taxi_pipeline",
        destination=destination,
        dataset_name="nyc_taxi_dlt"
    )
    ```
  - Exécuter : `pipeline.run(self.load_taxi_data())`
  - Retourner les informations de chargement

**💡 Structure DLT** :
```python
import dlt
from typing import Iterator, Dict, Any

class NYCTaxiDLTPipeline:

    @dlt.resource(name="yellow_taxi_trips", write_disposition="append")
    def load_taxi_data(self) -> Iterator[Dict[str, Any]]:
        # Pour chaque mois
        for month in range(1, max_month + 1):
            # Télécharger
            file_path = self._download_if_needed(month)

            # Lire et nettoyer
            df = pd.read_parquet(file_path)
            df = self._clean_data(df)

            # Yielder chaque ligne
            for record in df.to_dict('records'):
                yield record

    def run_pipeline(self):
        pipeline = dlt.pipeline(
            pipeline_name="...",
            destination="postgres",
            dataset_name="..."
        )

        load_info = pipeline.run(self.load_taxi_data())
        return load_info
```

8. **Créer la documentation `docs/DLT_MIGRATION.md`**

Créer un fichier markdown expliquant :

**Avantages de DLT** :
- Gestion automatique des doublons
- Schéma automatique
- Monitoring intégré
- Incrémental par défaut
- Portable (PostgreSQL, BigQuery, Snowflake, etc.)

**Tableau comparatif** :

| Fonctionnalité | Scripts Python | DLT |
|----------------|----------------|-----|
| Téléchargement | Manuel avec requests | Intégré dans resource |
| Dédoublonnage | Table import_log | write_disposition="append" |
| Nettoyage | Script séparé | Intégré dans resource |
| Monitoring | print() | Logs DLT + métriques |
| Destination | Hardcodé PostgreSQL | Configurable |
| Schéma | Défini manuellement | Détection automatique |

**Instructions d'utilisation** :
- Comment installer DLT
- Comment configurer les credentials
- Comment exécuter la pipeline

9. **Tester la pipeline**
   ```bash
   python src/dlt_pipeline.py
   ```

10. **Merger**
   ```bash
   git add .
   git commit -m "feat: migrate to DLT for data pipeline"
   git push -u origin feature/dlt-migration
   git checkout develop
   git merge feature/dlt-migration
   git push origin develop
   ```

**🔍 Points de vérification** :
- [ ] La pipeline DLT se lance sans erreur
- [ ] Les données sont téléchargées
- [ ] Les données sont nettoyées
- [ ] Les données sont chargées dans PostgreSQL
- [ ] Pas de doublons lors d'une ré-exécution

**💡 Avantages DLT constatés** :
- Un seul fichier au lieu de 3 scripts
- Gestion automatique des doublons (pas besoin de table import_log)
- Schéma automatiquement détecté
- Logs et métriques intégrés
- Facilement portable vers d'autres destinations (BigQuery, Snowflake...)

---

## Jour 6 : Déploiement Azure et automatisation

### Schéma de l'étape

```
┌────────────────────────────────────────────────┐
│  JOUR 6 : Déploiement Azure + Automatisation  │
└────────────────────────────────────────────────┘

    GitHub Repository
          │
          │ Push sur main
          ▼
    GitHub Actions
    ┌─────────────┐
    │  Workflow   │
    │  Scheduler  │
    │  (Mensuel)  │
    └──────┬──────┘
           │
           │ ① Exécution DLT
           ▼
    ┌─────────────┐
    │  Pipeline   │
    │  DLT        │
    └──────┬──────┘
           │
           │ ② Chargement
           ▼
    ┌─────────────┐
    │   Azure     │
    │ PostgreSQL  │
    │ Flexible    │
    │  Server     │
    └─────────────┘

    Scheduling:
    ┌─────┬─────┬─────┬─────┬─────┐
    │ Jan │ Feb │ Mar │ Apr │ ... │
    └──┬──┴──┬──┴──┬──┴──┬──┴─────┘
       │     │     │     │
       ▼     ▼     ▼     ▼
      Run   Run   Run   Run
```

### Étape 6.1 : Déploiement sur Azure (4-5h)

**🎯 Objectifs** :
- Créer une base de données PostgreSQL sur Azure
- Configurer les secrets GitHub
- Créer un workflow GitHub Actions schedulé (mensuel)
- Tester l'exécution automatique

**📋 Tâches à réaliser** :

1. **Créer une feature branch**
   ```bash
   git checkout develop
   git checkout -b feature/azure-deployment
   ```

2. **Installer Azure CLI**

   Selon votre OS :
   ```bash
   # macOS
   brew install azure-cli

   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Windows
   # Télécharger depuis https://aka.ms/installazurecliwindows
   ```

3. **Se connecter à Azure**
   ```bash
   az login
   ```

4. **Créer le script `scripts/deploy_azure.sh`**

Le script doit :
- Créer un resource group
- Créer un serveur PostgreSQL Flexible
- Créer la base de données
- Configurer le firewall pour autoriser GitHub Actions

```bash
#!/bin/bash

# Configuration
RESOURCE_GROUP="nyc-taxi-rg"
LOCATION="francecentral"
POSTGRES_SERVER="nyc-taxi-postgres-server"
POSTGRES_DB="nyc_taxi"
POSTGRES_ADMIN="taxiadmin"
POSTGRES_PASSWORD="YourStrongPassword123!"

echo "🚀 Déploiement sur Azure"
echo "="*60

# Créer le resource group
echo "📦 Création du resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Créer le serveur PostgreSQL
echo "🐘 Création du serveur PostgreSQL..."
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --location $LOCATION \
  --admin-user $POSTGRES_ADMIN \
  --admin-password $POSTGRES_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 16 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Créer la base de données
echo "💾 Création de la base de données..."
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --database-name $POSTGRES_DB

# Configurer le firewall
echo "🔥 Configuration du firewall..."
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --rule-name AllowGitHubActions \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255

echo "✅ Déploiement terminé !"
echo ""
echo "📝 Informations de connexion :"
echo "  Host: $POSTGRES_SERVER.postgres.database.azure.com"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_ADMIN"
echo "  Password: $POSTGRES_PASSWORD"
```

5. **Créer le workflow `.github/workflows/scheduled-dlt-pipeline.yml`**

```yaml
name: Scheduled DLT Pipeline

on:
  schedule:
    # Exécuter le 1er de chaque mois à 2h du matin (UTC)
    - cron: '0 2 1 * *'
  workflow_dispatch:  # Permet l'exécution manuelle

env:
  PYTHON_VERSION: '3.11'

jobs:
  run-dlt-pipeline:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Configure DLT secrets
        run: |
          mkdir -p .dlt
          cat > .dlt/secrets.toml << EOF
          [destination.postgres.credentials]
          database = "${{ secrets.AZURE_POSTGRES_DB }}"
          username = "${{ secrets.AZURE_POSTGRES_USER }}"
          password = "${{ secrets.AZURE_POSTGRES_PASSWORD }}"
          host = "${{ secrets.AZURE_POSTGRES_HOST }}"
          port = 5432
          EOF

      - name: Run DLT Pipeline
        run: |
          echo "🚀 Démarrage de la pipeline DLT"
          python src/dlt_pipeline.py
        env:
          POSTGRES_HOST: ${{ secrets.AZURE_POSTGRES_HOST }}
          POSTGRES_DB: ${{ secrets.AZURE_POSTGRES_DB }}
          POSTGRES_USER: ${{ secrets.AZURE_POSTGRES_USER }}
          POSTGRES_PASSWORD: ${{ secrets.AZURE_POSTGRES_PASSWORD }}

      - name: Notify on success
        if: success()
        run: |
          echo "✅ Pipeline DLT exécutée avec succès !"

      - name: Notify on failure
        if: failure()
        run: |
          echo "❌ Échec de la pipeline DLT"
          exit 1
```

**💡 Comprendre le Cron** :
```
'0 2 1 * *'
 │ │ │ │ │
 │ │ │ │ └─── Jour de la semaine (0-6, 0=Dimanche)
 │ │ │ └───── Mois (1-12)
 │ │ └─────── Jour du mois (1-31)
 │ └───────── Heure (0-23)
 └─────────── Minute (0-59)

Exemples :
'0 2 1 * *'   → Le 1er de chaque mois à 2h du matin
'0 0 * * 0'   → Tous les dimanches à minuit
'30 14 * * *' → Tous les jours à 14h30
```

6. **Créer la documentation `docs/AZURE_DEPLOYMENT.md`**

Cette documentation doit contenir :

**a) Prérequis** :
- Compte Azure
- Azure CLI installé
- Droits de création de ressources

**b) Guide de déploiement** :
- Commandes pour exécuter le script
- Configuration des secrets GitHub
- Test du workflow

**c) Coûts estimés** :
| Service | Tier | Coût mensuel estimé |
|---------|------|---------------------|
| PostgreSQL Flexible Server | Burstable B1ms | ~25€ |
| GitHub Actions | 2000 min/mois gratuit | Gratuit |

**d) Sécurité** :
- Recommandations pour le firewall
- Utilisation d'Azure Key Vault
- Activation SSL/TLS
- Alertes de monitoring

**e) Commandes utiles** :
```bash
# Vérifier l'état du serveur
az postgres flexible-server show \
  --resource-group nyc-taxi-rg \
  --name nyc-taxi-postgres-server

# Voir les métriques
az monitor metrics list \
  --resource <resource-id> \
  --metric-names cpu_percent,memory_percent

# Supprimer toutes les ressources
az group delete --name nyc-taxi-rg --yes --no-wait
```

7. **Créer la documentation `docs/TESTING_GUIDE.md`**

Guide de test avec :

**Tests locaux** :
- Tester le téléchargement
- Tester l'import PostgreSQL
- Tester l'API
- Tester DLT

**Tests Azure** :
- Exécution manuelle du workflow
- Vérification des logs
- Validation des données

**Requêtes de validation** :
```sql
-- PostgreSQL
SELECT COUNT(*) FROM yellow_taxi_trips;
SELECT MIN(tpep_pickup_datetime), MAX(tpep_pickup_datetime) FROM yellow_taxi_trips;
SELECT AVG(trip_distance), AVG(fare_amount) FROM yellow_taxi_trips;
```

```javascript
// MongoDB
db.cleaned_trips.countDocuments()
db.cleaned_trips.aggregate([
  { $group: {
      _id: null,
      avg_distance: { $avg: "$trip_distance" },
      total: { $sum: 1 }
    }
  }
])
```

8. **Mettre à jour le README principal**

Créer un README complet avec :

**Architecture** (diagramme ASCII) :
```
[NYC Data] → [Download] → [PostgreSQL] → [Clean] → [MongoDB]
                ↓
             [DLT Pipeline]
                ↓
          [Azure PostgreSQL]
                ↓
         [Scheduled Job (monthly)]
```

**Technologies** :
- Backend : Python 3.11, FastAPI
- Bases de données : PostgreSQL, MongoDB, DuckDB
- ETL : DLT (Data Load Tool)
- Containerisation : Docker, Docker Compose
- CI/CD : GitHub Actions, Semantic Release
- Cloud : Azure (PostgreSQL Flexible Server)

**Démarrage rapide** :
- Installation
- Configuration
- Lancement local
- Accès à l'API

**Liens vers la documentation** :
- Déploiement Azure
- Migration DLT
- Guide de test

**Workflow Git** :
- Branches (main, develop, feature/*)
- Conventions de commits

9. **Déployer sur Azure**
   ```bash
   chmod +x scripts/deploy_azure.sh
   ./scripts/deploy_azure.sh
   ```

10. **Configurer les secrets GitHub**

Via l'interface web GitHub (Settings > Secrets and variables > Actions) :

- `AZURE_POSTGRES_HOST` : `votre-serveur.postgres.database.azure.com`
- `AZURE_POSTGRES_DB` : `nyc_taxi`
- `AZURE_POSTGRES_USER` : `taxiadmin`
- `AZURE_POSTGRES_PASSWORD` : `VotreMotDePasse123!`

Ou via GitHub CLI :
```bash
gh secret set AZURE_POSTGRES_HOST --body "votre-serveur.postgres.database.azure.com"
gh secret set AZURE_POSTGRES_DB --body "nyc_taxi"
gh secret set AZURE_POSTGRES_USER --body "taxiadmin"
gh secret set AZURE_POSTGRES_PASSWORD --body "VotreMotDePasse123!"
```

11. **Tester le workflow manuellement**
   ```bash
   gh workflow run scheduled-dlt-pipeline.yml
   ```

   Vérifier l'exécution :
   ```bash
   gh run list --workflow=scheduled-dlt-pipeline.yml
   gh run view <run-id> --log
   ```

12. **Merger final**
   ```bash
   git add .
   git commit -m "feat: add Azure deployment and scheduled workflow"
   git push -u origin feature/azure-deployment
   git checkout develop
   git merge feature/azure-deployment
   git push origin develop

   # Merger develop dans main pour déclencher la release
   git checkout main
   git merge develop
   git push origin main
   ```

**🔍 Points de vérification** :
- [ ] Le serveur PostgreSQL est créé sur Azure
- [ ] Les secrets GitHub sont configurés
- [ ] Le workflow s'exécute manuellement sans erreur
- [ ] Les données sont chargées dans Azure PostgreSQL
- [ ] Le workflow schedulé est activé

---

## Livrables attendus

À la fin du brief, votre repository devra contenir :

### 1. Repository GitHub structuré

```
nyc-taxi-pipeline/
│
├── .github/
│   └── workflows/
│       ├── release.yml
│       ├── docker-build.yml
│       └── scheduled-dlt-pipeline.yml
│
├── src/
│   ├── download_data.py
│   ├── import_to_duckdb.py
│   ├── import_to_postgres.py
│   ├── data_cleaner.py
│   ├── dlt_pipeline.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── services.py
│   ├── routes.py
│   └── main.py
│
├── scripts/
│   └── deploy_azure.sh
│
├── docs/
│   ├── AZURE_DEPLOYMENT.md
│   ├── DLT_MIGRATION.md
│   └── TESTING_GUIDE.md
│
├── .dlt/
│   ├── config.toml
│   └── secrets.toml (non versionné)
│
├── data/
│   └── raw/ (non versionné)
│
├── .gitignore
├── .releaserc.json
├── .env.example
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── README.md
```

### 2. Fonctionnalités implémentées

- [x] Téléchargement automatique des données NYC Taxi 2025
- [x] Import dans DuckDB puis PostgreSQL
- [x] Analyse et nettoyage des données
- [x] Sauvegarde des données nettoyées dans MongoDB
- [x] API REST complète avec FastAPI (CRUD)
- [x] Pipeline DLT unifiée
- [x] Conteneurisation Docker
- [x] Déploiement Azure
- [x] Automatisation mensuelle via GitHub Actions

### 3. Infrastructure

- Docker Compose avec PostgreSQL et MongoDB
- Image Docker versionnée sur GitHub Container Registry
- Base de données PostgreSQL sur Azure
- Workflow schedulé fonctionnel

### 4. Documentation

- README principal complet
- Guide de déploiement Azure
- Documentation de migration DLT
- Guide de test et validation

---

## Critères d'évaluation

| Critère | Points | Détails |
|---------|--------|---------|
| **Repository Git** | 10 | Structure, branches, protection, commits |
| **Gestion des branches** | 10 | Feature branches, merges propres, pas de commits directs sur main |
| **Qualité du code Python** | 15 | Lisibilité, organisation, gestion d'erreurs, docstrings |
| **API FastAPI** | 15 | CRUD complet, schémas Pydantic, documentation Swagger |
| **Intégration Docker** | 10 | docker-compose fonctionnel, Dockerfile optimisé |
| **Migration DLT** | 15 | Pipeline fonctionnelle, pas de doublons, documentation |
| **Déploiement Azure** | 15 | PostgreSQL déployé, workflow schedulé, secrets configurés |
| **Documentation** | 10 | README, guides, clarté, exemples |
| **TOTAL** | **100** | |

### Grille détaillée

**Excellence (90-100)** :
- Code propre et professionnel
- Documentation exhaustive
- Gestion d'erreurs robuste
- Tests de bout en bout
- Optimisations avancées

**Bien (75-89)** :
- Toutes les fonctionnalités implémentées
- Code fonctionnel
- Documentation complète
- Quelques améliorations possibles

**Satisfaisant (60-74)** :
- Fonctionnalités principales présentes
- Code fonctionnel mais améliorable
- Documentation basique

**Insuffisant (<60)** :
- Fonctionnalités manquantes
- Erreurs fréquentes
- Documentation incomplète

---

## Ressources

### Documentation officielle

- **NYC Taxi Data** : https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- **DLT** : https://dlthub.com/docs
- **FastAPI** : https://fastapi.tiangolo.com
- **PostgreSQL** : https://www.postgresql.org/docs/
- **MongoDB** : https://www.mongodb.com/docs/
- **Docker** : https://docs.docker.com
- **Azure PostgreSQL** : https://learn.microsoft.com/azure/postgresql/
- **GitHub Actions** : https://docs.github.com/actions
- **Semantic Release** : https://semantic-release.gitbook.io/

### Tutoriels et guides

- Python Pandas : https://pandas.pydata.org/docs/
- SQLAlchemy : https://docs.sqlalchemy.org/
- Pydantic : https://docs.pydantic.dev/
- DuckDB : https://duckdb.org/docs/

### Outils

- GitHub CLI : https://cli.github.com/
- Azure CLI : https://learn.microsoft.com/cli/azure/
- Docker Desktop : https://www.docker.com/products/docker-desktop/

---

## Conseils et bonnes pratiques

### Git et versioning

- Utilisez des messages de commit descriptifs
- Respectez les conventions : `feat:`, `fix:`, `docs:`, `chore:`
- Ne committez jamais de secrets ou credentials
- Testez localement avant de pousser

### Python

- Utilisez des docstrings pour documenter vos fonctions
- Gérez les erreurs avec try/except
- Utilisez des noms de variables explicites
- Suivez PEP 8 pour le style

### Docker

- Utilisez des images légères (alpine)
- Nettoyez les fichiers temporaires
- Utilisez le cache Docker efficacement
- Documentez les variables d'environnement

### Sécurité

- Ne versionnez JAMAIS `.env` ou `secrets.toml`
- Utilisez des mots de passe forts
- Configurez correctement les firewalls
- Limitez les accès au strict nécessaire

### Performance

- Utilisez la pagination pour les grandes listes
- Traitez les données par batch
- Indexez les colonnes fréquemment requêtées
- Optimisez les requêtes SQL

---

## Support

### En cas de problème

1. **Consultez la documentation** du projet et des technologies
2. **Vérifiez les logs** pour identifier l'erreur
3. **Recherchez l'erreur** sur Google/Stack Overflow
4. **Testez étape par étape** pour isoler le problème
5. **Demandez de l'aide** en fournissant :
   - Message d'erreur complet
   - Code concerné
   - Étapes pour reproduire

### Ressources d'aide

- Documentation officielle des technologies
- Stack Overflow
- GitHub Issues des projets open source
- Forums de la communauté
- Discord/Slack de développeurs

---

## Bon courage ! 🚀

Ce projet vous donnera une expérience complète en data engineering, de l'ingestion à l'automatisation en production. Prenez le temps de bien comprendre chaque étape et n'hésitez pas à expérimenter !

**Points clés à retenir** :
- Testez régulièrement
- Committez souvent
- Documentez au fur et à mesure
- Automatisez ce qui peut l'être
- Pensez scalabilité et maintenabilité

Bonne chance dans votre aventure data engineering ! 🎯
