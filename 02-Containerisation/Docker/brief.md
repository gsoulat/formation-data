# 🐳 Brief Pratique Docker Complet - Data Engineering

**Durée estimée :** 6 heures
**Niveau :** Débutant à Avancé
**Modalité :** Pratique individuelle ou binôme

---

## 🎯 Objectifs du Brief

À l'issue de ce brief, vous serez capable de :
- Créer des Dockerfiles optimisés pour des applications Data Engineering
- Orchestrer une infrastructure complète multi-conteneurs
- Gérer les volumes, réseaux et variables d'environnement
- Déployer un pipeline de données end-to-end conteneurisé
- Troubleshooter et optimiser des conteneurs Docker
- Appliquer les bonnes pratiques de sécurité et performance

---

## 📋 Contexte

Vous êtes Data Engineer chez **DataStream Analytics**, une startup qui collecte et analyse des données en temps réel provenant de multiples sources (APIs, fichiers, streams). Votre mission est de conteneuriser l'ensemble de l'infrastructure de traitement de données pour :
- Faciliter le déploiement sur différents environnements
- Garantir la reproductibilité des traitements
- Simplifier la scalabilité de la plateforme
- Permettre aux Data Scientists de travailler dans des environnements isolés

---

## 🚀 Partie 1 : Pipeline ETL Basique (1h30)

### 🎯 Objectif
Créer un pipeline ETL Python conteneurisé qui extrait des données depuis une API, les transforme et les charge dans PostgreSQL.

### Tâche 1.1 : Préparer les fichiers sources

Créez la structure de projet suivante :
```
docker-etl-project/
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── requirements.txt
├── etl_pipeline.py
├── config/
│   └── config.yaml
├── src/
│   ├── __init__.py
│   ├── extract.py
│   ├── transform.py
│   └── load.py
├── data/
│   ├── raw/
│   └── processed/
└── logs/
```

### Tâche 1.2 : Créer le script ETL

**Fichier : `requirements.txt`**
```
pandas==2.1.3
requests==2.31.0
psycopg2-binary==2.9.9
sqlalchemy==2.0.23
pyyaml==6.0.1
python-dotenv==1.0.0
```

**Fichier : `etl_pipeline.py`**
```python
import pandas as pd
import requests
import psycopg2
from sqlalchemy import create_engine
import os
import logging
from datetime import datetime
import yaml

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/etl.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class ETLPipeline:
    def __init__(self):
        self.db_url = os.getenv('DATABASE_URL')
        self.engine = create_engine(self.db_url)
        logger.info("ETL Pipeline initialisé")

    def extract(self):
        """Extraction des données depuis une API publique"""
        logger.info("Début de l'extraction des données")
        try:
            # Utilisation de l'API JSONPlaceholder comme exemple
            response = requests.get('https://jsonplaceholder.typicode.com/users')
            response.raise_for_status()
            data = response.json()
            df = pd.DataFrame(data)
            logger.info(f"{len(df)} enregistrements extraits")
            return df
        except Exception as e:
            logger.error(f"Erreur lors de l'extraction : {e}")
            raise

    def transform(self, df):
        """Transformation des données"""
        logger.info("Début de la transformation")
        try:
            # Nettoyage et transformation
            df['extracted_at'] = datetime.now()

            # Normalisation des colonnes imbriquées
            if 'address' in df.columns:
                df['city'] = df['address'].apply(lambda x: x.get('city', ''))
                df['zipcode'] = df['address'].apply(lambda x: x.get('zipcode', ''))
                df['lat'] = df['address'].apply(lambda x: float(x.get('geo', {}).get('lat', 0)))
                df['lng'] = df['address'].apply(lambda x: float(x.get('geo', {}).get('lng', 0)))

            # Sélection des colonnes importantes
            columns_to_keep = ['id', 'name', 'username', 'email', 'phone',
                             'city', 'zipcode', 'lat', 'lng', 'extracted_at']
            df_clean = df[columns_to_keep].copy()

            logger.info(f"Transformation terminée : {len(df_clean)} lignes")
            return df_clean
        except Exception as e:
            logger.error(f"Erreur lors de la transformation : {e}")
            raise

    def load(self, df, table_name='users_data'):
        """Chargement des données dans PostgreSQL"""
        logger.info(f"Début du chargement dans la table {table_name}")
        try:
            df.to_sql(table_name, self.engine, if_exists='replace', index=False)
            logger.info(f"✅ {len(df)} lignes insérées dans {table_name}")
        except Exception as e:
            logger.error(f"Erreur lors du chargement : {e}")
            raise

    def run(self):
        """Exécution complète du pipeline"""
        logger.info("🚀 Démarrage du pipeline ETL")
        try:
            # ETL
            raw_data = self.extract()
            transformed_data = self.transform(raw_data)
            self.load(transformed_data)

            logger.info("✅ Pipeline terminé avec succès")
            return True
        except Exception as e:
            logger.error(f"❌ Erreur dans le pipeline : {e}")
            return False

if __name__ == "__main__":
    pipeline = ETLPipeline()
    success = pipeline.run()
    exit(0 if success else 1)
```

