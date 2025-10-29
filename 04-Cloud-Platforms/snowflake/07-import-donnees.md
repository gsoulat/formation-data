# 7. Import de données CSV

[← Retour au sommaire](README.md) | [← Précédent](06-creation-tables.md) | [Suivant →](08-gestion-privileges.md)

## Vue d'ensemble
Cette section explique comment importer des données CSV dans vos tables Snowflake via l'interface graphique.

---

## Étape 1 : Préparer les fichiers CSV

### Créer les fichiers d'exemple
Créez ces fichiers CSV sur votre machine locale :

**customers.csv** :
```csv
CUSTOMER_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE,ADDRESS,CITY,POSTAL_CODE,COUNTRY
1,Jean,Dupont,jean.dupont@email.com,0123456789,123 Rue de la Paix,Paris,75001,France
2,Marie,Martin,marie.martin@email.com,0987654321,456 Avenue des Champs,Lyon,69001,France
3,Pierre,Durand,pierre.durand@email.com,0147258369,789 Boulevard Voltaire,Marseille,13001,France
4,Sophie,Moreau,sophie.moreau@email.com,0156789012,321 Place République,Toulouse,31000,France
5,Thomas,Rousseau,thomas.rousseau@email.com,0167890123,654 Rue Commerce,Nice,06000,France
```

**products.csv** :
```csv
PRODUCT_ID,PRODUCT_NAME,CATEGORY,BRAND,UNIT_PRICE,DESCRIPTION
101,Ordinateur Portable HP,Informatique,HP,899.99,Ordinateur portable 15 pouces avec SSD 512GB
102,Souris sans fil Logitech,Accessoires,Logitech,29.99,Souris optique sans fil ergonomique
103,Clavier mécanique Corsair,Accessoires,Corsair,129.99,Clavier mécanique gaming RGB
104,Écran Dell 27 pouces,Informatique,Dell,459.99,Moniteur IPS 4K avec HDR
105,Casque Sony WH-1000XM4,Audio,Sony,299.99,Casque bluetooth réduction de bruit
```

**orders.csv** :
```csv
ORDER_ID,CUSTOMER_ID,ORDER_DATE,ORDER_STATUS,TOTAL_AMOUNT,SHIPPING_ADDRESS
1001,1,2024-01-15,Delivered,899.99,123 Rue de la Paix Paris
1002,2,2024-01-16,Delivered,159.98,456 Avenue des Champs Lyon
1003,3,2024-01-18,Shipped,589.98,789 Boulevard Voltaire Marseille
1004,4,2024-01-20,Processing,459.99,321 Place République Toulouse
1005,5,2024-01-22,Pending,329.98,654 Rue Commerce Nice
```

**order_items.csv** :
```csv
ORDER_ITEM_ID,ORDER_ID,PRODUCT_ID,QUANTITY,UNIT_PRICE
1,1001,101,1,899.99
2,1002,102,2,29.99
3,1002,103,1,129.99
4,1003,104,1,459.99
5,1003,103,1,129.99
6,1004,104,1,459.99
7,1005,102,1,29.99
8,1005,105,1,299.99
```

## Étape 2 : Utiliser l'interface de chargement
1. Naviguez vers votre table `CUSTOMERS`
2. Cliquez sur **Load Data**
3. Sélectionnez **Load data from file**


## Étape 3 : Configurer l'import

### Format de fichier
1. **Choose Files** : Sélectionnez votre fichier `customers.csv`
2. **File Format** :
   - Type : `CSV`
   - Header : `First line contains headers`
   - Field delimiter : `Comma`
   - Text qualifier : `Double quote`
3. **Preview** : Vérifiez que les données s'affichent correctement


## Étape 4 : Mapper les colonnes
1. Vérifiez le mapping automatique des colonnes
2. Ajustez si nécessaire en faisant glisser les colonnes
3. Cliquez sur **Load Data**


## Étape 5 : Répéter pour les autres tables
Répétez les étapes 2-4 pour importer :
- `products.csv` dans la table `PRODUCTS`
- `orders.csv` dans la table `ORDERS`
- `order_items.csv` dans la table `ORDER_ITEMS`


## Options avancées d'import

### Gestion des erreurs
- **ON_ERROR = CONTINUE** : Continue malgré les erreurs
- **ON_ERROR = SKIP_FILE** : Ignore le fichier entier en cas d'erreur
- **ON_ERROR = ABORT** : Arrête l'import (défaut)

### Transformation à la volée
Options disponibles :
- **TRIM_SPACE** : Supprime les espaces
- **NULL_IF** : Définit les valeurs NULL
- **SKIP_HEADER** : Nombre de lignes à ignorer

## Utilisation des Stages (méthode avancée)

### Qu'est-ce qu'un Stage ?
Un stage est une zone de stockage temporaire pour les fichiers avant import :
- **Internal Stage** : Stockage dans Snowflake
- **External Stage** : S3, Azure Blob, GCS

### Créer un Internal Stage
```sql
CREATE STAGE IF NOT EXISTS MY_CSV_STAGE
FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1);
```

### Upload vers le Stage
Via l'interface :
1. Allez dans **Data** > **Databases** > **SALES_DB** > **Stages**
2. Cliquez sur votre stage
3. Cliquez sur **Upload Files**
4. Sélectionnez vos fichiers CSV

## Validation des données importées

### Vérifier le nombre de lignes
```sql
SELECT 'CUSTOMERS' as TABLE_NAME, COUNT(*) as ROW_COUNT FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS;
```

### Vérifier l'intégrité référentielle
```sql
-- Vérifier les commandes sans client
SELECT COUNT(*) as ORPHANED_ORDERS
FROM ORDERS o
LEFT JOIN CUSTOMERS c ON o.CUSTOMER_ID = c.CUSTOMER_ID
WHERE c.CUSTOMER_ID IS NULL;
```

## Formats de fichiers supportés

| Format | Extension | Usage |
|--------|-----------|-------|
| CSV | .csv | Données tabulaires simples |
| JSON | .json | Données semi-structurées |
| Parquet | .parquet | Format columnar optimisé |
| ORC | .orc | Format Hadoop |
| Avro | .avro | Données avec schéma |
| XML | .xml | Données hiérarchiques |

## 💡 Conseils pour l'import

1. **Validez toujours** les données avant import en production
2. **Utilisez des stages** pour les imports réguliers
3. **Conservez les logs** d'import pour audit
4. **Testez d'abord** avec un échantillon
5. **Documentez** le format attendu

## Troubleshooting

### Problèmes fréquents
| Erreur | Cause | Solution |
|--------|-------|----------|
| Column count mismatch | Nombre de colonnes incorrect | Vérifier les délimiteurs |
| Data type error | Type incompatible | Vérifier les formats de date/nombre |
| Encoding error | Encodage du fichier | Utiliser UTF-8 |
| Size limit | Fichier trop gros | Diviser en plusieurs fichiers |

## ✅ Points de vérification
- [ ] Fichiers CSV créés
- [ ] Données importées dans CUSTOMERS
- [ ] Données importées dans PRODUCTS
- [ ] Données importées dans ORDERS
- [ ] Données importées dans ORDER_ITEMS
- [ ] Intégrité vérifiée

---

[Suivant : Gestion des privilèges →](08-gestion-privileges.md)