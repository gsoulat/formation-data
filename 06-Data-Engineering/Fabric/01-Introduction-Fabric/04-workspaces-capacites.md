# Workspaces et Capacités

## Concepts Fondamentaux

Dans Microsoft Fabric, deux concepts clés structurent l'organisation :
- **Workspace** : Conteneur logique pour vos items
- **Capacity** : Ressources compute allouées

```
┌─────────────────────────────────────────┐
│         Tenant (Organization)            │
│                                          │
│  ┌────────────────────────────────┐     │
│  │      Capacity F64              │     │
│  │  ┌──────────────────────────┐  │     │
│  │  │  Workspace: Sales        │  │     │
│  │  │  - Lakehouse A           │  │     │
│  │  │  - Warehouse B           │  │     │
│  │  │  - Pipeline C            │  │     │
│  │  └──────────────────────────┘  │     │
│  │  ┌──────────────────────────┐  │     │
│  │  │  Workspace: Marketing    │  │     │
│  │  │  - Semantic Model X      │  │     │
│  │  │  - Reports Y, Z          │  │     │
│  │  └──────────────────────────┘  │     │
│  └────────────────────────────────┘     │
└─────────────────────────────────────────┘
```

---

## Workspaces

### Qu'est-ce qu'un Workspace ?

Un workspace est un **conteneur collaboratif** qui regroupe des items Fabric liés.

**Analogie :** Un workspace = un dossier de projet partagé

### Types d'Items dans un Workspace

Un workspace peut contenir tous les types d'items Fabric :

```
Mon Workspace
├── 📊 Lakehouses (2)
├── 🏢 Warehouses (1)
├── 🔄 Pipelines (5)
├── 📓 Notebooks (10)
├── 📈 Semantic Models (3)
├── 📊 Reports (8)
├── 🔴 KQL Databases (1)
├── 🎯 ML Models (2)
└── ⚡ Dataflows (4)
```

### Création d'un Workspace

**Via UI :**
1. Fabric Portal → Workspaces
2. "+ New workspace"
3. Nom, description
4. Choisir la capacité (si disponible)
5. Create

**Via API REST :**
```http
POST https://api.fabric.microsoft.com/v1/workspaces
{
  "displayName": "Sales Analytics",
  "description": "Workspace for sales team analytics",
  "capacityId": "<capacity-guid>"
}
```

### Organisation des Workspaces

**Best Practices :**

**❌ Mauvais : Un seul workspace pour tout**
```
Workspace: "Company Data"
  ├── Sales stuff
  ├── Marketing stuff
  ├── Finance stuff
  └── HR stuff
```
Problème : Difficile à gérer, sécurité complexe

**✅ Bon : Workspaces par domaine/équipe**
```
├── Workspace: "Sales Analytics"
├── Workspace: "Marketing Campaigns"
├── Workspace: "Finance Reporting"
└── Workspace: "HR Dashboard"
```

**✅ Excellent : Workspaces par environnement + domaine**
```
├── Workspace: "Sales-Dev"
├── Workspace: "Sales-Test"
├── Workspace: "Sales-Prod"
├── Workspace: "Marketing-Dev"
├── Workspace: "Marketing-Prod"
```

---

## Rôles dans les Workspaces

### Les 4 Rôles Principaux

| Rôle | Permissions | Use Case |
|------|------------|----------|
| **Admin** | Tout (manage, publish, share, delete) | Owners, Data Engineers leads |
| **Member** | Create, edit, publish items | Data Engineers, Analysts |
| **Contributor** | Edit items, cannot publish | Junior analysts |
| **Viewer** | Read-only | Business users, consumers |

### Détail des Permissions

#### Admin 👑
```
✅ Gérer workspace (settings, delete)
✅ Ajouter/retirer membres
✅ Créer, éditer, publier items
✅ Partager items
✅ Gérer connections
✅ Voir toutes les dépendances
```

**Quand utiliser :**
- Responsables d'équipe
- Data Engineering leads
- Admins IT

#### Member 👨‍💻
```
✅ Créer items
✅ Éditer items
✅ Publier items
✅ Partager items (selon settings)
❌ Gérer workspace
❌ Supprimer workspace
```

