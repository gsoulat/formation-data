# 🗄️ Chapitre 6 : Bases de Données - Bonnes Pratiques

## Introduction

Les bases de données sont le cœur de la plupart des applications. Une mauvaise conception ou utilisation peut entraîner des problèmes de performance, de sécurité et de maintenabilité. Ce chapitre couvre les bonnes pratiques essentielles pour travailler efficacement avec les bases de données relationnelles et NoSQL.

## 📐 Conception et Modélisation

### Normalisation des Données

La normalisation réduit la redondance et améliore l'intégrité des données.

#### Formes Normales

```sql
-- ❌ Mauvais : Données non normalisées (0NF)
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_address VARCHAR(200),
    products VARCHAR(500), -- "laptop,mouse,keyboard"
    prices VARCHAR(200),   -- "1000,25,50"
    order_date DATE
);

-- ✅ Bon : 3ème forme normale (3NF)
-- Table des clients
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des adresses (relation 1:N avec customers)
CREATE TABLE addresses (
    address_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    street VARCHAR(100),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Table des produits
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT DEFAULT 0
);

-- Table des commandes
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Table de liaison commandes-produits (relation N:N)
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

### Conventions de Nommage

```sql
-- ✅ Bonnes conventions
-- Tables : nom au pluriel, snake_case
CREATE TABLE users ( ... );
CREATE TABLE user_profiles ( ... );
CREATE TABLE order_items ( ... );

-- Colonnes : snake_case, descriptives
user_id INT PRIMARY KEY,
first_name VARCHAR(50),
created_at TIMESTAMP,
is_active BOOLEAN

-- Clés primaires : table_id
users.user_id
products.product_id

-- Clés étrangères : referenced_table_id
orders.customer_id  -- référence customers.customer_id
order_items.product_id  -- référence products.product_id

-- Index : idx_table_columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Contraintes : constraint_type_table_description
ALTER TABLE users ADD CONSTRAINT chk_users_age CHECK (age >= 18);
ALTER TABLE orders ADD CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
```

### Types de Données Appropriés

```sql
-- ❌ Mauvais : Types inappropriés
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,  -- String pour un ID
    age VARCHAR(10),              -- String pour un nombre
    salary VARCHAR(50),           -- String pour un montant
    is_active VARCHAR(5),         -- String pour un boolean
    birthdate VARCHAR(20)         -- String pour une date
);