### Tâche 1.3 : Créer un Dockerfile optimisé

Créez un `Dockerfile` qui respecte les bonnes pratiques :
- Utilisez une image Python slim
- Optimisez le cache Docker
- Créez un utilisateur non-root
- Ajoutez des health checks
- Minimisez la taille de l'image

**Exemple de structure attendue :**
```dockerfile
# Utilisez python:3.11-slim comme base
# Configurez les variables d'environnement Python
# Installez les dépendances système nécessaires (gcc, postgresql-client)
# Copiez requirements.txt et installez les dépendances Python
# Copiez le code source
# Créez un utilisateur non-root
# Définissez le point d'entrée
```

### Tâche 1.4 : Créer le docker-compose.yml

Créez un fichier `docker-compose.yml` orchestrant :

1. **Service PostgreSQL**
   - Image : `postgres:15-alpine`
   - Variables d'environnement pour la base de données
   - Volume persistant pour les données
   - Health check pour vérifier la disponibilité

2. **Service ETL**
   - Build depuis votre Dockerfile
   - Dépend de PostgreSQL (avec condition de health)
   - Monte les volumes pour logs et données
   - Variables d'environnement pour la connexion DB

3. **Service PgAdmin** (optionnel pour visualisation)
   - Image : `dpage/pgadmin4`
   - Port exposé pour l'interface web

**Critères de réussite :**
- ✅ `docker-compose up -d` démarre tous les services
- ✅ L'ETL se connecte automatiquement à PostgreSQL
- ✅ Les données sont visibles dans la table `users_data`
- ✅ Les logs sont persistés dans le dossier `logs/`

### Tâche 1.5 : Tester et valider

```bash
# Construire et démarrer
docker-compose up -d

# Vérifier les logs
docker-compose logs -f etl

# Se connecter à PostgreSQL et vérifier les données
docker-compose exec postgres psql -U dataeng -d warehouse -c "SELECT * FROM users_data;"

# Vérifier les statistiques
docker stats
```

---

## 🗄️ Partie 2 : Infrastructure Multi-Services (2h)

### 🎯 Objectif
Étendre l'infrastructure avec des services additionnels : MongoDB, Redis, et une API REST.

### Tâche 2.1 : Ajouter MongoDB pour les données non structurées

Ajoutez un service MongoDB à votre `docker-compose.yml` :
- Image : `mongo:7`
- Authentification configurée
- Volume persistant
- Exposé sur le port 27017

Modifiez votre pipeline ETL pour écrire également les données brutes dans MongoDB :

```python
from pymongo import MongoClient

def load_to_mongo(self, data, collection_name='raw_data'):
    """Charge les données brutes dans MongoDB"""
    mongo_url = os.getenv('MONGO_URL', 'mongodb://admin:secret@mongodb:27017/')
    client = MongoClient(mongo_url)
    db = client['datawarehouse']
    collection = db[collection_name]

    # Insérer les données
    if isinstance(data, pd.DataFrame):
        records = data.to_dict('records')
    else:
        records = data

    result = collection.insert_many(records)
    logger.info(f"✅ {len(result.inserted_ids)} documents insérés dans MongoDB")
```

