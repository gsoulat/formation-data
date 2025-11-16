# Shortcuts

## Concept de Shortcut

Un **shortcut** dans OneLake est un **pointeur** vers des données externes, permettant d'accéder à ces données **sans les copier**.

```
┌─────────────────────────────────────┐
│     Fabric Lakehouse                │
│                                      │
│  Files/                              │
│    ├─ local_data/  (physique)       │
│    └─ external_data/ (shortcut) ────┼──→ AWS S3 Bucket
│                                      │
│  Tables/                             │
│    ├─ my_table (physique)           │
│    └─ external_table (shortcut) ────┼──→ ADLS Gen2
└─────────────────────────────────────┘
```

**Analogie :** Shortcut = Lien symbolique (symlink) dans un filesystem

## Types de Shortcuts

### 1. OneLake Shortcut

Lien vers un autre Lakehouse/Warehouse dans Fabric.

```
Workspace A / Lakehouse1 / Tables / sales
              ↓ (shortcut)
Workspace B / Lakehouse2 / Shortcuts / shared_sales
```

**Use case :** Partager données entre workspaces

### 2. ADLS Gen2 Shortcut

Lien vers Azure Data Lake Storage Gen2.

```
External ADLS Gen2
  Container: data
    Folder: sales/
              ↓ (shortcut)
Lakehouse / Files / adls_sales/
```

**Use case :** Accéder données existantes dans ADLS sans migration

### 3. S3 Shortcut

Lien vers Amazon S3.

```
AWS S3
  Bucket: company-data
    Prefix: transactions/
              ↓ (shortcut)
Lakehouse / Files / s3_transactions/
```

**Use case :** Multi-cloud, données dans AWS

### 4. Dataverse Shortcut

Lien vers Microsoft Dataverse (Dynamics 365, Power Apps).

```
Dataverse
  Tables: Account, Contact, Opportunity
              ↓ (shortcut)
Lakehouse / Tables / crm_*
```

**Use case :** Analytics sur données Dynamics/PowerApps

### 5. Google Cloud Storage Shortcut

Lien vers Google Cloud Storage (preview).

## Création de Shortcuts

### Via UI

**Étapes :**
1. Lakehouse → Files ou Tables
2. "..." → New shortcut
3. Choisir type (OneLake, ADLS Gen2, S3, Dataverse)
4. Configurer connexion
5. Choisir path source
6. Nommer le shortcut
7. Create

### Via API

```python
import requests

url = "https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/items/{lakehouse_id}/shortcuts"

payload = {
    "path": "Files/my_shortcut",
    "name": "external_data",
    "target": {
        "type": "AdlsGen2",
        "connectionId": "{connection_id}",
        "location": "https://{account}.dfs.core.windows.net/{container}/{path}"
    }
}

response = requests.post(url, json=payload, headers=headers)
```

## Configuration par Type

### OneLake Shortcut

```
Source:
  └─ Workspace: Sales-Analytics
  └─ Lakehouse: SalesLH
  └─ Path: Tables/customers

Target (dans votre Lakehouse):
  └─ Files/shared/customers
```

**Authentication :** Automatique (même tenant)

### ADLS Gen2 Shortcut

```
Source:
  └─ Storage Account: mystorage
  └─ Container: data
  └─ Path: bronze/sales/

Target:
  └─ Files/adls/sales/

Authentication:
  ├─ Account Key
  ├─ SAS Token
  ├─ Service Principal
  └─ Managed Identity (recommandé)
```

### S3 Shortcut

```
Source:
  └─ Bucket: company-prod-data
  └─ Prefix: analytics/transactions/

Target:
  └─ Files/s3/transactions/

Authentication:
  ├─ AWS Access Key + Secret
  └─ IAM Role (via AssumeRole)
```

**Configuration credentials :**
```python
# Créer connection
connection = {
    "name": "AWS_S3_Connection",
    "type": "S3",
    "credentials": {
        "accessKeyId": "AKIA...",
        "secretAccessKey": "..."
    }
}
```

### Dataverse Shortcut

```
Source:
  └─ Environment: production
  └─ Tables: Account, Contact, Opportunity

Target:
  └─ Tables/crm_account
  └─ Tables/crm_contact
  └─ Tables/crm_opportunity

Authentication:
  └─ Service Principal (Azure AD)
```

## Utilisation des Shortcuts

### Lire via Spark

```python
# Shortcut apparaît comme dossier normal
df = spark.read.parquet("Files/s3_shortcut/data.parquet")

# Si shortcut vers Delta table
df = spark.read.format("delta").load("Tables/shortcut_table")
```

### Lire via SQL

```sql
-- Si shortcut dans Tables/
SELECT * FROM shortcut_table;

-- Via OPENROWSET pour Files/
SELECT *
FROM OPENROWSET(
    BULK 'Files/shortcut/data.parquet',
    FORMAT = 'PARQUET'
) AS data;
```

### Lire via Power BI