**Quand utiliser :**
- Data Engineers
- Data Analysts
- Data Scientists
- Développeurs

#### Contributor ✏️
```
✅ Éditer items existants
✅ Créer rapports depuis semantic models
❌ Créer nouveaux items (Lakehouse, Warehouse, etc.)
❌ Publier
❌ Partager
```

**Quand utiliser :**
- Analystes juniors
- Report builders
- Utilisateurs qui éditent sans créer

#### Viewer 👀
```
✅ Voir items
✅ Lire données (si permissions)
✅ Exécuter rapports
❌ Éditer
❌ Créer
❌ Partager
```

**Quand utiliser :**
- Business users
- Consommateurs de rapports
- Stakeholders

### Gestion des Membres

**Ajouter un membre (UI) :**
```
Workspace → Manage access → Add people
  └─ Choisir: User, Group, or Service Principal
  └─ Sélectionner rôle
  └─ Add
```

**Ajouter un Azure AD Group :**
```
Best practice: Utiliser des groupes AD plutôt que users individuels

Example:
  - "Sales-Admins" → Admin
  - "Sales-Engineers" → Member
  - "Sales-Analysts" → Contributor
  - "Sales-Business-Users" → Viewer
```

**Service Principals :**
Pour automation (CI/CD, scripts) :
```
Service Principal: "Deployment-SPN"
Role: Admin
Used for: Automated deployments via Azure DevOps
```

---

## Capacités (Capacity)

### Qu'est-ce qu'une Capacité ?

Une capacité est un **pool de ressources compute** dédié à vos workloads Fabric.

**Modèle de licensing :** Vous achetez des Capacity Units (CU).

### F-SKUs Disponibles

| SKU | CU/heure | v-Cores | RAM | Prix indicatif/mois* |
|-----|----------|---------|-----|----------------------|
| F2  | 2 | 2 | 16 GB | ~€260 |
| F4  | 4 | 4 | 32 GB | ~€520 |
| F8  | 8 | 8 | 64 GB | ~€1,040 |
| F16 | 16 | 16 | 128 GB | ~€2,080 |
| F32 | 32 | 32 | 256 GB | ~€4,160 |
| F64 | 64 | 64 | 512 GB | ~€8,320 |
| F128 | 128 | 128 | 1 TB | ~€16,640 |
| F256 | 256 | 256 | 2 TB | ~€33,280 |
| F512 | 512 | 512 | 4 TB | ~€66,560 |

*Prix Europe Ouest, indicatif, à vérifier sur pricing Azure

**Minimum requis :** F64 pour production (ou F2 pour test/dev)

### Capacity Units (CU)

Les CU mesurent la consommation de ressources.

**Différents workloads consomment différemment :**

```
1 heure de Spark job sur F64 ≠ 1 heure de rapport Power BI

Example de consommation:
- Notebook Spark (heavy): 10 CU/heure
- Pipeline Copy activity: 2 CU/heure
- Power BI refresh: 5 CU/heure
- Warehouse query: 1 CU/heure
```

### Smoothing (Lissage sur 24h)

Fabric utilise un **lissage sur 24h** pour la facturation.

**Exemple :**
```
Capacité F64 = 64 CU/heure = 1,536 CU/jour (64 × 24)

Jour 1:
  9h-10h: Pic à 200 CU
  10h-17h: 20 CU/heure
  Reste: 0 CU

Total journalier: 340 CU
Lissé sur 24h: 340/24 = 14.2 CU/heure
Résultat: Dans la limite (< 64) ✅
```

**Conséquence :** Vous pouvez "burst" au-delà de votre capacité pendant de courtes périodes.

### Throttling

Si consommation dépasse la capacité sur 24h :

**Comportement :**
1. **Interactive operations** : Rejetées (erreur immédiate)
2. **Background operations** : Delayées (mises en queue)

**Types d'opérations :**
- **Interactive** : Requêtes Power BI, notebook ad-hoc
- **Background** : Refreshes, pipelines scheduled

**Comment éviter :**
- Right-size la capacité
- Optimiser les workloads
- Scheduler off-peak hours
- Monitor avec Capacity Metrics App

### Assignment de Workspaces

**Un workspace est assigné à UNE capacité.**

