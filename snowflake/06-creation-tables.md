# 6. Création des tables

[← Retour au sommaire](README.md) | [← Précédent](05-creation-database-schema.md) | [Suivant →](07-import-donnees.md)

## Vue d'ensemble
Nous allons créer 4 tables interconnectées pour notre système de ventes : CUSTOMERS, PRODUCTS, ORDERS et ORDER_ITEMS.

---

## Menu "Create" dans Snowflake

### Options de création disponibles
Snowflake propose un menu **Create** complet avec plusieurs méthodes de création :

#### 🔧 **Méthodes de création**
- **Create with SQL** : Écriture directe de code SQL
- **Create with guided setup (PREVIEW)** : Interface guidée étape par étape
- **Upload YAML file** : Import via fichier de configuration

#### 📊 **Objets de données**
| Type | Description | Usage |
|------|-------------|-------|
| **Table** | Tables relationnelles classiques | Stockage de données structurées |
| **Dynamic Table** | Tables avec refresh automatique | Agrégations en temps réel |
| **View** | Vues SQL classiques | Abstraction des requêtes |
| **Semantic View** | Vues sémantiques métier | Couche business intelligible |

#### 🗂️ **Objets de traitement et stockage**
| Type | Description | Usage |
|------|-------------|-------|
| **Stage** | Zone de transit pour fichiers | Import/export de données |
| **File Format** | Format de fichier réutilisable | Configuration CSV, JSON, etc. |
| **Image Repository** | Stockage d'images conteneur | Applications conteneurisées |
| **Sequence** | Générateur de nombres | Auto-incréments |
| **Pipe** | Pipeline d'ingestion | Chargement automatique |
| **Stream** | Capture de changements | CDC (Change Data Capture) |

#### ⚡ **Objets programmables**
| Type | Description | Usage |
|------|-------------|-------|
| **Task** | Tâches planifiées | Orchestration et automation |
| **Function** | Fonctions utilisateur | Logique métier réutilisable |
| **Procedure** | Procédures stockées | Scripts SQL complexes |

#### 🔗 **Intégrations et services**
| Type | Description | Usage |
|------|-------------|-------|
| **Git Repository** | Intégration Git | Gestion de versions |
| **Contact** | Contacts de notification | Alertes et monitoring |
| **Cortex Search Service (PREVIEW)** | Service de recherche AI | Recherche intelligente |


### 💡 Recommandations par cas d'usage

**Pour débuter :**
- Utilisez **Create with guided setup** pour les tables
- **Create with SQL** pour plus de contrôle

**Pour la production :**
- **Upload YAML file** pour la reproductibilité
- **Git Repository** pour le versioning

---

## Étape 1 : Accéder au schéma
1. Naviguez vers `SALES_DB` > `RAW_DATA`
2. Cliquez sur **+ Create Table**

![Interface création table](images/20-table-creation-interface.png)
*Interface de création de table dans le schéma*

## Étape 2 : Créer la table CUSTOMERS
1. **Table Name** : `CUSTOMERS`
2. Définissez les colonnes :
   - `CUSTOMER_ID` : `NUMBER(10,0)` - **Primary Key**
   - `FIRST_NAME` : `VARCHAR(50)` - **Not Null**
   - `LAST_NAME` : `VARCHAR(50)` - **Not Null**
   - `EMAIL` : `VARCHAR(100)` - **Unique**
   - `PHONE` : `VARCHAR(20)`
   - `ADDRESS` : `VARCHAR(200)`
   - `CITY` : `VARCHAR(50)`
   - `POSTAL_CODE` : `VARCHAR(10)`
   - `COUNTRY` : `VARCHAR(50)`
   - `CREATED_DATE` : `TIMESTAMP` - **Default** : `CURRENT_TIMESTAMP()`

