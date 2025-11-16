# Architecture OneLake

## Concept de OneLake

**OneLake** est le lac de données unifié de Microsoft Fabric. C'est l'innovation fondamentale qui différencie Fabric des autres plateformes.

### Analogie : OneDrive pour les données

Si OneDrive est "**un seul drive**" pour tous vos fichiers personnels, OneLake est "**un seul lac**" pour toutes les données de votre organisation.

```
OneDrive : Fichiers personnels
OneLake  : Données d'entreprise

Même principe : stockage unifié, accessible partout
```

## Architecture Technique

### Stack technologique

```
┌─────────────────────────────────────────┐
│      Fabric Workloads                   │
│  (Data Engineering, Warehouse, BI...)   │
├─────────────────────────────────────────┤
│           OneLake API                   │
│    (Compatible ADLS Gen2 API)           │
├─────────────────────────────────────────┤
│        Delta Lake Format                │
│   (Parquet + Transaction Log)           │
├─────────────────────────────────────────┤
│    Azure Data Lake Storage Gen2         │
│         (Physical storage)              │
└─────────────────────────────────────────┘
```

### Sous le capot

OneLake s'appuie sur **Azure Data Lake Storage Gen2** (ADLS Gen2) mais ajoute plusieurs couches d'abstraction et de fonctionnalités :

1. **Delta Lake** : Format de stockage transactionnel
2. **Metadata layer** : Catalogue unifié
3. **Security layer** : Gouvernance centralisée
4. **API layer** : Accès compatible ADLS Gen2

## Organisation des Données

### Hiérarchie OneLake

```
Tenant (Organization)
└── OneLake
    ├── Workspace 1
    │   ├── Lakehouse A
    │   │   ├── Files/
    │   │   └── Tables/
    │   ├── Warehouse B
    │   └── Semantic Model C
    ├── Workspace 2
    │   ├── Lakehouse D
    │   └── KQL Database E
    └── Workspace 3
        └── ...
```

### Structure d'un Lakehouse dans OneLake

```
MyLakehouse/
├── Files/                          # Unstructured data
│   ├── raw/
│   │   ├── 2024/
│   │   │   ├── 01/
│   │   │   └── 02/
│   │   └── archive/
│   ├── bronze/
│   ├── silver/
│   └── gold/
└── Tables/                         # Structured data (Delta tables)
    ├── customers/
    │   ├── _delta_log/             # Transaction log
    │   └── *.parquet               # Data files
    ├── orders/
    └── products/
```

### Format Delta Lake

OneLake utilise **Delta Lake** comme format par défaut pour les tables.

#### Qu'est-ce que Delta ?

Delta Lake = **Parquet** + **Transaction Log**

```
Table : sales_data
├── _delta_log/
│   ├── 00000000000000000000.json  # Transaction 1
│   ├── 00000000000000000001.json  # Transaction 2
│   └── 00000000000000000002.json  # Transaction 3
├── part-00000.parquet             # Data file 1
├── part-00001.parquet             # Data file 2
└── part-00002.parquet             # Data file 3
```

**Transaction log** enregistre :
- Les modifications (add, remove, update)
- Les métadonnées (schéma, partitions)
- Les timestamps
- Les statistiques

**Avantages :**
- ✅ Transactions ACID
- ✅ Time travel (historique des versions)
- ✅ Schema enforcement & evolution
- ✅ Concurrent reads/writes
- ✅ Optimisations (V-Order, Z-ordering)

## Accès aux Données OneLake

### 1. Via Fabric UI

L'interface web Fabric permet d'explorer OneLake visuellement.

```
Fabric Portal → Workspace → Lakehouse → Files ou Tables
```

### 2. Via ADLS Gen2 API

OneLake expose une API **compatible ADLS Gen2**, ce qui signifie que tous les outils supportant ADLS Gen2 fonctionnent avec OneLake.

#### URL OneLake

Format : `https://onelake.dfs.fabric.microsoft.com/{workspace}/{item}/...`

Exemple :
```
https://onelake.dfs.fabric.microsoft.com/
  SalesAnalytics/                    # Workspace
  SalesLakehouse/                    # Lakehouse
  Files/raw/sales_2024.csv           # File path
```

### 3. Via Azure Storage Explorer

```bash
# Connecter Azure Storage Explorer à OneLake
Account Type: ADLS Gen2
URL: https://onelake.dfs.fabric.microsoft.com
Auth: Azure AD
```

### 4. Via Spark

```python
# Lire depuis OneLake dans un notebook Fabric
df = spark.read.format("delta").load("Tables/customers")

# Écrire dans OneLake
df.write.format("delta").mode("overwrite").saveAsTable("sales_clean")
```

### 5. Via Power BI

Power BI peut lire directement depuis OneLake avec **Direct Lake** mode.

```
Semantic Model → Get Data → OneLake → Select tables
```

## Shortcuts : Virtualisation de Données

### Concept

Les **shortcuts** permettent de virtualiser des données externes dans OneLake **sans copie**.

```
OneLake Lakehouse
├── Tables/
│   └── local_sales/          # Données physiques
└── Files/
    └── external_data/         # Shortcut vers S3 (pas de copie!)
```

### Types de Shortcuts

#### 1. OneLake Shortcut
Lien vers un autre Lakehouse/Warehouse dans Fabric

```
Workspace A / Lakehouse1 / Tables / sales
             ↓ (shortcut)
Workspace B / Lakehouse2 / Shortcuts / sales
```

**Use case :** Partager des données entre workspaces sans duplication

#### 2. ADLS Gen2 Shortcut
Lien vers Azure Data Lake Storage Gen2