```
Power BI Desktop
  └─ Get Data
  └─ OneLake
  └─ Lakehouse
  └─ Tables/shortcut_table
  └─ Import ou DirectQuery
```

## Performance Considerations

### Latence

```
Local OneLake data:      < 10ms latency
OneLake shortcut:        10-50ms
ADLS Gen2 shortcut:      20-100ms
S3 shortcut (cross-cloud): 100-500ms
```

**Implication :** Shortcuts externes plus lents que données locales

### Data Transfer Costs

```
OneLake → OneLake:  Gratuit
OneLake → ADLS:     Gratuit (même région)
OneLake → S3:       Coûts egress AWS
S3 → OneLake:       Coûts data transfer
```

### Caching

```python
# Cache data en local pour performance
df = spark.read.format("delta").load("Tables/s3_shortcut")
df.write.format("delta").mode("overwrite").save("Tables/local_copy")

# Futures lectures sur local_copy = rapide
```

## Use Cases

### 1. Data Mesh Architecture

```
Domain A Lakehouse
  ├─ Local data (own domain)
  └─ Shortcuts → Domain B, C, D data

Chaque domaine partage via shortcuts
Pas de duplication centrale
```

### 2. Multi-Cloud Data Integration

```
Fabric Lakehouse
  ├─ Files/aws_data/ (shortcut S3)
  ├─ Files/gcp_data/ (shortcut GCS)
  └─ Files/azure_data/ (shortcut ADLS)

Analytics unifié sur données multi-cloud
```

### 3. Migration Progressive

```
Phase 1: Shortcut vers ancien système
  └─ Lakehouse / Files / legacy_data (shortcut ADLS)

Phase 2: Copie progressive
  └─ Pipeline Copy → Local storage

Phase 3: Suppression shortcut
  └─ Tout en local OneLake
```

### 4. Dev/Test/Prod Separation

```
Prod Lakehouse (workspace Prod)
  └─ Tables/customers (données production)

Test Lakehouse (workspace Test)
  └─ Tables/customers (shortcut vers Prod)
      └─ Tests sans impacter prod
```

## Limitations

### Shortcuts vers OneLake
- ✅ Lecture/Écriture
- ✅ Toutes opérations Delta
- ✅ Performance optimale

### Shortcuts vers ADLS Gen2
- ✅ Lecture
- ⚠️ Écriture (limitée)
- ⚠️ Pas toutes opérations Delta (MERGE limité)

### Shortcuts vers S3
- ✅ Lecture
- ❌ Écriture non supportée
- ⚠️ Latence plus élevée

### Shortcuts vers Dataverse
- ✅ Lecture
- ❌ Écriture via Fabric non supportée
- ⚠️ Données snapshot (pas temps réel)

## Sécurité

### Authentication

**OneLake :** Azure AD automatique

**ADLS Gen2 :**
- Managed Identity (recommandé)
- Service Principal
- Account Key
- SAS Token

**S3 :**
- Access Key + Secret
- IAM Role (AssumeRole)

**Dataverse :**
- Service Principal

### Permissions

```
User doit avoir:
  1. Permission sur Lakehouse cible (Member+)
  2. Permission sur source externe
  3. Connection credentials valides
```

## Monitoring

### Via UI

```
Lakehouse → Files ou Tables → Shortcut
  └─ Properties
  └─ Connection status
  └─ Target path
```

### Via API

```python
# Lister shortcuts
GET /v1/workspaces/{id}/items/{lakehouse_id}/shortcuts

# Vérifier status
GET /v1/workspaces/{id}/items/{lakehouse_id}/shortcuts/{path}
```

## Best Practices

✅ **DO:**
- Utiliser pour fédération de données
- Managed Identity pour auth (ADLS)
- Documenter les shortcuts (source, purpose)
- Monitor performance
- Cache si utilisé fréquemment

❌ **DON'T:**
- Trop de shortcuts (overhead)
- Shortcuts pour données modifiées fréquemment
- Credentials hardcodées
- Shortcut comme solution permanente (vs migration)

## Troubleshooting

### Erreur : Connection Failed

```
Causes possibles:
  - Credentials invalides
  - Permissions insuffisantes
  - Network/firewall
  - Path source incorrect

Solutions:
  - Vérifier credentials
  - Tester permissions manuellement
  - Vérifier network rules
```

### Performance Lente

```
Causes:
  - Latence network (cross-cloud)
  - Gros volume de données
  - Pas de data skipping

Solutions:
  - Cache en local
  - Filtrer à la source
  - Utiliser partitionnement
```

## Points Clés

- Shortcuts = virtualisation sans copie
- Types : OneLake, ADLS Gen2, S3, Dataverse, GCS
- Lecture généralement OK, écriture limitée
- Performance variable selon source
- Utile pour data mesh, multi-cloud
- Pas de duplication de données
- Monitoring important

---

**Prochain fichier :** [05 - Architecture Medallion](./05-schemas-medallion-architecture.md)

[⬅️ Fichier précédent](./03-onelake-storage.md) | [⬅️ Retour au README du module](./README.md)
