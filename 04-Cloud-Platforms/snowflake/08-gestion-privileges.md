# 8. Gestion des privilèges

[← Retour au sommaire](README.md) | [← Précédent](07-import-donnees.md) | [Suivant →](09-monitoring.md)

## Vue d'ensemble
La gestion des privilèges permet de contrôler qui peut accéder et modifier les données. Nous allons configurer les accès pour le rôle `SALES_ANALYST`.

---

## Étape 1 : Attribuer des privilèges sur le warehouse
1. Allez dans **Account** > **Users & Roles** > **Roles**
2. Cliquez sur le rôle `SALES_ANALYST`
3. Dans l'onglet **Privileges**, cliquez sur **Grant Privileges**
4. Sélectionnez :
   - **Object Type** : `Warehouse`
   - **Object** : `SALES_WH`
   - **Privileges** : `USAGE`

![Attribution privilèges warehouse](images/29-warehouse-privileges.png)
*Attribution de privilèges sur le warehouse*

## Étape 2 : Attribuer des privilèges sur la base de données
1. Ajoutez un autre privilège :
   - **Object Type** : `Database`
   - **Object** : `SALES_DB`
   - **Privileges** : `USAGE`

## Étape 3 : Attribuer des privilèges sur le schéma
1. Ajoutez :
   - **Object Type** : `Schema`
   - **Object** : `SALES_DB.RAW_DATA`
   - **Privileges** : `USAGE`, `SELECT`

## Étape 4 : Attribuer des privilèges sur les tables
1. Pour chaque table (`CUSTOMERS`, `PRODUCTS`, `ORDERS`, `ORDER_ITEMS`) :
   - **Object Type** : `Table`
   - **Object** : `SALES_DB.RAW_DATA.[TABLE_NAME]`
   - **Privileges** : `SELECT`

![Liste privilèges rôle](images/30-role-privileges-list.png)
*Liste complète des privilèges attribués au rôle*

## Étape 5 : Assigner le rôle à un utilisateur
1. Allez dans **Users & Roles** > **Users**
2. Sélectionnez votre utilisateur
3. Dans **Roles**, cliquez sur **Grant Role**
4. Sélectionnez `SALES_ANALYST`

![Attribution rôle utilisateur](images/31-user-role-assignment.png)
*Attribution du rôle à l'utilisateur*

## Types de privilèges Snowflake

### Privilèges sur les objets

| Objet | Privilèges disponibles |
|-------|----------------------|
| **Warehouse** | USAGE, OPERATE, MODIFY, MONITOR |
| **Database** | USAGE, CREATE SCHEMA, MONITOR, MODIFY |
| **Schema** | USAGE, CREATE TABLE, CREATE VIEW, MODIFY |
| **Table** | SELECT, INSERT, UPDATE, DELETE, TRUNCATE |
| **View** | SELECT, REFERENCES |

### Matrice des privilèges par rôle

| Action | SALES_ANALYST | SALES_DEVELOPER | SALES_ADMIN |
|--------|--------------|-----------------|-------------|
| Lire données | ✅ | ✅ | ✅ |
| Modifier données | ❌ | ✅ | ✅ |
| Créer tables | ❌ | ✅ | ✅ |
| Gérer privilèges | ❌ | ❌ | ✅ |

## Hiérarchie des rôles

```
ACCOUNTADMIN
    └── SECURITYADMIN
            └── SYSADMIN
                    └── SALES_ADMIN (custom)
                            ├── SALES_DEVELOPER (custom)
                            └── SALES_ANALYST (custom)
```

## Créer des rôles supplémentaires

### Via l'interface
1. **Account** > **Users & Roles** > **Roles**
2. **+ Create Role**
3. Définir nom et description
4. Configurer la hiérarchie

### Rôles suggérés
- **SALES_VIEWER** : Lecture seule sur les marts
- **SALES_DEVELOPER** : Développement ETL
- **SALES_ADMIN** : Administration complète

## Gestion des utilisateurs

### Créer un nouvel utilisateur
1. **Account** > **Users & Roles** > **Users**
2. **+ Create User**
3. Remplir :
   - Username
   - Email
   - First/Last name
   - Password (temporaire)
   - Default Role
   - Default Warehouse