```
OneLake Lakehouse
└── Shortcuts/
    └── raw_data/  → Points vers adls://mystorageaccount/container/data/
```

**Use case :** Accéder à des données existantes dans ADLS sans migration

#### 3. S3 Shortcut
Lien vers Amazon S3

```
OneLake Lakehouse
└── Shortcuts/
    └── s3_data/  → Points vers s3://my-bucket/data/
```

**Use case :** Architecture multi-cloud, accès à données dans AWS

#### 4. Dataverse Shortcut
Lien vers Microsoft Dataverse

```
OneLake Lakehouse
└── Shortcuts/
    └── crm_data/  → Points vers Dataverse tables
```

**Use case :** Analytics sur données Dynamics 365 / Power Apps

### Création d'un Shortcut (UI)

```
1. Lakehouse → Files → New Shortcut
2. Choisir le type (OneLake, S3, ADLS Gen2, Dataverse)
3. Fournir les credentials et le path
4. Nommer le shortcut
5. Créer
```

Les données sont immédiatement accessibles comme si elles étaient locales !

## Comparaison OneLake vs ADLS Gen2

| Caractéristique | OneLake | ADLS Gen2 |
|----------------|---------|-----------|
| **Scope** | Tout le tenant Fabric | Par compte de stockage |
| **Accès** | Unifié (tous workloads) | Nécessite configuration par service |
| **Format** | Delta Lake natif | Formats multiples |
| **Gouvernance** | Fabric native (Purview) | Externe |
| **Coût** | Inclus dans capacité Fabric | Séparé (stockage + transactions) |
| **Shortcuts** | Oui (OneLake, S3, ADLS) | Non natif |
| **Security** | Workspace-based | Container/Blob-based |

## Fonctionnalités Avancées

### 1. Compute-Storage Separation

OneLake sépare le **calcul** (Spark, SQL) du **stockage**.

**Avantages :**
- Scale indépendant
- Pas de lock-in compute/storage
- Optimisation des coûts

```
Multiple Compute Engines
    ↓      ↓      ↓
  Spark   SQL   Power BI
    ↓      ↓      ↓
  ┌──────────────────┐
  │     OneLake      │
  └──────────────────┘
```

### 2. V-Order Optimization

V-Order est une **optimisation de compression** propriétaire de Microsoft pour OneLake.

**Bénéfices :**
- Compression ~50% meilleure que Parquet standard
- Lecture ~2x plus rapide (Power BI Direct Lake)
- Écriture un peu plus lente (tradeoff)

**Activation :**
```sql
-- Automatique pour nouvelles tables
-- Ou manuel :
OPTIMIZE myTable;
```

### 3. Time Travel

Grâce au transaction log Delta, OneLake supporte le time travel.

```sql
-- Lire une version spécifique
SELECT * FROM sales VERSION AS OF 10;

-- Lire à une date précise
SELECT * FROM sales TIMESTAMP AS OF '2024-01-15 10:00:00';

-- Voir l'historique
DESCRIBE HISTORY sales;
```

### 4. Multi-region Support

OneLake peut être déployé dans **différentes régions Azure**.

```
Workspace Europe → OneLake (West Europe)
Workspace US     → OneLake (East US)
```

**Souveraineté des données** respectée.

## Sécurité OneLake

### Niveaux de sécurité

```
1. Tenant Level    : Admin Azure AD
2. Workspace Level : Admin/Member/Contributor/Viewer
3. Item Level      : Permissions sur Lakehouse/Warehouse
4. Data Level      : Row-Level Security (RLS), Column-Level Security (CLS)
```

### Encryption

- **At rest** : Chiffrement automatique (Microsoft-managed keys)
- **In transit** : TLS 1.2+
- **Customer-managed keys** : Possible via Azure Key Vault

## Best Practices OneLake

### 1. Organisation des données

✅ **DO:**
- Utiliser la structure Medallion (Bronze/Silver/Gold)
- Organiser par domaine métier dans workspaces
- Nommer clairement les tables et fichiers

❌ **DON'T:**
- Tout mettre dans un seul Lakehouse
- Mélanger raw et processed data
- Utiliser des noms cryptiques

### 2. Partitionnement

✅ **DO:**
- Partitionner les grandes tables (>1GB) par date
- Limiter à 1000-2000 partitions max

❌ **DON'T:**
- Over-partitionner (trop de petites partitions)
- Partitionner les petites tables

### 3. Shortcuts

✅ **DO:**
- Utiliser pour fédération de données
- Documenter les sources externes

❌ **DON'T:**
- Abuser des shortcuts (performance!)
- Oublier que la source doit rester disponible

## Monitoring OneLake

### Métriques clés

- **Storage utilisé** (GB)
- **Nombre de tables**
- **Nombre de fichiers**
- **Taux de croissance**

### Outils

```
Fabric Monitoring Hub
├── Storage metrics
├── Compute usage
└── Activity log
```

## Points clés à retenir

- OneLake est le lac de données **unifié** de Fabric (un seul pour tout le tenant)
- Format **Delta Lake** par défaut (Parquet + transaction log)
- **Shortcuts** permettent la virtualisation sans copie
- **Compatible ADLS Gen2** API (outils existants fonctionnent)
- **Separation compute-storage** pour flexibilité et coûts
- **V-Order** optimisation propriétaire pour performances
- **Time travel** natif grâce à Delta
- **Sécurité** multi-niveaux (tenant, workspace, item, data)

---

**Prochain fichier :** [03 - Workloads et Composants](./03-workloads-composants.md)

[⬅️ Fichier précédent](./01-overview-fabric.md) | [⬅️ Retour au README du module](./README.md)