```
Capacity F64
  ├─ Workspace Sales ✅
  ├─ Workspace Marketing ✅
  └─ Workspace Finance ✅

Capacity F32
  ├─ Workspace HR ✅
  └─ Workspace IT ✅
```

**Changer de capacité :**
```
Workspace Settings → License mode → Fabric capacity
  └─ Select capacity
```

### Trial vs Capacité Payante

**Fabric Trial :**
- 60 jours gratuits
- Équivalent F64
- Limites : 1 workspace, pas de production
- Extension possible (1 fois)

**Migration Trial → Paid :**
```
1. Acheter capacité Fabric (F-SKU)
2. Assigner workspace à la capacité payante
3. Trial workspace devient standard
```

---

## Workspace Settings

### Configuration Avancée

**Paramètres clés :**

#### 1. License Mode
```
Options:
  - Fabric capacity (F-SKU) ✅ Recommandé
  - Power BI Premium (P-SKU)
  - Pro (limité)
```

#### 2. OneLake Settings
```
- OneLake storage path
- Default storage format (Delta)
- Shortcuts allowed: Oui/Non
```

#### 3. Git Integration
```
- Connect to Azure DevOps / GitHub
- Branch configuration
- Sync settings
```

#### 4. Data Lineage
```
- Enable data lineage: Oui ✅
- Purview integration
```

#### 5. Contacts
```
- Workspace admins
- Support contacts
```

---

## Multi-Workspace Patterns

### Pattern 1 : Environnements Dev/Test/Prod

```
Development Capacity (F8)
  └─ Dev Workspaces

Test Capacity (F16)
  └─ Test Workspaces

Production Capacity (F64)
  └─ Prod Workspaces
```

**Avantages :**
- Isolation complète
- Coûts optimisés (dev/test plus petit)
- Sécurité renforcée

### Pattern 2 : Domaines Métier

```
Sales Capacity (F32)
  ├─ Sales-EU
  ├─ Sales-US
  └─ Sales-APAC

Marketing Capacity (F16)
  └─ Marketing-Global
```

**Avantages :**
- Chargeback par département
- Scaling indépendant
- Gouvernance par domaine

### Pattern 3 : Hybrid (Recommandé)

```
Shared Capacity (F64) - Production
  ├─ Sales-Prod
  ├─ Marketing-Prod
  └─ Finance-Prod

Development Capacity (F16) - Non-Prod
  ├─ Sales-Dev
  ├─ Marketing-Dev
  └─ Finance-Dev
```

**Avantages :**
- Coût optimisé
- Flexibilité
- Simple à gérer

---

## Monitoring & Governance

### Capacity Metrics App

```
Install → Monitor capacity utilization
  ├─ CU consumption
  ├─ Throttling events
  ├─ Top consumers
  └─ Trends
```

### Workspace Monitoring

```
Workspace → Monitoring Hub
  ├─ Pipeline runs
  ├─ Notebook executions
  ├─ Refresh history
  └─ Errors & warnings
```

---

## Best Practices

### Workspaces

✅ **DO:**
- Un workspace par projet/équipe
- Utiliser Azure AD groups pour membres
- Naming convention claire (`<team>-<env>`)
- Documenter le purpose du workspace

❌ **DON'T:**
- Trop de workspaces (overhead management)
- Assigner users individuellement
- Mélanger dev et prod dans même workspace

### Capacités

✅ **DO:**
- Right-size selon workload
- Monitor régulièrement (Capacity Metrics)
- Auto-pause pour dev/test
- Separate prod from non-prod

❌ **DON'T:**
- Under-provision (throttling)
- Over-provision (gaspillage)
- Ignorer les alertes de throttling

---

## Points Clés à Retenir

- **Workspace** = conteneur logique pour items
- **Capacity** = ressources compute (F-SKUs)
- 4 rôles : Admin, Member, Contributor, Viewer
- Capacity Units (CU) mesurent la consommation
- Smoothing sur 24h permet des pics temporaires
- Throttling si dépassement prolongé
- Best practice : Séparer dev/test/prod

---

**Prochain fichier :** [05 - Licences, SKU et Pricing](./05-licences-sku-pricing.md)

[⬅️ Fichier précédent](./03-workloads-composants.md) | [⬅️ Retour au README du module](./README.md)