### Tâche 2.2 : Ajouter Redis pour le cache

Ajoutez Redis pour mettre en cache les résultats :
- Image : `redis:7-alpine`
- Volume pour la persistence
- Port 6379

Implémentez un système de cache :

```python
import redis
import json
import hashlib

class CacheManager:
    def __init__(self):
        self.redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'redis'),
            port=6379,
            decode_responses=True
        )

    def get_cached(self, key):
        """Récupère une valeur du cache"""
        return self.redis_client.get(key)

    def set_cache(self, key, value, ttl=3600):
        """Met en cache une valeur"""
        self.redis_client.setex(key, ttl, json.dumps(value))

    def generate_cache_key(self, *args):
        """Génère une clé de cache unique"""
        key_str = "_".join(str(arg) for arg in args)
        return hashlib.md5(key_str.encode()).hexdigest()
```

### Tâche 2.3 : Créer une API REST avec FastAPI

Créez un service API REST pour exposer les données.

**Fichier : `api/main.py`**
```python
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, text
import os
from typing import List, Dict

app = FastAPI(title="DataStream API", version="1.0.0")

DATABASE_URL = os.getenv('DATABASE_URL')
engine = create_engine(DATABASE_URL)

@app.get("/")
def read_root():
    return {"message": "DataStream API", "status": "running"}

@app.get("/health")
def health_check():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users")
def get_users():
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT * FROM users_data LIMIT 100"))
            users = [dict(row._mapping) for row in result]
        return {"count": len(users), "data": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}")
def get_user(user_id: int):
    try:
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT * FROM users_data WHERE id = :id"),
                {"id": user_id}
            )
            user = result.fetchone()
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            return dict(user._mapping)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
def get_stats():
    try:
        with engine.connect() as conn:
            count = conn.execute(text("SELECT COUNT(*) FROM users_data")).scalar()
            cities = conn.execute(
                text("SELECT city, COUNT(*) as count FROM users_data GROUP BY city")
            ).fetchall()
        return {
            "total_users": count,
            "cities": [{"city": c[0], "count": c[1]} for c in cities]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

**Fichier : `api/requirements.txt`**
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
```

**Fichier : `api/Dockerfile`**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

Ajoutez le service API à votre `docker-compose.yml` :
```yaml
api:
  build: ./api
  container_name: datastream-api
  ports:
    - "8000:8000"
  environment:
    DATABASE_URL: postgresql://dataeng:${POSTGRES_PASSWORD}@postgres:5432/warehouse
  networks:
    - data-network
  depends_on:
    postgres:
      condition: service_healthy
```

**Critères de réussite :**
- ✅ L'API est accessible sur http://localhost:8000
- ✅ `/docs` affiche la documentation Swagger automatique
- ✅ `/health` retourne le statut de santé
- ✅ `/users` retourne les données depuis PostgreSQL
- ✅ Les données sont cachées dans Redis

### Tâche 2.4 : Créer un réseau personnalisé

Créez un réseau Docker personnalisé avec des sous-réseaux :

```yaml
networks:
  data-network:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
          gateway: 172.28.0.1

  monitoring-network:
    driver: bridge
```

---

## 📊 Partie 3 : Orchestration avec Airflow (1h30)

### 🎯 Objectif
Orchestrer les pipelines avec Apache Airflow et créer des DAGs pour automatiser les traitements.

### Tâche 3.1 : Configurer Airflow

Créez une configuration Airflow complète dans votre `docker-compose.yml`.