```sql
CREATE TABLE IF NOT EXISTS CUSTOMERS (
    CUSTOMER_ID     NUMBER(10,0) NOT NULL PRIMARY KEY,
    FIRST_NAME      VARCHAR(50) NOT NULL,
    LAST_NAME       VARCHAR(50) NOT NULL,
    EMAIL           VARCHAR(100) UNIQUE,
    PHONE           VARCHAR(20),
    ADDRESS         VARCHAR(200),
    CITY            VARCHAR(50),
    POSTAL_CODE     VARCHAR(10),
    COUNTRY         VARCHAR(50),
    CREATED_DATE    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

## Étape 3 : Créer la table PRODUCTS
Répétez le processus pour créer la table `PRODUCTS` :
- `PRODUCT_ID` : `NUMBER(10,0)` - **Primary Key**
- `PRODUCT_NAME` : `VARCHAR(100)` - **Not Null**
- `CATEGORY` : `VARCHAR(50)`
- `BRAND` : `VARCHAR(50)`
- `UNIT_PRICE` : `NUMBER(10,2)` - **Not Null**
- `DESCRIPTION` : `VARCHAR(500)`
- `CREATED_DATE` : `TIMESTAMP` - **Default** : `CURRENT_TIMESTAMP()`

```sql
CREATE TABLE IF NOT EXISTS PRODUCTS (
    PRODUCT_ID      NUMBER(10,0) NOT NULL PRIMARY KEY,
    PRODUCT_NAME    VARCHAR(100) NOT NULL,
    CATEGORY        VARCHAR(50),
    BRAND           VARCHAR(50),
    UNIT_PRICE      NUMBER(10,2) NOT NULL,
    DESCRIPTION     VARCHAR(500),
    CREATED_DATE    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

## Étape 4 : Créer la table ORDERS
Créez la table `ORDERS` :
- `ORDER_ID` : `NUMBER(10,0)` - **Primary Key**
- `CUSTOMER_ID` : `NUMBER(10,0)` - **Foreign Key** vers CUSTOMERS
- `ORDER_DATE` : `DATE` - **Not Null**
- `ORDER_STATUS` : `VARCHAR(20)` - **Default** : `'PENDING'`
- `TOTAL_AMOUNT` : `NUMBER(12,2)`
- `SHIPPING_ADDRESS` : `VARCHAR(200)`
- `CREATED_DATE` : `TIMESTAMP` - **Default** : `CURRENT_TIMESTAMP()`

```sql
CREATE TABLE IF NOT EXISTS ORDERS (
    ORDER_ID            NUMBER(10,0) NOT NULL PRIMARY KEY,
    CUSTOMER_ID         NUMBER(10,0) NOT NULL,
    ORDER_DATE          DATE NOT NULL,
    ORDER_STATUS        VARCHAR(20) DEFAULT 'PENDING',
    TOTAL_AMOUNT        NUMBER(12,2),
    SHIPPING_ADDRESS    VARCHAR(200),
    CREATED_DATE        TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT FK_ORDERS_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID)
);
```

## Étape 5 : Créer la table ORDER_ITEMS
Créez la table de liaison `ORDER_ITEMS` :
- `ORDER_ITEM_ID` : `NUMBER(10,0)` - **Primary Key**
- `ORDER_ID` : `NUMBER(10,0)` - **Foreign Key** vers ORDERS
- `PRODUCT_ID` : `NUMBER(10,0)` - **Foreign Key** vers PRODUCTS
- `QUANTITY` : `NUMBER(8,0)` - **Not Null**
- `UNIT_PRICE` : `NUMBER(10,2)` - **Not Null**
- `LINE_TOTAL` : `NUMBER(12,2)` - **Computed** : `QUANTITY * UNIT_PRICE`

```sql
CREATE TABLE IF NOT EXISTS ORDER_ITEMS (
    ORDER_ITEM_ID   NUMBER(10,0) NOT NULL PRIMARY KEY,
    ORDER_ID        NUMBER(10,0) NOT NULL,
    PRODUCT_ID      NUMBER(10,0) NOT NULL,
    QUANTITY        NUMBER(8,0) NOT NULL,
    UNIT_PRICE      NUMBER(10,2) NOT NULL,
    LINE_TOTAL      NUMBER(12,2) AS (QUANTITY * UNIT_PRICE),
    CONSTRAINT FK_ORDER_ITEMS_ORDER
        FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID),
    CONSTRAINT FK_ORDER_ITEMS_PRODUCT
        FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID)
);
```

## Types de données Snowflake

### Numériques
| Type | Description | Exemple |
|------|------------|---------|
| NUMBER(p,s) | Nombre décimal | NUMBER(10,2) |
| INTEGER | Entier | 12345 |
| FLOAT | Nombre flottant | 3.14159 |

### Chaînes de caractères
| Type | Description | Limite |
|------|------------|--------|
| VARCHAR(n) | Chaîne variable | 16MB max |
| CHAR(n) | Chaîne fixe | 16MB max |
| TEXT | Texte long | 16MB max |

### Dates et heures
| Type | Description |
|------|------------|
| DATE | Date seule |
| TIME | Heure seule |
| TIMESTAMP | Date et heure |

## Contraintes disponibles

### Via l'interface
- **PRIMARY KEY** : Identifiant unique
- **NOT NULL** : Valeur obligatoire
- **UNIQUE** : Valeur unique dans la table
- **DEFAULT** : Valeur par défaut

### Foreign Keys
Les clés étrangères doivent être ajoutées via SQL après création :
```sql
ALTER TABLE ORDERS
ADD CONSTRAINT FK_ORDERS_CUSTOMER
FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID);

ALTER TABLE ORDER_ITEMS
ADD CONSTRAINT FK_ORDER_ITEMS_ORDER
FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID);

ALTER TABLE ORDER_ITEMS
ADD CONSTRAINT FK_ORDER_ITEMS_PRODUCT
FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID);
```

## Diagramme de relations

```
CUSTOMERS (1) ──────< (n) ORDERS
                            │
                            │ (1)
                            │
                            ∨ (n)
PRODUCTS (1) ──────< (n) ORDER_ITEMS
```

## Scripts SQL complets

### Table CUSTOMERS
```sql
CREATE TABLE IF NOT EXISTS CUSTOMERS (
    CUSTOMER_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    FIRST_NAME VARCHAR(50) NOT NULL,
    LAST_NAME VARCHAR(50) NOT NULL,
    EMAIL VARCHAR(100) UNIQUE NOT NULL,
    PHONE VARCHAR(20),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(50),
    POSTAL_CODE VARCHAR(10),
    COUNTRY VARCHAR(50) DEFAULT 'France',
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

### Table PRODUCTS
```sql
CREATE TABLE IF NOT EXISTS PRODUCTS (
    PRODUCT_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100) NOT NULL,
    CATEGORY VARCHAR(50),
    BRAND VARCHAR(50),
    UNIT_PRICE NUMBER(10,2) NOT NULL,
    DESCRIPTION VARCHAR(500),
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

### Table ORDERS
```sql
CREATE TABLE IF NOT EXISTS ORDERS (
    ORDER_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    CUSTOMER_ID NUMBER(10,0) NOT NULL,
    ORDER_DATE DATE NOT NULL,
    ORDER_STATUS VARCHAR(20) DEFAULT 'PENDING',
    TOTAL_AMOUNT NUMBER(12,2),
    SHIPPING_ADDRESS VARCHAR(200),
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT FK_ORDERS_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID)
);
```

### Table ORDER_ITEMS
```sql
CREATE TABLE IF NOT EXISTS ORDER_ITEMS (
    ORDER_ITEM_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    ORDER_ID NUMBER(10,0) NOT NULL,
    PRODUCT_ID NUMBER(10,0) NOT NULL,
    QUANTITY NUMBER(8,0) NOT NULL,
    UNIT_PRICE NUMBER(10,2) NOT NULL,
    LINE_TOTAL NUMBER(12,2) AS (QUANTITY * UNIT_PRICE),
    CONSTRAINT FK_ORDER_ITEMS_ORDER
        FOREIGN KEY (ORDER_ID) REFERENCES ORDERS(ORDER_ID),
    CONSTRAINT FK_ORDER_ITEMS_PRODUCT
        FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID)
);
```

## ✅ Points de vérification
- [ ] Table CUSTOMERS créée
- [ ] Table PRODUCTS créée
- [ ] Table ORDERS créée avec FK
- [ ] Table ORDER_ITEMS créée avec FKs
- [ ] Toutes les contraintes appliquées

---

[Suivant : Import de données CSV →](07-import-donnees.md)