![Création utilisateur](images/32-user-creation-form.png)
*Formulaire de création d'utilisateur*

### Paramètres utilisateur
- **Must change password** : Force le changement au premier login
- **Account locked** : Bloque l'accès temporairement
- **Session timeout** : Durée d'inactivité avant déconnexion

## Privilèges futurs

### Configuration
Pour que les nouveaux objets héritent automatiquement des privilèges :

```sql
-- Privilèges sur futures tables
GRANT SELECT ON FUTURE TABLES IN SCHEMA SALES_DB.RAW_DATA
TO ROLE SALES_ANALYST;

-- Privilèges sur futurs schémas
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE SALES_DB
TO ROLE SALES_ANALYST;
```

## Audit des privilèges

### Vérifier les privilèges d'un rôle
```sql
SHOW GRANTS TO ROLE SALES_ANALYST;
```

### Vérifier les rôles d'un utilisateur
```sql
SHOW GRANTS TO USER [username];
```

### Vérifier qui a accès à une table
```sql
SHOW GRANTS ON TABLE SALES_DB.RAW_DATA.CUSTOMERS;
```

## Sécurité avancée

### Row Level Security (RLS)
Limite l'accès aux lignes selon des critères :
```sql
CREATE ROW ACCESS POLICY customer_policy
AS (customer_country STRING) RETURNS BOOLEAN ->
  'France' = customer_country OR CURRENT_ROLE() = 'SALES_ADMIN';

ALTER TABLE CUSTOMERS
ADD ROW ACCESS POLICY customer_policy ON (COUNTRY);
```

### Column Level Security
Masque des colonnes sensibles :
```sql
CREATE MASKING POLICY email_mask
AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('SALES_ADMIN') THEN val
    ELSE '***MASKED***'
  END;

ALTER TABLE CUSTOMERS MODIFY COLUMN EMAIL
SET MASKING POLICY email_mask;
```

## Best Practices

### ✅ À faire
1. **Principe du moindre privilège** : Ne donner que le minimum nécessaire
2. **Rôles fonctionnels** : Créer des rôles par fonction métier
3. **Documentation** : Documenter tous les rôles et privilèges
4. **Audit régulier** : Vérifier les accès tous les mois
5. **Rotation** : Changer les mots de passe régulièrement

### ❌ À éviter
1. Utiliser ACCOUNTADMIN pour les tâches quotidiennes
2. Donner des privilèges directs aux utilisateurs
3. Partager les identifiants
4. Créer des rôles trop permissifs
5. Oublier de révoquer les accès

## Commandes SQL équivalentes

```sql
-- Créer et configurer un rôle complet
USE ROLE ACCOUNTADMIN;

-- Créer le rôle
CREATE ROLE IF NOT EXISTS SALES_ANALYST;

-- Privilèges warehouse
GRANT USAGE ON WAREHOUSE SALES_WH TO ROLE SALES_ANALYST;

-- Privilèges database
GRANT USAGE ON DATABASE SALES_DB TO ROLE SALES_ANALYST;

-- Privilèges schema
GRANT USAGE ON SCHEMA SALES_DB.RAW_DATA TO ROLE SALES_ANALYST;

-- Privilèges tables
GRANT SELECT ON ALL TABLES IN SCHEMA SALES_DB.RAW_DATA
TO ROLE SALES_ANALYST;

-- Privilèges futurs
GRANT SELECT ON FUTURE TABLES IN SCHEMA SALES_DB.RAW_DATA
TO ROLE SALES_ANALYST;

-- Assigner à utilisateur
GRANT ROLE SALES_ANALYST TO USER 'username';
```

## ✅ Points de vérification
- [ ] Privilèges warehouse configurés
- [ ] Privilèges database configurés
- [ ] Privilèges schema configurés
- [ ] Privilèges tables configurés
- [ ] Rôle assigné à l'utilisateur
- [ ] Test de connexion avec le rôle

---

[Suivant : Monitoring et surveillance →](09-monitoring.md)