**Services à ajouter :**
1. **Airflow Webserver**
2. **Airflow Scheduler**
3. **Airflow Initdb** (pour l'initialisation)

**Structure pour Airflow :**
```yaml
x-airflow-common: &airflow-common
  image: apache/airflow:2.7.3-python3.11
  environment:
    - AIRFLOW__CORE__EXECUTOR=LocalExecutor
    - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://dataeng:${POSTGRES_PASSWORD}@postgres/airflow
    - AIRFLOW__CORE__FERNET_KEY=${AIRFLOW_FERNET_KEY}
    - AIRFLOW__CORE__LOAD_EXAMPLES=False
    - AIRFLOW__WEBSERVER__SECRET_KEY=${AIRFLOW_SECRET_KEY}
  volumes:
    - ./dags:/opt/airflow/dags
    - ./logs:/opt/airflow/logs
    - ./plugins:/opt/airflow/plugins
    - ./config:/opt/airflow/config
  networks:
    - data-network
  depends_on:
    postgres:
      condition: service_healthy

services:
  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  airflow-scheduler:
    <<: *airflow-common
    command: scheduler
    healthcheck:
      test: ["CMD-SHELL", "airflow jobs check --job-type SchedulerJob --hostname $${HOSTNAME}"]
      interval: 30s
      timeout: 10s
      retries: 5

  airflow-init:
    <<: *airflow-common
    command: >
      bash -c "
        airflow db init &&
        airflow users create \
          --username admin \
          --firstname Admin \
          --lastname User \
          --role Admin \
          --email admin@example.com \
          --password admin
      "
    restart: on-failure
```

### Tâche 3.2 : Créer un DAG ETL

Créez un DAG qui orchestre votre pipeline ETL.

**Fichier : `dags/etl_dag.py`**
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import requests
import pandas as pd
from sqlalchemy import create_engine
import os

default_args = {
    'owner': 'dataeng',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'datastream_etl_pipeline',
    default_args=default_args,
    description='Pipeline ETL DataStream',
    schedule_interval='@daily',
    catchup=False,
    tags=['etl', 'datastream'],
)

def extract_data(**context):
    """Extraction des données"""
    response = requests.get('https://jsonplaceholder.typicode.com/users')
    data = response.json()
    context['ti'].xcom_push(key='raw_data', value=data)
    return f"✅ {len(data)} enregistrements extraits"

def transform_data(**context):
    """Transformation des données"""
    data = context['ti'].xcom_pull(key='raw_data', task_ids='extract')
    df = pd.DataFrame(data)

    # Transformations
    df['extracted_at'] = datetime.now().isoformat()
    df['city'] = df['address'].apply(lambda x: x.get('city', ''))

    transformed = df.to_dict('records')
    context['ti'].xcom_push(key='transformed_data', value=transformed)
    return f"✅ {len(transformed)} lignes transformées"

def load_data(**context):
    """Chargement des données"""
    data = context['ti'].xcom_pull(key='transformed_data', task_ids='transform')
    df = pd.DataFrame(data)

    db_url = os.getenv('DATABASE_URL', 'postgresql://dataeng:secret@postgres:5432/warehouse')
    engine = create_engine(db_url)

    df.to_sql('users_data_airflow', engine, if_exists='replace', index=False)
    return f"✅ {len(df)} lignes chargées"

def check_data_quality(**context):
    """Vérification de la qualité des données"""
    db_url = os.getenv('DATABASE_URL', 'postgresql://dataeng:secret@postgres:5432/warehouse')
    engine = create_engine(db_url)

    with engine.connect() as conn:
        count = conn.execute("SELECT COUNT(*) FROM users_data_airflow").scalar()

    if count == 0:
        raise ValueError("❌ Aucune donnée trouvée !")

    return f"✅ {count} enregistrements vérifiés"

# Définir les tâches
extract_task = PythonOperator(
    task_id='extract',
    python_callable=extract_data,
    dag=dag,
)

transform_task = PythonOperator(
    task_id='transform',
    python_callable=transform_data,
    dag=dag,
)

load_task = PythonOperator(
    task_id='load',
    python_callable=load_data,
    dag=dag,
)

quality_check_task = PythonOperator(
    task_id='quality_check',
    python_callable=check_data_quality,
    dag=dag,
)

notify_task = BashOperator(
    task_id='notify',
    bash_command='echo "✅ Pipeline ETL terminé avec succès !"',
    dag=dag,
)

# Définir les dépendances
extract_task >> transform_task >> load_task >> quality_check_task >> notify_task
```

### Tâche 3.3 : Créer un DAG de monitoring

**Fichier : `dags/monitoring_dag.py`**
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from sqlalchemy import create_engine
import os

default_args = {
    'owner': 'dataeng',
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
}

dag = DAG(
    'data_monitoring',
    default_args=default_args,
    description='Monitoring des données',
    schedule_interval='@hourly',
    catchup=False,
    tags=['monitoring'],
)

def check_database_size(**context):
    """Vérifier la taille de la base"""
    db_url = os.getenv('DATABASE_URL')
    engine = create_engine(db_url)

    with engine.connect() as conn:
        result = conn.execute("""
            SELECT
                pg_size_pretty(pg_database_size('warehouse')) as db_size
        """)
        size = result.scalar()

    print(f"📊 Taille de la base : {size}")
    return size

def check_table_counts(**context):
    """Vérifier le nombre d'enregistrements"""
    db_url = os.getenv('DATABASE_URL')
    engine = create_engine(db_url)

    tables = ['users_data', 'users_data_airflow']
    counts = {}

    with engine.connect() as conn:
        for table in tables:
            try:
                count = conn.execute(f"SELECT COUNT(*) FROM {table}").scalar()
                counts[table] = count
            except:
                counts[table] = 0

    print(f"📊 Nombre d'enregistrements : {counts}")
    return counts

check_size = PythonOperator(
    task_id='check_database_size',
    python_callable=check_database_size,
    dag=dag,
)

check_counts = PythonOperator(
    task_id='check_table_counts',
    python_callable=check_table_counts,
    dag=dag,
)

check_size >> check_counts
```

**Critères de réussite :**
- ✅ Airflow UI accessible sur http://localhost:8080
- ✅ Les DAGs apparaissent dans l'interface
- ✅ Le DAG ETL s'exécute manuellement avec succès
- ✅ Toutes les tâches passent au vert
- ✅ Les données sont correctement insérées

---

## 🔧 Partie 4 : Optimisation et Sécurité (1h)

### 🎯 Objectif
Optimiser les images Docker et sécuriser l'infrastructure.

### Tâche 4.1 : Optimiser les Dockerfiles avec Multi-Stage Build

Refactorisez votre Dockerfile ETL avec un multi-stage build :

```dockerfile
# ============================================
# STAGE 1: Builder
# ============================================
FROM python:3.11 AS builder

WORKDIR /build

# Installer les dépendances de compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ make postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copier et installer les dépendances Python
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt

# ============================================
# STAGE 2: Runtime
# ============================================
FROM python:3.11-slim

WORKDIR /app

# Copier uniquement les wheels compilés
COPY --from=builder /build/wheels /wheels
COPY --from=builder /build/requirements.txt .

# Installer depuis les wheels (plus rapide et plus petit)
RUN pip install --no-cache /wheels/*

# Copier le code
COPY etl_pipeline.py .
COPY src/ ./src/
COPY config/ ./config/

# Créer les répertoires
RUN mkdir -p /data/raw /data/processed /app/logs

# Utilisateur non-root
RUN useradd -m -u 1000 dataeng && \
    chown -R dataeng:dataeng /app /data
USER dataeng

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD python -c "import sys; sys.exit(0)" || exit 1

CMD ["python", "etl_pipeline.py"]
```

### Tâche 4.2 : Créer un .dockerignore complet

```
# Git
.git
.gitignore
.gitattributes

# IDE
.vscode
.idea
*.swp
*.swo

# Python
__pycache__
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# Environment
.env
.env.local
.env.*.local
venv/
ENV/

# Logs
*.log
logs/

# Data
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep

# Docker
docker-compose.yml
docker-compose.*.yml
Dockerfile*
.dockerignore

# Documentation
README.md
docs/
*.md
```

### Tâche 4.3 : Sécuriser avec des secrets

Créez un fichier `.env` pour les secrets (à ne JAMAIS commiter) :

```env
# Database
POSTGRES_USER=dataeng
POSTGRES_PASSWORD=VotreSuperMotDePasseSecure123!
POSTGRES_DB=warehouse

# MongoDB
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=MongoSecure456!

# Airflow
AIRFLOW_FERNET_KEY=VotreCleFernet789==
AIRFLOW_SECRET_KEY=VotreCleSecrete012==

# Redis
REDIS_PASSWORD=RedisSecure345!
```

Modifiez votre `docker-compose.yml` pour utiliser les secrets :

```yaml
services:
  postgres:
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    # Ne jamais exposer directement en production
    # ports:
    #   - "5432:5432"
```

### Tâche 4.4 : Ajouter des Health Checks partout

Ajoutez des health checks à tous les services :

```yaml
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s

mongodb:
  healthcheck:
    test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
    interval: 10s
    timeout: 5s
    retries: 5

redis:
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 3s
    retries: 5

api:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 5s
    retries: 3
```

### Tâche 4.5 : Limiter les ressources

Limitez les ressources pour chaque conteneur :

```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  etl:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

**Critères de réussite :**
- ✅ Les images finales sont 50% plus petites
- ✅ Aucun secret n'est hardcodé dans les fichiers
- ✅ Tous les services ont des health checks fonctionnels
- ✅ Les ressources sont limitées et contrôlées

---

## 🎁 Partie 5 : Monitoring et Production (Bonus - 1h)

### Tâche 5.1 : Ajouter Prometheus et Grafana

Ajoutez le monitoring avec Prometheus et Grafana.

**Service Prometheus :**
```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus
  volumes:
    - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - monitoring-network
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
```

**Fichier : `monitoring/prometheus.yml`**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'api'
    static_configs:
      - targets: ['api:8000']
```

**Service Grafana :**
```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_USER=admin
    - GF_SECURITY_ADMIN_PASSWORD=admin
  volumes:
    - grafana_data:/var/lib/grafana
  networks:
    - monitoring-network
```

### Tâche 5.2 : Configurer les logs centralisés

Configurez un driver de logs :

```yaml
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    labels: "service"

services:
  etl:
    logging: *default-logging
```

### Tâche 5.3 : Créer un script de backup

**Fichier : `scripts/backup.sh`**
```bash
#!/bin/bash

# Backup PostgreSQL
docker-compose exec -T postgres pg_dump -U dataeng warehouse > backups/db_$(date +%Y%m%d_%H%M%S).sql

# Backup MongoDB
docker-compose exec -T mongodb mongodump --out=/backup

# Backup volumes
docker run --rm -v docker-etl-project_postgres_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/postgres_volume_$(date +%Y%m%d_%H%M%S).tar.gz /data

echo "✅ Backup terminé"
```

---

## 📤 Livrables Finaux

À la fin du brief, vous devez fournir :

### 1. Code Source Complet
```
docker-etl-project/
├── docker-compose.yml
├── .env.example
├── .dockerignore
├── Dockerfile
├── requirements.txt
├── etl_pipeline.py
├── src/
│   ├── extract.py
│   ├── transform.py
│   └── load.py
├── api/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── dags/
│   ├── etl_dag.py
│   └── monitoring_dag.py
├── config/
│   └── config.yaml
├── monitoring/
│   └── prometheus.yml
├── scripts/
│   ├── backup.sh
│   └── restore.sh
└── README.md
```

### 2. Documentation (README.md)

Votre README doit contenir :
- Architecture globale de la solution
- Prérequis et installation
- Guide de démarrage rapide
- Variables d'environnement
- Commandes utiles
- Accès aux services (ports, URLs)
- Troubleshooting
- Schéma d'architecture

### 3. Preuves de Fonctionnement

- Captures d'écran de l'interface Airflow avec DAGs réussis
- Captures de PgAdmin montrant les données
- Captures de l'API (Swagger UI)
- Logs du pipeline ETL
- Résultats des health checks
- Métriques de performance (docker stats)

---

## ✅ Critères d'Évaluation

| Critère | Points | Description |
|---------|--------|-------------|
| **Infrastructure Docker** | 20 | docker-compose.yml complet et fonctionnel |
| **Dockerfile optimisé** | 15 | Multi-stage, sécurisé, minimal |
| **Pipeline ETL** | 20 | Extract, Transform, Load fonctionnels |
| **Orchestration Airflow** | 15 | DAGs fonctionnels et bien structurés |
| **API REST** | 10 | FastAPI avec endpoints fonctionnels |
| **Volumes & Réseaux** | 10 | Persistance et isolation correctes |
| **Sécurité** | 10 | Secrets, non-root, health checks |
| **Documentation** | 10 | README complet et clair |
| **Bonus** | 10 | Monitoring, backups, optimisations |

**Total : 120 points (100 + 20 bonus)**

### Barème de notation :
- **100-120 pts** : Excellent - Production ready
- **80-99 pts** : Très bien - Quelques améliorations mineures
- **60-79 pts** : Bien - Fonctionnel mais perfectible
- **< 60 pts** : À revoir - Problèmes majeurs

---

## 💡 Conseils et Astuces

### Debugging Docker

```bash
# Voir tous les conteneurs
docker ps -a

# Logs détaillés
docker-compose logs --tail=100 -f [service]

# Se connecter à un conteneur
docker-compose exec [service] bash

# Inspecter un conteneur
docker inspect [container_id]

# Voir l'utilisation des ressources
docker stats

# Nettoyer
docker system prune -a --volumes
```

### Vérifier la santé

```bash
# Health check de tous les services
docker-compose ps

# Tester la connexion PostgreSQL
docker-compose exec postgres psql -U dataeng -d warehouse -c "SELECT version();"

# Tester MongoDB
docker-compose exec mongodb mongosh --eval "db.runCommand({ ping: 1 })"

# Tester Redis
docker-compose exec redis redis-cli ping

# Tester l'API
curl http://localhost:8000/health
```

### Optimisation

```bash
# Voir la taille des images
docker images

# Analyser les layers d'une image
docker history mon-image:tag

# Scanner les vulnérabilités
docker scan mon-image:tag
```

---

## 📚 Ressources Complémentaires

### Documentation Officielle
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### Outils Data Engineering
- [Apache Airflow Docs](https://airflow.apache.org/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [MongoDB Docker Hub](https://hub.docker.com/_/mongo)

### Sécurité
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Trivy - Scanner de vulnérabilités](https://github.com/aquasecurity/trivy)

---

## 🆘 Troubleshooting

### Problème : Le conteneur PostgreSQL ne démarre pas
```bash
# Vérifier les logs
docker-compose logs postgres

# Vérifier les permissions du volume
docker volume inspect docker-etl-project_postgres_data

# Recréer le volume
docker-compose down -v
docker-compose up -d postgres
```

### Problème : L'ETL ne peut pas se connecter à PostgreSQL
```bash
# Vérifier que PostgreSQL est prêt
docker-compose exec postgres pg_isready -U dataeng

# Vérifier les variables d'environnement
docker-compose exec etl env | grep DATABASE

# Tester la connexion réseau
docker-compose exec etl ping postgres
```

### Problème : Airflow ne démarre pas
```bash
# Réinitialiser la base Airflow
docker-compose run --rm airflow-init

# Vérifier la configuration
docker-compose config

# Vérifier les logs du scheduler
docker-compose logs airflow-scheduler
```

### Problème : Manque d'espace disque
```bash
# Voir l'utilisation
docker system df

# Nettoyer
docker system prune -a --volumes

# Supprimer les images non utilisées
docker image prune -a
```

---

## 🎯 Checklist Finale

Avant de soumettre votre travail, vérifiez que :

- [ ] `docker-compose up -d` démarre tous les services sans erreur
- [ ] PostgreSQL est accessible et contient les données
- [ ] MongoDB fonctionne et stocke les données brutes
- [ ] Redis cache les résultats correctement
- [ ] L'API REST répond sur http://localhost:8000
- [ ] Airflow UI est accessible sur http://localhost:8080
- [ ] Les DAGs s'exécutent avec succès
- [ ] Les logs sont persistés
- [ ] Les volumes conservent les données après un redémarrage
- [ ] Aucun secret n'est hardcodé
- [ ] Tous les services ont des health checks
- [ ] Les ressources sont limitées
- [ ] Le README est complet
- [ ] Les captures d'écran sont fournies
- [ ] Le code est commenté

---

**Bon courage ! 🚀**

Ce brief vous permettra de maîtriser Docker pour le Data Engineering de A à Z. N'hésitez pas à expérimenter et à aller au-delà des exigences !