-- ✅ Bon : Types appropriés
CREATE TABLE users (
    id SERIAL PRIMARY KEY,        -- Auto-increment pour PostgreSQL
    age SMALLINT CHECK (age >= 0 AND age <= 150),
    salary DECIMAL(12, 2),        -- Précision pour les montants
    is_active BOOLEAN DEFAULT TRUE,
    birthdate DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Types recommandés par cas d'usage
-- IDs : INT/BIGINT avec AUTO_INCREMENT ou UUID
id UUID DEFAULT gen_random_uuid(),  -- PostgreSQL 13+

-- Argent : DECIMAL/NUMERIC, jamais FLOAT
price DECIMAL(10, 2),  -- Jusqu'à 99,999,999.99

-- Texte court : VARCHAR avec limite
email VARCHAR(255),
username VARCHAR(50),

-- Texte long : TEXT
description TEXT,
content TEXT,

-- Dates : DATE, TIME, TIMESTAMP WITH TIME ZONE
appointment_date DATE,
appointment_time TIME,
created_at TIMESTAMP WITH TIME ZONE,

-- Énumérations : ENUM ou CHECK constraint
status ENUM('pending', 'approved', 'rejected'),
-- ou
status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected')),

-- JSON (PostgreSQL, MySQL 5.7+)
metadata JSONB,  -- PostgreSQL : JSONB pour performance
settings JSON    -- MySQL
```

## 🔑 Index et Performance

### Stratégies d'Indexation

```sql
-- Index sur les clés étrangères (souvent oubliés !)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Index composites pour les requêtes fréquentes
-- Ordre des colonnes important : plus sélectif en premier
CREATE INDEX idx_users_status_created ON users(status, created_at);

-- Index partiel (PostgreSQL) pour optimiser l'espace
CREATE INDEX idx_orders_pending ON orders(status) 
WHERE status = 'pending';

-- Index unique pour garantir l'unicité
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Index full-text pour la recherche (PostgreSQL)
CREATE INDEX idx_products_search ON products 
USING gin(to_tsvector('english', name || ' ' || description));

-- Index sur expressions
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

### Analyse des Requêtes

```sql
-- PostgreSQL : EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT o.*, c.name 
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2024-01-01'
  AND c.country = 'France';

-- MySQL : EXPLAIN
EXPLAIN 
SELECT * FROM users 
WHERE email = 'user@example.com';

-- Identifier les requêtes lentes (PostgreSQL)
-- Activer dans postgresql.conf
log_min_duration_statement = 100  -- Log queries > 100ms

-- Query pour voir les index manquants (PostgreSQL)
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1
ORDER BY n_distinct DESC;
```

## 🛡️ Sécurité des Données

### Protection contre les Injections SQL

```python
# ❌ JAMAIS : Concaténation de strings
def get_user_unsafe(email):
    query = f"SELECT * FROM users WHERE email = '{email}'"
    return db.execute(query)  # Vulnérable à l'injection SQL

# ❌ JAMAIS : Formatage de strings
def get_user_unsafe2(user_id):
    query = "SELECT * FROM users WHERE id = {}".format(user_id)
    return db.execute(query)

# ✅ TOUJOURS : Requêtes paramétrées
def get_user_safe(email):
    query = "SELECT * FROM users WHERE email = %s"  # PostgreSQL, MySQL
    return db.execute(query, (email,))

# ✅ Avec SQLAlchemy
from sqlalchemy import text

def get_user_sqlalchemy(email):
    query = text("SELECT * FROM users WHERE email = :email")
    return db.execute(query, {"email": email})

# ✅ Avec ORM (le plus sûr)
def get_user_orm(email):
    return User.query.filter_by(email=email).first()
```

### Chiffrement des Données Sensibles

```python
# Configuration de chiffrement avec SQLAlchemy
from sqlalchemy_utils import EncryptedType
from sqlalchemy_utils.types.encrypted.encrypted_type import AesEngine
import os

# Clé de chiffrement (à stocker de manière sécurisée)
SECRET_KEY = os.environ.get('ENCRYPTION_KEY')

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    
    # Données sensibles chiffrées
    ssn = db.Column(EncryptedType(db.String, SECRET_KEY, AesEngine, 'pkcs5'))
    credit_card = db.Column(EncryptedType(db.String, SECRET_KEY, AesEngine, 'pkcs5'))
    
    # Hash pour les mots de passe (jamais en clair !)
    password_hash = db.Column(db.String(255), nullable=False)

# Hachage des mots de passe
from werkzeug.security import generate_password_hash, check_password_hash

def set_password(user, password):
    user.password_hash = generate_password_hash(password)

def verify_password(user, password):
    return check_password_hash(user.password_hash, password)
```

### Gestion des Permissions

```sql
-- Création d'utilisateurs avec permissions limitées
-- PostgreSQL
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE myapp TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- User en lecture seule pour les rapports
CREATE USER report_user WITH PASSWORD 'another_secure_password';
GRANT CONNECT ON DATABASE myapp TO report_user;
GRANT USAGE ON SCHEMA public TO report_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_user;

-- Révoquer les permissions dangereuses
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE myapp FROM PUBLIC;
```

## 🔄 Migrations et Versioning

### Utilisation d'Alembic (Python)

```python
# alembic.ini
[alembic]
script_location = migrations
sqlalchemy.url = postgresql://user:pass@localhost/dbname

# migrations/env.py
from alembic import context
from sqlalchemy import engine_from_config, pool
from app.models import Base  # Import your models

target_metadata = Base.metadata

# Création d'une migration
# $ alembic revision --autogenerate -m "Add user table"

# migrations/versions/001_add_user_table.py
"""Add user table

Revision ID: 1234567890ab
Revises: 
Create Date: 2024-01-01 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '1234567890ab'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_users_email', 'users', ['email'], unique=True)

def downgrade():
    op.drop_index('idx_users_email', table_name='users')
    op.drop_table('users')
```

### Bonnes Pratiques de Migration

```sql
-- 1. Toujours tester les migrations en environnement de test

-- 2. Migrations réversibles
-- ✅ Bon : Migration avec rollback
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
-- Rollback:
ALTER TABLE users DROP COLUMN phone;

-- 3. Éviter les locks longs sur les grosses tables
-- ❌ Mauvais : Lock toute la table
ALTER TABLE large_table ADD COLUMN new_col INT DEFAULT 0;

-- ✅ Bon : Sans lock (PostgreSQL)
ALTER TABLE large_table ADD COLUMN new_col INT; -- Pas de DEFAULT
-- Puis dans une transaction séparée :
UPDATE large_table SET new_col = 0 WHERE new_col IS NULL;
-- Enfin :
ALTER TABLE large_table ALTER COLUMN new_col SET DEFAULT 0;

-- 4. Migrations de données volumineuses par batch
DO $$
DECLARE
    batch_size INT := 1000;
    offset_val INT := 0;
BEGIN
    LOOP
        UPDATE users 
        SET normalized_email = LOWER(email)
        WHERE id IN (
            SELECT id FROM users 
            WHERE normalized_email IS NULL 
            LIMIT batch_size
        );
        
        EXIT WHEN NOT FOUND;
        COMMIT;
    END LOOP;
END $$;
```

## 🎯 Optimisation des Requêtes

### Éviter les Problèmes N+1

```python
# ❌ Mauvais : N+1 queries
orders = Order.query.all()  # 1 query
for order in orders:
    print(order.customer.name)  # N queries

# ✅ Bon : Eager loading avec SQLAlchemy
orders = Order.query.options(joinedload(Order.customer)).all()  # 1 query

# ✅ Avec select_related (Django)
orders = Order.objects.select_related('customer').all()

# ✅ Requête SQL optimisée
SELECT o.*, c.* 
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;
```

### Pagination Efficace

```python
# ❌ Mauvais : LIMIT/OFFSET pour grandes valeurs
def get_page_inefficient(page, per_page=20):
    offset = (page - 1) * per_page
    return db.query(User).offset(offset).limit(per_page).all()
    # OFFSET 1000000 est très lent

# ✅ Bon : Cursor-based pagination
def get_page_efficient(last_id=0, per_page=20):
    return db.query(User)\
        .filter(User.id > last_id)\
        .order_by(User.id)\
        .limit(per_page)\
        .all()

# ✅ Avec SQL
-- Keyset pagination
SELECT * FROM users 
WHERE id > :last_id 
ORDER BY id 
LIMIT 20;

-- Pour pagination bidirectionnelle
SELECT * FROM users 
WHERE (created_at, id) > (:last_date, :last_id)
ORDER BY created_at, id 
LIMIT 20;
```

### Requêtes Complexes Optimisées

```sql
-- CTE (Common Table Expressions) pour lisibilité
WITH active_customers AS (
    SELECT customer_id, name, email
    FROM customers
    WHERE is_active = TRUE
      AND created_at >= CURRENT_DATE - INTERVAL '1 year'
),
customer_orders AS (
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    ac.name,
    ac.email,
    COALESCE(co.order_count, 0) as orders,
    COALESCE(co.total_spent, 0) as total_spent
FROM active_customers ac
LEFT JOIN customer_orders co ON ac.customer_id = co.customer_id
ORDER BY total_spent DESC;

-- Window functions pour analyses avancées
SELECT 
    customer_id,
    order_date,
    total_amount,
    -- Total cumulé
    SUM(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_date
    ) as running_total,
    -- Rang par montant
    RANK() OVER (
        PARTITION BY customer_id 
        ORDER BY total_amount DESC
    ) as order_rank,
    -- Moyenne mobile sur 3 commandes
    AVG(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg
FROM orders
WHERE status = 'completed';
```

## 🔐 Backup et Récupération

### Stratégies de Backup

```bash
# PostgreSQL : Backup complet
pg_dump -h localhost -U postgres -d myapp -f backup.sql

# Backup compressé
pg_dump -h localhost -U postgres -d myapp -Fc -f backup.dump

# Backup avec données uniquement (sans schéma)
pg_dump -h localhost -U postgres -d myapp --data-only -f data_backup.sql

# MySQL : Backup avec mysqldump
mysqldump -u root -p myapp > backup.sql

# Backup incrémental avec binary logs (MySQL)
mysqlbinlog --start-datetime="2024-01-01 00:00:00" \
            --stop-datetime="2024-01-02 00:00:00" \
            /var/lib/mysql/mysql-bin.000001 > incremental_backup.sql
```

### Script de Backup Automatisé

```python
#!/usr/bin/env python3
import os
import subprocess
from datetime import datetime
import boto3  # Pour upload S3

class DatabaseBackup:
    def __init__(self, db_config):
        self.db_config = db_config
        self.s3_client = boto3.client('s3')
        
    def create_backup(self):
        """Crée un backup de la base de données."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_file = f"backup_{self.db_config['name']}_{timestamp}.sql"
        
        # Commande pg_dump
        cmd = [
            'pg_dump',
            '-h', self.db_config['host'],
            '-U', self.db_config['user'],
            '-d', self.db_config['name'],
            '-f', backup_file
        ]
        
        # Exécution avec mot de passe
        env = os.environ.copy()
        env['PGPASSWORD'] = self.db_config['password']
        
        try:
            subprocess.run(cmd, env=env, check=True)
            print(f"Backup créé : {backup_file}")
            return backup_file
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors du backup : {e}")
            raise
    
    def upload_to_s3(self, backup_file, bucket_name):
        """Upload le backup vers S3."""
        try:
            self.s3_client.upload_file(
                backup_file,
                bucket_name,
                f"database-backups/{backup_file}"
            )
            print(f"Backup uploadé vers S3 : {bucket_name}")
        except Exception as e:
            print(f"Erreur upload S3 : {e}")
            raise
    
    def cleanup_old_backups(self, retention_days=7):
        """Supprime les vieux backups."""
        # Implementation de la logique de nettoyage
        pass

# Utilisation
if __name__ == "__main__":
    config = {
        'host': 'localhost',
        'user': 'postgres',
        'password': os.getenv('DB_PASSWORD'),
        'name': 'myapp'
    }
    
    backup = DatabaseBackup(config)
    backup_file = backup.create_backup()
    backup.upload_to_s3(backup_file, 'my-backup-bucket')
```

## 🔄 Transactions et Isolation

### Niveaux d'Isolation

```python
# SQLAlchemy : Gestion des transactions
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(
    'postgresql://user:pass@localhost/db',
    isolation_level="READ COMMITTED"  # Défaut PostgreSQL
)

# Niveaux disponibles :
# - READ UNCOMMITTED : Lecture sale possible
# - READ COMMITTED : Défaut, pas de lecture sale
# - REPEATABLE READ : Lectures cohérentes
# - SERIALIZABLE : Isolation complète

# Transaction explicite
from contextlib import contextmanager

@contextmanager
def transaction_scope():
    """Fournit un scope transactionnel."""
    session = Session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Utilisation
with transaction_scope() as session:
    user = User(name="Alice", email="alice@example.com")
    session.add(user)
    
    order = Order(user_id=user.id, total=100)
    session.add(order)
    # Commit automatique ou rollback en cas d'erreur
```

### Gestion des Deadlocks

```python
import time
from sqlalchemy.exc import OperationalError

def execute_with_retry(session, operation, max_retries=3):
    """Exécute une opération avec retry en cas de deadlock."""
    for attempt in range(max_retries):
        try:
            result = operation(session)
            session.commit()
            return result
        except OperationalError as e:
            session.rollback()
            if "deadlock detected" in str(e) and attempt < max_retries - 1:
                time.sleep(0.1 * (attempt + 1))  # Backoff exponentiel
                continue
            raise
```

## 🎯 Monitoring et Maintenance

### Requêtes de Monitoring

```sql
-- PostgreSQL : Statistiques des tables
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_live_tup as row_count,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index inutilisés
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Requêtes actives
SELECT 
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- MySQL : Processus en cours
SHOW PROCESSLIST;

-- Tables avec beaucoup de fragmentation
SELECT 
    table_schema,
    table_name,
    data_free / 1024 / 1024 as free_space_mb
FROM information_schema.tables
WHERE data_free > 100 * 1024 * 1024
ORDER BY data_free DESC;
```

## 🎯 Exercices Pratiques

### Exercice 1 : Conception de Schéma
Concevez un schéma de base de données pour un système de blog avec :
- Articles, auteurs, catégories, tags
- Commentaires avec modération
- Système de likes
- Historique des modifications

### Exercice 2 : Optimisation
Optimisez ces requêtes lentes :
```sql
-- Requête 1
SELECT * FROM orders 
WHERE YEAR(order_date) = 2024 
  AND MONTH(order_date) = 1;

-- Requête 2
SELECT DISTINCT customer_id 
FROM orders 
WHERE product_id IN (
    SELECT product_id 
    FROM products 
    WHERE category = 'Electronics'
);
```

### Exercice 3 : Migration Sécurisée
Écrivez une migration pour :
1. Ajouter une colonne `email_verified` à la table users
2. Migrer les données existantes
3. Ajouter une contrainte NOT NULL

## 📚 Points Clés à Retenir

1. **Normalisation appropriée** : 3NF généralement suffisante
2. **Index stratégiques** : Sur clés étrangères et colonnes de filtrage
3. **Sécurité d'abord** : Requêtes paramétrées TOUJOURS
4. **Performance** : Mesurer, ne pas deviner
5. **Backups réguliers** : Testez la restauration !

## 🔗 Ressources Complémentaires

- [Use The Index, Luke!](https://use-the-index-luke.com/) - Guide complet sur les index
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [High Performance MySQL](https://www.oreilly.com/library/view/high-performance-mysql/9781492080503/)
- [SQL Antipatterns](https://pragprog.com/titles/bksap1/sql-antipatterns/)

---

**Prochain chapitre** : [Sécurité →](07-securite.md)